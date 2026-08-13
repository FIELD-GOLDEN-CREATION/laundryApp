import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminVendorDetailState {
  const AdminVendorDetailState({this.coordQuery = '-6.7924, 39.2083', this.locSaved = false});

  final String coordQuery;
  final bool locSaved;

  AdminVendorDetailState copyWith({String? coordQuery, bool? locSaved}) =>
      AdminVendorDetailState(coordQuery: coordQuery ?? this.coordQuery, locSaved: locSaved ?? this.locSaved);
}

/// Ports the source's `coordQuery`/`locSaved`.
class AdminVendorDetailNotifier extends Notifier<AdminVendorDetailState> {
  @override
  AdminVendorDetailState build() => const AdminVendorDetailState();

  void setCoordQuery(String v) => state = state.copyWith(coordQuery: v, locSaved: false);
  void locateMe() => state = state.copyWith(coordQuery: '-6.7735, 39.2695', locSaved: false);
  void saveLocation() => state = state.copyWith(locSaved: true);
}

final adminVendorDetailProvider = NotifierProvider<AdminVendorDetailNotifier, AdminVendorDetailState>(
  AdminVendorDetailNotifier.new,
);
