/// A pre-bundled offer a vendor sells alongside the per-piece price list —
/// the customer picks one instead of counting garments item by item.
///
/// Four shapes cover how vendors actually bundle, and [PackageKind] names
/// them so the UI can pick the right icon/label without string matching.
enum PackageKind {
  /// Flat rate up to a weight limit — everyday wash & fold.
  weight,

  /// A fixed number of garments, usually cleaned and ironed.
  itemCount,

  /// Bulky bedding/household items a home machine can't take.
  household,

  /// Recurring plan paid up front, priced per month.
  subscription,
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
  });

  /// Stable slug, unique within a vendor's package list.
  final String id;

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

  /// Avatar letter for the cart row, matching `MenuItem.initial`.
  String get initial => name.isEmpty ? 'P' : name[0].toUpperCase();

  /// Short human name for [kind], used on cart and vendor rows.
  String get kindLabel => switch (kind) {
    PackageKind.weight => 'Weight package',
    PackageKind.itemCount => 'Item package',
    PackageKind.household => 'Household package',
    PackageKind.subscription => 'Monthly plan',
  };

  /// [priceUnit] phrased to sit after a label, e.g. '/ bag' -> 'per bag'.
  String get unitLabel => priceUnit.startsWith('/ ') ? 'per ${priceUnit.substring(2)}' : priceUnit;

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
  }) => ServicePackage(
    id: id,
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
  );
}

/// Cards stay scannable at three or four bullets — past that the bundle
/// stops reading as one decision.
const kMaxPackageInclusions = 4;
