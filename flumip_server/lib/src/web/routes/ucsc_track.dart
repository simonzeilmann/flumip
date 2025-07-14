import 'dart:io';

import 'package:flumip_server/src/services/file_service.dart';
import 'package:flumip_server/src/web/widgets/default_page_widget.dart';
import 'package:serverpod/serverpod.dart';

import '../../services/project_service.dart';

class UCSCTrackRoute extends WidgetRoute {
  final projectService = ProjectService();
  final fileService = FileService();

  @override
  Future<Widget> build(Session session, HttpRequest request) async {
    var requestUrl = request.requestedUri.toString();
    var projectId = int.tryParse(requestUrl.split('/').last);
    session.log(
        'UCSC Track for project $projectId requested by ${request.remoteIpAddress}');
    var project = await projectService.getProject(session, projectId!);
    if (project.id == null) {
      session.log("Project ID does not exist: $projectId",
          level: LogLevel.error);
      throw ArgumentError('Project id does not exist');
    }
    var track = await fileService.returnFile(
        session, projectId, "ucsc_track.bed");

    await track.pipe(request.response);

    //TODO: Rework so no exception gets shot into the ether
    return DefaultPageWidget();
  }
}
