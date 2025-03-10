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
import 'package:flumip_client/src/protocol/project_options.dart' as _i3;
import 'package:flumip_client/src/protocol/project.dart' as _i4;
import 'package:flumip_client/src/protocol/settings.dart' as _i5;
import 'protocol.dart' as _i6;

/// {@category Endpoint}
class EndpointFile extends _i1.EndpointRef {
  EndpointFile(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'file';

  _i2.Future<void> deleteByProducts(int projectID) =>
      caller.callServerEndpoint<void>(
        'file',
        'deleteByProducts',
        {'projectID': projectID},
      );

  _i2.Future<List<String>> showSnpMipsResult(int projectID) =>
      caller.callServerEndpoint<List<String>>(
        'file',
        'showSnpMipsResult',
        {'projectID': projectID},
      );

  _i2.Future<List<String>> showMipsResult(int projectID) =>
      caller.callServerEndpoint<List<String>>(
        'file',
        'showMipsResult',
        {'projectID': projectID},
      );

  _i2.Future<List<String>> showMipsProgress(int projectID) =>
      caller.callServerEndpoint<List<String>>(
        'file',
        'showMipsProgress',
        {'projectID': projectID},
      );
}

/// {@category Endpoint}
class EndpointMipgen extends _i1.EndpointRef {
  EndpointMipgen(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'mipgen';

  _i2.Future<void> createBedFile(int projectID) =>
      caller.callServerEndpoint<void>(
        'mipgen',
        'createBedFile',
        {'projectID': projectID},
      );

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

/// {@category Endpoint}
class EndpointOptions extends _i1.EndpointRef {
  EndpointOptions(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'options';

  _i2.Future<_i3.ProjectOptions> createProjectOptions() =>
      caller.callServerEndpoint<_i3.ProjectOptions>(
        'options',
        'createProjectOptions',
        {},
      );

  _i2.Future<_i3.ProjectOptions> insertProjectOptions(
          _i3.ProjectOptions options) =>
      caller.callServerEndpoint<_i3.ProjectOptions>(
        'options',
        'insertProjectOptions',
        {'options': options},
      );

  _i2.Future<_i3.ProjectOptions> getProjectOptions(int id) =>
      caller.callServerEndpoint<_i3.ProjectOptions>(
        'options',
        'getProjectOptions',
        {'id': id},
      );

  _i2.Future<void> updateProjectOptions(
    int id,
    _i3.ProjectOptions options,
  ) =>
      caller.callServerEndpoint<void>(
        'options',
        'updateProjectOptions',
        {
          'id': id,
          'options': options,
        },
      );

  _i2.Future<void> deleteProjectOptions(int id) =>
      caller.callServerEndpoint<void>(
        'options',
        'deleteProjectOptions',
        {'id': id},
      );
}

/// {@category Endpoint}
class EndpointProject extends _i1.EndpointRef {
  EndpointProject(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'project';

  _i2.Future<_i4.Project> createProject(
    String name,
    _i3.ProjectOptions options, [
    String? description,
  ]) =>
      caller.callServerEndpoint<_i4.Project>(
        'project',
        'createProject',
        {
          'name': name,
          'options': options,
          'description': description,
        },
      );

  _i2.Future<void> deleteProject(int id) => caller.callServerEndpoint<void>(
        'project',
        'deleteProject',
        {'id': id},
      );

  _i2.Future<List<_i4.Project>> getProjects() =>
      caller.callServerEndpoint<List<_i4.Project>>(
        'project',
        'getProjects',
        {},
      );

  _i2.Future<_i4.Project> getProject(int id) =>
      caller.callServerEndpoint<_i4.Project>(
        'project',
        'getProject',
        {'id': id},
      );

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
}

/// {@category Endpoint}
class EndpointSettings extends _i1.EndpointRef {
  EndpointSettings(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'settings';

  _i2.Future<_i5.Settings> getSettings() =>
      caller.callServerEndpoint<_i5.Settings>(
        'settings',
        'getSettings',
        {},
      );

  _i2.Future<void> updateSettings(_i5.Settings settings) =>
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
          _i6.Protocol(),
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
    mipgen = EndpointMipgen(this);
    options = EndpointOptions(this);
    project = EndpointProject(this);
    settings = EndpointSettings(this);
  }

  late final EndpointFile file;

  late final EndpointMipgen mipgen;

  late final EndpointOptions options;

  late final EndpointProject project;

  late final EndpointSettings settings;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
        'file': file,
        'mipgen': mipgen,
        'options': options,
        'project': project,
        'settings': settings,
      };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
