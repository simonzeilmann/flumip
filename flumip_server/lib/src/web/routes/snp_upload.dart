import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/project_access.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/auth_service.dart';
import 'package:flumip_server/src/services/snp_service.dart';
import 'package:flumip_server/src/web/routes/auth_routes.dart'
    show authCookieName;
import 'package:serverpod/serverpod.dart';

/// Receives the bytes of an uploaded SNP file.
///
/// `PUT /snp_upload/<snpId>/<fileName>`, with the file itself as the entire
/// request body. One request per file, so a `.vcf.gz` and its `.vcf.gz.tbi` are
/// two calls.
///
/// ## Why a raw body rather than multipart
///
/// A `.vcf.gz` is 100 MB to 1.5 GB. `request.read()` hands back a
/// `Stream<Uint8List>` that pipes straight into an [IOSink], so the bytes go from
/// socket to disk without the process ever holding the file. Multipart would need
/// a boundary scanner over every one of those bytes and would add `mime` as a
/// direct dependency, to carry exactly one part whose name we already have in the
/// path.
///
/// The size cap comes free with it: `read(maxLength:)` throws
/// [MaxBodySizeExceeded] *before consuming anything* when the declared
/// `Content-Length` is over the limit, and as soon as the running total crosses it
/// otherwise. Relic's own server maps an escaping one to a 413, but it is caught
/// here so the partial file gets cleaned up first.
///
/// ## Why a web route rather than an endpoint
///
/// The same two reasons as `/download`, in the other direction. An endpoint
/// argument is serialised, so the file would have to sit in memory in the browser
/// and again on the server. And this is **same-origin with the app**, so the
/// browser sends the session cookie by itself — which is what makes an
/// `XMLHttpRequest` carrying a `File` object work at all, since a bearer header
/// would mean reading the file into JavaScript first.
///
/// ⚠️ **This is a write primitive, and it is open while sign-in is off** — the
/// same position `/download` takes, but that one only reads. What bounds it: the
/// row must already exist and be waiting for files, the directory comes from the
/// row id and never from the request, only two filename shapes are accepted,
/// nothing is ever overwritten, and each file is capped.
class SnpUploadRoute extends Route {
  SnpUploadRoute() : super(methods: {Method.put});

  /// The largest single file this route will accept.
  ///
  /// Shared with the URL importer so the two paths cannot disagree about what is
  /// too big.
  static const maxBytes = SnpService.maxImportBytes;

  static String _asString(String value) => value;
  static const _snpParam = PathParam<String>(#snpId, _asString);
  static const _fileParam = PathParam<String>(#fileName, _asString);

  SnpService get snpService => sl<SnpService>();

  @override
  Future<Result> handleCall(Session session, Request request) async {
    // ⚠️ One refusal for everything — a bad id, no access, a rejected name, a
    // row not accepting files, a file already there. Anything more specific would
    // let somebody enumerate SNP ids or probe what is already uploaded.
    //
    // And it is 403 rather than 404 because **FlutterRoute swallows 404s**: it
    // answers any of them with `index.html` and a 200, so a refusal would arrive
    // looking like success. Same reasoning as `download.dart`.
    final refused = Response.forbidden(
      body: Body.fromString('Upload not accepted'),
    );

    final snpId = int.tryParse(request.pathParameters.get(_snpParam));
    final fileName = Uri.decodeComponent(
      request.pathParameters.get(_fileParam),
    );
    if (snpId == null) return refused;

    final snp = await Snp.db.findById(session, snpId);
    if (snp == null) return refused;

    if (!await _mayWrite(session, request, snp)) {
      session.log(
        'Refused an upload to SNP $snpId from '
        '${request.connectionInfo.remote.address}',
        level: LogLevel.warning,
      );
      return refused;
    }

    final paths = await snpService.resolveUploadTarget(session, snp, fileName);
    if (paths == null) return refused;

    return _receive(session, request, snp, fileName, paths);
  }

  /// Whether the caller may add files to this SNP set.
  ///
  /// Never throws: failing to work out who is asking has to come out as "not
  /// allowed" rather than as a 500 on an upload. Mirrors `DownloadRoute._mayRead`,
  /// with [snpIsWritable] in place of `projectIsAccessible` — seeing a shared SNP
  /// set is not permission to put files in it.
  Future<bool> _mayWrite(Session session, Request request, Snp snp) async {
    try {
      final enforcing = sl.isRegistered<AuthRuntime>()
          ? sl<AuthRuntime>().isEnforcing
          : false;
      if (!enforcing) return true;

      final cookie = _readAuthCookie(request);
      if (cookie == null) return false;

      final authSession = await sl<AuthService>().sessionForCookie(
        session,
        cookie,
      );
      if (authSession == null) return false;

      return snpIsWritable(
        enforcing: true,
        principal: Principal(
          userId: authSession.userId,
          isAdmin: authSession.isAdmin,
        ),
        owner: snp.owner,
      );
    } catch (e, stackTrace) {
      session.log(
        'Could not determine upload access; refusing.',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Streams the body to `.incoming/<name>.part`, then renames it into place.
  ///
  /// The rename is what makes a truncated file impossible to mistake for a
  /// finished one: it is atomic within a filesystem, so the SNP directory only
  /// ever holds complete files under real names.
  Future<Result> _receive(
    Session session,
    Request request,
    Snp snp,
    String fileName,
    ({File partial, File target}) paths,
  ) async {
    IOSink? sink;
    var written = 0;
    final declared = request.body.contentLength;
    try {
      sink = paths.partial.openWrite();
      await for (final chunk in request.read(maxLength: maxBytes)) {
        written += chunk.length;
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      sink = null;

      // ⚠️ **The completeness check, and it is not optional.** A stream that ends
      // early without an error — a proxy that closed the connection cleanly, a
      // client that went away between chunks — otherwise leaves a truncated file
      // that gets renamed into place and marked ready. If an index was uploaded
      // alongside it, tabix never runs, so nothing downstream ever looks at the
      // bytes and the first sign of trouble is mipgen dying on a corrupt archive
      // some minutes later.
      if (declared != null && written != declared) {
        await _discard(sink, paths.partial);
        session.log(
          'Refused a truncated upload for SNP ${snp.id}: got $written bytes of '
          'a declared $declared.',
          level: LogLevel.warning,
        );
        return Response.badRequest(
          body: Body.fromString(
            'The upload arrived incomplete ($written of $declared bytes). '
            'Nothing was saved; please try again.',
          ),
        );
      }

      await paths.partial.rename(paths.target.path);
      session.log(
        'Received $written bytes as "$fileName" for SNP ${snp.id}',
        level: LogLevel.info,
      );

      // ⚠️ A JSON body, not an empty 200. FlutterRoute answers an unmatched path
      // with index.html and a 200, so the client cannot tell a real success from
      // the app's own HTML unless the answer says something only this route says.
      return Response.ok(
        body: Body.fromString(
          '{"ok":true,"bytes":$written}',
          mimeType: MimeType.json,
        ),
        headers: Headers.build((h) => h['cache-control'] = ['no-store']),
      );
    } on MaxBodySizeExceeded {
      await _discard(sink, paths.partial);
      session.log(
        'Refused an oversized upload for SNP ${snp.id}',
        level: LogLevel.warning,
      );
      return Response.contentTooLarge(
        body: Body.fromString('That file is larger than this server accepts.'),
      );
    } catch (e, stackTrace) {
      // A dropped socket, a full disk. Either way the half-written file goes,
      // tied to the failure rather than to a timer.
      await _discard(sink, paths.partial);
      session.log(
        'Upload of "$fileName" for SNP ${snp.id} failed after $written bytes.',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return Response.forbidden(
        body: Body.fromString('The upload did not complete.'),
      );
    }
  }

  /// Closes the sink and removes the partial file.
  ///
  /// Closing first matters: on some filesystems an open file cannot be deleted,
  /// and the leftover would then be swept only a day later.
  Future<void> _discard(IOSink? sink, File partial) async {
    try {
      await sink?.close();
    } catch (_) {}
    try {
      if (await partial.exists()) await partial.delete();
    } catch (_) {}
  }
}

/// Reads the sign-in cookie, treating a malformed header as no cookie.
///
/// Third copy of this, and deliberately so — same reasoning as the one in
/// `download.dart`: `CookieHeader.parse` throws on things like a duplicate cookie
/// name set by something else on the domain, and that must not turn into a failed
/// upload.
String? _readAuthCookie(Request request) {
  final header = Headers.cookie.getValueFrom(
    request.headers,
    orElse: (_) => null,
  );
  return header?.getCookie(authCookieName)?.value;
}
