/// [over] marks a vendor queue as overloaded — the screen swaps the card's
/// colors to the amber "heavy load" scheme when true.
class VendorLoadCard {
  const VendorLoadCard({required this.name, required this.volume, required this.queue, required this.pct, required this.over});

  final String name;
  final String volume;
  final String queue;
  final double pct;
  final bool over;
}
