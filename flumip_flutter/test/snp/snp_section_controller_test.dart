import 'dart:async';

import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/snp/picked_file.dart';
import 'package:flumip_flutter/snp/snp_section_controller.dart';
import 'package:flumip_flutter/snp/snp_transport.dart';
import 'package:flumip_flutter/snp/snp_upload_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// One genome's SNP list, with the server replaced by closures.
///
/// ⚠️ This was the last tab-level widget reaching for `client` in its own
/// `initState`, and the reason `genome_tab_test` could not select a genome.
Snp snpFixture({
  int id = 1,
  String name = 'panel',
  bool private = true,
  bool custom = true,
  SnpImportStatus status = SnpImportStatus.ready,
}) => Snp(
  id: id,
  name: name,
  vcfPath: '/opt/flumip/data/custom_snp/user/$id/set.vcf.gz',
  tbiPath: '/opt/flumip/data/custom_snp/user/$id/set.vcf.gz.tbi',
  folder: '/opt/flumip/data/custom_snp/user/$id',
  active: true,
  custom: custom,
  private: private,
  status: status,
  statusMessage: '',
  size: 1000,
  bytesDownloaded: 0,
  totalBytes: 0,
  created: DateTime(2026),
);

CustomSnpRequestDto requestFixture({String name = 'new set'}) =>
    CustomSnpRequestDto(
      name: name,
      description: '',
      genomeId: 3,
      private: true,
    );

/// A transport that never finishes, so `anyLive` can be made true on demand.
class StalledTransport implements SnpTransport {
  final started = <int>[];

  @override
  SnpUploadHandle put({
    required int snpId,
    required PickedFile file,
    required void Function(int sent, int total) onProgress,
  }) {
    started.add(snpId);
    return SnpUploadHandle(Completer<void>().future, () {});
  }
}

class Harness {
  Harness({List<Snp>? snps, List<Snp>? mine, this.admin = false})
    : snps = snps ?? [snpFixture()],
      mine = mine ?? const [] {
    _build();
  }

  List<Snp> snps;
  List<Snp> mine;
  bool admin;

  Object? loadThrows;
  Object? actionThrows;
  Object? usageThrows;
  List<SnpUsageDto> usage = const [];

  final calls = <String>[];
  final messages = <String>[];
  final auth = ChangeNotifier();
  final access = ChangeNotifier();
  final transport = StalledTransport();
  late final SnpUploadController uploads;
  late final SnpSectionController controller;

  void _build() {
    uploads = SnpUploadController(
      transport: transport,
      finishUpload: (snpId) async => calls.add('finish $snpId'),
    );
    controller = SnpSectionController(
      genomeId: 3,
      loadSnps: (id) async {
        calls.add('snps $id');
        if (loadThrows != null) throw loadThrows!;
        return snps;
      },
      loadMySnps: () async {
        calls.add('mine');
        return mine;
      },
      setShared: (id, shared) async {
        calls.add('shared $id=$shared');
        if (actionThrows != null) throw actionThrows!;
      },
      rename: (id, name, description) async {
        calls.add('rename $id "$name"');
        if (actionThrows != null) throw actionThrows!;
      },
      retryImport: (id) async {
        calls.add('retry $id');
        if (actionThrows != null) throw actionThrows!;
      },
      cancelUpload: (id) async {
        calls.add('cancelUpload $id');
        if (actionThrows != null) throw actionThrows!;
      },
      deleteSnp: (id) async {
        calls.add('delete $id');
        if (actionThrows != null) throw actionThrows!;
      },
      deleteAsAdmin: (id, password, {required force}) async {
        calls.add('adminDelete $id password=$password force=$force');
        if (actionThrows != null) throw actionThrows!;
      },
      loadUsage: (id) async {
        calls.add('usage $id');
        if (usageThrows != null) throw usageThrows!;
        return usage;
      },
      importFromUrls: (request) async {
        calls.add('import ${request.name}');
        if (actionThrows != null) throw actionThrows!;
      },
      createUpload: (request) async {
        calls.add('createUpload ${request.name}');
        if (actionThrows != null) throw actionThrows!;
        return snpFixture(id: 42, name: request.name);
      },
      uploads: uploads,
      isAdmin: () => admin,
      auth: auth,
      access: access,
    );
    controller.messages.listen(messages.add);
  }

  void dispose() {
    controller.dispose();
    uploads.dispose();
  }
}

void main() {
  group('loading', () {
    test('lists the sets and marks the ones this caller added', () async {
      final h = Harness(
        snps: [snpFixture(id: 1), snpFixture(id: 2)],
        mine: [snpFixture(id: 2)],
      );
      addTearDown(h.dispose);

      await h.controller.load();

      expect(h.controller.snps, hasLength(2));
      expect(h.controller.isMine(snpFixture(id: 2)), isTrue);
      expect(h.controller.isMine(snpFixture(id: 1)), isFalse);
    });

    test('⚠️ the order is stable, whatever the server returns', () async {
      // Reported: a set jumped to the bottom, or one step, when it was shared or
      // while it was downloading. An unordered Postgres query returns heap
      // order, and an UPDATE rewrites the row at the end of the heap — so any
      // write moved the row under the cursor.
      final h = Harness(
        snps: [snpFixture(id: 3), snpFixture(id: 1), snpFixture(id: 2)],
      );
      addTearDown(h.dispose);

      await h.controller.load();
      expect(h.controller.snps!.map((s) => s.id), [1, 2, 3]);

      // The server hands them back in a different order after a write.
      h.snps = [snpFixture(id: 2), snpFixture(id: 3), snpFixture(id: 1)];
      await h.controller.load();

      expect(h.controller.snps!.map((s) => s.id), [1, 2, 3]);
    });

    test('sorts a copy, never the caller\'s list', () async {
      final h = Harness(
        snps: List.unmodifiable([snpFixture(id: 2), snpFixture(id: 1)]),
      );
      addTearDown(h.dispose);

      await h.controller.load();

      expect(h.controller.snps!.map((s) => s.id), [1, 2]);
    });

    test('a failure is reported', () async {
      final h = Harness()..loadThrows = Exception('down');
      addTearDown(h.dispose);

      await h.controller.load();

      expect(h.controller.errorMessage, contains('Could not load SNP sets'));
    });

    test('⚠️ a refusal empties the list and stops the poll', () async {
      // A revoked session would otherwise re-report the same refusal every
      // couple of seconds for as long as the tab is open.
      final h = Harness()
        ..loadThrows = ProjectAccessDeniedException(message: 'no');
      addTearDown(h.dispose);

      await h.controller.load();

      expect(h.controller.snps, isEmpty);
      expect(h.controller.errorMessage, isNull);
      expect(h.controller.polling, isFalse);
    });

    test('changing genome clears the list before refetching', () async {
      final h = Harness();
      addTearDown(h.dispose);
      await h.controller.load();
      expect(h.controller.snps, isNotNull);
      h.calls.clear();

      final pending = h.controller.showGenome(9);
      expect(
        h.controller.snps,
        isNull,
        reason: "the old genome's sets must not sit under the new heading",
      );
      await pending;

      expect(h.calls, contains('snps 9'));
    });

    test('showing the same genome again does not refetch', () async {
      final h = Harness();
      addTearDown(h.dispose);
      await h.controller.load();
      h.calls.clear();

      await h.controller.showGenome(3);

      expect(h.calls, isEmpty);
    });

    test('⚠️ signing in throws the previous caller\'s answer away', () async {
      // The whole list depends on who is asking.
      final h = Harness(snps: [snpFixture()], mine: [snpFixture()]);
      addTearDown(h.dispose);
      await h.controller.load();
      expect(h.controller.isMine(snpFixture()), isTrue);

      h.mine = const [];
      h.auth.notifyListeners();
      await pumpEventQueue();

      expect(h.controller.isMine(snpFixture()), isFalse);
    });
  });

  group('the poll', () {
    test('keeps running while an import is not finished', () async {
      final h = Harness(
        snps: [snpFixture(status: SnpImportStatus.downloading)],
      );
      addTearDown(h.dispose);

      await h.controller.load();

      expect(h.controller.polling, isTrue);
    });

    test('⚠️ keeps running while a browser upload is in flight', () async {
      // The server cannot see how far a PUT has got, so a list of otherwise
      // settled sets still has to be watched while one is being sent.
      final h = Harness(snps: [snpFixture(status: SnpImportStatus.ready)]);
      addTearDown(h.dispose);
      h.uploads.start(
        snpId: 1,
        vcf: const PickedFile(name: 'set.vcf.gz', size: 10, handle: 0),
      );

      await h.controller.load();

      expect(h.uploads.anyLive, isTrue);
      expect(h.controller.polling, isTrue);
    });
  });

  group('sharing', () {
    test('flips at once and sends the change', () async {
      final h = Harness();
      addTearDown(h.dispose);
      await h.controller.load();
      final snp = h.controller.snps!.single;
      h.calls.clear();

      await h.controller.setShared(snp, true);

      expect(snp.private, isFalse);
      expect(h.calls.first, 'shared 1=true');
    });

    test('⚠️ a refusal puts it back and says so', () async {
      final h = Harness()..actionThrows = Exception('read only');
      addTearDown(h.dispose);
      await h.controller.load();
      final snp = h.controller.snps!.single;
      expect(snp.private, isTrue);

      await h.controller.setShared(snp, true);
      await pumpEventQueue();

      expect(snp.private, isTrue, reason: 'rolled back');
      expect(h.messages.single, contains('Could not change sharing'));
    });
  });

  group('the row actions', () {
    test('each one reloads the list afterwards', () async {
      final h = Harness();
      addTearDown(h.dispose);
      await h.controller.load();
      final snp = h.controller.snps!.single;
      h.calls.clear();

      await h.controller.retry(snp);

      expect(h.calls, ['retry 1', 'snps 3', 'mine']);
    });

    test('a cancelled upload slot says what went', () async {
      final h = Harness();
      addTearDown(h.dispose);
      await h.controller.load();

      await h.controller.cancelUpload(h.controller.snps!.single);
      await pumpEventQueue();

      expect(h.messages.single, 'Removed "panel".');
    });

    test('a delete names the set', () async {
      final h = Harness();
      addTearDown(h.dispose);
      await h.controller.load();

      await h.controller.delete(h.controller.snps!.single);
      await pumpEventQueue();

      expect(h.messages.single, 'Deleted "panel" and its files.');
    });

    test('a failure reports rather than throwing', () async {
      final h = Harness()..actionThrows = Exception('refused');
      addTearDown(h.dispose);
      await h.controller.load();

      await h.controller.delete(h.controller.snps!.single);
      await pumpEventQueue();

      expect(h.messages.single, contains('Could not delete the SNP set'));
    });

    test('⚠️ an admin delete carries a null password when signed in', () async {
      // A signed-in administrator needs none; the settings password is only the
      // administrative credential on an install that is not enforcing sign-in.
      final h = Harness(admin: true);
      addTearDown(h.dispose);
      await h.controller.load();
      h.calls.clear();

      await h.controller.deleteAsAdmin(
        h.controller.snps!.single,
        null,
        force: false,
      );

      expect(h.calls.first, 'adminDelete 1 password=null force=false');
    });

    test('force is passed through', () async {
      final h = Harness();
      addTearDown(h.dispose);
      await h.controller.load();
      h.calls.clear();

      await h.controller.deleteAsAdmin(
        h.controller.snps!.single,
        'hunter2',
        force: true,
      );

      expect(h.calls.first, 'adminDelete 1 password=hunter2 force=true');
    });
  });

  group('usage, before a confirmation dialog', () {
    test('names the projects using the set', () async {
      final h = Harness()
        ..usage = [SnpUsageDto(projectId: 5, projectName: 'panel A')];
      addTearDown(h.dispose);

      expect(await h.controller.usage(snpFixture()), hasLength(1));
    });

    test('⚠️ null when the lookup itself failed, never empty', () async {
      // The dialog has to be able to say "could not check" instead of implying
      // "nothing is using it".
      final h = Harness()..usageThrows = Exception('down');
      addTearDown(h.dispose);

      expect(await h.controller.usage(snpFixture()), isNull);
    });
  });

  group('adding a set', () {
    test('a URL import says what it started', () async {
      final h = Harness();
      addTearDown(h.dispose);
      await h.controller.load();
      h.calls.clear();

      await h.controller.importFromUrls(requestFixture(), 'new set');
      await pumpEventQueue();

      expect(h.calls.first, 'import new set');
      expect(h.messages.single, contains('Downloading "new set"'));
    });

    test(
      '⚠️ an upload creates the row, reloads, then hands off the transfer',
      () async {
        // The transfer must not be owned by anything that can be closed: it takes
        // minutes, and this section is rebuilt whenever the genome changes.
        final h = Harness();
        addTearDown(h.dispose);
        await h.controller.load();
        h.calls.clear();

        await h.controller.startUpload(
          requestFixture(),
          vcf: const PickedFile(name: 'set.vcf.gz', size: 10, handle: 0),
        );

        expect(h.calls, ['createUpload new set', 'snps 3', 'mine']);
        expect(h.transport.started, [42], reason: 'handed to the uploader');
      },
    );

    test('a refused upload slot never starts a transfer', () async {
      final h = Harness()..actionThrows = Exception('no room');
      addTearDown(h.dispose);
      await h.controller.load();

      await h.controller.startUpload(
        requestFixture(),
        vcf: const PickedFile(name: 'set.vcf.gz', size: 10, handle: 0),
      );
      await pumpEventQueue();

      expect(h.transport.started, isEmpty);
      expect(h.messages.single, contains('Could not start the upload'));
    });
  });

  test('admin-ness follows the access controller', () async {
    final h = Harness(admin: false);
    addTearDown(h.dispose);
    expect(h.controller.isAdmin, isFalse);

    h.admin = true;

    expect(h.controller.isAdmin, isTrue);
  });

  test('the error can be dismissed', () async {
    final h = Harness()..loadThrows = Exception('down');
    addTearDown(h.dispose);
    await h.controller.load();

    h.controller.dismissError();

    expect(h.controller.errorMessage, isNull);
  });

  test('⚠️ a call landing after dispose does not throw', () async {
    final h = Harness();
    final pending = h.controller.load();
    h.dispose();

    await expectLater(pending, completes);
  });
}
