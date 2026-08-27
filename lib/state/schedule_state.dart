import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ports the source's `addr`, `day`, `slot`, `note` fields, extended with a
/// "use my current location" option. `addrIndex` selects a saved address
/// (0 = Home, 1 = Office); -1 means the GPS-resolved [currentLocation].
class ScheduleState {
  const ScheduleState({
    this.addrIndex = 0,
    this.dayIndex = 1,
    this.slotIndex = 1,
    this.note = '',
    this.currentLocation = '',
    this.currentLat,
    this.currentLng,
  });

  final int addrIndex;
  final int dayIndex;
  final int slotIndex;
  final String note;

  /// GPS-derived label used when [addrIndex] is -1.
  final String currentLocation;

  /// GPS coordinates behind [currentLocation] — needed for a real
  /// distance-based delivery quote, not just display.
  final double? currentLat;
  final double? currentLng;

  bool get isCurrentLocation => addrIndex == -1;

  ScheduleState copyWith({
    int? addrIndex,
    int? dayIndex,
    int? slotIndex,
    String? note,
    String? currentLocation,
    double? currentLat,
    double? currentLng,
  }) =>
      ScheduleState(
        addrIndex: addrIndex ?? this.addrIndex,
        dayIndex: dayIndex ?? this.dayIndex,
        slotIndex: slotIndex ?? this.slotIndex,
        note: note ?? this.note,
        currentLocation: currentLocation ?? this.currentLocation,
        currentLat: currentLat ?? this.currentLat,
        currentLng: currentLng ?? this.currentLng,
      );
}

class ScheduleNotifier extends Notifier<ScheduleState> {
  @override
  ScheduleState build() => const ScheduleState();

  void pickAddress(int i) => state = state.copyWith(addrIndex: i);
  void pickDay(int i) => state = state.copyWith(dayIndex: i);
  void pickSlot(int i) => state = state.copyWith(slotIndex: i);
  void setNote(String note) => state = state.copyWith(note: note);
  void setCurrentLocation(String label, {double? lat, double? lng}) =>
      state = state.copyWith(addrIndex: -1, currentLocation: label, currentLat: lat, currentLng: lng);
}

final scheduleProvider = NotifierProvider<ScheduleNotifier, ScheduleState>(ScheduleNotifier.new);
