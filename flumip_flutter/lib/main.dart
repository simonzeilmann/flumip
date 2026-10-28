/// ⚠️ **The browser-only end of the app, and the only file that may be.**
///
/// `dart:js_interop` and `package:web` exist when compiling to JavaScript or
/// Wasm and nowhere else, so importing this file from a VM test is a
/// *compile-time* error — not a runtime one, and not something a fake or a
/// guard can work around:
///
///     lib/main.dart:2:8: Error: Dart library 'dart:js_interop' is not
///     available on this platform.
///
/// Everything the rest of the app needs from here therefore lives in
/// `services.dart`, which stays free of both, and the shell — gate, app bar,
/// tabs, footer — lives in `app.dart`. This file is the entry point plus the
/// few lines of wiring that genuinely need a window.
///
/// ⚠️ **Nothing under `lib/` may import `main.dart`, and nothing new belongs in
/// it.** Seven files used to import it — every tab among them — which is why no
/// tab could be tested; the shell lived here too, and could not be tested either.
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:flumip_flutter/app.dart';
import 'package:flumip_flutter/services.dart';
import 'package:flumip_flutter/snp/file_picker.dart';
import 'package:flumip_flutter/snp/web_snp_transport.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Asks the browser to confirm before the page goes away.
///
/// Returning a string is the old contract and still what triggers the prompt;
/// browsers show their own wording rather than this text.
String _warnBeforeUnload(web.BeforeUnloadEvent event) {
  event.preventDefault();
  return 'An upload is still in progress.';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Everything that needs a browser, handed to the rest of the app as plain
  // callbacks. This is the whole of what `services.dart` cannot do for itself.
  installServices(
    navigate: (url) => web.window.location.href = url,
    openUrl: (url) => web.window.open(url, '_blank'),
    filePicker: pickFileFromBrowser,
    snpTransport: WebSnpTransport(siteUrl: siteUrl),
  );

  // Asks the server whether it wants a sign-in, and picks up an existing session
  // if there is one. On a default install this answers "no" and the app runs
  // exactly as it always has, with no Authorization header on any request.
  //
  // bootstrap() never throws, so a server that cannot answer still yields a
  // usable app rather than a blank screen.
  await authController.bootstrap();
  client.authKeyProvider = authController.authKeyProvider;

  // After the bearer is installed, so the first answer describes the real caller
  // rather than an anonymous one. Not awaited: it never throws, and the app must
  // not wait on it to draw.
  unawaited(accessController.reload());

  // ⚠️ Warn before leaving with an upload in flight. Closing the tab aborts the
  // transfer and leaves a `pending` row behind: the partial file in `.incoming/`
  // is swept after a day, and the row itself is failed by the next reconcile
  // pass once nothing has been written to it for half an hour. Recoverable
  // either way, but the set has to be uploaded again, so it is worth asking.
  snpUploads.addListener(() {
    web.window.onbeforeunload = snpUploads.anyLive
        ? _warnBeforeUnload.toJS
        : null;
  });

  runApp(const MyApp());
}
