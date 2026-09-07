import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_service.dart';

/// Hand-rolled Pusher-protocol client (private channels only) talking
/// directly to the self-hosted Laravel Reverb server behind
/// `wss://freshfold.qecure.online/app/{key}`.
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

  /// `action` is one of 'new_order' | 'accepted' | 'rejected' | 'status_updated'.
  void Function(String action, Map<String, dynamic> order)? onOrderEvent;
  void Function(Map<String, dynamic> notification)? onNotificationEvent;

  /// `action` is currently always 'redeemed' — fired when a customer's order
  /// applies this shop's promo code, the one promo change that doesn't
  /// originate from the vendor's own app and so can't just update local
  /// state on a successful request the way create/toggle/delete already do.
  void Function(String action, Map<String, dynamic> promo)? onPromoEvent;

  /// Ensures the socket is open and subscribed to exactly
  /// `private-user.{userId}` plus `private-vendor-shop.{shopId}` (when
  /// [shopId] is known). Safe to call repeatedly — e.g. once at login with
  /// `shopId: null`, then again once the dashboard load resolves it; only
  /// the newly-needed channel gets subscribed, the socket itself isn't
  /// reopened if already connected.
  void connect({required int userId, int? shopId}) {
    _wantedChannels = {
      'private-user.$userId',
      if (shopId != null) 'private-vendor-shop.$shopId',
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
      default:
        // pusher_internal:subscription_succeeded / subscription_error /
        // pusher:error — best-effort channel, nothing to act on here.
        break;
    }
  }

  Future<void> _subscribe(String channelName) async {
    final socketId = _socketId;
    if (socketId == null) return;
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
