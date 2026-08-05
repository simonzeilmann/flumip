import 'dart:async';
import 'dart:js_interop';

import 'package:flumip_flutter/snp/picked_file.dart';
import 'package:web/web.dart' as web;

/// Opens the browser's file dialog and returns what was chosen, or null.
///
/// ## Why this is hand-rolled rather than `file_picker`
///
/// ⚠️ **Size.** On web, `file_picker` returns bytes — read through a `FileReader`,
/// so every byte of a 1.5 GB VCF passes through the Dart heap — and it never
/// exposes the underlying browser `File` object, which is the one thing needed
/// here. It would also pull six platform plugin packages into an app whose only
/// current plugin dependency is `url_launcher`.
///
/// `package:web` has exactly what is required and is already a dependency. The
/// returned [PickedFile.handle] is the browser's `File`, which
/// `XMLHttpRequest.send` accepts directly: no copy, and the browser streams it
/// straight off the file handle.
Future<PickedFile?> pickFileFromBrowser({required String accept}) {
  final done = Completer<PickedFile?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept
    ..multiple = false
    ..style.display = 'none';

  // Attached to the document because a detached input's dialog is unreliable in
  // some browsers, and removed again on either outcome so repeated picks do not
  // litter the DOM.
  web.document.body!.appendChild(input);

  void finish(PickedFile? file) {
    if (!done.isCompleted) done.complete(file);
    input.remove();
  }

  input.onChange.first.then((_) {
    final files = input.files;
    if (files == null || files.length == 0) return finish(null);
    final file = files.item(0);
    if (file == null) return finish(null);
    finish(
      PickedFile(name: file.name, size: file.size, handle: file),
    );
  });

  // Fires when the dialog is dismissed. Without it the future never completes
  // and the caller leaks a listener. Supported in current Chrome, Firefox and
  // Safari; on anything older a cancel simply leaves the future pending, which is
  // harmless because nothing spins while the dialog is open.
  input.addEventListener('cancel', ((web.Event _) => finish(null)).toJS);

  input.click();
  return done.future;
}

/// What to offer in the dialog for a bgzip-compressed VCF.
///
/// `accept` is a hint and never a guarantee — the name is validated in Dart, and
/// again by the server. `.gz` is listed as the Safari fallback, which does not
/// honour a two-part suffix.
const vcfAccept = '.vcf.gz,.gz,application/gzip';

/// What to offer for a tabix index.
const tbiAccept = '.tbi,.vcf.gz.tbi';
