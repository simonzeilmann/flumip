import 'dart:async';

import 'package:flumip_flutter/snp/picked_file.dart';

/// An upload in flight.
class SnpUploadHandle {
  const SnpUploadHandle(this.done, this.cancel);

  /// Completes when every byte has been accepted, or completes with an error.
  final Future<void> done;

  /// Aborts the transfer. The [done] future then fails with [SnpUploadCancelled].
  final void Function() cancel;
}

/// The server refused an upload, or the connection failed.
class SnpUploadException implements Exception {
  const SnpUploadException(this.status, this.body);

  /// Zero when the request never got an answer at all.
  final int status;
  final String body;

  @override
  String toString() => switch (status) {
    0 => 'The connection failed.',
    403 => 'The server would not accept that file.',
    413 => 'That file is larger than this server accepts.',
    _ => 'The server answered $status.',
  };
}

/// The user aborted the upload.
class SnpUploadCancelled implements Exception {
  const SnpUploadCancelled();

  @override
  String toString() => 'Upload cancelled.';
}

/// Sends a chosen file to the upload route.
///
/// A seam, so [SnpUploadController] and its tests can run on the Dart VM with no
/// browser. The only implementation that touches `package:web` is
/// [WebSnpTransport].
abstract class SnpTransport {
  SnpUploadHandle put({
    required int snpId,
    required PickedFile file,
    required void Function(int sent, int total) onProgress,
  });
}
