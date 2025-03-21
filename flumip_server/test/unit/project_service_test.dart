import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/project_options.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Project Creation', (sessionBuilder, endpoints) {
    setup();
    var session = sessionBuilder.build();
    final projectService = sl<ProjectService>();

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
            throwsA(predicate((e) =>
                e is ArgumentError &&
                e.message == 'Project name cannot be empty')));
      },
      tags: ['unit'],
    );
  });

  withServerpod('Project Deletion', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final projectService = ProjectService();

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
          throwsA(predicate((e) =>
              e is FileNotFoundException && e.message == 'Project not found')));
    });
  });

  withServerpod('Get Projects', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final projectService = ProjectService();

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
          throwsA(predicate((e) =>
              e is FileNotFoundException && e.message == 'Project not found')));
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
}
