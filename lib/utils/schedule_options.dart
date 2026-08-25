import '../models/day_option.dart';

/// Delivery scheduling options — UI configuration, not business data.
/// Days are generated as the next 7 days so dates never go stale.

List<DayOption> upcomingDays() {
  const dows = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final now = DateTime.now();
  return [
    for (var i = 0; i < 7; i++)
      DayOption(dow: dows[now.add(Duration(days: i)).weekday - 1], num: '${now.add(Duration(days: i)).day}'),
  ];
}

const kTimeSlots = ['8 – 10 AM', '10 – 12 PM', '2 – 4 PM', '6 – 8 PM'];
