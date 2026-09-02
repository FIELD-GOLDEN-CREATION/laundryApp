import '../models/menu_item.dart';
import '../models/order_line.dart';
import '../state/vendor_catalog_state.dart' show VendorAddon;
import 'currency.dart';

/// Pure cart math over the basket quantities and the item catalog the
/// customer is currently ordering from (per-piece menu + package/addon
/// "extra" lines). The catalog comes from whichever shop screen filled the
/// basket, so totals stay correct across vendors.

double cartSubtotal(Map<String, int> qty, [List<MenuItem> extra = const [], List<MenuItem> catalog = const []]) {
  var total = 0.0;
  for (final item in [...catalog, ...extra]) {
    total += item.price * (qty[item.key] ?? 0);
  }
  return total;
}

int cartItemCount(Map<String, int> qty, [List<MenuItem> extra = const [], List<MenuItem> catalog = const []]) {
  var total = 0;
  for (final item in [...catalog, ...extra]) {
    total += qty[item.key] ?? 0;
  }
  return total;
}

List<OrderLine> cartLines(Map<String, int> qty, List<MenuItem> extra, [List<MenuItem> catalog = const []]) => [
      for (final item in [...catalog, ...extra])
        if ((qty[item.key] ?? 0) > 0) OrderLine(name: item.name, qty: qty[item.key]!, unitPrice: item.price),
    ];

/// The one package id currently in the basket, or null if there isn't
/// exactly one — read from any `pkg:<shopId>:<packageId>` line with qty > 0
/// (see `ServicePackage.cartKey`), regardless of which screen added it.
///
/// This is what the backend's promo resolver needs as the order-level
/// `package_id`: it does a strict equality check against a package-scoped
/// promo's own target package, so an ambiguous basket (more than one
/// distinct package) can't correctly supply a single id — that's treated
/// the same as "none" rather than guessing, since a wrong guess and a
/// missing id fail identically anyway. Call this with the same `qty`/
/// `catalog` at promo preview time and at order placement so the two never
/// disagree about which package is being charged.
String? cartPackageId(Map<String, int> qty, List<MenuItem> catalog) {
  final ids = <String>{};
  for (final item in catalog) {
    if ((qty[item.key] ?? 0) <= 0) continue;
    if (!item.key.startsWith('pkg:')) continue;
    final id = item.key.split(':').last;
    if (id.isNotEmpty) ids.add(id);
  }
  return ids.length == 1 ? ids.first : null;
}

String formatMoney(double n) => formatTzs(n);

/// Sum of a basket's toggled add-ons, priced against whichever vendor's
/// add-on list [addons] is — the indices themselves carry no vendor
/// identity, so the caller must pass the same shop's list the indices were
/// toggled against (see `VendorBasket.selectedAddonIndices`).
double addonTotal(Set<int> indices, List<VendorAddon> addons) {
  var total = 0.0;
  for (final i in indices) {
    if (i >= 0 && i < addons.length) total += addons[i].priceTzs;
  }
  return total;
}

List<VendorAddon> selectedAddons(Set<int> indices, List<VendorAddon> addons) => [
      for (final i in indices)
        if (i >= 0 && i < addons.length) addons[i],
    ];
