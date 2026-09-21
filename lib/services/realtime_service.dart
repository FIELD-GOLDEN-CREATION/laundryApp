import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_service.dart';

/// Hand-rolled Pusher-protocol client talking directly to the self-hosted
/// Laravel Reverb server behind `wss://freshfold.qecure.online/app/{key}`.
/// Mostly private channels (per-user/per-shop/per-thread, each requiring the
/// `/broadcasting/auth` handshake below), plus two public channels
/// (`reviews` and `packages`, both feeding the home screen's cross-vendor
/// carousels) that every client — even a signed-out one, in principle — can
/// join with no auth step at all.
///
/// `pusher_channels_flutter` was tried first, but its native Android/iOS
/// layer only forwards `apiKey`/`cluster` to the underlying Pusher SDKs —
/// there is no way to point it at a custom host, so it can only ever reach
/// Pusher's actual cloud service, never a self-hosted Reverb server. The
/// wire protocol itself is small enough (connect, auth a private channel,
/// subscribe, handle ping/pong) that hand-rolling it on `web_socket_channel`
/// (official Dart-team package) is more reliable than fighting a plugin
/// that fundamentally can't do what's needed here.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  static const _appKey = '559ce0a5b8ff665df27e';
  static final _wsUri = Uri.parse(
    'wss://freshfold.qecure.online/app/$_appKey?protocol=7&client=flutter&version=1.0&flash=false',
  );
  static const _reconnectDelay = Duration(seconds: 4);

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  String? _socketId;
  Set<String> _wantedChannels = {};
  final Set<String> _subscribedChannels = {};
  Timer? _reconnectTimer;
  bool _disposed = true;

  /// Chat-thread channels joined on demand (a panel opening/closing), keyed
  /// by the full `private-chat-thread.{id}` channel name — unlike the fixed
  /// per-session channels above, these come and go independently of
  /// [connect], so they're tracked separately and re-added to
  /// [_wantedChannels] on every [connect] call so a base reconnect doesn't
  /// drop whichever thread is currently open.
  final Map<String, void Function(Map<String, dynamic>)> _chatHandlers = {};

  /// `action` is one of 'new_order' | 'accepted' | 'rejected' | 'status_updated'.
  void Function(String action, Map<String, dynamic> order)? onOrderEvent;
  void Function(Map<String, dynamic> notification)? onNotificationEvent;

  /// `action` is currently always 'redeemed' — fired when a customer's order
  /// applies this shop's promo code, the one promo change that doesn't
  /// originate from the vendor's own app and so can't just update local
  /// state on a successful request the way create/toggle/delete already do.
  void Function(String action, Map<String, dynamic> promo)? onPromoEvent;

  /// `action` is 'shown' | 'hidden' — fired when an admin toggles whether a
  /// review is featured on the customer home screen's carousel. Delivered on
  /// the public `reviews` channel (see [_wantedChannels] in [connect]), not
  /// scoped to any one user.
  void Function(String action, Map<String, dynamic> review)? onReviewVisibilityEvent;

  /// `action` is 'shown' | 'hidden' — fired when an admin toggles whether a
  /// package is featured on the customer home screen's carousel (or flips
  /// `is_active` while it's already featured there). Delivered on the public
  /// `packages` channel (see [_wantedChannels] in [connect]), not scoped to
  /// any one user. Mirrors [onReviewVisibilityEvent].
  void Function(String action, Map<String, dynamic> package)? onPackageVisibilityEvent;

  /// Ensures the socket is open and subscribed to exactly
  /// `private-user.{userId}` plus `private-vendor-shop.{shopId}` (when
  /// [shopId] is known) plus the public `reviews` and `packages` channels.
  /// Safe to call repeatedly — e.g. once at login with
  /// `shopId: null`, then again once the dashboard load resolves it; only
  /// the newly-needed channel gets subscribed, the socket itself isn't
  /// reopened if already connected.
  void connect({required int userId, int? shopId}) {
    _wantedChannels = {
      'private-user.$userId',
      if (shopId != null) 'private-vendor-shop.$shopId',
      // Public — no 'private-' prefix, no auth handshake (see _subscribe).
      'reviews',
      'packages',
      ..._chatHandlers.keys,
    };

    if (_channel == null) {
      _disposed = false;
      _open();
      return;
    }

    if (_socketId != null) {
      for (final ch in _wantedChannels) {
        if (!_subscribedChannels.contains(ch)) _subscribe(ch);
      }
    }
    for (final ch in _subscribedChannels.difference(_wantedChannels).toList()) {
      _send({'event': 'pusher:unsubscribe', 'data': {'channel': ch}});
      _subscribedChannels.remove(ch);
    }
  }

  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _sub?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _socketId = null;
    _wantedChannels = {};
    _subscribedChannels.clear();
    _chatHandlers.clear();
  }

  /// Joins the private channel for one chat thread — call when a chat panel
  /// opens. [onMessage] receives every `message.created` event on that
  /// thread until [leaveChatThread] is called. Safe to call before the base
  /// socket is even open (e.g. right after [connect]); the channel just
  /// joins once the connection handshake completes.
  void joinChatThread(int threadId, void Function(Map<String, dynamic> message) onMessage) {
    final channel = 'private-chat-thread.$threadId';
    _chatHandlers[channel] = onMessage;
    _wantedChannels = {..._wantedChannels, channel};
    if (_socketId != null && !_subscribedChannels.contains(channel)) {
      _subscribe(channel);
    }
  }

  /// Leaves one chat thread's channel — call when its panel closes.
  void leaveChatThread(int threadId) {
    final channel = 'private-chat-thread.$threadId';
    _chatHandlers.remove(channel);
    _wantedChannels = {..._wantedChannels}..remove(channel);
    if (_subscribedChannels.remove(channel)) {
      _send({'event': 'pusher:unsubscribe', 'data': {'channel': channel}});
    }
  }

  void _open() {
    _sub?.cancel();
    try {
      _channel = WebSocketChannel.connect(_wsUri);
    } catch (_) {
      _scheduleReconnect();
      return;
    }
    _socketId = null;
    _subscribedChannels.clear();
    _sub = _channel!.stream.listen(
      _onMessage,
      onError: (_) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
      cancelOnError: true,
    );
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, _open);
  }

  Future<void> _onMessage(dynamic raw) async {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final event = msg['event'] as String?;
    final rawData = msg['data'];
    Map<String, dynamic> data = const {};
    if (rawData is String && rawData.isNotEmpty) {
      try {
        data = jsonDecode(rawData) as Map<String, dynamic>;
      } catch (_) {}
    } else if (rawData is Map) {
      data = rawData.cast<String, dynamic>();
    }

    switch (event) {
      case 'pusher:connection_established':
        _socketId = data['socket_id'] as String?;
        for (final ch in _wantedChannels) {
          _subscribe(ch);
        }
      case 'pusher:ping':
        _send({'event': 'pusher:pong', 'data': {}});
      case 'notification.created':
        onNotificationEvent?.call(data);
      case 'order.updated':
        final order = data['order'];
        onOrderEvent?.call(
          data['action'] as String? ?? '',
          order is Map ? order.cast<String, dynamic>() : const {},
        );
      case 'promo.updated':
        final promo = data['promo'];
        onPromoEvent?.call(
          data['action'] as String? ?? '',
          promo is Map ? promo.cast<String, dynamic>() : const {},
        );
      case 'review.updated':
        final review = data['review'];
        onReviewVisibilityEvent?.call(
          data['action'] as String? ?? '',
          review is Map ? review.cast<String, dynamic>() : const {},
        );
      case 'package.updated':
        final package = data['package'];
        onPackageVisibilityEvent?.call(
          data['action'] as String? ?? '',
          package is Map ? package.cast<String, dynamic>() : const {},
        );
      case 'message.created':
        // Routed by channel (not a single fixed callback like the events
        // above) since more than one chat-thread channel could in principle
        // be joined — Reverb echoes the source channel on every frame.
        final channel = msg['channel'] as String?;
        if (channel != null) _chatHandlers[channel]?.call(data);
      default:
        // pusher_internal:subscription_succeeded / subscription_error /
        // pusher:error — best-effort channel, nothing to act on here.
        break;
    }
  }

  Future<void> _subscribe(String channelName) async {
    final socketId = _socketId;
    if (socketId == null) return;

    // Public channels (no 'private-' prefix) need no auth handshake at all —
    // just subscribe directly.
    if (!channelName.startsWith('private-')) {
      _send({
        'event': 'pusher:subscribe',
        'data': {'channel': channelName},
      });
      _subscribedChannels.add(channelName);
      return;
    }

    try {
      final res = await api.post('/broadcasting/auth', body: {
        'socket_id': socketId,
        'channel_name': channelName,
      });
      final auth = res['auth'] as String?;
      if (auth == null) return;
      _send({
        'event': 'pusher:subscribe',
        'data': {'channel': channelName, 'auth': auth},
      });
      _subscribedChannels.add(channelName);
    } on ApiException {
      // Best-effort — an expired/invalid token here fails the same way it
      // would on any other API call; the next reconnect retries it.
    }
  }

  void _send(Map<String, dynamic> msg) {
    try {
      _channel?.sink.add(jsonEncode(msg));
    } catch (_) {}
  }
}
