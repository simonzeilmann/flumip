import 'dart:io';

import 'package:flumip_server/src/future_calls/demo_mode_cleanup.dart';
import 'package:serverpod/serverpod.dart';

import 'package:flumip_server/src/web/routes/ucsc_track.dart';

import 'src/generated/protocol.dart';
import 'src/generated/endpoints.dart';

// This is the starting point of your Serverpod server. In most cases, you will
// only need to make additions to this file if you add future calls,  are
// configuring Relic (Serverpod's web-server), or need custom setup work.

void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // CheckIndexProgress / CheckMipgenProgress are spec future calls and are
  // registered automatically from the generated code. DemoModeCleanup still
  // uses the legacy string-keyed API (identifier-based scheduling/cancellation)
  // and is registered manually.
  pod.registerFutureCall(DemoModeCleanup(), 'demoModeCleanup');

  // Setup the flutter project server.
  final flutterAppDir = Directory('web/app');

  if (!flutterAppDir.existsSync()) {
    print('Warning: Flutter web app not found at ${flutterAppDir.path}');
    print('Build your Flutter app and copy it to web/app/');
  } else {
    pod.webServer.addRoute(FlutterRoute(flutterAppDir));
  }

  pod.webServer.addRoute(UCSCTrackRoute(), '/ucsc_track/:id');

  // Start the server.
  await pod.start();
}
