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
import '../endpoints/auth_endpoint.dart' as _i2;
import '../endpoints/file_endpoint.dart' as _i3;
import '../endpoints/genome_endpoint.dart' as _i4;
import '../endpoints/mipgen_endpoint.dart' as _i5;
import '../endpoints/options_endpoint.dart' as _i6;
import '../endpoints/project_endpoint.dart' as _i7;
import '../endpoints/settings_endpoint.dart' as _i8;
import '../endpoints/snp_endpoint.dart' as _i9;
import 'package:flumip_server/src/generated/genome.dart' as _i10;
import 'package:flumip_server/src/generated/project_options.dart' as _i11;
import 'package:flumip_server/src/generated/settings.dart' as _i12;
import 'package:flumip_server/src/generated/custom_snp_request_dto.dart'
    as _i13;
import 'package:flumip_server/src/generated/future_calls.dart' as _i14;
export 'future_calls.dart' show ServerpodFutureCallsGetter;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'auth': _i2.AuthEndpoint()
        ..initialize(
          server,
          'auth',
          null,
        ),
      'file': _i3.FileEndpoint()
        ..initialize(
          server,
          'file',
          null,
        ),
      'genome': _i4.GenomeEndpoint()
        ..initialize(
          server,
          'genome',
          null,
        ),
      'mipgen': _i5.MipgenEndpoint()
        ..initialize(
          server,
          'mipgen',
          null,
        ),
      'options': _i6.OptionsEndpoint()
        ..initialize(
          server,
          'options',
          null,
        ),
      'project': _i7.ProjectEndpoint()
        ..initialize(
          server,
          'project',
          null,
        ),
      'settings': _i8.SettingsEndpoint()
        ..initialize(
          server,
          'settings',
          null,
        ),
      'snp': _i9.SnpEndpoint()
        ..initialize(
          server,
          'snp',
          null,
        ),
    };
    connectors['auth'] = _i1.EndpointConnector(
      name: 'auth',
      endpoint: endpoints['auth']!,
      methodConnectors: {
        'config': _i1.MethodConnector(
          name: 'config',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _i2.AuthEndpoint).config(session),
        ),
        'me': _i1.MethodConnector(
          name: 'me',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i2.AuthEndpoint).me(session),
        ),
        'logout': _i1.MethodConnector(
          name: 'logout',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _i2.AuthEndpoint).logout(session),
        ),
      },
    );
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
                  (endpoints['file'] as _i3.FileEndpoint).deleteByProducts(
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
                  (endpoints['file'] as _i3.FileEndpoint).showSnpMipsResult(
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
              ) async => (endpoints['file'] as _i3.FileEndpoint).showMipsResult(
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
                  (endpoints['file'] as _i3.FileEndpoint).showMipsProgress(
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
              ) async => (endpoints['file'] as _i3.FileEndpoint).showUSCSTrack(
                session,
                params['projectID'],
              ),
        ),
        'getUcscTrackToken': _i1.MethodConnector(
          name: 'getUcscTrackToken',
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
                  (endpoints['file'] as _i3.FileEndpoint).getUcscTrackToken(
                    session,
                    params['projectID'],
                  ),
        ),
        'listProjectFiles': _i1.MethodConnector(
          name: 'listProjectFiles',
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
                  (endpoints['file'] as _i3.FileEndpoint).listProjectFiles(
                    session,
                    params['projectID'],
                  ),
        ),
        'requireProject': _i1.MethodConnector(
          name: 'requireProject',
          params: {
            'projectId': _i1.ParameterDescription(
              name: 'projectId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['file'] as _i3.FileEndpoint).requireProject(
                session,
                params['projectId'],
              ),
        ),
        'requireProjectOptions': _i1.MethodConnector(
          name: 'requireProjectOptions',
          params: {
            'optionsId': _i1.ParameterDescription(
              name: 'optionsId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['file'] as _i3.FileEndpoint).requireProjectOptions(
                    session,
                    params['optionsId'],
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
              ) async => (endpoints['genome'] as _i4.GenomeEndpoint).getGenome(
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
              ) async => (endpoints['genome'] as _i4.GenomeEndpoint)
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
              type: _i1.getType<_i10.Genome>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['genome'] as _i4.GenomeEndpoint).updateGenome(
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
              ) async => (endpoints['genome'] as _i4.GenomeEndpoint)
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
              ) async => (endpoints['genome'] as _i4.GenomeEndpoint).getSnp(
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
              ) async => (endpoints['genome'] as _i4.GenomeEndpoint)
                  .getAllSnpForGenome(
                    session,
                    params['genomeId'],
                  ),
        ),
        'getCategories': _i1.MethodConnector(
          name: 'getCategories',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['genome'] as _i4.GenomeEndpoint)
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
              ) async => (endpoints['genome'] as _i4.GenomeEndpoint)
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
              ) async => (endpoints['genome'] as _i4.GenomeEndpoint).indexFasta(
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
                  (endpoints['genome'] as _i4.GenomeEndpoint).deleteFastaIndex(
                    session,
                    params['id'],
                  ),
        ),
        'requireProject': _i1.MethodConnector(
          name: 'requireProject',
          params: {
            'projectId': _i1.ParameterDescription(
              name: 'projectId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['genome'] as _i4.GenomeEndpoint).requireProject(
                    session,
                    params['projectId'],
                  ),
        ),
        'requireProjectOptions': _i1.MethodConnector(
          name: 'requireProjectOptions',
          params: {
            'optionsId': _i1.ParameterDescription(
              name: 'optionsId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['genome'] as _i4.GenomeEndpoint)
                  .requireProjectOptions(
                    session,
                    params['optionsId'],
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
                  (endpoints['mipgen'] as _i5.MipgenEndpoint).createBedFile(
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
                  (endpoints['mipgen'] as _i5.MipgenEndpoint).generateMips(
                    session,
                    params['projectID'],
                    params['deleteExcessFiles'],
                  ),
        ),
        'requireProject': _i1.MethodConnector(
          name: 'requireProject',
          params: {
            'projectId': _i1.ParameterDescription(
              name: 'projectId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['mipgen'] as _i5.MipgenEndpoint).requireProject(
                    session,
                    params['projectId'],
                  ),
        ),
        'requireProjectOptions': _i1.MethodConnector(
          name: 'requireProjectOptions',
          params: {
            'optionsId': _i1.ParameterDescription(
              name: 'optionsId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mipgen'] as _i5.MipgenEndpoint)
                  .requireProjectOptions(
                    session,
                    params['optionsId'],
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
              ) async => (endpoints['options'] as _i6.OptionsEndpoint)
                  .createProjectOptions(session),
        ),
        'insertProjectOptions': _i1.MethodConnector(
          name: 'insertProjectOptions',
          params: {
            'options': _i1.ParameterDescription(
              name: 'options',
              type: _i1.getType<_i11.ProjectOptions>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['options'] as _i6.OptionsEndpoint)
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
              ) async => (endpoints['options'] as _i6.OptionsEndpoint)
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
              type: _i1.getType<_i11.ProjectOptions>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['options'] as _i6.OptionsEndpoint)
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
              ) async => (endpoints['options'] as _i6.OptionsEndpoint)
                  .deleteProjectOptions(
                    session,
                    params['id'],
                  ),
        ),
        'requireProject': _i1.MethodConnector(
          name: 'requireProject',
          params: {
            'projectId': _i1.ParameterDescription(
              name: 'projectId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['options'] as _i6.OptionsEndpoint).requireProject(
                    session,
                    params['projectId'],
                  ),
        ),
        'requireProjectOptions': _i1.MethodConnector(
          name: 'requireProjectOptions',
          params: {
            'optionsId': _i1.ParameterDescription(
              name: 'optionsId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['options'] as _i6.OptionsEndpoint)
                  .requireProjectOptions(
                    session,
                    params['optionsId'],
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
              type: _i1.getType<_i11.ProjectOptions>(),
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
                  (endpoints['project'] as _i7.ProjectEndpoint).createProject(
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
                  (endpoints['project'] as _i7.ProjectEndpoint).deleteProject(
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
              ) async => (endpoints['project'] as _i7.ProjectEndpoint)
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
                  (endpoints['project'] as _i7.ProjectEndpoint).getProject(
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
              ) async => (endpoints['project'] as _i7.ProjectEndpoint)
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
              ) async => (endpoints['project'] as _i7.ProjectEndpoint)
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
              ) async => (endpoints['project'] as _i7.ProjectEndpoint)
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
                  (endpoints['project'] as _i7.ProjectEndpoint).setGeneById(
                    session,
                    params['id'],
                    params['genomeId'],
                  ),
        ),
        'setEmailNotification': _i1.MethodConnector(
          name: 'setEmailNotification',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'enabled': _i1.ParameterDescription(
              name: 'enabled',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['project'] as _i7.ProjectEndpoint)
                  .setEmailNotification(
                    session,
                    params['id'],
                    params['enabled'],
                  ),
        ),
        'setProjectOwner': _i1.MethodConnector(
          name: 'setProjectOwner',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'ownerId': _i1.ParameterDescription(
              name: 'ownerId',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['project'] as _i7.ProjectEndpoint).setProjectOwner(
                    session,
                    params['id'],
                    params['ownerId'],
                  ),
        ),
        'assignableOwners': _i1.MethodConnector(
          name: 'assignableOwners',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['project'] as _i7.ProjectEndpoint)
                  .assignableOwners(session),
        ),
        'notificationsAvailable': _i1.MethodConnector(
          name: 'notificationsAvailable',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['project'] as _i7.ProjectEndpoint)
                  .notificationsAvailable(session),
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
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['project'] as _i7.ProjectEndpoint).setSnpById(
                    session,
                    params['id'],
                    params['snpId'],
                  ),
        ),
        'requireProject': _i1.MethodConnector(
          name: 'requireProject',
          params: {
            'projectId': _i1.ParameterDescription(
              name: 'projectId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['project'] as _i7.ProjectEndpoint).requireProject(
                    session,
                    params['projectId'],
                  ),
        ),
        'requireProjectOptions': _i1.MethodConnector(
          name: 'requireProjectOptions',
          params: {
            'optionsId': _i1.ParameterDescription(
              name: 'optionsId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['project'] as _i7.ProjectEndpoint)
                  .requireProjectOptions(
                    session,
                    params['optionsId'],
                  ),
        ),
      },
    );
    connectors['settings'] = _i1.EndpointConnector(
      name: 'settings',
      endpoint: endpoints['settings']!,
      methodConnectors: {
        'userSettings': _i1.MethodConnector(
          name: 'userSettings',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['settings'] as _i8.SettingsEndpoint)
                  .userSettings(session),
        ),
        'getSettings': _i1.MethodConnector(
          name: 'getSettings',
          params: {
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['settings'] as _i8.SettingsEndpoint).getSettings(
                    session,
                    params['password'],
                  ),
        ),
        'updateSettings': _i1.MethodConnector(
          name: 'updateSettings',
          params: {
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'settings': _i1.ParameterDescription(
              name: 'settings',
              type: _i1.getType<_i12.Settings>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['settings'] as _i8.SettingsEndpoint)
                  .updateSettings(
                    session,
                    params['password'],
                    params['settings'],
                  ),
        ),
        'setOidcClientSecret': _i1.MethodConnector(
          name: 'setOidcClientSecret',
          params: {
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'secret': _i1.ParameterDescription(
              name: 'secret',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['settings'] as _i8.SettingsEndpoint)
                  .setOidcClientSecret(
                    session,
                    params['password'],
                    params['secret'],
                  ),
        ),
        'getAuthAdminStatus': _i1.MethodConnector(
          name: 'getAuthAdminStatus',
          params: {
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['settings'] as _i8.SettingsEndpoint)
                  .getAuthAdminStatus(
                    session,
                    params['password'],
                  ),
        ),
        'sendTestMail': _i1.MethodConnector(
          name: 'sendTestMail',
          params: {
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'to': _i1.ParameterDescription(
              name: 'to',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['settings'] as _i8.SettingsEndpoint).sendTestMail(
                    session,
                    params['password'],
                    params['to'],
                  ),
        ),
      },
    );
    connectors['snp'] = _i1.EndpointConnector(
      name: 'snp',
      endpoint: endpoints['snp']!,
      methodConnectors: {
        'listSnpsForGenome': _i1.MethodConnector(
          name: 'listSnpsForGenome',
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
              ) async =>
                  (endpoints['snp'] as _i9.SnpEndpoint).listSnpsForGenome(
                    session,
                    params['genomeId'],
                  ),
        ),
        'listMySnps': _i1.MethodConnector(
          name: 'listMySnps',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['snp'] as _i9.SnpEndpoint).listMySnps(session),
        ),
        'createUpload': _i1.MethodConnector(
          name: 'createUpload',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i13.CustomSnpRequestDto>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['snp'] as _i9.SnpEndpoint).createUpload(
                session,
                params['request'],
              ),
        ),
        'finishUpload': _i1.MethodConnector(
          name: 'finishUpload',
          params: {
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
              ) async => (endpoints['snp'] as _i9.SnpEndpoint).finishUpload(
                session,
                params['snpId'],
              ),
        ),
        'cancelUpload': _i1.MethodConnector(
          name: 'cancelUpload',
          params: {
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
              ) async => (endpoints['snp'] as _i9.SnpEndpoint).cancelUpload(
                session,
                params['snpId'],
              ),
        ),
        'importFromUrls': _i1.MethodConnector(
          name: 'importFromUrls',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i13.CustomSnpRequestDto>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['snp'] as _i9.SnpEndpoint).importFromUrls(
                session,
                params['request'],
              ),
        ),
        'retryImport': _i1.MethodConnector(
          name: 'retryImport',
          params: {
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
              ) async => (endpoints['snp'] as _i9.SnpEndpoint).retryImport(
                session,
                params['snpId'],
              ),
        ),
        'setShared': _i1.MethodConnector(
          name: 'setShared',
          params: {
            'snpId': _i1.ParameterDescription(
              name: 'snpId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'shared': _i1.ParameterDescription(
              name: 'shared',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['snp'] as _i9.SnpEndpoint).setShared(
                session,
                params['snpId'],
                params['shared'],
              ),
        ),
        'renameSnp': _i1.MethodConnector(
          name: 'renameSnp',
          params: {
            'snpId': _i1.ParameterDescription(
              name: 'snpId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['snp'] as _i9.SnpEndpoint).renameSnp(
                session,
                params['snpId'],
                params['name'],
                params['description'],
              ),
        ),
        'snpUsage': _i1.MethodConnector(
          name: 'snpUsage',
          params: {
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
              ) async => (endpoints['snp'] as _i9.SnpEndpoint).snpUsage(
                session,
                params['snpId'],
              ),
        ),
        'deleteCustomSnp': _i1.MethodConnector(
          name: 'deleteCustomSnp',
          params: {
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
              ) async => (endpoints['snp'] as _i9.SnpEndpoint).deleteCustomSnp(
                session,
                params['snpId'],
              ),
        ),
        'deleteSnpAsAdmin': _i1.MethodConnector(
          name: 'deleteSnpAsAdmin',
          params: {
            'snpId': _i1.ParameterDescription(
              name: 'snpId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'settingsPassword': _i1.ParameterDescription(
              name: 'settingsPassword',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'force': _i1.ParameterDescription(
              name: 'force',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['snp'] as _i9.SnpEndpoint).deleteSnpAsAdmin(
                session,
                params['snpId'],
                params['settingsPassword'],
                force: params['force'],
              ),
        ),
        'collectCustomSnps': _i1.MethodConnector(
          name: 'collectCustomSnps',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['snp'] as _i9.SnpEndpoint)
                  .collectCustomSnps(session),
        ),
        'requireProject': _i1.MethodConnector(
          name: 'requireProject',
          params: {
            'projectId': _i1.ParameterDescription(
              name: 'projectId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['snp'] as _i9.SnpEndpoint).requireProject(
                session,
                params['projectId'],
              ),
        ),
        'requireProjectOptions': _i1.MethodConnector(
          name: 'requireProjectOptions',
          params: {
            'optionsId': _i1.ParameterDescription(
              name: 'optionsId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['snp'] as _i9.SnpEndpoint).requireProjectOptions(
                    session,
                    params['optionsId'],
                  ),
        ),
      },
    );
  }

  @override
  _i1.FutureCallDispatch? get futureCalls {
    return _i14.FutureCalls();
  }
}
