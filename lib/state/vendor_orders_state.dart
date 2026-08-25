import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vendor_order.dart';
import '../services/api_service.dart';
import '../utils/num_helper.dart';
import 'vendor_order_detail_state.dart';

class VendorOrdersState {
  const VendorOrdersState({
    this.tab = 0,
    this.orders = const [],
    this.isLoading = false,
    this.selectedId,
  });

  final int tab;
  final List<VendorOrder> orders;
  final bool isLoading;

  /// Raw API id of the order the vendor opened from the list, so the
  /// detail screen knows which one to fetch.
  final String? selectedId;

  List<VendorOrder> get newOrders => orders.where((o) => o.stage == 'new').toList();
  List<VendorOrder> get wipOrders => orders.where((o) => o.stage == 'wip').toList();
  List<VendorOrder> get readyOrders => orders.where((o) => o.stage == 'ready').toList();

  VendorOrdersState copyWith({
    int? tab,
    List<VendorOrder>? orders,
    bool? isLoading,
    String? selectedId,
  }) =>
      VendorOrdersState(
        tab: tab ?? this.tab,
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        selectedId: selectedId ?? this.selectedId,
      );
}

class VendorOrdersNotifier extends Notifier<VendorOrdersState> {
  @override
  VendorOrdersState build() => const VendorOrdersState();

  void pickTab(int i) => state = state.copyWith(tab: i);

  void openOrder(VendorOrder order) =>
      state = state.copyWith(selectedId: normalizeVendorOrderId(order.id));

  Future<void> loadOrders({String? stage}) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await api.getVendorOrders(stage: stage);
      final orders = data.map((j) => _fromJson(j)).toList();
      state = state.copyWith(orders: orders, isLoading: false);
    } on ApiException {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> acceptOrder(String orderId, {int? deliveryFeeTzs}) async {
    try {
      await api.acceptOrder(orderId, deliveryFeeTzs: deliveryFeeTzs);
      // Reload orders to reflect the change
      await loadOrders();
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<bool> rejectOrder(String orderId) async {
    try {
      await api.rejectOrder(orderId);
      await loadOrders();
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await api.updateOrderStatus(orderId, status);
      await loadOrders();
      return true;
    } on ApiException {
      return false;
    }
  }

  VendorOrder _fromJson(Map<String, dynamic> j) {
    return VendorOrder(
      id: j['id'] != null ? '#LD-${j['id']}' : (j['order_number'] as String? ?? ''),
      customer: j['customer_name'] as String? ?? '',
      items: j['items_summary'] as String? ?? '',
      dist: j['distance'] as String? ?? '',
      priority: j['priority'] as String? ?? 'Standard',
      chips: (j['tags'] as List?)?.cast<String>() ?? [],
      when: j['status_text'] as String? ?? '',
      total: j['total'] != null ? 'TZS ${j['total']}' : (j['total_tzs']?.toString() ?? ''),
      stage: j['stage'] as String? ?? 'new',
      fulfillment: j['fulfillment'] as String? ?? 'delivery',
      deliveryFeeTzs: parseInt(j['delivery_fee']) ?? 0,
      customerPhone: j['customer_phone'] as String? ?? '',
      customerAddress: j['delivery_address'] as String? ?? '',
      subtotalTzs: parseInt(j['subtotal']) ?? 0,
    );
  }
}

final vendorOrdersProvider =
    NotifierProvider<VendorOrdersNotifier, VendorOrdersState>(VendorOrdersNotifier.new);
