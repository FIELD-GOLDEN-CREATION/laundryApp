import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/service_package.dart';

/// The vendor's own package list, authored on the Vendor Catalog screen.
///
/// Seeded from [packagesFor] against the vendor's shop (`kShops.first`), so
/// the catalog opens showing exactly what the customer already sees. Edits
/// here surface immediately on that shop's customer-facing Detail page —
/// the same "trace" the Vendor Settings screen already has for the shop
/// title, bio and hours.
class VendorPackagesNotifier extends Notifier<List<ServicePackage>> {
  @override
  List<ServicePackage> build() => packagesFor(kShops.first);

  void _replace(String id, ServicePackage Function(ServicePackage) update) {
    state = [
      for (final p in state)
        if (p.id == id) update(p) else p,
    ];
  }

  void toggleActive(String id) => _replace(id, (p) => p.copyWith(active: !p.active));

  /// Sets the headline price. The compare-at total is left alone: it is
  /// what the same basket costs per piece, which repricing the bundle does
  /// not change — so the savings percentage tracks the new price by itself.
  void setPrice(String id, double value) =>
      _replace(id, (p) => p.copyWith(priceTzs: value.clamp(0, double.infinity)));

  void addPackage(ServicePackage package) => state = [...state, package];

  void removePackage(String id) => state = [
    for (final p in state)
      if (p.id != id) p,
  ];
}

final vendorPackagesProvider =
    NotifierProvider<VendorPackagesNotifier, List<ServicePackage>>(VendorPackagesNotifier.new);

/// What the customer sees on the vendor's shop page — active packages only,
/// under the same display cap as every other shop.
List<ServicePackage> activeVendorPackages(List<ServicePackage> all) => [
  for (final p in all)
    if (p.active) p,
].take(kMaxShopPackages).toList();
