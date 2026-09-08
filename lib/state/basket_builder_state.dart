import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/laundry_category.dart';
import '../models/menu_item.dart';
import '../models/shop.dart';
import 'catalog_state.dart';

// ── Draft: what the customer put in the basket ─────────────────────────────

class BasketBuilderState {
  const BasketBuilderState({this.quantities = const {}});

  /// Global catalog item id → qty.
  final Map<String, int> quantities;

  int get distinctCount => quantities.length;
  int get totalQty => quantities.values.fold(0, (s, q) => s + q);
  bool get isEmpty => quantities.isEmpty;
}

class BasketBuilderNotifier extends Notifier<BasketBuilderState> {
  @override
  BasketBuilderState build() => const BasketBuilderState();

  void toggle(String itemId) {
    final next = Map<String, int>.of(state.quantities);
    if (next.containsKey(itemId)) {
      next.remove(itemId);
    } else {
      next[itemId] = 1;
    }
    state = BasketBuilderState(quantities: next);
  }

  void setQty(String itemId, int delta) {
    final next = Map<String, int>.of(state.quantities);
    final qty = ((next[itemId] ?? 0) + delta).clamp(0, 999);
    if (qty == 0) {
      next.remove(itemId);
    } else {
      next[itemId] = qty;
    }
    state = BasketBuilderState(quantities: next);
  }

  void clear() => state = const BasketBuilderState();
}

final basketBuilderProvider =
    NotifierProvider<BasketBuilderNotifier, BasketBuilderState>(
        BasketBuilderNotifier.new);

// ── Quotes: per-vendor totals for the draft ────────────────────────────────

/// How vendor results are ordered. Best match gives cheapest price
/// priority (nearest distance breaks ties); cheapest / nearest sort by
/// that dimension only.
enum QuoteSort { recommended, cheapest, nearest }

extension QuoteSortLabel on QuoteSort {
  String get label {
    switch (this) {
      case QuoteSort.recommended:
        return 'Recommended';
      case QuoteSort.cheapest:
        return 'Cheapest';
      case QuoteSort.nearest:
        return 'Nearest';
    }
  }
}

class VendorQuote {
  const VendorQuote({
    required this.shop,
    required this.catalog,
    required this.prices,
    required this.totalTzs,
    required this.distanceKm,
    required this.matched,
    required this.total,
    required this.missingNames,
    this.isRecommended = false,
    this.isCheapest = false,
    this.isNearest = false,
  });

  /// The vendor.
  final Shop shop;

  /// The vendor's priced catalog (handed to the basket on select).
  final List<MenuItem> catalog;

  /// Global item id → vendor unit price (matched items only).
  final Map<String, double> prices;
  final double totalTzs;
  final double distanceKm;
  final int matched;
  final int total;
  final List<String> missingNames;
  final bool isRecommended;
  final bool isCheapest;
  final bool isNearest;

  bool get fullCoverage => matched == total && total > 0;
}

String vendorItemId(MenuItem item) {
  final parts = item.key.split(':');
  return parts.isEmpty ? item.key : parts.last;
}

/// Pure quote builder — every vendor that can price at least one selected
/// item, with cheapest/nearest/recommended flags assigned across the
/// fully-covering set.
List<VendorQuote> buildQuotes({
  required List<Shop> shops,
  required Map<String, int> selections,
  required Map<String, LaundryItem> itemById,
  required Map<String, List<MenuItem>> catalogBySlot,
}) {
  if (selections.isEmpty) return const [];

  final quotes = <VendorQuote>[];
  for (final shop in shops) {
    final catalog = catalogBySlot[shop.listSlotId] ?? const [];
    final prices = <String, double>{};
    for (final m in catalog) {
      final id = vendorItemId(m);
      if (selections.containsKey(id)) prices[id] = m.price;
    }
    if (prices.isEmpty) continue;

    var total = 0.0;
    final missing = <String>[];
    for (final entry in selections.entries) {
      final unit = prices[entry.key];
      if (unit == null) {
        missing.add(itemById[entry.key]?.name ?? 'Item');
      } else {
        total += unit * entry.value;
      }
    }
    quotes.add(VendorQuote(
      shop: shop,
      catalog: catalog,
      prices: prices,
      totalTzs: total,
      distanceKm: shop.distanceKm,
      matched: prices.length,
      total: selections.length,
      missingNames: missing,
    ));
  }

  // Flags across fully-covering vendors only.
  final full = quotes.where((q) => q.fullCoverage).toList();
  if (full.isNotEmpty) {
    VendorQuote cheapest = full.first;
    VendorQuote nearest = full.first;
    for (final q in full.skip(1)) {
      if (q.totalTzs < cheapest.totalTzs) cheapest = q;
      if (_dist(q) < _dist(nearest)) nearest = q;
    }
    // Best match = cheapest price gets priority, nearest distance breaks
    // ties — the nearest vendor among the cheapest totals wins.
    VendorQuote? recommended;
    for (final q in full) {
      if (recommended == null ||
          q.totalTzs < recommended.totalTzs ||
          (q.totalTzs == recommended.totalTzs && _dist(q) < _dist(recommended))) {
        recommended = q;
      }
    }
    for (var i = 0; i < quotes.length; i++) {
      final q = quotes[i];
      if (!q.fullCoverage) continue;
      quotes[i] = VendorQuote(
        shop: q.shop,
        catalog: q.catalog,
        prices: q.prices,
        totalTzs: q.totalTzs,
        distanceKm: q.distanceKm,
        matched: q.matched,
        total: q.total,
        missingNames: q.missingNames,
        isRecommended: identical(q, recommended),
        isCheapest: identical(q, cheapest),
        isNearest: identical(q, nearest),
      );
    }
  }
  return quotes;
}

/// Unknown distances sort last.
double _dist(VendorQuote q) => q.distanceKm < 0 ? 1e9 : q.distanceKm;

/// Full coverage first, then the requested ordering inside each group.
List<VendorQuote> sortQuotes(List<VendorQuote> quotes, QuoteSort sort) {
  final full = quotes.where((q) => q.fullCoverage).toList();
  final partial = quotes.where((q) => !q.fullCoverage).toList()
    ..sort((a, b) {
      final c = b.matched.compareTo(a.matched);
      if (c != 0) return c;
      return a.totalTzs.compareTo(b.totalTzs);
    });
  switch (sort) {
    case QuoteSort.cheapest:
      full.sort((a, b) => a.totalTzs.compareTo(b.totalTzs));
      break;
    case QuoteSort.nearest:
      full.sort((a, b) => _dist(a).compareTo(_dist(b)));
      break;
    case QuoteSort.recommended:
      full.sort((a, b) {
        if (a.isRecommended != b.isRecommended) return a.isRecommended ? -1 : 1;
        final c = a.totalTzs.compareTo(b.totalTzs);
        if (c != 0) return c;
        return _dist(a).compareTo(_dist(b));
      });
      break;
  }
  return [...full, ...partial];
}

// ── Async search over the vendor network ───────────────────────────────────

/// How many nearby vendors to price-check per search. Each check is one
/// cached public `GET /shops/:slug` call; twelve keeps results rich without
/// hammering the API on mobile data.
const kQuoteCandidateShops = 12;

class VendorQuotesNotifier extends Notifier<AsyncValue<List<VendorQuote>>> {
  @override
  AsyncValue<List<VendorQuote>> build() => const AsyncValue.loading();

  Future<void> search() async {
    state = const AsyncValue.loading();
    try {
      final draft = ref.read(basketBuilderProvider);
      if (draft.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }
      final categories = ref.read(categoriesProvider).items;
      final itemById = <String, LaundryItem>{
        for (final c in categories)
          for (final i in c.items) i.id: i,
      };

      // Nearest first (unknown distances last), then price-check the top N.
      final shops = [...ref.read(shopsWithDistanceProvider)]
        ..sort((a, b) => _shopDist(a).compareTo(_shopDist(b)));
      final candidates = shops.take(kQuoteCandidateShops).toList();

      final catalogBySlot = <String, List<MenuItem>>{};
      await Future.wait([
        for (final s in candidates)
          ref
              .read(shopDetailProvider(s.listSlotId).future)
              .then((items) => catalogBySlot[s.listSlotId] = items)
              .catchError((_) => catalogBySlot[s.listSlotId] = const <MenuItem>[]),
      ]);

      state = AsyncValue.data(buildQuotes(
        shops: candidates,
        selections: draft.quantities,
        itemById: itemById,
        catalogBySlot: catalogBySlot,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

double _shopDist(Shop s) => s.distanceKm < 0 ? 1e9 : s.distanceKm;

final vendorQuotesProvider =
    NotifierProvider<VendorQuotesNotifier, AsyncValue<List<VendorQuote>>>(
        VendorQuotesNotifier.new);
