import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/models/service_package.dart';
import 'package:laundry_app/models/shop.dart';
import 'package:laundry_app/screens/customer/shop_detail/shop_detail_screen.dart';
import 'package:laundry_app/state/cart_state.dart';
import 'package:laundry_app/state/catalog_state.dart';
import 'package:laundry_app/state/fulfillment_state.dart';
import 'package:laundry_app/theme/app_theme.dart';
import 'package:laundry_app/utils/cart_math.dart';

const _marina = Shop(
  slotId: '4',
  listSlotId: 'marina-fresh',
  name: 'Marina Fresh Laundry',
  rating: '4.9',
  meta: '',
  price: '',
  badge: '',
  reviewCount: '312',
  distance: '',
  hours: 'Open till 8 PM',
  description: 'A family-run shop that has been washing for the neighbourhood since 2009.',
  badges: [],
  services: ['Wash & fold'],
  ratingValue: 4.9,
  priceFromTzs: 0,
  distanceKm: 1.2,
  is24h: false,
  isOpenNow: true,
  phone: '+255700000001',
);

const _brightAndFold = Shop(
  slotId: '5',
  listSlotId: 'bright-fold',
  name: 'Bright & Fold',
  rating: '4.7',
  meta: '',
  price: '',
  badge: '',
  reviewCount: '180',
  distance: '',
  hours: 'Open till 9 PM',
  description: 'Eco-friendly laundry service.',
  badges: [],
  services: ['Dry clean'],
  ratingValue: 4.7,
  priceFromTzs: 0,
  distanceKm: 2.4,
  is24h: false,
  isOpenNow: true,
  phone: '+255700000002',
);

ServicePackage _pkg(String id, double price) => ServicePackage(
  id: id,
  name: 'Bag $id',
  tagline: 'Up to 5kg',
  kind: PackageKind.weight,
  priceTzs: price,
  priceUnit: '/ bag',
  inclusions: const [],
);

/// The Detail screen reads its packages/price list from API-backed
/// providers. Override them locally so these widget tests stay offline.
/// Both shops are overridden upfront so repumping with a second shop
/// doesn't hit the real API (which hangs forever in tests).
List<Override> _seededOverrides() => [
  shopPackagesProvider(_marina.slotId).overrideWith((ref) async => [_pkg('p1', 34000)]),
  shopDetailProvider(_marina.listSlotId).overrideWith((ref) async => []),
  shopPackagesProvider(_brightAndFold.slotId).overrideWith((ref) async => [_pkg('p2', 40000)]),
  shopDetailProvider(_brightAndFold.listSlotId).overrideWith((ref) async => []),
];

/// `google_fonts` cannot fetch Inter inside a test harness, so every string
/// renders in a fallback face that measures far wider than the real thing —
/// These tests are about ordering and basket behaviour, not pixel widths, so
/// the viewport is sized past that noise.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Pumps the Detail screen for [shop] on its own, off the router.
Future<ProviderContainer> _pumpDetail(WidgetTester tester, Shop shop) async {
  final container = ProviderContainer(overrides: _seededOverrides());
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: appTheme, home: ShopDetailScreen(shop: shop)),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  return container;
}

Future<void> _openPackagesTab(WidgetTester tester) async {
  await tester.tap(find.text('Packages').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('About tab shows the bio; Packages tab shows the seeded packages', (tester) async {
    _useTallViewport(tester);

    await _pumpDetail(tester, _marina);

    // The screen opens on About — the shop bio is front and centre.
    expect(find.text(_marina.description), findsOneWidget);
    expect(find.text('Select package'), findsNothing);

    await _openPackagesTab(tester);

    expect(find.text('Select package'), findsOneWidget);
    expect(find.text(_marina.description), findsNothing);
  });

  testWidgets('selecting a package adds one priced line to the basket', (tester) async {
    _useTallViewport(tester);

    final container = await _pumpDetail(tester, _marina);
    await _openPackagesTab(tester);

    final package = container.read(shopPackagesProvider(_marina.slotId)).asData!.value.first;
    final key = package.cartKey(_marina.slotId);

    await tester.tap(find.text('Select package').first);
    await tester.pump();

    expect(container.read(cartProvider)[key], 1);
    expect(container.read(fulfillmentProvider).extraItems[key]?.price, package.priceTzs);

    // The bundle's price reaches the sticky CTA.
    final extra = container.read(fulfillmentProvider).extraItems.values.toList();
    expect(cartSubtotal(container.read(cartProvider), extra), package.priceTzs);

    // Second tap is a "view basket" affordance, not a duplicate purchase.
    expect(find.text('In basket · view'), findsOneWidget);
  });

  testWidgets('a second vendor asks before emptying the basket', (tester) async {
    _useTallViewport(tester);

    final container = await _pumpDetail(tester, _marina);
    await _openPackagesTab(tester);
    await tester.tap(find.text('Select package').first);
    await tester.pump();
    expect(container.read(fulfillmentProvider).shop, _marina.name);

    // Now the same customer opens a different shop and picks a package.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: appTheme, home: ShopDetailScreen(shop: _brightAndFold)),
      ),
    );
    await tester.pump();
    await _openPackagesTab(tester);
    await tester.tap(find.text('Select package').first);
    await tester.pumpAndSettle();

    expect(find.text('Start a new basket?'), findsOneWidget);

    // Backing out leaves the first shop's basket exactly as it was.
    await tester.tap(find.text('Keep basket'));
    await tester.pumpAndSettle();
    expect(container.read(fulfillmentProvider).shop, _marina.name);
    expect(container.read(cartProvider)[container.read(shopPackagesProvider(_marina.slotId)).asData!.value.first.cartKey(_marina.slotId)], 1);

    // Confirming swaps the basket over to the new vendor.
    await tester.tap(find.text('Select package').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start new basket'));
    await tester.pumpAndSettle();

    expect(container.read(fulfillmentProvider).shop, _brightAndFold.name);
    expect(container.read(cartProvider)[container.read(shopPackagesProvider(_marina.slotId)).asData!.value.first.cartKey(_marina.slotId)] ?? 0, 0);
    expect(container.read(cartProvider)[container.read(shopPackagesProvider(_brightAndFold.slotId)).asData!.value.first.cartKey(_brightAndFold.slotId)], 1);
  });
}
