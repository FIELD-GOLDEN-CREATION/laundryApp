import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../utils/num_helper.dart';
import 'vendor_orders_state.dart';

/// One row of the vendor's "Processing status" checklist — a fixed pipeline
/// entry cross-referenced against this order's `order_tracking` rows.
class VendorTrackStep {
  const VendorTrackStep({required this.status, required this.title, this.completedAt});

  /// Backend `orders.status` / `order_tracking.status` key, e.g. `in_wash`.
  final String status;
  final String title;
  final DateTime? completedAt;

  bool get done => completedAt != null;
}

/// Full order-status pipeline, always displayed in this order regardless of
/// which steps have a tracking row yet. Mirrors `Order::STATUS_STEPS` on the
/// backend (pending..delivered; `cancelled` is a terminal branch, not shown
/// here since this screen only opens for accepted orders).
const kVendorPipeline = [
  ('pending', 'Order placed'),
  ('accepted', 'Accepted'),
  ('in_wash', 'Washing'),
  ('ready', 'Ready for delivery'),
  ('out_for_delivery', 'Out for delivery'),
  ('delivered', 'Delivered'),
];

/// Steps that are always-true facts of the order reaching this screen —
/// never independently toggleable by the vendor.
const kVendorLockedStatuses = {'pending', 'accepted'};

/// The 4 statuses the vendor's per-step toggle / bulk-complete endpoints
/// operate on. Mirrors `Order::STATUS_PIPELINE` minus `accepted`.
const kVendorToggleableStatuses = ['in_wash', 'ready', 'out_for_delivery', 'delivered'];

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
    this.orderId = '',
    this.status = '',
    this.customerName = '',
    this.itemsSummary = '',
    this.lines = const [],
    this.addons = const [],
    this.steps = const [],
    this.bulkSnapshot,
    this.isLoading = false,
    this.isUpdatingStatus = false,
  });

  final String orderId;

  /// Raw backend `orders.status` (e.g. `in_wash`, `ready`) for the loaded order.
  final String status;
  final String customerName;
  final String itemsSummary;
  final List<DetailLine> lines;
  final List<DetailAddon> addons;

  /// The full processing-status pipeline (see [kVendorPipeline]), each entry
  /// resolved against this order's tracking rows.
  final List<VendorTrackStep> steps;

  /// Snapshot of [steps] taken right before "Mark all complete" was tapped —
  /// non-null while that bulk action is currently applied; lets "Undo" put
  /// every step back exactly where it was on/off before the tap.
  final List<VendorTrackStep>? bulkSnapshot;

  final bool isLoading;

  /// True while a step toggle's PATCH to the backend is in flight.
  final bool isUpdatingStatus;

  bool get hasOrder => orderId.isNotEmpty;

  List<DetailLine> get packageLines => lines.where((l) => l.lineType == 'package').toList();
  List<DetailLine> get itemLines => lines.where((l) => l.lineType == 'item').toList();

  VendorOrderDetailState copyWith({
    String? orderId,
    String? status,
    String? customerName,
    String? itemsSummary,
    List<DetailLine>? lines,
    List<DetailAddon>? addons,
    List<VendorTrackStep>? steps,
    List<VendorTrackStep>? Function()? bulkSnapshot,
    bool? isLoading,
    bool? isUpdatingStatus,
  }) =>
      VendorOrderDetailState(
        orderId: orderId ?? this.orderId,
        status: status ?? this.status,
        customerName: customerName ?? this.customerName,
        itemsSummary: itemsSummary ?? this.itemsSummary,
        lines: lines ?? this.lines,
        addons: addons ?? this.addons,
        steps: steps ?? this.steps,
        bulkSnapshot: bulkSnapshot != null ? bulkSnapshot() : this.bulkSnapshot,
        isLoading: isLoading ?? this.isLoading,
        isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      );
}

/// Resolves [kVendorPipeline] against the order's raw `tracking[]` rows —
/// shared by the initial load and every toggle/bulk response so the
/// checklist always reflects exactly what the backend has on record.
List<VendorTrackStep> _stepsFromTracking(List? raw) {
  final rows = (raw ?? []).whereType<Map<String, dynamic>>().toList();
  final byStatus = <String, DateTime?>{
    for (final j in rows)
      (j['status'] as String? ?? ''): DateTime.tryParse((j['completed_at'] ?? j['created_at']) as String? ?? ''),
  };
  return [
    for (final (status, title) in kVendorPipeline)
      VendorTrackStep(status: status, title: title, completedAt: byStatus[status]),
  ];
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

      state = state.copyWith(
        orderId: rawOrderId,
        status: data['status'] as String? ?? '',
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
        steps: _stepsFromTracking(data['tracking'] as List?),
        bulkSnapshot: () => null,
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

  /// `PUT .../status` and `.../status/bulk-complete` responses only echo
  /// back the order row (no `tracking` array) — refetch the full detail so
  /// [steps] reflects the tracking rows the backend actually recorded,
  /// instead of the empty list a bare `data['tracking']` would produce.
  Future<void> _refreshSteps() async {
    final envelope = await api.getVendorOrderDetail(state.orderId);
    final data = envelope['data'] as Map<String, dynamic>? ?? envelope;
    state = state.copyWith(
      status: data['status'] as String? ?? state.status,
      steps: _stepsFromTracking(data['tracking'] as List?),
    );
  }

  /// Toggles one processing-status step on/off. No-op for locked statuses
  /// (order placed/accepted), while a request is already in flight, or
  /// before an order has loaded. Returns false on any of those or an API
  /// failure.
  Future<bool> toggleStep(String status) async {
    if (state.isUpdatingStatus || !state.hasOrder) return false;
    if (kVendorLockedStatuses.contains(status)) return false;
    final current = state.steps.firstWhere((s) => s.status == status, orElse: () => const VendorTrackStep(status: '', title: ''));
    if (current.status.isEmpty) return false;

    state = state.copyWith(isUpdatingStatus: true);
    try {
      await api.updateOrderStatus(state.orderId, status, done: !current.done);
      await _refreshSteps();
      state = state.copyWith(isUpdatingStatus: false);
      // Refresh the orders list so the Incoming/In progress/Ready tabs
      // (bucketed server-side from `status`) pick up any stage change.
      ref.read(vendorOrdersProvider.notifier).loadOrders();
      return true;
    } on ApiException {
      state = state.copyWith(isUpdatingStatus: false);
      return false;
    }
  }

  /// Stamps every remaining step (Washing..Delivered) done with one shared
  /// timestamp, after capturing the current on/off pattern so it can be
  /// restored by [undoMarkAllComplete].
  Future<bool> markAllComplete() async {
    if (state.isUpdatingStatus || !state.hasOrder) return false;

    final snapshot = state.steps;
    state = state.copyWith(isUpdatingStatus: true);
    try {
      await api.bulkCompleteOrderStatus(state.orderId);
      await _refreshSteps();
      state = state.copyWith(bulkSnapshot: () => snapshot, isUpdatingStatus: false);
      ref.read(vendorOrdersProvider.notifier).loadOrders();
      return true;
    } on ApiException {
      state = state.copyWith(isUpdatingStatus: false);
      return false;
    }
  }

  /// Restores the exact on/off pattern [markAllComplete] captured. Steps
  /// that go back "on" get a fresh timestamp (the moment of the undo, not
  /// their original one) — replaying the original times would require the
  /// backend to accept client-supplied timestamps, which isn't worth the
  /// integrity risk for what's fundamentally a same-session convenience
  /// action.
  Future<bool> undoMarkAllComplete() async {
    if (state.isUpdatingStatus || !state.hasOrder) return false;
    final snapshot = state.bulkSnapshot;
    if (snapshot == null) return false;

    state = state.copyWith(isUpdatingStatus: true);
    try {
      for (final status in kVendorToggleableStatuses) {
        final wasDone = snapshot.firstWhere((s) => s.status == status).done;
        final isDone = state.steps.firstWhere((s) => s.status == status).done;
        if (wasDone == isDone) continue;
        await api.updateOrderStatus(state.orderId, status, done: wasDone);
        await _refreshSteps();
      }
      state = state.copyWith(bulkSnapshot: () => null, isUpdatingStatus: false);
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
