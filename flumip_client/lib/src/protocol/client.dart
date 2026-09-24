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
import 'dart:async' as _ida;
import 'package:flumip_client/src/protocol/auth_admin_status_dto.dart'
    as _ifh830yy;
import 'package:flumip_client/src/protocol/auth_config_dto.dart' as _im9pga5k;
import 'package:flumip_client/src/protocol/auth_user_dto.dart' as _iqovtkew;
import 'package:flumip_client/src/protocol/custom_snp_request_dto.dart'
    as _iqct5zkb;
import 'package:flumip_client/src/protocol/flumip_user_dto.dart' as _i15z9m0g;
import 'package:flumip_client/src/protocol/genome.dart' as _ixuye8o9;
import 'package:flumip_client/src/protocol/project.dart' as _iqi8mkqf;
import 'package:flumip_client/src/protocol/project_file_dto.dart' as _i5l1g0eo;
import 'package:flumip_client/src/protocol/project_options.dart' as _iqoum48a;
import 'package:flumip_client/src/protocol/search_hit_dto.dart' as _i8y6t52d;
import 'package:flumip_client/src/protocol/settings.dart' as _ibile1le;
import 'package:flumip_client/src/protocol/snp.dart' as _iumnx4id;
import 'package:flumip_client/src/protocol/snp_usage_dto.dart' as _idqeum9a;
import 'package:flumip_client/src/protocol/user_settings_dto.dart' as _ikcb9gvb;
import 'package:http/http.dart' as _i85jenna;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'protocol.dart' as _il2as5qe;

/// What the app needs in order to decide whether to show a sign-in screen.
///
/// Plain [Endpoint], never a [FlumipEndpoint]: the app calls [config] before it
/// has any credential at all, so requiring one would be circular.
/// {@category Endpoint}
class EndpointAuth extends _isc.EndpointRef {
  EndpointAuth(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auth';

  /// Whether this server wants a sign-in, and what to label the button.
  ///
  /// Answered unauthenticated on purpose. It leaks only whether SSO is on and a
  /// label an administrator chose — both of which are visible from the sign-in
  /// page anyway.
  _ida.Future<_im9pga5k.AuthConfigDto> config() =>
      caller.callServerEndpoint<_im9pga5k.AuthConfigDto>('auth', 'config', {});

  /// The signed-in user, or null when this request carries no valid session.
  _ida.Future<_iqovtkew.AuthUserDto?> me() =>
      caller.callServerEndpoint<_iqovtkew.AuthUserDto?>('auth', 'me', {});

  /// Ends this browser session everywhere.
  ///
  /// Revokes the [AuthSession] named by the token's `authId`, which cascades to
  /// every bearer minted from it — so other tabs lose access too, which is what
  /// signing out should mean. The cookie itself is cleared by `/auth/logout`,
  /// since only the web server can set headers on the app's own origin.
  _ida.Future<void> logout() =>
      caller.callServerEndpoint<void>('auth', 'logout', {});
}

/// Endpoint for handling file-related operations.
/// {@category Endpoint}
class EndpointFile extends EndpointFlumip {
  EndpointFile(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'file';

  /// Deletes byproduct files for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  _ida.Future<void> deleteByProducts(int projectID) =>
      caller.callServerEndpoint<void>('file', 'deleteByProducts', {
        'projectID': projectID,
      });

  /// Shows the SNP MIPs result for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the SNP MIPs result.
  _ida.Future<List<String>> showSnpMipsResult(int projectID) =>
      caller.callServerEndpoint<List<String>>('file', 'showSnpMipsResult', {
        'projectID': projectID,
      });

  /// Shows the MIPs result for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the MIPs result.
  _ida.Future<List<String>> showMipsResult(int projectID) =>
      caller.callServerEndpoint<List<String>>('file', 'showMipsResult', {
        'projectID': projectID,
      });

  /// Shows the MIPs progress for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the MIPs progress.
  _ida.Future<List<String>> showMipsProgress(int projectID) =>
      caller.callServerEndpoint<List<String>>('file', 'showMipsProgress', {
        'projectID': projectID,
      });

  _ida.Future<List<String>> showUSCSTrack(int projectID) =>
      caller.callServerEndpoint<List<String>>('file', 'showUSCSTrack', {
        'projectID': projectID,
      });

  /// The token for this project's public UCSC track URL.
  ///
  /// The app builds `<siteUrl>/ucsc_track/<token>` from this and hands that URL
  /// to genome.ucsc.edu. It used to build the URL from the project id, which made
  /// every track world-readable and enumerable — see [UCSCTrackRoute] for why the
  /// route itself cannot require a session.
  ///
  /// This is the access check that the public route cannot do: the token is only
  /// ever released to somebody allowed to open the project.
  _ida.Future<String> getUcscTrackToken(int projectID) =>
      caller.callServerEndpoint<String>('file', 'getUcscTrackToken', {
        'projectID': projectID,
      });

  /// Lists a project's files, so the app can offer them for download.
  ///
  /// Names and sizes only — the bytes come from the `/download/...` web route,
  /// which streams them. Routing a multi-gigabyte file through a serialised
  /// endpoint response would mean holding it in memory on both sides.
  ///
  /// Empty for a project whose generation never ran; that is not an error.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  _ida.Future<List<_i5l1g0eo.ProjectFileDto>> listProjectFiles(int projectID) =>
      caller.callServerEndpoint<List<_i5l1g0eo.ProjectFileDto>>(
        'file',
        'listProjectFiles',
        {'projectID': projectID},
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
abstract class EndpointFlumip extends _isc.EndpointRef {
  EndpointFlumip(_isc.EndpointCaller caller) : super(caller);
}

/// Endpoint for genome-related operations.
/// {@category Endpoint}
class EndpointGenome extends EndpointFlumip {
  EndpointGenome(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'genome';

  /// Retrieves a genome by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to retrieve.
  /// \returns The genome with the specified ID.
  /// \throws Exception if an error occurs during retrieval.
  _ida.Future<_ixuye8o9.Genome> getGenome(int id) => caller
      .callServerEndpoint<_ixuye8o9.Genome>('genome', 'getGenome', {'id': id});

  /// Retrieves all genomes.
  ///
  /// \param session The current session.
  /// \returns A list of all genomes.
  /// \throws Exception if an error occurs during retrieval.
  _ida.Future<List<_ixuye8o9.Genome>> getAllGenomes() =>
      caller.callServerEndpoint<List<_ixuye8o9.Genome>>(
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
  _ida.Future<void> updateGenome(int id, _ixuye8o9.Genome genome) =>
      caller.callServerEndpoint<void>('genome', 'updateGenome', {
        'id': id,
        'genome': genome,
      });

  /// Collects genomes from the genome directory.
  ///
  /// \param session The current session.
  /// \throws Exception if an error occurs during collection.
  _ida.Future<void> collectGenomes() =>
      caller.callServerEndpoint<void>('genome', 'collectGenomes', {});

  /// Retrieves an SNP by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the SNP to retrieve.
  /// \returns The SNP with the specified ID.
  /// \throws Exception if an error occurs during retrieval.
  _ida.Future<_iumnx4id.Snp> getSnp(int id) =>
      caller.callServerEndpoint<_iumnx4id.Snp>('genome', 'getSnp', {'id': id});

  /// Retrieves all SNPs for a specific genome.
  ///
  /// \param session The current session.
  /// \param genomeId The ID of the genome to retrieve SNPs for.
  /// \returns A list of all SNPs for the specified genome.
  /// \throws Exception if an error occurs during retrieval.
  _ida.Future<List<_iumnx4id.Snp>> getAllSnpForGenome(int genomeId) =>
      caller.callServerEndpoint<List<_iumnx4id.Snp>>(
        'genome',
        'getAllSnpForGenome',
        {'genomeId': genomeId},
      );

  /// Retrieves all genome categories.
  ///
  /// \param session The current session.
  /// \returns A list of all genome categories.
  /// \throws Exception if an error occurs during retrieval.
  _ida.Future<List<String>> getCategories() =>
      caller.callServerEndpoint<List<String>>('genome', 'getCategories', {});

  /// Retrieves genomes by category.
  ///
  /// \param session The current session.
  /// \param category The category to filter genomes by.
  /// \returns A list of genomes in the specified category.
  /// \throws Exception if an error occurs during retrieval.
  _ida.Future<List<_ixuye8o9.Genome>> getGenomeByCategory(String category) =>
      caller.callServerEndpoint<List<_ixuye8o9.Genome>>(
        'genome',
        'getGenomeByCategory',
        {'category': category},
      );

  _ida.Future<void> indexFasta(int id) =>
      caller.callServerEndpoint<void>('genome', 'indexFasta', {'id': id});

  _ida.Future<void> deleteFastaIndex(int id) =>
      caller.callServerEndpoint<void>('genome', 'deleteFastaIndex', {'id': id});
}

/// Endpoint for handling MIP generation-related operations.
/// {@category Endpoint}
class EndpointMipgen extends EndpointFlumip {
  EndpointMipgen(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'mipgen';

  /// Creates a BED file for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  _ida.Future<void> createBedFile(int projectID) =>
      caller.callServerEndpoint<void>('mipgen', 'createBedFile', {
        'projectID': projectID,
      });

  /// Generates MIPs for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \param deleteExcessFiles Whether to delete intermediate files after generating MIPs.
  _ida.Future<void> generateMips(int projectID, bool deleteExcessFiles) =>
      caller.callServerEndpoint<void>('mipgen', 'generateMips', {
        'projectID': projectID,
        'deleteExcessFiles': deleteExcessFiles,
      });
}

/// Endpoint for handling project options-related operations.
/// {@category Endpoint}
class EndpointOptions extends EndpointFlumip {
  EndpointOptions(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'options';

  /// Creates project options.
  ///
  /// \param session The current session.
  /// \returns The created [ProjectOptions] object.
  _ida.Future<_iqoum48a.ProjectOptions> createProjectOptions() =>
      caller.callServerEndpoint<_iqoum48a.ProjectOptions>(
        'options',
        'createProjectOptions',
        {},
      );

  /// Inserts project options.
  ///
  /// \param session The current session.
  /// \param options The [ProjectOptions] object to insert.
  /// \returns The inserted [ProjectOptions] object.
  _ida.Future<_iqoum48a.ProjectOptions> insertProjectOptions(
    _iqoum48a.ProjectOptions options,
  ) => caller.callServerEndpoint<_iqoum48a.ProjectOptions>(
    'options',
    'insertProjectOptions',
    {'options': options},
  );

  /// Retrieves project options by ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project options to retrieve.
  /// \returns The retrieved [ProjectOptions] object.
  _ida.Future<_iqoum48a.ProjectOptions> getProjectOptions(int id) =>
      caller.callServerEndpoint<_iqoum48a.ProjectOptions>(
        'options',
        'getProjectOptions',
        {'id': id},
      );

  /// Updates project options.
  ///
  /// \param session The current session.
  /// \param id The ID of the project options to update.
  /// \param options The [ProjectOptions] object to update.
  _ida.Future<void> updateProjectOptions(
    int id,
    _iqoum48a.ProjectOptions options,
  ) => caller.callServerEndpoint<void>('options', 'updateProjectOptions', {
    'id': id,
    'options': options,
  });

  /// Deletes project options by ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project options to delete.
  _ida.Future<void> deleteProjectOptions(int id) => caller
      .callServerEndpoint<void>('options', 'deleteProjectOptions', {'id': id});
}

/// Endpoint for handling project-related operations.
/// {@category Endpoint}
class EndpointProject extends EndpointFlumip {
  EndpointProject(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'project';

  /// Creates a new project.
  ///
  /// \param session The current session.
  /// \param name The name of the project.
  /// \param options The options for the project.
  /// \param description An optional description of the project.
  /// \returns The created [Project] object.
  _ida.Future<_iqi8mkqf.Project> createProject(
    String name,
    _iqoum48a.ProjectOptions options, [
    String? description,
  ]) => caller.callServerEndpoint<_iqi8mkqf.Project>(
    'project',
    'createProject',
    {'name': name, 'options': options, 'description': description},
  );

  /// Deletes a project by ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project to delete.
  _ida.Future<void> deleteProject(int id) =>
      caller.callServerEndpoint<void>('project', 'deleteProject', {'id': id});

  /// Retrieves all projects.
  ///
  /// \param session The current session.
  /// \returns A list of [Project] objects.
  _ida.Future<List<_iqi8mkqf.Project>> getProjects() =>
      caller.callServerEndpoint<List<_iqi8mkqf.Project>>(
        'project',
        'getProjects',
        {},
      );

  /// Retrieves a project by ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project to retrieve.
  /// \returns The retrieved [Project] object.
  _ida.Future<_iqi8mkqf.Project> getProject(int id) =>
      caller.callServerEndpoint<_iqi8mkqf.Project>('project', 'getProject', {
        'id': id,
      });

  /// Adds a gene to a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param gene The gene to add.
  _ida.Future<void> addGeneToProject(int id, String gene) =>
      caller.callServerEndpoint<void>('project', 'addGeneToProject', {
        'id': id,
        'gene': gene,
      });

  /// Removes a gene from a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param gene The gene to remove.
  _ida.Future<void> removeGeneFromProject(int id, String gene) =>
      caller.callServerEndpoint<void>('project', 'removeGeneFromProject', {
        'id': id,
        'gene': gene,
      });

  /// Adds multiple genes to a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param genes The list of genes to add.
  _ida.Future<void> addGenesToProject(int id, List<String> genes) =>
      caller.callServerEndpoint<void>('project', 'addGenesToProject', {
        'id': id,
        'genes': genes,
      });

  /// Sets the genome for a project by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param genomeId The ID of the genome to set.
  _ida.Future<void> setGeneById(int id, int genomeId) =>
      caller.callServerEndpoint<void>('project', 'setGeneById', {
        'id': id,
        'genomeId': genomeId,
      });

  /// Turns the finish notification on or off for a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param enabled Whether to email the project's owner when generation ends.
  _ida.Future<void> setEmailNotification(int id, bool enabled) =>
      caller.callServerEndpoint<void>('project', 'setEmailNotification', {
        'id': id,
        'enabled': enabled,
      });

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
  _ida.Future<void> setProjectOwner(int id, int? ownerId) =>
      caller.callServerEndpoint<void>('project', 'setProjectOwner', {
        'id': id,
        'ownerId': ownerId,
      });

  /// Every user a project can be handed to.
  ///
  /// **Administrators only.** This is the only endpoint that exposes the user
  /// list, so the gate is the whole of its security: an ordinary user has no
  /// business enumerating everyone with an account.
  ///
  /// \param session The current session.
  _ida.Future<List<_i15z9m0g.FlumipUserDto>> assignableOwners() =>
      caller.callServerEndpoint<List<_i15z9m0g.FlumipUserDto>>(
        'project',
        'assignableOwners',
        {},
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
  _ida.Future<bool> notificationsAvailable() =>
      caller.callServerEndpoint<bool>('project', 'notificationsAvailable', {});

  /// Sets the SNP for a project, or clears it.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param snpId The ID of the SNP to set, or null for no SNP masking. Clearing
  ///   became necessary once an SNP set could be deleted or fail to import, which
  ///   can leave a project pointing at one it can no longer use.
  _ida.Future<void> setSnpById(int id, int? snpId) =>
      caller.callServerEndpoint<void>('project', 'setSnpById', {
        'id': id,
        'snpId': snpId,
      });
}

/// Finding a project, a genome or an SNP set by typing part of its name.
///
/// Extends [FlumipEndpoint], so it is gated exactly as the three list endpoints it
/// draws on — and it reuses their visibility rules rather than restating them; see
/// [SearchService] for how the SQL and Dart predicates divide.
/// {@category Endpoint}
class EndpointSearch extends EndpointFlumip {
  EndpointSearch(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'search';

  /// Every project, genome and SNP set matching [query] that this caller may see.
  ///
  /// Grouped by the client, not here: the order is projects, then genomes, then
  /// SNP sets, each capped at [SearchService.hitsPerKind]. A query shorter than
  /// [SearchService.minQueryLength] answers with nothing rather than everything.
  ///
  /// ⚠️ **The query is not logged, unlike every other endpoint in this package.**
  /// This one is called on a debounce tick while somebody types, and its only
  /// argument is free text a user typed — a line per query would be both the
  /// noisiest and the least appropriate entry in the log. Failures are logged;
  /// queries are not. So silence here is the healthy state.
  ///
  /// \param session The current session.
  /// \param query What the user typed.
  _ida.Future<List<_i8y6t52d.SearchHitDto>> search(String query) =>
      caller.callServerEndpoint<List<_i8y6t52d.SearchHitDto>>(
        'search',
        'search',
        {'query': query},
      );
}

/// Endpoint for handling settings-related operations.
///
/// Deliberately **not** a [FlumipEndpoint]: [userSettings] has to answer before
/// the app knows anything, and the password route below has to keep working on
/// an install with no identities at all.
///
/// Every method gates itself instead, on an authenticated admin session or — only
/// while sign-in is not being enforced — the settings password. See
/// `SettingsService._isAdmin` for what that trades away, and for the escape that
/// is left when the identity provider is the thing that broke.
/// {@category Endpoint}
class EndpointSettings extends _isc.EndpointRef {
  EndpointSettings(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'settings';

  /// What the calling user may see, and how they may get in.
  ///
  /// Answered for **anyone**, signed in or not, and deliberately leaks nothing:
  /// two booleans the app needs before it can decide what to draw. Without it
  /// the Settings tab has to guess — which is what produced the behaviour this
  /// replaced, where an administrator was shown a password box for a password
  /// they did not need, and a user was shown one that would have worked.
  ///
  /// **The extension point for per-user settings**: see [UserSettingsDto].
  ///
  /// \param session The current session.
  _ida.Future<_ikcb9gvb.UserSettingsDto> userSettings() =>
      caller.callServerEndpoint<_ikcb9gvb.UserSettingsDto>(
        'settings',
        'userSettings',
        {},
      );

  /// Retrieves the settings.
  ///
  /// \param session The current session.
  /// \param password The settings password, or null to rely on an admin session.
  /// \returns The retrieved [Settings] object.
  _ida.Future<_ibile1le.Settings> getSettings(String? password) =>
      caller.callServerEndpoint<_ibile1le.Settings>('settings', 'getSettings', {
        'password': password,
      });

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
  _ida.Future<void> updateSettings(
    String? password,
    _ibile1le.Settings settings,
  ) => caller.callServerEndpoint<void>('settings', 'updateSettings', {
    'password': password,
    'settings': settings,
  });

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
  _ida.Future<void> setOidcClientSecret(String? password, String secret) =>
      caller.callServerEndpoint<void>('settings', 'setOidcClientSecret', {
        'password': password,
        'secret': secret,
      });

  /// Stores the SMTP password, which is never sent back.
  ///
  /// Write-only, exactly like [setOidcClientSecret] and for the same reason: an
  /// ordinary field is serialised on every `getSettings`, so the mail account's
  /// password travelled to the browser in cleartext for anyone with the settings
  /// screen open.
  ///
  /// An empty [secret] clears it, which is how a relay that needs no
  /// authentication is configured. To *keep* the stored one, do not call this —
  /// saving the rest of the settings leaves it alone.
  _ida.Future<void> setSmtpPassword(String? password, String secret) =>
      caller.callServerEndpoint<void>('settings', 'setSmtpPassword', {
        'password': password,
        'secret': secret,
      });

  /// Whether an SMTP password is stored, without revealing it.
  ///
  /// Lets the settings tab say "a password is stored, type here to replace it"
  /// rather than showing an empty box that looks like nothing is configured.
  _ida.Future<bool> smtpPasswordConfigured(String? password) =>
      caller.callServerEndpoint<bool>('settings', 'smtpPasswordConfigured', {
        'password': password,
      });

  /// Changes the settings password, which is stored hashed and never sent back.
  ///
  /// Write-only for the same reason as [setSmtpPassword] and
  /// [setOidcClientSecret] — an ordinary field is serialized on every
  /// `getSettings` — but with one difference that matters: an empty
  /// [newPassword] is **refused**, not treated as "clear it". See
  /// `SettingsService.setSettingsPassword`.
  ///
  /// ⚠️ Authenticated with the *old* password (or an admin session). The caller
  /// must then start using the new one for subsequent calls; nothing about this
  /// endpoint's result does that for it.
  ///
  /// \param session The current session.
  /// \param password The current settings password, or null for an admin session.
  /// \param newPassword The replacement. Must not be empty.
  _ida.Future<void> setSettingsPassword(String? password, String newPassword) =>
      caller.callServerEndpoint<void>('settings', 'setSettingsPassword', {
        'password': password,
        'newPassword': newPassword,
      });

  /// Whether the settings password is still the shipped default.
  ///
  /// Hashing removed the only thing that used to make that visible — the
  /// password sitting readable in its own box — so the tab asks instead and
  /// warns. See `SettingsService.settingsPasswordIsDefault`.
  _ida.Future<bool> settingsPasswordIsDefault(String? password) =>
      caller.callServerEndpoint<bool>('settings', 'settingsPasswordIsDefault', {
        'password': password,
      });

  /// Everything the settings tab needs to show about the SSO setup that is not
  /// itself a stored setting.
  ///
  /// Runs a live discovery probe, mirroring how [sendTestMail] validates the SMTP
  /// configuration — the point is to fail here, with a readable message, rather
  /// than at someone's first sign-in attempt.
  ///
  /// \param session The current session.
  /// \param password The settings password, or null to rely on an admin session.
  _ida.Future<_ifh830yy.AuthAdminStatusDto> getAuthAdminStatus(
    String? password,
  ) => caller.callServerEndpoint<_ifh830yy.AuthAdminStatusDto>(
    'settings',
    'getAuthAdminStatus',
    {'password': password},
  );

  /// Sends a test email so the SMTP configuration can be validated.
  ///
  /// \param session The current session.
  /// \param password The settings password, or null to rely on an admin session.
  /// \param to The recipient address.
  _ida.Future<void> sendTestMail(String? password, String to) =>
      caller.callServerEndpoint<void>('settings', 'sendTestMail', {
        'password': password,
        'to': to,
      });
}

/// Everything to do with SNP sets that a user, rather than the server's
/// administrator, brought along.
///
/// Reading and listing live here too, because they have to be visibility-filtered
/// and `GenomeEndpoint` has no notion of who owns what.
/// {@category Endpoint}
class EndpointSnp extends EndpointFlumip {
  EndpointSnp(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'snp';

  /// Every SNP for a genome that this caller may see.
  ///
  /// Filtered twice over — once for visibility, and again to hide somebody else's
  /// half-finished import — by [AuthorizationService.listableSnps], which is
  /// where both passes live now that search needs the same pair.
  ///
  /// \param session The current session.
  /// \param genomeId The genome whose SNP sets to list.
  _ida.Future<List<_iumnx4id.Snp>> listSnpsForGenome(int genomeId) =>
      caller.callServerEndpoint<List<_iumnx4id.Snp>>(
        'snp',
        'listSnpsForGenome',
        {'genomeId': genomeId},
      );

  /// Every custom SNP this caller added, whatever state it is in.
  ///
  /// Unlike [listSnpsForGenome] this shows failed and in-flight imports, because
  /// this is the list somebody goes to in order to fix or remove one. An
  /// administrator gets every custom SNP on the server, which is what makes
  /// cleaning up after a departed colleague possible.
  ///
  /// Doubles as the app's answer to "which of these are mine?" — the session
  /// carries no user id, so the client works it out from the ids in this list.
  _ida.Future<List<_iumnx4id.Snp>> listMySnps() =>
      caller.callServerEndpoint<List<_iumnx4id.Snp>>('snp', 'listMySnps', {});

  /// Announces a custom SNP set whose files the browser is about to send.
  ///
  /// Step one of three. Returns a `pending` row with its directory made, so the
  /// browser knows where to `PUT` — the path is derived from the row id and can
  /// therefore never be influenced by anything a user typed.
  ///
  /// ```
  /// 1. createUpload(dto)                       -> Snp (pending)
  /// 2. PUT /snp_upload/<id>/<fileName>         x1 or x2, raw bytes
  /// 3. finishUpload(id)                        -> Snp (ready | indexing | failed)
  /// ```
  _ida.Future<_iumnx4id.Snp> createUpload(
    _iqct5zkb.CustomSnpRequestDto request,
  ) => caller.callServerEndpoint<_iumnx4id.Snp>('snp', 'createUpload', {
    'request': request,
  });

  /// Step three: works out what actually arrived and settles the row.
  ///
  /// Reads the directory rather than trusting the client's account of what it
  /// sent, so a browser that dropped the second `PUT` cannot leave a row claiming
  /// to be complete.
  _ida.Future<_iumnx4id.Snp> finishUpload(int snpId) =>
      caller.callServerEndpoint<_iumnx4id.Snp>('snp', 'finishUpload', {
        'snpId': snpId,
      });

  /// Removes a custom SNP set whose upload never completed.
  ///
  /// Distinct from [deleteCustomSnp] only in intent: this is the "cancel" the app
  /// offers on a `pending` row, and refusing anything further along stops it
  /// double-serving as a delete without confirmation.
  _ida.Future<void> cancelUpload(int snpId) =>
      caller.callServerEndpoint<void>('snp', 'cancelUpload', {'snpId': snpId});

  /// Adds a custom SNP set whose files the server fetches for itself.
  ///
  /// `request.urls` is the `.vcf.gz` address and optionally its `.vcf.gz.tbi`.
  /// Returns immediately with a `pending` row; the bytes arrive on a future call
  /// and the app watches `status` and `bytesDownloaded`.
  ///
  /// ⚠️ **Every URL is validated synchronously, before the row is inserted.** A
  /// rejected address comes back as an error on this call rather than as a
  /// `failed` row the user has to go and find — and, more to the point, the
  /// address check is what stops this endpoint being a request proxy into the
  /// deployment's own network. See `snpSourceUrlRejection`.
  _ida.Future<_iumnx4id.Snp> importFromUrls(
    _iqct5zkb.CustomSnpRequestDto request,
  ) => caller.callServerEndpoint<_iumnx4id.Snp>('snp', 'importFromUrls', {
    'request': request,
  });

  /// Puts a failed import back in the queue and reschedules it.
  ///
  /// Starts over rather than resuming: a half-download that silently continued
  /// against a *changed* remote file would produce a corrupt archive, which is a
  /// worse outcome than fetching a gigabyte twice.
  _ida.Future<_iumnx4id.Snp> retryImport(int snpId) =>
      caller.callServerEndpoint<_iumnx4id.Snp>('snp', 'retryImport', {
        'snpId': snpId,
      });

  /// Shares an SNP with everyone on this server, or takes it back.
  ///
  /// Only its owner — or an administrator — may do this, even once it is shared.
  /// Ownership survives sharing.
  ///
  /// \param session The current session.
  /// \param snpId The SNP to change.
  /// \param shared True to make it visible to everybody.
  _ida.Future<_iumnx4id.Snp> setShared(int snpId, bool shared) =>
      caller.callServerEndpoint<_iumnx4id.Snp>('snp', 'setShared', {
        'snpId': snpId,
        'shared': shared,
      });

  /// Renames an SNP and rewrites its description.
  ///
  /// Cosmetic only: the files on disk are named after the row id, never after
  /// this, so nothing has to move and no path changes.
  _ida.Future<_iumnx4id.Snp> renameSnp(
    int snpId,
    String name,
    String description,
  ) => caller.callServerEndpoint<_iumnx4id.Snp>('snp', 'renameSnp', {
    'snpId': snpId,
    'name': name,
    'description': description,
  });

  /// The projects currently using this SNP.
  ///
  /// Read before a delete is confirmed, so the dialog can name them rather than
  /// warning in the abstract.
  _ida.Future<List<_idqeum9a.SnpUsageDto>> snpUsage(int snpId) =>
      caller.callServerEndpoint<List<_idqeum9a.SnpUsageDto>>(
        'snp',
        'snpUsage',
        {'snpId': snpId},
      );

  /// Deletes a custom SNP and its files. Its owner, or an administrator.
  ///
  /// Refuses a global SNP outright. Removing one of those deletes files out of
  /// the shared genome tree, which is a different decision needing a different
  /// gate — see [deleteSnpAsAdmin]. Keeping them as separate methods is what stops
  /// an ordinary user's delete button from ever being able to reach one.
  _ida.Future<void> deleteCustomSnp(int snpId) => caller
      .callServerEndpoint<void>('snp', 'deleteCustomSnp', {'snpId': snpId});

  /// Deletes **any** SNP, including a global one, along with its files.
  ///
  /// ⚠️ **Irreversible, and it reaches outside this application's own data.** A
  /// global SNP's files are part of the hand-assembled genome tree; dbSNP is
  /// tens of gigabytes and hours of transfer, quite possibly on a shared mount.
  /// There is no undo and no tombstone — restoring means putting the files back
  /// and collecting again, which produces a new row with a new id.
  ///
  /// Gated by [SettingsService.requireAdmin] rather than
  /// `AuthorizationService.requireAdmin`, and the difference matters. The latter
  /// deliberately *throws* while single sign-on is off, on the grounds that
  /// reassigning ownership is meaningless without identities. That reasoning does
  /// not carry here: a no-auth install can perfectly well have a broken global SNP
  /// that needs removing, and it has an established administrative credential in
  /// the settings password. [SettingsService.requireAdmin] already implements
  /// exactly that dual gate — an admin session, or the password while sign-in is
  /// not enforced.
  ///
  /// \param settingsPassword Ignored when the caller is a signed-in admin.
  /// \param force Required when projects are still using it. Without it the call
  ///   refuses and names them, so nobody removes a file three running designs
  ///   depend on by accident.
  _ida.Future<void> deleteSnpAsAdmin(
    int snpId,
    String? settingsPassword, {
    required bool force,
  }) => caller.callServerEndpoint<void>('snp', 'deleteSnpAsAdmin', {
    'snpId': snpId,
    'settingsPassword': settingsPassword,
    'force': force,
  });

  /// Rescans the custom SNP directory.
  ///
  /// Ungated, matching `GenomeEndpoint.collectGenomes`, which has always been.
  /// It creates nothing a user did not already put on the server's disk, and
  /// gating both is a defensible hardening for another day.
  _ida.Future<void> collectCustomSnps() =>
      caller.callServerEndpoint<void>('snp', 'collectCustomSnps', {});
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(_isc.MethodCallContext, Object, StackTrace)? onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    auth = EndpointAuth(this);
    file = EndpointFile(this);
    genome = EndpointGenome(this);
    mipgen = EndpointMipgen(this);
    options = EndpointOptions(this);
    project = EndpointProject(this);
    search = EndpointSearch(this);
    settings = EndpointSettings(this);
    snp = EndpointSnp(this);
  }

  late final EndpointAuth auth;

  late final EndpointFile file;

  late final EndpointGenome genome;

  late final EndpointMipgen mipgen;

  late final EndpointOptions options;

  late final EndpointProject project;

  late final EndpointSearch search;

  late final EndpointSettings settings;

  late final EndpointSnp snp;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'auth': auth,
    'file': file,
    'genome': genome,
    'mipgen': mipgen,
    'options': options,
    'project': project,
    'search': search,
    'settings': settings,
    'snp': snp,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {};
}
