import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ports the source's `addr`, `day`, `slot`, `note` fields.
class ScheduleState {
  const ScheduleState({this.addrIndex = 0, this.dayIndex = 1, this.slotIndex = 1, this.note = ''});

  final int addrIndex;
  final int dayIndex;
  final int slotIndex;
  final String note;

  ScheduleState copyWith({int? addrIndex, int? dayIndex, int? slotIndex, String? note}) => ScheduleState(
    addrIndex: addrIndex ?? this.addrIndex,
    dayIndex: dayIndex ?? this.dayIndex,
    slotIndex: slotIndex ?? this.slotIndex,
    note: note ?? this.note,
  );
}

class ScheduleNotifier extends Notifier<ScheduleState> {
  @override
  ScheduleState build() => const ScheduleState();

  void pickAddress(int i) => state = state.copyWith(addrIndex: i);
  void pickDay(int i) => state = state.copyWith(dayIndex: i);
  void pickSlot(int i) => state = state.copyWith(slotIndex: i);
  void setNote(String note) => state = state.copyWith(note: note);
}

final scheduleProvider = NotifierProvider<ScheduleNotifier, ScheduleState>(ScheduleNotifier.new);
