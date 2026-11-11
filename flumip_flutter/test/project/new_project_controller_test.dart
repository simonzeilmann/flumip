import 'dart:async';

import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/new_project_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'project_run_panel_test.dart' show projectFixture;
import 'project_tile_controller_test.dart' show genomeFixture, snpFixture;

/// The create-project form, with the server replaced by closures.
class Harness {
  Harness() {
    _build();
  }

  ProjectOptions defaults = ProjectOptions(minCaptureSize: 180);

  Object? defaultsThrows;
  Object? saveThrows;
  Object? bedThrows;
  Object? generateThrows;

  /// Completes the save only when completed, for the tests that need to look
  /// at the form while a save is in flight.
  Completer<void>? saveGate;

  final calls = <String>[];
  ProjectDraftDto? saved;
  late final NewProjectController controller;

  void _build() {
    controller = NewProjectController(
      loadDefaultOptions: () async {
        calls.add('defaults');
        if (defaultsThrows != null) throw defaultsThrows!;
        return defaults;
      },
      saveProject: (draft) async {
        calls.add('save "${draft.name}"');
        await saveGate?.future;
        if (saveThrows != null) throw saveThrows!;
        saved = draft;
        return projectFixture();
      },
      loadGenomeCategories: () async => ['Homo sapiens'],
      loadGenomesInCategory: (category) async => [genomeFixture()],
      loadSnpsForGenome: (genomeId) async {
        calls.add('snps $genomeId');
        return [snpFixture()];
      },
      createBedFile: (id) async {
        calls.add('bed $id');
        if (bedThrows != null) throw bedThrows!;
      },
      generateMips: (id, deleteExcessFiles) async {
        calls.add('generate $id delete=$deleteExcessFiles');
        if (generateThrows != null) throw generateThrows!;
      },
    );
  }

  /// A form with enough in it to start a run.
  void fillForStart() {
    controller.name.text = 'panel A';
    controller.chooseGenome(genomeFixture());
    controller.addGene('BRCA1');
    calls.clear();
  }
}

void main() {
  group('the defaults', () {
    test('fill the option fields', () async {
      final h = Harness();
      addTearDown(h.controller.dispose);

      await h.controller.loadDefaults();

      expect(h.controller.options.minCaptureSize.text, '180');
      expect(h.controller.errorMessage, isNull);
    });

    test('a failure is reported and the form still works', () async {
      final h = Harness()..defaultsThrows = Exception('down');
      addTearDown(h.controller.dispose);

      await h.controller.loadDefaults();

      expect(h.controller.errorMessage, contains('Failed to load default'));
    });
  });

  group('the design target', () {
    test('choosing a genome fetches its SNP sets once', () {
      final h = Harness();
      addTearDown(h.controller.dispose);

      h.controller.chooseGenome(genomeFixture(id: 3));
      // Read twice, as two rebuilds would.
      final first = h.controller.snpsForGenome;
      final second = h.controller.snpsForGenome;

      expect(h.controller.genome?.id, 3);
      expect(first, same(second));
      expect(h.calls, ['snps 3']);
    });

    test('⚠️ changing the genome drops the SNP set', () {
      // A set is called against one build. Kept, it would be refused by the
      // server when the form is saved — long after the choice that broke it.
      final h = Harness();
      addTearDown(h.controller.dispose);
      h.controller.chooseGenome(genomeFixture(id: 3));
      h.controller.setSnp(9);

      h.controller.chooseGenome(genomeFixture(id: 7, name: 'hs1'));

      expect(h.controller.snpId, isNull);
      expect(h.calls, ['snps 3', 'snps 7']);
    });

    test('picking the same genome again keeps the SNP set', () {
      final h = Harness();
      addTearDown(h.controller.dispose);
      h.controller.chooseGenome(genomeFixture(id: 3));
      h.controller.setSnp(9);

      h.controller.chooseGenome(genomeFixture(id: 3));

      expect(h.controller.snpId, 9);
    });

    test('a gene is stored trimmed and upper-cased', () {
      final h = Harness();
      addTearDown(h.controller.dispose);

      h.controller.addGene('  brca1 ');

      expect(h.controller.genes, ['BRCA1']);
      expect(h.controller.errorMessage, isNull);
    });

    test('a gene that cannot be a symbol is refused as it is typed', () {
      final h = Harness();
      addTearDown(h.controller.dispose);

      h.controller.addGene('HLA-A');

      expect(h.controller.genes, isEmpty);
      expect(h.controller.errorMessage, contains('"HLA-A" cannot be one'));
    });

    test('a repeated gene is refused, whatever its case', () {
      final h = Harness();
      addTearDown(h.controller.dispose);
      h.controller.addGene('BRCA1');

      h.controller.addGene('brca1');

      expect(h.controller.genes, ['BRCA1']);
      expect(h.controller.errorMessage, 'BRCA1 is already on this project.');
    });

    test('a gene can be taken off again', () {
      final h = Harness();
      addTearDown(h.controller.dispose);
      h.controller.addGene('BRCA1');
      h.controller.addGene('TP53');

      h.controller.removeGene('BRCA1');

      expect(h.controller.genes, ['TP53']);
    });

    test('starting needs a genome and a gene', () {
      final h = Harness();
      addTearDown(h.controller.dispose);
      expect(h.controller.canStart, isFalse);

      h.controller.chooseGenome(genomeFixture());
      expect(h.controller.canStart, isFalse);

      h.controller.addGene('BRCA1');
      expect(h.controller.canStart, isTrue);
    });
  });

  group('saving', () {
    test('⚠️ everything goes to the server in one call', () async {
      // The whole point of the form: the project is made complete or not at
      // all, so there is exactly one write and it carries all of it.
      final h = Harness();
      addTearDown(h.controller.dispose);
      await h.controller.loadDefaults();
      h.controller.name.text = 'panel A';
      h.controller.description.text = 'exons only';
      h.controller.options.extMaxLength.text = '24';
      h.controller.chooseGenome(genomeFixture(id: 3));
      h.controller.setSnp(9);
      h.controller.addGene('brca1');
      h.controller.addGene('TP53');
      h.controller.setEmailNotification(true);
      h.calls.clear();

      final result = await h.controller.save(start: false);

      expect(h.calls, ['save "panel A"']);
      expect(h.saved!.description, 'exons only');
      expect(h.saved!.options.extMaxLength, 24);
      expect(h.saved!.genome, 3);
      expect(h.saved!.snp, 9);
      expect(h.saved!.genes, ['BRCA1', 'TP53']);
      expect(h.saved!.emailNotification, isTrue);
      expect(result!.started, isFalse);
      expect(result.startError, isNull);
    });

    test('a name is all a draft needs', () async {
      final h = Harness();
      addTearDown(h.controller.dispose);
      h.controller.name.text = 'panel A';

      final result = await h.controller.save(start: false);

      expect(result, isNotNull);
      expect(h.saved!.genome, isNull);
      expect(h.saved!.genes, isEmpty);
    });

    test('⚠️ a nameless project is refused before anything is sent', () async {
      final h = Harness();
      addTearDown(h.controller.dispose);

      final result = await h.controller.save(start: false);

      expect(result, isNull);
      expect(h.calls, isEmpty);
      expect(h.controller.errorMessage, 'A project needs a name.');
    });

    test('a refusal is reported and the form is live again', () async {
      final h = Harness()..saveThrows = Exception('name already taken');
      addTearDown(h.controller.dispose);
      h.controller.name.text = 'panel A';

      final result = await h.controller.save(start: false);

      expect(result, isNull);
      expect(h.controller.errorMessage, contains('name already taken'));
      expect(h.controller.name.text, 'panel A', reason: 'not cleared');
      expect(h.controller.isBusy, isFalse);
    });

    test('⚠️ a second press while saving does nothing', () async {
      // There was no guard at all, so a double click made two projects.
      final h = Harness()..saveGate = Completer<void>();
      addTearDown(h.controller.dispose);
      h.controller.name.text = 'panel A';

      final first = h.controller.save(start: false);
      expect(h.controller.busy, NewProjectBusy.saving);
      final second = await h.controller.save(start: false);
      h.saveGate!.complete();

      expect(second, isNull);
      expect(await first, isNotNull);
      expect(h.calls, ['save "panel A"']);
    });

    test('⚠️ the form stays dead once the project exists', () async {
      // It is about to be replaced by the list. Live again in between, "Save"
      // would store a second copy of a project that is already saved.
      final h = Harness();
      addTearDown(h.controller.dispose);
      h.controller.name.text = 'panel A';
      await h.controller.save(start: false);

      expect(h.controller.isBusy, isTrue);
      expect(await h.controller.save(start: false), isNull);
      expect(h.calls, ['save "panel A"']);
    });
  });

  group('saving and starting', () {
    test('⚠️ stores, builds the BED file, then starts the run', () async {
      // In that order: the BED file is built from the stored genes, and the
      // run reads the BED file.
      final h = Harness()..fillForStart();
      addTearDown(h.controller.dispose);

      final result = await h.controller.save(start: true);

      expect(h.calls, ['save "panel A"', 'bed 1', 'generate 1 delete=true']);
      expect(result!.started, isTrue);
      expect(result.startError, isNull);
    });

    test('the intermediate-files switch is what the run is given', () async {
      final h = Harness()..fillForStart();
      addTearDown(h.controller.dispose);
      h.controller.setDeleteExcessFiles(false);

      await h.controller.save(start: true);

      expect(h.calls.last, 'generate 1 delete=false');
    });

    test('it is refused without a genome and a gene', () async {
      final h = Harness();
      addTearDown(h.controller.dispose);
      h.controller.name.text = 'panel A';

      final result = await h.controller.save(start: true);

      expect(result, isNull);
      expect(h.calls, isEmpty);
      expect(h.controller.errorMessage, NewProjectController.startRequirement);
    });

    test('a refused save starts nothing', () async {
      final h = Harness()
        ..fillForStart()
        ..saveThrows = Exception('refused');
      addTearDown(h.controller.dispose);

      final result = await h.controller.save(start: true);

      expect(result, isNull);
      expect(h.calls, ['save "panel A"']);
    });

    test('⚠️ a BED file that cannot be built still hands the project '
        'back', () async {
      // The project is stored by then. Reporting this as a failed save would
      // leave the form open over a project that already exists.
      final h = Harness()
        ..fillForStart()
        ..bedThrows = BedCreationException(
          message: 'BRCA1 is not in this genome.',
        );
      addTearDown(h.controller.dispose);

      final result = await h.controller.save(start: true);

      expect(result!.project.id, 1);
      expect(result.started, isFalse);
      expect(
        result.startError,
        'The project was saved, but could not be started: '
        'BRCA1 is not in this genome.',
      );
      expect(h.calls, ['save "panel A"', 'bed 1']);
      expect(h.controller.errorMessage, isNull);
    });

    test('a run that is refused hands the project back too', () async {
      final h = Harness()
        ..fillForStart()
        ..generateThrows = ArgumentException(
          message: 'You already have a run going.',
        );
      addTearDown(h.controller.dispose);

      final result = await h.controller.save(start: true);

      expect(result!.started, isFalse);
      expect(result.startError, contains('You already have a run going.'));
    });
  });

  test('the options section starts shut and toggles', () {
    final h = Harness();
    addTearDown(h.controller.dispose);

    expect(h.controller.showOptions, isFalse);
    h.controller.toggleOptions();
    expect(h.controller.showOptions, isTrue);
  });

  test('the error can be dismissed', () async {
    final h = Harness()..defaultsThrows = Exception('down');
    addTearDown(h.controller.dispose);
    await h.controller.loadDefaults();

    h.controller.dismissError();

    expect(h.controller.errorMessage, isNull);
  });
}
