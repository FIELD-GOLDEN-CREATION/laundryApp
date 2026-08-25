import '../models/menu_item.dart';
import '../models/order_line.dart';
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

String formatMoney(double n) => formatTzs(n);
