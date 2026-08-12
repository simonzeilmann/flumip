import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/file_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:flumip_server/service_locator.dart';

/// Serves a project's BED track for the UCSC Genome Browser.
///
/// ## Why this route has no authentication, and what stands in for it
///
/// The client here is not a browser holding a session — it is genome.ucsc.edu,
/// fetching the URL the user pasted into `hgt.customText`. It sends no cookie and
/// no bearer, and there is nowhere to sign in. So the route cannot be gated the
/// way the endpoints are, and adding [FlumipEndpoint]-style checks would simply
/// break the feature.
///
/// It used to be keyed on the project's primary key: `/ucsc_track/1`,
/// `/ucsc_track/2`, and so on. That made every project's track readable by
/// anyone who could reach the port, and — because the ids are sequential —
/// enumerable in a single loop. Authorizing the endpoints while leaving that in
/// place would have been decorative.
///
/// It is now keyed on `Project.trackToken`, a per-project v7 UUID that is
/// `serverOnly` and only ever handed out by `FileEndpoint.getUcscTrackToken`
/// after an access check. Unguessable in place of authenticated: the URL itself
/// is the capability, which is the standard shape for a resource a third-party
/// service must fetch on the user's behalf.
///
/// Consequences worth knowing:
///
/// - The token is a credential. It is never logged; the project id is logged
///   instead.
/// - An unknown token and a project with no track file get the **same** 404, so
///   the response cannot be used to test whether a token is real.
/// - Anyone holding the URL can read that one track. Rotating it means clearing
///   `trackToken`; the next request from the owner mints a new one.
class UCSCTrackRoute extends Route {
  UCSCTrackRoute() : super(methods: {Method.get});
  final fileService = sl<FileService>();

  static String _asToken(String value) => value;
  static const _tokenParam = PathParam<String>(#token, _asToken);

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final notFound = Response.notFound(
      body: Body.fromString("UCSC track not found"),
    );

    final token = request.pathParameters.get(_tokenParam);
    if (token.isEmpty) return notFound;

    final project = await Project.db.findFirstRow(
      session,
      where: (t) => t.trackToken.equals(token),
    );
    if (project == null) {
      // Deliberately indistinguishable from "no track file", and deliberately
      // without the token in the log line.
      session.log(
        'UCSC track requested with an unknown token from '
        '${request.connectionInfo.remote.address}',
        level: LogLevel.warning,
      );
      return notFound;
    }

    session.log(
      'UCSC Track for project ${project.id} requested by '
      '${request.connectionInfo.remote.address}',
    );

    String track;
    try {
      track = await fileService.readFileAsString(
        session,
        project.id!,
        "ucsc_track.bed",
      );
    } catch (e) {
      return notFound;
    }

    if (track.isEmpty) {
      return Response.notFound(body: Body.fromString("UCSC track is empty"));
    }

    return Response.ok(
      body: Body.fromString(track, mimeType: MimeType.plainText),
    );
  }
}
