/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:flumip_client/src/protocol/genome.dart' as _i3;
import 'package:flumip_client/src/protocol/snp.dart' as _i4;
import 'package:flumip_client/src/protocol/project_options.dart' as _i5;
import 'package:flumip_client/src/protocol/project.dart' as _i6;
import 'package:flumip_client/src/protocol/settings.dart' as _i7;
import 'protocol.dart' as _i8;

/// Endpoint for handling file-related operations.
/// {@category Endpoint}
class EndpointFile extends _i1.EndpointRef {
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
}

/// Endpoint for genome-related operations.
/// {@category Endpoint}
class EndpointGenome extends _i1.EndpointRef {
  EndpointGenome(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'genome';

  /// Retrieves a genome by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to retrieve.
  /// \returns The genome with the specified ID.
  /// \throws Exception if an error occurs during retrieval.
  _i2.Future<_i3.Genome> getGenome(int id) =>
      caller.callServerEndpoint<_i3.Genome>(
        'genome',
        'getGenome',
        {'id': id},
      );

  /// Retrieves all genomes.
  ///
  /// \param session The current session.
  /// \returns A list of all genomes.
  /// \throws Exception if an error occurs during retrieval.
  _i2.Future<List<_i3.Genome>> getAllGenomes() =>
      caller.callServerEndpoint<List<_i3.Genome>>(
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
    _i3.Genome genome,
  ) =>
      caller.callServerEndpoint<void>(
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

  /// Indexes the FA file for the specified genome.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to index.
  /// \throws Exception if an error occurs during indexing.
  _i2.Future<void> indexGenome(int id) => caller.callServerEndpoint<void>(
        'genome',
        'indexGenome',
        {'id': id},
      );

  /// Deletes the index for the specified genome.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to delete the index for.
  /// \throws Exception if an error occurs during deletion.
  _i2.Future<void> deleteGenomeIndex(int id) => caller.callServerEndpoint<void>(
        'genome',
        'deleteGenomeIndex',
        {'id': id},
      );

  /// Retrieves an SNP by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the SNP to retrieve.
  /// \returns The SNP with the specified ID.
  /// \throws Exception if an error occurs during retrieval.
  _i2.Future<_i4.Snp> getSnp(int id) => caller.callServerEndpoint<_i4.Snp>(
        'genome',
        'getSnp',
        {'id': id},
      );

  _i2.Future<List<_i4.Snp>> getSnpsForGenome(int genomeId) =>
      caller.callServerEndpoint<List<_i4.Snp>>(
        'genome',
        'getSnpsForGenome',
        {'genomeId': genomeId},
      );

  /// Retrieves all SNPs for a specific genome.
  ///
  /// \param session The current session.
  /// \param genomeId The ID of the genome to retrieve SNPs for.
  /// \returns A list of all SNPs for the specified genome.
  /// \throws Exception if an error occurs during retrieval.
  _i2.Future<List<_i4.Snp>> getAllSnpForGenome(int genomeId) =>
      caller.callServerEndpoint<List<_i4.Snp>>(
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
    _i4.Snp snp,
  ) =>
      caller.callServerEndpoint<void>(
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
  _i2.Future<List<_i3.Genome>> getGenomeByCategory(String category) =>
      caller.callServerEndpoint<List<_i3.Genome>>(
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
}

/// Endpoint for handling MIP generation-related operations.
/// {@category Endpoint}
class EndpointMipgen extends _i1.EndpointRef {
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
  /// \param deleteExcessFiles Whether to delete excess files after generating MIPs.
  _i2.Future<void> generateMips(
    int projectID,
    bool deleteExcessFiles,
  ) =>
      caller.callServerEndpoint<void>(
        'mipgen',
        'generateMips',
        {
          'projectID': projectID,
          'deleteExcessFiles': deleteExcessFiles,
        },
      );
}

/// Endpoint for handling project options-related operations.
/// {@category Endpoint}
class EndpointOptions extends _i1.EndpointRef {
  EndpointOptions(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'options';

  /// Creates project options.
  ///
  /// \param session The current session.
  /// \returns The created [ProjectOptions] object.
  _i2.Future<_i5.ProjectOptions> createProjectOptions() =>
      caller.callServerEndpoint<_i5.ProjectOptions>(
        'options',
        'createProjectOptions',
        {},
      );

  /// Inserts project options.
  ///
  /// \param session The current session.
  /// \param options The [ProjectOptions] object to insert.
  /// \returns The inserted [ProjectOptions] object.
  _i2.Future<_i5.ProjectOptions> insertProjectOptions(
          _i5.ProjectOptions options) =>
      caller.callServerEndpoint<_i5.ProjectOptions>(
        'options',
        'insertProjectOptions',
        {'options': options},
      );

  /// Retrieves project options by ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project options to retrieve.
  /// \returns The retrieved [ProjectOptions] object.
  _i2.Future<_i5.ProjectOptions> getProjectOptions(int id) =>
      caller.callServerEndpoint<_i5.ProjectOptions>(
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
    _i5.ProjectOptions options,
  ) =>
      caller.callServerEndpoint<void>(
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
}

/// Endpoint for handling project-related operations.
/// {@category Endpoint}
class EndpointProject extends _i1.EndpointRef {
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
  _i2.Future<_i6.Project> createProject(
    String name,
    _i5.ProjectOptions options, [
    String? description,
  ]) =>
      caller.callServerEndpoint<_i6.Project>(
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
  _i2.Future<List<_i6.Project>> getProjects() =>
      caller.callServerEndpoint<List<_i6.Project>>(
        'project',
        'getProjects',
        {},
      );

  /// Retrieves a project by ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project to retrieve.
  /// \returns The retrieved [Project] object.
  _i2.Future<_i6.Project> getProject(int id) =>
      caller.callServerEndpoint<_i6.Project>(
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
  ) =>
      caller.callServerEndpoint<void>(
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
  ) =>
      caller.callServerEndpoint<void>(
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
  ) =>
      caller.callServerEndpoint<void>(
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
  ) =>
      caller.callServerEndpoint<void>(
        'project',
        'setGeneById',
        {
          'id': id,
          'genomeId': genomeId,
        },
      );

  /// Sets the SNP for a project by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param snpId The ID of the SNP to set.
  _i2.Future<void> setSnpById(
    int id,
    int snpId,
  ) =>
      caller.callServerEndpoint<void>(
        'project',
        'setSnpById',
        {
          'id': id,
          'snpId': snpId,
        },
      );
}

/// Endpoint for handling settings-related operations.
/// {@category Endpoint}
class EndpointSettings extends _i1.EndpointRef {
  EndpointSettings(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'settings';

  /// Retrieves the settings.
  ///
  /// \param session The current session.
  /// \param password The password for authentication.
  /// \returns The retrieved [Settings] object.
  _i2.Future<_i7.Settings> getSettings(String password) =>
      caller.callServerEndpoint<_i7.Settings>(
        'settings',
        'getSettings',
        {'password': password},
      );

  /// Updates the settings.
  ///
  /// \param session The current session.
  /// \param settings The [Settings] object to update.
  _i2.Future<void> updateSettings(_i7.Settings settings) =>
      caller.callServerEndpoint<void>(
        'settings',
        'updateSettings',
        {'settings': settings},
      );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    _i1.AuthenticationKeyManager? authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )? onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
          host,
          _i8.Protocol(),
          securityContext: securityContext,
          authenticationKeyManager: authenticationKeyManager,
          streamingConnectionTimeout: streamingConnectionTimeout,
          connectionTimeout: connectionTimeout,
          onFailedCall: onFailedCall,
          onSucceededCall: onSucceededCall,
          disconnectStreamsOnLostInternetConnection:
              disconnectStreamsOnLostInternetConnection,
        ) {
    file = EndpointFile(this);
    genome = EndpointGenome(this);
    mipgen = EndpointMipgen(this);
    options = EndpointOptions(this);
    project = EndpointProject(this);
    settings = EndpointSettings(this);
  }

  late final EndpointFile file;

  late final EndpointGenome genome;

  late final EndpointMipgen mipgen;

  late final EndpointOptions options;

  late final EndpointProject project;

  late final EndpointSettings settings;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
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
