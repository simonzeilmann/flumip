import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/project_access.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/auth_service.dart';
import 'package:flumip_server/src/services/file_service.dart';
import 'package:flumip_server/src/web/routes/auth_routes.dart'
    show authCookieName;
import 'package:serverpod/serverpod.dart';

/// Serves a project's result files.
///
/// `GET /download/<projectId>/<fileName>` for one file, and
/// `GET /download/<projectId>/all.zip` for the lot.
///
/// ## Why a web route rather than an endpoint
///
/// Two reasons, and the second is the one that matters.
///
/// It **streams**. A finished project can be gigabytes; an endpoint response is
/// serialised, so the file would have to be held in memory on the server and
/// again in the browser before anything could be saved. Here the bytes go
/// straight from disk to the socket, and the browser writes them to disk as they
/// arrive, with a progress bar it drew itself.
///
/// It is **same-origin with the app**, so the browser sends the session cookie
/// without being asked. API calls authenticate with a bearer header instead
/// (see `AuthApiToken` for why), and a plain `<a download>` or `window.open`
/// carries no header, so a bearer-authenticated download would have to be
/// fetched into memory by JavaScript first, which is exactly the thing being
/// avoided.
///
/// ## Authorization
///
/// The same rule as everywhere else, reached differently: there is no
/// `session.authenticated` on a web route, so the cookie is resolved to an
/// `AuthSession` by hand and turned into a [Principal]. [projectIsAccessible]
/// then decides, so this route cannot grow its own idea of who may read what.
///
/// While sign-in is not enforced this is open, exactly as every project-scoped
/// endpoint is — a no-auth install has no identities and its projects are shared
/// by definition.
///
/// ⚠️ Unlike `/ucsc_track/<token>`, this route is **not** a capability URL. It
/// takes the project id, so it must check the caller; the UCSC route takes an
/// unguessable token precisely because its caller (genome.ucsc.edu) cannot
/// authenticate at all.
class DownloadRoute extends Route {
  DownloadRoute() : super(methods: {Method.get});

  /// The name that means "everything, zipped" rather than a file on disk.
  static const zipName = 'all.zip';

  static String _asString(String value) => value;
  static const _projectParam = PathParam<String>(#projectId, _asString);
  static const _fileParam = PathParam<String>(#fileName, _asString);

  FileService get fileService => sl<FileService>();

  @override
  Future<Result> handleCall(Session session, Request request) async {
    // ⚠️ 403, not 404, and one and the same for every failure — unknown
    // project, no access, missing file, a rejected name. A different answer for
    // any of them would let somebody enumerate projects, or test whether a file
    // exists in one that is not theirs.
    //
    // It is 403 because **FlutterRoute swallows 404s**: it installs a fallback
    // that answers any 404 with `index.html` and a 200, so a refused download
    // would arrive as the app's own HTML under the requested file name. The
    // bytes were never at risk — the refusal happens first — but the client
    // could not tell a failure from a file, and would "download" a copy of the
    // page. Any status other than 404 passes through untouched.
    final refused = Response.forbidden(
      body: Body.fromString('File not available'),
    );

    final projectId = int.tryParse(request.pathParameters.get(_projectParam));
    // ⚠️ Not `Uri.decodeComponent`. Relic percent-decodes path parameters
    // already, so decoding again is both wrong and fatal: `Uri.decodeComponent`
    // rejects any raw non-ASCII character, so a browser asking for
    // `M%C3%BCller.txt` arrived here as `Müller.txt` and threw
    // `ArgumentError: Illegal percent encoding in URI` — a 500 before the
    // access check had even run, on every project file with an accent in its
    // name. A file called `a%b.txt` did the same.
    //
    // That also broke this route's one promise, that every refusal looks
    // identical: a 500 says "this name made the server crash" where a 403 says
    // nothing. And it made the RFC 5987 `filename*` half of
    // [_attachmentHeaders] unreachable — the request never got that far.
    final fileName = request.pathParameters.get(_fileParam);
    if (projectId == null) return refused;

    final project = await Project.db.findById(session, projectId);
    if (project == null) return refused;

    if (!await _mayRead(session, request, project)) {
      session.log(
        'Refused a download of project $projectId from '
        '${request.connectionInfo.remote.address}',
        level: LogLevel.warning,
      );
      return refused;
    }

    if (fileName == zipName) return _sendZip(session, project, refused);
    return _sendFile(session, project, fileName, refused);
  }

  /// Whether the caller may read this project's files.
  ///
  /// Never throws: a failure to work out who is asking has to come out as "not
  /// allowed" rather than as a 500 on a download.
  Future<bool> _mayRead(
    Session session,
    Request request,
    Project project,
  ) async {
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

      return projectIsAccessible(
        enforcing: true,
        principal: Principal(
          userId: authSession.userId,
          isAdmin: authSession.isAdmin,
        ),
        owner: project.owner,
        department: project.department,
      );
    } catch (e, stackTrace) {
      session.log(
        'Could not determine download access; refusing.',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<Result> _sendFile(
    Session session,
    Project project,
    String fileName,
    Response refused,
  ) async {
    final file = await fileService.resolveProjectFile(
      session,
      project.id!,
      fileName,
    );
    if (file == null) return refused;

    session.log(
      'Serving "$fileName" of project ${project.id}',
      level: LogLevel.info,
    );
    return Response.ok(
      body: Body.fromDataStream(
        file.openRead().map(
          (chunk) => chunk is Uint8List ? chunk : Uint8List.fromList(chunk),
        ),
        contentLength: await file.length(),
        // Everything here is a result file to be saved, not rendered. Serving
        // them as octet-stream also means a project file called something.html
        // can never be executed as a page on this origin.
        mimeType: MimeType.octetStream,
      ),
      headers: _attachmentHeaders(fileName),
    );
  }

  Future<Result> _sendZip(
    Session session,
    Project project,
    Response refused,
  ) async {
    final zip = await fileService.zipProjectFiles(session, project.id!);
    if (zip == null) return refused;

    final name = '${_safeStem(project.name)}-files.zip';
    // Read before the stream starts, because the stream ends by deleting it.
    final length = await zip.length();
    session.log(
      'Serving $length bytes of zip for project ${project.id}',
      level: LogLevel.info,
    );

    return Response.ok(
      body: Body.fromDataStream(
        _readThenDelete(session, zip),
        contentLength: length,
        mimeType: MimeType.octetStream,
      ),
      headers: _attachmentHeaders(name),
    );
  }

  /// The zip's bytes, and the zip deleted afterwards — however the reading ends.
  ///
  /// [FileService.zipProjectFiles] writes the whole archive to the system temp
  /// directory before the first byte is sent, so something has to delete it,
  /// and a response does not only end by finishing. The generator's `finally`
  /// covers all three endings: the last chunk sent, an error off the disk, and
  /// the client hanging up.
  ///
  /// ⚠️ That last one is why this is not a `handleDone` transformer, which
  /// fires only when the source stream completes normally. A client that
  /// disconnects cancels the subscription instead, which skips `handleDone`
  /// entirely — so every aborted "download all" used to strand a full copy of
  /// the project's files in the temp directory, and nothing ever reclaimed it.
  Stream<Uint8List> _readThenDelete(Session session, File zip) async* {
    try {
      await for (final chunk in zip.openRead()) {
        yield chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
      }
    } finally {
      try {
        await zip.delete();
      } catch (e) {
        // Not worth failing a download over — but a temp directory quietly
        // filling up is exactly the thing that should leave a trace.
        session.log(
          'Could not delete the temporary zip ${zip.path}',
          level: LogLevel.warning,
          exception: e,
        );
      }
    }
  }

  /// `Content-Disposition: attachment`, so the browser saves rather than
  /// displays, and offers the file's own name.
  ///
  /// The name is sent twice: a stripped ASCII `filename` for old clients, and
  /// RFC 5987 `filename*` carrying the real one. A project called `Müller panel`
  /// otherwise arrives as mojibake or breaks the header.
  Headers _attachmentHeaders(String fileName) {
    final ascii = fileName
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '_')
        .replaceAll('"', '');
    final encoded = Uri.encodeComponent(fileName);
    return Headers.build((h) {
      h['content-disposition'] = [
        'attachment; filename="$ascii"; filename*=UTF-8\'\'$encoded',
      ];
      // Result files change when generation is re-run under the same name.
      h['cache-control'] = ['no-store'];
    });
  }

  /// A project name reduced to something safe to put in a filename.
  static String _safeStem(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    return cleaned.isEmpty ? 'project' : cleaned;
  }
}

/// Reads the sign-in cookie, treating a malformed header as no cookie.
///
/// Same reasoning as the copy in `auth_routes.dart`: `CookieHeader.parse` throws
/// on things like a duplicate cookie name set by something else on the domain,
/// and that must not turn into a failed download.
String? _readAuthCookie(Request request) {
  final header = Headers.cookie.getValueFrom(
    request.headers,
    orElse: (_) => null,
  );
  return header?.getCookie(authCookieName)?.value;
}
