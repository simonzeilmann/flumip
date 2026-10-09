import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
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

    test('calling `createProject` should return the project', () async {
      final result = await projectService.createProject(
        session,
        "test123",
        ProjectOptions(id: 1),
      );
      expect(result.name, "test123");
    }, tags: ['unit']);
    test(
      'calling `createProject` with description should return the project including the description',
      () async {
        final result = await projectService.createProject(
          session,
          "test123",
          ProjectOptions(id: 1),
          "description",
        );
        expect(result.description, "description");
      },
      tags: ['unit'],
    );
    test('createProject makes the project directory', () async {
      final settings = await SettingsService().getSettings(session);
      final project = await projectService.createProject(
        session,
        'withfolder',
        ProjectOptions(id: 1),
      );

      expect(
        Directory('${settings.projectDir}/${project.folderName}').existsSync(),
        isTrue,
      );
    }, tags: ['unit']);

    test('⚠️ a directory it cannot make leaves no project behind', () async {
      // The order this pins. The directory used to be made *last*, after the
      // row was inserted and the cleanup future call scheduled, so anything
      // that went wrong in `create()` left a project nobody could use sitting
      // in everybody's list — and `deleteProject` then failed on the folder
      // that had never been there.
      //
      // A file where the directory should go is the cheapest way to make
      // `create()` fail for a reason that is not "the parent is missing",
      // which `recursive: true` now handles on its own.
      final base = createTempDir('projsvc-blocked');
      final blocker = File('${base.path}/blocked')..writeAsStringSync('x');
      await overrideSettingsDirs(session, projectDir: blocker.path);

      final before = await Project.db.find(session);
      await expectLater(
        () => projectService.createProject(
          session,
          'doomed',
          ProjectOptions(id: 1),
        ),
        throwsA(isA<FileSystemException>()),
      );

      final after = await Project.db.find(session);
      expect(after.length, before.length, reason: 'an orphan row was stored');
    }, tags: ['unit']);

    test('unsaved options are refused before any folder is made', () async {
      // `options.id!` used to throw a bare null check after the directory had
      // been created: a 500 for the caller and an empty folder left behind.
      final settings = await SettingsService().getSettings(session);
      final dir = Directory(settings.projectDir);
      final before = dir.listSync().length;

      await expectLater(
        () =>
            projectService.createProject(session, 'unsaved', ProjectOptions()),
        throwsMessage('Save the project options before creating the project.'),
      );
      expect(dir.listSync().length, before, reason: 'a folder was left behind');
    }, tags: ['unit']);

    test('empty project name should throw an exception', () async {
      expect(
        () => projectService.createProject(session, "", ProjectOptions(id: 1)),
        throwsMessage('A project needs a name.'),
      );
    }, tags: ['unit']);
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
          session,
          "test123",
          ProjectOptions(id: 1),
        );
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
        throwsMessage('This project no longer exists.'),
      );
    });

    test('deletes a project whose directory was never created', () async {
      // ⚠️ The bug this exists to stop coming back. `Directory.delete` throws
      // `PathNotFoundException` for a path that is not there, and the row is
      // deleted *before* the cleanup runs — so the project was fully deleted
      // and then reported as a failure, leaving the client showing a row that
      // no longer existed.
      //
      // A project reaches this state when `createProject` committed the row
      // but its non-recursive `Directory.create()` failed (no `projectDir`),
      // when `projectDir` is repointed, or when the folder is cleared by hand.
      final project = await projectService.createProject(
        session,
        "never-ran",
        ProjectOptions(id: 1),
      );

      final settings = await SettingsService().getSettings(session);
      final folder = Directory('${settings.projectDir}/${project.folderName}');
      if (await folder.exists()) await folder.delete(recursive: true);

      await projectService.deleteProject(session, project.id!);

      expect(await projectService.getProjects(session), isEmpty);
    }, tags: ['unit']);

    test('a project with files on disk takes them with it', () async {
      final project = await projectService.createProject(
        session,
        "has-files",
        ProjectOptions(id: 1),
      );

      final settings = await SettingsService().getSettings(session);
      final folder = Directory('${settings.projectDir}/${project.folderName}');
      await folder.create(recursive: true);
      await File('${folder.path}/result.txt').writeAsString('mips');

      await projectService.deleteProject(session, project.id!);

      expect(await folder.exists(), isFalse);
      expect(await projectService.getProjects(session), isEmpty);
    }, tags: ['unit']);
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
        session,
        "test123",
        ProjectOptions(id: 1),
      );
      expect(result.name, "test123");
      final project = await projectService.getProject(session, result.id!);
      expect(project.name, "test123");
    });

    test('calling get Project with non existent project id'
        'should throw an exception', () async {
      expect(
        () => projectService.getProject(session, -1),
        throwsMessage('This project no longer exists.'),
      );
    });

    test('calling `getProjects` should return a list of projects', () async {
      final result = await projectService.createProject(
        session,
        "test123",
        ProjectOptions(id: 1),
      );
      expect(result.name, "test123");
      final projects = await projectService.getProjects(session);
      expect(projects.length, 1);
      expect(projects[0].name, "test123");
    }, tags: ['unit']);
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

    test('calling `addGenesToProject` should add genes'
        'to the project database entry', () async {
      List<String> genes = ["BART1", "SN1PZ1"];

      final result = await projectService.createProject(
        session,
        "test123",
        ProjectOptions(id: 1),
      );
      expect(result.name, "test123");
      await projectService.addGenesToProject(session, result.id!, genes);
      final project = await projectService.getProject(session, result.id!);
      expect(project.genes, genes);
    }, tags: ['unit']);

    test('calling `addGenesToProject` should add a genes'
        'to the project database entry', () async {
      List<String> genes = ["BART1"];

      final result = await projectService.createProject(
        session,
        "test123",
        ProjectOptions(id: 1),
      );
      expect(result.name, "test123");
      await projectService.addGeneToProject(session, result.id!, "BART1");
      final project = await projectService.getProject(session, result.id!);
      expect(project.genes, genes);
    }, tags: ['unit']);

    test('calling `removeGeneFromProject` should remove a gene'
        'from the project database entry', () async {
      List<String> genes = ["BART1"];

      final result = await projectService.createProject(
        session,
        "test123",
        ProjectOptions(id: 1),
      );
      expect(result.name, "test123");
      await projectService.addGeneToProject(session, result.id!, "BART1");
      final project = await projectService.getProject(session, result.id!);
      expect(project.genes, genes);
      await projectService.removeGeneFromProject(session, result.id!, "BART1");
      final project2 = await projectService.getProject(session, result.id!);
      expect(project2.genes?.isEmpty, true);
    }, tags: ['unit']);
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
        throwsMessage('This project no longer exists.'),
      );
    }, tags: ['unit']);

    test('setGenomeById throws when the genome is missing', () async {
      final project = await seedProject(session, options: 1);
      expect(
        () => projectService.setGenomeById(session, project.id!, -1),
        throwsMessage('This gene is not on this project.'),
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
        throwsMessage('This project no longer exists.'),
      );
    }, tags: ['unit']);

    test('setSnpById throws when the snp is missing', () async {
      final project = await seedProject(session, options: 1);
      expect(
        () => projectService.setSnpById(session, project.id!, -1),
        throwsMessage('This SNP set no longer exists.'),
      );
    }, tags: ['unit']);

    test('setSnpById refuses an SNP called against another genome', () async {
      // VCF coordinates are build-specific, so this does not fail at run time —
      // it quietly designs the wrong MIPs. The check exists because the SNP now
      // records which build it belongs to.
      final hg38 = await seedGenome(session, name: 'hg38');
      final hs1 = await seedGenome(session, name: 'hs1');
      final project = await seedProject(session, options: 1, genome: hg38.id);
      final wrongBuild = await seedSnp(
        session,
        name: 'hs1 snps',
        genome: hs1.id,
      );
      expect(
        () => projectService.setSnpById(session, project.id!, wrongBuild.id!),
        throwsMessage('different genome build'),
      );
    }, tags: ['unit']);

    test('setSnpById refuses an SNP whose bytes have not arrived', () async {
      final genome = await seedGenome(session, name: 'hg38');
      final project = await seedProject(session, options: 1, genome: genome.id);
      final pending = await seedSnp(
        session,
        name: 'downloading',
        genome: genome.id,
        custom: true,
        status: SnpImportStatus.downloading,
      );
      expect(
        () => projectService.setSnpById(session, project.id!, pending.id!),
        throwsMessage('not ready to use'),
      );
    }, tags: ['unit']);

    test('setSnpById with null clears the selection', () async {
      final genome = await seedGenome(session, name: 'hg38');
      final snp = await seedSnp(session, name: 'common', genome: genome.id);
      final project = await seedProject(
        session,
        options: 1,
        genome: genome.id,
        snp: snp.id,
      );

      await projectService.setSnpById(session, project.id!, null);

      expect(
        (await projectService.getProject(session, project.id!)).snp,
        isNull,
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
        throwsMessage('BRCA1 is already on this project.'),
      );
    }, tags: ['unit']);

    test('⚠️ addGeneToProject rejects a duplicate typed in any case', () async {
      // The bug this pins. The duplicate check read the string as typed while
      // the list stores it upper-cased, so `contains('myh11')` never matched the
      // `MYH11` already there and lower case added it again every time. A
      // project in the wild ended up with the same gene three times over.
      final project = await seedProject(session, options: 1);
      await projectService.addGeneToProject(session, project.id!, 'MYH11');

      for (final typed in ['myh11', 'Myh11', 'mYh11', '  myh11  ']) {
        await expectLater(
          () => projectService.addGeneToProject(session, project.id!, typed),
          throwsMessage('MYH11 is already on this project.'),
          reason: 'accepted "$typed" as a second MYH11',
        );
      }

      final reread = await projectService.getProject(session, project.id!);
      expect(reread.genes, ['MYH11']);
    }, tags: ['unit']);

    test(
      'addGeneToProject stores the symbol upper-cased and trimmed',
      () async {
        final project = await seedProject(session, options: 1);
        await projectService.addGeneToProject(session, project.id!, '  brca1 ');

        final reread = await projectService.getProject(session, project.id!);
        expect(reread.genes, ['BRCA1']);
      },
      tags: ['unit'],
    );

    test('addGeneToProject rejects an empty gene', () async {
      final project = await seedProject(session, options: 1);
      expect(
        () => projectService.addGeneToProject(session, project.id!, ''),
        throwsMessage('Enter a gene symbol.'),
      );
    }, tags: ['unit']);

    test('addGeneToProject rejects invalid characters', () async {
      final project = await seedProject(session, options: 1);
      expect(
        () => projectService.addGeneToProject(session, project.id!, 'BR-CA1'),
        throwsMessage('can only contain letters and numbers'),
      );
    }, tags: ['unit']);

    test('addGeneToProject throws when the project is missing', () async {
      expect(
        () => projectService.addGeneToProject(session, -1, 'BRCA1'),
        throwsMessage('This project no longer exists.'),
      );
    }, tags: ['unit']);

    test('addGenesToProject normalises and drops repeats', () async {
      // It replaces the whole list rather than appending, so without this a bulk
      // write could seed mixed case that the single-gene check would then never
      // catch. Repeats are dropped rather than refused: a list arrives in one
      // go, and failing the whole write would make the caller diff it by hand.
      final project = await seedProject(session, options: 1);
      await projectService.addGenesToProject(session, project.id!, [
        'brca1',
        ' TP53 ',
        'BRCA1',
      ]);

      final reread = await projectService.getProject(session, project.id!);
      expect(reread.genes, ['BRCA1', 'TP53']);
    }, tags: ['unit']);

    test('addGenesToProject rejects invalid characters', () async {
      final project = await seedProject(session, options: 1);
      expect(
        () => projectService.addGenesToProject(session, project.id!, [
          'OK',
          'bad gene',
        ]),
        throwsMessage('can only contain letters and numbers'),
      );
    }, tags: ['unit']);

    test('addGenesToProject throws when the project is missing', () async {
      expect(
        () => projectService.addGenesToProject(session, -1, ['BRCA1']),
        throwsMessage('This project no longer exists.'),
      );
    }, tags: ['unit']);

    test('removeGeneFromProject throws when there are no genes', () async {
      final project = await seedProject(session, options: 1);
      expect(
        () => projectService.removeGeneFromProject(session, project.id!, 'X'),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                '$e'.contains('This gene is not on this project.'),
          ),
        ),
      );
    }, tags: ['unit']);
  });

  withServerpod('Email notification flag', (sessionBuilder, endpoints) {
    setup();
    var session = sessionBuilder.build();
    final projectService = sl<ProjectService>();

    test('defaults to off', () async {
      final options = await seedOptions(session);
      final project = await seedProject(session, options: options.id!);
      expect(project.emailNotification, isFalse);
    }, tags: ['unit']);

    test('setEmailNotification turns it on and back off', () async {
      final options = await seedOptions(session);
      final project = await seedProject(session, options: options.id!);

      await projectService.setEmailNotification(session, project.id!, true);
      var reloaded = await projectService.getProject(session, project.id!);
      expect(reloaded.emailNotification, isTrue);

      await projectService.setEmailNotification(session, project.id!, false);
      reloaded = await projectService.getProject(session, project.id!);
      expect(reloaded.emailNotification, isFalse);
    }, tags: ['unit']);

    test('stores the flag on an unowned project too', () async {
      // Nothing can be delivered for an unowned project, but refusing the write
      // would put the "can this send?" rule in two places. The send path is the
      // one that decides; see MailService.resolveRecipient.
      final options = await seedOptions(session);
      final project = await seedProject(session, options: options.id!);
      expect(project.owner, isNull);

      await projectService.setEmailNotification(session, project.id!, true);

      final reloaded = await projectService.getProject(session, project.id!);
      expect(reloaded.emailNotification, isTrue);
    }, tags: ['unit']);

    test('stores the flag even while mail is globally disabled', () async {
      // Same reasoning: an admin switching mail on later must not require every
      // user to go back and re-tick their projects.
      await overrideMailSettings(session, mailActive: false);
      final options = await seedOptions(session);
      final project = await seedProject(session, options: options.id!);

      await projectService.setEmailNotification(session, project.id!, true);

      final reloaded = await projectService.getProject(session, project.id!);
      expect(reloaded.emailNotification, isTrue);
    }, tags: ['unit']);

    test('setEmailNotification throws when the project is missing', () async {
      expect(
        () => projectService.setEmailNotification(session, -1, true),
        throwsMessage('This project no longer exists.'),
      );
    }, tags: ['unit']);
  });

  withServerpod('Ownership reassignment', (sessionBuilder, endpoints) {
    setup();
    var session = sessionBuilder.build();
    final projectService = sl<ProjectService>();

    test('setOwner hands the project over', () async {
      final options = await seedOptions(session);
      final alice = await seedSignedInUser(session, email: 'a@uni.example');
      final bob = await seedSignedInUser(session, email: 'b@uni.example');
      final project = await seedProject(
        session,
        options: options.id!,
        owner: alice.user.id,
      );

      await projectService.setOwner(session, project.id!, bob.user.id);

      final reloaded = await projectService.getProject(session, project.id!);
      expect(reloaded.owner, bob.user.id);
    }, tags: ['unit']);

    test('setOwner(null) releases the project to unowned', () async {
      final options = await seedOptions(session);
      final alice = await seedSignedInUser(session, email: 'a@uni.example');
      final project = await seedProject(
        session,
        options: options.id!,
        owner: alice.user.id,
      );

      await projectService.setOwner(session, project.id!, null);

      final reloaded = await projectService.getProject(session, project.id!);
      expect(reloaded.owner, isNull);
    }, tags: ['unit']);

    test('setOwner rejects a user that does not exist', () async {
      // Looked up rather than trusted, so this reads as "User not found"
      // instead of surfacing as a foreign-key violation from the driver.
      final options = await seedOptions(session);
      final project = await seedProject(session, options: options.id!);

      await expectLater(
        projectService.setOwner(session, project.id!, 999999),
        throwsMessage('This user no longer exists.'),
      );

      final reloaded = await projectService.getProject(session, project.id!);
      expect(reloaded.owner, isNull, reason: 'nothing was written');
    }, tags: ['unit']);

    test('setOwner throws when the project is missing', () async {
      await expectLater(
        projectService.setOwner(session, -1, null),
        throwsMessage('This project no longer exists.'),
      );
    }, tags: ['unit']);

    test('assignableOwners lists every user, oldest first', () async {
      final first = await seedSignedInUser(session, email: 'first@uni.example');
      final second = await seedSignedInUser(
        session,
        email: 'second@uni.example',
      );

      final owners = await projectService.assignableOwners(session);

      expect(
        owners.map((u) => u.id),
        containsAllInOrder([first.user.id, second.user.id]),
      );
    }, tags: ['unit']);

    test('assignableOwners is empty on an install with no users', () async {
      // Which is every no-auth install — the picker has nothing to offer, and
      // the endpoint in front of this refuses the call there anyway.
      expect(await projectService.assignableOwners(session), isEmpty);
    }, tags: ['unit']);
  });

  withServerpod('ProjectEndpoint.notificationsAvailable', (
    sessionBuilder,
    endpoints,
  ) {
    setup();
    var session = sessionBuilder.build();

    test('reports whether the admin has mail switched on', () async {
      await overrideMailSettings(session, mailActive: false);
      expect(
        await endpoints.project.notificationsAvailable(sessionBuilder),
        isFalse,
      );

      await overrideMailSettings(session, mailActive: true);
      expect(
        await endpoints.project.notificationsAvailable(sessionBuilder),
        isTrue,
      );
    }, tags: ['integration']);
  });
}
