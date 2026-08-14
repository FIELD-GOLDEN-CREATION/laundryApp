class OrderLine {
  const OrderLine({required this.name, required this.qty, required this.unitPrice});

  final String name;
  final int qty;
  final double unitPrice;

  double get total => unitPrice * qty;
}
