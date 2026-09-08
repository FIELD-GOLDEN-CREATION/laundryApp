import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/models/laundry_category.dart';
import 'package:laundry_app/models/menu_item.dart';
import 'package:laundry_app/models/shop.dart';
import 'package:laundry_app/state/basket_builder_state.dart';

LaundryItem item(String id, String name) => LaundryItem(
      id: id,
      name: name,
      nameSwahili: name,
      description: '',
      imageUrl: '',
      priceTzs: 0,
      unit: 'per piece',
    );

MenuItem vendor(String slug, String itemId, double price) => MenuItem(
      key: MenuItem.cartKey(slug, itemId),
      name: itemId,
      unit: 'per piece',
      initial: 'X',
      price: price,
    );

Shop shop(String slug, double km) => Shop(
      slotId: slug,
      listSlotId: slug,
      name: slug,
      rating: '4.5',
      meta: '',
      price: '',
      badge: '',
      reviewCount: '',
      distance: '',
      hours: '',
      description: '',
      badges: const [],
      services: const [],
      ratingValue: 4.5,
      priceFromTzs: 0,
      distanceKm: km,
      is24h: false,
      isOpenNow: true,
      phone: '',
      imageUrl: '',
      photos: const [],
      latitude: null,
      longitude: null,
    );

void main() {
  final items = {
    'shirt': item('shirt', 'Shirt'),
    'suit': item('suit', 'Suit'),
    'duvet': item('duvet', 'Duvet'),
  };
  const selections = {'shirt': 2, 'suit': 1};

  Map<String, List<MenuItem>> catalogs() => {
        'a': [vendor('a', 'shirt', 1000), vendor('a', 'suit', 5000)],
        'b': [vendor('b', 'shirt', 800), vendor('b', 'suit', 6000)],
        'c': [vendor('c', 'shirt', 900)],
      };

  List<Shop> shops() => [shop('a', 5.0), shop('b', 1.0), shop('c', 0.5)];

  group('buildQuotes', () {
    test('totals multiply vendor unit price by qty', () {
      final quotes = buildQuotes(
        shops: shops(),
        selections: selections,
        itemById: items,
        catalogBySlot: catalogs(),
      );
      final a = quotes.firstWhere((q) => q.shop.slotId == 'a');
      expect(a.totalTzs, 2 * 1000 + 5000);
      expect(a.fullCoverage, isTrue);
    });

    test('partial coverage flagged with missing names', () {
      final quotes = buildQuotes(
        shops: shops(),
        selections: selections,
        itemById: items,
        catalogBySlot: catalogs(),
      );
      final c = quotes.firstWhere((q) => q.shop.slotId == 'c');
      expect(c.fullCoverage, isFalse);
      expect(c.matched, 1);
      expect(c.missingNames, ['Suit']);
    });

    test('cheapest and nearest flags go to full-coverage vendors', () {
      final quotes = buildQuotes(
        shops: shops(),
        selections: selections,
        itemById: items,
        catalogBySlot: catalogs(),
      );
      // a: 7000 @5km, b: 7600 @1km → a cheapest, b nearest
      expect(quotes.firstWhere((q) => q.shop.slotId == 'a').isCheapest, isTrue);
      expect(quotes.firstWhere((q) => q.shop.slotId == 'b').isNearest, isTrue);
      // partial vendor c gets no flags
      final c = quotes.firstWhere((q) => q.shop.slotId == 'c');
      expect(c.isCheapest || c.isNearest || c.isRecommended, isFalse);
    });

    test('empty selections yield no quotes', () {
      expect(
        buildQuotes(shops: shops(), selections: {}, itemById: items, catalogBySlot: catalogs()),
        isEmpty,
      );
    });

    test('best match breaks price ties by nearest distance', () {
      final tieShops = [shop('d', 2.0), shop('e', 0.5)];
      final tieCatalogs = {
        'd': [vendor('d', 'shirt', 1000), vendor('d', 'suit', 5000)],
        'e': [vendor('e', 'shirt', 1000), vendor('e', 'suit', 5000)],
      };
      final quotes = buildQuotes(
        shops: tieShops,
        selections: selections,
        itemById: items,
        catalogBySlot: tieCatalogs,
      );
      expect(quotes.firstWhere((q) => q.shop.slotId == 'e').isRecommended, isTrue);
      expect(quotes.firstWhere((q) => q.shop.slotId == 'd').isRecommended, isFalse);
    });
  });

  group('sortQuotes', () {
    test('full coverage first, then requested order', () {
      final quotes = buildQuotes(
        shops: shops(),
        selections: selections,
        itemById: items,
        catalogBySlot: catalogs(),
      );
      final cheapest = sortQuotes(quotes, QuoteSort.cheapest);
      expect(cheapest.first.fullCoverage, isTrue);
      expect(cheapest.first.shop.slotId, 'a');
      expect(cheapest.last.shop.slotId, 'c');

      final nearest = sortQuotes(quotes, QuoteSort.nearest);
      expect(nearest.first.shop.slotId, 'b');

      final recommended = sortQuotes(quotes, QuoteSort.recommended);
      expect(recommended.first.isRecommended, isTrue);
    });
  });
}
