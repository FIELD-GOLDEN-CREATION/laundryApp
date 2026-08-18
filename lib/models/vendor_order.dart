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
    required this.address,
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

  /// Customer's pickup/delivery address — shown on the "Accept order" sheet's
  /// map/navigation section and the Vendor Order Detail screen.
  final String address;
}
