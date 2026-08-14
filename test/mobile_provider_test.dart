import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/data/mock_data.dart';

void main() {
  test('detectMobileProvider maps each Tanzanian prefix to its network', () {
    String? name(String number) => detectMobileProvider(number)?.name;

    // Vodacom M-Pesa
    expect(name('0714111222'), 'M-Pesa');
    expect(name('0744111222'), 'M-Pesa');
    expect(name('0754111222'), 'M-Pesa');
    expect(name('0764111222'), 'M-Pesa');

    // Airtel
    expect(name('0684111222'), 'Airtel Money');
    expect(name('0694111222'), 'Airtel Money');
    expect(name('0784111222'), 'Airtel Money');
    expect(name('0794111222'), 'Airtel Money');

    // Halotel (HaloPesa)
    expect(name('0614111222'), 'HaloPesa');
    expect(name('0624111222'), 'HaloPesa');

    // Yas (Mixx by Yas)
    expect(name('0664111222'), 'Mixx By Yas');
    expect(name('0774111222'), 'Mixx By Yas');
  });

  test('detectMobileProvider returns null until three digits are entered', () {
    expect(detectMobileProvider(''), isNull);
    expect(detectMobileProvider('0'), isNull);
    expect(detectMobileProvider('07'), isNull);
    expect(detectMobileProvider('074'), isNotNull);
  });

  test('detectMobileProvider ignores non-digit formatting', () {
    expect(detectMobileProvider('0754 111 222')?.name, 'M-Pesa');
    expect(detectMobileProvider('0774-111-222')?.name, 'Mixx By Yas');
  });
}
