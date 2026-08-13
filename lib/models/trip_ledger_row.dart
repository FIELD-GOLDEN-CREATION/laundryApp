/// One row in the Wallet screen's "Trip breakdown" list.
class TripLedgerRow {
  const TripLedgerRow({
    required this.id,
    required this.date,
    required this.km,
    required this.base,
    required this.tip,
    required this.total,
  });

  final String id;
  final String date;
  final String km;
  final String base;
  final String tip;
  final String total;
}
