import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/project_options.dart';
import 'package:flumip_server/src/services/options_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:test/test.dart';

import '../support/matchers.dart';

import '../integration/test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Create', (sessionBuilder, endpoints) {
    setup();
    var session = sessionBuilder.build();
    final optionsService = sl<OptionsService>();

    test(
      'calling `create options` should return the an options object',
      () async {
        final options = await optionsService.createProjectOptions(session);
        expect(options.silentMode, false);
      },
      tags: ['unit'],
    );
  });

  withServerpod('Insert', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final optionsService = OptionsService();

    test(
      'calling `insert options` should return the inserted options object',
      () async {
        final options = ProjectOptions()..silentMode = true;
        final retOptions = await optionsService.insertProjectOptions(
          session,
          options,
        );
        expect(retOptions.silentMode, true);
      },
      tags: ['unit'],
    );
  });

  withServerpod('Delete', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final optionsService = OptionsService();

    test(
      'calling `delete options` should not return the deleted options object',
      () async {
        final options = ProjectOptions()..silentMode = true;
        final retOptions = await optionsService.insertProjectOptions(
          session,
          options,
        );
        expect(retOptions.silentMode, true);
        await optionsService.deleteProjectOptions(session, retOptions.id!);
        expect(
          () => optionsService.getProjectOptions(session, retOptions.id!),
          throwsA(isA<FileNotFoundException>()),
        );
      },
      tags: ['unit'],
    );
  });

  withServerpod('Update', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final optionsService = OptionsService();

    test(
      'calling `update options` should return the updated options object',
      () async {
        final options = ProjectOptions()..silentMode = true;
        final retOptions = await optionsService.insertProjectOptions(
          session,
          options,
        );
        expect(retOptions.silentMode, true);
        retOptions.silentMode = false;
        await optionsService.updateProjectOptions(
          session,
          retOptions.id!,
          retOptions,
        );
        final updatedOptions = await optionsService.getProjectOptions(
          session,
          retOptions.id!,
        );
        expect(updatedOptions.silentMode, false);
      },
      tags: ['unit'],
    );
  });

  withServerpod('Get', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final optionsService = OptionsService();

    test('calling `get options` should return the options object', () async {
      final options = ProjectOptions()..silentMode = true;
      final retOptions = await optionsService.insertProjectOptions(
        session,
        options,
      );
      expect(retOptions.silentMode, true);
      final fetchedOptions = await optionsService.getProjectOptions(
        session,
        retOptions.id!,
      );
      expect(fetchedOptions.silentMode, true);
    }, tags: ['unit']);
  });

  withServerpod('Not found', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final optionsService = OptionsService();

    test('getProjectOptions throws for a missing id', () async {
      expect(
        () => optionsService.getProjectOptions(session, -1),
        throwsA(isA<FileNotFoundException>()),
      );
    }, tags: ['unit']);

    test('updateProjectOptions throws for a missing id', () async {
      expect(
        () =>
            optionsService.updateProjectOptions(session, -1, ProjectOptions()),
        throwsMessage('Project options not found'),
      );
    }, tags: ['unit']);

    test('deleteProjectOptions throws for a missing id', () async {
      expect(
        () => optionsService.deleteProjectOptions(session, -1),
        throwsMessage('Project options not found'),
      );
    }, tags: ['unit']);
  });
}
