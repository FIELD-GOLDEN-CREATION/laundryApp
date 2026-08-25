import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/models/menu_item.dart';
import 'package:laundry_app/utils/cart_math.dart';

const _catalog = [
  MenuItem(key: 'shirt', name: 'Shirts', unit: 'per piece', initial: 'S', price: 9100),
  MenuItem(key: 'trouser', name: 'Trousers', unit: 'per piece', initial: 'T', price: 11050),
  MenuItem(key: 'dress', name: 'Dress', unit: 'per piece', initial: 'D', price: 12500),
];

void main() {
  group('cart math', () {
    test('subtotal sums price * quantity across items', () {
      // shirt 2*9100 + trouser 1*11050 = 29250
      expect(cartSubtotal(const {'shirt': 2, 'trouser': 1}, [], _catalog), 29250.0);
    });

    test('item count sums all quantities', () {
      expect(cartItemCount(const {'shirt': 2, 'trouser': 1, 'dress': 1}, [], _catalog), 4);
    });

    test('missing keys default to zero', () {
      expect(cartSubtotal(const {}, [], _catalog), 0.0);
      expect(cartItemCount(const {}, [], _catalog), 0);
    });

    test('formatMoney formats whole shillings with thousands separators', () {
      expect(formatMoney(90350), 'TZS 90,350');
      expect(formatMoney(0), 'TZS 0');
    });
  });
}
