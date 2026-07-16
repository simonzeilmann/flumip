import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/genome.dart';
import 'package:flumip_server/src/generated/project_options.dart';
import 'package:flumip_server/src/services/file_service.dart';
import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Bed file', (sessionBuilder, endpoints) {
    setup();
    var session = sessionBuilder.build();
    final projectService = sl<ProjectService>();
    final mipgenService = sl<MipgenService>();
    final fileService = sl<FileService>();
    final settingsService = sl<SettingsService>();

    // Seeds an hg38 genome row (reference data installed by setup-mipgen.sh)
    // and returns its id. createBedFile requires the project to reference a
    // genome with a valid refPath (the refGene.txt file).
    Future<int> seedHg38Genome() async {
      final settings = await settingsService.getSettings(session);
      final genome = await Genome.db.insertRow(
        session,
        Genome(
          name: 'hg38',
          refPath: '${settings.genomeDir}/human/hg38/refGene.txt',
          fastaPath: '${settings.genomeDir}/human/hg38/fa/hg38.fa',
        ),
      );
      return genome.id!;
    }

    test(
      'calling `createBedFile` should create a bed file',
      () async {
        final project = await projectService.createProject(
            session, "test123", ProjectOptions(id: 1));
        expect(project.name, "test123");
        project.genome = await seedHg38Genome();
        await projectService.updateProject(session, project);
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
        final project = await projectService.createProject(
            session, "test123", ProjectOptions(id: 1));
        expect(project.name, "test123");
        project.genome = await seedHg38Genome();
        await projectService.updateProject(session, project);
        expect(
            () => mipgenService.createBedFile(session, project.id!),
            throwsA(predicate((e) =>
                e is ArgumentError &&
                e.message == 'No genes found in project')));
      },
      tags: ['unit'],
    );
  });
}
