import 'package:test/test.dart';

/// Matches a thrown error/exception by its message, tolerant of the exact type.
///
/// The backend throws a mix of Dart core errors (ArgumentError) and Serverpod
/// serializable exceptions (ArgumentException, FlumipFileNotFoundException,
/// FlumipFileNotFoundException, BedCreationException), all of which expose a
/// `message` field, plus plain `Exception('...')` values. This checks the
/// dynamic `.message` (exact or substring) and falls back to `toString()`, so
/// tests assert on the message without coupling to the specific type.
Matcher throwsMessage(String message) => throwsA(
  predicate((Object? e) {
    try {
      final dynamic m = (e as dynamic).message;
      if (m is String) return m == message || m.contains(message);
    } catch (_) {
      // No `.message` getter (e.g. plain Exception); fall through.
    }
    return e.toString().contains(message);
  }, 'throws something whose message contains "$message"'),
);
