import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import '../services/authorization_service.dart';
import '../services/project_service.dart';
import '../services/settings_service.dart';
import '../generated/protocol.dart';
import 'flumip_endpoint.dart';

/// Endpoint for handling project-related operations.
class ProjectEndpoint extends FlumipEndpoint {
  ProjectService get projectService => ProjectService();

  /// Creates a new project.
  ///
  /// \param session The current session.
  /// \param name The name of the project.
  /// \param options The options for the project.
  /// \param description An optional description of the project.
  /// \returns The created [Project] object.
  Future<Project> createProject(
    Session session,
    String name,
    ProjectOptions options, [
    String? description,
  ]) async {
    session.log("Creating project with name: $name", level: LogLevel.info);
    try {
      return await projectService.createProject(
        session,
        name,
        options,
        description,
      );
    } catch (e) {
      session.log(
        "Error creating project with name: $name",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Deletes a project by ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project to delete.
  Future<void> deleteProject(Session session, int id) async {
    session.log("Deleting project with ID: $id", level: LogLevel.info);
    try {
      await requireProject(session, id);
      return await projectService.deleteProject(session, id);
    } catch (e) {
      session.log(
        "Error deleting project with ID: $id",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Retrieves all projects.
  ///
  /// \param session The current session.
  /// \returns A list of [Project] objects.
  Future<List<Project>> getProjects(Session session) async {
    session.log("Retrieving all projects", level: LogLevel.info);
    try {
      // Filtered, not all of them. Foreign projects are dropped here rather than
      // refused on open, so a user simply never sees work that is not theirs and
      // ProjectAccessDeniedException stays a thing only a hand-built request can hit.
      return await authz.visibleProjects(session);
    } catch (e) {
      session.log(
        "Error retrieving all projects",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Retrieves a project by ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project to retrieve.
  /// \returns The retrieved [Project] object.
  Future<Project> getProject(Session session, int id) async {
    session.log("Retrieving project with ID: $id", level: LogLevel.info);
    try {
      await requireProject(session, id);
      return await projectService.getProject(session, id);
    } catch (e) {
      session.log(
        "Error retrieving project with ID: $id",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Adds a gene to a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param gene The gene to add.
  Future<void> addGeneToProject(Session session, int id, String gene) async {
    session.log("Adding gene to project with ID: $id", level: LogLevel.info);
    try {
      await requireProject(session, id);
      return await projectService.addGeneToProject(session, id, gene);
    } catch (e) {
      session.log(
        "Error adding gene to project with ID: $id",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Removes a gene from a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param gene The gene to remove.
  Future<void> removeGeneFromProject(
    Session session,
    int id,
    String gene,
  ) async {
    session.log(
      "Removing gene from project with ID: $id",
      level: LogLevel.info,
    );
    try {
      await requireProject(session, id);
      return await projectService.removeGeneFromProject(session, id, gene);
    } catch (e) {
      session.log(
        "Error removing gene from project with ID: $id",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Adds multiple genes to a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param genes The list of genes to add.
  Future<void> addGenesToProject(
    Session session,
    int id,
    List<String> genes,
  ) async {
    session.log("Adding genes to project with ID: $id", level: LogLevel.info);
    try {
      await requireProject(session, id);
      return await projectService.addGenesToProject(session, id, genes);
    } catch (e) {
      session.log(
        "Error adding genes to project with ID: $id",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Sets the genome for a project by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param genomeId The ID of the genome to set.
  Future<void> setGeneById(Session session, int id, int genomeId) async {
    session.log("Setting gene to project with ID: $id", level: LogLevel.info);
    try {
      await requireProject(session, id);
      return await projectService.setGenomeById(session, id, genomeId);
    } catch (e) {
      session.log(
        "Error setting gene to project with ID: $id",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Turns the finish notification on or off for a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param enabled Whether to email the project's owner when generation ends.
  Future<void> setEmailNotification(
    Session session,
    int id,
    bool enabled,
  ) async {
    session.log(
      "Setting email notification to $enabled for project with ID: $id",
      level: LogLevel.info,
    );
    try {
      await requireProject(session, id);
      return await projectService.setEmailNotification(session, id, enabled);
    } catch (e) {
      session.log(
        "Error setting email notification for project with ID: $id",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Hands a project to a different owner, or to nobody.
  ///
  /// **Administrators only** — and note this is guarded by [AuthorizationService.requireAdmin]
  /// rather than `requireProject`. The two are not interchangeable: an owner
  /// passes `requireProject` for their own project, and being allowed to *use*
  /// something is not being allowed to give it away.
  ///
  /// A null [ownerId] releases the project to unowned, i.e. shared.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param ownerId The `flumip_user` id of the new owner, or null for unowned.
  Future<void> setProjectOwner(Session session, int id, int? ownerId) async {
    session.log(
      "Setting owner of project $id to ${ownerId ?? 'nobody'}",
      level: LogLevel.info,
    );
    try {
      await authz.requireAdmin(session);
      return await projectService.setOwner(session, id, ownerId);
    } catch (e) {
      session.log(
        "Error setting owner of project with ID: $id",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Every user a project can be handed to.
  ///
  /// **Administrators only.** This is the only endpoint that exposes the user
  /// list, so the gate is the whole of its security: an ordinary user has no
  /// business enumerating everyone with an account.
  ///
  /// \param session The current session.
  Future<List<FlumipUserDto>> assignableOwners(Session session) async {
    try {
      await authz.requireAdmin(session);
      final users = await projectService.assignableOwners(session);
      return users
          .map(
            (u) => FlumipUserDto(
              id: u.id!,
              email: u.email,
              displayName: u.displayName,
            ),
          )
          .toList();
    } catch (e) {
      session.log(
        "Error listing assignable owners",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Moves a project into a department, or out of every department with null.
  ///
  /// ⚠️ **Not admin-gated, unlike [setProjectOwner]** — the owner of a project
  /// decides which of *their own* groups it belongs to, and the service refuses
  /// a department the caller is not in. Requiring an admin would put a lab
  /// administrator in the loop for something the person who made the project
  /// already knows the answer to.
  ///
  /// \param session The current session.
  /// \param id The project.
  /// \param department The group name, or null to remove it.
  Future<void> setProjectDepartment(
    Session session,
    int id,
    String? department,
  ) async {
    session.log(
      "Setting department of project $id to ${department ?? 'none'}",
      level: LogLevel.info,
    );
    try {
      await requireProject(session, id);
      return await projectService.setDepartment(session, id, department);
    } on ArgumentException {
      rethrow;
    } on ProjectAccessDeniedException {
      rethrow;
    } catch (e) {
      session.log(
        "Error setting department of project with ID: $id",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// The departments the caller may put a project into.
  ///
  /// Their own groups, as the identity provider reported them at sign-in.
  /// **Empty when no department claim is configured**, which is the default —
  /// the app hides the control entirely in that case rather than offering a
  /// picker with nothing in it.
  ///
  /// An administrator additionally gets every department already in use, so
  /// that they can tidy up after a group is renamed without being a member of
  /// it.
  ///
  /// Leaks nothing an ordinary caller did not already tell us: these are the
  /// groups the provider put in their own token.
  ///
  /// \param session The current session.
  Future<List<String>> assignableDepartments(Session session) async {
    try {
      return await projectService.assignableDepartments(session);
    } catch (e) {
      session.log(
        "Error listing assignable departments",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Whether an administrator has switched mail on for this install.
  ///
  /// The per-project notification switch is meaningless without it, so the app
  /// asks once and hides the control when this is false. **Advisory only** — the
  /// server decides what is actually sent, on the send path. Deliberately not
  /// part of [SettingsEndpoint]: every method there is admin-gated, and an
  /// ordinary user has to be able to read this to render their own switch.
  ///
  /// \param session The current session.
  Future<bool> notificationsAvailable(Session session) async {
    final settings = await SettingsService().getSettings(session);
    return settings.mailActive;
  }

  /// Sets the SNP for a project, or clears it.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param snpId The ID of the SNP to set, or null for no SNP masking. Clearing
  ///   became necessary once an SNP set could be deleted or fail to import, which
  ///   can leave a project pointing at one it can no longer use.
  Future<void> setSnpById(Session session, int id, int? snpId) async {
    session.log("Setting snp to project with ID: $id", level: LogLevel.info);
    try {
      await requireProject(session, id);
      return await projectService.setSnpById(session, id, snpId);
    } catch (e) {
      session.log(
        "Error setting snp to project with ID: $id",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }
}
