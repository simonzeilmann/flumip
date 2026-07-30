import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/project_options.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:test/test.dart';

import '../support/matchers.dart';

import '../integration/test_tools/serverpod_test_tools.dart';
import '../support/seed.dart';
import '../support/temp_dir.dart';

void main() {
  withServerpod('Project Creation', (sessionBuilder, endpoints) {
    setup();
    var session = sessionBuilder.build();
    final projectService = sl<ProjectService>();

    // createProject creates <projectDir>/<folderName>; point projectDir at a
    // writable temp dir so the test doesn't depend on /opt/flumip existing.
    setUp(() async {
      final base = createTempDir('projsvc');
      await overrideSettingsDirs(session, projectDir: base.path);
    });

    test(
      'calling `createProject` should return the project',
      () async {
        final result = await projectService.createProject(
            session, "test123", ProjectOptions(id: 1));
        expect(result.name, "test123");
      },
      tags: ['unit'],
    );
    test(
      'calling `createProject` with description should return the project including the description',
      () async {
        final result = await projectService.createProject(
            session, "test123", ProjectOptions(id: 1), "description");
        expect(result.description, "description");
      },
      tags: ['unit'],
    );
    test(
      'empty project name should throw an exception',
      () async {
        expect(
            () => projectService.createProject(session, "", ProjectOptions(id: 1)),
            throwsMessage('Project name cannot be empty'));
      },
      tags: ['unit'],
    );
  });

  withServerpod('Project Deletion', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final projectService = ProjectService();

    setUp(() async {
      final base = createTempDir('projsvc');
      await overrideSettingsDirs(session, projectDir: base.path);
    });

    test(
      'calling `deleteProject` should give an empty list of projects',
      () async {
        final result = await projectService.createProject(
            session, "test123", ProjectOptions(id: 1));
        expect(result.name, "test123");
        await projectService.deleteProject(session, result.id!);
        final projects = await projectService.getProjects(session);
        expect(projects.length, 0);
      },
      tags: ['unit'],
    );
    test('non existent project id should throw an exception', () async {
      expect(
          () => projectService.deleteProject(session, -1),
          throwsMessage('Project not found'));
    });
  });

  withServerpod('Get Projects', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final projectService = ProjectService();

    setUp(() async {
      final base = createTempDir('projsvc');
      await overrideSettingsDirs(session, projectDir: base.path);
    });

    test('calling get Project should return the requested project', () async {
      final result = await projectService.createProject(
          session, "test123", ProjectOptions(id: 1));
      expect(result.name, "test123");
      final project = await projectService.getProject(session, result.id!);
      expect(project.name, "test123");
    });

    test(
        'calling get Project with non existent project id'
        'should throw an exception', () async {
      expect(
          () => projectService.getProject(session, -1),
          throwsMessage('Project not found'));
    });

    test(
      'calling `getProjects` should return a list of projects',
      () async {
        final result = await projectService.createProject(
            session, "test123", ProjectOptions(id: 1));
        expect(result.name, "test123");
        final projects = await projectService.getProjects(session);
        expect(projects.length, 1);
        expect(projects[0].name, "test123");
      },
      tags: ['unit'],
    );
    test('calling `getProjects` should return an empty list', () async {
      final projects = await projectService.getProjects(session);
      expect(projects.length, 0);
    });
  });

  withServerpod('Gene Update Tests', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final projectService = ProjectService();

    setUp(() async {
      final base = createTempDir('projsvc');
      await overrideSettingsDirs(session, projectDir: base.path);
    });

    test(
      'calling `addGenesToProject` should add genes'
      'to the project database entry',
      () async {
        List<String> genes = ["BART1", "SN1PZ1"];

        final result = await projectService.createProject(
            session, "test123", ProjectOptions(id: 1));
        expect(result.name, "test123");
        await projectService.addGenesToProject(session, result.id!, genes);
        final project = await projectService.getProject(session, result.id!);
        expect(project.genes, genes);
      },
      tags: ['unit'],
    );

    test(
      'calling `addGenesToProject` should add a genes'
      'to the project database entry',
      () async {
        List<String> genes = ["BART1"];

        final result = await projectService.createProject(
            session, "test123", ProjectOptions(id: 1));
        expect(result.name, "test123");
        await projectService.addGeneToProject(session, result.id!, "BART1");
        final project = await projectService.getProject(session, result.id!);
        expect(project.genes, genes);
      },
      tags: ['unit'],
    );

    test(
      'calling `removeGeneFromProject` should remove a gene'
      'from the project database entry',
      () async {
        List<String> genes = ["BART1"];

        final result = await projectService.createProject(
            session, "test123", ProjectOptions(id: 1));
        expect(result.name, "test123");
        await projectService.addGeneToProject(session, result.id!, "BART1");
        final project = await projectService.getProject(session, result.id!);
        expect(project.genes, genes);
        await projectService.removeGeneFromProject(
            session, result.id!, "BART1");
        final project2 = await projectService.getProject(session, result.id!);
        expect(project2.genes?.isEmpty, true);
      },
      tags: ['unit'],
    );
  });

  withServerpod('Genome / SNP assignment', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final projectService = ProjectService();

    test('setGenomeById links the genome to the project', () async {
      final project = await seedProject(session, options: 1);
      final genome = await seedGenome(session, name: 'hg38');
      await projectService.setGenomeById(session, project.id!, genome.id!);
      final reloaded = await projectService.getProject(session, project.id!);
      expect(reloaded.genome, genome.id);
    }, tags: ['unit']);

    test('setGenomeById throws when the project is missing', () async {
      expect(
        () => projectService.setGenomeById(session, -1, 1),
        throwsMessage('Project not found'),
      );
    }, tags: ['unit']);

    test('setGenomeById throws when the genome is missing', () async {
      final project = await seedProject(session, options: 1);
      expect(
        () => projectService.setGenomeById(session, project.id!, -1),
        throwsMessage('Gene not found'),
      );
    }, tags: ['unit']);

    test('setSnpById links the snp to the project', () async {
      final project = await seedProject(session, options: 1);
      final snp = await seedSnp(session, name: 'common');
      await projectService.setSnpById(session, project.id!, snp.id!);
      final reloaded = await projectService.getProject(session, project.id!);
      expect(reloaded.snp, snp.id);
    }, tags: ['unit']);

    test('setSnpById throws when the project is missing', () async {
      expect(
        () => projectService.setSnpById(session, -1, 1),
        throwsMessage('Project not found'),
      );
    }, tags: ['unit']);

    test('setSnpById throws when the snp is missing', () async {
      final project = await seedProject(session, options: 1);
      expect(
        () => projectService.setSnpById(session, project.id!, -1),
        throwsMessage('Snp not found'),
      );
    }, tags: ['unit']);

    test('updateProject persists field changes', () async {
      final project = await seedProject(session, options: 1);
      project.error = 'boom';
      await projectService.updateProject(session, project);
      final reloaded = await projectService.getProject(session, project.id!);
      expect(reloaded.error, 'boom');
    }, tags: ['unit']);
  });

  withServerpod('Gene validation', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final projectService = ProjectService();

    test('addGeneToProject rejects a duplicate gene', () async {
      final project = await seedProject(session, options: 1);
      await projectService.addGeneToProject(session, project.id!, 'BRCA1');
      expect(
        () => projectService.addGeneToProject(session, project.id!, 'BRCA1'),
        throwsA(predicate(
            (e) => e is Exception && '$e'.contains('Gene already exists'))),
      );
    }, tags: ['unit']);

    test('addGeneToProject rejects an empty gene', () async {
      final project = await seedProject(session, options: 1);
      expect(
        () => projectService.addGeneToProject(session, project.id!, ''),
        throwsMessage('Supplied gene empty'),
      );
    }, tags: ['unit']);

    test('addGeneToProject rejects invalid characters', () async {
      final project = await seedProject(session, options: 1);
      expect(
        () => projectService.addGeneToProject(session, project.id!, 'BR-CA1'),
        throwsMessage('Gene name contains invalid characters'),
      );
    }, tags: ['unit']);

    test('addGeneToProject throws when the project is missing', () async {
      expect(
        () => projectService.addGeneToProject(session, -1, 'BRCA1'),
        throwsMessage('Project not found'),
      );
    }, tags: ['unit']);

    test('addGenesToProject rejects invalid characters', () async {
      final project = await seedProject(session, options: 1);
      expect(
        () => projectService
            .addGenesToProject(session, project.id!, ['OK', 'bad gene']),
        throwsMessage('Gene name contains invalid characters'),
      );
    }, tags: ['unit']);

    test('addGenesToProject throws when the project is missing', () async {
      expect(
        () => projectService.addGenesToProject(session, -1, ['BRCA1']),
        throwsMessage('Project not found'),
      );
    }, tags: ['unit']);

    test('removeGeneFromProject throws when there are no genes', () async {
      final project = await seedProject(session, options: 1);
      expect(
        () => projectService.removeGeneFromProject(session, project.id!, 'X'),
        throwsA(predicate(
            (e) => e is Exception && '$e'.contains('does not have any genes'))),
      );
    }, tags: ['unit']);
  });
}
