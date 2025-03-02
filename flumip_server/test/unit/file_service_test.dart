import 'package:flumip_server/src/services/file_service.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Gene File Creation', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final fileService = FileService();
    final projectService = ProjectService();

    test(
      'calling `createGeneFile` should place a gene file in the project folder and update the database entry',
      () async {
        List<String> genes = ["BART1", "SN1PZ1"];

        final result = await projectService.createProject(session, "test123");
        expect(result.name, "test123");
        await fileService.createGeneFile(session, result.id!, genes);
        final genesFile = await fileService.getGenes(session, result.id!);
        expect(genesFile, genes);
        final project = await projectService.getProject(session, result.id!);
        expect(project.geneFileCreated, true);
      },
      tags: ['unit'],
    );
    test(
      'empty project id should throw an exception',
      () async {
        List<String> genes = ["BART1", "SN1PZ1"];
        expect(
            () => fileService.createGeneFile(session, -1, genes),
            throwsA(predicate((e) =>
                e is ArgumentError &&
                e.message == 'Project id does not exist')));
      },
      tags: ['unit'],
    );
  });
}
