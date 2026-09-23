/// A pre-bundled offer a vendor sells alongside the per-piece price list —
/// the customer picks one instead of counting garments item by item.
///
/// Three shapes cover how vendors actually bundle, and [PackageKind] names
/// them so the UI can pick the right icon/label without string matching.
enum PackageKind {
  /// Flat rate up to a weight limit in kilograms — no attached items.
  weight,

  /// A fixed set of attached items with quantities.
  itemCount,

  /// House cleaning: a number of rooms (each deep-cleaned) plus optional
  /// garden/yard maintenance. Price may be fixed or negotiable.
  household,
}

/// Bundled card photo per package kind. Pinterest hotlinks carry no CORS
/// headers, so web builds can't fetch them — the photos ship in the app
/// bundle instead and always render, online or off.
const kPackageKindImages = {
  PackageKind.weight: 'assets/images/package-weight.jpg',
  PackageKind.itemCount: 'assets/images/package-itemcount.jpg',
  PackageKind.household: 'assets/images/package-household.jpg',
};

/// Auto-sliding card photos per kind (first entry == the default above).
const kPackageKindSlideshows = {
  PackageKind.weight: [
    'assets/images/package-weight.jpg',
    'assets/images/pkg-weight-2.jpg',
    'assets/images/pkg-weight-3.jpg',
  ],
  PackageKind.itemCount: [
    'assets/images/package-itemcount.jpg',
    'assets/images/pkg-items-2.jpg',
    'assets/images/pkg-items-3.jpg',
    'assets/images/pkg-items-4.jpg',
    'assets/images/pkg-items-5.jpg',
  ],
  PackageKind.household: [
    'assets/images/package-household.jpg',
    'assets/images/pkg-household-2.jpg',
    'assets/images/pkg-household-3.jpg',
    'assets/images/pkg-household-4.jpg',
  ],
};

/// What every household room includes.
const kHouseholdRoomTasks = [
  'Deep cleaning the whole house',
  'Cleaning the windows',
  'Mopping the floor',
  'Cleaning the cupboards and tables',
  'Sofas',
];

/// Extra household services the vendor can offer (checkboxes in the form).
const kHouseholdExtraTasks = [
  'Sofa deep cleaning',
  'Washing and folding clothes',
];

/// A single line item inside a vendor-created package, pairing a laundry
/// item with its quantity. The customer sees these as "3× T-Shirt / Polo"
/// inside the package details.
class PackageItem {
  const PackageItem({
    required this.itemId,
    required this.itemName,
    required this.qty,
    required this.unitPrice,
  });

  final String itemId;
  final String itemName;
  final int qty;
  final double unitPrice;

  double get lineTotal => unitPrice * qty;

  PackageItem copyWith({int? qty}) => PackageItem(
    itemId: itemId,
    itemName: itemName,
    qty: qty ?? this.qty,
    unitPrice: unitPrice,
  );
}

class ServicePackage {
  const ServicePackage({
    required this.id,
    required this.name,
    required this.tagline,
    required this.kind,
    required this.priceTzs,
    required this.priceUnit,
    required this.inclusions,
    this.compareAtTzs,
    this.note = '',
    this.tag = '',
    this.serviceTags = const [],
    this.active = true,
    this.adminLocked = false,
    this.packageItems = const [],
    this.shopId = '',
    this.shopName = '',
    this.weightKg,
    this.rooms,
    this.gardenYard = false,
    this.priceNegotiable = false,
    this.imageUrl = '',
  });

  /// Stable slug, unique within a vendor's package list.
  final String id;

  /// Backend id of the vendor this package belongs to. Empty for
  /// vendor-side contexts that don't need to name their own shop.
  final String shopId;

  /// Vendor display name — used to point the basket at the right shop
  /// when a package is added from a cross-vendor listing (e.g. the home
  /// carousel), same as any other add-to-cart flow.
  final String shopName;

  final String name;

  /// One-line hook under the name, e.g. 'Up to 5kg of everyday wear'.
  final String tagline;

  final PackageKind kind;

  final double priceTzs;

  /// Suffix rendered after the price, e.g. '/ bag', '/ pack', '/ month'.
  final String priceUnit;

  /// What the bundle covers. The card renders at most
  /// [kMaxPackageInclusions] of these, so keep the list short and concrete.
  final List<String> inclusions;

  /// Single-item total this bundle undercuts. [savingsPercent] is derived
  /// from it, so a "Save 25%" pill can never drift from the actual price —
  /// leave it null and no savings are claimed at all.
  final double? compareAtTzs;

  /// Fine print: size limits, treatment notes, renewal terms.
  final String note;

  /// Optional pill copy, e.g. 'Popular'. Savings render their own pill.
  final String tag;

  /// Which of a shop's [Shop.services] this package belongs to, matched
  /// loosely ('iron' matches 'Ironing'). Empty means "offer it everywhere".
  final List<String> serviceTags;

  /// Vendors can retire a package without deleting it; inactive packages
  /// never reach the customer-facing shop page.
  final bool active;

  /// Set when an admin deactivated this package. While true, the vendor
  /// can still edit it but the backend rejects any attempt to flip [active]
  /// back on — only an admin re-activating clears it.
  final bool adminLocked;

  /// Specific items with quantities included in this package.
  /// Only itemCount packages carry these. Empty means the package is a
  /// generic bundle (weight) or a scoped service (household).
  final List<PackageItem> packageItems;

  /// Weight packages: flat rate for this many kilograms.
  final double? weightKg;

  /// Household packages: number of rooms in scope.
  final int? rooms;

  /// Household packages: garden/yard maintenance included.
  final bool gardenYard;

  /// When true the vendor settles the price with the customer (WhatsApp)
  /// instead of fixed checkout pricing.
  final bool priceNegotiable;

  /// True when no fixed price applies: flagged negotiable, or a zero
  /// amount. Display "Ask for price" and route to WhatsApp instead of
  /// showing TZS 0 anywhere.
  bool get isAskPrice => priceNegotiable || priceTzs <= 0;

  /// Card background photo. Empty falls back to the kind default.
  final String imageUrl;

  /// Photo to show behind the package card: the vendor photo when usable,
  /// otherwise the bundled kind photo (pinimg hotlinks are skipped — they
  /// carry no CORS headers so web builds can't fetch them).
  String get displayImage {
    if (imageUrl.isNotEmpty && !imageUrl.contains('pinimg.com')) {
      return imageUrl;
    }
    return kPackageKindImages[kind] ?? '';
  }

  /// Slideshow photos for the card: vendor photo first (when usable),
  /// then the bundled kind photos.
  List<String> get displayImages {
    if (imageUrl.isNotEmpty && !imageUrl.contains('pinimg.com')) {
      return [imageUrl, ...?kPackageKindSlideshows[kind]];
    }
    return kPackageKindSlideshows[kind] ?? [displayImage];
  }

  /// True when [displayImage] is a bundled asset rather than a URL.
  bool get displayImageIsAsset =>
      imageUrl.isEmpty || imageUrl.contains('pinimg.com');

  /// Avatar letter for the cart row, matching `MenuItem.initial`.
  String get initial => name.isEmpty ? 'P' : name[0].toUpperCase();

  /// Short human name for [kind], used on cart and vendor rows.
  String get kindLabel => switch (kind) {
    PackageKind.weight => 'Weight package',
    PackageKind.itemCount => 'Item package',
    PackageKind.household => 'House cleaning',
  };

  /// [priceUnit] phrased to sit after a label, e.g. '/ bag' -> 'per bag'.
  String get unitLabel =>
      priceUnit.startsWith('/ ') ? 'per ${priceUnit.substring(2)}' : priceUnit;

  /// The one-line subtitle a basket row shows under the package name.
  /// Deliberately short — `_CartRow` clips to a single line.
  String get cartSubtitle => '$kindLabel · $unitLabel';

  /// Whole-percent discount against [compareAtTzs], or null when there is
  /// nothing honest to claim.
  int? get savingsPercent {
    final compareAt = compareAtTzs;
    if (compareAt == null || compareAt <= priceTzs) return null;
    return ((compareAt - priceTzs) / compareAt * 100).round();
  }

  /// Cart key for this package at a given shop. Namespaced by shop so the
  /// same package bought from two vendors never collides, and prefixed
  /// `pkg:` the way service items use `svc:`.
  String cartKey(String shopSlotId) => 'pkg:$shopSlotId:$id';

  /// Substring match in both directions so 'iron' catches 'Ironing' and
  /// 'wash' catches 'Wash & fold'. An empty [serviceTags] matches anything.
  bool matchesServices(List<String> services) {
    if (serviceTags.isEmpty) return true;
    for (final tag in serviceTags) {
      final needle = tag.toLowerCase();
      for (final service in services) {
        final hay = service.toLowerCase();
        if (hay.contains(needle) || needle.contains(hay)) return true;
      }
    }
    return false;
  }

  ServicePackage copyWith({
    String? name,
    String? tagline,
    PackageKind? kind,
    double? priceTzs,
    String? priceUnit,
    List<String>? inclusions,
    double? compareAtTzs,
    String? note,
    String? tag,
    List<String>? serviceTags,
    bool? active,
    bool? adminLocked,
    List<PackageItem>? packageItems,
    double? weightKg,
    int? rooms,
    bool? gardenYard,
    bool? priceNegotiable,
    String? imageUrl,
  }) => ServicePackage(
    id: id,
    shopId: shopId,
    shopName: shopName,
    name: name ?? this.name,
    tagline: tagline ?? this.tagline,
    kind: kind ?? this.kind,
    priceTzs: priceTzs ?? this.priceTzs,
    priceUnit: priceUnit ?? this.priceUnit,
    inclusions: inclusions ?? this.inclusions,
    compareAtTzs: compareAtTzs ?? this.compareAtTzs,
    note: note ?? this.note,
    tag: tag ?? this.tag,
    serviceTags: serviceTags ?? this.serviceTags,
    active: active ?? this.active,
    adminLocked: adminLocked ?? this.adminLocked,
    packageItems: packageItems ?? this.packageItems,
    weightKg: weightKg ?? this.weightKg,
    rooms: rooms ?? this.rooms,
    gardenYard: gardenYard ?? this.gardenYard,
    priceNegotiable: priceNegotiable ?? this.priceNegotiable,
    imageUrl: imageUrl ?? this.imageUrl,
  );
}

/// Cards stay scannable at three or four bullets — past that the bundle
/// stops reading as one decision.
const kMaxPackageInclusions = 4;
