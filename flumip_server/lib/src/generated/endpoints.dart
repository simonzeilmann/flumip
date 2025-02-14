/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import '../endpoints/mipgen_endpoint.dart' as _i2;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'mipgen': _i2.MipgenEndpoint()
        ..initialize(
          server,
          'mipgen',
          null,
        )
    };
    connectors['mipgen'] = _i1.EndpointConnector(
      name: 'mipgen',
      endpoint: endpoints['mipgen']!,
      methodConnectors: {
        'createProject': _i1.MethodConnector(
          name: 'createProject',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['mipgen'] as _i2.MipgenEndpoint).createProject(
            session,
            params['name'],
          ),
        ),
        'deleteProject': _i1.MethodConnector(
          name: 'deleteProject',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['mipgen'] as _i2.MipgenEndpoint).deleteProject(
            session,
            params['name'],
          ),
        ),
        'getProjects': _i1.MethodConnector(
          name: 'getProjects',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['mipgen'] as _i2.MipgenEndpoint).getProjects(session),
        ),
        'createGeneFile': _i1.MethodConnector(
          name: 'createGeneFile',
          params: {
            'projectName': _i1.ParameterDescription(
              name: 'projectName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'genes': _i1.ParameterDescription(
              name: 'genes',
              type: _i1.getType<List<String>>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['mipgen'] as _i2.MipgenEndpoint).createGeneFile(
            session,
            params['projectName'],
            params['genes'],
          ),
        ),
        'getGenes': _i1.MethodConnector(
          name: 'getGenes',
          params: {
            'projectName': _i1.ParameterDescription(
              name: 'projectName',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['mipgen'] as _i2.MipgenEndpoint).getGenes(
            session,
            params['projectName'],
          ),
        ),
        'createBedFile': _i1.MethodConnector(
          name: 'createBedFile',
          params: {
            'projectName': _i1.ParameterDescription(
              name: 'projectName',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['mipgen'] as _i2.MipgenEndpoint).createBedFile(
            session,
            params['projectName'],
          ),
        ),
        'checkBedFileExists': _i1.MethodConnector(
          name: 'checkBedFileExists',
          params: {
            'projectName': _i1.ParameterDescription(
              name: 'projectName',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['mipgen'] as _i2.MipgenEndpoint).checkBedFileExists(
            session,
            params['projectName'],
          ),
        ),
        'generateMips': _i1.MethodConnector(
          name: 'generateMips',
          params: {
            'projectName': _i1.ParameterDescription(
              name: 'projectName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'deleteExcessFiles': _i1.ParameterDescription(
              name: 'deleteExcessFiles',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['mipgen'] as _i2.MipgenEndpoint).generateMips(
            session,
            params['projectName'],
            params['deleteExcessFiles'],
          ),
        ),
        'showMipsProgress': _i1.MethodConnector(
          name: 'showMipsProgress',
          params: {
            'projectName': _i1.ParameterDescription(
              name: 'projectName',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['mipgen'] as _i2.MipgenEndpoint).showMipsProgress(
            session,
            params['projectName'],
          ),
        ),
        'showMipsResult': _i1.MethodConnector(
          name: 'showMipsResult',
          params: {
            'projectName': _i1.ParameterDescription(
              name: 'projectName',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['mipgen'] as _i2.MipgenEndpoint).showMipsResult(
            session,
            params['projectName'],
          ),
        ),
      },
    );
  }
}
