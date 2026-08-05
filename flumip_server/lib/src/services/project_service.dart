import 'dart:io';
import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/authorization_service.dart';
import 'package:flumip_server/src/services/process_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';
import 'package:uuid/uuid.dart';

/// A service class for handling project-related operations.
class ProjectService {
  ProjectService();

  /// Retrieves a project by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project to retrieve.
  /// \returns The retrieved [Project] object.
  /// \throws [FileNotFoundException] if the project is not found.
  Future<Project> getProject(Session session, int id) async {
    session.log("Retrieving project with ID: $id", level: LogLevel.info);
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FlumipFileNotFoundException(message: 'Project not found');
    }
    session.log("Project retrieved with ID: $id", level: LogLevel.info);
    return project;
  }

  /// Creates a new project.
  ///
  /// \param session The current session.
  /// \param projectName The name of the project to create.
  /// \param options The [ProjectOptions] for the project.
  /// \param desc An optional description for the project.
  /// \returns The created [Project] object.
  /// \throws [ArgumentError] if the project name is empty.
  Future<Project> createProject(
    Session session,
    String projectName,
    ProjectOptions options, [
    String? desc,
  ]) async {
    session.log(
      "Creating project with name: $projectName",
      level: LogLevel.info,
    );
    if (projectName == '') {
      session.log("Project name cannot be empty", level: LogLevel.error);
      throw ArgumentError('Project name cannot be empty');
    }

    var projectRow = Project(
      name: projectName,
      description: desc,
      folderName: Uuid().v7(),
      options: options.id!,
      // Null while single sign-on is off, which is what keeps every project on a
      // no-auth install unowned and therefore shared. Stamping is done here
      // rather than in the endpoint because it populates data; the *checks* live
      // at the endpoint boundary, where unauthenticated future calls cannot trip
      // over them.
      owner: await authz.ownerForNewProject(session),
      trackToken: Uuid().v7(),
    );
    var project = await Project.db.insertRow(session, projectRow);

    // Schedule demo mode cleanup
    await session.serverpod.futureCallWithDelay(
      'demoModeCleanup',
      project,
      const Duration(days: 7),
      identifier: project.folderName,
    );

    var settings = await SettingsService().getSettings(session);
    await Directory("${settings.projectDir}/${project.folderName}").create();
    session.log("Project created with ID: ${project.id}", level: LogLevel.info);
    return project;
  }

  /// Deletes a project by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project to delete.
  /// \throws [FileNotFoundException] if the project is not found.
  Future<void> deleteProject(Session session, int id) async {
    ProcessService processService = sl<ProcessService>();

    session.log("Deleting project with ID: $id", level: LogLevel.info);
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FlumipFileNotFoundException(message: 'Project not found');
    } else {
      await Project.db.deleteRow(session, project);
      await ProjectOptions.db.deleteWhere(
        session,
        where: (t) => t.id.equals(project.options),
      );

      if (project.active && project.pid != null && project.pid! > 0) {
        await processService.terminateProcess(session, project.pid!);
      }
      var settings = await SettingsService().getSettings(session);
      await Directory(
        "${settings.projectDir}/${project.folderName}",
      ).delete(recursive: true);
      // Cancel any scheduled future calls related to this project
      await session.serverpod.cancelFutureCall(project.folderName!);
      session.log("Project deleted with ID: $id", level: LogLevel.info);
    }
  }

  /// Adds a gene to a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param gene The gene to add.
  /// \throws [FileNotFoundException] if the project is not found.
  /// \throws [Exception] if the gene already exists in the project.
  /// \throws [ArgumentError] if the gene is empty or contains invalid characters.
  Future<void> addGeneToProject(Session session, int id, String gene) async {
    session.log("Adding gene to project with ID: $id", level: LogLevel.info);
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FlumipFileNotFoundException(message: 'Project not found');
    }
    if (project.genes != null && project.genes!.contains(gene)) {
      session.log(
        "Gene already exists in project with ID: $id",
        level: LogLevel.error,
      );
      throw Exception('Gene already exists in project');
    }
    if (gene.isEmpty || gene == '') {
      session.log("Supplied gene is empty", level: LogLevel.error);
      throw ArgumentError('Supplied gene empty');
    }
    if (RegExp(r'^[A-Za-z0-9]+$').hasMatch(gene)) {
      project.genes ??= [];
      project.genes!.add(gene.toUpperCase());
      await Project.db.updateRow(session, project);
      session.log("Gene added to project with ID: $id", level: LogLevel.info);
    } else {
      session.log(
        "Gene name contains invalid characters",
        level: LogLevel.error,
      );
      throw ArgumentError('Gene name contains invalid characters');
    }
  }

  /// Removes a gene from a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param gene The gene to remove.
  /// \throws [FileNotFoundException] if the project is not found.
  /// \throws [Exception] if the project does not have any genes.
  Future<void> removeGeneFromProject(
    Session session,
    int id,
    String gene,
  ) async {
    session.log(
      "Removing gene from project with ID: $id",
      level: LogLevel.info,
    );
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FlumipFileNotFoundException(message: 'Project not found');
    } else {
      if (project.genes == null) {
        session.log("Project does not have any genes", level: LogLevel.error);
        throw Exception('Project does not have any genes');
      }
      project.genes!.remove(gene);
      await Project.db.updateRow(session, project);
      session.log(
        "Gene removed from project with ID: $id",
        level: LogLevel.info,
      );
    }
  }

  /// Adds multiple genes to a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param genes The list of genes to add.
  /// \throws [FileNotFoundException] if the project is not found.
  /// \throws [ArgumentError] if any gene is empty or contains invalid characters.
  Future<void> addGenesToProject(
    Session session,
    int id,
    List<String> genes,
  ) async {
    session.log(
      "Adding multiple genes to project with ID: $id",
      level: LogLevel.info,
    );
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FlumipFileNotFoundException(message: 'Project not found');
    } else {
      for (var gene in genes) {
        if (gene.isEmpty || gene == '') {
          session.log("Supplied gene is empty", level: LogLevel.error);
          throw ArgumentError('Supplied gene empty');
        }
        if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(gene)) {
          session.log(
            "Gene name contains invalid characters",
            level: LogLevel.error,
          );
          throw ArgumentError('Gene name contains invalid characters');
        }
      }
      project.genes = genes;
      await Project.db.updateRow(session, project);
      session.log(
        "Multiple genes added to project with ID: $id",
        level: LogLevel.info,
      );
    }
  }

  /// The token for this project's public `/ucsc_track/<token>` URL, minting one
  /// if the project does not have it yet.
  ///
  /// Projects created before the token existed have null here, so this fills it
  /// in on first request rather than in a migration — generating per-row UUIDs in
  /// SQL would have meant hand-editing generated migration output, which the next
  /// `serverpod create-migration` could quietly undo.
  ///
  /// The caller is responsible for the access check; this is reached through
  /// `FileEndpoint.getUcscTrackToken`, which does it.
  Future<String> ensureTrackToken(Session session, int id) async {
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FlumipFileNotFoundException(message: 'Project not found');
    }

    final existing = project.trackToken;
    if (existing != null && existing.isNotEmpty) return existing;

    final token = Uuid().v7();
    project.trackToken = token;
    await Project.db.updateRow(session, project);
    session.log(
      "Minted a UCSC track token for project ID: $id",
      level: LogLevel.info,
    );
    return token;
  }

  /// Retrieves all projects, **without any access filtering**.
  ///
  /// Not what an endpoint wants. `ProjectEndpoint.getProjects` goes through
  /// `AuthorizationService.visibleProjects`, which applies the same predicate the
  /// per-project gate uses. This stays as the unfiltered primitive for internal
  /// callers that legitimately need every row.
  ///
  /// \param session The current session.
  /// \returns A list of [Project] objects.
  Future<List<Project>> getProjects(Session session) async {
    session.log("Retrieving all projects", level: LogLevel.info);
    var projects = await Project.db.find(session, where: (t) => t.id > 0);
    session.log("Projects retrieved", level: LogLevel.info);
    return projects;
  }

  /// Updates an existing project.
  ///
  /// \param session The current session.
  /// \param project The [Project] object to update.
  Future<void> updateProject(Session session, Project project) async {
    session.log(
      "Updating project with ID: ${project.id}",
      level: LogLevel.info,
    );
    await Project.db.updateRow(session, project);
    session.log("Project updated with ID: ${project.id}", level: LogLevel.info);
  }

  /// Sets the genome for a project by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param geneId The ID of the genome to set.
  /// \throws [FileNotFoundException] if the project or genome is not found.
  Future<void> setGenomeById(Session session, int id, int geneId) async {
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FlumipFileNotFoundException(message: 'Project not found');
    }
    var genome = await Genome.db.findById(session, geneId);
    if (genome == null) {
      session.log("Gene not found with ID: $geneId", level: LogLevel.error);
      throw FlumipFileNotFoundException(message: 'Gene not found');
    }
    project.genome = geneId;
    await Project.db.updateRow(session, project);
  }

  /// Sets the SNP for a project, or clears it when [snpId] is null.
  ///
  /// Three checks the first version did not make, each now possible because an
  /// SNP knows which genome it belongs to and whether its bytes have arrived:
  ///
  /// - **The builds must match.** VCF coordinates are build-specific, so an hg38
  ///   file used against hs1 does not fail — it quietly designs the wrong MIPs.
  /// - **The caller must be able to see it.** Without this, guessing an id would
  ///   attach somebody else's private upload, and its contents could then be read
  ///   back indirectly out of the design output.
  /// - **It must be ready.** A failed or half-downloaded import has no usable VCF.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param snpId The ID of the SNP to set, or null to use no SNP.
  /// \throws [FlumipFileNotFoundException] if the project or SNP is not found.
  /// \throws [ArgumentException] if the SNP is for another genome or not ready.
  Future<void> setSnpById(Session session, int id, int? snpId) async {
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FlumipFileNotFoundException(message: 'Project not found');
    }

    if (snpId == null) {
      project.snp = null;
      await Project.db.updateRow(session, project);
      return;
    }

    var snp = await Snp.db.findById(session, snpId);
    if (snp == null) {
      session.log("Snp not found with ID: $snpId", level: LogLevel.error);
      throw FlumipFileNotFoundException(message: 'Snp not found');
    }
    await authz.requireSnpAccess(session, snp);

    if (snp.genome != null && snp.genome != project.genome) {
      session.log(
        "Refused SNP $snpId for project $id: it is for genome ${snp.genome}, "
        "the project uses ${project.genome}",
        level: LogLevel.error,
      );
      throw ArgumentException(
        message: 'That SNP set is for a different genome build.',
      );
    }

    if (snp.status != SnpImportStatus.ready) {
      session.log(
        "Refused SNP $snpId for project $id: status is ${snp.status.name}",
        level: LogLevel.error,
      );
      throw ArgumentException(
        message: 'That SNP set is not ready to use yet.',
      );
    }

    project.snp = snpId;
    await Project.db.updateRow(session, project);
  }

  /// Hands a project to a different owner, or to nobody.
  ///
  /// A null [ownerId] makes the project **unowned**, which is not the same as
  /// orphaned: unowned means shared, reachable by everyone, and it is the state
  /// every project predating authorization is already in. It is the correct way
  /// to release a project that should not belong to one person.
  ///
  /// The user is looked up rather than trusted, so a bad id fails here with a
  /// readable message instead of as a foreign-key violation from the driver.
  ///
  /// No access check: reassignment is administrative and is gated at the
  /// endpoint, like every other rule in this codebase. Guarding here would also
  /// stop the unauthenticated future calls that legitimately write projects.
  Future<void> setOwner(Session session, int id, int? ownerId) async {
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FlumipFileNotFoundException(message: 'Project not found');
    }

    if (ownerId != null) {
      final user = await FlumipUser.db.findById(session, ownerId);
      if (user == null) {
        session.log("User not found with ID: $ownerId", level: LogLevel.error);
        throw FlumipFileNotFoundException(message: 'User not found');
      }
    }

    project.owner = ownerId;
    await Project.db.updateRow(session, project);
  }

  /// Every user a project can be handed to, oldest account first.
  ///
  /// Only ever reached through an admin-gated endpoint — this is the one place
  /// the user list becomes visible to a client at all.
  Future<List<FlumipUser>> assignableOwners(Session session) {
    return FlumipUser.db.find(
      session,
      orderBy: (t) => t.id,
    );
  }

  /// Turns "email me when MIP generation finishes" on or off for a project.
  ///
  /// The flag is stored unconditionally — including when mail is globally off,
  /// or the project is unowned and so has nobody to notify. Whether anything is
  /// actually sent stays decided in one place, on the send path:
  /// `MailService.notifyProjectFinished` checks `Settings.mailActive`, and
  /// `MailService.resolveRecipient` needs an owner. Re-checking either here
  /// would be a second expression of the same rule — the thing
  /// `projectIsAccessible` exists to avoid — and would additionally make the
  /// flag impossible to set ahead of an administrator switching mail on.
  Future<void> setEmailNotification(
    Session session,
    int id,
    bool enabled,
  ) async {
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FlumipFileNotFoundException(message: 'Project not found');
    }
    project.emailNotification = enabled;
    await Project.db.updateRow(session, project);
  }
}
