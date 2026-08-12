import 'package:flumip_server/src/services/search_service.dart';
import 'package:test/test.dart';

/// Pure tests: [escapeLikePattern] is a string function and needs no database.
///
/// Small, and the load-bearing tests for search. Serverpod inlines an `ILIKE`
/// pattern as a quoted SQL literal, so quoting is handled and escaping is not —
/// which makes this function the only thing standing between a typed `%` and a
/// match-all across three tables.
void main() {
  /// What the service actually sends, so the tests read the way the query does.
  String pattern(String query) => '%${escapeLikePattern(query)}%';

  group('escapeLikePattern', () {
    test('leaves ordinary text alone', () {
      expect(escapeLikePattern('BRCA1'), 'BRCA1');
      expect(escapeLikePattern('hg38 panel'), 'hg38 panel');
    });

    test('⚠️ a query of % cannot become a match-all', () {
      // Unescaped this is '%%%', which every row in the table matches. Escaped it
      // asks for rows containing a literal per cent sign, which is what was typed.
      expect(pattern('%'), r'%\%%');
    });

    test('underscore stops being a single-character wildcard', () {
      // Unescaped, `a_c` would match `abc`. It should match only `a_c`.
      expect(escapeLikePattern('a_c'), r'a\_c');
    });

    test('a backslash is escaped as itself', () {
      expect(escapeLikePattern(r'C:\data'), r'C:\\data');
    });

    test(
      '⚠️ the backslash is escaped first, so escapes are not re-escaped',
      () {
        // Wrong order (% before \) turns this into r'\\%' — a literal backslash
        // followed by a live wildcard, which is the bug this ordering prevents.
        expect(escapeLikePattern(r'\%'), r'\\\%');
      },
    );

    test('every metacharacter at once', () {
      expect(escapeLikePattern(r'100%_off\now'), r'100\%\_off\\now');
    });

    test('an empty query is unchanged', () {
      expect(escapeLikePattern(''), '');
    });
  });
}
