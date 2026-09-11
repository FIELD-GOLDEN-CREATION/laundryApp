import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/laundry_category.dart';
import '../models/menu_item.dart';
import '../models/shop.dart';
import '../utils/location.dart' show haversineKm;
import 'browse_location_state.dart';
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

/// How vendor results are ordered. Best match blends rating, price, and
/// distance into one score (see [kBestMatchRatingWeight] /
/// [kBestMatchPriceWeight] / [kBestMatchDistanceWeight]); cheapest / nearest
/// sort by that one dimension only.
enum QuoteSort { recommended, cheapest, nearest }

/// Weight given to rating vs. price vs. distance in the "Best match"
/// blended score. Rating dominates — outweighing price and distance even
/// combined (0.6 > 0.25 + 0.15) — since a vendor customers consistently
/// rate well beats one that's merely cheaper or closer; price matters more
/// than distance among what's left. Weights sum to 1.
const kBestMatchRatingWeight = 0.6;
const kBestMatchPriceWeight = 0.25;
const kBestMatchDistanceWeight = 0.15;

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
    this.matchScore = 0,
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

  /// Blended rating+price+distance score used by "Best match" (see
  /// [kBestMatchRatingWeight]) — lower is better, computed across every
  /// quote regardless of [fullCoverage].
  final double matchScore;
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
/// item, with cheapest/nearest/recommended (blended rating+price+distance)
/// flags assigned across the whole result set; coverage doesn't gate
/// eligibility, it's surfaced separately via [VendorQuote.fullCoverage].
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

  // Cheapest/nearest/recommended are absolute facts about the whole result
  // set — coverage doesn't gate eligibility, it's surfaced separately via
  // the "X/Y items" badge (see [VendorQuote.fullCoverage]) so a vendor
  // missing an item can still legitimately be the cheapest or best match.
  if (quotes.isNotEmpty) {
    VendorQuote cheapest = quotes.first;
    VendorQuote nearest = quotes.first;
    for (final q in quotes.skip(1)) {
      if (q.totalTzs < cheapest.totalTzs) cheapest = q;
      if (_dist(q) < _dist(nearest)) nearest = q;
    }
    final scores = _bestMatchScores(quotes);
    VendorQuote recommended = quotes.first;
    for (final q in quotes.skip(1)) {
      if (scores[q]! < scores[recommended]!) recommended = q;
    }
    for (var i = 0; i < quotes.length; i++) {
      final q = quotes[i];
      quotes[i] = VendorQuote(
        shop: q.shop,
        catalog: q.catalog,
        prices: q.prices,
        totalTzs: q.totalTzs,
        distanceKm: q.distanceKm,
        matched: q.matched,
        total: q.total,
        missingNames: q.missingNames,
        matchScore: scores[q]!,
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

/// Min-max normalizes [value] into its [0, 1] position between [lo] and
/// [hi] — 0 = best, 1 = worst. A pool with no spread normalizes everything
/// to 0 so that dimension stops influencing the blend instead of dividing
/// by zero.
double _normalize(double value, double lo, double hi) => hi > lo ? (value - lo) / (hi - lo) : 0.0;

/// Blended rating+price+distance score for every quote in [pool] (coverage
/// plays no part — a vendor missing an item competes on equal footing),
/// normalized against that pool alone — lower is better. Vendors with
/// unresolved distance (no browse location set, or the shop itself lacks
/// coordinates) score worst on that dimension, so "unknown" never outranks
/// "known-near".
Map<VendorQuote, double> _bestMatchScores(List<VendorQuote> pool) {
  if (pool.isEmpty) return {};
  final prices = pool.map((q) => q.totalTzs);
  final minPrice = prices.reduce(math.min);
  final maxPrice = prices.reduce(math.max);

  final ratings = pool.map((q) => q.shop.ratingValue);
  final minRating = ratings.reduce(math.min);
  final maxRating = ratings.reduce(math.max);

  final knownDistances = pool.map((q) => q.distanceKm).where((d) => d >= 0).toList();
  final minDist = knownDistances.isEmpty ? 0.0 : knownDistances.reduce(math.min);
  final maxDist = knownDistances.isEmpty ? 0.0 : knownDistances.reduce(math.max);

  return {
    for (final q in pool)
      q: // Rating is "higher is better" — invert so, like price/distance, 0 = best.
          (1 - _normalize(q.shop.ratingValue, minRating, maxRating)) * kBestMatchRatingWeight +
          _normalize(q.totalTzs, minPrice, maxPrice) * kBestMatchPriceWeight +
          (q.distanceKm < 0
                  ? (knownDistances.isEmpty ? 0.0 : 1.0)
                  : _normalize(q.distanceKm, minDist, maxDist)) *
              kBestMatchDistanceWeight,
  };
}

/// Orders every quote by the requested metric alone — coverage never gates
/// position (a vendor missing an item can rank above one with everything if
/// it wins on price/distance/blend); it's surfaced only via the "X/Y items"
/// badge on the card.
List<VendorQuote> sortQuotes(List<VendorQuote> quotes, QuoteSort sort) {
  final sorted = [...quotes];

  int byPrice(VendorQuote a, VendorQuote b) {
    final c = a.totalTzs.compareTo(b.totalTzs);
    return c != 0 ? c : b.matched.compareTo(a.matched);
  }

  int byDistance(VendorQuote a, VendorQuote b) {
    final c = _dist(a).compareTo(_dist(b));
    return c != 0 ? c : b.matched.compareTo(a.matched);
  }

  switch (sort) {
    case QuoteSort.cheapest:
      sorted.sort(byPrice);
      break;
    case QuoteSort.nearest:
      sorted.sort(byDistance);
      break;
    case QuoteSort.recommended:
      sorted.sort((a, b) => a.matchScore.compareTo(b.matchScore));
      break;
  }
  return sorted;
}

// ── Async search over the vendor network ───────────────────────────────────

/// How many nearby vendors to price-check per search. Each check is one
/// cached public `GET /shops/:slug` call; twelve keeps results rich without
/// hammering the API on mobile data.
const kQuoteCandidateShops = 12;

/// Floor on how long the loading state stays visible. Shop catalogs are
/// cached (see [shopDetailProvider]), so a repeat search against the same
/// nearby shops can resolve in a few milliseconds — too fast for the
/// skeleton to ever get painted. Padding every search out to this length
/// keeps the loading UI perceptible and consistent on every visit, not just
/// the first (cold) one.
const _kMinSearchDuration = Duration(milliseconds: 500);

class VendorQuotesNotifier extends AutoDisposeNotifier<AsyncValue<List<VendorQuote>>> {
  @override
  AsyncValue<List<VendorQuote>> build() => const AsyncValue.loading();

  /// Bumped on every [search] call so a slower, superseded call can tell
  /// it's stale and drop its result instead of overwriting a newer one —
  /// e.g. the auto-search fired on screen load (before the browse location
  /// has resolved) racing a re-search triggered moments later by the
  /// customer picking their address/GPS. Without this, whichever call's
  /// network fetches happen to finish last wins, even if it's the older,
  /// location-less one.
  int _generation = 0;

  Future<void> search() async {
    final generation = ++_generation;
    final loc = ref.read(browseLocationProvider);
    debugPrint('[VendorQuotes] #$generation start hasLocation=${loc.hasLocation} lat=${loc.lat} lng=${loc.lng}');
    state = const AsyncValue.loading();
    final stopwatch = Stopwatch()..start();
    try {
      final draft = ref.read(basketBuilderProvider);
      if (draft.isEmpty) {
        await _padToMinDuration(stopwatch);
        if (generation == _generation) state = const AsyncValue.data([]);
        return;
      }
      final categories = ref.read(categoriesProvider).items;
      final itemById = <String, LaundryItem>{
        for (final c in categories)
          for (final i in c.items) i.id: i,
      };

      // Nearest first (unknown distances last), then price-check the top N.
      // Computed directly from the raw shop list + [loc] here rather than
      // through [shopsWithDistanceProvider] — that provider is a separately
      // memoized `Provider` with no active watcher on this screen, and
      // reading it reentrantly (this whole call is itself a side effect of
      // a `browseLocationProvider` state change) could observe it before
      // it's recomputed for the new location. Reading the two primitives
      // directly can't go stale the same way.
      final rawShops = ref.read(shopsProvider).items;
      final shops = [
        for (final shop in rawShops)
          if (loc.hasLocation && shop.latitude != null && shop.longitude != null)
            shop.copyWith(distanceKm: haversineKm(shop.latitude!, shop.longitude!, loc.lat!, loc.lng!))
          else
            shop,
      ]..sort((a, b) => _shopDist(a).compareTo(_shopDist(b)));
      final candidates = shops.take(kQuoteCandidateShops).toList();

      final catalogBySlot = <String, List<MenuItem>>{};
      await Future.wait([
        for (final s in candidates)
          ref
              .read(shopDetailProvider(s.listSlotId).future)
              .then((items) => catalogBySlot[s.listSlotId] = items)
              .catchError((_) => catalogBySlot[s.listSlotId] = const <MenuItem>[]),
      ]);

      final quotes = buildQuotes(
        shops: candidates,
        selections: draft.quantities,
        itemById: itemById,
        catalogBySlot: catalogBySlot,
      );
      await _padToMinDuration(stopwatch);
      final stale = generation != _generation;
      debugPrint('[VendorQuotes] #$generation done stale=$stale '
          'distances=${quotes.map((q) => q.distanceKm.toStringAsFixed(1)).toList()}');
      if (!stale) state = AsyncValue.data(quotes);
    } catch (e, st) {
      await _padToMinDuration(stopwatch);
      debugPrint('[VendorQuotes] #$generation error: $e');
      if (generation == _generation) state = AsyncValue.error(e, st);
    }
  }

  Future<void> _padToMinDuration(Stopwatch stopwatch) async {
    final remaining = _kMinSearchDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
  }
}

double _shopDist(Shop s) => s.distanceKm < 0 ? 1e9 : s.distanceKm;

final vendorQuotesProvider =
    NotifierProvider.autoDispose<VendorQuotesNotifier, AsyncValue<List<VendorQuote>>>(
        VendorQuotesNotifier.new);
