import 'dart:async';
import 'dart:js_interop';

import 'package:flumip_flutter/snp/picked_file.dart';
import 'package:flumip_flutter/snp/snp_transport.dart';
import 'package:web/web.dart' as web;

/// The browser half of the upload, kept in its own library.
///
/// ⚠️ **Split from `snp_transport.dart` on purpose.** That file holds the seam and
/// its exception types, and anything importing `package:web` cannot be compiled
/// for the Dart VM — which is where every test in this app runs. Keeping the
/// abstraction browser-free is what lets `SnpUploadController` be tested at all.
/// The real transport: `XMLHttpRequest`.
///
/// ## Why XHR rather than fetch or package:http
///
/// - **`package:http`** takes a `Uint8List` body, so a 1.5 GB file would have to
///   be materialised in the Dart heap. It also offers no upload-progress hook.
/// - **`fetch`** accepts the browser `File` with no copy, so memory is fine, but
///   there is **no upload progress event** at all. Streaming a request body to get
///   one needs `duplex: 'half'`, which is Chromium-only, requires HTTP/2, and
///   cannot be combined with a blob body anyway.
/// - **`XMLHttpRequest`** accepts the `File` directly *and* is the only one of the
///   three with `upload.onprogress`. For an upload somebody watches for minutes,
///   that decides it.
class WebSnpTransport implements SnpTransport {
  const WebSnpTransport({required this.siteUrl});

  /// The **web** origin, not the API one — that is where the session cookie is
  /// valid, and a raw PUT carries no bearer header.
  final String siteUrl;

  @override
  SnpUploadHandle put({
    required int snpId,
    required PickedFile file,
    required void Function(int sent, int total) onProgress,
  }) {
    final done = Completer<void>();
    final xhr = web.XMLHttpRequest();

    xhr.open(
      'PUT',
      '$siteUrl/snp_upload/$snpId/${Uri.encodeComponent(file.name)}',
      true,
    );
    // Same-origin in every install, so this is inert there. Set anyway so the
    // cookie would travel if the origins ever diverged.
    xhr.withCredentials = true;
    xhr.setRequestHeader('Content-Type', 'application/octet-stream');
    // Deliberately no timeout: it defaults to none, and a gigabyte over a slow
    // link legitimately takes hours. A dead connection surfaces as onerror.

    xhr.upload.onprogress = ((web.ProgressEvent e) {
      onProgress(e.loaded, e.lengthComputable ? e.total : file.size);
    }).toJS;

    xhr.onload = ((web.ProgressEvent _) {
      // ⚠️ A 2xx is not enough. FlutterRoute answers any unmatched path with
      // index.html and a 200, so a mistyped route would arrive looking like
      // success and carrying HTML. Require the acknowledgement only this route
      // sends.
      final contentType = xhr.getResponseHeader('content-type') ?? '';
      if (xhr.status == 200 && contentType.contains('application/json')) {
        done.complete();
      } else {
        done.completeError(
          SnpUploadException(xhr.status, _bounded(xhr.responseText)),
        );
      }
    }).toJS;

    xhr.onerror = ((web.ProgressEvent _) {
      if (!done.isCompleted) {
        done.completeError(const SnpUploadException(0, ''));
      }
    }).toJS;

    xhr.onabort = ((web.ProgressEvent _) {
      if (!done.isCompleted) {
        done.completeError(const SnpUploadCancelled());
      }
    }).toJS;

    // web.File is a JSObject, so it is assignable to send's JSAny? body with no
    // Dart-side copy. This line is the whole reason for PickedFile.handle.
    xhr.send(file.handle as web.File);
    // Wrapped rather than torn off: `xhr.abort` is an external extension-type
    // interop member, and the web compiler rejects a tear-off of one. `dart
    // analyze` does not catch this, so it only shows up in `flutter build web`.
    return SnpUploadHandle(done.future, () => xhr.abort());
  }

  /// Bounded, so an accidental HTML body cannot fill a SnackBar.
  static String _bounded(String body) =>
      body.length > 300 ? '${body.substring(0, 300)}…' : body;
}
