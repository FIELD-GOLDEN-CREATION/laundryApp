/// Stage in the vendor's fulfillment pipeline: 'new' (Incoming tab),
/// 'wip' (In progress), or 'ready' (Ready).
class VendorOrder {
  const VendorOrder({
    required this.id,
    required this.customer,
    required this.items,
    required this.dist,
    required this.priority,
    required this.chips,
    required this.when,
    required this.total,
    required this.stage,
    this.fulfillment = 'delivery',
    this.deliveryFeeTzs = 0,
    this.customerPhone = '',
    this.customerAddress = '',
    this.subtotalTzs = 0,
  });

  final String id;
  final String customer;
  final String items;
  final String dist;
  final String priority;
  final List<String> chips;
  final String when;
  final String total;
  final String stage;
  final String fulfillment;
  final int deliveryFeeTzs;
  final String customerPhone;
  final String customerAddress;
  final int subtotalTzs;

  VendorOrder copyWith({
    String? id,
    String? customer,
    String? items,
    String? dist,
    String? priority,
    List<String>? chips,
    String? when,
    String? total,
    String? stage,
    String? fulfillment,
    int? deliveryFeeTzs,
    String? customerPhone,
    String? customerAddress,
    int? subtotalTzs,
  }) =>
      VendorOrder(
        id: id ?? this.id,
        customer: customer ?? this.customer,
        items: items ?? this.items,
        dist: dist ?? this.dist,
        priority: priority ?? this.priority,
        chips: chips ?? this.chips,
        when: when ?? this.when,
        total: total ?? this.total,
        stage: stage ?? this.stage,
        fulfillment: fulfillment ?? this.fulfillment,
        deliveryFeeTzs: deliveryFeeTzs ?? this.deliveryFeeTzs,
        customerPhone: customerPhone ?? this.customerPhone,
        customerAddress: customerAddress ?? this.customerAddress,
        subtotalTzs: subtotalTzs ?? this.subtotalTzs,
      );
}
