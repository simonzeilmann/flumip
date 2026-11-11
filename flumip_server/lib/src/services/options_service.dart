import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:serverpod/server.dart';

/// A service class for handling project options.
///
/// ⚠️ Everything that arrives here as a [ProjectOptions] came from the client
/// and is treated as such: the row written is the one the caller *named*, never
/// the one the object says it is, and only the fields a client may set are
/// taken from it. Who may name which row is decided at the endpoint, by
/// `AuthorizationService.requireOptionsAccessForAll`.
class OptionsService {
  OptionsService();

  /// Creates a new project options entry.
  ///
  /// \param session The current session.
  /// \returns The created [ProjectOptions] object.
  Future<ProjectOptions> createProjectOptions(Session session) async {
    var projectOptions = ProjectOptions();

    return projectOptions;
  }

  /// Inserts a new project options entry in the database.
  ///
  /// Always a new row: an id on [options] is dropped rather than honoured, so
  /// this cannot be used to write over a row that exists.
  ///
  /// \param session The current session.
  /// \param options The [ProjectOptions] object to insert.
  /// \returns The inserted [ProjectOptions] object.
  /// \throws [ArgumentException] if a value cannot be given to mipgen.
  Future<ProjectOptions> insertProjectOptions(
    Session session,
    ProjectOptions options,
  ) async {
    final row = clientSettable(options).copyWith(id: null);
    var projectOptions = await ProjectOptions.db.insertRow(session, row);
    return projectOptions;
  }

  /// Retrieves a project options entry by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project options to retrieve.
  /// \returns The retrieved [ProjectOptions] object.
  /// \throws [FlumipFileNotFoundException] if the project options are not found.
  Future<ProjectOptions> getProjectOptions(Session session, int id) async {
    var projectOptions = await ProjectOptions.db.findById(session, id);
    if (projectOptions == null) {
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }
    return projectOptions;
  }

  /// Updates an existing project options entry in the database.
  ///
  /// ⚠️ Writes row [id], whatever `options.id` says. This used to hand
  /// [options] to `updateRow` as it came, and `updateRow` writes the row the
  /// *object* names — so the access check on [id] guarded one row and the
  /// write landed on another. Anybody could overwrite the options of any
  /// project by naming their own options as [id] and the victim's in the body.
  ///
  /// \param session The current session.
  /// \param id The ID of the project options to update.
  /// \param options The updated [ProjectOptions] object.
  /// \throws [FlumipFileNotFoundException] if the project options are not found.
  /// \throws [ArgumentException] if a value cannot be given to mipgen.
  Future<void> updateProjectOptions(
    Session session,
    int id,
    ProjectOptions options,
  ) async {
    var projectOptions = await ProjectOptions.db.findById(session, id);
    if (projectOptions == null) {
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }
    await ProjectOptions.db.updateRow(
      session,
      clientSettable(options).copyWith(id: id),
    );
  }

  /// Deletes a project options entry from the database.
  ///
  /// Refuses options a project still uses. Deleting them would leave that
  /// project pointing at nothing — it could no longer run or show its
  /// settings — and the way to be rid of a project's options is to delete
  /// the project, which takes them with it.
  ///
  /// \param session The current session.
  /// \param id The ID of the project options to delete.
  /// \throws [FlumipFileNotFoundException] if the project options are not found.
  /// \throws [ArgumentException] if a project still uses them.
  Future<void> deleteProjectOptions(Session session, int id) async {
    var projectOptions = await ProjectOptions.db.findById(session, id);
    if (projectOptions == null) {
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }
    final users = await Project.db.count(
      session,
      where: (t) => t.options.equals(id),
    );
    if (users > 0) {
      throw ArgumentException(
        message:
            'These options belong to a project. Delete the project instead.',
      );
    }
    await ProjectOptions.db.deleteRow(session, projectOptions);
  }

  /// [options] reduced to what a client may set, or the reason it cannot be.
  ///
  /// The values are checked by [mipgenOptionsProblem] so that somebody typing
  /// an impossible one hears about it when saving rather than when the run
  /// fails. `genomeDir` is cleared: it is a server path, mipgen is never given
  /// it any more (see `MipgenService._prepareRun`), and a client-chosen path
  /// has no business being stored as though it were one.
  ///
  /// The id is left for the caller to decide, because inserting and updating
  /// want opposite things done with it.
  static ProjectOptions clientSettable(ProjectOptions options) {
    final problem = mipgenOptionsProblem(options);
    if (problem != null) throw ArgumentException(message: problem);
    return options.copyWith(genomeDir: null);
  }
}
