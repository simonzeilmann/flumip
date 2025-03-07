import 'package:flumip_server/src/services/file_service.dart';
import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Bed file', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final projectService = ProjectService();
    final mipgenService = MipgenService();
    final fileService = FileService();

    test(
      'calling `createBedFile` should give create a bed file',
      () async {
        final project = await projectService.createProject(session, "test123");
        expect(project.name, "test123");
        await projectService.addGeneToProject(session, project.id!, "BRCA1");
        await mipgenService.createBedFile(session, project.id!);
        final exists =
            await fileService.checkBedFileExists(session, project.id!);
        expect(exists, true);
      },
      tags: ['unit'],
    );

    test(
      'calling `createBedFile` without genes should throw an ArgumentError',
          () async {
        final project = await projectService.createProject(session, "test123");
        expect(project.name, "test123");
        expect(
                () => mipgenService.createBedFile(session, project.id!),
            throwsA(predicate((e) =>
            e is ArgumentError && e.message == 'No genes found in project')));
      },
      tags: ['unit'],
    );
  });
}
