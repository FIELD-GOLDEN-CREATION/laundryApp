import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/models/modal_copy.dart';

void main() {
  group('kModalCopy', () {
    test('has non-empty copy for every ModalKind', () {
      for (final kind in ModalKind.values) {
        final copy = kModalCopy[kind];
        expect(copy, isNotNull, reason: '$kind is missing from kModalCopy');
        expect(copy!.title, isNotEmpty, reason: '$kind has an empty title');
        expect(copy.sub, isNotEmpty, reason: '$kind has an empty sub');
        expect(copy.primary, isNotEmpty, reason: '$kind has an empty primary label');
        expect(copy.fields, isNotEmpty, reason: '$kind has no form fields');
      }
    });

    test('covers exactly the 8 admin actions with no extras', () {
      expect(kModalCopy.length, ModalKind.values.length);
    });
  });
}
