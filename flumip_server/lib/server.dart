import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/authentication_handler.dart';
import 'package:flumip_server/src/future_calls/demo_mode_cleanup.dart';
import 'package:flumip_server/src/services/snp_service.dart';
import 'package:serverpod/serverpod.dart';

import 'package:flumip_server/src/web/routes/auth_routes.dart';
import 'package:flumip_server/src/web/routes/download.dart';
import 'package:flumip_server/src/web/routes/service_worker_tombstone.dart';
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
    // ⚠️ Serve the app with no caching. Everywhere, not only in development.
    //
    // FlutterRoute's default caches everything except a short list (index.html,
    // flutter_bootstrap.js, …) for a **day**, and `main.dart.js` — which is the
    // entire app — is not on that list and is referenced with no version query.
    // So after a deploy, a browser that has visited before keeps running the
    // *old* app for up to 24 hours.
    //
    // That is invisible and actively misleading: the UI behaves as it did before
    // the change, which reads as "the fix did not work" rather than as a stale
    // asset. It cost a debugging round in development, and then cost another one
    // on staging — where the comment that used to sit here said production
    // "keeps the caching default, where it is worth having". It was not worth
    // having. A deploy nobody can see is not a deploy.
    //
    // The cost of switching it off is one revalidation of a few hundred kilobytes
    // per page load, and `etag` makes that a 304 in the ordinary case. That is a
    // trade worth making for an internal tool on a fast network, and it is the
    // difference between "reload" and "close every tab you have open".
    //
    // Note this is only half the fix: a service worker sits *in front* of the
    // HTTP cache and ignores all of this, which is why builds now pass
    // `--pwa-strategy=none` and `/flutter_service_worker.js` is served by
    // ServiceWorkerTombstoneRoute, which unregisters anything still installed.
    pod.webServer.addRoute(
      FlutterRoute(
        flutterAppDir,
        cacheControlFactory: StaticRoute.privateNoCache(),
      ),
    );
  }

  // ⚠️ A route rather than a file, and it must out-rank the Flutter fallback.
  // Deleting the file instead would leave old workers installed forever, because
  // FlutterRoute answers a missing file with index.html and a 200 rather than a
  // 404 — see ServiceWorkerTombstoneRoute for the whole story.
  pod.webServer.addRoute(
    ServiceWorkerTombstoneRoute(),
    '/flutter_service_worker.js',
  );

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
  // actually is. The API server is a different origin and uses a bearer header.
  pod.webServer.addRoute(AuthLoginRoute(), '/auth/login');
  pod.webServer.addRoute(AuthCallbackRoute(), '/auth/callback');
  pod.webServer.addRoute(AuthSessionRoute(), '/auth/session');
  pod.webServer.addRoute(AuthLogoutRoute(), '/auth/logout');

  final authRuntime = sl<AuthRuntime>();

  // Read the configuration before the server accepts a single request, so there
  // is no window in which the gate is unenforced. This is possible because the
  // database pool is started in the Serverpod constructor, not in start().
  //
  // On a fresh database the settings table does not exist yet — migrations are
  // applied inside start() — so this read fails and the configuration falls back
  // to the environment alone. refresh() is total and handles that itself; the
  // refresh after start() picks up the stored settings.
  await _withSession(pod, authRuntime.refresh);

  // Start the server.
  await pod.start();

  // Re-read now that any migrations have been applied, then keep it current. The
  // periodic refresh doubles as the self-heal for "the identity provider was
  // unreachable at boot", and prunes expired sessions on the same tick.
  await _withSession(pod, authRuntime.refresh);
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
  await _withSession(pod, (session) async {
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

/// Runs [action] with a short-lived internal session, always closing it.
Future<void> _withSession(
  Serverpod pod,
  Future<void> Function(Session session) action,
) async {
  final session = await pod.createSession(enableLogging: false);
  try {
    await action(session);
  } finally {
    await session.close();
  }
}
