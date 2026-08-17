import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/data/mock_data.dart';
import 'package:laundry_app/models/menu_item.dart';
import 'package:laundry_app/models/service_package.dart';
import 'package:laundry_app/state/basket_helper.dart';
import 'package:laundry_app/state/cart_state.dart';
import 'package:laundry_app/state/fulfillment_state.dart';
import 'package:laundry_app/state/vendor_packages_state.dart';

ServicePackage _package({
  String id = 'p1',
  double priceTzs = 100,
  double? compareAtTzs,
  List<String> serviceTags = const [],
  bool active = true,
}) => ServicePackage(
  id: id,
  name: 'Test Bag',
  tagline: 'Up to 5kg',
  kind: PackageKind.weight,
  priceTzs: priceTzs,
  compareAtTzs: compareAtTzs,
  priceUnit: '/ bag',
  inclusions: const ['Washed', 'Folded'],
  serviceTags: serviceTags,
  active: active,
);

void main() {
  group('ServicePackage', () {
    test('savings percent is derived from the compare-at total', () {
      expect(_package(priceTzs: 34000, compareAtTzs: 45500).savingsPercent, 25);
      expect(_package(priceTzs: 195000, compareAtTzs: 260000).savingsPercent, 25);
    });

    test('savings percent is null when there is nothing to claim', () {
      expect(_package(compareAtTzs: null).savingsPercent, isNull);
      expect(_package(priceTzs: 100, compareAtTzs: 100).savingsPercent, isNull);
      expect(_package(priceTzs: 100, compareAtTzs: 90).savingsPercent, isNull);
    });

    test('cart key is namespaced by shop so two vendors never collide', () {
      final package = _package(id: 'student-bag');
      expect(package.cartKey('ld-p1'), 'pkg:ld-p1:student-bag');
      expect(package.cartKey('ld-p1'), isNot(package.cartKey('ld-p2')));
    });

    test('service matching is loose in both directions', () {
      expect(_package(serviceTags: ['wash']).matchesServices(['Wash & fold']), isTrue);
      expect(_package(serviceTags: ['iron']).matchesServices(['Ironing']), isTrue);
      expect(_package(serviceTags: ['suits']).matchesServices(['Suits']), isTrue);
      expect(_package(serviceTags: ['wash']).matchesServices(['Dry clean', 'Suits']), isFalse);
      expect(_package(serviceTags: []).matchesServices(['Anything']), isTrue);
    });

    test('cart subtitle stays short enough for a single-line basket row', () {
      expect(_package().cartSubtitle, 'Weight package · per bag');
    });
  });

  group('packagesFor', () {
    test('only offers packages the shop actually services', () {
      final crispCorner = kShops.firstWhere((s) => s.name == 'Crisp Corner');
      final ids = packagesFor(crispCorner).map((p) => p.id);

      // Dry clean and suits only — no wash-based bags or bedding.
      expect(ids, contains('suit-care'));
      expect(ids, isNot(contains('student-bag')));
      expect(ids, isNot(contains('bedding-refresh')));
    });

    test('universal packages reach every shop', () {
      for (final shop in kShops) {
        expect(packagesFor(shop).map((p) => p.id), contains('family-monthly'));
      }
    });

    test('never returns more than the display cap', () {
      for (final shop in kShops) {
        expect(packagesFor(shop).length, lessThanOrEqualTo(kMaxShopPackages));
      }
    });

    test('every seeded compare-at total actually beats the bundle price', () {
      for (final package in kServicePackages) {
        if (package.compareAtTzs == null) continue;
        expect(package.compareAtTzs, greaterThan(package.priceTzs), reason: package.id);
      }
    });
  });

  group('package in the basket', () {
    test('prices as an extra line alongside the per-piece menu', () {
      final package = _package(id: 'student-bag', priceTzs: 34000);
      final key = package.cartKey('ld-p1');
      final extra = [
        MenuItem(key: key, name: package.name, unit: package.cartSubtitle, initial: package.initial, price: package.priceTzs),
      ];

      // One package plus two shirts (9,100 each).
      expect(cartSubtotal({key: 1, 'shirt': 2}, extra), 52200.0);
      expect(cartItemCount({key: 1, 'shirt': 2}, extra), 3);
      expect(cartLines({key: 1}, extra).single.name, 'Test Bag');
    });

    test('is invisible to totals that forget the extras list', () {
      // Guards the Detail screen's CTA hint, which used to drop `extra`.
      final key = _package().cartKey('ld-p1');
      expect(cartSubtotal({key: 1}), 0.0);
    });
  });

  group('basketBelongsToOtherShop', () {
    const marina = FulfillmentState(shop: 'Marina Fresh Laundry');

    test('is false for an empty basket, whatever shop it was pointed at', () {
      expect(basketBelongsToOtherShop(const {}, marina, 'Bright & Fold'), isFalse);
      expect(basketBelongsToOtherShop(const {'shirt': 0}, marina, 'Bright & Fold'), isFalse);
    });

    test('is false when the basket already belongs to that shop', () {
      expect(basketBelongsToOtherShop(const {'shirt': 2}, marina, 'Marina Fresh Laundry'), isFalse);
    });

    test('is true when a filled basket belongs to someone else', () {
      expect(basketBelongsToOtherShop(const {'shirt': 2}, marina, 'Bright & Fold'), isTrue);
    });

    test('counts service and package lines, not just the menu', () {
      final fulfillment = marina.copyWith(
        extraItems: {'svc:x': const MenuItem(key: 'svc:x', name: 'Ironing', unit: 'per service', initial: 'I', price: 5000)},
      );
      expect(basketBelongsToOtherShop(const {'svc:x': 1}, fulfillment, 'Bright & Fold'), isTrue);
    });
  });

  group('basket state', () {
    test('clear empties the cart', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cartProvider.notifier).setQty('shirt', 3);
      container.read(cartProvider.notifier).clear();
      expect(container.read(cartProvider), isEmpty);
    });

    test('startBasketFor repoints the shop and drops the old vendor extras', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(fulfillmentProvider.notifier);
      notifier.addServiceItem(const MenuItem(key: 'svc:x', name: 'Ironing', unit: 'per service', initial: 'I', price: 5000));
      notifier.startBasketFor('Bright & Fold');

      expect(container.read(fulfillmentProvider).shop, 'Bright & Fold');
      expect(container.read(fulfillmentProvider).extraItems, isEmpty);
    });
  });

  group('vendor package authoring', () {
    test('seeds from what the vendor shop already shows customers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(vendorPackagesProvider).map((p) => p.id),
        packagesFor(kShops.first).map((p) => p.id),
      );
    });

    test('pausing a package pulls it off the customer shop page', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = container.read(vendorPackagesProvider).first;
      container.read(vendorPackagesProvider.notifier).toggleActive(first.id);

      expect(container.read(vendorPackagesProvider).first.active, isFalse);
      expect(activeVendorPackages(container.read(vendorPackagesProvider)).map((p) => p.id), isNot(contains(first.id)));
    });

    test('repricing moves the savings percentage with it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(vendorPackagesProvider.notifier);
      final target = container.read(vendorPackagesProvider).firstWhere((p) => p.compareAtTzs != null);
      final before = target.savingsPercent!;

      notifier.setPrice(target.id, target.priceTzs - 5000);
      final after = container.read(vendorPackagesProvider).firstWhere((p) => p.id == target.id);

      expect(after.priceTzs, target.priceTzs - 5000);
      expect(after.savingsPercent, greaterThan(before));
    });

    test('price never goes negative', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(vendorPackagesProvider.notifier);
      final id = container.read(vendorPackagesProvider).first.id;
      notifier.setPrice(id, -500);
      expect(container.read(vendorPackagesProvider).first.priceTzs, 0);
    });

    test('add and remove round-trip', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(vendorPackagesProvider.notifier);
      final before = container.read(vendorPackagesProvider).length;

      notifier.addPackage(_package(id: 'vendor-1'));
      expect(container.read(vendorPackagesProvider).length, before + 1);

      notifier.removePackage('vendor-1');
      expect(container.read(vendorPackagesProvider).map((p) => p.id), isNot(contains('vendor-1')));
    });
  });
}
