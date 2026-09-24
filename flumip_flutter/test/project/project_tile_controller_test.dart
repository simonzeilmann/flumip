import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/project_tile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'project_run_panel_test.dart' show projectFixture;

/// One project row's state, with the server replaced by closures.
///
/// ⚠️ The last widget in the app that reached for `client` from inside a
/// `State`, and the largest untested surface left: the poll, the genome and SNP
/// loading, and the whole run lifecycle. Every piece it *draws* already had
/// tests; the state driving them had none.
Genome genomeFixture({int id = 3, String name = 'hg38'}) => Genome(
  id: id,
  name: name,
  description: '',
  category: 'Homo sapiens',
  path: '/opt/flumip/data/genomes/human/$name',
  size: 3_100_000_000,
  indexed: true,
  indexing: false,
  active: true,
);

Snp snpFixture({int id = 9, String name = 'dbSNP common'}) => Snp(
  id: id,
  name: name,
  vcfPath: '/opt/flumip/data/custom_snp/user/$id/set.vcf.gz',
  tbiPath: '/opt/flumip/data/custom_snp/user/$id/set.vcf.gz.tbi',
  folder: '/opt/flumip/data/custom_snp/user/$id',
  active: true,
  custom: true,
  private: false,
  status: SnpImportStatus.ready,
  statusMessage: '',
  size: 1000,
  bytesDownloaded: 0,
  totalBytes: 0,
  created: DateTime(2026),
);

class Harness {
  Harness({Project? project, this.expanded = false})
    : project = project ?? projectFixture() {
    _build();
  }

  Project project;
  bool expanded;

  Object? loadThrows;
  Object? actionThrows;
  List<String> progress = const ['designing MIPs for BRCA1'];
  List<String> categories = const ['Homo sapiens'];
  List<Genome> genomes = const [];
  List<Snp> snps = const [];

  final calls = <String>[];
  final messages = <String>[];
  late final ProjectTileController controller;

  void _build() {
    controller = ProjectTileController(
      project: project,
      expanded: expanded,
      loadProject: (id) async {
        calls.add('project $id');
        if (loadThrows != null) throw loadThrows!;
        return project;
      },
      loadOptions: (id) async {
        calls.add('options $id');
        return ProjectOptions();
      },
      loadGenome: (id) async {
        calls.add('genome $id');
        return genomeFixture(id: id);
      },
      loadSnp: (id) async {
        calls.add('snp $id');
        return snpFixture(id: id);
      },
      loadProgress: (id) async {
        calls.add('progress $id');
        return progress;
      },
      addGene: (id, gene) async {
        calls.add('addGene $gene');
        if (actionThrows != null) throw actionThrows!;
      },
      removeGene: (id, gene) async {
        calls.add('removeGene $gene');
        if (actionThrows != null) throw actionThrows!;
      },
      createBedFile: (id) async {
        calls.add('createBed $id');
        if (actionThrows != null) throw actionThrows!;
      },
      generateMips: (id, deleteExcessFiles) async {
        calls.add('generate $id delete=$deleteExcessFiles');
        if (actionThrows != null) throw actionThrows!;
      },
      loadGenomeCategories: () async {
        calls.add('categories');
        return categories;
      },
      loadGenomesInCategory: (category) async {
        calls.add('genomes $category');
        return genomes;
      },
      loadSnpsForGenome: (genomeId) async {
        calls.add('snpsFor $genomeId');
        return snps;
      },
      setGenome: (projectId, genomeId) async {
        calls.add('setGenome $genomeId');
        if (actionThrows != null) throw actionThrows!;
        // The server records it, so the reload that follows sees the new one.
        project.genome = genomeId;
      },
      setSnp: (projectId, snpId) async {
        calls.add('setSnp $snpId');
        if (actionThrows != null) throw actionThrows!;
        project.snp = snpId;
      },
      setEmailNotification: (projectId, enabled) async {
        calls.add('notify $enabled');
        if (actionThrows != null) throw actionThrows!;
      },
    );
    controller.messages.listen(messages.add);
  }
}

void main() {
  group('opening and closing', () {
    test('⚠️ a collapsed tile fetches nothing and schedules nothing', () async {
      // This was one Timer.periodic(10s) per tile in the list, so a hundred
      // projects meant a hundred timers waking up to find the tile shut.
      final h = Harness();
      addTearDown(h.controller.dispose);

      await h.controller.openIfNeeded();

      expect(h.calls, isEmpty);
      expect(h.controller.polling, isFalse);
    });

    test('a tile that opens itself loads straight away', () async {
      final h = Harness(expanded: true);
      addTearDown(h.controller.dispose);

      await h.controller.openIfNeeded();

      expect(h.calls, contains('project 1'));
    });

    test('opening loads, closing stops the poll', () async {
      final h = Harness();
      addTearDown(h.controller.dispose);

      await h.controller.toggleExpanded();
      expect(h.controller.expanded, isTrue);
      expect(h.controller.polling, isTrue);

      await h.controller.toggleExpanded();
      expect(h.controller.expanded, isFalse);
      expect(h.controller.polling, isFalse);
    });

    test('⚠️ closing drops the genome so a stale one cannot flash', () async {
      final h = Harness(project: projectFixture(genome: 3));
      addTearDown(h.controller.dispose);
      await h.controller.toggleExpanded();
      expect(h.controller.genome, isNotNull);

      await h.controller.toggleExpanded();

      expect(h.controller.genome, isNull);
    });
  });

  group('the poll', () {
    test('runs faster while a design is going', () async {
      final h = Harness(
        project: projectFixture(
          genes: ['BRCA1'],
          genome: 3,
          bedFileCreated: true,
          active: true,
        ),
      );
      addTearDown(h.controller.dispose);

      await h.controller.toggleExpanded();

      expect(h.controller.polling, isTrue);
      expect(h.calls, contains('progress 1'), reason: 'the log is read too');
    });

    test('a finished project does not re-read its log', () async {
      final h = Harness(
        project: projectFixture(
          bedFileCreated: true,
          completedIn: const Duration(minutes: 5),
        ),
      );
      addTearDown(h.controller.dispose);

      await h.controller.toggleExpanded();

      expect(h.calls, isNot(contains('progress 1')));
    });

    test('⚠️ a deleted project stops the poll and says nothing', () async {
      // The poll and the delete race by nature: a tick can be in flight when the
      // row is removed. The row is on its way out, so an error would be noise.
      final h = Harness()
        ..loadThrows = FlumipFileNotFoundException(message: 'gone');
      addTearDown(h.controller.dispose);

      await h.controller.toggleExpanded();

      expect(h.controller.polling, isFalse);
      expect(h.controller.errorMessage, isNull);
    });

    test('⚠️ a refused project stops the poll but does say why', () async {
      // A revoked session or a reassigned project: nothing will change, so stop
      // asking — but the user is looking at it and deserves the reason.
      final h = Harness()
        ..loadThrows = ProjectAccessDeniedException(message: 'not yours');
      addTearDown(h.controller.dispose);

      await h.controller.toggleExpanded();

      expect(h.controller.polling, isFalse);
      expect(h.controller.errorMessage, contains('not yours'));
    });

    test('an ordinary failure keeps trying', () async {
      final h = Harness()..loadThrows = Exception('blip');
      addTearDown(h.controller.dispose);

      await h.controller.toggleExpanded();

      expect(h.controller.polling, isTrue);
      expect(h.controller.errorMessage, contains('blip'));
    });
  });

  group('the genome and its SNP sets', () {
    test('both are loaded when the project has them', () async {
      final h = Harness(project: projectFixture(genome: 3, snp: 9));
      addTearDown(h.controller.dispose);

      await h.controller.toggleExpanded();

      expect(h.controller.genome!.id, 3);
      expect(h.controller.snp!.id, 9);
    });

    test(
      '⚠️ the SNP list is not asked for before the genome has arrived',
      () async {
        // The frame between opening a tile and its genome landing. Reaching for
        // `genome.id!` there is what threw and painted the red screen.
        final h = Harness(project: projectFixture(genome: 3));
        addTearDown(h.controller.dispose);

        expect(h.controller.snpChoices, isNull);

        await h.controller.toggleExpanded();

        expect(h.controller.snpChoices, isNotNull);
      },
    );

    test('⚠️ a finished project is not asked for alternatives', () async {
      // Its SNP set is a fact about the run, not a choice.
      final h = Harness(
        project: projectFixture(
          genome: 3,
          bedFileCreated: true,
          completedIn: const Duration(minutes: 5),
        ),
      );
      addTearDown(h.controller.dispose);
      await h.controller.toggleExpanded();

      expect(h.controller.snpChoices, isNull);
      expect(h.calls, isNot(contains('snpsFor 3')));
    });

    test('the SNP list is fetched once, not on every rebuild', () async {
      final h = Harness(project: projectFixture(genome: 3));
      addTearDown(h.controller.dispose);
      await h.controller.toggleExpanded();

      h.controller.snpChoices;
      h.controller.snpChoices;
      h.controller.snpChoices;

      expect(h.calls.where((c) => c == 'snpsFor 3'), hasLength(1));
    });

    test(
      'choosing a genome shows it at once and drops the old SNP list',
      () async {
        final h = Harness(project: projectFixture(genome: 3));
        addTearDown(h.controller.dispose);
        await h.controller.toggleExpanded();
        h.controller.snpChoices;
        h.calls.clear();

        await h.controller.chooseGenome(genomeFixture(id: 7, name: 'hs1'));

        expect(h.calls, contains('setGenome 7'));
        h.controller.snpChoices;
        expect(
          h.calls,
          contains('snpsFor 7'),
          reason: 'refetched for the new one',
        );
      },
    );

    test('a refused genome change is reported', () async {
      final h = Harness()..actionThrows = Exception('locked');
      addTearDown(h.controller.dispose);

      await h.controller.chooseGenome(genomeFixture());

      expect(h.controller.errorMessage, contains('locked'));
    });

    test('the categories are sorted, on a copy', () async {
      final h = Harness()..categories = List.unmodifiable(['B', 'A']);
      addTearDown(h.controller.dispose);

      expect(await h.controller.genomeCategories(), ['A', 'B']);
    });
  });

  group('the run', () {
    test('creating the BED file reports success and reloads', () async {
      final h = Harness();
      addTearDown(h.controller.dispose);
      await h.controller.toggleExpanded();
      h.calls.clear();

      await h.controller.createBedFile();
      await pumpEventQueue();

      expect(h.calls.first, 'createBed 1');
      expect(h.messages, contains('BED file created successfully'));
    });

    test('a BED failure carries the server\'s own words', () async {
      // They name the gene that could not be found, which is the useful half.
      final h = Harness()
        ..actionThrows = BedCreationException(message: 'No exons for XYZ');
      addTearDown(h.controller.dispose);

      await h.controller.createBedFile();
      await pumpEventQueue();

      expect(h.messages.single, 'No exons for XYZ');
    });

    test('the disk-space switch is carried into the run', () async {
      final h = Harness();
      addTearDown(h.controller.dispose);
      h.controller.setDeleteExcessFiles(true);

      await h.controller.generateMips();
      await pumpEventQueue();

      expect(h.calls.first, 'generate 1 delete=true');
      expect(h.messages, contains('MIPs generation started successfully'));
    });

    test('a refused run says why and starts nothing', () async {
      final h = Harness()
        ..actionThrows = ArgumentException(
          message: 'This SNP set is not ready',
        );
      addTearDown(h.controller.dispose);

      await h.controller.generateMips();
      await pumpEventQueue();

      expect(h.messages.single, 'This SNP set is not ready');
    });
  });

  group('the genes', () {
    test('adding reloads the project', () async {
      final h = Harness();
      addTearDown(h.controller.dispose);
      h.calls.clear();

      await h.controller.addGene('BRCA1');

      expect(h.calls, ['addGene BRCA1', 'project 1', 'options 1']);
    });

    test('a refusal is reported without throwing', () async {
      final h = Harness()..actionThrows = Exception('bed already built');
      addTearDown(h.controller.dispose);

      await h.controller.removeGene('BRCA1');
      await pumpEventQueue();

      expect(h.messages.single, contains('Failed to remove gene'));
    });
  });

  test('the notification switch reports a refusal on the banner', () async {
    final h = Harness()..actionThrows = Exception('no owner');
    addTearDown(h.controller.dispose);

    await h.controller.setEmailNotification(true);

    expect(h.controller.errorMessage, contains('no owner'));
  });

  test('adopting the list\'s copy replaces the project', () async {
    final h = Harness();
    addTearDown(h.controller.dispose);

    h.controller.adopt(projectFixture(owner: 7));

    expect(h.controller.project.owner, 7);
  });

  test('the error can be dismissed', () async {
    final h = Harness()..loadThrows = Exception('down');
    addTearDown(h.controller.dispose);
    await h.controller.toggleExpanded();

    h.controller.dismissError();

    expect(h.controller.errorMessage, isNull);
  });

  test('⚠️ a call landing after dispose does not throw', () async {
    final h = Harness(expanded: true);
    final pending = h.controller.refresh();
    h.controller.dispose();

    await expectLater(pending, completes);
  });
}
