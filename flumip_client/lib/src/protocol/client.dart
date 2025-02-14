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
import 'protocol.dart' as _i3;

/// {@category Endpoint}
class EndpointMipgen extends _i1.EndpointRef {
  EndpointMipgen(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'mipgen';

  _i2.Future<bool> createProject(String name) =>
      caller.callServerEndpoint<bool>(
        'mipgen',
        'createProject',
        {'name': name},
      );

  _i2.Future<void> deleteProject(String name) =>
      caller.callServerEndpoint<void>(
        'mipgen',
        'deleteProject',
        {'name': name},
      );

  _i2.Future<List<String>> getProjects() =>
      caller.callServerEndpoint<List<String>>(
        'mipgen',
        'getProjects',
        {},
      );

  _i2.Future<void> createGeneFile(
    String projectName,
    List<String> genes,
  ) =>
      caller.callServerEndpoint<void>(
        'mipgen',
        'createGeneFile',
        {
          'projectName': projectName,
          'genes': genes,
        },
      );

  _i2.Future<List<String>> getGenes(String projectName) =>
      caller.callServerEndpoint<List<String>>(
        'mipgen',
        'getGenes',
        {'projectName': projectName},
      );

  _i2.Future<void> createBedFile(String projectName) =>
      caller.callServerEndpoint<void>(
        'mipgen',
        'createBedFile',
        {'projectName': projectName},
      );

  _i2.Future<bool> checkBedFileExists(String projectName) =>
      caller.callServerEndpoint<bool>(
        'mipgen',
        'checkBedFileExists',
        {'projectName': projectName},
      );

  _i2.Future<void> generateMips(
    String projectName,
    bool deleteExcessFiles,
  ) =>
      caller.callServerEndpoint<void>(
        'mipgen',
        'generateMips',
        {
          'projectName': projectName,
          'deleteExcessFiles': deleteExcessFiles,
        },
      );

  _i2.Future<List<String>> showMipsProgress(String projectName) =>
      caller.callServerEndpoint<List<String>>(
        'mipgen',
        'showMipsProgress',
        {'projectName': projectName},
      );

  _i2.Future<List<String>> showMipsResult(String projectName) =>
      caller.callServerEndpoint<List<String>>(
        'mipgen',
        'showMipsResult',
        {'projectName': projectName},
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
          _i3.Protocol(),
          securityContext: securityContext,
          authenticationKeyManager: authenticationKeyManager,
          streamingConnectionTimeout: streamingConnectionTimeout,
          connectionTimeout: connectionTimeout,
          onFailedCall: onFailedCall,
          onSucceededCall: onSucceededCall,
          disconnectStreamsOnLostInternetConnection:
              disconnectStreamsOnLostInternetConnection,
        ) {
    mipgen = EndpointMipgen(this);
  }

  late final EndpointMipgen mipgen;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {'mipgen': mipgen};

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
