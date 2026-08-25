import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/track_step_def.dart';
import '../services/api_service.dart';
import '../utils/num_helper.dart';

const kGarmentLabels = ['Shirts ×4', 'Trousers ×2', 'Dress ×1', 'Linen ×1'];
const kDamageLabels = [
  'Fading on collar (shirt 2)',
  'Loose seam on trousers',
  'Bleach mark on linen',
  'Missing button',
];

/// Fallback pipeline labels used when an order has no `tracking` rows yet.
const kProcessingSteps = [
  TrackStepDef(title: 'Received', time: '—'),
  TrackStepDef(title: 'Sorted & tagged', time: '—'),
  TrackStepDef(title: 'Washing', time: '—'),
  TrackStepDef(title: 'Drying & pressing', time: '—'),
  TrackStepDef(title: 'Ready for delivery', time: '—'),
];

/// One line of the customer's actual basket (GET /vendor/orders/{id} →
/// `lines[]`): a package row or a per-item service.
class DetailLine {
  const DetailLine({
    required this.name,
    required this.qty,
    required this.unitPriceTzs,
    this.lineType = '',
  });

  final String name;
  final int qty;
  final double unitPriceTzs;
  final String lineType;

  double get total => qty * unitPriceTzs;
}

/// Raw API id (no "#LD-" prefix) of the order currently open in the detail
/// screen — set by the orders list before the route push.
String normalizeVendorOrderId(String displayId) =>
    displayId.startsWith('#LD-') ? displayId.substring(4) : displayId;

class VendorOrderDetailState {
  const VendorOrderDetailState({
    this.garment = 0,
    this.damage = const [true, false, false, false],
    this.damageNote = '',
    this.tagId = 'MF-2481-A',
    this.step = 2,
    this.orderId = '',
    this.customerName = '',
    this.itemsSummary = '',
    this.lines = const [],
    this.timeline = const [],
    this.isLoading = false,
  });

  final int garment;
  final List<bool> damage;
  final String damageNote;
  final String tagId;
  final int step;

  final String orderId;
  final String customerName;
  final String itemsSummary;
  final List<DetailLine> lines;
  final List<TrackStepDef> timeline;
  final bool isLoading;

  bool get hasOrder => orderId.isNotEmpty;

  VendorOrderDetailState copyWith({
    int? garment,
    List<bool>? damage,
    String? damageNote,
    String? tagId,
    int? step,
    String? orderId,
    String? customerName,
    String? itemsSummary,
    List<DetailLine>? lines,
    List<TrackStepDef>? timeline,
    bool? isLoading,
  }) =>
      VendorOrderDetailState(
        garment: garment ?? this.garment,
        damage: damage ?? this.damage,
        damageNote: damageNote ?? this.damageNote,
        tagId: tagId ?? this.tagId,
        step: step ?? this.step,
        orderId: orderId ?? this.orderId,
        customerName: customerName ?? this.customerName,
        itemsSummary: itemsSummary ?? this.itemsSummary,
        lines: lines ?? this.lines,
        timeline: timeline ?? this.timeline,
        isLoading: isLoading ?? this.isLoading,
      );
}

class VendorOrderDetailNotifier extends Notifier<VendorOrderDetailState> {
  @override
  VendorOrderDetailState build() => const VendorOrderDetailState();

  Future<void> load(String rawOrderId) async {
    if (rawOrderId.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      final data = await api.getVendorOrderDetail(rawOrderId);
      final customer = data['customer'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        orderId: rawOrderId,
        customerName: customer['name'] as String? ?? '',
        itemsSummary: data['items_summary'] as String? ?? '',
        lines: [
          for (final j in (data['lines'] as List?)?.whereType<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[])
            DetailLine(
              name: j['item_name'] as String? ?? '',
              qty: parseInt(j['qty']) ?? 0,
              unitPriceTzs: parseDouble(j['unit_price_tzs']) ?? 0,
              lineType: j['line_type'] as String? ?? '',
            ),
        ],
        timeline: _timeline(data['tracking'] as List?),
        isLoading: false,
      );
    } on ApiException {
      // Keep prior state — the inspection UI still works offline.
      state = state.copyWith(isLoading: false);
    }
  }

  /// `tracking[]` rows arrive newest-first or oldest-first depending on the
  /// backend; normalize to oldest-first with humanized labels.
  List<TrackStepDef> _timeline(List? raw) {
    final rows = (raw ?? []).whereType<Map<String, dynamic>>().toList();
    if (rows.isEmpty) return const [];
    return [
      for (final j in rows.reversed)
        TrackStepDef(
          title: _statusLabel(j['status'] as String? ?? ''),
          time: _timeLabel(j['created_at'] as String? ?? j['at'] as String? ?? ''),
        ),
    ];
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Update';
    return status
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _timeLabel(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return '—';
    final h = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final m = parsed.minute.toString().padLeft(2, '0');
    final suffix = parsed.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $suffix';
  }

  void pickGarment(int i) => state = state.copyWith(garment: i);

  void toggleDamage(int i) {
    final next = List.of(state.damage);
    next[i] = !next[i];
    state = state.copyWith(damage: next);
  }

  void setDamageNote(String v) => state = state.copyWith(damageNote: v);

  void regenTag() {
    state = state.copyWith(
      tagId: 'MF-${DateTime.now().millisecondsSinceEpoch % 10000}',
    );
  }

  void pickStep(int i) => state = state.copyWith(step: i);
}

final vendorOrderDetailProvider = NotifierProvider<VendorOrderDetailNotifier, VendorOrderDetailState>(
  VendorOrderDetailNotifier.new,
);
