import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';
import '../support/fake_process_runner.dart';
import '../support/seed.dart';
import '../support/temp_dir.dart';

/// MipgenService with the progress poll stubbed out, as in
/// `mipgen_service_test.dart`.
class _NoScheduleMipgenService extends MipgenService {
  @override
  Future<void> scheduleMipgenProgressCheck(
    Session session,
    Project project, {
    Duration delay = const Duration(seconds: 10),
  }) async {}
}

final fake = FakeProcessRunner();

void main() {
  group('mipgenOptionsProblem', () {
    test('the defaults are fine', () {
      expect(mipgenOptionsProblem(ProjectOptions()), isNull);
    }, tags: ['unit']);

    test('arm lengths, sums and tag sizes in the shapes mipgen parses', () {
      expect(
        mipgenOptionsProblem(
          ProjectOptions(
            armLengths: '16:24, 16:25,16:26',
            armLengthSums: '40, 41',
            tagSizes: '5',
          ),
        ),
        isNull,
      );
      expect(mipgenOptionsProblem(ProjectOptions(armLengths: '')), isNull);
    }, tags: ['unit']);

    for (final (what, options) in [
      // mipgen's parser reads any argv starting with `-` as an option name.
      ('a negative whole number', ProjectOptions(maxMipOverlap: -1)),
      ('a negative decimal', ProjectOptions(logisticOptimalScore: -0.5)),
      ('NaN', ProjectOptions(maskedArmThreshold: double.nan)),
      ('infinity', ProjectOptions(svrPriorityScore: double.infinity)),
      ('an overflowing number', ProjectOptions(maxCaptureSize: 1 << 40)),
      ('an option name as arm lengths', ProjectOptions(armLengths: '-bwa')),
      ('a command in arm lengths', ProjectOptions(armLengths: '16:24;id')),
      ('empty arm length sums', ProjectOptions(armLengthSums: '')),
      ('an option name as sums', ProjectOptions(armLengthSums: '-trf')),
      ('a substitution in sums', ProjectOptions(armLengthSums: r'40,$(id)')),
      ('a pipe in tag sizes', ProjectOptions(tagSizes: '5,0|sh')),
      ('three tag sizes', ProjectOptions(tagSizes: '5,0,1')),
    ]) {
      test('refuses $what', () {
        expect(mipgenOptionsProblem(options), isNotNull);
      }, tags: ['unit']);
    }
  });

  withServerpod('MipgenService and client-supplied options', (
    sessionBuilder,
    endpoints,
  ) {
    setup(processRunner: fake);
    setUp(fake.reset);
    final session = sessionBuilder.build();

    /// A runnable project whose options row is written directly, the way a row
    /// from before the checks existed — or from anything that bypasses
    /// `OptionsService` — would be.
    Future<Project> seedWith(ProjectOptions options) async {
      final base = createTempDir('mipgen_options');
      await overrideSettingsDirs(
        session,
        projectDir: base.path,
        mipgenExecutable: 'mipgen-exe',
      );
      final row = await ProjectOptions.db.insertRow(session, options);
      final genome = await seedGenome(
        session,
        name: 'hg38',
        fastaPath: '/data/hg38.fa',
      );
      Directory('${base.path}/proj').createSync(recursive: true);
      fake.stubRun('pgrep', exitCode: 0, stdout: '777 mipgen\n');
      return seedProject(
        session,
        name: 'demo',
        options: row.id!,
        folderName: 'proj',
        genome: genome.id,
      );
    }

    List<String> mipgenArgs() => fake.startCalls
        .firstWhere((c) => c.executable == 'mipgen-exe')
        .arguments;

    test('a stored genome directory never reaches mipgen', () async {
      // It was passed as `-genome_dir` verbatim: a path of the client's
      // choosing for mipgen to read, or with a leading `-`, an option name.
      final project = await seedWith(
        ProjectOptions(armLengths: '', genomeDir: '-file_of_parameters'),
      );

      await _NoScheduleMipgenService().generateMips(
        session,
        project.id!,
        false,
      );

      final args = mipgenArgs();
      expect(args, isNot(contains('-genome_dir')));
      expect(args, isNot(contains('-file_of_parameters')));
    }, tags: ['unit']);

    test('an option that would re-bind -bwa is refused, not run', () async {
      // `-arm_lengths -bwa -arm_length_sums <x>`: mipgen reads `-bwa` as an
      // option and takes the next argv as the command it runs with system().
      final project = await seedWith(ProjectOptions(armLengths: '-bwa'));

      await expectLater(
        _NoScheduleMipgenService().generateMips(session, project.id!, false),
        throwsA(
          isA<ArgumentException>().having(
            (e) => e.message,
            'message',
            contains('Arm lengths'),
          ),
        ),
      );
      expect(
        fake.startCalls.where((c) => c.executable == 'mipgen-exe'),
        isEmpty,
      );
    }, tags: ['unit']);

    test('a negative number is refused, not run', () async {
      final project = await seedWith(
        ProjectOptions(armLengths: '', featureFlank: -5),
      );

      await expectLater(
        _NoScheduleMipgenService().generateMips(session, project.id!, false),
        throwsA(isA<ArgumentException>()),
      );
      expect(
        fake.startCalls.where((c) => c.executable == 'mipgen-exe'),
        isEmpty,
      );
    }, tags: ['unit']);

    test('spaces after commas are taken out on the way to mipgen', () async {
      final project = await seedWith(
        ProjectOptions(
          armLengths: '16:24, 16:25',
          armLengthSums: '40, 41',
          tagSizes: '5, 0',
        ),
      );

      await _NoScheduleMipgenService().generateMips(
        session,
        project.id!,
        false,
      );

      final args = mipgenArgs();
      expect(args[args.indexOf('-arm_lengths') + 1], '16:24,16:25');
      expect(args[args.indexOf('-arm_length_sums') + 1], '40,41');
      expect(args[args.indexOf('-tag_sizes') + 1], '5,0');
      expect(
        args.where((a) => a.startsWith('-')).length * 2,
        args.length,
        reason: 'every value follows its option; none looks like one',
      );
    }, tags: ['unit']);
  });
}
