import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:laundry_app/app.dart';

void main() {
  testWidgets('App boots on the Home tab', (tester) async {
    // Not pumpAndSettle: the home screen's pulse-ring animation repeats
    // forever, so "settled" never arrives.
    await tester.pumpWidget(const ProviderScope(child: LaundryApp()));
    await tester.pump(const Duration(milliseconds: 100));

    // Guests boot straight onto Home but see no tab bar and no pickup
    // address (both gated on login), so assert on content that is visible
    // to a guest: the search placeholder plus Home-only section headers.
    expect(find.text('Search services or shops'), findsOneWidget);
    expect(find.text('Just for you'), findsOneWidget);
    expect(find.text('Nearby shops'), findsOneWidget);
  });
}
