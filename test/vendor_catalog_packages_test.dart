import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/models/laundry_category.dart';
import 'package:laundry_app/models/service_package.dart';
import 'package:laundry_app/screens/vendor/vendor_catalog_screen.dart';
import 'package:laundry_app/state/catalog_state.dart';
import 'package:laundry_app/state/vendor_packages_state.dart';
import 'package:laundry_app/theme/app_theme.dart';

/// The catalog reads the vendor's packages from an API-backed provider.
/// Seed it locally so these widget tests stay offline.
final _seededPackages = [
  ServicePackage(
    id: 'a',
    name: 'Starter Bag',
    tagline: 'Up to 5kg',
    kind: PackageKind.weight,
    priceTzs: 34000,
    priceUnit: '/ bag',
    inclusions: const [],
  ),
  ServicePackage(
    id: 'b',
    name: 'Family Bag',
    tagline: 'Up to 12kg',
    kind: PackageKind.weight,
    priceTzs: 58000,
    priceUnit: '/ bag',
    inclusions: const [],
  ),
];

class _SeededVendorPackages extends VendorPackagesNotifier {
  @override
  List<ServicePackage> build() => _seededPackages;
}

/// Inclusions are picked from the live catalog items now, so seed a small
/// menu matching the old static price rows the tests interact with.
const _seededCategories = [
  LaundryCategory(
    id: '1',
    name: 'Everyday Wear',
    nameSwahili: '',
    description: '',
    imageUrl: '',
    items: [
      LaundryItem(
        id: 'tshirt',
        name: 'T-Shirt / Polo',
        nameSwahili: '',
        description: '',
        imageUrl: '',
        priceTzs: 2250,
        unit: 'per piece',
      ),
      LaundryItem(
        id: 'sneakers',
        name: 'Sneakers',
        nameSwahili: '',
        description: '',
        imageUrl: '',
        priceTzs: 6000,
        unit: 'per pair',
      ),
    ],
  ),
];

class _SeededCategories extends CategoriesNotifier {
  @override
  AsyncCatalogState<LaundryCategory> build() =>
      const AsyncCatalogState(items: _seededCategories);
}

/// See `shop_detail_packages_test.dart` — Inter is unavailable in tests and
/// the fallback face measures much wider, so the viewport is oversized.
Future<ProviderContainer> _pumpCatalog(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 5000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(overrides: [
    vendorPackagesProvider.overrideWith(_SeededVendorPackages.new),
    categoriesProvider.overrideWith(_SeededCategories.new),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: appTheme, home: const VendorCatalogScreen()),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets('catalog lists the vendor\'s packages with an add affordance', (tester) async {
    final container = await _pumpCatalog(tester);

    expect(find.text('PACKAGES'), findsOneWidget);
    expect(find.text('+ Add package'), findsOneWidget);

    for (final package in container.read(vendorPackagesProvider)) {
      expect(find.text(package.name), findsOneWidget);
    }
  });

  testWidgets('pausing a package updates the live count shown to the vendor', (tester) async {
    final container = await _pumpCatalog(tester);
    final live = container.read(vendorPackagesProvider).length;
    expect(find.textContaining('of $live live'), findsOneWidget);

    container.read(vendorPackagesProvider.notifier).toggleActive(
      container.read(vendorPackagesProvider).first.id,
    );
    await tester.pump();

    expect(find.textContaining('of ${live - 1} live'), findsOneWidget);
  });

  testWidgets('the new-package sheet opens and stays inert until it can be sold', (tester) async {
    await _pumpCatalog(tester);

    await tester.tap(find.text('+ Add package'));
    await tester.pumpAndSettle();

    expect(find.text('New package'), findsOneWidget);
    expect(find.text('Save package'), findsOneWidget);

    // Name and price are both required, so a name alone is not enough.
    await tester.enterText(find.byType(TextField).first, 'Market Trader Bag');
    await tester.pump();
    await tester.tap(find.text('Save package'));
    await tester.pumpAndSettle();
    expect(find.text('New package'), findsOneWidget, reason: 'sheet should still be open');
  });

  testWidgets('a saved package reaches the vendor list', (tester) async {
    final container = await _pumpCatalog(tester);
    final before = container.read(vendorPackagesProvider).length;

    await tester.tap(find.text('+ Add package'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Market Trader Bag');
    await tester.enterText(fields.at(1), 'Up to 15kg of market stock');
    await tester.enterText(fields.at(2), '88000');
    await tester.enterText(fields.at(3), 'load');
    await tester.pump();

    // Inclusions are picked from the vendor's own menu pricing, not typed.
    await tester.tap(find.text('Select from your menu pricing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('T-Shirt / Polo'));
    await tester.pump();
    await tester.tap(find.text('Sneakers'));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save package'));
    await tester.pumpAndSettle();

    final packages = container.read(vendorPackagesProvider);
    expect(packages.length, before + 1);

    final created = packages.last;
    expect(created.name, 'Market Trader Bag');
    expect(created.priceTzs, 88000);
    expect(created.priceUnit, '/ load');
    expect(created.inclusions, ['T-Shirt / Polo', 'Sneakers']);
    // Nothing was claimed about a "was" price, so no savings badge appears.
    expect(created.savingsPercent, isNull);

    // And it is immediately what the customer would see on the shop page.
    expect(activeVendorPackages(packages).length, lessThanOrEqualTo(4));
    expect(find.text('Market Trader Bag'), findsOneWidget);
  });
}
