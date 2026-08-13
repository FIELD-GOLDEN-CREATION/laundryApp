import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shop.dart';

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

  switch (search.filter) {
    case 'Within 5 km':
      result = result.where((shop) => shop.distanceKm <= 5).toList();
      result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    case 'Within 10 km':
      result = result.where((shop) => shop.distanceKm <= 10).toList();
      result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    case 'Within 20 km':
      result = result.where((shop) => shop.distanceKm <= 20).toList();
      result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    case 'Within 25 km':
      result = result.where((shop) => shop.distanceKm <= 25).toList();
      result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    case 'Within 30 km':
      result = result.where((shop) => shop.distanceKm <= 30).toList();
      result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    case 'Fast turnaround':
      result = result.where((shop) => shop.is24h).toList();
      result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    case 'Top rated':
      result.sort((a, b) => b.ratingValue.compareTo(a.ratingValue));
    case 'Under TZS 13,000':
      result = result.where((shop) => shop.priceFromTzs < 13000).toList();
      result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    case '24h':
      result = result.where((shop) => shop.is24h).toList();
      result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    case 'Open now':
      result = result.where((shop) => shop.isOpenNow).toList();
      result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    case 'Nearby':
    default:
      result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }

  return result;
}
