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
    required this.phone,
    this.imageUrl = '',
    this.photos = const [],
    this.latitude,
    this.longitude,
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

  /// Vendor contact number in international format (e.g. '+255754111222'),
  /// used to launch a phone call and a WhatsApp chat from Orders.
  final String phone;

  /// Storefront photo URL. Empty means "no photo yet" — the UI renders a
  /// styled placeholder via RemoteImage's fallback.
  final String imageUrl;

  /// The shop's uploaded gallery (vendor Settings → Shop photos), shown as
  /// an auto-advancing slideshow on the Detail screen's header. Empty means
  /// the header falls back to the single [imageUrl].
  final List<String> photos;

  /// GPS coordinates, when the backend has them — lets the UI resolve a
  /// real place name if [meta] turns out to be a stale raw coordinate pair.
  final double? latitude;
  final double? longitude;

  Shop copyWith({
    String? slotId,
    String? listSlotId,
    String? name,
    String? rating,
    String? meta,
    String? price,
    String? badge,
    String? reviewCount,
    String? distance,
    String? hours,
    String? description,
    List<String>? badges,
    List<String>? services,
    double? ratingValue,
    double? priceFromTzs,
    double? distanceKm,
    bool? is24h,
    bool? isOpenNow,
    String? phone,
    String? imageUrl,
    List<String>? photos,
    double? latitude,
    double? longitude,
  }) =>
      Shop(
        slotId: slotId ?? this.slotId,
        listSlotId: listSlotId ?? this.listSlotId,
        name: name ?? this.name,
        rating: rating ?? this.rating,
        meta: meta ?? this.meta,
        price: price ?? this.price,
        badge: badge ?? this.badge,
        reviewCount: reviewCount ?? this.reviewCount,
        distance: distance ?? this.distance,
        hours: hours ?? this.hours,
        description: description ?? this.description,
        badges: badges ?? this.badges,
        services: services ?? this.services,
        ratingValue: ratingValue ?? this.ratingValue,
        priceFromTzs: priceFromTzs ?? this.priceFromTzs,
        distanceKm: distanceKm ?? this.distanceKm,
        is24h: is24h ?? this.is24h,
        isOpenNow: isOpenNow ?? this.isOpenNow,
        phone: phone ?? this.phone,
        imageUrl: imageUrl ?? this.imageUrl,
        photos: photos ?? this.photos,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
      );
}
