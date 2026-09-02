class MenuItem {
  const MenuItem({
    required this.key,
    required this.name,
    required this.unit,
    required this.initial,
    required this.price,
  });

  final String key;
  final String name;
  final String unit;
  final String initial;
  final double price;

  /// Cart key for a per-piece catalog item at a given shop. Namespaced by
  /// shop (slug) so the same catalog item sold by two vendors never
  /// collides in the basket — mirrors `ServicePackage.cartKey`, which does
  /// the same for packages.
  static String cartKey(String shopSlug, String itemId) => 'itm:$shopSlug:$itemId';
}
