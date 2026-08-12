import 'dart:async';

import 'package:flumip_flutter/snp/picked_file.dart';
import 'package:flumip_flutter/snp/snp_transport.dart';
import 'package:flutter/foundation.dart';

/// One SNP set's upload, as the interface needs to see it.
class UploadJob {
  UploadJob({required this.total, required this.fileLabel});

  /// Bytes accepted so far, across both files.
  int sent = 0;

  /// Bytes to send in total, across both files. Known up front from the picker.
  final int total;

  /// Which file is moving right now, for the line under the bar.
  String fileLabel;

  /// Set when the upload failed; the row's own status carries the server's view.
  String? error;

  bool cancelled = false;

  double? get fraction => total <= 0 ? null : (sent / total).clamp(0.0, 1.0);
}

/// Drives browser uploads for custom SNP sets.
///
/// ⚠️ **Lives as a top-level singleton in `main.dart`, not in a widget.** An
/// upload takes minutes and must survive the dialog being closed, the tab being
/// switched, and the `TabBarView` rebuilding — none of which should cancel a
/// transfer somebody started.
///
/// Its I/O is injected, so the ordering logic below is tested on the Dart VM with
/// no browser: see `test/snp/snp_upload_controller_test.dart`.
class SnpUploadController extends ChangeNotifier {
  SnpUploadController({
    required SnpTransport transport,
    required Future<void> Function(int snpId) finishUpload,
  }) : _transport = transport,
       _finish = finishUpload;

  final SnpTransport _transport;
  final Future<void> Function(int snpId) _finish;

  final Map<int, UploadJob> _jobs = {};
  final Map<int, void Function()> _cancels = {};

  UploadJob? operator [](int? snpId) => snpId == null ? null : _jobs[snpId];

  bool get isEmpty => _jobs.isEmpty;
  bool get isNotEmpty => _jobs.isNotEmpty;

  /// Whether anything is still moving, which is what the list's poll rate keys on.
  bool get anyLive => _jobs.values.any((j) => j.error == null && !j.cancelled);

  /// Sends [vcf], then [tbi] if given, then tells the server it is finished.
  ///
  /// ⚠️ **Sequential, not concurrent.** Two 1.5 GB streams fight for the same pipe
  /// and make both progress bars meaningless; one after the other is also what
  /// lets a single bar describe the whole job honestly.
  ///
  /// ⚠️ **`finishUpload` runs only if every file landed.** It is what reads the
  /// directory and settles the row, so calling it after a failed second PUT would
  /// mark an SNP set complete when its index never arrived.
  Future<void> start({
    required int snpId,
    required PickedFile vcf,
    PickedFile? tbi,
  }) async {
    final job = UploadJob(
      total: vcf.size + (tbi?.size ?? 0),
      fileLabel: vcf.name,
    );
    _jobs[snpId] = job;
    notifyListeners();

    try {
      await _send(snpId, job, vcf, base: 0);
      if (tbi != null) {
        job.fileLabel = tbi.name;
        notifyListeners();
        await _send(snpId, job, tbi, base: vcf.size);
      }
      await _finish(snpId);
      _jobs.remove(snpId);
      _cancels.remove(snpId);
    } on SnpUploadCancelled {
      job.cancelled = true;
      job.error = 'Cancelled.';
    } catch (e) {
      job.error = e.toString();
    } finally {
      _cancels.remove(snpId);
      notifyListeners();
    }
  }

  Future<void> _send(
    int snpId,
    UploadJob job,
    PickedFile file, {
    required int base,
  }) async {
    final handle = _transport.put(
      snpId: snpId,
      file: file,
      onProgress: (sent, _) {
        // Offset by the bytes already sent, so one bar covers both files.
        job.sent = base + sent;
        notifyListeners();
      },
    );
    _cancels[snpId] = handle.cancel;
    await handle.done;
    job.sent = base + file.size;
    notifyListeners();
  }

  /// Aborts an upload in flight.
  ///
  /// The row is left `pending` on the server with nothing in its directory, so it
  /// can be retried or cancelled from the list.
  void cancel(int snpId) => _cancels[snpId]?.call();

  /// Forgets a finished-but-failed job, so its message stops being shown.
  void dismiss(int snpId) {
    _jobs.remove(snpId);
    _cancels.remove(snpId);
    notifyListeners();
  }
}
