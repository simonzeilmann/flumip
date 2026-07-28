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
import 'package:serverpod/serverpod.dart' as _i1;
import '../endpoints/file_endpoint.dart' as _i2;
import '../endpoints/genome_endpoint.dart' as _i3;
import '../endpoints/mipgen_endpoint.dart' as _i4;
import '../endpoints/options_endpoint.dart' as _i5;
import '../endpoints/project_endpoint.dart' as _i6;
import '../endpoints/settings_endpoint.dart' as _i7;
import 'package:flumip_server/src/generated/genome.dart' as _i8;
import 'package:flumip_server/src/generated/snp.dart' as _i9;
import 'package:flumip_server/src/generated/project_options.dart' as _i10;
import 'package:flumip_server/src/generated/settings.dart' as _i11;
import 'package:flumip_server/src/generated/future_calls.dart' as _i12;
export 'future_calls.dart' show ServerpodFutureCallsGetter;

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
      'genome': _i3.GenomeEndpoint()
        ..initialize(
          server,
          'genome',
          null,
        ),
      'mipgen': _i4.MipgenEndpoint()
        ..initialize(
          server,
          'mipgen',
          null,
        ),
      'options': _i5.OptionsEndpoint()
        ..initialize(
          server,
          'options',
          null,
        ),
      'project': _i6.ProjectEndpoint()
        ..initialize(
          server,
          'project',
          null,
        ),
      'settings': _i7.SettingsEndpoint()
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
            ),
          },
          call:
              (
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
            ),
          },
          call:
              (
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
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['file'] as _i2.FileEndpoint).showMipsResult(
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
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['file'] as _i2.FileEndpoint).showMipsProgress(
                    session,
                    params['projectID'],
                  ),
        ),
        'showUSCSTrack': _i1.MethodConnector(
          name: 'showUSCSTrack',
          params: {
            'projectID': _i1.ParameterDescription(
              name: 'projectID',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['file'] as _i2.FileEndpoint).showUSCSTrack(
                session,
                params['projectID'],
              ),
        ),
      },
    );
    connectors['genome'] = _i1.EndpointConnector(
      name: 'genome',
      endpoint: endpoints['genome']!,
      methodConnectors: {
        'getGenome': _i1.MethodConnector(
          name: 'getGenome',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['genome'] as _i3.GenomeEndpoint).getGenome(
                session,
                params['id'],
              ),
        ),
        'getAllGenomes': _i1.MethodConnector(
          name: 'getAllGenomes',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['genome'] as _i3.GenomeEndpoint)
                  .getAllGenomes(session),
        ),
        'updateGenome': _i1.MethodConnector(
          name: 'updateGenome',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'genome': _i1.ParameterDescription(
              name: 'genome',
              type: _i1.getType<_i8.Genome>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['genome'] as _i3.GenomeEndpoint).updateGenome(
                    session,
                    params['id'],
                    params['genome'],
                  ),
        ),
        'collectGenomes': _i1.MethodConnector(
          name: 'collectGenomes',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['genome'] as _i3.GenomeEndpoint)
                  .collectGenomes(session),
        ),
        'getSnp': _i1.MethodConnector(
          name: 'getSnp',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['genome'] as _i3.GenomeEndpoint).getSnp(
                session,
                params['id'],
              ),
        ),
        'getAllSnpForGenome': _i1.MethodConnector(
          name: 'getAllSnpForGenome',
          params: {
            'genomeId': _i1.ParameterDescription(
              name: 'genomeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['genome'] as _i3.GenomeEndpoint)
                  .getAllSnpForGenome(
                    session,
                    params['genomeId'],
                  ),
        ),
        'updateSnp': _i1.MethodConnector(
          name: 'updateSnp',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'snp': _i1.ParameterDescription(
              name: 'snp',
              type: _i1.getType<_i9.Snp>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['genome'] as _i3.GenomeEndpoint).updateSnp(
                session,
                params['id'],
                params['snp'],
              ),
        ),
        'getCategories': _i1.MethodConnector(
          name: 'getCategories',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['genome'] as _i3.GenomeEndpoint)
                  .getCategories(session),
        ),
        'getGenomeByCategory': _i1.MethodConnector(
          name: 'getGenomeByCategory',
          params: {
            'category': _i1.ParameterDescription(
              name: 'category',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['genome'] as _i3.GenomeEndpoint)
                  .getGenomeByCategory(
                    session,
                    params['category'],
                  ),
        ),
        'indexFasta': _i1.MethodConnector(
          name: 'indexFasta',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['genome'] as _i3.GenomeEndpoint).indexFasta(
                session,
                params['id'],
              ),
        ),
        'deleteFastaIndex': _i1.MethodConnector(
          name: 'deleteFastaIndex',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['genome'] as _i3.GenomeEndpoint).deleteFastaIndex(
                    session,
                    params['id'],
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
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['mipgen'] as _i4.MipgenEndpoint).createBedFile(
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
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['mipgen'] as _i4.MipgenEndpoint).generateMips(
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
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['options'] as _i5.OptionsEndpoint)
                  .createProjectOptions(session),
        ),
        'insertProjectOptions': _i1.MethodConnector(
          name: 'insertProjectOptions',
          params: {
            'options': _i1.ParameterDescription(
              name: 'options',
              type: _i1.getType<_i10.ProjectOptions>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['options'] as _i5.OptionsEndpoint)
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
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['options'] as _i5.OptionsEndpoint)
                  .getProjectOptions(
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
              type: _i1.getType<_i10.ProjectOptions>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['options'] as _i5.OptionsEndpoint)
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
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['options'] as _i5.OptionsEndpoint)
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
              type: _i1.getType<_i10.ProjectOptions>(),
              nullable: false,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['project'] as _i6.ProjectEndpoint).createProject(
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
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['project'] as _i6.ProjectEndpoint).deleteProject(
                    session,
                    params['id'],
                  ),
        ),
        'getProjects': _i1.MethodConnector(
          name: 'getProjects',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['project'] as _i6.ProjectEndpoint)
                  .getProjects(session),
        ),
        'getProject': _i1.MethodConnector(
          name: 'getProject',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['project'] as _i6.ProjectEndpoint).getProject(
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
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['project'] as _i6.ProjectEndpoint)
                  .addGeneToProject(
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
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['project'] as _i6.ProjectEndpoint)
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
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['project'] as _i6.ProjectEndpoint)
                  .addGenesToProject(
                    session,
                    params['id'],
                    params['genes'],
                  ),
        ),
        'setGeneById': _i1.MethodConnector(
          name: 'setGeneById',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'genomeId': _i1.ParameterDescription(
              name: 'genomeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['project'] as _i6.ProjectEndpoint).setGeneById(
                    session,
                    params['id'],
                    params['genomeId'],
                  ),
        ),
        'setSnpById': _i1.MethodConnector(
          name: 'setSnpById',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'snpId': _i1.ParameterDescription(
              name: 'snpId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['project'] as _i6.ProjectEndpoint).setSnpById(
                    session,
                    params['id'],
                    params['snpId'],
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
          params: {
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['settings'] as _i7.SettingsEndpoint).getSettings(
                    session,
                    params['password'],
                  ),
        ),
        'updateSettings': _i1.MethodConnector(
          name: 'updateSettings',
          params: {
            'settings': _i1.ParameterDescription(
              name: 'settings',
              type: _i1.getType<_i11.Settings>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['settings'] as _i7.SettingsEndpoint)
                  .updateSettings(
                    session,
                    params['settings'],
                  ),
        ),
      },
    );
  }

  @override
  _i1.FutureCallDispatch? get futureCalls {
    return _i12.FutureCalls();
  }
}
