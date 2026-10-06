import 'dart:async';

import 'package:serverpod/serverpod.dart';

/// The API, served under `/api` on the web server's own port.
///
/// `POST /api/<endpoint>/<method>` is answered exactly as
/// `POST /<endpoint>/<method>` on the API port would be. This is how every
/// client reaches the API; the API port is internal.
///
/// ## Why
///
/// Serverpod serves the app and the API on two ports, and a build cannot know
/// an install's hostname. Pointing the app at the API port meant either baking
/// the address into each build or guessing it from the page's port
/// (9082 → 9080), and neither survives a reverse proxy terminating TLS on 443.
/// With this route the whole install is **one origin**, so a proxy needs a
/// single upstream — the web port — and the app always calls
/// `<its own origin>/api/`.
///
/// Serverpod always starts the API server regardless; it is configured with
/// `publicHost: localhost` and should be kept off any proxy.
///
/// ## How
///
/// Not a proxy: no second hop, no loopback socket. [apiRouter] is a router
/// carrying Serverpod's own API routes, injected from `pod.server` — the same
/// endpoint dispatch, authentication and error mapping the API port runs. This
/// route strips the prefix and hands the request over in-process.
///
/// Every status passes through untouched, 404 for an unknown endpoint included,
/// so `/api/x` answers exactly as `x` does on the API port. (It once answered
/// 405 instead, while FlutterRoute's fallback swallowed every 404 on the web
/// server; see AppRoute.)
///
/// ⚠️ **Build [apiRouter] before `pod.start()`.** `Server.injectIn` treats an
/// injection into a running server as a hot reload and re-initialises every
/// endpoint.
class ApiRoute extends Route {
  ApiRoute(this.apiRouter)
    : super(methods: {Method.get, Method.post, Method.options});

  /// The path this route is mounted under, without a trailing slash.
  static const prefix = '/api';

  /// A router holding the API routes, as built by [forServer].
  final RelicRouter apiRouter;

  /// A router carrying [server]'s API routes and nothing else.
  static RelicRouter forServer(Server server) => RelicRouter()..inject(server);

  /// [url] with [prefix] removed from the front of its path.
  ///
  /// `/api/project/list` → `/project/list`, and `/api` → `/`. Endpoint dispatch
  /// derives the endpoint name from the whole path, so leaving the prefix on
  /// would look for an endpoint called `api`.
  static Uri stripPrefix(Uri url) {
    final rest = url.path.substring(prefix.length);
    return url.replace(path: rest.isEmpty ? '/' : rest);
  }

  @override
  Future<Result> call(Request req) async =>
      await apiRouter.asHandler(req.copyWith(url: stripPrefix(req.url)));

  @override
  FutureOr<Result> handleCall(Session session, Request request) =>
      throw StateError('ApiRoute.call handles every request itself');
}
