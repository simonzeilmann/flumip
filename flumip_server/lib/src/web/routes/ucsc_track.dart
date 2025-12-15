import 'package:flumip_server/src/services/file_service.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:flumip_server/service_locator.dart';

class UCSCTrackRoute extends Route {
  UCSCTrackRoute() : super(methods: {Method.get});
  final projectService = sl<ProjectService>();
  final fileService = sl<FileService>();
  static const _idParam = IntPathParam(#id);

  @override
  Future<Result> handleCall(Session session, Request request) async {
    var projectId = request.pathParameters.get(_idParam);
    session.log(
      'UCSC Track for project $projectId requested by ${request.connectionInfo.remote.address}',
    );

    String track;
    try {
      track = await fileService.readFileAsString(
        session,
        projectId,
        "ucsc_track.bed",
      );
    } catch (e) {
      return Response.notFound(body: Body.fromString("UCSC track not found"));
    }

    if (track.isEmpty) {
      return Response.notFound(body: Body.fromString("UCSC track is empty"));
    }

    return Response.ok(
      body: Body.fromString(track, mimeType: MimeType.plainText),
    );
  }
}
