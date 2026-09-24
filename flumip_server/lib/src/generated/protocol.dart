/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flumip_server/src/generated/flumip_user_dto.dart' as _ipn4uvlw;
import 'package:flumip_server/src/generated/genome.dart' as _i2jfp72f;
import 'package:flumip_server/src/generated/project.dart' as _idblq1ye;
import 'package:flumip_server/src/generated/project_file_dto.dart' as _iaw3nq06;
import 'package:flumip_server/src/generated/search_hit_dto.dart' as _ih1e1b1z;
import 'package:flumip_server/src/generated/snp.dart' as _icqkl7md;
import 'package:flumip_server/src/generated/snp_usage_dto.dart' as _ivyy2rnq;
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'auth_admin_status_dto.dart' as _ilu62sh8;
import 'auth_api_token.dart' as _i1qrzley;
import 'auth_config_dto.dart' as _i3pxz8st;
import 'auth_flow.dart' as _iopq1986;
import 'auth_session.dart' as _i1cqtl3u;
import 'auth_user_dto.dart' as _i9fqmmja;
import 'custom_snp_request_dto.dart' as _i50r13ns;
import 'exceptions.dart' as _ifprdzfb;
import 'exceptions/argument_exception.dart' as _ix5u8j9t;
import 'exceptions/flumip_file_not_found_exception.dart' as _iua77lfj;
import 'exceptions/GenomeExceptions/bed_creation_exception.dart' as _il9ya82w;
import 'exceptions/project_access_denied_exception.dart' as _iq9wx7jy;
import 'flumip_user.dart' as _ijkt6zbv;
import 'flumip_user_dto.dart' as _im3lr0ct;
import 'genome.dart' as _ik3s3pjn;
import 'project.dart' as _ifiazq2p;
import 'project_file_dto.dart' as _ip1wvjxo;
import 'project_options.dart' as _i4kq7s26;
import 'score_method.dart' as _iootg8bv;
import 'search_hit_dto.dart' as _iy8r37ur;
import 'search_hit_kind.dart' as _ia4xis23;
import 'settings.dart' as _ibmr8d9c;
import 'snp.dart' as _ip0fcn2o;
import 'snp_import_status.dart' as _iq9n7xnd;
import 'snp_usage_dto.dart' as _i8stnodc;
import 'user_settings_dto.dart' as _igo562ik;
export 'auth_admin_status_dto.dart';
export 'auth_api_token.dart';
export 'auth_config_dto.dart';
export 'auth_flow.dart';
export 'auth_session.dart';
export 'auth_user_dto.dart';
export 'custom_snp_request_dto.dart';
export 'exceptions.dart';
export 'exceptions/GenomeExceptions/bed_creation_exception.dart';
export 'exceptions/argument_exception.dart';
export 'exceptions/flumip_file_not_found_exception.dart';
export 'exceptions/project_access_denied_exception.dart';
export 'flumip_user.dart';
export 'flumip_user_dto.dart';
export 'genome.dart';
export 'project.dart';
export 'project_file_dto.dart';
export 'project_options.dart';
export 'score_method.dart';
export 'search_hit_dto.dart';
export 'search_hit_kind.dart';
export 'settings.dart';
export 'snp.dart';
export 'snp_import_status.dart';
export 'snp_usage_dto.dart';
export 'user_settings_dto.dart';

class Protocol extends _is.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    _isp.TableDefinition(
      name: 'auth_api_token',
      dartName: 'AuthApiToken',
      schema: 'public',
      module: 'flumip',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'authSessionId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'tokenHash',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'email',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'isAdmin',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'created',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'expires',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'auth_api_token_fk_0',
          columns: ['authSessionId'],
          referenceTable: 'auth_session',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'auth_api_token_hash_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'tokenHash',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'auth_api_token_session_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'authSessionId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'auth_api_token_expires_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'expires',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'auth_flow',
      dartName: 'AuthFlow',
      schema: 'public',
      module: 'flumip',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'state',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'codeVerifier',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'nonce',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'redirectUri',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'created',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'expires',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'auth_flow_state_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'state',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'auth_flow_expires_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'expires',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'auth_session',
      dartName: 'AuthSession',
      schema: 'public',
      module: 'flumip',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'cookieHash',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'email',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'isAdmin',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'created',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'expires',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'lastSeen',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'auth_session_fk_0',
          columns: ['userId'],
          referenceTable: 'flumip_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'auth_session_cookie_hash_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'cookieHash',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'auth_session_expires_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'expires',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'flumip_user',
      dartName: 'FlumipUser',
      schema: 'public',
      module: 'flumip',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'email',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'subject',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'issuer',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'displayName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'',
        ),
        _isp.ColumnDefinition(
          name: 'created',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'lastLogin',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'flumip_user_identity_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'issuer',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'subject',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'flumip_user_email_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'email',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'genome',
      dartName: 'Genome',
      schema: 'public',
      module: 'flumip',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'description',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'',
        ),
        _isp.ColumnDefinition(
          name: 'path',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'fastaPath',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'refPath',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'snpFolder',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'category',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'active',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'indexed',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'indexing',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'indexPID',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'indexResults',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'size',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
      ],
      foreignKeys: [],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'project',
      dartName: 'Project',
      schema: 'public',
      module: 'flumip',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'folderName',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'description',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'',
        ),
        _isp.ColumnDefinition(
          name: 'genome',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'snp',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'created',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'owner',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'department',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'trackToken',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'genes',
          columnType: _isp.ColumnType.json,
          isNullable: true,
          dartType: 'List<String>?',
        ),
        _isp.ColumnDefinition(
          name: 'bedFileCreated',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'active',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'pid',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'size',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'emailNotification',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'options',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'started',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'completedIn',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'Duration?',
        ),
        _isp.ColumnDefinition(
          name: 'error',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'',
        ),
        _isp.ColumnDefinition(
          name: 'warning',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'',
        ),
        _isp.ColumnDefinition(
          name: 'cleanup',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'project_fk_0',
          columns: ['snp'],
          referenceTable: 'snp',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'project_fk_1',
          columns: ['owner'],
          referenceTable: 'flumip_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'project_owner_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'owner',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'project_track_token_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'trackToken',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'project_options',
      dartName: 'ProjectOptions',
      schema: 'public',
      module: 'flumip',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'minCaptureSize',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '162',
        ),
        _isp.ColumnDefinition(
          name: 'maxCaptureSize',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '162',
        ),
        _isp.ColumnDefinition(
          name: 'armLengths',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'armLengthSums',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'40,41,42,43,44,45\'',
        ),
        _isp.ColumnDefinition(
          name: 'extMinLength',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '16',
        ),
        _isp.ColumnDefinition(
          name: 'extMaxLength',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '18',
        ),
        _isp.ColumnDefinition(
          name: 'ligMinLength',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '18',
        ),
        _isp.ColumnDefinition(
          name: 'tagSizes',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'5,0\'',
        ),
        _isp.ColumnDefinition(
          name: 'maskedArmThreshold',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '0.5',
        ),
        _isp.ColumnDefinition(
          name: 'targetArmCopy',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '20',
        ),
        _isp.ColumnDefinition(
          name: 'maxArmCopyProduct',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '75',
        ),
        _isp.ColumnDefinition(
          name: 'trf',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'genomeDir',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'featureFlank',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'captureIncrement',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '5',
        ),
        _isp.ColumnDefinition(
          name: 'logisticHeuristic',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'maxMipOverlap',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '30',
        ),
        _isp.ColumnDefinition(
          name: 'startingMipOverlap',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'checkCopyNumber',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'sealBothStrands',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'halfSealBothStrands',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'doubleTileStrandUnaware',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'doubleTileStrandsSeparately',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'scoreMethod',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ScoreMethod',
          columnDefault: '\'logistic\'',
        ),
        _isp.ColumnDefinition(
          name: 'logisticOptimalScore',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '0.98',
        ),
        _isp.ColumnDefinition(
          name: 'svrOptimalScore',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '2.2',
        ),
        _isp.ColumnDefinition(
          name: 'logisticPriorityScore',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '0.9',
        ),
        _isp.ColumnDefinition(
          name: 'svrPriorityScore',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '1.5',
        ),
        _isp.ColumnDefinition(
          name: 'silentMode',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'bwaThreads',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
      ],
      foreignKeys: [],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'settings',
      dartName: 'Settings',
      schema: 'public',
      module: 'flumip',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'demoMode',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'demoModeRetentionHours',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '168',
        ),
        _isp.ColumnDefinition(
          name: 'baseDir',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'/opt/flumip\'',
        ),
        _isp.ColumnDefinition(
          name: 'projectDir',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'/opt/flumip/projects\'',
        ),
        _isp.ColumnDefinition(
          name: 'genomeDir',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'/opt/flumip/data/genomes\'',
        ),
        _isp.ColumnDefinition(
          name: 'customSnpDir',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'/opt/flumip/data/custom_snp\'',
        ),
        _isp.ColumnDefinition(
          name: 'snpSourceAllowedHosts',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'',
        ),
        _isp.ColumnDefinition(
          name: 'toolsDir',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'/opt/flumip/tools\'',
        ),
        _isp.ColumnDefinition(
          name: 'mipgenExecutable',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'/opt/flumip/MIPGEN/mipgen\'',
        ),
        _isp.ColumnDefinition(
          name: 'exonExtractScript',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault:
              '\'/opt/flumip/MIPGEN/tools/extract_coding_gene_exons.sh\'',
        ),
        _isp.ColumnDefinition(
          name: 'ucscTrackGenerator',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'/opt/flumip/MIPGEN/tools/generate_ucsc_track.py\'',
        ),
        _isp.ColumnDefinition(
          name: 'binCreationScript',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'/opt/flumip/MIPGEN/tools/add_bins_to_refgene.py\'',
        ),
        _isp.ColumnDefinition(
          name: 'bigGenePredToGenePredExecutable',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'/opt/flumip/tools/bigGenePredToGenePred\'',
        ),
        _isp.ColumnDefinition(
          name: 'mailActive',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'smtpServer',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'',
        ),
        _isp.ColumnDefinition(
          name: 'smtpPort',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '25',
        ),
        _isp.ColumnDefinition(
          name: 'smtpUser',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'',
        ),
        _isp.ColumnDefinition(
          name: 'smtpPassword',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'smtpFrom',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'flumip@yourdomain.com\'',
        ),
        _isp.ColumnDefinition(
          name: 'startTLS',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'loginRequired',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'settingsPassword',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'oidcIssuer',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'',
        ),
        _isp.ColumnDefinition(
          name: 'oidcClientId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'',
        ),
        _isp.ColumnDefinition(
          name: 'oidcClientSecret',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'oidcScopes',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'openid email profile\'',
        ),
        _isp.ColumnDefinition(
          name: 'oidcButtonLabel',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'Sign in with SSO\'',
        ),
        _isp.ColumnDefinition(
          name: 'oidcAllowedEmailDomains',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'',
        ),
        _isp.ColumnDefinition(
          name: 'oidcAdminEmails',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'',
        ),
        _isp.ColumnDefinition(
          name: 'authPublicUrl',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'',
        ),
      ],
      foreignKeys: [],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'snp',
      dartName: 'Snp',
      schema: 'public',
      module: 'flumip',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'description',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'',
        ),
        _isp.ColumnDefinition(
          name: 'vcfPath',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'tbiPath',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'folder',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'active',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'private',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'size',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'genome',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'owner',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'custom',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SnpImportStatus',
          columnDefault: '\'ready\'',
        ),
        _isp.ColumnDefinition(
          name: 'statusMessage',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'',
        ),
        _isp.ColumnDefinition(
          name: 'sourceVcfUrl',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'sourceTbiUrl',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'bytesDownloaded',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'totalBytes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'statusUpdated',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'created',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'snp_fk_0',
          columns: ['genome'],
          referenceTable: 'genome',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'snp_fk_1',
          columns: ['owner'],
          referenceTable: 'flumip_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'snp_genome_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'genome',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'snp_owner_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'owner',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'snp_folder_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'folder',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._isp.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(dynamic data, [Type? t]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _is.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _ilu62sh8.AuthAdminStatusDto) {
      return _ilu62sh8.AuthAdminStatusDto.fromJson(data) as T;
    }
    if (t == _i1qrzley.AuthApiToken) {
      return _i1qrzley.AuthApiToken.fromJson(data) as T;
    }
    if (t == _i3pxz8st.AuthConfigDto) {
      return _i3pxz8st.AuthConfigDto.fromJson(data) as T;
    }
    if (t == _iopq1986.AuthFlow) {
      return _iopq1986.AuthFlow.fromJson(data) as T;
    }
    if (t == _i1cqtl3u.AuthSession) {
      return _i1cqtl3u.AuthSession.fromJson(data) as T;
    }
    if (t == _i9fqmmja.AuthUserDto) {
      return _i9fqmmja.AuthUserDto.fromJson(data) as T;
    }
    if (t == _i50r13ns.CustomSnpRequestDto) {
      return _i50r13ns.CustomSnpRequestDto.fromJson(data) as T;
    }
    if (t == _ifprdzfb.GeneExtractionException) {
      return _ifprdzfb.GeneExtractionException.fromJson(data) as T;
    }
    if (t == _il9ya82w.BedCreationException) {
      return _il9ya82w.BedCreationException.fromJson(data) as T;
    }
    if (t == _ix5u8j9t.ArgumentException) {
      return _ix5u8j9t.ArgumentException.fromJson(data) as T;
    }
    if (t == _iua77lfj.FlumipFileNotFoundException) {
      return _iua77lfj.FlumipFileNotFoundException.fromJson(data) as T;
    }
    if (t == _iq9wx7jy.ProjectAccessDeniedException) {
      return _iq9wx7jy.ProjectAccessDeniedException.fromJson(data) as T;
    }
    if (t == _ijkt6zbv.FlumipUser) {
      return _ijkt6zbv.FlumipUser.fromJson(data) as T;
    }
    if (t == _im3lr0ct.FlumipUserDto) {
      return _im3lr0ct.FlumipUserDto.fromJson(data) as T;
    }
    if (t == _ik3s3pjn.Genome) {
      return _ik3s3pjn.Genome.fromJson(data) as T;
    }
    if (t == _ifiazq2p.Project) {
      return _ifiazq2p.Project.fromJson(data) as T;
    }
    if (t == _ip1wvjxo.ProjectFileDto) {
      return _ip1wvjxo.ProjectFileDto.fromJson(data) as T;
    }
    if (t == _i4kq7s26.ProjectOptions) {
      return _i4kq7s26.ProjectOptions.fromJson(data) as T;
    }
    if (t == _iootg8bv.ScoreMethod) {
      return _iootg8bv.ScoreMethod.fromJson(data) as T;
    }
    if (t == _iy8r37ur.SearchHitDto) {
      return _iy8r37ur.SearchHitDto.fromJson(data) as T;
    }
    if (t == _ia4xis23.SearchHitKind) {
      return _ia4xis23.SearchHitKind.fromJson(data) as T;
    }
    if (t == _ibmr8d9c.Settings) {
      return _ibmr8d9c.Settings.fromJson(data) as T;
    }
    if (t == _ip0fcn2o.Snp) {
      return _ip0fcn2o.Snp.fromJson(data) as T;
    }
    if (t == _iq9n7xnd.SnpImportStatus) {
      return _iq9n7xnd.SnpImportStatus.fromJson(data) as T;
    }
    if (t == _i8stnodc.SnpUsageDto) {
      return _i8stnodc.SnpUsageDto.fromJson(data) as T;
    }
    if (t == _igo562ik.UserSettingsDto) {
      return _igo562ik.UserSettingsDto.fromJson(data) as T;
    }
    if (t == _is.getType<_ilu62sh8.AuthAdminStatusDto?>()) {
      return (data != null ? _ilu62sh8.AuthAdminStatusDto.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i1qrzley.AuthApiToken?>()) {
      return (data != null ? _i1qrzley.AuthApiToken.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i3pxz8st.AuthConfigDto?>()) {
      return (data != null ? _i3pxz8st.AuthConfigDto.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iopq1986.AuthFlow?>()) {
      return (data != null ? _iopq1986.AuthFlow.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i1cqtl3u.AuthSession?>()) {
      return (data != null ? _i1cqtl3u.AuthSession.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i9fqmmja.AuthUserDto?>()) {
      return (data != null ? _i9fqmmja.AuthUserDto.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i50r13ns.CustomSnpRequestDto?>()) {
      return (data != null
              ? _i50r13ns.CustomSnpRequestDto.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ifprdzfb.GeneExtractionException?>()) {
      return (data != null
              ? _ifprdzfb.GeneExtractionException.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_il9ya82w.BedCreationException?>()) {
      return (data != null
              ? _il9ya82w.BedCreationException.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ix5u8j9t.ArgumentException?>()) {
      return (data != null ? _ix5u8j9t.ArgumentException.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iua77lfj.FlumipFileNotFoundException?>()) {
      return (data != null
              ? _iua77lfj.FlumipFileNotFoundException.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iq9wx7jy.ProjectAccessDeniedException?>()) {
      return (data != null
              ? _iq9wx7jy.ProjectAccessDeniedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ijkt6zbv.FlumipUser?>()) {
      return (data != null ? _ijkt6zbv.FlumipUser.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_im3lr0ct.FlumipUserDto?>()) {
      return (data != null ? _im3lr0ct.FlumipUserDto.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ik3s3pjn.Genome?>()) {
      return (data != null ? _ik3s3pjn.Genome.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ifiazq2p.Project?>()) {
      return (data != null ? _ifiazq2p.Project.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ip1wvjxo.ProjectFileDto?>()) {
      return (data != null ? _ip1wvjxo.ProjectFileDto.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i4kq7s26.ProjectOptions?>()) {
      return (data != null ? _i4kq7s26.ProjectOptions.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iootg8bv.ScoreMethod?>()) {
      return (data != null ? _iootg8bv.ScoreMethod.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iy8r37ur.SearchHitDto?>()) {
      return (data != null ? _iy8r37ur.SearchHitDto.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ia4xis23.SearchHitKind?>()) {
      return (data != null ? _ia4xis23.SearchHitKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ibmr8d9c.Settings?>()) {
      return (data != null ? _ibmr8d9c.Settings.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ip0fcn2o.Snp?>()) {
      return (data != null ? _ip0fcn2o.Snp.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iq9n7xnd.SnpImportStatus?>()) {
      return (data != null ? _iq9n7xnd.SnpImportStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i8stnodc.SnpUsageDto?>()) {
      return (data != null ? _i8stnodc.SnpUsageDto.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_igo562ik.UserSettingsDto?>()) {
      return (data != null ? _igo562ik.UserSettingsDto.fromJson(data) : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == _is.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_iaw3nq06.ProjectFileDto>) {
      return (data as List)
              .map((e) => deserialize<_iaw3nq06.ProjectFileDto>(e))
              .toList()
          as T;
    }
    if (t == List<_i2jfp72f.Genome>) {
      return (data as List)
              .map((e) => deserialize<_i2jfp72f.Genome>(e))
              .toList()
          as T;
    }
    if (t == List<_icqkl7md.Snp>) {
      return (data as List).map((e) => deserialize<_icqkl7md.Snp>(e)).toList()
          as T;
    }
    if (t == List<_idblq1ye.Project>) {
      return (data as List)
              .map((e) => deserialize<_idblq1ye.Project>(e))
              .toList()
          as T;
    }
    if (t == List<_ipn4uvlw.FlumipUserDto>) {
      return (data as List)
              .map((e) => deserialize<_ipn4uvlw.FlumipUserDto>(e))
              .toList()
          as T;
    }
    if (t == List<_ih1e1b1z.SearchHitDto>) {
      return (data as List)
              .map((e) => deserialize<_ih1e1b1z.SearchHitDto>(e))
              .toList()
          as T;
    }
    if (t == List<_ivyy2rnq.SnpUsageDto>) {
      return (data as List)
              .map((e) => deserialize<_ivyy2rnq.SnpUsageDto>(e))
              .toList()
          as T;
    }
    try {
      return _isp.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _ilu62sh8.AuthAdminStatusDto => 'AuthAdminStatusDto',
      _i1qrzley.AuthApiToken => 'AuthApiToken',
      _i3pxz8st.AuthConfigDto => 'AuthConfigDto',
      _iopq1986.AuthFlow => 'AuthFlow',
      _i1cqtl3u.AuthSession => 'AuthSession',
      _i9fqmmja.AuthUserDto => 'AuthUserDto',
      _i50r13ns.CustomSnpRequestDto => 'CustomSnpRequestDto',
      _ifprdzfb.GeneExtractionException => 'GeneExtractionException',
      _il9ya82w.BedCreationException => 'BedCreationException',
      _ix5u8j9t.ArgumentException => 'ArgumentException',
      _iua77lfj.FlumipFileNotFoundException => 'FlumipFileNotFoundException',
      _iq9wx7jy.ProjectAccessDeniedException => 'ProjectAccessDeniedException',
      _ijkt6zbv.FlumipUser => 'FlumipUser',
      _im3lr0ct.FlumipUserDto => 'FlumipUserDto',
      _ik3s3pjn.Genome => 'Genome',
      _ifiazq2p.Project => 'Project',
      _ip1wvjxo.ProjectFileDto => 'ProjectFileDto',
      _i4kq7s26.ProjectOptions => 'ProjectOptions',
      _iootg8bv.ScoreMethod => 'ScoreMethod',
      _iy8r37ur.SearchHitDto => 'SearchHitDto',
      _ia4xis23.SearchHitKind => 'SearchHitKind',
      _ibmr8d9c.Settings => 'Settings',
      _ip0fcn2o.Snp => 'Snp',
      _iq9n7xnd.SnpImportStatus => 'SnpImportStatus',
      _i8stnodc.SnpUsageDto => 'SnpUsageDto',
      _igo562ik.UserSettingsDto => 'UserSettingsDto',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('flumip.', '');
    }

    switch (data) {
      case _ilu62sh8.AuthAdminStatusDto():
        return 'AuthAdminStatusDto';
      case _i1qrzley.AuthApiToken():
        return 'AuthApiToken';
      case _i3pxz8st.AuthConfigDto():
        return 'AuthConfigDto';
      case _iopq1986.AuthFlow():
        return 'AuthFlow';
      case _i1cqtl3u.AuthSession():
        return 'AuthSession';
      case _i9fqmmja.AuthUserDto():
        return 'AuthUserDto';
      case _i50r13ns.CustomSnpRequestDto():
        return 'CustomSnpRequestDto';
      case _ifprdzfb.GeneExtractionException():
        return 'GeneExtractionException';
      case _il9ya82w.BedCreationException():
        return 'BedCreationException';
      case _ix5u8j9t.ArgumentException():
        return 'ArgumentException';
      case _iua77lfj.FlumipFileNotFoundException():
        return 'FlumipFileNotFoundException';
      case _iq9wx7jy.ProjectAccessDeniedException():
        return 'ProjectAccessDeniedException';
      case _ijkt6zbv.FlumipUser():
        return 'FlumipUser';
      case _im3lr0ct.FlumipUserDto():
        return 'FlumipUserDto';
      case _ik3s3pjn.Genome():
        return 'Genome';
      case _ifiazq2p.Project():
        return 'Project';
      case _ip1wvjxo.ProjectFileDto():
        return 'ProjectFileDto';
      case _i4kq7s26.ProjectOptions():
        return 'ProjectOptions';
      case _iootg8bv.ScoreMethod():
        return 'ScoreMethod';
      case _iy8r37ur.SearchHitDto():
        return 'SearchHitDto';
      case _ia4xis23.SearchHitKind():
        return 'SearchHitKind';
      case _ibmr8d9c.Settings():
        return 'Settings';
      case _ip0fcn2o.Snp():
        return 'Snp';
      case _iq9n7xnd.SnpImportStatus():
        return 'SnpImportStatus';
      case _i8stnodc.SnpUsageDto():
        return 'SnpUsageDto';
      case _igo562ik.UserSettingsDto():
        return 'UserSettingsDto';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AuthAdminStatusDto') {
      return deserialize<_ilu62sh8.AuthAdminStatusDto>(data['data']);
    }
    if (dataClassName == 'AuthApiToken') {
      return deserialize<_i1qrzley.AuthApiToken>(data['data']);
    }
    if (dataClassName == 'AuthConfigDto') {
      return deserialize<_i3pxz8st.AuthConfigDto>(data['data']);
    }
    if (dataClassName == 'AuthFlow') {
      return deserialize<_iopq1986.AuthFlow>(data['data']);
    }
    if (dataClassName == 'AuthSession') {
      return deserialize<_i1cqtl3u.AuthSession>(data['data']);
    }
    if (dataClassName == 'AuthUserDto') {
      return deserialize<_i9fqmmja.AuthUserDto>(data['data']);
    }
    if (dataClassName == 'CustomSnpRequestDto') {
      return deserialize<_i50r13ns.CustomSnpRequestDto>(data['data']);
    }
    if (dataClassName == 'GeneExtractionException') {
      return deserialize<_ifprdzfb.GeneExtractionException>(data['data']);
    }
    if (dataClassName == 'BedCreationException') {
      return deserialize<_il9ya82w.BedCreationException>(data['data']);
    }
    if (dataClassName == 'ArgumentException') {
      return deserialize<_ix5u8j9t.ArgumentException>(data['data']);
    }
    if (dataClassName == 'FlumipFileNotFoundException') {
      return deserialize<_iua77lfj.FlumipFileNotFoundException>(data['data']);
    }
    if (dataClassName == 'ProjectAccessDeniedException') {
      return deserialize<_iq9wx7jy.ProjectAccessDeniedException>(data['data']);
    }
    if (dataClassName == 'FlumipUser') {
      return deserialize<_ijkt6zbv.FlumipUser>(data['data']);
    }
    if (dataClassName == 'FlumipUserDto') {
      return deserialize<_im3lr0ct.FlumipUserDto>(data['data']);
    }
    if (dataClassName == 'Genome') {
      return deserialize<_ik3s3pjn.Genome>(data['data']);
    }
    if (dataClassName == 'Project') {
      return deserialize<_ifiazq2p.Project>(data['data']);
    }
    if (dataClassName == 'ProjectFileDto') {
      return deserialize<_ip1wvjxo.ProjectFileDto>(data['data']);
    }
    if (dataClassName == 'ProjectOptions') {
      return deserialize<_i4kq7s26.ProjectOptions>(data['data']);
    }
    if (dataClassName == 'ScoreMethod') {
      return deserialize<_iootg8bv.ScoreMethod>(data['data']);
    }
    if (dataClassName == 'SearchHitDto') {
      return deserialize<_iy8r37ur.SearchHitDto>(data['data']);
    }
    if (dataClassName == 'SearchHitKind') {
      return deserialize<_ia4xis23.SearchHitKind>(data['data']);
    }
    if (dataClassName == 'Settings') {
      return deserialize<_ibmr8d9c.Settings>(data['data']);
    }
    if (dataClassName == 'Snp') {
      return deserialize<_ip0fcn2o.Snp>(data['data']);
    }
    if (dataClassName == 'SnpImportStatus') {
      return deserialize<_iq9n7xnd.SnpImportStatus>(data['data']);
    }
    if (dataClassName == 'SnpUsageDto') {
      return deserialize<_i8stnodc.SnpUsageDto>(data['data']);
    }
    if (dataClassName == 'UserSettingsDto') {
      return deserialize<_igo562ik.UserSettingsDto>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _isp.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i1qrzley.AuthApiToken:
        return _i1qrzley.AuthApiToken.t;
      case _iopq1986.AuthFlow:
        return _iopq1986.AuthFlow.t;
      case _i1cqtl3u.AuthSession:
        return _i1cqtl3u.AuthSession.t;
      case _ijkt6zbv.FlumipUser:
        return _ijkt6zbv.FlumipUser.t;
      case _ik3s3pjn.Genome:
        return _ik3s3pjn.Genome.t;
      case _ifiazq2p.Project:
        return _ifiazq2p.Project.t;
      case _i4kq7s26.ProjectOptions:
        return _i4kq7s26.ProjectOptions.t;
      case _ibmr8d9c.Settings:
        return _ibmr8d9c.Settings.t;
      case _ip0fcn2o.Snp:
        return _ip0fcn2o.Snp.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'flumip';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _isp.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
