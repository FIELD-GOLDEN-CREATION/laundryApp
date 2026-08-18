import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminOrdersState {
  const AdminOrdersState({this.range = 1, this.hour = 0, this.dateFrom = '06 Aug 2026', this.dateTo = '12 Aug 2026'});

  final int range;
  final int hour;
  final String dateFrom;
  final String dateTo;

  AdminOrdersState copyWith({int? range, int? hour, String? dateFrom, String? dateTo}) => AdminOrdersState(
    range: range ?? this.range,
    hour: hour ?? this.hour,
    dateFrom: dateFrom ?? this.dateFrom,
    dateTo: dateTo ?? this.dateTo,
  );
}

/// Ports the source's `aRange`/`aHour`/`dateFrom`/`dateTo`.
class AdminOrdersNotifier extends Notifier<AdminOrdersState> {
  @override
  AdminOrdersState build() => const AdminOrdersState();

  void pickRange(int i) => state = state.copyWith(range: i);
  void pickHour(int i) => state = state.copyWith(hour: i);
  void setDateFrom(String v) => state = state.copyWith(dateFrom: v);
  void setDateTo(String v) => state = state.copyWith(dateTo: v);
}

final adminOrdersProvider = NotifierProvider<AdminOrdersNotifier, AdminOrdersState>(AdminOrdersNotifier.new);
