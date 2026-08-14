import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:laundry_app/app.dart';

void main() {
  testWidgets('App boots on the Home tab', (tester) async {
    // Not pumpAndSettle: the home screen's pulse-ring animation repeats
    // forever, so "settled" never arrives.
    await tester.pumpWidget(const ProviderScope(child: LaundryApp()));
    await tester.pump(const Duration(milliseconds: 100));

    // Guests boot straight onto Home and see the customer tab bar, but no
    // pickup address (which remains gated on login).
    expect(find.text('Search services or shops'), findsOneWidget);
    expect(find.text('Just for you'), findsOneWidget);
    expect(find.text('Nearby shops'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
