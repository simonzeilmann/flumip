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
import 'package:flumip_server/src/generated/custom_snp_request_dto.dart'
    as _iiiv2d81;
import 'package:flumip_server/src/generated/future_calls.dart' as _i9339m0o;
import 'package:flumip_server/src/generated/genome.dart' as _i2jfp72f;
import 'package:flumip_server/src/generated/project_options.dart' as _i83mfwb1;
import 'package:flumip_server/src/generated/settings.dart' as _iycfx74a;
import 'package:serverpod/serverpod.dart' as _is;
import '../endpoints/auth_endpoint.dart' as _iyggisn2;
import '../endpoints/file_endpoint.dart' as _iiw2d7cj;
import '../endpoints/genome_endpoint.dart' as _ivwv8mg9;
import '../endpoints/mipgen_endpoint.dart' as _iw1n0ioe;
import '../endpoints/options_endpoint.dart' as _il08k6cm;
import '../endpoints/project_endpoint.dart' as _iemg8ri2;
import '../endpoints/search_endpoint.dart' as _ipmmezh5;
import '../endpoints/settings_endpoint.dart' as _ivmxe84z;
import '../endpoints/snp_endpoint.dart' as _idyrhezd;
export 'future_calls.dart' show ServerpodFutureCallsGetter;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'auth': _iyggisn2.AuthEndpoint()..initialize(server, 'auth', null),
      'file': _iiw2d7cj.FileEndpoint()..initialize(server, 'file', null),
      'genome': _ivwv8mg9.GenomeEndpoint()..initialize(server, 'genome', null),
      'mipgen': _iw1n0ioe.MipgenEndpoint()..initialize(server, 'mipgen', null),
      'options': _il08k6cm.OptionsEndpoint()
        ..initialize(server, 'options', null),
      'project': _iemg8ri2.ProjectEndpoint()
        ..initialize(server, 'project', null),
      'search': _ipmmezh5.SearchEndpoint()..initialize(server, 'search', null),
      'settings': _ivmxe84z.SettingsEndpoint()
        ..initialize(server, 'settings', null),
      'snp': _idyrhezd.SnpEndpoint()..initialize(server, 'snp', null),
    };
    connectors['auth'] = _is.EndpointConnector(
      name: 'auth',
      endpoint: endpoints['auth']!,
      methodConnectors: {
        'config': _is.MethodConnector(
          name: 'config',
          params: {},
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['auth'] as _iyggisn2.AuthEndpoint).config(session),
        ),
        'me': _is.MethodConnector(
          name: 'me',
          params: {},
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['auth'] as _iyggisn2.AuthEndpoint).me(session),
        ),
        'logout': _is.MethodConnector(
          name: 'logout',
          params: {},
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['auth'] as _iyggisn2.AuthEndpoint).logout(session),
        ),
      },
    );
    connectors['file'] = _is.EndpointConnector(
      name: 'file',
      endpoint: endpoints['file']!,
      methodConnectors: {
        'deleteByProducts': _is.MethodConnector(
          name: 'deleteByProducts',
          params: {
            'projectID': _is.ParameterDescription(
              name: 'projectID',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['file'] as _iiw2d7cj.FileEndpoint).deleteByProducts(
                session,
                params['projectID'],
              ),
        ),
        'showSnpMipsResult': _is.MethodConnector(
          name: 'showSnpMipsResult',
          params: {
            'projectID': _is.ParameterDescription(
              name: 'projectID',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['file'] as _iiw2d7cj.FileEndpoint).showSnpMipsResult(
                session,
                params['projectID'],
              ),
        ),
        'showMipsResult': _is.MethodConnector(
          name: 'showMipsResult',
          params: {
            'projectID': _is.ParameterDescription(
              name: 'projectID',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['file'] as _iiw2d7cj.FileEndpoint).showMipsResult(
                session,
                params['projectID'],
              ),
        ),
        'showMipsProgress': _is.MethodConnector(
          name: 'showMipsProgress',
          params: {
            'projectID': _is.ParameterDescription(
              name: 'projectID',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['file'] as _iiw2d7cj.FileEndpoint).showMipsProgress(
                session,
                params['projectID'],
              ),
        ),
        'showUSCSTrack': _is.MethodConnector(
          name: 'showUSCSTrack',
          params: {
            'projectID': _is.ParameterDescription(
              name: 'projectID',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['file'] as _iiw2d7cj.FileEndpoint).showUSCSTrack(
                session,
                params['projectID'],
              ),
        ),
        'getUcscTrackToken': _is.MethodConnector(
          name: 'getUcscTrackToken',
          params: {
            'projectID': _is.ParameterDescription(
              name: 'projectID',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['file'] as _iiw2d7cj.FileEndpoint).getUcscTrackToken(
                session,
                params['projectID'],
              ),
        ),
        'listProjectFiles': _is.MethodConnector(
          name: 'listProjectFiles',
          params: {
            'projectID': _is.ParameterDescription(
              name: 'projectID',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['file'] as _iiw2d7cj.FileEndpoint).listProjectFiles(
                session,
                params['projectID'],
              ),
        ),
      },
    );
    connectors['genome'] = _is.EndpointConnector(
      name: 'genome',
      endpoint: endpoints['genome']!,
      methodConnectors: {
        'getGenome': _is.MethodConnector(
          name: 'getGenome',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['genome'] as _ivwv8mg9.GenomeEndpoint).getGenome(
                session,
                params['id'],
              ),
        ),
        'getAllGenomes': _is.MethodConnector(
          name: 'getAllGenomes',
          params: {},
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['genome'] as _ivwv8mg9.GenomeEndpoint).getAllGenomes(
                session,
              ),
        ),
        'updateGenome': _is.MethodConnector(
          name: 'updateGenome',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'genome': _is.ParameterDescription(
              name: 'genome',
              type: _is.getType<_i2jfp72f.Genome>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['genome'] as _ivwv8mg9.GenomeEndpoint).updateGenome(
                session,
                params['id'],
                params['genome'],
              ),
        ),
        'collectGenomes': _is.MethodConnector(
          name: 'collectGenomes',
          params: {},
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['genome'] as _ivwv8mg9.GenomeEndpoint).collectGenomes(
                session,
              ),
        ),
        'getSnp': _is.MethodConnector(
          name: 'getSnp',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['genome'] as _ivwv8mg9.GenomeEndpoint).getSnp(
                session,
                params['id'],
              ),
        ),
        'getAllSnpForGenome': _is.MethodConnector(
          name: 'getAllSnpForGenome',
          params: {
            'genomeId': _is.ParameterDescription(
              name: 'genomeId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['genome'] as _ivwv8mg9.GenomeEndpoint)
                  .getAllSnpForGenome(session, params['genomeId']),
        ),
        'getCategories': _is.MethodConnector(
          name: 'getCategories',
          params: {},
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['genome'] as _ivwv8mg9.GenomeEndpoint).getCategories(
                session,
              ),
        ),
        'getGenomeByCategory': _is.MethodConnector(
          name: 'getGenomeByCategory',
          params: {
            'category': _is.ParameterDescription(
              name: 'category',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['genome'] as _ivwv8mg9.GenomeEndpoint)
                  .getGenomeByCategory(session, params['category']),
        ),
        'indexFasta': _is.MethodConnector(
          name: 'indexFasta',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['genome'] as _ivwv8mg9.GenomeEndpoint).indexFasta(
                session,
                params['id'],
              ),
        ),
        'deleteFastaIndex': _is.MethodConnector(
          name: 'deleteFastaIndex',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['genome'] as _ivwv8mg9.GenomeEndpoint)
                  .deleteFastaIndex(session, params['id']),
        ),
      },
    );
    connectors['mipgen'] = _is.EndpointConnector(
      name: 'mipgen',
      endpoint: endpoints['mipgen']!,
      methodConnectors: {
        'createBedFile': _is.MethodConnector(
          name: 'createBedFile',
          params: {
            'projectID': _is.ParameterDescription(
              name: 'projectID',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['mipgen'] as _iw1n0ioe.MipgenEndpoint).createBedFile(
                session,
                params['projectID'],
              ),
        ),
        'generateMips': _is.MethodConnector(
          name: 'generateMips',
          params: {
            'projectID': _is.ParameterDescription(
              name: 'projectID',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'deleteExcessFiles': _is.ParameterDescription(
              name: 'deleteExcessFiles',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['mipgen'] as _iw1n0ioe.MipgenEndpoint).generateMips(
                session,
                params['projectID'],
                params['deleteExcessFiles'],
              ),
        ),
      },
    );
    connectors['options'] = _is.EndpointConnector(
      name: 'options',
      endpoint: endpoints['options']!,
      methodConnectors: {
        'createProjectOptions': _is.MethodConnector(
          name: 'createProjectOptions',
          params: {},
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['options'] as _il08k6cm.OptionsEndpoint)
                  .createProjectOptions(session),
        ),
        'insertProjectOptions': _is.MethodConnector(
          name: 'insertProjectOptions',
          params: {
            'options': _is.ParameterDescription(
              name: 'options',
              type: _is.getType<_i83mfwb1.ProjectOptions>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['options'] as _il08k6cm.OptionsEndpoint)
                  .insertProjectOptions(session, params['options']),
        ),
        'getProjectOptions': _is.MethodConnector(
          name: 'getProjectOptions',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['options'] as _il08k6cm.OptionsEndpoint)
                  .getProjectOptions(session, params['id']),
        ),
        'updateProjectOptions': _is.MethodConnector(
          name: 'updateProjectOptions',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'options': _is.ParameterDescription(
              name: 'options',
              type: _is.getType<_i83mfwb1.ProjectOptions>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['options'] as _il08k6cm.OptionsEndpoint)
                  .updateProjectOptions(
                    session,
                    params['id'],
                    params['options'],
                  ),
        ),
        'deleteProjectOptions': _is.MethodConnector(
          name: 'deleteProjectOptions',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['options'] as _il08k6cm.OptionsEndpoint)
                  .deleteProjectOptions(session, params['id']),
        ),
      },
    );
    connectors['project'] = _is.EndpointConnector(
      name: 'project',
      endpoint: endpoints['project']!,
      methodConnectors: {
        'createProject': _is.MethodConnector(
          name: 'createProject',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'options': _is.ParameterDescription(
              name: 'options',
              type: _is.getType<_i83mfwb1.ProjectOptions>(),
              nullable: false,
            ),
            'description': _is.ParameterDescription(
              name: 'description',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['project'] as _iemg8ri2.ProjectEndpoint).createProject(
                session,
                params['name'],
                params['options'],
                params['description'],
              ),
        ),
        'deleteProject': _is.MethodConnector(
          name: 'deleteProject',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['project'] as _iemg8ri2.ProjectEndpoint).deleteProject(
                session,
                params['id'],
              ),
        ),
        'getProjects': _is.MethodConnector(
          name: 'getProjects',
          params: {},
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['project'] as _iemg8ri2.ProjectEndpoint).getProjects(
                session,
              ),
        ),
        'getProject': _is.MethodConnector(
          name: 'getProject',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['project'] as _iemg8ri2.ProjectEndpoint).getProject(
                session,
                params['id'],
              ),
        ),
        'addGeneToProject': _is.MethodConnector(
          name: 'addGeneToProject',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'gene': _is.ParameterDescription(
              name: 'gene',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['project'] as _iemg8ri2.ProjectEndpoint)
                  .addGeneToProject(session, params['id'], params['gene']),
        ),
        'removeGeneFromProject': _is.MethodConnector(
          name: 'removeGeneFromProject',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'gene': _is.ParameterDescription(
              name: 'gene',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['project'] as _iemg8ri2.ProjectEndpoint)
                  .removeGeneFromProject(session, params['id'], params['gene']),
        ),
        'addGenesToProject': _is.MethodConnector(
          name: 'addGenesToProject',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'genes': _is.ParameterDescription(
              name: 'genes',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['project'] as _iemg8ri2.ProjectEndpoint)
                  .addGenesToProject(session, params['id'], params['genes']),
        ),
        'setGeneById': _is.MethodConnector(
          name: 'setGeneById',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'genomeId': _is.ParameterDescription(
              name: 'genomeId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['project'] as _iemg8ri2.ProjectEndpoint).setGeneById(
                session,
                params['id'],
                params['genomeId'],
              ),
        ),
        'setEmailNotification': _is.MethodConnector(
          name: 'setEmailNotification',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'enabled': _is.ParameterDescription(
              name: 'enabled',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['project'] as _iemg8ri2.ProjectEndpoint)
                  .setEmailNotification(
                    session,
                    params['id'],
                    params['enabled'],
                  ),
        ),
        'setProjectOwner': _is.MethodConnector(
          name: 'setProjectOwner',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'ownerId': _is.ParameterDescription(
              name: 'ownerId',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['project'] as _iemg8ri2.ProjectEndpoint)
                  .setProjectOwner(session, params['id'], params['ownerId']),
        ),
        'assignableOwners': _is.MethodConnector(
          name: 'assignableOwners',
          params: {},
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['project'] as _iemg8ri2.ProjectEndpoint)
                  .assignableOwners(session),
        ),
        'notificationsAvailable': _is.MethodConnector(
          name: 'notificationsAvailable',
          params: {},
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['project'] as _iemg8ri2.ProjectEndpoint)
                  .notificationsAvailable(session),
        ),
        'setSnpById': _is.MethodConnector(
          name: 'setSnpById',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'snpId': _is.ParameterDescription(
              name: 'snpId',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['project'] as _iemg8ri2.ProjectEndpoint).setSnpById(
                session,
                params['id'],
                params['snpId'],
              ),
        ),
      },
    );
    connectors['search'] = _is.EndpointConnector(
      name: 'search',
      endpoint: endpoints['search']!,
      methodConnectors: {
        'search': _is.MethodConnector(
          name: 'search',
          params: {
            'query': _is.ParameterDescription(
              name: 'query',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['search'] as _ipmmezh5.SearchEndpoint).search(
                session,
                params['query'],
              ),
        ),
      },
    );
    connectors['settings'] = _is.EndpointConnector(
      name: 'settings',
      endpoint: endpoints['settings']!,
      methodConnectors: {
        'userSettings': _is.MethodConnector(
          name: 'userSettings',
          params: {},
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['settings'] as _ivmxe84z.SettingsEndpoint)
                  .userSettings(session),
        ),
        'getSettings': _is.MethodConnector(
          name: 'getSettings',
          params: {
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['settings'] as _ivmxe84z.SettingsEndpoint).getSettings(
                session,
                params['password'],
              ),
        ),
        'updateSettings': _is.MethodConnector(
          name: 'updateSettings',
          params: {
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'settings': _is.ParameterDescription(
              name: 'settings',
              type: _is.getType<_iycfx74a.Settings>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['settings'] as _ivmxe84z.SettingsEndpoint)
                  .updateSettings(
                    session,
                    params['password'],
                    params['settings'],
                  ),
        ),
        'setOidcClientSecret': _is.MethodConnector(
          name: 'setOidcClientSecret',
          params: {
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'secret': _is.ParameterDescription(
              name: 'secret',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['settings'] as _ivmxe84z.SettingsEndpoint)
                  .setOidcClientSecret(
                    session,
                    params['password'],
                    params['secret'],
                  ),
        ),
        'setSmtpPassword': _is.MethodConnector(
          name: 'setSmtpPassword',
          params: {
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'secret': _is.ParameterDescription(
              name: 'secret',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['settings'] as _ivmxe84z.SettingsEndpoint)
                  .setSmtpPassword(
                    session,
                    params['password'],
                    params['secret'],
                  ),
        ),
        'smtpPasswordConfigured': _is.MethodConnector(
          name: 'smtpPasswordConfigured',
          params: {
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['settings'] as _ivmxe84z.SettingsEndpoint)
                  .smtpPasswordConfigured(session, params['password']),
        ),
        'getAuthAdminStatus': _is.MethodConnector(
          name: 'getAuthAdminStatus',
          params: {
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['settings'] as _ivmxe84z.SettingsEndpoint)
                  .getAuthAdminStatus(session, params['password']),
        ),
        'sendTestMail': _is.MethodConnector(
          name: 'sendTestMail',
          params: {
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'to': _is.ParameterDescription(
              name: 'to',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['settings'] as _ivmxe84z.SettingsEndpoint)
                  .sendTestMail(session, params['password'], params['to']),
        ),
      },
    );
    connectors['snp'] = _is.EndpointConnector(
      name: 'snp',
      endpoint: endpoints['snp']!,
      methodConnectors: {
        'listSnpsForGenome': _is.MethodConnector(
          name: 'listSnpsForGenome',
          params: {
            'genomeId': _is.ParameterDescription(
              name: 'genomeId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['snp'] as _idyrhezd.SnpEndpoint).listSnpsForGenome(
                session,
                params['genomeId'],
              ),
        ),
        'listMySnps': _is.MethodConnector(
          name: 'listMySnps',
          params: {},
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['snp'] as _idyrhezd.SnpEndpoint).listMySnps(session),
        ),
        'createUpload': _is.MethodConnector(
          name: 'createUpload',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_iiiv2d81.CustomSnpRequestDto>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['snp'] as _idyrhezd.SnpEndpoint).createUpload(
                session,
                params['request'],
              ),
        ),
        'finishUpload': _is.MethodConnector(
          name: 'finishUpload',
          params: {
            'snpId': _is.ParameterDescription(
              name: 'snpId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['snp'] as _idyrhezd.SnpEndpoint).finishUpload(
                session,
                params['snpId'],
              ),
        ),
        'cancelUpload': _is.MethodConnector(
          name: 'cancelUpload',
          params: {
            'snpId': _is.ParameterDescription(
              name: 'snpId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['snp'] as _idyrhezd.SnpEndpoint).cancelUpload(
                session,
                params['snpId'],
              ),
        ),
        'importFromUrls': _is.MethodConnector(
          name: 'importFromUrls',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_iiiv2d81.CustomSnpRequestDto>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['snp'] as _idyrhezd.SnpEndpoint).importFromUrls(
                session,
                params['request'],
              ),
        ),
        'retryImport': _is.MethodConnector(
          name: 'retryImport',
          params: {
            'snpId': _is.ParameterDescription(
              name: 'snpId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['snp'] as _idyrhezd.SnpEndpoint).retryImport(
                session,
                params['snpId'],
              ),
        ),
        'setShared': _is.MethodConnector(
          name: 'setShared',
          params: {
            'snpId': _is.ParameterDescription(
              name: 'snpId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'shared': _is.ParameterDescription(
              name: 'shared',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['snp'] as _idyrhezd.SnpEndpoint).setShared(
                session,
                params['snpId'],
                params['shared'],
              ),
        ),
        'renameSnp': _is.MethodConnector(
          name: 'renameSnp',
          params: {
            'snpId': _is.ParameterDescription(
              name: 'snpId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'description': _is.ParameterDescription(
              name: 'description',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['snp'] as _idyrhezd.SnpEndpoint).renameSnp(
                session,
                params['snpId'],
                params['name'],
                params['description'],
              ),
        ),
        'snpUsage': _is.MethodConnector(
          name: 'snpUsage',
          params: {
            'snpId': _is.ParameterDescription(
              name: 'snpId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['snp'] as _idyrhezd.SnpEndpoint).snpUsage(
                session,
                params['snpId'],
              ),
        ),
        'deleteCustomSnp': _is.MethodConnector(
          name: 'deleteCustomSnp',
          params: {
            'snpId': _is.ParameterDescription(
              name: 'snpId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['snp'] as _idyrhezd.SnpEndpoint).deleteCustomSnp(
                session,
                params['snpId'],
              ),
        ),
        'deleteSnpAsAdmin': _is.MethodConnector(
          name: 'deleteSnpAsAdmin',
          params: {
            'snpId': _is.ParameterDescription(
              name: 'snpId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'settingsPassword': _is.ParameterDescription(
              name: 'settingsPassword',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'force': _is.ParameterDescription(
              name: 'force',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['snp'] as _idyrhezd.SnpEndpoint).deleteSnpAsAdmin(
                session,
                params['snpId'],
                params['settingsPassword'],
                force: params['force'],
              ),
        ),
        'collectCustomSnps': _is.MethodConnector(
          name: 'collectCustomSnps',
          params: {},
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['snp'] as _idyrhezd.SnpEndpoint).collectCustomSnps(
                session,
              ),
        ),
      },
    );
  }

  @override
  _is.FutureCallDispatch? get futureCalls {
    return _i9339m0o.FutureCalls();
  }
}
