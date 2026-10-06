import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/authentication_handler.dart';
import 'package:flumip_server/src/services/snp_service.dart';
import 'package:serverpod/serverpod.dart';

import 'package:flumip_server/src/web/routes/api_route.dart';
import 'package:flumip_server/src/web/routes/app_route.dart';
import 'package:flumip_server/src/web/routes/auth_routes.dart';
import 'package:flumip_server/src/web/routes/download.dart';
import 'package:flumip_server/src/web/routes/snp_upload.dart';
import 'package:flumip_server/src/web/routes/ucsc_track.dart';

import 'src/generated/protocol.dart';
import 'src/generated/endpoints.dart';

// This is the starting point of your Serverpod server. In most cases, you will
// only need to make additions to this file if you add future calls,  are
// configuring Relic (Serverpod's web-server), or need custom setup work.

void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Lets the OIDC client secret be supplied as FLUMIP_OIDC_CLIENT_SECRET in the
  // environment, or as `oidcClientSecret` in config/passwords.yaml, rather than
  // being stored in the database. Must come before anything reads it.
  pod.loadCustomPasswords([
    (envName: 'FLUMIP_OIDC_CLIENT_SECRET', alias: 'oidcClientSecret'),
  ]);

  // Installed unconditionally, even when single sign-on is switched off.
  //
  // Serverpod's default handler throws UnimplementedError, and the framework
  // calls the handler whenever a request carries an `authorization` header. A
  // browser holding a token from before SSO was turned off would therefore get a
  // 500 on every call to every endpoint — including the settings endpoint needed
  // to fix it. Ours resolves an unknown token to null, which comes out as a
  // clean 401 that the client can recover from.
  pod.authenticationHandler = flumipAuthenticationHandler;

  // Setup the flutter project server.
  final flutterAppDir = Directory('web/app');

  if (!flutterAppDir.existsSync()) {
    print('Warning: Flutter web app not found at ${flutterAppDir.path}');
    print('Build your Flutter app and copy it to web/app/');
  } else {
    // The app is served with no caching, in every run mode.
    //
    // Up to Serverpod 3 this was a development-only override, because
    // FlutterRoute's default cached everything outside a short list
    // (index.html, flutter_bootstrap.js, …) for a **day** — and `main.dart.js`,
    // which is the entire app, is not on that list and is referenced with no
    // version query. So after a rebuild a browser that had visited before kept
    // running the *old* app for up to 24 hours. That is invisible and actively
    // misleading: the UI behaves as it did before the change, which reads as
    // "the fix did not work" rather than as a stale asset. It cost a full
    // debugging round already.
    //
    // Serverpod 4 makes `private, no-cache` the default for all Flutter assets,
    // so the override is gone and production gets the same treatment. That is
    // the right trade here — this is an internal tool where a deploy landing
    // correctly matters more than re-fetching the bundle — but it *is* a change:
    // production no longer caches `main.dart.js` for a day. If that bandwidth
    // ever matters, set `SERVERPOD_WEB_SERVER_FLUTTER_CACHE_CONTROL` in the
    // unit's EnvironmentFile rather than reinstating a branch here; caching then
    // becomes a deploy-time decision instead of a compiled-in one.
    //
    // ⚠️ This is only half of the staleness problem. The service worker sits in
    // front of the HTTP cache and can keep an old build alive regardless — see
    // "The service worker is ON" in HANDOFF.md.
    //
    // AppRoute, not FlutterRoute directly: FlutterRoute's index.html fallback
    // would otherwise swallow every other route's 404. See AppRoute.
    pod.webServer.addRoute(AppRoute(flutterAppDir));
  }

  // Keyed on the project's track token, not its id: the route is unauthenticated
  // by necessity (genome.ucsc.edu is the fetcher) so an unguessable path is what
  // keeps tracks from being enumerable. See UCSCTrackRoute.
  pod.webServer.addRoute(UCSCTrackRoute(), '/ucsc_track/:token');

  // Result files. Keyed on the project id and authorized against the caller's
  // cookie — see DownloadRoute for why this is a web route and not an endpoint.
  pod.webServer.addRoute(DownloadRoute(), '/download/:projectId/:fileName');

  // Uploaded SNP files, the same shape in reverse: the file is the whole request
  // body, so a gigabyte goes socket-to-disk without the process holding it, and
  // the browser's own session cookie authorizes it. See SnpUploadRoute.
  pod.webServer.addRoute(SnpUploadRoute(), '/snp_upload/:snpId/:fileName');

  // The sign-in flow runs on the web server, which is the origin the app itself
  // is served from — so the session cookie is set and read where the browser
  // actually is. API calls authenticate with a short-lived bearer minted from
  // that cookie at /auth/session, not with the cookie itself.
  pod.webServer.addRoute(AuthLoginRoute(), '/auth/login');
  pod.webServer.addRoute(AuthCallbackRoute(), '/auth/callback');
  pod.webServer.addRoute(AuthSessionRoute(), '/auth/session');
  pod.webServer.addRoute(AuthLogoutRoute(), '/auth/logout');

  // The API, under /api on the web port, so an install is one origin and a
  // TLS-terminating proxy needs a single upstream. Every build calls it here;
  // the API port itself is internal. Must be built before pod.start() — see
  // ApiRoute.
  pod.webServer.addRoute(
    ApiRoute(ApiRoute.forServer(pod.server)),
    '${ApiRoute.prefix}/**',
  );

  final authRuntime = sl<AuthRuntime>();

  // Read the configuration before the server accepts a single request, so there
  // is no window in which the gate is unenforced. This is possible because the
  // database pool is started in the Serverpod constructor, not in start().
  //
  // On a fresh database the settings table does not exist yet — migrations are
  // applied inside start() — so this read fails and the configuration falls back
  // to the environment alone. refresh() is total and handles that itself; the
  // refresh after start() picks up the stored settings.
  await pod.withSession(authRuntime.refresh, enableLogging: false);

  // Start the server.
  await pod.start();

  // Re-read now that any migrations have been applied, then keep it current. The
  // periodic refresh doubles as the self-heal for "the identity provider was
  // unreachable at boot", and prunes expired sessions on the same tick.
  await pod.withSession(authRuntime.refresh, enableLogging: false);
  authRuntime.startPeriodicRefresh(pod);

  // Reconcile the SNP tree once the database is migrated. This is what heals an
  // import that was cut off by the restart we just performed — the row would
  // otherwise sit at `downloading` forever, since the thing that was updating it
  // no longer exists. It also backfills the genome link on every SNP predating
  // custom SNPs, without which the pickers would come up empty after upgrading.
  //
  // Deliberately not on the periodic tick: this walks only `customSnpDir`, but
  // `collectGenomes` — which also calls it — walks the whole genome tree with a
  // recursive size count, and that is hundreds of gigabytes of stat calls for
  // data that changes only when somebody puts a file there.
  await pod.withSession(enableLogging: false, (session) async {
    try {
      await sl<SnpService>().collectCustomSnps(session);
    } catch (e, stackTrace) {
      // Never fatal. A server that will not start because a data directory is
      // missing is far worse than one whose SNP list is briefly stale, and the
      // "Collect" button re-runs exactly this.
      session.log(
        'Could not reconcile SNPs at startup; the server is running anyway.',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    }
  });
}

// The hand-rolled `_withSession` helper that used to live here is gone:
// Serverpod 4 provides `Serverpod.withSession`, which does the same thing and
// additionally attaches the error and stack trace to the session when the
// callback throws, so a failure at startup reaches the logs instead of being
// swallowed by a bare `finally`.
