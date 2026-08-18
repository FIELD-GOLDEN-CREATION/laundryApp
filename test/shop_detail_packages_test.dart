import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/data/mock_data.dart';
import 'package:laundry_app/models/shop.dart';
import 'package:laundry_app/screens/customer/shop_detail/shop_detail_screen.dart';
import 'package:laundry_app/state/cart_state.dart';
import 'package:laundry_app/state/fulfillment_state.dart';
import 'package:laundry_app/theme/app_theme.dart';

/// `google_fonts` cannot fetch Inter inside a test harness, so every string
/// renders in a fallback face that measures far wider than the real thing —
/// the shop's own rating/distance/hours row overflows a 360pt viewport by
/// 154pt under it. These tests are about ordering and basket behaviour, not
/// pixel widths, so the viewport is sized past that noise. `PackageCard`'s
/// own price row is a `Wrap` and reflows at any width regardless.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Pumps the Detail screen for [shop] on its own, off the router — enough to
/// exercise the packages section without booting the whole shell.
Future<ProviderContainer> _pumpDetail(WidgetTester tester, Shop shop) async {
  final container = ProviderContainer();
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

void main() {
  final marina = kShops.first;
  final brightAndFold = kShops.firstWhere((s) => s.name == 'Bright & Fold');

  testWidgets('packages sit between the shop bio and the price list', (tester) async {
    _useTallViewport(tester);

    await _pumpDetail(tester, marina);

    expect(find.text('Packages'), findsOneWidget);
    expect(find.text('Price list'), findsOneWidget);

    final packagesY = tester.getTopLeft(find.text('Packages')).dy;
    final priceListY = tester.getTopLeft(find.text('Price list')).dy;
    final bioY = tester.getTopLeft(find.text(marina.description)).dy;

    expect(packagesY, greaterThan(bioY));
    expect(packagesY, lessThan(priceListY));
  });

  testWidgets('selecting a package adds one priced line to the basket', (tester) async {
    _useTallViewport(tester);

    final container = await _pumpDetail(tester, marina);
    final package = packagesFor(marina).first;
    final key = package.cartKey(marina.slotId);

    await tester.tap(find.text('Select package').first);
    await tester.pump();

    expect(container.read(cartProvider)[key], 1);
    expect(container.read(fulfillmentProvider).extraItems[key]?.price, package.priceTzs);

    // The bundle's price reaches the sticky CTA, which used to price only
    // the per-piece menu and would have shown TZS 0 here.
    final extra = container.read(fulfillmentProvider).extraItems.values.toList();
    expect(cartSubtotal(container.read(cartProvider), extra), package.priceTzs);
    expect(find.text(formatMoney(package.priceTzs)), findsWidgets);

    // Second tap is a "view basket" affordance, not a duplicate purchase.
    expect(find.text('In basket · view'), findsOneWidget);
  });

  testWidgets('a second vendor asks before emptying the basket', (tester) async {
    _useTallViewport(tester);

    final container = await _pumpDetail(tester, marina);
    await tester.tap(find.text('Select package').first);
    await tester.pump();
    expect(container.read(fulfillmentProvider).shop, marina.name);

    // Now the same customer opens a different shop and picks a package.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: appTheme, home: ShopDetailScreen(shop: brightAndFold)),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Select package').first);
    await tester.pumpAndSettle();

    expect(find.text('Start a new basket?'), findsOneWidget);

    // Backing out leaves the first shop's basket exactly as it was.
    await tester.tap(find.text('Keep basket'));
    await tester.pumpAndSettle();
    expect(container.read(fulfillmentProvider).shop, marina.name);
    expect(container.read(cartProvider)[packagesFor(marina).first.cartKey(marina.slotId)], 1);

    // Confirming swaps the basket over to the new vendor.
    await tester.tap(find.text('Select package').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start new basket'));
    await tester.pumpAndSettle();

    expect(container.read(fulfillmentProvider).shop, brightAndFold.name);
    expect(container.read(cartProvider)[packagesFor(marina).first.cartKey(marina.slotId)] ?? 0, 0);
    expect(container.read(cartProvider)[packagesFor(brightAndFold).first.cartKey(brightAndFold.slotId)], 1);
  });
}
