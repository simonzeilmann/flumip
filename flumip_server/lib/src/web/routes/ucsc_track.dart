import 'package:flumip_server/src/services/file_service.dart';
import 'package:serverpod/serverpod.dart';

import '../../services/project_service.dart';

class UCSCTrackRoute extends Route {
  UCSCTrackRoute() : super(methods: {Method.get});
  final projectService = ProjectService();
  final fileService = FileService();
  static const _idParam = IntPathParam(#id);

  @override
  Future<Result> handleCall(Session session, Request request) async {
    var projectId = request.pathParameters.get(_idParam);
    session.log(
        'UCSC Track for project $projectId requested by ${request.connectionInfo.remote.address}');
    var project = await projectService.getProject(session, projectId);
    if (project.id == null) {
      session.log("Project ID does not exist: $projectId",
          level: LogLevel.error);
      throw ArgumentError('Project id does not exist');
    }

    var track = await fileService.readFileAsString(session, projectId, "ucsc_track.bed");
    if (track.isEmpty) {
      return Response.notFound();
    }

    return Response.ok(
      body: Body.fromString(
        track,
        mimeType: MimeType.plainText,
      ),
    );
  }
}
