/// Card-display data for a shop, used on Home and Search. The `Shop` tapped
/// is threaded through to the Detail screen via go_router's `extra`, so the
/// `reviewCount`/`distance`/`hours`/`description`/`badges` fields below back
/// that per-vendor detail content instead of a single static page.
class Shop {
  const Shop({
    required this.slotId,
    required this.listSlotId,
    required this.name,
    required this.rating,
    required this.meta,
    required this.price,
    required this.badge,
    required this.reviewCount,
    required this.distance,
    required this.hours,
    required this.description,
    required this.badges,
    required this.services,
    required this.ratingValue,
    required this.priceFromTzs,
    required this.distanceKm,
    required this.is24h,
    required this.isOpenNow,
  });

  final String slotId;
  final String listSlotId;
  final String name;
  final String rating;
  final String meta;
  final String price;
  final String badge;

  /// Number of reviews behind [rating], e.g. '312'.
  final String reviewCount;

  /// Detail-header distance line, e.g. '1.2 km away'.
  final String distance;

  /// Detail-header hours line, e.g. 'Open till 8 PM'.
  final String hours;

  /// Longer blurb shown on the Detail screen.
  final String description;

  /// Detail-screen feature badges, e.g. ['Free pickup', '24h turnaround', 'Eco detergent'].
  final List<String> badges;

  /// Service tags this vendor offers, e.g. ['Wash & fold', 'Dry clean']. Backs
  /// text search on the Search screen.
  final List<String> services;

  /// Numeric form of [rating], used to sort by "Top rated".
  final double ratingValue;

  /// Numeric form of [price]'s lead figure, used by the "Under TZS x" filter.
  final double priceFromTzs;

  /// Numeric form of [distance], used to sort by "Nearby".
  final double distanceKm;

  /// Whether this vendor runs 24-hour turnaround, backs the "24h" filter.
  final bool is24h;

  /// Whether this vendor is open right now, backs the "Open now" filter.
  final bool isOpenNow;
}
