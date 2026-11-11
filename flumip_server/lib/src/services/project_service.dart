import 'dart:io';
import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/future_calls.dart';
import 'package:flumip_server/src/auth/auth_tokens.dart';
import 'package:flumip_server/src/auth/project_access.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/auth_service.dart';
import 'package:flumip_server/src/services/authorization_service.dart';
import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:flumip_server/src/services/options_service.dart';
import 'package:flumip_server/src/services/process_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';
import 'package:uuid/uuid.dart';

/// What a gene symbol is allowed to look like.
///
/// ⚠️ Letters and numbers only, which rejects every real HGNC symbol containing
/// a hyphen — `HLA-A`, `NKX2-1`, `MT-CO1`. That is the rule as it has always
/// been, named here rather than repeated as a literal in two places so that
/// widening it is one edit. Widening it is a behaviour change nobody has asked
/// for yet; see HANDOFF.md.
final geneSymbol = RegExp(r'^[A-Za-z0-9]+$');

/// The longest name a project can be given.
const projectNameMaxLength = 100;

/// C0 and C1 control characters, line breaks and tabs among them.
final _controlCharacter = RegExp(r'[\x00-\x1F\x7F-\x9F  ]');

/// Whether projects on this server are deleted automatically: demo mode, or a
/// public instance, which implies it.
///
/// Whether a particular project goes is [projectExpires].
bool projectsExpire(Settings settings) => settings.demoMode || authz.isPublic;

/// Whether [project] is deleted automatically, leaving aside
/// [Project.keptIndefinitely].
///
/// On a public instance only guests' projects are, and [Project.expires] is the
/// record of which those are: stamped when a guest creates the project, left
/// null when a signed-in user does (see [newProjectExpires]). A guest's project
/// keeps its date after the guest's identity is cleaned up and the owner goes,
/// which is what still deletes it then. Demo mode changes nothing there.
///
/// Elsewhere it is demo mode, for every project, and a null [Project.expires]
/// falls back to the retention window; see [deletionDeadline].
bool projectExpires(Project project, Settings settings) =>
    authz.isPublic ? project.expires != null : settings.demoMode;

/// Whether a project [creator] makes now is given a deletion date.
bool newProjectExpires(Principal creator, Settings settings) =>
    authz.isPublic ? creator.isGuest : settings.demoMode;

/// The end of the day [moment] falls in: the first midnight, in the server's
/// own time zone, at or after it.
///
/// Projects are deleted when their last day is over rather than at the minute
/// they were created, so a project shows one date and keeps it all day. A
/// moment that is already exactly midnight is its own end of day — which is what
/// keeps [deletionDeadline] and `extendProject` from creeping a day further on
/// every pass.
DateTime endOfDay(DateTime moment) {
  final local = moment.toLocal();
  final midnight = DateTime(local.year, local.month, local.day);
  if (local.isAtSameMomentAs(midnight)) return midnight.toUtc();
  return DateTime(local.year, local.month, local.day + 1).toUtc();
}

/// When [project] is due to be deleted, assuming [projectExpires]: always a
/// midnight, the end of the project's last day.
///
/// [Project.expires] where it is set, but never earlier than the end of the day
/// [Project.created] plus the current retention window falls in. That floor
/// keeps the rule this had before the column existed: **raising** the window
/// spares projects that are already scheduled, while lowering it cannot pull a
/// deletion forward. It is also the whole answer for a project from before
/// [Project.expires] existed, where the column is null.
DateTime deletionDeadline(Project project, Settings settings) {
  final floor = endOfDay(project.created.toUtc().add(demoRetention(settings)));
  final expires = project.expires?.toUtc();
  return expires != null && expires.isAfter(floor) ? expires : floor;
}

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
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
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
  /// \throws [ArgumentException] if the project name is empty, longer than
  /// [projectNameMaxLength], or contains control characters.
  Future<Project> createProject(
    Session session,
    String projectName,
    ProjectOptions options, [
    String? desc,
  ]) async {
    _requireValidName(session, projectName);
    session.log(
      "Creating project with name: $projectName",
      level: LogLevel.info,
    );
    // Before the directory below: options that were never saved have no id, and
    // `options.id!` used to throw a bare null check *after* the folder existed,
    // so the caller got a 500 and an empty folder was left behind. The app
    // always saves the options first; this is for anything else on the API.
    if (options.id == null) {
      session.log("Project options were never saved", level: LogLevel.error);
      throw ArgumentException(
        message: 'Save the project options before creating the project.',
      );
    }
    // ⚠️ Options and projects are one to one, and this is what keeps them so.
    // Only the id of [options] is used, and it used to be taken on trust: a
    // project could be created pointing at the options of somebody else's
    // project. The new project then counted as "the project owning those
    // options" for the access check, which made the victim's configuration
    // readable and writable — and deleting the new project deleted the
    // victim's options with it. Fresh, unused options are the only kind a
    // project can be created with; the app always inserts them just before.
    if (await ProjectOptions.db.findById(session, options.id!) == null ||
        await Project.db.count(
              session,
              where: (t) => t.options.equals(options.id!),
            ) >
            0) {
      session.log(
        "Refusing to create a project with options ${options.id}: they are "
        "missing or already used by another project",
        level: LogLevel.warning,
      );
      throw ArgumentException(
        message:
            'These project options are already in use. Save new options '
            'before creating the project.',
      );
    }

    final (settings, who) = await _admitCreator(session);
    return _insertProject(
      session,
      settings,
      who,
      name: projectName,
      description: desc,
      optionsId: options.id!,
    );
  }

  /// Creates a project with its genome, SNP set and genes already chosen.
  ///
  /// What the create-project form calls. [createProject] makes a bare project
  /// and leaves the rest to one call each; this takes all of it at once, so the
  /// form's "Save" either makes the whole project or makes nothing.
  ///
  /// ⚠️ **Every refusal comes before the first write.** The name, the options,
  /// the genome, the SNP set, the genes and the guest quota are all checked
  /// first, with the same rules — the same code — as the calls that set them
  /// one at a time. Only then are the options inserted, and they are removed
  /// again if the project cannot be made after all, so a failure never leaves
  /// options that belong to nothing.
  ///
  /// \param session The current session.
  /// \param draft What the form collected.
  /// \returns The created [Project] object.
  /// \throws [ArgumentException] if the name, an option, a gene or the SNP set
  /// is refused, or the caller is a guest with no room for another project.
  /// \throws [FlumipFileNotFoundException] if the genome or the SNP set is gone.
  Future<Project> createConfiguredProject(
    Session session,
    ProjectDraftDto draft,
  ) async {
    _requireValidName(session, draft.name);
    // Thrown away: this is only the check. The row is written further down by
    // the options service, which reduces the options the same way.
    OptionsService.clientSettable(draft.options);

    final genomeId = draft.genome;
    if (genomeId != null) await _requireGenome(session, genomeId);
    final snpId = draft.snp;
    if (snpId != null) await _requireUsableSnp(session, snpId, genomeId);
    final genes = _normaliseGenes(session, draft.genes ?? const []);

    final (settings, who) = await _admitCreator(session);

    session.log(
      "Creating configured project with name: ${draft.name}",
      level: LogLevel.info,
    );
    final options = await OptionsService().insertProjectOptions(
      session,
      draft.options,
    );
    try {
      return await _insertProject(
        session,
        settings,
        who,
        name: draft.name,
        description: draft.description,
        optionsId: options.id!,
        genome: genomeId,
        snp: snpId,
        // Null rather than empty, which is what a project nobody has added a
        // gene to looks like everywhere else.
        genes: genes.isEmpty ? null : genes,
        emailNotification: draft.emailNotification,
      );
    } catch (_) {
      await ProjectOptions.db.deleteRow(session, options);
      rethrow;
    }
  }

  /// Refuses a project name that is empty, too long, or not a label.
  void _requireValidName(Session session, String projectName) {
    if (projectName == '') {
      session.log("Project name cannot be empty", level: LogLevel.error);
      throw ArgumentException(message: 'A project needs a name.');
    }
    // The name is a label: it is shown, mailed and logged, and never handed to
    // mipgen as it is (see `mipgenPrefixOf`). So any printable text is fine,
    // and these two rules are only about what a label cannot be — anybody can
    // type this on a public instance.
    if (projectName.length > projectNameMaxLength) {
      session.log("Project name is too long", level: LogLevel.error);
      throw ArgumentException(
        message:
            'A project name can be at most $projectNameMaxLength characters.',
      );
    }
    if (_controlCharacter.hasMatch(projectName)) {
      session.log(
        "Project name contains control characters",
        level: LogLevel.error,
      );
      throw ArgumentException(
        message: 'A project name cannot contain line breaks or tabs.',
      );
    }
  }

  /// Who is creating a project, and under which settings — or a refusal, for a
  /// guest who has no room for another one.
  ///
  /// Called before anything is written, for the reason [_insertProject] gives
  /// for its own ordering.
  Future<(Settings, Principal)> _admitCreator(Session session) async {
    final settings = await SettingsService().getSettings(session);
    final who = await authz.principal(session);
    await _requireGuestQuota(session, who, settings);
    return (settings, who);
  }

  /// Makes the project's folder, its row and its cleanup call.
  ///
  /// The last step of both ways to create a project. Everything that can refuse
  /// has already run by the time this is called.
  Future<Project> _insertProject(
    Session session,
    Settings settings,
    Principal who, {
    required String name,
    required String? description,
    required int optionsId,
    int? genome,
    int? snp,
    List<String>? genes,
    bool emailNotification = false,
  }) async {
    // ⚠️ The directory is made **before** the row is inserted, and the order is
    // the whole point. It used to run last, after the insert and after the
    // cleanup call was scheduled, so anything that went wrong in `create()`
    // left a project row and a scheduled future call behind — a broken project
    // in everybody's list, and `deleteProject` then failing on the folder that
    // was never there.
    //
    // Failing here now leaves nothing at all. Failing *after* here leaves an
    // empty directory, which nothing lists and the next create ignores.
    //
    // `recursive: true` because the non-recursive form throws
    // PathNotFoundException when `projectDir` itself is absent — which is the
    // ordinary state of a fresh install that has not had a project yet.
    final folderName = Uuid().v7();
    await Directory(
      "${settings.projectDir}/$folderName",
    ).create(recursive: true);

    final now = DateTime.now().toUtc();
    var projectRow = Project(
      name: name,
      created: now,
      // What the tile shows as "Deleted on". The cleanup call scheduled below
      // is what actually deletes it, and reads this when it fires. On a public
      // instance it is also what decides *whether* it goes: a signed-in user's
      // project gets none and is kept.
      expires: newProjectExpires(who, settings)
          ? endOfDay(now.add(demoRetention(settings)))
          : null,
      description: description,
      folderName: folderName,
      options: optionsId,
      genome: genome,
      snp: snp,
      genes: genes,
      emailNotification: emailNotification,
      // Null while single sign-on is off, which is what keeps every project on a
      // no-auth install unowned and therefore shared. Stamping is done here
      // rather than in the endpoint because it populates data; the *checks* live
      // at the endpoint boundary, where unauthenticated future calls cannot trip
      // over them.
      owner: await authz.ownerForNewProject(session),
      // Stamped only when the creator is in exactly one group, because then
      // there is nothing to choose. Somebody in several gets null and picks on
      // the tile — guessing one of them and calling it the project's would be
      // an arbitrary decision presented as a fact, and it widens who can see
      // the project, so getting it wrong is not free.
      department: who.departments.singleOrNull,
      trackToken: Uuid().v7(),
    );
    var project = await Project.db.insertRow(session, projectRow);

    // Scheduled whether or not demo mode is on, because the flag is read again
    // when the call fires — so switching demo mode on later still sweeps
    // projects created before it.
    await session.serverpod.futureCalls
        .callWithDelay(demoRetention(settings), identifier: project.folderName)
        .demoModeCleanup
        .run(project);
    session.log("Project created with ID: ${project.id}", level: LogLevel.info);
    return project;
  }

  /// Refuses a genome that does not exist.
  Future<void> _requireGenome(Session session, int genomeId) async {
    if (await Genome.db.findById(session, genomeId) == null) {
      session.log("Genome not found with ID: $genomeId", level: LogLevel.error);
      throw FlumipFileNotFoundException(
        message: 'This genome no longer exists.',
      );
    }
  }

  /// Refuses an SNP set that a project on [genomeId] cannot use.
  ///
  /// Three checks, each possible because an SNP knows which genome it belongs
  /// to and whether its bytes have arrived:
  ///
  /// - **The builds must match.** VCF coordinates are build-specific, so an hg38
  ///   file used against hs1 does not fail — it quietly designs the wrong MIPs.
  /// - **The caller must be able to see it.** Without this, guessing an id would
  ///   attach somebody else's private upload, and its contents could then be read
  ///   back indirectly out of the design output.
  /// - **It must be ready.** A failed or half-downloaded import has no usable VCF.
  Future<void> _requireUsableSnp(
    Session session,
    int snpId,
    int? genomeId,
  ) async {
    var snp = await Snp.db.findById(session, snpId);
    if (snp == null) {
      session.log("Snp not found with ID: $snpId", level: LogLevel.error);
      throw FlumipFileNotFoundException(
        message: 'This SNP set no longer exists.',
      );
    }
    await authz.requireSnpAccess(session, snp);

    if (snp.genome != null && snp.genome != genomeId) {
      session.log(
        "Refused SNP $snpId: it is for genome ${snp.genome}, the project "
        "uses $genomeId",
        level: LogLevel.error,
      );
      throw ArgumentException(
        message: 'This SNP set is for a different genome build.',
      );
    }

    if (snp.status != SnpImportStatus.ready) {
      session.log(
        "Refused SNP $snpId: status is ${snp.status.name}",
        level: LogLevel.error,
      );
      throw ArgumentException(message: 'This SNP set is not ready to use yet.');
    }
  }

  /// [genes] as a project stores them: trimmed, upper-cased, repeats dropped.
  ///
  /// \throws [ArgumentException] if any gene is empty or contains invalid
  /// characters.
  List<String> _normaliseGenes(Session session, List<String> genes) {
    final normalised = <String>[];
    for (var gene in genes) {
      final typed = gene.trim();
      if (typed.isEmpty) {
        session.log("Supplied gene is empty", level: LogLevel.error);
        throw ArgumentException(message: 'Enter a gene symbol.');
      }
      if (!geneSymbol.hasMatch(typed)) {
        session.log(
          "Gene name contains invalid characters",
          level: LogLevel.error,
        );
        throw ArgumentException(
          message:
              'A gene symbol can only contain letters and numbers, so '
              '"$typed" cannot be one.',
        );
      }
      final upper = typed.toUpperCase();
      // Quietly dropped rather than refused: a list is pasted in one go, and
      // failing the whole write over a repeat would make the caller diff it
      // by hand.
      if (!normalised.contains(upper)) normalised.add(upper);
    }
    return normalised;
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
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }

    // Stop the run before the row goes, while the pid is still meaningful.
    // Best-effort: a process that has already exited must not stop a deletion.
    // terminateMipgenRun, not terminateProcess: the stored pid may have been
    // handed to another process since, and that one must not be killed.
    if (project.active && project.pid != null && project.pid! > 0) {
      try {
        await processService.terminateMipgenRun(session, project);
      } catch (e) {
        session.log(
          'Could not terminate process ${project.pid} for project $id; '
          'deleting anyway.',
          level: LogLevel.warning,
          exception: e,
        );
      }
    }

    await Project.db.deleteRow(session, project);
    await ProjectOptions.db.deleteWhere(
      session,
      where: (t) => t.id.equals(project.options),
    );

    // ⚠️ Everything past this point is cleanup, and **must not throw**. The row
    // is already gone, so the project *is* deleted; a failure here that
    // propagated would report a deletion that plainly happened as an error, and
    // the client would leave the row on screen rather than refreshing it away.
    //
    // The concrete case: `Directory.delete` throws `PathNotFoundException` for a
    // path that is not there, and a project can legitimately have no directory.
    // `createProject` inserts the row *before* creating the folder, with a
    // non-recursive `create()` — so if `projectDir` itself does not exist, the
    // row is committed and the directory never appears. The same state follows
    // from `projectDir` being repointed, or the folder being cleared out by
    // hand. Any of those made deleting the project report a failure while
    // having entirely succeeded.
    final folderName = project.folderName;
    if (folderName != null && folderName.isNotEmpty) {
      final settings = await SettingsService().getSettings(session);
      final directory = Directory('${settings.projectDir}/$folderName');
      try {
        // `recursive: true` still throws when the path is absent, so ask first.
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      } catch (e) {
        // Leaks a directory, which is visible and recoverable. Refusing the
        // deletion is neither.
        session.log(
          'Deleted project $id but could not remove ${directory.path}.',
          level: LogLevel.warning,
          exception: e,
        );
      }

      try {
        await session.serverpod.futureCalls.cancel(folderName);
      } catch (e) {
        session.log(
          'Deleted project $id but could not cancel its future calls.',
          level: LogLevel.warning,
          exception: e,
        );
      }
    }

    // A running project frees a slot for the queue. Never throws.
    if (project.active) await sl<MipgenService>().startNextQueued(session);

    session.log("Project deleted with ID: $id", level: LogLevel.info);
  }

  /// Adds a gene to a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param gene The gene to add.
  /// \throws [FileNotFoundException] if the project is not found.
  /// \throws [Exception] if the gene already exists in the project.
  /// \throws [ArgumentException] if the gene is empty or contains invalid characters.
  Future<void> addGeneToProject(Session session, int id, String gene) async {
    session.log("Adding gene to project with ID: $id", level: LogLevel.info);
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }
    // ⚠️ Normalised *before* the duplicate check, which is the whole bug this
    // replaced: the check read the string as typed while the list stores it
    // upper-cased, so `contains('myh11')` never matched the `MYH11` already
    // there. Typing a gene in lower case added it again, every time — a project
    // in the wild had the same gene three times over, and the design would have
    // been built from a list with it repeated.
    final typed = gene.trim();
    final normalised = typed.toUpperCase();

    if (normalised.isEmpty) {
      session.log("Supplied gene is empty", level: LogLevel.error);
      throw ArgumentException(message: 'Enter a gene symbol.');
    }
    if (!geneSymbol.hasMatch(normalised)) {
      session.log(
        "Gene name contains invalid characters",
        level: LogLevel.error,
      );
      throw ArgumentException(
        message:
            'A gene symbol can only contain letters and numbers, so "$typed" '
            'cannot be one.',
      );
    }
    if (project.genes?.contains(normalised) ?? false) {
      session.log(
        "Gene already exists in project with ID: $id",
        level: LogLevel.error,
      );
      throw ArgumentException(
        message: '$normalised is already on this project.',
      );
    }

    project.genes ??= [];
    project.genes!.add(normalised);
    await Project.db.updateRow(session, project);
    session.log("Gene added to project with ID: $id", level: LogLevel.info);
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
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    } else {
      if (project.genes == null) {
        session.log("Project does not have any genes", level: LogLevel.error);
        // ⚠️ A typed exception, not a bare `Exception`. `describeError` has no
        // case for the latter, so it reached the user as
        // "Exception: Project does not have any genes" — the class name
        // included.
        throw FlumipFileNotFoundException(
          message: 'This gene is not on this project.',
        );
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
  /// \throws [ArgumentException] if any gene is empty or contains invalid characters.
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
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    } else {
      // Same normalisation as [addGeneToProject], for the same reason. This
      // replaces the whole list rather than appending, so without it a bulk
      // write could seed mixed case that the single-gene duplicate check would
      // then never catch.
      final normalised = _normaliseGenes(session, genes);
      project.genes = normalised;
      await Project.db.updateRow(session, project);
      session.log(
        "Multiple genes added to project with ID: $id",
        level: LogLevel.info,
      );
    }
  }

  /// Pushes a project's automatic deletion back by one retention window, up to
  /// the end of the day `Settings.maxProjectLifetimeDays` after it was created.
  ///
  /// ⚠️ **One window from the current deadline, not from now.** It used to be
  /// "now plus the window", which on a project created this week is the date it
  /// already had — the button did nothing visible until most of the window had
  /// passed. Each press now adds the window again, up to the cap.
  ///
  /// Returns the project unchanged once it is at that limit — the app disables
  /// the button there, and a second click arriving late is not an error. The
  /// cleanup call needs no rescheduling: when it fires at the old time it finds
  /// the deadline has moved and puts itself back for the rest.
  ///
  /// The caller is responsible for the access check.
  ///
  /// \throws [ArgumentException] if this project is not deleted
  ///   automatically — nothing on this server is, or it belongs to a signed-in
  ///   user on a public instance.
  Future<Project> extendProject(Session session, int id) async {
    final project = await getProject(session, id);
    final settings = await SettingsService().getSettings(session);
    if (project.keptIndefinitely) return project;
    if (!projectExpires(project, settings)) {
      throw ArgumentException(
        message:
            'This project is not deleted automatically, so there is nothing '
            'to extend.',
      );
    }

    final deadline = deletionDeadline(project, settings);
    final cap = endOfDay(
      project.created.toUtc().add(maxProjectLifetime(settings)),
    );
    var target = endOfDay(deadline.add(demoRetention(settings)));
    if (target.isAfter(cap)) target = cap;
    if (!target.isAfter(deadline)) return project;

    project.expires = target;
    final updated = await Project.db.updateRow(session, project);
    session.log(
      "Project $id will now be deleted on ${target.toIso8601String()}",
      level: LogLevel.info,
    );
    return updated;
  }

  /// Exempts a project from automatic deletion, or puts it back under it.
  ///
  /// Turning it back on gives the project a **fresh** window from today rather
  /// than its old deadline, which has usually passed by then and would delete
  /// it on the spot. The cleanup call is replaced, not just left to run: a kept
  /// project's call stops rescheduling itself when it fires, so there may be
  /// none left to find the new deadline.
  ///
  /// A signed-in user's project on a public instance has no deadline to
  /// restart, and clearing the flag leaves it kept; see [projectExpires].
  ///
  /// The caller is responsible for the check — administrators only.
  Future<Project> setKeptIndefinitely(
    Session session,
    int id,
    bool kept,
  ) async {
    final project = await getProject(session, id);
    final settings = await SettingsService().getSettings(session);
    project.keptIndefinitely = kept;
    if (!kept && projectExpires(project, settings)) {
      project.expires = endOfDay(
        DateTime.now().toUtc().add(demoRetention(settings)),
      );
    }
    final updated = await Project.db.updateRow(session, project);

    if (kept) {
      final folderName = project.folderName;
      if (folderName != null && folderName.isNotEmpty) {
        await session.serverpod.futureCalls.cancel(folderName);
      }
    } else {
      await _rescheduleCleanup(session, updated, settings);
    }
    session.log(
      kept
          ? "Project $id is now kept indefinitely"
          : "Project $id is subject to automatic deletion again",
      level: LogLevel.info,
    );
    return updated;
  }

  /// The token for this project's share link, `<site>/#/p/<token>`, minting one
  /// on first request.
  ///
  /// Stored as it is, unlike the session cookie, because the owner has to be
  /// able to copy the same link again tomorrow. What limits the damage of a
  /// database leak is the same thing that limits a leaked link:
  /// [resetShareToken].
  ///
  /// The caller is responsible for the access check.
  Future<String> ensureShareToken(Session session, int id) async {
    final project = await getProject(session, id);
    final existing = project.shareToken;
    if (existing != null && existing.isNotEmpty) return existing;
    return _mintShareToken(session, project);
  }

  /// Withdraws the project's share link: mints a new token, so the old link
  /// stops working, **and** removes every grant redeemed from it.
  ///
  /// Both halves are needed. A new token alone stops the link being used again,
  /// but everybody who had already opened it would keep the project in their
  /// list — which is exactly who a leaked link let in.
  ///
  /// The caller is responsible for the access check.
  Future<String> resetShareToken(Session session, int id) async {
    final project = await getProject(session, id);
    await ProjectGrant.db.deleteWhere(
      session,
      where: (t) => t.projectId.equals(id),
    );
    return _mintShareToken(session, project);
  }

  Future<String> _mintShareToken(Session session, Project project) async {
    final token = AuthTokens.newToken();
    project.shareToken = token;
    await Project.db.updateRow(session, project);
    session.log(
      "Minted a share link for project ID: ${project.id}",
      level: LogLevel.info,
    );
    return token;
  }

  /// Opens the project a share link points at, and gives [userId] lasting
  /// access to it.
  ///
  /// [userId] is null on an install with no identities, where every project is
  /// everybody's already; the project is simply returned.
  ///
  /// An unknown token answers with the same not-found error as a deleted
  /// project, so the endpoint cannot be used to tell a withdrawn link from one
  /// that never existed.
  Future<Project> redeemShareToken(
    Session session,
    String token,
    int? userId,
  ) async {
    final project = token.isEmpty
        ? null
        : await Project.db.findFirstRow(
            session,
            where: (t) => t.shareToken.equals(token),
          );
    if (project == null) {
      throw FlumipFileNotFoundException(
        message:
            'This link does not lead to a project any more. It may have been '
            'withdrawn, or the project deleted.',
      );
    }

    if (userId != null && project.owner != userId) {
      final existing = await ProjectGrant.db.findFirstRow(
        session,
        where: (t) => t.projectId.equals(project.id!) & t.userId.equals(userId),
      );
      if (existing == null) {
        await ProjectGrant.db.insertRow(
          session,
          ProjectGrant(projectId: project.id!, userId: userId),
        );
        session.log(
          "User $userId opened project ${project.id} from its share link",
          level: LogLevel.info,
        );
      }
    }
    return project;
  }

  /// Refuses a guest who already has as many projects as one visitor may.
  ///
  /// Guests only: administrators and people who signed in are not counted, and
  /// a quota of zero or less means no limit. Counts what the guest owns, not
  /// what they reached through a share link — those are somebody else's.
  Future<void> _requireGuestQuota(
    Session session,
    Principal who,
    Settings settings,
  ) async {
    final userId = who.userId;
    final limit = settings.guestMaxProjects;
    if (!who.isGuest || userId == null || limit <= 0) return;

    final owned = await Project.db.count(
      session,
      where: (t) => t.owner.equals(userId),
    );
    if (owned < limit) return;

    session.log(
      "Refused a new project for guest $userId: $owned of $limit",
      level: LogLevel.warning,
    );
    throw ArgumentException(
      message:
          'You already have $owned projects, the most this public server keeps '
          'for one visitor. Delete one to make room for a new one.',
    );
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
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
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
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }
    await _requireGenome(session, geneId);
    project.genome = geneId;
    await Project.db.updateRow(session, project);
  }

  /// Sets the SNP for a project, or clears it when [snpId] is null.
  ///
  /// The set has to be one this project can use: visible to the caller, for the
  /// project's genome build, and ready. See [_requireUsableSnp], which
  /// [createConfiguredProject] shares.
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
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }

    if (snpId == null) {
      project.snp = null;
      await Project.db.updateRow(session, project);
      return;
    }

    await _requireUsableSnp(session, snpId, project.genome);

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
  /// On a public instance the new owner also decides whether the project is
  /// deleted (see [projectExpires]): handing it to a signed-in user keeps it,
  /// handing it to a guest starts a fresh window if it had none. Handing it to
  /// nobody leaves that as it was, since there is nobody to decide by.
  ///
  /// No access check: reassignment is administrative and is gated at the
  /// endpoint, like every other rule in this codebase. Guarding here would also
  /// stop the unauthenticated future calls that legitimately write projects.
  Future<void> setOwner(Session session, int id, int? ownerId) async {
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }

    FlumipUser? user;
    if (ownerId != null) {
      user = await FlumipUser.db.findById(session, ownerId);
      if (user == null) {
        session.log("User not found with ID: $ownerId", level: LogLevel.error);
        throw FlumipFileNotFoundException(
          message: 'This user no longer exists.',
        );
      }
    }

    project.owner = ownerId;
    Settings? restarted;
    if (authz.isPublic && user != null) {
      if (user.issuer != AuthService.guestIssuer) {
        project.expires = null;
      } else if (project.expires == null) {
        restarted = await SettingsService().getSettings(session);
        project.expires = endOfDay(
          DateTime.now().toUtc().add(demoRetention(restarted)),
        );
      }
    }
    final updated = await Project.db.updateRow(session, project);
    // A signed-in user's project stopped rescheduling its cleanup call the
    // last time one fired, so there may be none left to find the new date.
    if (restarted != null && !updated.keptIndefinitely) {
      await _rescheduleCleanup(session, updated, restarted);
    }
  }

  /// Replaces [project]'s cleanup call with one due at its deadline.
  Future<void> _rescheduleCleanup(
    Session session,
    Project project,
    Settings settings,
  ) async {
    final folderName = project.folderName;
    if (folderName == null || folderName.isEmpty) return;
    await session.serverpod.futureCalls.cancel(folderName);
    await session.serverpod.futureCalls
        .callWithDelay(
          deletionDeadline(
            project,
            settings,
          ).difference(DateTime.now().toUtc()),
          identifier: folderName,
        )
        .demoModeCleanup
        .run(project);
  }

  /// Moves a project into [department], or out of every department when null.
  ///
  /// ⚠️ **Refuses a department the caller is not in**, unless they are an
  /// administrator. Without that, setting a department would be a way to hand
  /// your own project to a group you have nothing to do with — and since a
  /// department only ever widens access, that is a way to share a project with
  /// people who were never meant to see it.
  ///
  /// An administrator may set any department, because they can see every
  /// project anyway and are the ones who tidy up after a group is renamed.
  Future<void> setDepartment(
    Session session,
    int id,
    String? department,
  ) async {
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }

    final wanted = department?.trim();
    if (wanted != null && wanted.isNotEmpty) {
      final who = await authz.principal(session);
      if (!who.isAdmin && !who.departments.contains(wanted)) {
        session.log(
          'Refused to move project $id into "$wanted" for $who',
          level: LogLevel.warning,
        );
        throw ProjectAccessDeniedException(
          message:
              'You are not in "$wanted", so you cannot move a project into it.',
        );
      }
    }

    project.department = (wanted == null || wanted.isEmpty) ? null : wanted;
    await Project.db.updateRow(session, project);
  }

  /// The departments the caller may put a project into, sorted.
  ///
  /// Their own groups; an administrator also gets every department already in
  /// use, so they can move a project out of a group that has been renamed away
  /// without joining it first.
  Future<List<String>> assignableDepartments(Session session) async {
    final who = await authz.principal(session);
    final departments = <String>{...who.departments};

    if (who.isAdmin) {
      final projects = await Project.db.find(session);
      departments.addAll(
        projects
            .map((p) => p.department)
            .whereType<String>()
            .where((d) => d.isNotEmpty),
      );
    }

    final sorted = departments.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  /// Every user a project can be handed to, oldest account first.
  ///
  /// Only ever reached through an admin-gated endpoint — this is the one place
  /// the user list becomes visible to a client at all.
  Future<List<FlumipUser>> assignableOwners(Session session) {
    return FlumipUser.db.find(session, orderBy: (t) => t.id);
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
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }
    project.emailNotification = enabled;
    await Project.db.updateRow(session, project);
  }
}
