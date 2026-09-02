/// One row from the backend's `order_tracking` table (GET /orders/{id} and
/// GET /vendor/orders/{id} → `tracking[]`): the moment an order reached a
/// given `orders.status` value.
class OrderTrackingEvent {
  const OrderTrackingEvent({required this.status, required this.title, this.completedAt});

  final String status;
  final String title;
  final DateTime? completedAt;
}
