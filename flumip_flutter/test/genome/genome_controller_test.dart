import 'dart:async';

import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/genome/genome_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// The genome tab's logic, with the server replaced by closures.
///
/// ⚠️ The poll, the failure backoff and the mutation guard are the reason this
/// file matters. All three were written to fix reported bugs — a tab rebuilding
/// twelve times a minute, a server outage hammered once a second, an Active
/// switch that flipped itself back — and none of them could be tested while they
/// lived in a `State` that imported `main.dart`.
Genome genomeFixture({
  int id = 1,
  String name = 'hg38',
  String category = 'Homo sapiens',
  bool indexed = false,
  bool indexing = false,
  bool active = true,
}) => Genome(
  id: id,
  name: name,
  description: '',
  category: category,
  path: '/opt/flumip/data/genomes/human/$name',
  size: 3_100_000_000,
  indexed: indexed,
  indexing: indexing,
  active: active,
);

class Harness {
  Harness({
    this.categories = const ['Homo sapiens'],
    List<Genome>? genomes,
    Genome? genome,
  }) : genomes = genomes ?? [genomeFixture()],
       genome = genome ?? genomeFixture() {
    _build();
  }

  List<String> categories;
  List<Genome> genomes;

  /// What `loadGenome` answers with next.
  Genome genome;

  Object? categoriesThrows;
  Object? genomesThrows;
  Object? genomeThrows;
  Object? indexThrows;
  Object? deleteIndexThrows;
  Object? updateThrows;
  Object? scanThrows;
  Object? recheckThrows;

  /// Held open so a test can decide when a call answers.
  Completer<Genome>? genomeGate;

  final calls = <String>[];
  final messages = <String>[];

  late final GenomeController controller;

  void _build() {
    controller = GenomeController(
      loadCategories: () async {
        calls.add('categories');
        if (categoriesThrows != null) throw categoriesThrows!;
        return categories;
      },
      loadGenomes: (category) async {
        calls.add('genomes $category');
        if (genomesThrows != null) throw genomesThrows!;
        return genomes;
      },
      loadGenome: (id) async {
        calls.add('genome $id');
        if (genomeGate != null) return genomeGate!.future;
        if (genomeThrows != null) throw genomeThrows!;
        return genome;
      },
      indexGenome: (id) async {
        calls.add('index $id');
        if (indexThrows != null) throw indexThrows!;
      },
      deleteIndex: (id) async {
        calls.add('deleteIndex $id');
        if (deleteIndexThrows != null) throw deleteIndexThrows!;
      },
      updateGenome: (id, g) async {
        calls.add('update $id active=${g.active}');
        if (updateThrows != null) throw updateThrows!;
      },
      scanForGenomes: () async {
        calls.add('scan');
        if (scanThrows != null) throw scanThrows!;
      },
      recheckSnpSets: () async {
        calls.add('recheck');
        if (recheckThrows != null) throw recheckThrows!;
      },
    );
    controller.messages.listen(messages.add);
  }
}

void main() {
  group('the rail', () {
    test('categories load, sorted', () async {
      final h = Harness(categories: ['Mus musculus', 'Homo sapiens']);

      await h.controller.load();

      expect(h.controller.categories, ['Homo sapiens', 'Mus musculus']);
      expect(h.controller.railError, isNull);
    });

    test('⚠️ sorts a copy, never the caller\'s list', () async {
      final h = Harness(categories: List.unmodifiable(['B', 'A']));

      await h.controller.load();

      expect(h.controller.categories, ['A', 'B']);
    });

    test('a failure lands on the rail, not the pane', () async {
      final h = Harness()..categoriesThrows = Exception('down');

      await h.controller.load();

      expect(h.controller.railError, isNotNull);
      expect(h.controller.detailError, isNull);
    });

    test('opening a category loads its genomes, sorted by name', () async {
      final h = Harness(
        genomes: [
          genomeFixture(id: 2, name: 'hs1'),
          genomeFixture(name: 'hg19'),
        ],
      );

      h.controller.toggleCategory('Homo sapiens');
      expect(h.controller.loadingCategory, 'Homo sapiens');
      await pumpEventQueue();

      expect(h.controller.genomes.map((g) => g.name), ['hg19', 'hs1']);
      expect(h.controller.loadingCategory, isNull);
    });

    test('closing a category empties the list without a fetch', () async {
      final h = Harness();
      h.controller.toggleCategory('Homo sapiens');
      await pumpEventQueue();
      h.calls.clear();

      h.controller.toggleCategory(null);
      await pumpEventQueue();

      expect(h.controller.genomes, isEmpty);
      expect(h.controller.expandedCategory, isNull);
      expect(h.calls, isEmpty);
    });

    test('⚠️ a late answer for a closed category is discarded', () async {
      // Otherwise the rail lists one category's genomes under another's
      // heading — the answer arrives after the user has moved on.
      final gate = Completer<List<Genome>>();
      final h = Harness();
      var pending = true;
      final controller = GenomeController(
        loadCategories: () async => const ['A', 'B'],
        loadGenomes: (category) async {
          if (pending) {
            pending = false;
            return gate.future;
          }
          return [genomeFixture(id: 9, name: 'other')];
        },
        loadGenome: (id) async => h.genome,
        indexGenome: (id) async {},
        deleteIndex: (id) async {},
        updateGenome: (id, g) async {},
        scanForGenomes: () async {},
        recheckSnpSets: () async {},
      );
      addTearDown(controller.dispose);

      controller.toggleCategory('A');
      controller.toggleCategory('B');
      await pumpEventQueue();
      gate.complete([genomeFixture(id: 1, name: 'stale')]);
      await pumpEventQueue();

      expect(controller.expandedCategory, 'B');
      expect(controller.genomes.map((g) => g.name), [
        'other',
      ], reason: "A's answer must not land in B's list");
    });

    test('a failed genome list is reported and stops the spinner', () async {
      final h = Harness()..genomesThrows = Exception('refused');

      h.controller.toggleCategory('Homo sapiens');
      await pumpEventQueue();

      expect(h.controller.loadingCategory, isNull);
      expect(h.controller.railError, contains('refused'));
    });
  });

  group('selecting a genome', () {
    test('shows it at once and then re-reads it', () async {
      final h = Harness(genome: genomeFixture(indexed: true));

      h.controller.selectGenome(genomeFixture());
      expect(h.controller.selectedGenome, isNotNull);
      await pumpEventQueue();

      expect(h.calls, contains('genome 1'));
      expect(h.controller.selectedGenome!.indexed, isTrue);
    });

    test('going back drops the selection and stops the poll', () async {
      final h = Harness(genome: genomeFixture(indexing: true));
      h.controller.selectGenome(genomeFixture());
      await pumpEventQueue();
      expect(h.controller.polling, isTrue);

      h.controller.clearSelection();

      expect(h.controller.selectedGenome, isNull);
      expect(h.controller.polling, isFalse);
    });
  });

  group('revealing a genome from a search result', () {
    test('it opens the category and selects the genome', () async {
      final h = Harness(genome: genomeFixture(id: 7, name: 'mm39'));
      await h.controller.load();

      await h.controller.revealGenome(7, 'Mus musculus');

      expect(h.controller.expandedCategory, 'Mus musculus');
      expect(h.controller.selectedGenome!.id, 7);
      // Selected by id, which is the point: the genome need not be in a category
      // anybody has opened, and most of them are not.
      expect(h.calls, contains('genome 7'));
      expect(h.calls, contains('genomes Mus musculus'));
    });

    test('⚠️ a null category leaves the rail alone', () async {
      // `toggleCategory(null)` *closes* the rail, which is the opposite of what
      // revealing wants — and a genome with no category is otherwise unreachable.
      final h = Harness(genome: genomeFixture(id: 7));
      await h.controller.load();
      h.controller.toggleCategory('Homo sapiens');
      await pumpEventQueue();

      await h.controller.revealGenome(7, null);

      expect(h.controller.expandedCategory, 'Homo sapiens');
      expect(h.controller.selectedGenome!.id, 7);
    });

    test('the already-open category is not re-fetched', () async {
      final h = Harness();
      await h.controller.load();
      h.controller.toggleCategory('Homo sapiens');
      await pumpEventQueue();
      h.calls.clear();

      await h.controller.revealGenome(1, 'Homo sapiens');

      expect(h.calls, ['genome 1']);
    });

    test('a failure lands on the detail banner, not the rail', () async {
      final h = Harness()..genomeThrows = Exception('genome is gone');
      await h.controller.load();

      await h.controller.revealGenome(7, 'Homo sapiens');

      expect(h.controller.detailError, contains('genome is gone'));
      expect(h.controller.railError, isNull);
    });
  });

  group('the poll', () {
    test('⚠️ runs only while an index is being built', () async {
      // It used to be Timer.periodic(5s) for as long as a genome was selected,
      // rebuilding the whole tab twelve times a minute for data that cannot
      // change on its own.
      final h = Harness(genome: genomeFixture(indexing: true));
      h.controller.selectGenome(genomeFixture());
      await pumpEventQueue();
      expect(h.controller.polling, isTrue, reason: 'indexing');

      h.genome = genomeFixture(indexed: true);
      await h.controller.refreshSelected();

      expect(h.controller.polling, isFalse, reason: 'finished; stop asking');
    });

    test('a quiet refresh does not put an error over the pane', () async {
      final h = Harness(genome: genomeFixture(indexing: true));
      h.controller.selectGenome(genomeFixture());
      await pumpEventQueue();

      h.genomeThrows = Exception('blip');
      await h.controller.refreshSelected(quiet: true);

      expect(h.controller.detailError, isNull);
    });

    test('a refresh the user asked for does', () async {
      final h = Harness()..genomeThrows = Exception('blip');
      h.controller.selectGenome(genomeFixture());
      await pumpEventQueue();

      expect(h.controller.detailError, contains('blip'));
    });

    test(
      '⚠️ a refused genome stops the poll rather than retrying forever',
      () async {
        final h = Harness(genome: genomeFixture(indexing: true));
        h.controller.selectGenome(genomeFixture());
        await pumpEventQueue();
        expect(h.controller.polling, isTrue);

        h.genomeThrows = ProjectAccessDeniedException(message: 'no');
        await h.controller.refreshSelected(quiet: true);

        expect(
          h.controller.polling,
          isFalse,
          reason: 'nothing changes while access is refused',
        );
      },
    );
  });

  group('indexing', () {
    test('starts, then re-reads the genome', () async {
      final h = Harness();
      h.controller.selectGenome(genomeFixture());
      await pumpEventQueue();
      h.calls.clear();

      await h.controller.indexGenome();

      expect(h.calls, ['index 1', 'genome 1']);
    });

    test('a failure is a message, not a banner', () async {
      // An action the user just took reports where they are looking.
      final h = Harness()..indexThrows = Exception('busy');
      h.controller.selectGenome(genomeFixture());
      await pumpEventQueue();

      await h.controller.indexGenome();
      await pumpEventQueue();

      expect(h.messages.single, contains('Could not start indexing'));
      expect(h.controller.detailError, isNull);
    });

    test('deleting the index goes through the same path', () async {
      final h = Harness();
      h.controller.selectGenome(genomeFixture());
      await pumpEventQueue();
      h.calls.clear();

      await h.controller.deleteIndex();

      expect(h.calls, ['deleteIndex 1', 'genome 1']);
    });

    test('nothing happens with no genome selected', () async {
      final h = Harness();
      await h.controller.indexGenome();
      expect(h.calls, isEmpty);
    });
  });

  group('the Active switch', () {
    test('moves at once and sends the new value', () async {
      final h = Harness();
      h.controller.selectGenome(genomeFixture(active: true));
      await pumpEventQueue();
      h.calls.clear();

      await h.controller.toggleActive(false);

      expect(h.controller.selectedGenome!.active, isFalse);
      expect(h.calls, ['update 1 active=false']);
    });

    test('⚠️ a refusal puts it back and says so', () async {
      // Without the rollback the switch stayed where the user left it even
      // though the server had refused, so the interface asserted something
      // untrue until the next poll happened to correct it.
      final h = Harness()..updateThrows = Exception('read only');
      h.controller.selectGenome(genomeFixture(active: true));
      await pumpEventQueue();

      await h.controller.toggleActive(false);

      expect(h.controller.selectedGenome!.active, isTrue);
      expect(h.controller.detailError, contains('read only'));
    });

    test('⚠️ a poll landing mid-change does not stomp the switch', () async {
      // The bug the mutation guard exists for. The old code had a ValueNotifier
      // the poll wrote to on every tick, which put the switch back to whatever
      // the server last said while the user's change was still in flight.
      final h = Harness();
      h.controller.selectGenome(genomeFixture(active: true));
      await pumpEventQueue();

      // A change starts and does not finish yet.
      final update = Completer<void>();
      final controller = GenomeController(
        loadCategories: () async => const [],
        loadGenomes: (_) async => const [],
        // The poll answers with the server's stale "active: true".
        loadGenome: (id) async => genomeFixture(active: true),
        indexGenome: (id) async {},
        deleteIndex: (id) async {},
        updateGenome: (id, g) => update.future,
        scanForGenomes: () async {},
        recheckSnpSets: () async {},
      );
      addTearDown(controller.dispose);
      controller.selectGenome(genomeFixture(active: true));
      await pumpEventQueue();

      final toggling = controller.toggleActive(false);
      await controller.refreshSelected(quiet: true);

      expect(
        controller.selectedGenome!.active,
        isFalse,
        reason: "the user's change wins over a poll in flight",
      );
      update.complete();
      await toggling;
    });
  });

  group('the library menu', () {
    test('scanning reloads the categories and the open one', () async {
      final h = Harness();
      h.controller.toggleCategory('Homo sapiens');
      await pumpEventQueue();
      h.calls.clear();

      await h.controller.scanForGenomes();
      await pumpEventQueue();

      expect(h.calls, ['scan', 'categories', 'genomes Homo sapiens']);
      expect(h.messages.single, 'Scanned for new genomes.');
    });

    test('rechecking SNP sets re-reads the selected genome', () async {
      final h = Harness();
      h.controller.selectGenome(genomeFixture());
      await pumpEventQueue();
      h.calls.clear();

      await h.controller.recheckSnpSets();
      await pumpEventQueue();

      expect(h.calls, ['recheck', 'genome 1']);
      expect(h.messages.single, 'Rechecked the custom SNP sets.');
    });

    test('a failed scan says so and changes nothing', () async {
      final h = Harness()..scanThrows = Exception('permission denied');

      await h.controller.scanForGenomes();
      await pumpEventQueue();

      expect(h.messages.single, contains('Could not scan for genomes'));
      expect(h.controller.railError, isNull);
    });
  });

  test('errors can be dismissed independently', () async {
    final h = Harness()
      ..categoriesThrows = Exception('rail down')
      ..genomeThrows = Exception('pane down');
    await h.controller.load();
    h.controller.selectGenome(genomeFixture());
    await pumpEventQueue();

    expect(h.controller.railError, isNotNull);
    expect(h.controller.detailError, isNotNull);

    h.controller.dismissRailError();
    expect(h.controller.railError, isNull);
    expect(h.controller.detailError, isNotNull);

    h.controller.dismissDetailError();
    expect(h.controller.detailError, isNull);
  });

  test('⚠️ a call landing after dispose does not throw', () async {
    final h = Harness();
    h.controller.selectGenome(genomeFixture());
    final pending = h.controller.refreshSelected();
    h.controller.dispose();

    await expectLater(pending, completes);
  });
}
