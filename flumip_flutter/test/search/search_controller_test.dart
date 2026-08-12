import 'dart:async';

import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/search/search_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// The search box, with the server replaced by a closure.
///
/// Everything here uses `debounce: Duration.zero` and `pumpEventQueue()`: no test
/// in this repo advances a real timer, and the debounce interval itself is pinned
/// in `debounce_test.dart` rather than waited on here.
SearchHitDto hitFixture({
  SearchHitKind kind = SearchHitKind.project,
  int id = 1,
  String name = 'a hit',
  String subtitle = '',
  int? genomeId,
  String? category,
  String context = '',
}) => SearchHitDto(
  kind: kind,
  id: id,
  name: name,
  subtitle: subtitle,
  genomeId: genomeId,
  category: category,
  context: context,
);

/// A controller wired to a fake, with knobs for what the call does.
class Harness {
  Harness({this.hits = const []});

  List<SearchHitDto> hits;
  Object? searchThrows;

  /// Every query the controller actually sent. The point of most tests here is
  /// what is *not* in this list.
  final queries = <String>[];

  /// Set to gate an answer, so a slow reply can be made to land late.
  Completer<void>? gate;

  late final UnifiedSearchController controller = UnifiedSearchController(
    debounce: Duration.zero,
    search: (query) async {
      queries.add(query);
      if (gate != null) await gate!.future;
      if (searchThrows != null) throw searchThrows!;
      return hits;
    },
  );
}

void main() {
  group('asking as little as possible', () {
    test('a one-character query is not sent at all', () async {
      final h = Harness();

      h.controller.queryChanged('b');
      await pumpEventQueue();

      expect(h.queries, isEmpty);
      expect(h.controller.idle, isTrue);
      expect(h.controller.hits, isNull);
      // Not "loading": nothing has been asked, so nothing is outstanding.
      expect(h.controller.loading, isFalse);
    });

    test('whitespace does not count towards the minimum', () async {
      final h = Harness();

      h.controller.queryChanged('  b  ');
      await pumpEventQueue();

      expect(h.queries, isEmpty);
      expect(h.controller.idle, isTrue);
    });

    test('a typed word becomes one request, for the whole word', () async {
      final h = Harness();

      h.controller.queryChanged('br');
      h.controller.queryChanged('brc');
      h.controller.queryChanged('brca');
      await pumpEventQueue();

      expect(h.queries, ['brca']);
    });

    test('the query is sent trimmed', () async {
      final h = Harness();

      h.controller.queryChanged('  brca  ');
      await pumpEventQueue();

      expect(h.queries, ['brca']);
    });

    test(
      'a repeat query is answered from the cache, with no second call',
      () async {
        final h = Harness(hits: [hitFixture(name: 'BRCA panel')]);

        h.controller.queryChanged('brca');
        await pumpEventQueue();
        expect(h.queries, ['brca']);

        // Backspacing to a query that was never asked, then back to one that was.
        h.controller.queryChanged('brc');
        await pumpEventQueue();
        h.controller.queryChanged('brca');
        await pumpEventQueue();

        expect(h.queries, ['brca', 'brc']);
        expect(h.controller.hits, hasLength(1));
      },
    );

    test('a cache hit cancels the pending request', () async {
      final h = Harness(hits: [hitFixture()]);

      h.controller.queryChanged('brca');
      await pumpEventQueue();
      h.queries.clear();

      // Typed and then immediately reverted, within one debounce window.
      h.controller.queryChanged('brcax');
      h.controller.queryChanged('brca');
      await pumpEventQueue();

      expect(h.queries, isEmpty);
    });

    test('dropping below the minimum forgets the results', () async {
      final h = Harness(hits: [hitFixture()]);

      h.controller.queryChanged('brca');
      await pumpEventQueue();
      expect(h.controller.hits, hasLength(1));

      h.controller.queryChanged('b');
      expect(h.controller.hits, isNull);
      expect(h.controller.idle, isTrue);
    });
  });

  group('answers', () {
    test('nothing matched is not the same as no answer yet', () async {
      final h = Harness(hits: const []);

      h.controller.queryChanged('brca');
      expect(h.controller.hits, isNull, reason: 'no answer yet');
      expect(h.controller.loading, isTrue);

      await pumpEventQueue();

      expect(h.controller.hits, isEmpty, reason: 'nothing matched');
      expect(h.controller.loading, isFalse);
    });

    test(
      '⚠️ busy stays true for queries after the first, loading does not',
      () async {
        // The previous results are deliberately kept on screen while the next
        // answer is in flight, which makes `hits` non-null and `loading` false —
        // so a progress bar driven off `loading` would appear exactly once per
        // dialog. `busy` is what the bar is for.
        final h = Harness(hits: [hitFixture()]);

        h.controller.queryChanged('brca');
        await pumpEventQueue();
        expect(h.controller.loading, isFalse);
        expect(h.controller.busy, isFalse);

        h.gate = Completer<void>();
        h.controller.queryChanged('brca panel');
        await pumpEventQueue();

        expect(h.controller.busy, isTrue);
        expect(h.controller.loading, isFalse, reason: 'results are still up');
        expect(h.controller.hits, hasLength(1));

        h.gate!.complete();
        await pumpEventQueue();
        expect(h.controller.busy, isFalse);
      },
    );

    test('busy goes false when a request fails', () async {
      final h = Harness()..searchThrows = Exception('nope');

      h.controller.queryChanged('brca');
      await pumpEventQueue();

      expect(h.controller.busy, isFalse);
    });

    test('deleting the query stops it looking busy', () async {
      final h = Harness(hits: [hitFixture()]);
      h.gate = Completer<void>();

      h.controller.queryChanged('brca');
      await pumpEventQueue();
      expect(h.controller.busy, isTrue);

      h.controller.queryChanged('b');

      expect(h.controller.busy, isFalse);
    });

    test('hits are grouped by kind, in tab order', () async {
      final h = Harness(
        hits: [
          hitFixture(kind: SearchHitKind.project, id: 1, name: 'panel'),
          hitFixture(kind: SearchHitKind.snpSet, id: 2, name: 'calls'),
          hitFixture(kind: SearchHitKind.genome, id: 3, name: 'hg38'),
          hitFixture(kind: SearchHitKind.project, id: 4, name: 'panel 2'),
        ],
      );

      h.controller.queryChanged('anything');
      await pumpEventQueue();

      expect(h.controller.projects.map((x) => x.name), ['panel', 'panel 2']);
      expect(h.controller.genomes.map((x) => x.name), ['hg38']);
      expect(h.controller.snpSets.map((x) => x.name), ['calls']);
    });

    test(
      'firstHit is what Enter opens, and null when there is nothing',
      () async {
        final h = Harness(
          hits: [
            hitFixture(name: 'first'),
            hitFixture(id: 2),
          ],
        );

        expect(h.controller.firstHit, isNull);

        h.controller.queryChanged('brca');
        await pumpEventQueue();

        expect(h.controller.firstHit?.name, 'first');
      },
    );

    test('clear empties the field and the results', () async {
      final h = Harness(hits: [hitFixture()]);

      h.controller.queryChanged('brca');
      await pumpEventQueue();

      h.controller.clear();

      expect(h.controller.query, '');
      expect(h.controller.hits, isNull);
      expect(h.controller.idle, isTrue);
    });
  });

  group('failures and races', () {
    test('a failure lands in errorMessage', () async {
      final h = Harness()..searchThrows = Exception('server went away');

      h.controller.queryChanged('brca');
      await pumpEventQueue();

      expect(h.controller.errorMessage, contains('server went away'));
      expect(h.controller.loading, isFalse);
    });

    test('a later query clears an earlier failure', () async {
      final h = Harness(hits: [hitFixture()])
        ..searchThrows = Exception('transient');

      h.controller.queryChanged('brca');
      await pumpEventQueue();
      expect(h.controller.errorMessage, isNotNull);

      h.searchThrows = null;
      h.controller.queryChanged('brca2');
      await pumpEventQueue();

      expect(h.controller.errorMessage, isNull);
      expect(h.controller.hits, hasLength(1));
    });

    test('⚠️ a late answer for a superseded query is discarded', () async {
      // Without the guard, a slow answer for "br" overwrites the results for
      // "brca" — the search box's version of the bug
      // `GenomeController._refreshGenomes` documents.
      final h = Harness(hits: [hitFixture(name: 'stale')]);
      h.gate = Completer<void>();

      h.controller.queryChanged('br');
      await pumpEventQueue();

      // The user has moved on before the first answer lands.
      h.gate = null;
      h.hits = [hitFixture(name: 'fresh')];
      h.controller.queryChanged('brca');
      await pumpEventQueue();
      expect(h.controller.hits!.single.name, 'fresh');

      // Now let the first, slower call answer.
      h.controller.queryChanged('brca');
      await pumpEventQueue();

      expect(h.controller.hits!.single.name, 'fresh');
    });

    test(
      '⚠️ a late failure for a superseded query does not raise a banner',
      () async {
        final h = Harness(hits: [hitFixture(name: 'fine')]);
        h.gate = Completer<void>();
        h.searchThrows = Exception('slow failure');

        h.controller.queryChanged('br');
        await pumpEventQueue();

        h.gate = null;
        h.searchThrows = null;
        h.controller.queryChanged('brca');
        await pumpEventQueue();
        expect(h.controller.errorMessage, isNull);

        h.controller.queryChanged('brca');
        await pumpEventQueue();

        expect(h.controller.errorMessage, isNull);
        expect(h.controller.hits!.single.name, 'fine');
      },
    );

    test('⚠️ an answer landing after dispose does not throw', () async {
      final h = Harness(hits: [hitFixture()]);
      h.gate = Completer<void>();

      h.controller.queryChanged('brca');
      await pumpEventQueue();
      h.controller.dispose();

      h.gate!.complete();
      await pumpEventQueue();
      // Reaching here without an exception is the assertion: notifying a disposed
      // ChangeNotifier throws, and Flutter paints it over whatever is behind.
    });

    test('a pending request is dropped on dispose', () async {
      final h = Harness();

      h.controller.queryChanged('brca');
      h.controller.dispose();
      await pumpEventQueue();

      expect(h.queries, isEmpty);
    });
  });
}
