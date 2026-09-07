import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shop.dart';
import 'catalog_state.dart' show kUnresolvedDistanceKm;

/// Search filter chips — UI configuration, not business data.
const kFilterOptions = [
  'Within 5 km',
  'Within 10 km',
  'Within 20 km',
  'Within 25 km',
  'Within 30 km',
  'Fast turnaround',
  'Open now',
  'Top rated',
];

class SearchState {
  const SearchState({this.query = '', this.filter = 'Nearby'});

  final String query;
  final String filter;

  SearchState copyWith({String? query, String? filter}) =>
      SearchState(query: query ?? this.query, filter: filter ?? this.filter);
}

/// Ports the source's `query`/`filter` fields.
class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  void setQuery(String query) => state = state.copyWith(query: query);
  void setFilter(String filter) => state = state.copyWith(filter: filter);
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);

/// Sorts by distance, always pushing shops with an unresolved distance
/// ([kUnresolvedDistanceKm] — no customer location known yet) to the end
/// regardless of direction, since a raw ascending sort would otherwise put
/// them first. Exposed for reuse by any other screen sorting shops by
/// distance (e.g. `service_vendors_screen.dart`).
int compareShopsByDistance(Shop a, Shop b) {
  final aResolved = a.distanceKm != kUnresolvedDistanceKm;
  final bResolved = b.distanceKm != kUnresolvedDistanceKm;
  if (aResolved != bResolved) return aResolved ? -1 : 1;
  if (!aResolved) return 0;
  return a.distanceKm.compareTo(b.distanceKm);
}

/// Applies the free-text query plus the active filter chip to [shops]. The
/// chips double as both a filter (price/24h/open now) and a sort (nearby/top
/// rated) depending on which one is active, matching the single-select chip
/// row on the Search screen.
List<Shop> filteredShops(List<Shop> shops, SearchState search) {
  var result = List.of(shops);

  final query = search.query.trim().toLowerCase();
  if (query.isNotEmpty) {
    result = result
        .where(
          (shop) =>
              shop.name.toLowerCase().contains(query) ||
              shop.services.any((service) => service.toLowerCase().contains(query)),
        )
        .toList();
  }

  bool withinKm(Shop shop, num maxKm) => shop.distanceKm != kUnresolvedDistanceKm && shop.distanceKm <= maxKm;

  switch (search.filter) {
    case 'Within 5 km':
      result = result.where((shop) => withinKm(shop, 5)).toList();
      result.sort(compareShopsByDistance);
    case 'Within 10 km':
      result = result.where((shop) => withinKm(shop, 10)).toList();
      result.sort(compareShopsByDistance);
    case 'Within 20 km':
      result = result.where((shop) => withinKm(shop, 20)).toList();
      result.sort(compareShopsByDistance);
    case 'Within 25 km':
      result = result.where((shop) => withinKm(shop, 25)).toList();
      result.sort(compareShopsByDistance);
    case 'Within 30 km':
      result = result.where((shop) => withinKm(shop, 30)).toList();
      result.sort(compareShopsByDistance);
    case 'Fast turnaround':
      result = result.where((shop) => shop.is24h).toList();
      result.sort(compareShopsByDistance);
    case 'Top rated':
      result.sort((a, b) => b.ratingValue.compareTo(a.ratingValue));
    case 'Under TZS 13,000':
      result = result.where((shop) => shop.priceFromTzs < 13000).toList();
      result.sort(compareShopsByDistance);
    case '24h':
      result = result.where((shop) => shop.is24h).toList();
      result.sort(compareShopsByDistance);
    case 'Open now':
      result = result.where((shop) => shop.isOpenNow).toList();
      result.sort(compareShopsByDistance);
    case 'Nearby':
    default:
      result.sort(compareShopsByDistance);
  }

  return result;
}
