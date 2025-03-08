import 'package:flumip_server/src/generated/project_options.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

class OptionsService {
  OptionsService();

  Future<ProjectOptions> createProjectOptions(Session session) async {
    var projectOptionsRow = ProjectOptions();
    var projectOptions =
        await ProjectOptions.db.insertRow(session, projectOptionsRow);

    return projectOptions;
  }

  Future<ProjectOptions> getProjectOptions(Session session, int id) async {
    var projectOptions = await ProjectOptions.db.findById(session, id);
    if (projectOptions == null) {
      throw FileNotFoundException(message: 'Project options not found');
    }
    return projectOptions;
  }

  Future<void> updateProjectOptions(
      Session session, int id, ProjectOptions options) async {
    var projectOptions = await ProjectOptions.db.findById(session, id);
    if (projectOptions == null) {
      throw FileNotFoundException(message: 'Project options not found');
    }
    await ProjectOptions.db.updateRow(session, options);
  }

  Future<void> deleteProjectOptions(Session session, int id) async {
    var projectOptions = await ProjectOptions.db.findById(session, id);
    if (projectOptions == null) {
      throw FileNotFoundException(message: 'Project options not found');
    }
    await ProjectOptions.db.deleteRow(session, projectOptions);
  }
}
