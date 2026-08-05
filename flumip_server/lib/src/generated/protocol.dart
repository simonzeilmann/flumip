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
import 'package:serverpod/protocol.dart' as _i2;
import 'auth_admin_status_dto.dart' as _i3;
import 'auth_api_token.dart' as _i4;
import 'auth_config_dto.dart' as _i5;
import 'auth_flow.dart' as _i6;
import 'auth_session.dart' as _i7;
import 'auth_user_dto.dart' as _i8;
import 'custom_snp_request_dto.dart' as _i9;
import 'exceptions.dart' as _i10;
import 'exceptions/GenomeExceptions/bed_creation_exception.dart' as _i11;
import 'exceptions/argument_exception.dart' as _i12;
import 'exceptions/flumip_file_not_found_exception.dart' as _i13;
import 'exceptions/project_access_denied_exception.dart' as _i14;
import 'flumip_user.dart' as _i15;
import 'flumip_user_dto.dart' as _i16;
import 'genome.dart' as _i17;
import 'project.dart' as _i18;
import 'project_file_dto.dart' as _i19;
import 'project_options.dart' as _i20;
import 'score_method.dart' as _i21;
import 'settings.dart' as _i22;
import 'snp.dart' as _i23;
import 'snp_import_status.dart' as _i24;
import 'snp_usage_dto.dart' as _i25;
import 'user_settings_dto.dart' as _i26;
import 'package:flumip_server/src/generated/project_file_dto.dart' as _i27;
import 'package:flumip_server/src/generated/genome.dart' as _i28;
import 'package:flumip_server/src/generated/snp.dart' as _i29;
import 'package:flumip_server/src/generated/project.dart' as _i30;
import 'package:flumip_server/src/generated/flumip_user_dto.dart' as _i31;
import 'package:flumip_server/src/generated/snp_usage_dto.dart' as _i32;
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
export 'settings.dart';
export 'snp.dart';
export 'snp_import_status.dart';
export 'snp_usage_dto.dart';
export 'user_settings_dto.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'auth_api_token',
      dartName: 'AuthApiToken',
      schema: 'public',
      module: 'flumip',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'auth_api_token_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'authSessionId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'tokenHash',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'email',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'isAdmin',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'created',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
        _i2.ColumnDefinition(
          name: 'expires',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'auth_api_token_fk_0',
          columns: ['authSessionId'],
          referenceTable: 'auth_session',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'auth_api_token_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'auth_api_token_hash_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'tokenHash',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'auth_api_token_session_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'authSessionId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'auth_api_token_expires_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
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
    _i2.TableDefinition(
      name: 'auth_flow',
      dartName: 'AuthFlow',
      schema: 'public',
      module: 'flumip',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'auth_flow_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'state',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'codeVerifier',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'nonce',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'redirectUri',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'created',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
        _i2.ColumnDefinition(
          name: 'expires',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'auth_flow_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'auth_flow_state_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'state',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'auth_flow_expires_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
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
    _i2.TableDefinition(
      name: 'auth_session',
      dartName: 'AuthSession',
      schema: 'public',
      module: 'flumip',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'auth_session_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'cookieHash',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'email',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'isAdmin',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'created',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
        _i2.ColumnDefinition(
          name: 'expires',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'lastSeen',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'auth_session_fk_0',
          columns: ['userId'],
          referenceTable: 'flumip_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'auth_session_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'auth_session_cookie_hash_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'cookieHash',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'auth_session_expires_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
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
    _i2.TableDefinition(
      name: 'flumip_user',
      dartName: 'FlumipUser',
      schema: 'public',
      module: 'flumip',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'flumip_user_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'email',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'subject',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'issuer',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'displayName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'created',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
        _i2.ColumnDefinition(
          name: 'lastLogin',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'flumip_user_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'flumip_user_identity_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'issuer',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'subject',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'flumip_user_email_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
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
    _i2.TableDefinition(
      name: 'genome',
      dartName: 'Genome',
      schema: 'public',
      module: 'flumip',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'genome_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'path',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'fastaPath',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'refPath',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'snpFolder',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'snp',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'List<int>?',
        ),
        _i2.ColumnDefinition(
          name: 'category',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'active',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'indexed',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'indexing',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'indexPID',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'indexResults',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'size',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'genome_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'project',
      dartName: 'Project',
      schema: 'public',
      module: 'flumip',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'project_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'folderName',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'genome',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'snp',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'tags',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'List<String>?',
        ),
        _i2.ColumnDefinition(
          name: 'created',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
        _i2.ColumnDefinition(
          name: 'owner',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'department',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'trackToken',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'genes',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'List<String>?',
        ),
        _i2.ColumnDefinition(
          name: 'bedFileCreated',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'active',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'pid',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'size',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'emailNotification',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'options',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'started',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'completedIn',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'Duration?',
        ),
        _i2.ColumnDefinition(
          name: 'error',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'cleanup',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'project_fk_0',
          columns: ['snp'],
          referenceTable: 'snp',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.setNull,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'project_fk_1',
          columns: ['owner'],
          referenceTable: 'flumip_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'project_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'project_owner_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'owner',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'project_track_token_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
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
    _i2.TableDefinition(
      name: 'project_options',
      dartName: 'ProjectOptions',
      schema: 'public',
      module: 'flumip',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'project_options_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'minCaptureSize',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '162',
        ),
        _i2.ColumnDefinition(
          name: 'maxCaptureSize',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '162',
        ),
        _i2.ColumnDefinition(
          name: 'armLengths',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'armLengthSums',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'40,41,42,43,44,45\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'extMinLength',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '16',
        ),
        _i2.ColumnDefinition(
          name: 'extMaxLength',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '18',
        ),
        _i2.ColumnDefinition(
          name: 'ligMinLength',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '18',
        ),
        _i2.ColumnDefinition(
          name: 'tagSizes',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'5,0\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'maskedArmThreshold',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '0.5',
        ),
        _i2.ColumnDefinition(
          name: 'targetArmCopy',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '20',
        ),
        _i2.ColumnDefinition(
          name: 'maxArmCopyProduct',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '75',
        ),
        _i2.ColumnDefinition(
          name: 'trf',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'genomeDir',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'featureFlank',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'captureIncrement',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '5',
        ),
        _i2.ColumnDefinition(
          name: 'logisticHeuristic',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'maxMipOverlap',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '30',
        ),
        _i2.ColumnDefinition(
          name: 'startingMipOverlap',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'checkCopyNumber',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'sealBothStrands',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'halfSealBothStrands',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'doubleTileStrandUnaware',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'doubleTileStrandsSeparately',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'scoreMethod',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ScoreMethod',
          columnDefault: '\'logistic\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'logisticOptimalScore',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '0.98',
        ),
        _i2.ColumnDefinition(
          name: 'svrOptimalScore',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '2.2',
        ),
        _i2.ColumnDefinition(
          name: 'logisticPriorityScore',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '0.9',
        ),
        _i2.ColumnDefinition(
          name: 'svrPriorityScore',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '1.5',
        ),
        _i2.ColumnDefinition(
          name: 'silentMode',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'bwaThreads',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'project_options_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'settings',
      dartName: 'Settings',
      schema: 'public',
      module: 'flumip',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'settings_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'demoMode',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'baseDir',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'/opt/flumip\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'projectDir',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'/opt/flumip/projects\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'genomeDir',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'/opt/flumip/data/genomes\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'customSnpDir',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'/opt/flumip/data/custom_snp\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'snpSourceAllowedHosts',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'toolsDir',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'/opt/flumip/tools\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'mipgenExecutable',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'/opt/flumip/MIPGEN/mipgen\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'exonExtractScript',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault:
              '\'/opt/flumip/MIPGEN/tools/extract_coding_gene_exons.sh\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'ucscTrackGenerator',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault:
              '\'/opt/flumip/MIPGEN/tools/generate_ucsc_track.py\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'binCreationScript',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault:
              '\'/opt/flumip/MIPGEN/tools/add_bins_to_refgene.py\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'bigGenePredToGenePredExecutable',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'/opt/flumip/tools/bigGenePredToGenePred\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'mailActive',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'smtpServer',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'smtpPort',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '25',
        ),
        _i2.ColumnDefinition(
          name: 'smtpUser',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'smtpPassword',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'smtpFrom',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'flumip@yourdomain.com\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'startTLS',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'loginRequired',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'settingsPassword',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'changeme\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'oidcIssuer',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'oidcClientId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'oidcClientSecret',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'oidcScopes',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'openid email profile\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'oidcButtonLabel',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'Sign in with SSO\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'oidcAllowedEmailDomains',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'oidcAdminEmails',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'authPublicUrl',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'settings_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'snp',
      dartName: 'Snp',
      schema: 'public',
      module: 'flumip',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'snp_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'vcfPath',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'tbiPath',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'folder',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'active',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'private',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'size',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'genome',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'owner',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'custom',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SnpImportStatus',
          columnDefault: '\'ready\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'statusMessage',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'sourceVcfUrl',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'sourceTbiUrl',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'bytesDownloaded',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'totalBytes',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'statusUpdated',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'created',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'snp_fk_0',
          columns: ['genome'],
          referenceTable: 'genome',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.setNull,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'snp_fk_1',
          columns: ['owner'],
          referenceTable: 'flumip_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'snp_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'snp_genome_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'genome',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'snp_owner_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'owner',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'snp_folder_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
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
    ..._i2.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i3.AuthAdminStatusDto) {
      return _i3.AuthAdminStatusDto.fromJson(data) as T;
    }
    if (t == _i4.AuthApiToken) {
      return _i4.AuthApiToken.fromJson(data) as T;
    }
    if (t == _i5.AuthConfigDto) {
      return _i5.AuthConfigDto.fromJson(data) as T;
    }
    if (t == _i6.AuthFlow) {
      return _i6.AuthFlow.fromJson(data) as T;
    }
    if (t == _i7.AuthSession) {
      return _i7.AuthSession.fromJson(data) as T;
    }
    if (t == _i8.AuthUserDto) {
      return _i8.AuthUserDto.fromJson(data) as T;
    }
    if (t == _i9.CustomSnpRequestDto) {
      return _i9.CustomSnpRequestDto.fromJson(data) as T;
    }
    if (t == _i10.GeneExtractionException) {
      return _i10.GeneExtractionException.fromJson(data) as T;
    }
    if (t == _i11.BedCreationException) {
      return _i11.BedCreationException.fromJson(data) as T;
    }
    if (t == _i12.ArgumentException) {
      return _i12.ArgumentException.fromJson(data) as T;
    }
    if (t == _i13.FlumipFileNotFoundException) {
      return _i13.FlumipFileNotFoundException.fromJson(data) as T;
    }
    if (t == _i14.ProjectAccessDeniedException) {
      return _i14.ProjectAccessDeniedException.fromJson(data) as T;
    }
    if (t == _i15.FlumipUser) {
      return _i15.FlumipUser.fromJson(data) as T;
    }
    if (t == _i16.FlumipUserDto) {
      return _i16.FlumipUserDto.fromJson(data) as T;
    }
    if (t == _i17.Genome) {
      return _i17.Genome.fromJson(data) as T;
    }
    if (t == _i18.Project) {
      return _i18.Project.fromJson(data) as T;
    }
    if (t == _i19.ProjectFileDto) {
      return _i19.ProjectFileDto.fromJson(data) as T;
    }
    if (t == _i20.ProjectOptions) {
      return _i20.ProjectOptions.fromJson(data) as T;
    }
    if (t == _i21.ScoreMethod) {
      return _i21.ScoreMethod.fromJson(data) as T;
    }
    if (t == _i22.Settings) {
      return _i22.Settings.fromJson(data) as T;
    }
    if (t == _i23.Snp) {
      return _i23.Snp.fromJson(data) as T;
    }
    if (t == _i24.SnpImportStatus) {
      return _i24.SnpImportStatus.fromJson(data) as T;
    }
    if (t == _i25.SnpUsageDto) {
      return _i25.SnpUsageDto.fromJson(data) as T;
    }
    if (t == _i26.UserSettingsDto) {
      return _i26.UserSettingsDto.fromJson(data) as T;
    }
    if (t == _i1.getType<_i3.AuthAdminStatusDto?>()) {
      return (data != null ? _i3.AuthAdminStatusDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.AuthApiToken?>()) {
      return (data != null ? _i4.AuthApiToken.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.AuthConfigDto?>()) {
      return (data != null ? _i5.AuthConfigDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.AuthFlow?>()) {
      return (data != null ? _i6.AuthFlow.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.AuthSession?>()) {
      return (data != null ? _i7.AuthSession.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.AuthUserDto?>()) {
      return (data != null ? _i8.AuthUserDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.CustomSnpRequestDto?>()) {
      return (data != null ? _i9.CustomSnpRequestDto.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i10.GeneExtractionException?>()) {
      return (data != null ? _i10.GeneExtractionException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i11.BedCreationException?>()) {
      return (data != null ? _i11.BedCreationException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i12.ArgumentException?>()) {
      return (data != null ? _i12.ArgumentException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.FlumipFileNotFoundException?>()) {
      return (data != null
              ? _i13.FlumipFileNotFoundException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i14.ProjectAccessDeniedException?>()) {
      return (data != null
              ? _i14.ProjectAccessDeniedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i15.FlumipUser?>()) {
      return (data != null ? _i15.FlumipUser.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.FlumipUserDto?>()) {
      return (data != null ? _i16.FlumipUserDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.Genome?>()) {
      return (data != null ? _i17.Genome.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.Project?>()) {
      return (data != null ? _i18.Project.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.ProjectFileDto?>()) {
      return (data != null ? _i19.ProjectFileDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.ProjectOptions?>()) {
      return (data != null ? _i20.ProjectOptions.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.ScoreMethod?>()) {
      return (data != null ? _i21.ScoreMethod.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.Settings?>()) {
      return (data != null ? _i22.Settings.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.Snp?>()) {
      return (data != null ? _i23.Snp.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.SnpImportStatus?>()) {
      return (data != null ? _i24.SnpImportStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.SnpUsageDto?>()) {
      return (data != null ? _i25.SnpUsageDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.UserSettingsDto?>()) {
      return (data != null ? _i26.UserSettingsDto.fromJson(data) : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == _i1.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i27.ProjectFileDto>) {
      return (data as List)
              .map((e) => deserialize<_i27.ProjectFileDto>(e))
              .toList()
          as T;
    }
    if (t == List<_i28.Genome>) {
      return (data as List).map((e) => deserialize<_i28.Genome>(e)).toList()
          as T;
    }
    if (t == List<_i29.Snp>) {
      return (data as List).map((e) => deserialize<_i29.Snp>(e)).toList() as T;
    }
    if (t == List<_i30.Project>) {
      return (data as List).map((e) => deserialize<_i30.Project>(e)).toList()
          as T;
    }
    if (t == List<_i31.FlumipUserDto>) {
      return (data as List)
              .map((e) => deserialize<_i31.FlumipUserDto>(e))
              .toList()
          as T;
    }
    if (t == List<_i32.SnpUsageDto>) {
      return (data as List)
              .map((e) => deserialize<_i32.SnpUsageDto>(e))
              .toList()
          as T;
    }
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i3.AuthAdminStatusDto => 'AuthAdminStatusDto',
      _i4.AuthApiToken => 'AuthApiToken',
      _i5.AuthConfigDto => 'AuthConfigDto',
      _i6.AuthFlow => 'AuthFlow',
      _i7.AuthSession => 'AuthSession',
      _i8.AuthUserDto => 'AuthUserDto',
      _i9.CustomSnpRequestDto => 'CustomSnpRequestDto',
      _i10.GeneExtractionException => 'GeneExtractionException',
      _i11.BedCreationException => 'BedCreationException',
      _i12.ArgumentException => 'ArgumentException',
      _i13.FlumipFileNotFoundException => 'FlumipFileNotFoundException',
      _i14.ProjectAccessDeniedException => 'ProjectAccessDeniedException',
      _i15.FlumipUser => 'FlumipUser',
      _i16.FlumipUserDto => 'FlumipUserDto',
      _i17.Genome => 'Genome',
      _i18.Project => 'Project',
      _i19.ProjectFileDto => 'ProjectFileDto',
      _i20.ProjectOptions => 'ProjectOptions',
      _i21.ScoreMethod => 'ScoreMethod',
      _i22.Settings => 'Settings',
      _i23.Snp => 'Snp',
      _i24.SnpImportStatus => 'SnpImportStatus',
      _i25.SnpUsageDto => 'SnpUsageDto',
      _i26.UserSettingsDto => 'UserSettingsDto',
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
      case _i3.AuthAdminStatusDto():
        return 'AuthAdminStatusDto';
      case _i4.AuthApiToken():
        return 'AuthApiToken';
      case _i5.AuthConfigDto():
        return 'AuthConfigDto';
      case _i6.AuthFlow():
        return 'AuthFlow';
      case _i7.AuthSession():
        return 'AuthSession';
      case _i8.AuthUserDto():
        return 'AuthUserDto';
      case _i9.CustomSnpRequestDto():
        return 'CustomSnpRequestDto';
      case _i10.GeneExtractionException():
        return 'GeneExtractionException';
      case _i11.BedCreationException():
        return 'BedCreationException';
      case _i12.ArgumentException():
        return 'ArgumentException';
      case _i13.FlumipFileNotFoundException():
        return 'FlumipFileNotFoundException';
      case _i14.ProjectAccessDeniedException():
        return 'ProjectAccessDeniedException';
      case _i15.FlumipUser():
        return 'FlumipUser';
      case _i16.FlumipUserDto():
        return 'FlumipUserDto';
      case _i17.Genome():
        return 'Genome';
      case _i18.Project():
        return 'Project';
      case _i19.ProjectFileDto():
        return 'ProjectFileDto';
      case _i20.ProjectOptions():
        return 'ProjectOptions';
      case _i21.ScoreMethod():
        return 'ScoreMethod';
      case _i22.Settings():
        return 'Settings';
      case _i23.Snp():
        return 'Snp';
      case _i24.SnpImportStatus():
        return 'SnpImportStatus';
      case _i25.SnpUsageDto():
        return 'SnpUsageDto';
      case _i26.UserSettingsDto():
        return 'UserSettingsDto';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
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
      return deserialize<_i3.AuthAdminStatusDto>(data['data']);
    }
    if (dataClassName == 'AuthApiToken') {
      return deserialize<_i4.AuthApiToken>(data['data']);
    }
    if (dataClassName == 'AuthConfigDto') {
      return deserialize<_i5.AuthConfigDto>(data['data']);
    }
    if (dataClassName == 'AuthFlow') {
      return deserialize<_i6.AuthFlow>(data['data']);
    }
    if (dataClassName == 'AuthSession') {
      return deserialize<_i7.AuthSession>(data['data']);
    }
    if (dataClassName == 'AuthUserDto') {
      return deserialize<_i8.AuthUserDto>(data['data']);
    }
    if (dataClassName == 'CustomSnpRequestDto') {
      return deserialize<_i9.CustomSnpRequestDto>(data['data']);
    }
    if (dataClassName == 'GeneExtractionException') {
      return deserialize<_i10.GeneExtractionException>(data['data']);
    }
    if (dataClassName == 'BedCreationException') {
      return deserialize<_i11.BedCreationException>(data['data']);
    }
    if (dataClassName == 'ArgumentException') {
      return deserialize<_i12.ArgumentException>(data['data']);
    }
    if (dataClassName == 'FlumipFileNotFoundException') {
      return deserialize<_i13.FlumipFileNotFoundException>(data['data']);
    }
    if (dataClassName == 'ProjectAccessDeniedException') {
      return deserialize<_i14.ProjectAccessDeniedException>(data['data']);
    }
    if (dataClassName == 'FlumipUser') {
      return deserialize<_i15.FlumipUser>(data['data']);
    }
    if (dataClassName == 'FlumipUserDto') {
      return deserialize<_i16.FlumipUserDto>(data['data']);
    }
    if (dataClassName == 'Genome') {
      return deserialize<_i17.Genome>(data['data']);
    }
    if (dataClassName == 'Project') {
      return deserialize<_i18.Project>(data['data']);
    }
    if (dataClassName == 'ProjectFileDto') {
      return deserialize<_i19.ProjectFileDto>(data['data']);
    }
    if (dataClassName == 'ProjectOptions') {
      return deserialize<_i20.ProjectOptions>(data['data']);
    }
    if (dataClassName == 'ScoreMethod') {
      return deserialize<_i21.ScoreMethod>(data['data']);
    }
    if (dataClassName == 'Settings') {
      return deserialize<_i22.Settings>(data['data']);
    }
    if (dataClassName == 'Snp') {
      return deserialize<_i23.Snp>(data['data']);
    }
    if (dataClassName == 'SnpImportStatus') {
      return deserialize<_i24.SnpImportStatus>(data['data']);
    }
    if (dataClassName == 'SnpUsageDto') {
      return deserialize<_i25.SnpUsageDto>(data['data']);
    }
    if (dataClassName == 'UserSettingsDto') {
      return deserialize<_i26.UserSettingsDto>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i4.AuthApiToken:
        return _i4.AuthApiToken.t;
      case _i6.AuthFlow:
        return _i6.AuthFlow.t;
      case _i7.AuthSession:
        return _i7.AuthSession.t;
      case _i15.FlumipUser:
        return _i15.FlumipUser.t;
      case _i17.Genome:
        return _i17.Genome.t;
      case _i18.Project:
        return _i18.Project.t;
      case _i20.ProjectOptions:
        return _i20.ProjectOptions.t;
      case _i22.Settings:
        return _i22.Settings.t;
      case _i23.Snp:
        return _i23.Snp.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
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
      return _i2.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
