import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/services/file_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:test/test.dart';

import '../support/matchers.dart';

import '../integration/test_tools/serverpod_test_tools.dart';
import '../support/seed.dart';
import '../support/temp_dir.dart';

/// Polls [condition] until true or the timeout elapses. Used because
/// [FileService.deleteByproducts] does not await its `File.delete()` calls.
Future<void> eventually(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  throw StateError('condition not met within $timeout');
}

void main() {
  withServerpod('FileService', (sessionBuilder, endpoints) {
    setup();
    var session = sessionBuilder.build();
    final fileService = sl<FileService>();

    // Seeds a project with an on-disk directory under a fresh temp projectDir.
    Future<({int id, String dir})> prepareProject() async {
      final base = createTempDir('filesvc');
      await overrideSettingsDirs(session, projectDir: base.path);
      final project = await seedProject(session, options: 1, folderName: 'proj');
      final dir = '${base.path}/proj';
      Directory(dir).createSync(recursive: true);
      return (id: project.id!, dir: dir);
    }

    // --- getDirSize ---------------------------------------------------------
    test('getDirSize returns 0 for a missing directory', () async {
      expect(await fileService.getDirSize('/does/not/exist/xyz'), 0);
    }, tags: ['unit']);

    test('getDirSize returns 0 for an empty directory', () async {
      final dir = createTempDir('dirsize');
      expect(await fileService.getDirSize(dir.path), 0);
    }, tags: ['unit']);

    test('getDirSize sums nested file sizes', () async {
      final dir = createTempDir('dirsize');
      File('${dir.path}/a.txt').writeAsStringSync('12345'); // 5 bytes
      Directory('${dir.path}/sub').createSync();
      File('${dir.path}/sub/b.txt').writeAsStringSync('abc'); // 3 bytes
      await eventually(() => true); // let writes settle
      expect(await fileService.getDirSize(dir.path), 8);
    }, tags: ['unit']);

    // --- writeStringToFile / readFileAsString ------------------------------
    test('writeStringToFile writes the content', () async {
      final dir = createTempDir('write');
      final path = '${dir.path}/out.txt';
      await fileService.writeStringToFile(session, path, 'hello world');
      expect(File(path).readAsStringSync(), 'hello world');
    }, tags: ['unit']);

    test('readFileAsString returns the matching file content', () async {
      final p = await prepareProject();
      File('${p.dir}/notes.txt').writeAsStringSync('content here');
      expect(
        await fileService.readFileAsString(session, p.id, 'notes.txt'),
        'content here',
      );
    }, tags: ['unit']);

    test('readFileAsString returns empty string when file is absent', () async {
      final p = await prepareProject();
      expect(await fileService.readFileAsString(session, p.id, 'nope.txt'), '');
    }, tags: ['unit']);

    // --- createGeneFile -----------------------------------------------------
    test('createGeneFile writes the genes to genes.txt', () async {
      final p = await prepareProject();
      await fileService.createGeneFile(session, p.id, ['BRCA1', 'TP53']);
      final lines = File('${p.dir}/genes.txt').readAsLinesSync();
      expect(lines, ['BRCA1', 'TP53']);
    }, tags: ['unit']);

    test('createGeneFile throws when the project directory is missing',
        () async {
      final base = createTempDir('nodir');
      await overrideSettingsDirs(session, projectDir: base.path);
      // Seed the project row but do NOT create its directory.
      final project = await seedProject(session, options: 1, folderName: 'gone');
      expect(
        () => fileService.createGeneFile(session, project.id!, ['BRCA1']),
        throwsMessage('Project directory does not exist'),
      );
    }, tags: ['unit']);

    // --- checkBedFileExists -------------------------------------------------
    test('checkBedFileExists is false when the bed file is absent', () async {
      final p = await prepareProject();
      expect(await fileService.checkBedFileExists(session, p.id), isFalse);
    }, tags: ['unit']);

    test('checkBedFileExists is false when the bed file is <= 1024 bytes',
        () async {
      final p = await prepareProject();
      File('${p.dir}/genes.bed').writeAsStringSync('small');
      expect(await fileService.checkBedFileExists(session, p.id), isFalse);
    }, tags: ['unit']);

    test('checkBedFileExists is true when the bed file is > 1024 bytes',
        () async {
      final p = await prepareProject();
      File('${p.dir}/genes.bed').writeAsStringSync('x' * 2000);
      expect(await fileService.checkBedFileExists(session, p.id), isTrue);
    }, tags: ['unit']);

    // --- deleteGeneFile -----------------------------------------------------
    test('deleteGeneFile removes genes.txt', () async {
      final p = await prepareProject();
      final file = File('${p.dir}/genes.txt')..writeAsStringSync('BRCA1');
      await fileService.deleteGeneFile(session, p.id);
      expect(file.existsSync(), isFalse);
    }, tags: ['unit']);

    test('deleteGeneFile throws for a missing project', () async {
      expect(
        () => fileService.deleteGeneFile(session, -1),
        throwsMessage('Project id does not exist'),
      );
    }, tags: ['unit']);

    // --- deleteByproducts ---------------------------------------------------
    test('deleteByproducts removes only .sai and .fq files', () async {
      final p = await prepareProject();
      final sai = File('${p.dir}/x.sai')..writeAsStringSync('a');
      final fq = File('${p.dir}/y.fq')..writeAsStringSync('b');
      final keep = File('${p.dir}/z.txt')..writeAsStringSync('c');
      await fileService.deleteByproducts(session, p.id);
      await eventually(() => !sai.existsSync() && !fq.existsSync());
      expect(keep.existsSync(), isTrue);
    }, tags: ['unit']);

    test('deleteByproducts throws when the project directory is missing',
        () async {
      final base = createTempDir('nobp');
      await overrideSettingsDirs(session, projectDir: base.path);
      final project = await seedProject(session, options: 1, folderName: 'gone');
      expect(
        () => fileService.deleteByproducts(session, project.id!),
        throwsA(isA<FileNotFoundException>()),
      );
    }, tags: ['unit']);

    // --- show* readers ------------------------------------------------------
    test('showMipsProgress returns the progress file lines', () async {
      final p = await prepareProject();
      File('${p.dir}/run.progress.txt').writeAsStringSync('10%\n20%\n');
      expect(await fileService.showMipsProgress(session, p.id), ['10%', '20%']);
    }, tags: ['unit']);

    test('showMipsProgress returns empty when no progress file exists',
        () async {
      final p = await prepareProject();
      expect(await fileService.showMipsProgress(session, p.id), isEmpty);
    }, tags: ['unit']);

    test('showMipsResult / showSnpMipsResult / showUSCSTrack read their files',
        () async {
      final p = await prepareProject();
      File('${p.dir}/a.picked_mips.txt').writeAsStringSync('mip1\n');
      File('${p.dir}/a.snp_mips.txt').writeAsStringSync('snp1\n');
      File('${p.dir}/a.ucsc_track.bed').writeAsStringSync('track1\n');
      expect(await fileService.showMipsResult(session, p.id), ['mip1']);
      expect(await fileService.showSnpMipsResult(session, p.id), ['snp1']);
      expect(await fileService.showUSCSTrack(session, p.id), ['track1']);
    }, tags: ['unit']);

    test('showMipsProgress throws for a missing project', () async {
      expect(
        () => fileService.showMipsProgress(session, -1),
        throwsA(isA<FileNotFoundException>()),
      );
    }, tags: ['unit']);

    // --- returnFile ---------------------------------------------------------
    test('returnFile streams the matching file bytes', () async {
      final p = await prepareProject();
      File('${p.dir}/data.bin').writeAsStringSync('streamed');
      final stream = await fileService.returnFile(session, p.id, 'data.bin');
      final bytes = await stream.expand((chunk) => chunk).toList();
      expect(String.fromCharCodes(bytes), 'streamed');
    }, tags: ['unit']);

    test('returnFile returns an empty stream when the file is absent',
        () async {
      final p = await prepareProject();
      final stream = await fileService.returnFile(session, p.id, 'missing.bin');
      expect(await stream.isEmpty, isTrue);
    }, tags: ['unit']);

    // --- downloads ----------------------------------------------------------
    group('listProjectFiles', () {
      test('returns every file with its size, sorted', () async {
        final p = await prepareProject();
        File('${p.dir}/b.txt').writeAsStringSync('hello');
        File('${p.dir}/a.txt').writeAsStringSync('hi');
        Directory('${p.dir}/sub').createSync();

        final files = await fileService.listProjectFiles(session, p.id);

        expect(files.map((f) => f.name), ['a.txt', 'b.txt']);
        expect(files.first.sizeBytes, 2);
        expect(files.last.sizeBytes, 5);
      }, tags: ['unit']);

      test('is empty for a project whose generation never ran', () async {
        // Not an error: there is simply nothing to download yet.
        final base = createTempDir('nofiles');
        await overrideSettingsDirs(session, projectDir: base.path);
        final project =
            await seedProject(session, options: 1, folderName: 'never-ran');

        expect(await fileService.listProjectFiles(session, project.id!),
            isEmpty);
      }, tags: ['unit']);
    });

    group('resolveProjectFile', () {
      test('finds a file in the project directory', () async {
        final p = await prepareProject();
        File('${p.dir}/mips.txt').writeAsStringSync('x');

        final file = await fileService.resolveProjectFile(
          session,
          p.id,
          'mips.txt',
        );
        expect(file, isNotNull);
        expect(await file!.readAsString(), 'x');
      }, tags: ['unit']);

      test('refuses to escape the project directory', () async {
        // The guard. The name arrives from a URL, so anything that is not a
        // bare file name is rejected outright — otherwise the route becomes an
        // arbitrary-file-read on the server.
        final p = await prepareProject();
        final outside = File('${Directory(p.dir).parent.path}/secret.txt')
          ..writeAsStringSync('nope');
        expect(outside.existsSync(), isTrue, reason: 'the target really exists');

        for (final name in [
          '../secret.txt',
          '../../etc/passwd',
          '/etc/passwd',
          'sub/../../secret.txt',
          r'..\secret.txt',
          '..',
          '',
        ]) {
          expect(
            await fileService.resolveProjectFile(session, p.id, name),
            isNull,
            reason: 'must refuse "$name"',
          );
        }
      }, tags: ['unit']);

      test('refuses a symlink pointing out of the directory', () async {
        // A bare name is not enough on its own: the resolved path has to be
        // inside the project directory too.
        final p = await prepareProject();
        final outside = File('${Directory(p.dir).parent.path}/secret.txt')
          ..writeAsStringSync('nope');
        Link('${p.dir}/innocent.txt').createSync(outside.path);

        expect(
          await fileService.resolveProjectFile(session, p.id, 'innocent.txt'),
          isNull,
        );
      }, tags: ['unit']);

      test('returns null for a name that is simply not there', () async {
        final p = await prepareProject();
        expect(
          await fileService.resolveProjectFile(session, p.id, 'missing.txt'),
          isNull,
        );
      }, tags: ['unit']);
    });

    group('zipProjectFiles', () {
      test('zips every file and the archive round-trips', () async {
        final p = await prepareProject();
        File('${p.dir}/a.txt').writeAsStringSync('alpha');
        File('${p.dir}/b.txt').writeAsStringSync('beta');

        final zip = await fileService.zipProjectFiles(session, p.id);
        expect(zip, isNotNull);
        addTearDown(() => zip!.existsSync() ? zip.deleteSync() : null);

        final archive = ZipDecoder().decodeBytes(await zip!.readAsBytes());
        expect(archive.files.map((f) => f.name).toList()..sort(),
            ['a.txt', 'b.txt']);
        final alpha = archive.files.firstWhere((f) => f.name == 'a.txt');
        expect(utf8.decode(alpha.content as List<int>), 'alpha');
      }, tags: ['unit']);

      test('returns null when there is nothing to zip', () async {
        // So the route can 404 rather than hand back an empty archive, which
        // looks like a broken download.
        final p = await prepareProject();
        expect(await fileService.zipProjectFiles(session, p.id), isNull);
      }, tags: ['unit']);
    });
  });
}
