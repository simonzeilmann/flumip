import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/new_project_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'project_run_panel_test.dart' show projectFixture;

/// The create-project form, with the server replaced by closures.
class Harness {
  Harness() {
    _build();
  }

  ProjectOptions defaults = ProjectOptions(minCaptureSize: 180);

  Object? defaultsThrows;
  Object? insertThrows;
  Object? createThrows;

  final calls = <String>[];
  ProjectOptions? inserted;
  late final NewProjectController controller;

  void _build() {
    controller = NewProjectController(
      loadDefaultOptions: () async {
        calls.add('defaults');
        if (defaultsThrows != null) throw defaultsThrows!;
        return defaults;
      },
      insertOptions: (options) async {
        calls.add('insertOptions');
        if (insertThrows != null) throw insertThrows!;
        inserted = options;
        return ProjectOptions(id: 7);
      },
      createProject: (name, options, description) async {
        calls.add('create "$name" options=${options.id} "$description"');
        if (createThrows != null) throw createThrows!;
        return projectFixture();
      },
    );
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

  group('creating', () {
    test('⚠️ the options row is stored first, then pointed at', () async {
      // A project cannot reference options that do not exist yet, so the order
      // is not a style choice.
      final h = Harness();
      addTearDown(h.controller.dispose);
      await h.controller.loadDefaults();
      h.calls.clear();
      h.controller.name.text = 'panel A';
      h.controller.description.text = 'exons only';

      final created = await h.controller.create();

      expect(created, isNotNull);
      expect(h.calls, [
        'insertOptions',
        'create "panel A" options=7 "exons only"',
      ]);
    });

    test('the options sent are what the form says', () async {
      final h = Harness();
      addTearDown(h.controller.dispose);
      await h.controller.loadDefaults();
      h.controller.name.text = 'panel A';
      h.controller.options.extMaxLength.text = '24';

      await h.controller.create();

      expect(h.inserted!.extMaxLength, 24);
    });

    test(
      '⚠️ a nameless project is refused before anything is stored',
      () async {
        // Otherwise an options row is written for a project that never appears.
        final h = Harness();
        addTearDown(h.controller.dispose);
        await h.controller.loadDefaults();
        h.calls.clear();

        final created = await h.controller.create();

        expect(created, isNull);
        expect(h.calls, isEmpty);
        expect(h.controller.errorMessage, 'A project needs a name.');
      },
    );

    test('the fields are cleared once it exists', () async {
      final h = Harness();
      addTearDown(h.controller.dispose);
      h.controller.name.text = 'panel A';
      h.controller.description.text = 'notes';

      await h.controller.create();

      expect(h.controller.name.text, isEmpty);
      expect(h.controller.description.text, isEmpty);
    });

    test('a refusal is reported and nothing is claimed', () async {
      final h = Harness()..createThrows = Exception('name already taken');
      addTearDown(h.controller.dispose);
      h.controller.name.text = 'panel A';

      final created = await h.controller.create();

      expect(created, isNull);
      expect(h.controller.errorMessage, contains('name already taken'));
      expect(h.controller.name.text, 'panel A', reason: 'not cleared');
    });

    test('a failure storing the options stops before the project', () async {
      final h = Harness()..insertThrows = Exception('refused');
      addTearDown(h.controller.dispose);
      h.controller.name.text = 'panel A';
      h.calls.clear();

      await h.controller.create();

      expect(h.calls, ['insertOptions']);
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
