import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/error_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure tests: no widgets, no client, no browser.
void main() {
  group('describeError', () {
    test('uses the message from an access refusal', () {
      expect(
        describeError(ProjectAccessDeniedException(message: 'Not your project')),
        'Not your project',
      );
    });

    test('does not leak the exception class name into the message', () {
      // The point of the helper. Interpolating the exception directly, which is
      // what every call site did before, yields its toString() — wrapper class
      // included — instead of the sentence the server wrote.
      final described = describeError(ProjectAccessDeniedException());
      expect(described, isNot(contains('Exception')));
      expect(described, isNot(contains('Instance of')));
      expect(described, contains('access'));
    });

    test('unwraps the other typed server exceptions', () {
      expect(
        describeError(FlumipFileNotFoundException(message: 'Project not found')),
        'Project not found',
      );
      expect(
        describeError(ArgumentException(message: 'Supplied gene empty')),
        'Supplied gene empty',
      );
      expect(
        describeError(BedCreationException(message: 'No genes')),
        'No genes',
      );
    });

    test('falls back to the plain string for anything unknown', () {
      // Guarantees that wrapping an existing call site can only improve it: an
      // error the helper does not recognise renders exactly as `'$e'` did.
      final error = StateError('something broke');
      expect(describeError(error), '$error');
      expect(describeError('a bare string'), 'a bare string');
    });
  });

  group('isAccessDenied', () {
    test('is true only for an access refusal', () {
      expect(isAccessDenied(ProjectAccessDeniedException()), isTrue);
      expect(
        isAccessDenied(FlumipFileNotFoundException(message: 'gone')),
        isFalse,
      );
      expect(isAccessDenied(StateError('transient')), isFalse);
    });

    test('separates permanent refusal from a retryable failure', () {
      // This is what the project tile keys its "stop the ten-second poll"
      // decision on, so a false positive would stop refreshing a healthy project
      // and a false negative would re-report the same refusal forever.
      expect(isAccessDenied(Exception('connection reset')), isFalse);
    });
  });
}
