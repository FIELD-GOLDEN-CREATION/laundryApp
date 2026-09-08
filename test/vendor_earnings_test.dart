import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/models/review_item.dart';
import 'package:laundry_app/state/vendor_earnings_state.dart';

EarningLine line(String label, double amount, DateTime date, {bool credit = true}) {
  return EarningLine(
    label: label,
    sub: 'order_payment · ${date.toIso8601String().substring(0, 10)}',
    amountTzs: amount,
    isCredit: credit,
    date: date.toIso8601String(),
  );
}

void main() {
  group('vendor earnings state', () {
    test('orderLines excludes commission and other non-credit rows', () {
      final now = DateTime.now();
      const state = VendorEarningsState();
      final withLines = state.copyWith(lines: [
        line('Order A-1', 10000, now),
        line('Commission', 1500, now, credit: false),
        line('Order A-2', 20000, now),
      ]);
      expect(withLines.orderLines.length, 2);
      expect(withLines.orderLines.every((l) => l.isCredit), isTrue);
    });

    test('week trend has 7 daily buckets ending today', () {
      final now = DateTime.now();
      final state = const VendorEarningsState().copyWith(lines: [
        line('Order A-1', 10000, now),
        line('Order A-2', 5000, now.subtract(const Duration(days: 1))),
        line('Old', 99999, now.subtract(const Duration(days: 30))),
      ]);
      final trend = state.trendFor(TrendRange.week);
      expect(trend.length, 7);
      expect(trend.last.amountTzs, 10000);
      expect(trend[5].amountTzs, 5000);
      expect(trend.first.amountTzs, 0);
    });

    test('month trend has 30 buckets, year trend has 12', () {
      final now = DateTime.now();
      final state = const VendorEarningsState().copyWith(lines: [
        line('Order A-1', 7000, now),
      ]);
      expect(state.trendFor(TrendRange.month).length, 30);
      final year = state.trendFor(TrendRange.year);
      expect(year.length, 12);
      expect(year.last.amountTzs, 7000);
    });

    test('rating summary counts per star and average', () {
      const state = VendorEarningsState(reviews: [
        ReviewItem(name: 'A', stars: '?????', text: 'Great'),
        ReviewItem(name: 'B', stars: '????', text: 'Good'),
        ReviewItem(name: 'C', stars: '????', text: 'Good'),
        ReviewItem(name: 'D', stars: '???', text: 'Ok'),
      ]);
      expect(state.starCounts[5], 1);
      expect(state.starCounts[4], 2);
      expect(state.starCounts[3], 1);
      expect(state.starCounts[2], 0);
      expect(state.starCounts[1], 0);
      expect(state.avgRating, closeTo(4.0, 0.001));
    });

    test('empty state yields zeros without crashing', () {
      const state = VendorEarningsState();
      expect(state.trendFor(TrendRange.week).length, 7);
      expect(state.trendFor(TrendRange.year).length, 12);
      expect(state.avgRating, 0);
      expect(state.starCounts.values.every((c) => c == 0), isTrue);
      expect(state.orderLines, isEmpty);
    });
  });
}
