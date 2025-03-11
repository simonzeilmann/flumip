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
import '../endpoints/file_endpoint.dart' as _i2;
import '../endpoints/mipgen_endpoint.dart' as _i3;
import '../endpoints/options_endpoint.dart' as _i4;
import '../endpoints/project_endpoint.dart' as _i5;
import '../endpoints/settings_endpoint.dart' as _i6;
import 'package:flumip_server/src/generated/project_options.dart' as _i7;
import 'package:flumip_server/src/generated/settings.dart' as _i8;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'file': _i2.FileEndpoint()
        ..initialize(
          server,
          'file',
          null,
        ),
      'mipgen': _i3.MipgenEndpoint()
        ..initialize(
          server,
          'mipgen',
          null,
        ),
      'options': _i4.OptionsEndpoint()
        ..initialize(
          server,
          'options',
          null,
        ),
      'project': _i5.ProjectEndpoint()
        ..initialize(
          server,
          'project',
          null,
        ),
      'settings': _i6.SettingsEndpoint()
        ..initialize(
          server,
          'settings',
          null,
        ),
    };
    connectors['file'] = _i1.EndpointConnector(
      name: 'file',
      endpoint: endpoints['file']!,
      methodConnectors: {
        'deleteByProducts': _i1.MethodConnector(
          name: 'deleteByProducts',
          params: {
            'projectID': _i1.ParameterDescription(
              name: 'projectID',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['file'] as _i2.FileEndpoint).deleteByProducts(
            session,
            params['projectID'],
          ),
        ),
        'showSnpMipsResult': _i1.MethodConnector(
          name: 'showSnpMipsResult',
          params: {
            'projectID': _i1.ParameterDescription(
              name: 'projectID',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['file'] as _i2.FileEndpoint).showSnpMipsResult(
            session,
            params['projectID'],
          ),
        ),
        'showMipsResult': _i1.MethodConnector(
          name: 'showMipsResult',
          params: {
            'projectID': _i1.ParameterDescription(
              name: 'projectID',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['file'] as _i2.FileEndpoint).showMipsResult(
            session,
            params['projectID'],
          ),
        ),
        'showMipsProgress': _i1.MethodConnector(
          name: 'showMipsProgress',
          params: {
            'projectID': _i1.ParameterDescription(
              name: 'projectID',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['file'] as _i2.FileEndpoint).showMipsProgress(
            session,
            params['projectID'],
          ),
        ),
      },
    );
    connectors['mipgen'] = _i1.EndpointConnector(
      name: 'mipgen',
      endpoint: endpoints['mipgen']!,
      methodConnectors: {
        'createBedFile': _i1.MethodConnector(
          name: 'createBedFile',
          params: {
            'projectID': _i1.ParameterDescription(
              name: 'projectID',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['mipgen'] as _i3.MipgenEndpoint).createBedFile(
            session,
            params['projectID'],
          ),
        ),
        'generateMips': _i1.MethodConnector(
          name: 'generateMips',
          params: {
            'projectID': _i1.ParameterDescription(
              name: 'projectID',
              type: _i1.getType<int>(),
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
              (endpoints['mipgen'] as _i3.MipgenEndpoint).generateMips(
            session,
            params['projectID'],
            params['deleteExcessFiles'],
          ),
        ),
      },
    );
    connectors['options'] = _i1.EndpointConnector(
      name: 'options',
      endpoint: endpoints['options']!,
      methodConnectors: {
        'createProjectOptions': _i1.MethodConnector(
          name: 'createProjectOptions',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['options'] as _i4.OptionsEndpoint)
                  .createProjectOptions(session),
        ),
        'insertProjectOptions': _i1.MethodConnector(
          name: 'insertProjectOptions',
          params: {
            'options': _i1.ParameterDescription(
              name: 'options',
              type: _i1.getType<_i7.ProjectOptions>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['options'] as _i4.OptionsEndpoint)
                  .insertProjectOptions(
            session,
            params['options'],
          ),
        ),
        'getProjectOptions': _i1.MethodConnector(
          name: 'getProjectOptions',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['options'] as _i4.OptionsEndpoint).getProjectOptions(
            session,
            params['id'],
          ),
        ),
        'updateProjectOptions': _i1.MethodConnector(
          name: 'updateProjectOptions',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'options': _i1.ParameterDescription(
              name: 'options',
              type: _i1.getType<_i7.ProjectOptions>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['options'] as _i4.OptionsEndpoint)
                  .updateProjectOptions(
            session,
            params['id'],
            params['options'],
          ),
        ),
        'deleteProjectOptions': _i1.MethodConnector(
          name: 'deleteProjectOptions',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['options'] as _i4.OptionsEndpoint)
                  .deleteProjectOptions(
            session,
            params['id'],
          ),
        ),
      },
    );
    connectors['project'] = _i1.EndpointConnector(
      name: 'project',
      endpoint: endpoints['project']!,
      methodConnectors: {
        'createProject': _i1.MethodConnector(
          name: 'createProject',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'options': _i1.ParameterDescription(
              name: 'options',
              type: _i1.getType<_i7.ProjectOptions>(),
              nullable: false,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['project'] as _i5.ProjectEndpoint).createProject(
            session,
            params['name'],
            params['options'],
            params['description'],
          ),
        ),
        'deleteProject': _i1.MethodConnector(
          name: 'deleteProject',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['project'] as _i5.ProjectEndpoint).deleteProject(
            session,
            params['id'],
          ),
        ),
        'getProjects': _i1.MethodConnector(
          name: 'getProjects',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['project'] as _i5.ProjectEndpoint)
                  .getProjects(session),
        ),
        'getProject': _i1.MethodConnector(
          name: 'getProject',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['project'] as _i5.ProjectEndpoint).getProject(
            session,
            params['id'],
          ),
        ),
        'addGeneToProject': _i1.MethodConnector(
          name: 'addGeneToProject',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'gene': _i1.ParameterDescription(
              name: 'gene',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['project'] as _i5.ProjectEndpoint).addGeneToProject(
            session,
            params['id'],
            params['gene'],
          ),
        ),
        'removeGeneFromProject': _i1.MethodConnector(
          name: 'removeGeneFromProject',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'gene': _i1.ParameterDescription(
              name: 'gene',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['project'] as _i5.ProjectEndpoint)
                  .removeGeneFromProject(
            session,
            params['id'],
            params['gene'],
          ),
        ),
        'addGenesToProject': _i1.MethodConnector(
          name: 'addGenesToProject',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
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
              (endpoints['project'] as _i5.ProjectEndpoint).addGenesToProject(
            session,
            params['id'],
            params['genes'],
          ),
        ),
      },
    );
    connectors['settings'] = _i1.EndpointConnector(
      name: 'settings',
      endpoint: endpoints['settings']!,
      methodConnectors: {
        'getSettings': _i1.MethodConnector(
          name: 'getSettings',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['settings'] as _i6.SettingsEndpoint)
                  .getSettings(session),
        ),
        'updateSettings': _i1.MethodConnector(
          name: 'updateSettings',
          params: {
            'settings': _i1.ParameterDescription(
              name: 'settings',
              type: _i1.getType<_i8.Settings>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['settings'] as _i6.SettingsEndpoint).updateSettings(
            session,
            params['settings'],
          ),
        ),
      },
    );
  }
}
