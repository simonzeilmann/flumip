import 'dart:async';
import 'dart:io';

import 'package:flumip_server/src/services/snp_downloader.dart';
import 'package:flumip_server/src/services/snp_service.dart';

/// A single recorded call to [SnpDownloader.download].
class DownloadInvocation {
  DownloadInvocation({
    required this.url,
    required this.target,
    required this.maxBytes,
    required this.allowedHosts,
  });

  final Uri url;
  final File target;
  final int maxBytes;
  final List<String> allowedHosts;
}

/// In-memory [SnpDownloader] for tests.
///
/// Writes canned bytes to the target and reports canned progress, so the import
/// job's state machine can be exercised without a network. Set [error] to make
/// every call fail; use [stub] to script one URL at a time.
///
/// This is why the downloader is a seam rather than an inline `HttpClient` call:
/// a fake [ProcessRunner] wrapping `wget` could assert the argv, but could never
/// exercise a truncated response, a cap overrun, or a redirect into a private
/// network.
class FakeSnpDownloader implements SnpDownloader {
  final List<DownloadInvocation> invocations = [];
  final Map<String, ({int bytes, Object? error, List<(int, int?)> progress})>
  _stubs = {};

  /// Bytes written by a call with no stub. Zero means "write nothing".
  int defaultBytes = 64;

  /// When set, every unstubbed call throws this.
  Object? error;

  void reset() {
    invocations.clear();
    _stubs.clear();
    defaultBytes = 64;
    error = null;
  }

  /// Scripts the outcome for one exact URL.
  ///
  /// [progress] is a list of `(received, total)` pairs handed to `onProgress`
  /// before the call returns, so a test can assert what the job persisted.
  void stub(
    String url, {
    int bytes = 64,
    Object? error,
    List<(int, int?)> progress = const [],
  }) {
    _stubs[url] = (bytes: bytes, error: error, progress: progress);
  }

  @override
  Future<int> download(
    Uri url,
    File target, {
    required int maxBytes,
    required List<String> allowedHosts,
    required FutureOr<void> Function(int received, int? total) onProgress,
  }) async {
    invocations.add(
      DownloadInvocation(
        url: url,
        target: target,
        maxBytes: maxBytes,
        allowedHosts: allowedHosts,
      ),
    );

    final stub = _stubs[url.toString()];
    final failure = stub?.error ?? error;
    if (failure != null) {
      // The real downloader deletes its partial file before throwing, and the
      // job relies on that, so the fake has to as well.
      if (await target.exists()) await target.delete();
      throw failure;
    }

    for (final (received, total) in stub?.progress ?? const <(int, int?)>[]) {
      await onProgress(received, total);
    }

    final size = stub?.bytes ?? defaultBytes;
    await target.parent.create(recursive: true);
    await target.writeAsBytes(_bgzfBytes(size));
    await onProgress(size, size);
    return size;
  }

  /// Bytes of a **complete** bgzip file.
  ///
  /// ⚠️ Must end with the BGZF end-of-file block, not merely begin with a valid
  /// header: `SnpService.vcfProblem` treats a missing marker as a truncated
  /// download, which is exactly what a fake payload of header-only bytes looks
  /// like.
  static List<int> _bgzfBytes(int size) {
    final marker = SnpService.bgzfEofMarker;
    if (size <= marker.length * 2) return marker;
    return [
      ...marker,
      ...List.filled(size - marker.length * 2, 0x78),
      ...marker,
    ];
  }
}
