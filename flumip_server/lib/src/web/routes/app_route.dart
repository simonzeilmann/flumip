import 'dart:io';

import 'package:serverpod/serverpod.dart';

/// Serves the Flutter web app, falling back to `index.html` for the app's own
/// client-side paths — and **only** for those.
///
/// ⚠️ Serverpod's [FlutterRoute] cannot be added directly. It installs its
/// "any 404 becomes `index.html`" fallback as middleware on the root of the web
/// server's router, and Relic applies root middleware to every route. So a 404
/// from *another* route — `/ucsc_track/<unknown token>`, an unknown endpoint
/// under `/api` — reached the client as the app's HTML with a 200. UCSC then
/// complained about a malformed track instead of saying it was not found.
///
/// Here the same [FlutterRoute], with all its defaults (caching, the
/// `SERVERPOD_WEB_SERVER_FLUTTER_CACHE_CONTROL` override, the WASM headers), is
/// built into a router of its own and mounted at the tail `/**`. Relic tries
/// literal and parameter segments before a tail, so every other route still
/// wins its paths and answers them itself; only a path nothing else claims
/// reaches the app, where the fallback belongs.
class AppRoute extends Route {
  AppRoute(Directory directory)
    : _app = RelicRouter()..inject(FlutterRoute(directory)),
      super(methods: {Method.get, Method.head}, path: '/**');

  final RelicRouter _app;

  @override
  void injectIn(RelicRouter router) =>
      router.anyOf(methods, path, _app.asHandler);

  @override
  Future<Result> handleCall(Session session, Request request) async =>
      _app.asHandler(request);
}
