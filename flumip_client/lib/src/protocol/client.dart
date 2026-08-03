/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:flumip_client/src/protocol/auth_config_dto.dart' as _i3;
import 'package:flumip_client/src/protocol/auth_user_dto.dart' as _i4;
import 'package:flumip_client/src/protocol/genome.dart' as _i5;
import 'package:flumip_client/src/protocol/snp.dart' as _i6;
import 'package:flumip_client/src/protocol/project_options.dart' as _i7;
import 'package:flumip_client/src/protocol/project.dart' as _i8;
import 'package:flumip_client/src/protocol/settings.dart' as _i9;
import 'package:flumip_client/src/protocol/auth_admin_status_dto.dart' as _i10;
import 'protocol.dart' as _i11;

/// What the app needs in order to decide whether to show a sign-in screen.
///
/// Plain [Endpoint], never a [FlumipEndpoint]: the app calls [config] before it
/// has any credential at all, so requiring one would be circular.
/// {@category Endpoint}
class EndpointAuth extends _i1.EndpointRef {
  EndpointAuth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auth';

  /// Whether this server wants a sign-in, and what to label the button.
  ///
  /// Answered unauthenticated on purpose. It leaks only whether SSO is on and a
  /// label an administrator chose — both of which are visible from the sign-in
  /// page anyway.
  _i2.Future<_i3.AuthConfigDto> config() =>
      caller.callServerEndpoint<_i3.AuthConfigDto>(
        'auth',
        'config',
        {},
      );

  /// The signed-in user, or null when this request carries no valid session.
  _i2.Future<_i4.AuthUserDto?> me() =>
      caller.callServerEndpoint<_i4.AuthUserDto?>(
        'auth',
        'me',
        {},
      );

  /// Ends this browser session everywhere.
  ///
  /// Revokes the [AuthSession] named by the token's `authId`, which cascades to
  /// every bearer minted from it — so other tabs lose access too, which is what
  /// signing out should mean. The cookie itself is cleared by `/auth/logout`,
  /// since only the web server can set headers on the app's own origin.
  _i2.Future<void> logout() => caller.callServerEndpoint<void>(
    'auth',
    'logout',
    {},
  );
}

/// Endpoint for handling file-related operations.
/// {@category Endpoint}
class EndpointFile extends EndpointFlumip {
  EndpointFile(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'file';

  /// Deletes byproduct files for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  _i2.Future<void> deleteByProducts(int projectID) =>
      caller.callServerEndpoint<void>(
        'file',
        'deleteByProducts',
        {'projectID': projectID},
      );

  /// Shows the SNP MIPs result for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the SNP MIPs result.
  _i2.Future<List<String>> showSnpMipsResult(int projectID) =>
      caller.callServerEndpoint<List<String>>(
        'file',
        'showSnpMipsResult',
        {'projectID': projectID},
      );

  /// Shows the MIPs result for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the MIPs result.
  _i2.Future<List<String>> showMipsResult(int projectID) =>
      caller.callServerEndpoint<List<String>>(
        'file',
        'showMipsResult',
        {'projectID': projectID},
      );

  /// Shows the MIPs progress for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the MIPs progress.
  _i2.Future<List<String>> showMipsProgress(int projectID) =>
      caller.callServerEndpoint<List<String>>(
        'file',
        'showMipsProgress',
        {'projectID': projectID},
      );

  _i2.Future<List<String>> showUSCSTrack(int projectID) =>
      caller.callServerEndpoint<List<String>>(
        'file',
        'showUSCSTrack',
        {'projectID': projectID},
      );

  /// The token for this project's public UCSC track URL.
  ///
  /// The app builds `<siteUrl>/ucsc_track/<token>` from this and hands that URL
  /// to genome.ucsc.edu. It used to build the URL from the project id, which made
  /// every track world-readable and enumerable — see [UCSCTrackRoute] for why the
  /// route itself cannot require a session.
  ///
  /// This is the access check that the public route cannot do: the token is only
  /// ever released to somebody allowed to open the project.
  _i2.Future<String> getUcscTrackToken(int projectID) =>
      caller.callServerEndpoint<String>(
        'file',
        'getUcscTrackToken',
        {'projectID': projectID},
      );

  /// Refuses unless the caller is allowed to touch this project.
  ///
  /// **Every endpoint method that takes a project id must start with this.**
  ///
  /// Adds [ProjectAccessDeniedException] and changes nothing else: an unknown id passes
  /// straight through so the operation still reports the not-found error it
  /// always reported.
  ///
  /// The check lives here, at the request boundary, rather than inside
  /// `ProjectService` — which would look like the tidier place — because the
  /// services are also called by things that have no user at all. `DemoModeCleanup`
  /// and the mipgen progress future calls run on unauthenticated sessions and go
  /// through `getProject`, `updateProject` and `deleteProject`; enforcing down
  /// there would have stopped demo-mode cleanup the moment a project had an
  /// owner, and `DemoModeCleanup` catches the failure and logs "Project not
  /// found", so it would have gone on reporting success while quietly doing
  /// nothing.
  ///
  @override
  _i2.Future<void> requireProject(int projectId) =>
      caller.callServerEndpoint<void>(
        'file',
        'requireProject',
        {'projectId': projectId},
      );

  /// Checks that the caller may touch the project owning these options.
  @override
  _i2.Future<void> requireProjectOptions(int optionsId) =>
      caller.callServerEndpoint<void>(
        'file',
        'requireProjectOptions',
        {'optionsId': optionsId},
      );
}

/// Base class for the endpoints that require a signed-in user when — and only
/// when — single sign-on is switched on and working.
///
/// [Endpoint.requireLogin] is a synchronous getter that Serverpod reads on every
/// call, so this has to be a field read rather than a database query; see
/// [AuthRuntime] for how the answer gets there and stays current.
///
/// Notably **not** extended by `SettingsEndpoint`: the switch that turns
/// authentication off must never sit behind the thing it switches off, or a
/// misconfiguration becomes a lockout with no way back. That endpoint has its
/// own gate, satisfied by either the settings password or an admin session.
/// {@category Endpoint}
abstract class EndpointFlumip extends _i1.EndpointRef {
  EndpointFlumip(_i1.EndpointCaller caller) : super(caller);

  /// Refuses unless the caller is allowed to touch this project.
  ///
  /// **Every endpoint method that takes a project id must start with this.**
  ///
  /// Adds [ProjectAccessDeniedException] and changes nothing else: an unknown id passes
  /// straight through so the operation still reports the not-found error it
  /// always reported.
  ///
  /// The check lives here, at the request boundary, rather than inside
  /// `ProjectService` — which would look like the tidier place — because the
  /// services are also called by things that have no user at all. `DemoModeCleanup`
  /// and the mipgen progress future calls run on unauthenticated sessions and go
  /// through `getProject`, `updateProject` and `deleteProject`; enforcing down
  /// there would have stopped demo-mode cleanup the moment a project had an
  /// owner, and `DemoModeCleanup` catches the failure and logs "Project not
  /// found", so it would have gone on reporting success while quietly doing
  /// nothing.
  ///
  _i2.Future<void> requireProject(int projectId);

  /// Checks that the caller may touch the project owning these options.
  _i2.Future<void> requireProjectOptions(int optionsId);
}

/// Endpoint for genome-related operations.
/// {@category Endpoint}
class EndpointGenome extends EndpointFlumip {
  EndpointGenome(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'genome';

  /// Retrieves a genome by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to retrieve.
  /// \returns The genome with the specified ID.
  /// \throws Exception if an error occurs during retrieval.
  _i2.Future<_i5.Genome> getGenome(int id) =>
      caller.callServerEndpoint<_i5.Genome>(
        'genome',
        'getGenome',
        {'id': id},
      );

  /// Retrieves all genomes.
  ///
  /// \param session The current session.
  /// \returns A list of all genomes.
  /// \throws Exception if an error occurs during retrieval.
  _i2.Future<List<_i5.Genome>> getAllGenomes() =>
      caller.callServerEndpoint<List<_i5.Genome>>(
        'genome',
        'getAllGenomes',
        {},
      );

  /// Updates a genome.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to update.
  /// \param genome The updated genome data.
  /// \throws Exception if an error occurs during the update.
  _i2.Future<void> updateGenome(
    int id,
    _i5.Genome genome,
  ) => caller.callServerEndpoint<void>(
    'genome',
    'updateGenome',
    {
      'id': id,
      'genome': genome,
    },
  );

  /// Collects genomes from the genome directory.
  ///
  /// \param session The current session.
  /// \throws Exception if an error occurs during collection.
  _i2.Future<void> collectGenomes() => caller.callServerEndpoint<void>(
    'genome',
    'collectGenomes',
    {},
  );

  /// Retrieves an SNP by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the SNP to retrieve.
  /// \returns The SNP with the specified ID.
  /// \throws Exception if an error occurs during retrieval.
  _i2.Future<_i6.Snp> getSnp(int id) => caller.callServerEndpoint<_i6.Snp>(
    'genome',
    'getSnp',
    {'id': id},
  );

  /// Retrieves all SNPs for a specific genome.
  ///
  /// \param session The current session.
  /// \param genomeId The ID of the genome to retrieve SNPs for.
  /// \returns A list of all SNPs for the specified genome.
  /// \throws Exception if an error occurs during retrieval.
  _i2.Future<List<_i6.Snp>> getAllSnpForGenome(int genomeId) =>
      caller.callServerEndpoint<List<_i6.Snp>>(
        'genome',
        'getAllSnpForGenome',
        {'genomeId': genomeId},
      );

  /// Updates an SNP.
  ///
  /// \param session The current session.
  /// \param id The ID of the SNP to update.
  /// \param snp The updated SNP data.
  /// \throws Exception if an error occurs during the update.
  _i2.Future<void> updateSnp(
    int id,
    _i6.Snp snp,
  ) => caller.callServerEndpoint<void>(
    'genome',
    'updateSnp',
    {
      'id': id,
      'snp': snp,
    },
  );

  /// Retrieves all genome categories.
  ///
  /// \param session The current session.
  /// \returns A list of all genome categories.
  /// \throws Exception if an error occurs during retrieval.
  _i2.Future<List<String>> getCategories() =>
      caller.callServerEndpoint<List<String>>(
        'genome',
        'getCategories',
        {},
      );

  /// Retrieves genomes by category.
  ///
  /// \param session The current session.
  /// \param category The category to filter genomes by.
  /// \returns A list of genomes in the specified category.
  /// \throws Exception if an error occurs during retrieval.
  _i2.Future<List<_i5.Genome>> getGenomeByCategory(String category) =>
      caller.callServerEndpoint<List<_i5.Genome>>(
        'genome',
        'getGenomeByCategory',
        {'category': category},
      );

  _i2.Future<void> indexFasta(int id) => caller.callServerEndpoint<void>(
    'genome',
    'indexFasta',
    {'id': id},
  );

  _i2.Future<void> deleteFastaIndex(int id) => caller.callServerEndpoint<void>(
    'genome',
    'deleteFastaIndex',
    {'id': id},
  );

  /// Refuses unless the caller is allowed to touch this project.
  ///
  /// **Every endpoint method that takes a project id must start with this.**
  ///
  /// Adds [ProjectAccessDeniedException] and changes nothing else: an unknown id passes
  /// straight through so the operation still reports the not-found error it
  /// always reported.
  ///
  /// The check lives here, at the request boundary, rather than inside
  /// `ProjectService` — which would look like the tidier place — because the
  /// services are also called by things that have no user at all. `DemoModeCleanup`
  /// and the mipgen progress future calls run on unauthenticated sessions and go
  /// through `getProject`, `updateProject` and `deleteProject`; enforcing down
  /// there would have stopped demo-mode cleanup the moment a project had an
  /// owner, and `DemoModeCleanup` catches the failure and logs "Project not
  /// found", so it would have gone on reporting success while quietly doing
  /// nothing.
  ///
  @override
  _i2.Future<void> requireProject(int projectId) =>
      caller.callServerEndpoint<void>(
        'genome',
        'requireProject',
        {'projectId': projectId},
      );

  /// Checks that the caller may touch the project owning these options.
  @override
  _i2.Future<void> requireProjectOptions(int optionsId) =>
      caller.callServerEndpoint<void>(
        'genome',
        'requireProjectOptions',
        {'optionsId': optionsId},
      );
}

/// Endpoint for handling MIP generation-related operations.
/// {@category Endpoint}
class EndpointMipgen extends EndpointFlumip {
  EndpointMipgen(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'mipgen';

  /// Creates a BED file for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  _i2.Future<void> createBedFile(int projectID) =>
      caller.callServerEndpoint<void>(
        'mipgen',
        'createBedFile',
        {'projectID': projectID},
      );

  /// Generates MIPs for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \param deleteExcessFiles Whether to delete intermediate files after generating MIPs.
  _i2.Future<void> generateMips(
    int projectID,
    bool deleteExcessFiles,
  ) => caller.callServerEndpoint<void>(
    'mipgen',
    'generateMips',
    {
      'projectID': projectID,
      'deleteExcessFiles': deleteExcessFiles,
    },
  );

  /// Refuses unless the caller is allowed to touch this project.
  ///
  /// **Every endpoint method that takes a project id must start with this.**
  ///
  /// Adds [ProjectAccessDeniedException] and changes nothing else: an unknown id passes
  /// straight through so the operation still reports the not-found error it
  /// always reported.
  ///
  /// The check lives here, at the request boundary, rather than inside
  /// `ProjectService` — which would look like the tidier place — because the
  /// services are also called by things that have no user at all. `DemoModeCleanup`
  /// and the mipgen progress future calls run on unauthenticated sessions and go
  /// through `getProject`, `updateProject` and `deleteProject`; enforcing down
  /// there would have stopped demo-mode cleanup the moment a project had an
  /// owner, and `DemoModeCleanup` catches the failure and logs "Project not
  /// found", so it would have gone on reporting success while quietly doing
  /// nothing.
  ///
  @override
  _i2.Future<void> requireProject(int projectId) =>
      caller.callServerEndpoint<void>(
        'mipgen',
        'requireProject',
        {'projectId': projectId},
      );

  /// Checks that the caller may touch the project owning these options.
  @override
  _i2.Future<void> requireProjectOptions(int optionsId) =>
      caller.callServerEndpoint<void>(
        'mipgen',
        'requireProjectOptions',
        {'optionsId': optionsId},
      );
}

/// Endpoint for handling project options-related operations.
/// {@category Endpoint}
class EndpointOptions extends EndpointFlumip {
  EndpointOptions(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'options';

  /// Creates project options.
  ///
  /// \param session The current session.
  /// \returns The created [ProjectOptions] object.
  _i2.Future<_i7.ProjectOptions> createProjectOptions() =>
      caller.callServerEndpoint<_i7.ProjectOptions>(
        'options',
        'createProjectOptions',
        {},
      );

  /// Inserts project options.
  ///
  /// \param session The current session.
  /// \param options The [ProjectOptions] object to insert.
  /// \returns The inserted [ProjectOptions] object.
  _i2.Future<_i7.ProjectOptions> insertProjectOptions(
    _i7.ProjectOptions options,
  ) => caller.callServerEndpoint<_i7.ProjectOptions>(
    'options',
    'insertProjectOptions',
    {'options': options},
  );

  /// Retrieves project options by ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project options to retrieve.
  /// \returns The retrieved [ProjectOptions] object.
  _i2.Future<_i7.ProjectOptions> getProjectOptions(int id) =>
      caller.callServerEndpoint<_i7.ProjectOptions>(
        'options',
        'getProjectOptions',
        {'id': id},
      );

  /// Updates project options.
  ///
  /// \param session The current session.
  /// \param id The ID of the project options to update.
  /// \param options The [ProjectOptions] object to update.
  _i2.Future<void> updateProjectOptions(
    int id,
    _i7.ProjectOptions options,
  ) => caller.callServerEndpoint<void>(
    'options',
    'updateProjectOptions',
    {
      'id': id,
      'options': options,
    },
  );

  /// Deletes project options by ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project options to delete.
  _i2.Future<void> deleteProjectOptions(int id) =>
      caller.callServerEndpoint<void>(
        'options',
        'deleteProjectOptions',
        {'id': id},
      );

  /// Refuses unless the caller is allowed to touch this project.
  ///
  /// **Every endpoint method that takes a project id must start with this.**
  ///
  /// Adds [ProjectAccessDeniedException] and changes nothing else: an unknown id passes
  /// straight through so the operation still reports the not-found error it
  /// always reported.
  ///
  /// The check lives here, at the request boundary, rather than inside
  /// `ProjectService` — which would look like the tidier place — because the
  /// services are also called by things that have no user at all. `DemoModeCleanup`
  /// and the mipgen progress future calls run on unauthenticated sessions and go
  /// through `getProject`, `updateProject` and `deleteProject`; enforcing down
  /// there would have stopped demo-mode cleanup the moment a project had an
  /// owner, and `DemoModeCleanup` catches the failure and logs "Project not
  /// found", so it would have gone on reporting success while quietly doing
  /// nothing.
  ///
  @override
  _i2.Future<void> requireProject(int projectId) =>
      caller.callServerEndpoint<void>(
        'options',
        'requireProject',
        {'projectId': projectId},
      );

  /// Checks that the caller may touch the project owning these options.
  @override
  _i2.Future<void> requireProjectOptions(int optionsId) =>
      caller.callServerEndpoint<void>(
        'options',
        'requireProjectOptions',
        {'optionsId': optionsId},
      );
}

/// Endpoint for handling project-related operations.
/// {@category Endpoint}
class EndpointProject extends EndpointFlumip {
  EndpointProject(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'project';

  /// Creates a new project.
  ///
  /// \param session The current session.
  /// \param name The name of the project.
  /// \param options The options for the project.
  /// \param description An optional description of the project.
  /// \returns The created [Project] object.
  _i2.Future<_i8.Project> createProject(
    String name,
    _i7.ProjectOptions options, [
    String? description,
  ]) => caller.callServerEndpoint<_i8.Project>(
    'project',
    'createProject',
    {
      'name': name,
      'options': options,
      'description': description,
    },
  );

  /// Deletes a project by ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project to delete.
  _i2.Future<void> deleteProject(int id) => caller.callServerEndpoint<void>(
    'project',
    'deleteProject',
    {'id': id},
  );

  /// Retrieves all projects.
  ///
  /// \param session The current session.
  /// \returns A list of [Project] objects.
  _i2.Future<List<_i8.Project>> getProjects() =>
      caller.callServerEndpoint<List<_i8.Project>>(
        'project',
        'getProjects',
        {},
      );

  /// Retrieves a project by ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project to retrieve.
  /// \returns The retrieved [Project] object.
  _i2.Future<_i8.Project> getProject(int id) =>
      caller.callServerEndpoint<_i8.Project>(
        'project',
        'getProject',
        {'id': id},
      );

  /// Adds a gene to a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param gene The gene to add.
  _i2.Future<void> addGeneToProject(
    int id,
    String gene,
  ) => caller.callServerEndpoint<void>(
    'project',
    'addGeneToProject',
    {
      'id': id,
      'gene': gene,
    },
  );

  /// Removes a gene from a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param gene The gene to remove.
  _i2.Future<void> removeGeneFromProject(
    int id,
    String gene,
  ) => caller.callServerEndpoint<void>(
    'project',
    'removeGeneFromProject',
    {
      'id': id,
      'gene': gene,
    },
  );

  /// Adds multiple genes to a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param genes The list of genes to add.
  _i2.Future<void> addGenesToProject(
    int id,
    List<String> genes,
  ) => caller.callServerEndpoint<void>(
    'project',
    'addGenesToProject',
    {
      'id': id,
      'genes': genes,
    },
  );

  /// Sets the genome for a project by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param genomeId The ID of the genome to set.
  _i2.Future<void> setGeneById(
    int id,
    int genomeId,
  ) => caller.callServerEndpoint<void>(
    'project',
    'setGeneById',
    {
      'id': id,
      'genomeId': genomeId,
    },
  );

  /// Turns the finish notification on or off for a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param enabled Whether to email the project's owner when generation ends.
  _i2.Future<void> setEmailNotification(
    int id,
    bool enabled,
  ) => caller.callServerEndpoint<void>(
    'project',
    'setEmailNotification',
    {
      'id': id,
      'enabled': enabled,
    },
  );

  /// Whether an administrator has switched mail on for this install.
  ///
  /// The per-project notification switch is meaningless without it, so the app
  /// asks once and hides the control when this is false. **Advisory only** — the
  /// server decides what is actually sent, on the send path. Deliberately not
  /// part of [SettingsEndpoint]: every method there is admin-gated, and an
  /// ordinary user has to be able to read this to render their own switch.
  ///
  /// \param session The current session.
  _i2.Future<bool> notificationsAvailable() => caller.callServerEndpoint<bool>(
    'project',
    'notificationsAvailable',
    {},
  );

  /// Sets the SNP for a project by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param snpId The ID of the SNP to set.
  _i2.Future<void> setSnpById(
    int id,
    int snpId,
  ) => caller.callServerEndpoint<void>(
    'project',
    'setSnpById',
    {
      'id': id,
      'snpId': snpId,
    },
  );

  /// Refuses unless the caller is allowed to touch this project.
  ///
  /// **Every endpoint method that takes a project id must start with this.**
  ///
  /// Adds [ProjectAccessDeniedException] and changes nothing else: an unknown id passes
  /// straight through so the operation still reports the not-found error it
  /// always reported.
  ///
  /// The check lives here, at the request boundary, rather than inside
  /// `ProjectService` — which would look like the tidier place — because the
  /// services are also called by things that have no user at all. `DemoModeCleanup`
  /// and the mipgen progress future calls run on unauthenticated sessions and go
  /// through `getProject`, `updateProject` and `deleteProject`; enforcing down
  /// there would have stopped demo-mode cleanup the moment a project had an
  /// owner, and `DemoModeCleanup` catches the failure and logs "Project not
  /// found", so it would have gone on reporting success while quietly doing
  /// nothing.
  ///
  @override
  _i2.Future<void> requireProject(int projectId) =>
      caller.callServerEndpoint<void>(
        'project',
        'requireProject',
        {'projectId': projectId},
      );

  /// Checks that the caller may touch the project owning these options.
  @override
  _i2.Future<void> requireProjectOptions(int optionsId) =>
      caller.callServerEndpoint<void>(
        'project',
        'requireProjectOptions',
        {'optionsId': optionsId},
      );
}

/// Endpoint for handling settings-related operations.
///
/// Deliberately **not** a [FlumipEndpoint]: this endpoint is how single sign-on
/// gets switched off, so putting it behind a login would make a misconfiguration
/// unrecoverable from the UI. Every method here gates itself instead, on either
/// the settings password or an authenticated admin session.
/// {@category Endpoint}
class EndpointSettings extends _i1.EndpointRef {
  EndpointSettings(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'settings';

  /// Retrieves the settings.
  ///
  /// \param session The current session.
  /// \param password The settings password, or null to rely on an admin session.
  /// \returns The retrieved [Settings] object.
  _i2.Future<_i9.Settings> getSettings(String? password) =>
      caller.callServerEndpoint<_i9.Settings>(
        'settings',
        'getSettings',
        {'password': password},
      );

  /// Updates the settings.
  ///
  /// Gated like [getSettings]: the settings hold the SMTP credentials and the
  /// settings password itself, so writing them must be authenticated.
  ///
  /// The authentication configuration is re-read afterwards, so switching single
  /// sign-on on or off takes effect immediately rather than on the next refresh
  /// tick.
  ///
  /// \param session The current session.
  /// \param password The settings password, or null to rely on an admin session.
  /// \param settings The [Settings] object to update.
  _i2.Future<void> updateSettings(
    String? password,
    _i9.Settings settings,
  ) => caller.callServerEndpoint<void>(
    'settings',
    'updateSettings',
    {
      'password': password,
      'settings': settings,
    },
  );

  /// Sets the OIDC client secret.
  ///
  /// Separate from [updateSettings] because the secret is write-only: it is a
  /// `serverOnly` field, so it never travels to the browser and cannot be part of
  /// the [Settings] object the settings tab sends back. Passing an empty string
  /// clears it.
  ///
  /// \param session The current session.
  /// \param password The settings password, or null to rely on an admin session.
  /// \param secret The new client secret.
  _i2.Future<void> setOidcClientSecret(
    String? password,
    String secret,
  ) => caller.callServerEndpoint<void>(
    'settings',
    'setOidcClientSecret',
    {
      'password': password,
      'secret': secret,
    },
  );

  /// Everything the settings tab needs to show about the SSO setup that is not
  /// itself a stored setting.
  ///
  /// Runs a live discovery probe, mirroring how [sendTestMail] validates the SMTP
  /// configuration — the point is to fail here, with a readable message, rather
  /// than at someone's first sign-in attempt.
  ///
  /// \param session The current session.
  /// \param password The settings password, or null to rely on an admin session.
  _i2.Future<_i10.AuthAdminStatusDto> getAuthAdminStatus(String? password) =>
      caller.callServerEndpoint<_i10.AuthAdminStatusDto>(
        'settings',
        'getAuthAdminStatus',
        {'password': password},
      );

  /// Sends a test email so the SMTP configuration can be validated.
  ///
  /// \param session The current session.
  /// \param password The settings password, or null to rely on an admin session.
  /// \param to The recipient address.
  _i2.Future<void> sendTestMail(
    String? password,
    String to,
  ) => caller.callServerEndpoint<void>(
    'settings',
    'sendTestMail',
    {
      'password': password,
      'to': to,
    },
  );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i11.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    auth = EndpointAuth(this);
    file = EndpointFile(this);
    genome = EndpointGenome(this);
    mipgen = EndpointMipgen(this);
    options = EndpointOptions(this);
    project = EndpointProject(this);
    settings = EndpointSettings(this);
  }

  late final EndpointAuth auth;

  late final EndpointFile file;

  late final EndpointGenome genome;

  late final EndpointMipgen mipgen;

  late final EndpointOptions options;

  late final EndpointProject project;

  late final EndpointSettings settings;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'auth': auth,
    'file': file,
    'genome': genome,
    'mipgen': mipgen,
    'options': options,
    'project': project,
    'settings': settings,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
