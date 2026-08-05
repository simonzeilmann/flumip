import 'package:serverpod/serverpod.dart';

/// Answers `/flutter_service_worker.js` with a worker that switches itself off.
///
/// ## Why this exists
///
/// FLUMIP used to ship Flutter's generated service worker, which caches the whole
/// app shell. That made deploys invisible: a service worker sits *in front of*
/// the HTTP cache, so a hard reload does not bypass it, and the standard
/// lifecycle keeps a newly installed worker **waiting** until every tab on the
/// origin closes. Reloading the same tab never activates it. A browser can go on
/// running a months-old build while the server holds the new one — which, from
/// the user's side, is indistinguishable from a bug. It cost a debugging round on
/// staging, on a change that had shipped correctly.
///
/// Builds now pass `--pwa-strategy=none` so no caching worker is generated. That
/// fixes new visitors and does nothing at all for the browsers that already have
/// one registered, of which there are some right now.
///
/// ## Why it is a route and not a file in `web/`
///
/// Two reasons, and either alone would be enough.
///
/// ⚠️ **`--pwa-strategy=none` writes its own empty `flutter_service_worker.js`
/// over anything in `web/`.** A file placed there is silently truncated to zero
/// bytes at build time.
///
/// ⚠️ **That empty worker does not solve the problem anyway.** It is valid
/// JavaScript with no `fetch` handler, so it installs and stops caching — but
/// with no `skipWaiting()` it sits in the waiting state until every tab closes,
/// which is precisely the behaviour being undone. The script below calls
/// `skipWaiting`, clears the caches, unregisters itself, and reloads open tabs,
/// so one ordinary reload is enough.
///
/// Serving it from here also means it is correct however the client was built.
///
/// ## Why the file cannot simply be deleted
///
/// ⚠️ A registered worker checks for updates by fetching its own URL, and
/// `FlutterRoute` answers a request for a missing file with `index.html` and a
/// **200** — not a 404. The browser would receive HTML, fail to evaluate it as a
/// script, treat the update as failed, and keep the old worker alive
/// indefinitely. A 404 would deregister it; a 200 full of HTML will not.
///
/// ## When this can go
///
/// Once no client anywhere still has a worker registered — which is unknowable,
/// since a browser that has not visited since is still carrying one. Treat it as
/// permanent.
class ServiceWorkerTombstoneRoute extends Route {
  ServiceWorkerTombstoneRoute()
      : super(methods: {Method.get, Method.head});

  static const script = '''
// FLUMIP no longer uses a service worker. This one exists only to remove
// whatever was installed before. See ServiceWorkerTombstoneRoute.
self.addEventListener('install', () => {
  // Do not wait for tabs to close — waiting is the behaviour being undone.
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    await self.clients.claim();

    // Drop everything the old worker cached, including the stale app bundle.
    const names = await caches.keys();
    await Promise.all(names.map((name) => caches.delete(name)));

    await self.registration.unregister();

    // Reload open tabs. Without this they keep running the old bundle already in
    // memory until somebody happens to navigate, which is the confusion this is
    // meant to end.
    const clients = await self.clients.matchAll({type: 'window'});
    for (const client of clients) {
      client.navigate(client.url);
    }
  })());
});

// Everything straight to the network while this is briefly alive.
self.addEventListener('fetch', () => {});
''';

  @override
  Future<Result> handleCall(Session session, Request request) async {
    return Response.ok(
      body: Body.fromString(script, mimeType: MimeType.javascript),
      // ⚠️ Never cached. A cached tombstone is a worker that cannot be replaced,
      // and the browser must see this on every update check.
      headers: Headers.build((h) {
        h['cache-control'] = ['no-store, no-cache, must-revalidate'];
      }),
    );
  }
}
