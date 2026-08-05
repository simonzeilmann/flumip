import 'dart:async';

import 'package:flumip_flutter/snp/picked_file.dart';
import 'package:flumip_flutter/snp/snp_transport.dart';
import 'package:flumip_flutter/snp/snp_upload_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// One scripted PUT.
class ScriptedPut {
  ScriptedPut(this.snpId, this.file);
  final int snpId;
  final PickedFile file;
  final completer = Completer<void>();
  void Function(int, int)? onProgress;
  var cancelled = false;
}

/// A [SnpTransport] that records calls and lets the test decide when each
/// finishes. No browser, no network.
class FakeTransport implements SnpTransport {
  final List<ScriptedPut> puts = <ScriptedPut>[];

  /// When set, every put fails with this immediately.
  Object? failWith;

  @override
  SnpUploadHandle put({
    required int snpId,
    required PickedFile file,
    required void Function(int sent, int total) onProgress,
  }) {
    final put = ScriptedPut(snpId, file)..onProgress = onProgress;
    puts.add(put);
    if (failWith != null) {
      put.completer.completeError(failWith!);
    }
    return SnpUploadHandle(put.completer.future, () {
      put.cancelled = true;
      if (!put.completer.isCompleted) {
        put.completer.completeError(const SnpUploadCancelled());
      }
    });
  }
}

PickedFile file(String name, int size) =>
    PickedFile(name: name, size: size, handle: Object());

void main() {
  late FakeTransport transport;
  late List<int> finished;
  late SnpUploadController controller;
  Object? finishError;

  setUp(() {
    transport = FakeTransport();
    finished = [];
    finishError = null;
    controller = SnpUploadController(
      transport: transport,
      finishUpload: (id) async {
        if (finishError != null) throw finishError!;
        finished.add(id);
      },
    );
  });

  test('one file: sends it, then tells the server it is finished', () async {
    final job = controller.start(snpId: 7, vcf: file('a.vcf.gz', 100));
    await pumpEventQueue();

    expect(transport.puts, hasLength(1));
    expect(transport.puts.single.snpId, 7);
    expect(finished, isEmpty, reason: 'not until the bytes have landed');

    transport.puts.single.completer.complete();
    await job;

    expect(finished, [7]);
    expect(controller[7], isNull, reason: 'a finished job stops being shown');
  });

  test('two files are sent one after the other, not at once', () async {
    // ⚠️ Two 1.5 GB streams fight for the same pipe and make both bars
    // meaningless. Sequential is also what lets one bar describe the whole job.
    final job = controller.start(
      snpId: 7,
      vcf: file('a.vcf.gz', 100),
      tbi: file('a.vcf.gz.tbi', 20),
    );
    await pumpEventQueue();

    expect(transport.puts, hasLength(1));
    expect(transport.puts.single.file.name, 'a.vcf.gz');

    transport.puts.first.completer.complete();
    await pumpEventQueue();

    expect(transport.puts, hasLength(2));
    expect(transport.puts.last.file.name, 'a.vcf.gz.tbi');
    expect(finished, isEmpty);

    transport.puts.last.completer.complete();
    await job;

    expect(finished, [7]);
  });

  test('finishUpload is NOT called when the index upload fails', () async {
    // ⚠️ finishUpload is what reads the directory and settles the row. Calling it
    // after a dropped second PUT would mark an SNP set complete when its index
    // never arrived.
    final job = controller.start(
      snpId: 7,
      vcf: file('a.vcf.gz', 100),
      tbi: file('a.vcf.gz.tbi', 20),
    );
    await pumpEventQueue();
    transport.puts.first.completer.complete();
    await pumpEventQueue();
    transport.puts.last.completer.completeError(
      const SnpUploadException(403, ''),
    );
    await job;

    expect(finished, isEmpty);
    expect(controller[7], isNotNull);
    expect(controller[7]!.error, isNotNull);
  });

  test('progress covers both files with a single running total', () async {
    final job = controller.start(
      snpId: 7,
      vcf: file('a.vcf.gz', 100),
      tbi: file('a.vcf.gz.tbi', 20),
    );
    await pumpEventQueue();

    expect(controller[7]!.total, 120);

    transport.puts.first.onProgress!(50, 100);
    expect(controller[7]!.sent, 50);
    expect(controller[7]!.fraction, closeTo(50 / 120, 0.001));

    transport.puts.first.completer.complete();
    await pumpEventQueue();

    // The second file's bytes are offset by the first file's size.
    transport.puts.last.onProgress!(10, 20);
    expect(controller[7]!.sent, 110);

    transport.puts.last.completer.complete();
    await job;
  });

  test('a failed first upload never starts the second', () async {
    transport.failWith = const SnpUploadException(413, '');
    await controller.start(
      snpId: 7,
      vcf: file('a.vcf.gz', 100),
      tbi: file('a.vcf.gz.tbi', 20),
    );

    expect(transport.puts, hasLength(1));
    expect(finished, isEmpty);
    expect(controller[7]!.error, contains('larger than'));
  });

  test('cancelling marks the job cancelled rather than errored', () async {
    final job = controller.start(snpId: 7, vcf: file('a.vcf.gz', 100));
    await pumpEventQueue();

    controller.cancel(7);
    await job;

    expect(transport.puts.single.cancelled, isTrue);
    expect(controller[7]!.cancelled, isTrue);
    expect(finished, isEmpty);
  });

  test('a failing finishUpload is reported, not swallowed', () async {
    finishError = Exception('server said no');
    final job = controller.start(snpId: 7, vcf: file('a.vcf.gz', 100));
    await pumpEventQueue();
    transport.puts.single.completer.complete();
    await job;

    expect(controller[7]!.error, isNotNull);
  });

  test('anyLive reflects whether something is still moving', () async {
    expect(controller.anyLive, isFalse);

    final job = controller.start(snpId: 7, vcf: file('a.vcf.gz', 100));
    await pumpEventQueue();
    expect(controller.anyLive, isTrue, reason: 'drives the tighter poll rate');

    transport.puts.single.completer.complete();
    await job;
    expect(controller.anyLive, isFalse);
  });

  test('a cancelled job is not live', () async {
    final job = controller.start(snpId: 7, vcf: file('a.vcf.gz', 100));
    await pumpEventQueue();
    controller.cancel(7);
    await job;
    expect(controller.anyLive, isFalse);
  });

  test('dismiss forgets a failed job', () async {
    transport.failWith = const SnpUploadException(0, '');
    await controller.start(snpId: 7, vcf: file('a.vcf.gz', 100));
    expect(controller[7], isNotNull);

    controller.dismiss(7);

    expect(controller[7], isNull);
    expect(controller.isEmpty, isTrue);
  });

  test('two SNP sets upload independently', () async {
    final a = controller.start(snpId: 1, vcf: file('a.vcf.gz', 100));
    final b = controller.start(snpId: 2, vcf: file('b.vcf.gz', 200));
    await pumpEventQueue();

    expect(controller[1]!.total, 100);
    expect(controller[2]!.total, 200);

    transport.puts.firstWhere((p) => p.snpId == 1).completer.complete();
    await a;
    expect(finished, [1]);
    expect(controller[2], isNotNull, reason: 'the other one keeps going');

    transport.puts.firstWhere((p) => p.snpId == 2).completer.complete();
    await b;
    expect(finished, [1, 2]);
  });

  test('it notifies listeners as progress arrives', () async {
    var notifications = 0;
    controller.addListener(() => notifications++);

    final job = controller.start(snpId: 7, vcf: file('a.vcf.gz', 100));
    await pumpEventQueue();
    transport.puts.single.onProgress!(50, 100);
    transport.puts.single.completer.complete();
    await job;

    expect(notifications, greaterThan(2));
  });

  group('SnpUploadException messages', () {
    test('each status gets something a person can act on', () {
      expect(const SnpUploadException(0, '').toString(), contains('connection'));
      expect(const SnpUploadException(403, '').toString(), contains('not'));
      expect(const SnpUploadException(413, '').toString(), contains('larger'));
      expect(const SnpUploadException(500, '').toString(), contains('500'));
    });
  });

  group('UploadJob.fraction', () {
    test('is null when nothing is expected, so the bar is indeterminate', () {
      expect(UploadJob(total: 0, fileLabel: 'x').fraction, isNull);
    });

    test('clamps, because an out-of-range value asserts in the progress bar',
        () {
      final job = UploadJob(total: 100, fileLabel: 'x')..sent = 150;
      expect(job.fraction, 1.0);
    });
  });
}
