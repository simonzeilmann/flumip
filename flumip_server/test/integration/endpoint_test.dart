import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:serverpod/protocol.dart';
import 'package:test/test.dart';

import '../support/fake_process_runner.dart';
import '../support/matchers.dart';
import '../support/seed.dart';
import 'test_tools/serverpod_test_tools.dart';

final fake = FakeProcessRunner();

void main() {
  withServerpod('Endpoints', (sessionBuilder, endpoints) {
    setup(processRunner: fake);
    setUp(fake.reset);
    var session = sessionBuilder.build();

    // --- OptionsEndpoint ----------------------------------------------------
    test('options: insert then get round-trips through the endpoint', () async {
      final inserted = await endpoints.options.insertProjectOptions(
          sessionBuilder, ProjectOptions()..silentMode = true);
      final got = await endpoints.options
          .getProjectOptions(sessionBuilder, inserted.id!);
      expect(got.silentMode, isTrue);
    }, tags: ['integration']);

    test('options: getProjectOptions rethrows for a missing id', () async {
      expect(
        () => endpoints.options.getProjectOptions(sessionBuilder, -1),
        throwsA(isA<FileNotFoundException>()),
      );
    }, tags: ['integration']);

    // --- SettingsEndpoint (password-gated) ----------------------------------
    test('settings: getSettings returns settings for the correct password',
        () async {
      final s = await endpoints.settings.getSettings(sessionBuilder, 'changeme');
      expect(s.baseDir, '/opt/flumip');
    }, tags: ['integration']);

    test('settings: getSettings rethrows for an invalid password', () async {
      expect(
        () => endpoints.settings.getSettings(sessionBuilder, 'wrong'),
        throwsA(isA<Exception>()),
      );
    }, tags: ['integration']);

    // --- GenomeEndpoint -----------------------------------------------------
    test('genome: getGenome returns a seeded genome', () async {
      final genome = await seedGenome(session, name: 'hg38');
      final got = await endpoints.genome.getGenome(sessionBuilder, genome.id!);
      expect(got.name, 'hg38');
    }, tags: ['integration']);

    test('genome: getGenome rethrows for a missing id', () async {
      expect(
        () => endpoints.genome.getGenome(sessionBuilder, -1),
        throwsMessage('Genome not found'),
      );
    }, tags: ['integration']);

    test('genome: getAllGenomes and getCategories return seeded data',
        () async {
      await seedGenome(session, name: 'hg38', category: 'human');
      await seedGenome(session, name: 'mm10', category: 'mouse');
      final all = await endpoints.genome.getAllGenomes(sessionBuilder);
      expect(all.length, greaterThanOrEqualTo(2));
      final cats = await endpoints.genome.getCategories(sessionBuilder);
      expect(cats.toSet(), containsAll(['human', 'mouse']));
    }, tags: ['integration']);

    // --- ProjectEndpoint ----------------------------------------------------
    test('project: createProject creates the row and its directory', () async {
      final base = createTempDirLocal();
      await overrideSettingsDirs(session, projectDir: base.path);
      final project = await endpoints.project
          .createProject(sessionBuilder, 'int_test', ProjectOptions(id: 1));
      expect(project.id, greaterThan(0));
      expect(
        Directory('${base.path}/${project.folderName}').existsSync(),
        isTrue,
      );
    }, tags: ['integration']);

    test('project: getProject rethrows for a missing id', () async {
      expect(
        () => endpoints.project.getProject(sessionBuilder, -1),
        throwsMessage('Project not found'),
      );
    }, tags: ['integration']);

    // --- MipgenEndpoint (error wrapper) -------------------------------------
    test('mipgen: createBedFile rethrows the service ArgumentError', () async {
      final project = await seedProject(session, options: 1); // no genome
      expect(
        () => endpoints.mipgen.createBedFile(sessionBuilder, project.id!),
        throwsMessage('No genome found in project'),
      );
    }, tags: ['integration']);

    // --- FileEndpoint (error wrapper) ---------------------------------------
    test('file: showMipsProgress rethrows for a missing project', () async {
      expect(
        () => endpoints.file.showMipsProgress(sessionBuilder, -1),
        throwsA(isA<FileNotFoundException>()),
      );
    }, tags: ['integration']);

    // --- More project delegations ------------------------------------------
    test('project: getProjects returns seeded projects', () async {
      await seedProject(session, options: 1);
      final projects = await endpoints.project.getProjects(sessionBuilder);
      expect(projects, isNotEmpty);
    }, tags: ['integration']);

    test('project: gene add/remove and genome/snp assignment', () async {
      final project = await seedProject(session, options: 1);
      final genome = await seedGenome(session, name: 'hg38');
      final snp = await seedSnp(session, name: 'common');
      await endpoints.project
          .addGenesToProject(sessionBuilder, project.id!, ['BRCA1', 'TP53']);
      await endpoints.project
          .removeGeneFromProject(sessionBuilder, project.id!, 'TP53');
      await endpoints.project
          .setGeneById(sessionBuilder, project.id!, genome.id!);
      await endpoints.project.setSnpById(sessionBuilder, project.id!, snp.id!);
      final reloaded =
          await endpoints.project.getProject(sessionBuilder, project.id!);
      expect(reloaded.genes, ['BRCA1']);
      expect(reloaded.genome, genome.id);
      expect(reloaded.snp, snp.id);
    }, tags: ['integration']);

    // --- More options delegations ------------------------------------------
    test('options: create, update and delete', () async {
      final created =
          await endpoints.options.createProjectOptions(sessionBuilder);
      expect(created.silentMode, isFalse);
      final inserted = await endpoints.options
          .insertProjectOptions(sessionBuilder, ProjectOptions());
      await endpoints.options.updateProjectOptions(
          sessionBuilder, inserted.id!, ProjectOptions(id: inserted.id)..silentMode = true);
      await endpoints.options
          .deleteProjectOptions(sessionBuilder, inserted.id!);
      expect(
        () => endpoints.options.getProjectOptions(sessionBuilder, inserted.id!),
        throwsA(isA<FileNotFoundException>()),
      );
    }, tags: ['integration']);

    // --- More genome delegations -------------------------------------------
    test('genome: snp getters, category filter and updates', () async {
      final genome =
          await seedGenome(session, name: 'hg38', category: 'human');
      final s1 = await seedSnp(session, name: 'common', genome: genome.id);
      final byCat =
          await endpoints.genome.getGenomeByCategory(sessionBuilder, 'human');
      expect(byCat.map((g) => g.name), contains('hg38'));
      final snpsForGenome =
          await endpoints.genome.getAllSnpForGenome(sessionBuilder, genome.id!);
      expect(snpsForGenome.single.name, 'common');
      final gotSnp = await endpoints.genome.getSnp(sessionBuilder, s1.id!);
      expect(gotSnp.name, 'common');
      await endpoints.genome.updateGenome(
          sessionBuilder, genome.id!, genome..description = 'x');
    }, tags: ['integration']);

    // --- SnpEndpoint delegations -------------------------------------------
    test('snp: listing, renaming and sharing round-trip', () async {
      final genome = await seedGenome(session, name: 'hg38');
      final snp = await seedSnp(session,
          name: 'my panel', genome: genome.id, custom: true, private: true);

      final listed =
          await endpoints.snp.listSnpsForGenome(sessionBuilder, genome.id!);
      expect(listed.single.name, 'my panel');

      final renamed = await endpoints.snp
          .renameSnp(sessionBuilder, snp.id!, 'renamed', 'a note');
      expect(renamed.name, 'renamed');
      expect(renamed.description, 'a note');

      final shared =
          await endpoints.snp.setShared(sessionBuilder, snp.id!, true);
      expect(shared.private, isFalse);

      expect(
        (await endpoints.snp.listMySnps(sessionBuilder)).single.id,
        snp.id,
      );
    }, tags: ['integration']);

    test('snp: a global SNP cannot be changed through the ordinary path',
        () async {
      // The split between deleteCustomSnp and deleteSnpAsAdmin is what keeps a
      // user's delete button away from the shared genome tree. If this ever
      // passes, that separation has been lost.
      final scanned = await seedSnp(session, name: 'dbsnp');
      await expectLater(
        endpoints.snp.deleteCustomSnp(sessionBuilder, scanned.id!),
        throwsA(isA<ProjectAccessDeniedException>()),
      );
      await expectLater(
        endpoints.snp.setShared(sessionBuilder, scanned.id!, true),
        throwsA(isA<ProjectAccessDeniedException>()),
      );
    }, tags: ['integration']);

    test('snp: usage names the projects using an SNP', () async {
      final genome = await seedGenome(session, name: 'hg38');
      final snp = await seedSnp(session, genome: genome.id, custom: true);
      final options = await seedOptions(session);
      await seedProject(session,
          name: 'Cardio panel', options: options.id!, snp: snp.id);

      final usage = await endpoints.snp.snpUsage(sessionBuilder, snp.id!);
      expect(usage.single.projectName, 'Cardio panel');
    }, tags: ['integration']);

    // --- Settings + file readers -------------------------------------------
    test('settings: updateSettings persists', () async {
      final current = await endpoints.settings.getSettings(sessionBuilder, 'changeme');
      current.smtpFrom = 'test@flumip.local';
      await endpoints.settings
          .updateSettings(sessionBuilder, 'changeme', current);
      final again = await endpoints.settings.getSettings(sessionBuilder, 'changeme');
      expect(again.smtpFrom, 'test@flumip.local');
    }, tags: ['integration']);

    // Guards SettingsService.updateSettings, which merges an explicit list of
    // client-editable fields onto the stored row. A field added to the model but
    // forgotten in that list would silently write its default on every save, so
    // this round-trips every one of them with a distinct value.
    test('settings: updateSettings round-trips every client-editable field',
        () async {
      final current =
          await endpoints.settings.getSettings(sessionBuilder, 'changeme');
      final updated = current.copyWith(
        demoMode: true,
        baseDir: '/rt/base',
        projectDir: '/rt/projects',
        genomeDir: '/rt/genomes',
        customSnpDir: '/rt/snp',
        snpSourceAllowedHosts: 'rt.example, ftp.rt.example',
        toolsDir: '/rt/tools',
        mipgenExecutable: '/rt/mipgen',
        exonExtractScript: '/rt/exons.sh',
        ucscTrackGenerator: '/rt/track.py',
        binCreationScript: '/rt/bins.py',
        bigGenePredToGenePredExecutable: '/rt/bgp',
        mailActive: true,
        smtpServer: 'smtp.rt.example',
        smtpPort: 2525,
        smtpUser: 'rt-user',
        smtpPassword: 'rt-pass',
        smtpFrom: 'rt@flumip.local',
        startTLS: false,
        loginRequired: false,
        settingsPassword: 'changeme',
        oidcIssuer: 'https://rt.example/realms/rt',
        oidcClientId: 'rt-client',
        oidcScopes: 'openid email',
        oidcButtonLabel: 'RT login',
        oidcAllowedEmailDomains: 'rt.example',
        oidcAdminEmails: 'admin@rt.example',
        authPublicUrl: 'https://rt.example',
      );
      await endpoints.settings
          .updateSettings(sessionBuilder, 'changeme', updated);

      final again =
          await endpoints.settings.getSettings(sessionBuilder, 'changeme');
      final expected = updated.toJson()..remove('id');
      final actual = again.toJson()..remove('id');
      expect(actual, expected);
    }, tags: ['integration']);

    test('settings: updateSettings rejects an invalid password', () async {
      final current =
          await endpoints.settings.getSettings(sessionBuilder, 'changeme');
      expect(
        () => endpoints.settings
            .updateSettings(sessionBuilder, 'wrong', current),
        throwsMessage('Invalid password'),
      );
    }, tags: ['integration']);

    test('settings: sendTestMail rejects an invalid password', () async {
      expect(
        () => endpoints.settings
            .sendTestMail(sessionBuilder, 'wrong', 'someone@example.com'),
        throwsMessage('Invalid password'),
      );
    }, tags: ['integration']);

    test('file: readers return seeded project files', () async {
      final base = createTempDirLocal();
      await overrideSettingsDirs(session, projectDir: base.path);
      final project =
          await seedProject(session, options: 1, folderName: 'proj');
      final dir = Directory('${base.path}/proj')..createSync(recursive: true);
      File('${dir.path}/a.picked_mips.txt').writeAsStringSync('mip1\n');
      File('${dir.path}/a.snp_mips.txt').writeAsStringSync('snp1\n');
      File('${dir.path}/a.ucsc_track.bed').writeAsStringSync('track1\n');
      expect(await endpoints.file.showMipsResult(sessionBuilder, project.id!),
          ['mip1']);
      expect(await endpoints.file.showSnpMipsResult(sessionBuilder, project.id!),
          ['snp1']);
      expect(await endpoints.file.showUSCSTrack(sessionBuilder, project.id!),
          ['track1']);
    }, tags: ['integration']);
  });
}

/// Temp dir cleaned up after the whole group (endpoints run their own sessions,
/// so we avoid per-test [addTearDown] ordering surprises).
Directory createTempDirLocal() {
  final dir = Directory.systemTemp.createTempSync('flumip_endpoint_');
  addTearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  return dir;
}
