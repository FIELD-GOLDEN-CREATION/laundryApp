import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/data/mock_data.dart';

void main() {
  group('cart math', () {
    test('subtotal sums price * quantity across items', () {
      // shirt 2*9100 + trouser 1*11050 = 29250
      expect(cartSubtotal(const {'shirt': 2, 'trouser': 1}), 29250.0);
    });

    test('item count sums all quantities', () {
      expect(cartItemCount(const {'shirt': 2, 'trouser': 1, 'dress': 1}), 4);
    });

    test('missing keys default to zero', () {
      expect(cartSubtotal(const {}), 0.0);
      expect(cartItemCount(const {}), 0);
    });

    test('formatMoney formats whole shillings with thousands separators', () {
      expect(formatMoney(90350), 'TZS 90,350');
      expect(formatMoney(0), 'TZS 0');
    });
  });
}
