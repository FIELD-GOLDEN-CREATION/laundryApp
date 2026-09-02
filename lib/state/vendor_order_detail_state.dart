import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/track_step_def.dart';
import '../services/api_service.dart';
import '../utils/num_helper.dart';
import '../utils/time_format.dart';
import 'vendor_orders_state.dart';

const kGarmentLabels = ['Shirts ×4', 'Trousers ×2', 'Dress ×1', 'Linen ×1'];
const kDamageLabels = [
  'Fading on collar (shirt 2)',
  'Loose seam on trousers',
  'Bleach mark on linen',
  'Missing button',
];

/// Fallback pipeline labels used when an order has no `tracking` rows yet —
/// one entry per backend status in [kVendorStatusPipeline], same index.
const kProcessingSteps = [
  TrackStepDef(title: 'Accepted', time: '—'),
  TrackStepDef(title: 'Washing', time: '—'),
  TrackStepDef(title: 'Ready for delivery', time: '—'),
  TrackStepDef(title: 'Out for delivery', time: '—'),
  TrackStepDef(title: 'Delivered', time: '—'),
];

/// Backend `orders.status` values a vendor can advance an order through,
/// in order — index i is the status PATCHed by tapping step i in
/// [kProcessingSteps]. Mirrors `VendorOrderController::updateStatus`'s
/// `$validTransitions` on the backend (accepted is the entry status set by
/// `POST .../accept`, not itself PATCHed via the status endpoint).
const kVendorStatusPipeline = ['accepted', 'in_wash', 'ready', 'out_for_delivery', 'delivered'];

/// One line of the customer's actual basket (GET /vendor/orders/{id} →
/// `lines[]`): a package row or a per-item service.
class DetailLine {
  const DetailLine({
    required this.name,
    required this.qty,
    required this.unitPriceTzs,
    this.lineType = '',
    this.categoryName = '',
  });

  final String name;
  final int qty;
  final double unitPriceTzs;
  final String lineType;

  /// The catalog category this item belongs to (e.g. "Shirts"), when the
  /// line is a per-item pick (`lineType == 'item'`). Empty for package rows.
  final String categoryName;

  double get total => qty * unitPriceTzs;
}

/// An add-on service the customer selected for this order (GET
/// /vendor/orders/{id} → `addons[]`), e.g. "Stain removal".
class DetailAddon {
  const DetailAddon({required this.title, required this.priceTzs});

  final String title;
  final double priceTzs;
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
    this.step = 0,
    this.orderId = '',
    this.status = '',
    this.customerName = '',
    this.itemsSummary = '',
    this.lines = const [],
    this.addons = const [],
    this.timeline = const [],
    this.isLoading = false,
    this.isUpdatingStatus = false,
  });

  final int garment;
  final List<bool> damage;
  final String damageNote;
  final String tagId;

  /// Index into [kProcessingSteps]/[kVendorStatusPipeline] the order is
  /// currently at, derived from [status].
  final int step;

  final String orderId;

  /// Raw backend `orders.status` (e.g. `in_wash`, `ready`) for the loaded order.
  final String status;
  final String customerName;
  final String itemsSummary;
  final List<DetailLine> lines;
  final List<DetailAddon> addons;
  final List<TrackStepDef> timeline;
  final bool isLoading;

  /// True while a step tap's PATCH to the backend is in flight.
  final bool isUpdatingStatus;

  bool get hasOrder => orderId.isNotEmpty;

  List<DetailLine> get packageLines => lines.where((l) => l.lineType == 'package').toList();
  List<DetailLine> get itemLines => lines.where((l) => l.lineType == 'item').toList();

  VendorOrderDetailState copyWith({
    int? garment,
    List<bool>? damage,
    String? damageNote,
    String? tagId,
    int? step,
    String? orderId,
    String? status,
    String? customerName,
    String? itemsSummary,
    List<DetailLine>? lines,
    List<DetailAddon>? addons,
    List<TrackStepDef>? timeline,
    bool? isLoading,
    bool? isUpdatingStatus,
  }) =>
      VendorOrderDetailState(
        garment: garment ?? this.garment,
        damage: damage ?? this.damage,
        damageNote: damageNote ?? this.damageNote,
        tagId: tagId ?? this.tagId,
        step: step ?? this.step,
        orderId: orderId ?? this.orderId,
        status: status ?? this.status,
        customerName: customerName ?? this.customerName,
        itemsSummary: itemsSummary ?? this.itemsSummary,
        lines: lines ?? this.lines,
        addons: addons ?? this.addons,
        timeline: timeline ?? this.timeline,
        isLoading: isLoading ?? this.isLoading,
        isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      );
}

/// Where `status` sits in [kVendorStatusPipeline]; -1 (e.g. still `pending`,
/// not yet accepted) shows every step as pending.
int stepForVendorStatus(String status) {
  final i = kVendorStatusPipeline.indexOf(status);
  return i;
}

class VendorOrderDetailNotifier extends Notifier<VendorOrderDetailState> {
  @override
  VendorOrderDetailState build() => const VendorOrderDetailState();

  Future<void> load(String rawOrderId) async {
    if (rawOrderId.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      final envelope = await api.getVendorOrderDetail(rawOrderId);
      final data = envelope['data'] as Map<String, dynamic>? ?? envelope;
      final customer = data['customer'] as Map<String, dynamic>? ?? {};

      final lines = [
        for (final j in (data['lines'] as List?)?.whereType<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[])
          DetailLine(
            name: j['name'] as String? ?? '',
            qty: parseInt(j['qty']) ?? 0,
            unitPriceTzs: parseDouble(j['unit_price_tzs']) ?? 0,
            lineType: j['line_type'] as String? ?? '',
            categoryName: _categoryName(j),
          ),
      ];

      final status = data['status'] as String? ?? '';
      state = state.copyWith(
        orderId: rawOrderId,
        status: status,
        step: stepForVendorStatus(status),
        customerName: customer['name'] as String? ?? '',
        itemsSummary: lines
            .where((l) => l.lineType == 'item')
            .map((l) => '${l.qty}× ${l.name}')
            .join(', '),
        lines: lines,
        addons: [
          for (final j in (data['addons'] as List?)?.whereType<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[])
            DetailAddon(
              title: j['title'] as String? ?? '',
              priceTzs: parseDouble(j['price_tzs']) ?? 0,
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

  /// A line's catalog category name, when the backend joined `item.category`
  /// (only present for `line_type == 'item'` rows — package rows have no item).
  String _categoryName(Map<String, dynamic> line) {
    final item = line['item'] as Map<String, dynamic>?;
    final category = item?['category'] as Map<String, dynamic>?;
    return category?['name'] as String? ?? '';
  }

  /// `tracking[]` rows arrive newest-first or oldest-first depending on the
  /// backend; normalize to oldest-first with humanized labels.
  List<TrackStepDef> _timeline(List? raw) {
    final rows = (raw ?? []).whereType<Map<String, dynamic>>().toList();
    if (rows.isEmpty) return const [];
    return [
      for (final j in rows.reversed)
        TrackStepDef(
          title: _stepTitle(j),
          // `completed_at` is when the stage was actually reached;
          // `created_at` is only a fallback for older rows that predate it.
          time: _timeLabel((j['completed_at'] ?? j['created_at']) as String? ?? ''),
        ),
    ];
  }

  /// Prefers the row's human-readable `title` (what the backend records);
  /// falls back to humanizing the raw `status` key if `title` is missing.
  String _stepTitle(Map<String, dynamic> j) {
    final title = j['title'] as String?;
    if (title != null && title.isNotEmpty) return title;
    return _statusLabel(j['status'] as String? ?? '');
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
    return formatClockTime(parsed);
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

  /// Advances the order to `kVendorStatusPipeline[i]` via the vendor status
  /// API. Only the immediate next step is a valid move — mirrors the
  /// backend's `$validTransitions` map, which rejects skipping or
  /// re-triggering a step. Returns false (no-op) for an invalid tap,
  /// a request already in flight, or an API failure.
  Future<bool> advanceStep(int i) async {
    if (state.isUpdatingStatus || !state.hasOrder) return false;
    if (i != state.step + 1 || i >= kVendorStatusPipeline.length) return false;

    state = state.copyWith(isUpdatingStatus: true);
    try {
      await api.updateOrderStatus(state.orderId, kVendorStatusPipeline[i]);
      state = state.copyWith(
        step: i,
        status: kVendorStatusPipeline[i],
        isUpdatingStatus: false,
      );
      // Refresh the orders list so the Incoming/In progress/Ready tabs
      // (bucketed server-side from `status`) pick up the new stage.
      ref.read(vendorOrdersProvider.notifier).loadOrders();
      return true;
    } on ApiException {
      state = state.copyWith(isUpdatingStatus: false);
      return false;
    }
  }
}

final vendorOrderDetailProvider = NotifierProvider<VendorOrderDetailNotifier, VendorOrderDetailState>(
  VendorOrderDetailNotifier.new,
);
