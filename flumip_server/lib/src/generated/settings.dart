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
import 'package:serverpod/serverpod.dart' as _is;

abstract class Settings
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Settings._({
    this.id,
    bool? demoMode,
    int? demoModeRetentionHours,
    String? baseDir,
    String? projectDir,
    String? genomeDir,
    String? customSnpDir,
    String? snpSourceAllowedHosts,
    String? toolsDir,
    String? mipgenExecutable,
    String? exonExtractScript,
    String? ucscTrackGenerator,
    String? binCreationScript,
    String? bigGenePredToGenePredExecutable,
    bool? mailActive,
    String? smtpServer,
    int? smtpPort,
    String? smtpUser,
    this.smtpPassword,
    String? smtpFrom,
    bool? startTLS,
    bool? loginRequired,
    this.settingsPassword,
    String? oidcIssuer,
    String? oidcClientId,
    this.oidcClientSecret,
    String? oidcScopes,
    String? oidcButtonLabel,
    String? oidcAllowedEmailDomains,
    String? oidcAdminEmails,
    String? oidcDepartmentClaim,
    String? authPublicUrl,
  }) : demoMode = demoMode ?? false,
       demoModeRetentionHours = demoModeRetentionHours ?? 168,
       baseDir = baseDir ?? '/opt/flumip',
       projectDir = projectDir ?? '/opt/flumip/projects',
       genomeDir = genomeDir ?? '/opt/flumip/data/genomes',
       customSnpDir = customSnpDir ?? '/opt/flumip/data/custom_snp',
       snpSourceAllowedHosts = snpSourceAllowedHosts ?? '',
       toolsDir = toolsDir ?? '/opt/flumip/tools',
       mipgenExecutable = mipgenExecutable ?? '/opt/flumip/MIPGEN/mipgen',
       exonExtractScript =
           exonExtractScript ??
           '/opt/flumip/MIPGEN/tools/extract_coding_gene_exons.sh',
       ucscTrackGenerator =
           ucscTrackGenerator ??
           '/opt/flumip/MIPGEN/tools/generate_ucsc_track.py',
       binCreationScript =
           binCreationScript ??
           '/opt/flumip/MIPGEN/tools/add_bins_to_refgene.py',
       bigGenePredToGenePredExecutable =
           bigGenePredToGenePredExecutable ??
           '/opt/flumip/tools/bigGenePredToGenePred',
       mailActive = mailActive ?? false,
       smtpServer = smtpServer ?? '',
       smtpPort = smtpPort ?? 25,
       smtpUser = smtpUser ?? '',
       smtpFrom = smtpFrom ?? 'flumip@yourdomain.com',
       startTLS = startTLS ?? true,
       loginRequired = loginRequired ?? false,
       oidcIssuer = oidcIssuer ?? '',
       oidcClientId = oidcClientId ?? '',
       oidcScopes = oidcScopes ?? 'openid email profile',
       oidcButtonLabel = oidcButtonLabel ?? 'Sign in with SSO',
       oidcAllowedEmailDomains = oidcAllowedEmailDomains ?? '',
       oidcAdminEmails = oidcAdminEmails ?? '',
       oidcDepartmentClaim = oidcDepartmentClaim ?? '',
       authPublicUrl = authPublicUrl ?? '';

  factory Settings({
    int? id,
    bool? demoMode,
    int? demoModeRetentionHours,
    String? baseDir,
    String? projectDir,
    String? genomeDir,
    String? customSnpDir,
    String? snpSourceAllowedHosts,
    String? toolsDir,
    String? mipgenExecutable,
    String? exonExtractScript,
    String? ucscTrackGenerator,
    String? binCreationScript,
    String? bigGenePredToGenePredExecutable,
    bool? mailActive,
    String? smtpServer,
    int? smtpPort,
    String? smtpUser,
    String? smtpPassword,
    String? smtpFrom,
    bool? startTLS,
    bool? loginRequired,
    String? settingsPassword,
    String? oidcIssuer,
    String? oidcClientId,
    String? oidcClientSecret,
    String? oidcScopes,
    String? oidcButtonLabel,
    String? oidcAllowedEmailDomains,
    String? oidcAdminEmails,
    String? oidcDepartmentClaim,
    String? authPublicUrl,
  }) = _SettingsImpl;

  factory Settings.fromJson(Map<String, dynamic> jsonSerialization) {
    return Settings(
      id: jsonSerialization['id'] as int?,
      demoMode: jsonSerialization['demoMode'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['demoMode']),
      demoModeRetentionHours:
          jsonSerialization['demoModeRetentionHours'] as int?,
      baseDir: jsonSerialization['baseDir'] as String?,
      projectDir: jsonSerialization['projectDir'] as String?,
      genomeDir: jsonSerialization['genomeDir'] as String?,
      customSnpDir: jsonSerialization['customSnpDir'] as String?,
      snpSourceAllowedHosts:
          jsonSerialization['snpSourceAllowedHosts'] as String?,
      toolsDir: jsonSerialization['toolsDir'] as String?,
      mipgenExecutable: jsonSerialization['mipgenExecutable'] as String?,
      exonExtractScript: jsonSerialization['exonExtractScript'] as String?,
      ucscTrackGenerator: jsonSerialization['ucscTrackGenerator'] as String?,
      binCreationScript: jsonSerialization['binCreationScript'] as String?,
      bigGenePredToGenePredExecutable:
          jsonSerialization['bigGenePredToGenePredExecutable'] as String?,
      mailActive: jsonSerialization['mailActive'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['mailActive']),
      smtpServer: jsonSerialization['smtpServer'] as String?,
      smtpPort: jsonSerialization['smtpPort'] as int?,
      smtpUser: jsonSerialization['smtpUser'] as String?,
      smtpPassword: jsonSerialization['smtpPassword'] as String?,
      smtpFrom: jsonSerialization['smtpFrom'] as String?,
      startTLS: jsonSerialization['startTLS'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['startTLS']),
      loginRequired: jsonSerialization['loginRequired'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['loginRequired']),
      settingsPassword: jsonSerialization['settingsPassword'] as String?,
      oidcIssuer: jsonSerialization['oidcIssuer'] as String?,
      oidcClientId: jsonSerialization['oidcClientId'] as String?,
      oidcClientSecret: jsonSerialization['oidcClientSecret'] as String?,
      oidcScopes: jsonSerialization['oidcScopes'] as String?,
      oidcButtonLabel: jsonSerialization['oidcButtonLabel'] as String?,
      oidcAllowedEmailDomains:
          jsonSerialization['oidcAllowedEmailDomains'] as String?,
      oidcAdminEmails: jsonSerialization['oidcAdminEmails'] as String?,
      oidcDepartmentClaim: jsonSerialization['oidcDepartmentClaim'] as String?,
      authPublicUrl: jsonSerialization['authPublicUrl'] as String?,
    );
  }

  static final t = SettingsTable();

  static const db = SettingsRepository._();

  @override
  int? id;

  bool demoMode;

  /// How long a project survives on a demo install, in hours. 168 = 7 days.
  ///
  /// ⚠️ Read when the cleanup call *fires*, not only when it is scheduled, so
  /// raising it spares projects that were already queued. Lowering it cannot
  /// pull a scheduled deletion earlier — that project keeps the deadline it was
  /// created with. See DemoModeCleanup.
  int demoModeRetentionHours;

  String baseDir;

  String projectDir;

  String genomeDir;

  String customSnpDir;

  String snpSourceAllowedHosts;

  String toolsDir;

  String mipgenExecutable;

  String exonExtractScript;

  String ucscTrackGenerator;

  String binCreationScript;

  String bigGenePredToGenePredExecutable;

  bool mailActive;

  String smtpServer;

  int smtpPort;

  String smtpUser;

  String? smtpPassword;

  String smtpFrom;

  bool startTLS;

  bool loginRequired;

  String? settingsPassword;

  String oidcIssuer;

  String oidcClientId;

  String? oidcClientSecret;

  String oidcScopes;

  String oidcButtonLabel;

  String oidcAllowedEmailDomains;

  String oidcAdminEmails;

  String oidcDepartmentClaim;

  String authPublicUrl;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Settings]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Settings copyWith({
    int? id,
    bool? demoMode,
    int? demoModeRetentionHours,
    String? baseDir,
    String? projectDir,
    String? genomeDir,
    String? customSnpDir,
    String? snpSourceAllowedHosts,
    String? toolsDir,
    String? mipgenExecutable,
    String? exonExtractScript,
    String? ucscTrackGenerator,
    String? binCreationScript,
    String? bigGenePredToGenePredExecutable,
    bool? mailActive,
    String? smtpServer,
    int? smtpPort,
    String? smtpUser,
    String? smtpPassword,
    String? smtpFrom,
    bool? startTLS,
    bool? loginRequired,
    String? settingsPassword,
    String? oidcIssuer,
    String? oidcClientId,
    String? oidcClientSecret,
    String? oidcScopes,
    String? oidcButtonLabel,
    String? oidcAllowedEmailDomains,
    String? oidcAdminEmails,
    String? oidcDepartmentClaim,
    String? authPublicUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Settings',
      if (id != null) 'id': id,
      'demoMode': demoMode,
      'demoModeRetentionHours': demoModeRetentionHours,
      'baseDir': baseDir,
      'projectDir': projectDir,
      'genomeDir': genomeDir,
      'customSnpDir': customSnpDir,
      'snpSourceAllowedHosts': snpSourceAllowedHosts,
      'toolsDir': toolsDir,
      'mipgenExecutable': mipgenExecutable,
      'exonExtractScript': exonExtractScript,
      'ucscTrackGenerator': ucscTrackGenerator,
      'binCreationScript': binCreationScript,
      'bigGenePredToGenePredExecutable': bigGenePredToGenePredExecutable,
      'mailActive': mailActive,
      'smtpServer': smtpServer,
      'smtpPort': smtpPort,
      'smtpUser': smtpUser,
      if (smtpPassword != null) 'smtpPassword': smtpPassword,
      'smtpFrom': smtpFrom,
      'startTLS': startTLS,
      'loginRequired': loginRequired,
      if (settingsPassword != null) 'settingsPassword': settingsPassword,
      'oidcIssuer': oidcIssuer,
      'oidcClientId': oidcClientId,
      if (oidcClientSecret != null) 'oidcClientSecret': oidcClientSecret,
      'oidcScopes': oidcScopes,
      'oidcButtonLabel': oidcButtonLabel,
      'oidcAllowedEmailDomains': oidcAllowedEmailDomains,
      'oidcAdminEmails': oidcAdminEmails,
      'oidcDepartmentClaim': oidcDepartmentClaim,
      'authPublicUrl': authPublicUrl,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Settings',
      if (id != null) 'id': id,
      'demoMode': demoMode,
      'demoModeRetentionHours': demoModeRetentionHours,
      'baseDir': baseDir,
      'projectDir': projectDir,
      'genomeDir': genomeDir,
      'customSnpDir': customSnpDir,
      'snpSourceAllowedHosts': snpSourceAllowedHosts,
      'toolsDir': toolsDir,
      'mipgenExecutable': mipgenExecutable,
      'exonExtractScript': exonExtractScript,
      'ucscTrackGenerator': ucscTrackGenerator,
      'binCreationScript': binCreationScript,
      'bigGenePredToGenePredExecutable': bigGenePredToGenePredExecutable,
      'mailActive': mailActive,
      'smtpServer': smtpServer,
      'smtpPort': smtpPort,
      'smtpUser': smtpUser,
      'smtpFrom': smtpFrom,
      'startTLS': startTLS,
      'loginRequired': loginRequired,
      'oidcIssuer': oidcIssuer,
      'oidcClientId': oidcClientId,
      'oidcScopes': oidcScopes,
      'oidcButtonLabel': oidcButtonLabel,
      'oidcAllowedEmailDomains': oidcAllowedEmailDomains,
      'oidcAdminEmails': oidcAdminEmails,
      'oidcDepartmentClaim': oidcDepartmentClaim,
      'authPublicUrl': authPublicUrl,
    };
  }

  static SettingsInclude include() {
    return SettingsInclude._();
  }

  static SettingsIncludeList includeList({
    _is.WhereExpressionBuilder<SettingsTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SettingsTable>? orderBy,
    _is.OrderByListBuilder<SettingsTable>? orderByList,
    SettingsInclude? include,
  }) {
    return SettingsIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Settings.t),
      orderByList: orderByList?.call(Settings.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SettingsImpl extends Settings {
  _SettingsImpl({
    int? id,
    bool? demoMode,
    int? demoModeRetentionHours,
    String? baseDir,
    String? projectDir,
    String? genomeDir,
    String? customSnpDir,
    String? snpSourceAllowedHosts,
    String? toolsDir,
    String? mipgenExecutable,
    String? exonExtractScript,
    String? ucscTrackGenerator,
    String? binCreationScript,
    String? bigGenePredToGenePredExecutable,
    bool? mailActive,
    String? smtpServer,
    int? smtpPort,
    String? smtpUser,
    String? smtpPassword,
    String? smtpFrom,
    bool? startTLS,
    bool? loginRequired,
    String? settingsPassword,
    String? oidcIssuer,
    String? oidcClientId,
    String? oidcClientSecret,
    String? oidcScopes,
    String? oidcButtonLabel,
    String? oidcAllowedEmailDomains,
    String? oidcAdminEmails,
    String? oidcDepartmentClaim,
    String? authPublicUrl,
  }) : super._(
         id: id,
         demoMode: demoMode,
         demoModeRetentionHours: demoModeRetentionHours,
         baseDir: baseDir,
         projectDir: projectDir,
         genomeDir: genomeDir,
         customSnpDir: customSnpDir,
         snpSourceAllowedHosts: snpSourceAllowedHosts,
         toolsDir: toolsDir,
         mipgenExecutable: mipgenExecutable,
         exonExtractScript: exonExtractScript,
         ucscTrackGenerator: ucscTrackGenerator,
         binCreationScript: binCreationScript,
         bigGenePredToGenePredExecutable: bigGenePredToGenePredExecutable,
         mailActive: mailActive,
         smtpServer: smtpServer,
         smtpPort: smtpPort,
         smtpUser: smtpUser,
         smtpPassword: smtpPassword,
         smtpFrom: smtpFrom,
         startTLS: startTLS,
         loginRequired: loginRequired,
         settingsPassword: settingsPassword,
         oidcIssuer: oidcIssuer,
         oidcClientId: oidcClientId,
         oidcClientSecret: oidcClientSecret,
         oidcScopes: oidcScopes,
         oidcButtonLabel: oidcButtonLabel,
         oidcAllowedEmailDomains: oidcAllowedEmailDomains,
         oidcAdminEmails: oidcAdminEmails,
         oidcDepartmentClaim: oidcDepartmentClaim,
         authPublicUrl: authPublicUrl,
       );

  /// Returns a shallow copy of this [Settings]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Settings copyWith({
    Object? id = _Undefined,
    bool? demoMode,
    int? demoModeRetentionHours,
    String? baseDir,
    String? projectDir,
    String? genomeDir,
    String? customSnpDir,
    String? snpSourceAllowedHosts,
    String? toolsDir,
    String? mipgenExecutable,
    String? exonExtractScript,
    String? ucscTrackGenerator,
    String? binCreationScript,
    String? bigGenePredToGenePredExecutable,
    bool? mailActive,
    String? smtpServer,
    int? smtpPort,
    String? smtpUser,
    Object? smtpPassword = _Undefined,
    String? smtpFrom,
    bool? startTLS,
    bool? loginRequired,
    Object? settingsPassword = _Undefined,
    String? oidcIssuer,
    String? oidcClientId,
    Object? oidcClientSecret = _Undefined,
    String? oidcScopes,
    String? oidcButtonLabel,
    String? oidcAllowedEmailDomains,
    String? oidcAdminEmails,
    String? oidcDepartmentClaim,
    String? authPublicUrl,
  }) {
    return Settings(
      id: id is int? ? id : this.id,
      demoMode: demoMode ?? this.demoMode,
      demoModeRetentionHours:
          demoModeRetentionHours ?? this.demoModeRetentionHours,
      baseDir: baseDir ?? this.baseDir,
      projectDir: projectDir ?? this.projectDir,
      genomeDir: genomeDir ?? this.genomeDir,
      customSnpDir: customSnpDir ?? this.customSnpDir,
      snpSourceAllowedHosts:
          snpSourceAllowedHosts ?? this.snpSourceAllowedHosts,
      toolsDir: toolsDir ?? this.toolsDir,
      mipgenExecutable: mipgenExecutable ?? this.mipgenExecutable,
      exonExtractScript: exonExtractScript ?? this.exonExtractScript,
      ucscTrackGenerator: ucscTrackGenerator ?? this.ucscTrackGenerator,
      binCreationScript: binCreationScript ?? this.binCreationScript,
      bigGenePredToGenePredExecutable:
          bigGenePredToGenePredExecutable ??
          this.bigGenePredToGenePredExecutable,
      mailActive: mailActive ?? this.mailActive,
      smtpServer: smtpServer ?? this.smtpServer,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpUser: smtpUser ?? this.smtpUser,
      smtpPassword: smtpPassword is String? ? smtpPassword : this.smtpPassword,
      smtpFrom: smtpFrom ?? this.smtpFrom,
      startTLS: startTLS ?? this.startTLS,
      loginRequired: loginRequired ?? this.loginRequired,
      settingsPassword: settingsPassword is String?
          ? settingsPassword
          : this.settingsPassword,
      oidcIssuer: oidcIssuer ?? this.oidcIssuer,
      oidcClientId: oidcClientId ?? this.oidcClientId,
      oidcClientSecret: oidcClientSecret is String?
          ? oidcClientSecret
          : this.oidcClientSecret,
      oidcScopes: oidcScopes ?? this.oidcScopes,
      oidcButtonLabel: oidcButtonLabel ?? this.oidcButtonLabel,
      oidcAllowedEmailDomains:
          oidcAllowedEmailDomains ?? this.oidcAllowedEmailDomains,
      oidcAdminEmails: oidcAdminEmails ?? this.oidcAdminEmails,
      oidcDepartmentClaim: oidcDepartmentClaim ?? this.oidcDepartmentClaim,
      authPublicUrl: authPublicUrl ?? this.authPublicUrl,
    );
  }
}

class SettingsUpdateTable extends _is.UpdateTable<SettingsTable> {
  SettingsUpdateTable(super.table);

  _is.ColumnValue<bool, bool> demoMode(bool value) =>
      _is.ColumnValue(table.demoMode, value);

  _is.ColumnValue<int, int> demoModeRetentionHours(int value) =>
      _is.ColumnValue(table.demoModeRetentionHours, value);

  _is.ColumnValue<String, String> baseDir(String value) =>
      _is.ColumnValue(table.baseDir, value);

  _is.ColumnValue<String, String> projectDir(String value) =>
      _is.ColumnValue(table.projectDir, value);

  _is.ColumnValue<String, String> genomeDir(String value) =>
      _is.ColumnValue(table.genomeDir, value);

  _is.ColumnValue<String, String> customSnpDir(String value) =>
      _is.ColumnValue(table.customSnpDir, value);

  _is.ColumnValue<String, String> snpSourceAllowedHosts(String value) =>
      _is.ColumnValue(table.snpSourceAllowedHosts, value);

  _is.ColumnValue<String, String> toolsDir(String value) =>
      _is.ColumnValue(table.toolsDir, value);

  _is.ColumnValue<String, String> mipgenExecutable(String value) =>
      _is.ColumnValue(table.mipgenExecutable, value);

  _is.ColumnValue<String, String> exonExtractScript(String value) =>
      _is.ColumnValue(table.exonExtractScript, value);

  _is.ColumnValue<String, String> ucscTrackGenerator(String value) =>
      _is.ColumnValue(table.ucscTrackGenerator, value);

  _is.ColumnValue<String, String> binCreationScript(String value) =>
      _is.ColumnValue(table.binCreationScript, value);

  _is.ColumnValue<String, String> bigGenePredToGenePredExecutable(
    String value,
  ) => _is.ColumnValue(table.bigGenePredToGenePredExecutable, value);

  _is.ColumnValue<bool, bool> mailActive(bool value) =>
      _is.ColumnValue(table.mailActive, value);

  _is.ColumnValue<String, String> smtpServer(String value) =>
      _is.ColumnValue(table.smtpServer, value);

  _is.ColumnValue<int, int> smtpPort(int value) =>
      _is.ColumnValue(table.smtpPort, value);

  _is.ColumnValue<String, String> smtpUser(String value) =>
      _is.ColumnValue(table.smtpUser, value);

  _is.ColumnValue<String, String> smtpPassword(String? value) =>
      _is.ColumnValue(table.smtpPassword, value);

  _is.ColumnValue<String, String> smtpFrom(String value) =>
      _is.ColumnValue(table.smtpFrom, value);

  _is.ColumnValue<bool, bool> startTLS(bool value) =>
      _is.ColumnValue(table.startTLS, value);

  _is.ColumnValue<bool, bool> loginRequired(bool value) =>
      _is.ColumnValue(table.loginRequired, value);

  _is.ColumnValue<String, String> settingsPassword(String? value) =>
      _is.ColumnValue(table.settingsPassword, value);

  _is.ColumnValue<String, String> oidcIssuer(String value) =>
      _is.ColumnValue(table.oidcIssuer, value);

  _is.ColumnValue<String, String> oidcClientId(String value) =>
      _is.ColumnValue(table.oidcClientId, value);

  _is.ColumnValue<String, String> oidcClientSecret(String? value) =>
      _is.ColumnValue(table.oidcClientSecret, value);

  _is.ColumnValue<String, String> oidcScopes(String value) =>
      _is.ColumnValue(table.oidcScopes, value);

  _is.ColumnValue<String, String> oidcButtonLabel(String value) =>
      _is.ColumnValue(table.oidcButtonLabel, value);

  _is.ColumnValue<String, String> oidcAllowedEmailDomains(String value) =>
      _is.ColumnValue(table.oidcAllowedEmailDomains, value);

  _is.ColumnValue<String, String> oidcAdminEmails(String value) =>
      _is.ColumnValue(table.oidcAdminEmails, value);

  _is.ColumnValue<String, String> oidcDepartmentClaim(String value) =>
      _is.ColumnValue(table.oidcDepartmentClaim, value);

  _is.ColumnValue<String, String> authPublicUrl(String value) =>
      _is.ColumnValue(table.authPublicUrl, value);
}

class SettingsTable extends _is.Table<int?> {
  SettingsTable({super.tableRelation}) : super(tableName: 'settings') {
    updateTable = SettingsUpdateTable(this);
    demoMode = _is.ColumnBool('demoMode', this, hasDefault: true);
    demoModeRetentionHours = _is.ColumnInt(
      'demoModeRetentionHours',
      this,
      hasDefault: true,
    );
    baseDir = _is.ColumnString('baseDir', this, hasDefault: true);
    projectDir = _is.ColumnString('projectDir', this, hasDefault: true);
    genomeDir = _is.ColumnString('genomeDir', this, hasDefault: true);
    customSnpDir = _is.ColumnString('customSnpDir', this, hasDefault: true);
    snpSourceAllowedHosts = _is.ColumnString(
      'snpSourceAllowedHosts',
      this,
      hasDefault: true,
    );
    toolsDir = _is.ColumnString('toolsDir', this, hasDefault: true);
    mipgenExecutable = _is.ColumnString(
      'mipgenExecutable',
      this,
      hasDefault: true,
    );
    exonExtractScript = _is.ColumnString(
      'exonExtractScript',
      this,
      hasDefault: true,
    );
    ucscTrackGenerator = _is.ColumnString(
      'ucscTrackGenerator',
      this,
      hasDefault: true,
    );
    binCreationScript = _is.ColumnString(
      'binCreationScript',
      this,
      hasDefault: true,
    );
    bigGenePredToGenePredExecutable = _is.ColumnString(
      'bigGenePredToGenePredExecutable',
      this,
      hasDefault: true,
    );
    mailActive = _is.ColumnBool('mailActive', this, hasDefault: true);
    smtpServer = _is.ColumnString('smtpServer', this, hasDefault: true);
    smtpPort = _is.ColumnInt('smtpPort', this, hasDefault: true);
    smtpUser = _is.ColumnString('smtpUser', this, hasDefault: true);
    smtpPassword = _is.ColumnString('smtpPassword', this);
    smtpFrom = _is.ColumnString('smtpFrom', this, hasDefault: true);
    startTLS = _is.ColumnBool('startTLS', this, hasDefault: true);
    loginRequired = _is.ColumnBool('loginRequired', this, hasDefault: true);
    settingsPassword = _is.ColumnString('settingsPassword', this);
    oidcIssuer = _is.ColumnString('oidcIssuer', this, hasDefault: true);
    oidcClientId = _is.ColumnString('oidcClientId', this, hasDefault: true);
    oidcClientSecret = _is.ColumnString('oidcClientSecret', this);
    oidcScopes = _is.ColumnString('oidcScopes', this, hasDefault: true);
    oidcButtonLabel = _is.ColumnString(
      'oidcButtonLabel',
      this,
      hasDefault: true,
    );
    oidcAllowedEmailDomains = _is.ColumnString(
      'oidcAllowedEmailDomains',
      this,
      hasDefault: true,
    );
    oidcAdminEmails = _is.ColumnString(
      'oidcAdminEmails',
      this,
      hasDefault: true,
    );
    oidcDepartmentClaim = _is.ColumnString(
      'oidcDepartmentClaim',
      this,
      hasDefault: true,
    );
    authPublicUrl = _is.ColumnString('authPublicUrl', this, hasDefault: true);
  }

  late final SettingsUpdateTable updateTable;

  late final _is.ColumnBool demoMode;

  /// How long a project survives on a demo install, in hours. 168 = 7 days.
  ///
  /// ⚠️ Read when the cleanup call *fires*, not only when it is scheduled, so
  /// raising it spares projects that were already queued. Lowering it cannot
  /// pull a scheduled deletion earlier — that project keeps the deadline it was
  /// created with. See DemoModeCleanup.
  late final _is.ColumnInt demoModeRetentionHours;

  late final _is.ColumnString baseDir;

  late final _is.ColumnString projectDir;

  late final _is.ColumnString genomeDir;

  late final _is.ColumnString customSnpDir;

  late final _is.ColumnString snpSourceAllowedHosts;

  late final _is.ColumnString toolsDir;

  late final _is.ColumnString mipgenExecutable;

  late final _is.ColumnString exonExtractScript;

  late final _is.ColumnString ucscTrackGenerator;

  late final _is.ColumnString binCreationScript;

  late final _is.ColumnString bigGenePredToGenePredExecutable;

  late final _is.ColumnBool mailActive;

  late final _is.ColumnString smtpServer;

  late final _is.ColumnInt smtpPort;

  late final _is.ColumnString smtpUser;

  late final _is.ColumnString smtpPassword;

  late final _is.ColumnString smtpFrom;

  late final _is.ColumnBool startTLS;

  late final _is.ColumnBool loginRequired;

  late final _is.ColumnString settingsPassword;

  late final _is.ColumnString oidcIssuer;

  late final _is.ColumnString oidcClientId;

  late final _is.ColumnString oidcClientSecret;

  late final _is.ColumnString oidcScopes;

  late final _is.ColumnString oidcButtonLabel;

  late final _is.ColumnString oidcAllowedEmailDomains;

  late final _is.ColumnString oidcAdminEmails;

  late final _is.ColumnString oidcDepartmentClaim;

  late final _is.ColumnString authPublicUrl;

  @override
  List<_is.Column> get columns => [
    id,
    demoMode,
    demoModeRetentionHours,
    baseDir,
    projectDir,
    genomeDir,
    customSnpDir,
    snpSourceAllowedHosts,
    toolsDir,
    mipgenExecutable,
    exonExtractScript,
    ucscTrackGenerator,
    binCreationScript,
    bigGenePredToGenePredExecutable,
    mailActive,
    smtpServer,
    smtpPort,
    smtpUser,
    smtpPassword,
    smtpFrom,
    startTLS,
    loginRequired,
    settingsPassword,
    oidcIssuer,
    oidcClientId,
    oidcClientSecret,
    oidcScopes,
    oidcButtonLabel,
    oidcAllowedEmailDomains,
    oidcAdminEmails,
    oidcDepartmentClaim,
    authPublicUrl,
  ];
}

class SettingsInclude extends _is.IncludeObject {
  SettingsInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Settings.t;
}

class SettingsIncludeList extends _is.IncludeList {
  SettingsIncludeList._({
    _is.WhereExpressionBuilder<SettingsTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Settings.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Settings.t;
}

class SettingsRepository {
  const SettingsRepository._();

  /// Returns a list of [Settings]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Settings>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SettingsTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SettingsTable>? orderBy,
    _is.OrderByListBuilder<SettingsTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Settings>(
      where: where?.call(Settings.t),
      orderBy: orderBy?.call(Settings.t),
      orderByList: orderByList?.call(Settings.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Settings] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Settings?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SettingsTable>? where,
    int? offset,
    _is.OrderByBuilder<SettingsTable>? orderBy,
    _is.OrderByListBuilder<SettingsTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Settings>(
      where: where?.call(Settings.t),
      orderBy: orderBy?.call(Settings.t),
      orderByList: orderByList?.call(Settings.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Settings] by its [id] or null if no such row exists.
  Future<Settings?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Settings>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Settings]s in the list and returns the inserted rows.
  ///
  /// The returned [Settings]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Settings>> insert(
    _is.DatabaseSession session,
    List<Settings> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Settings>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Settings] and returns the inserted row.
  ///
  /// The returned [Settings] will have its `id` field set.
  Future<Settings> insertRow(
    _is.DatabaseSession session,
    Settings row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Settings>(row, transaction: transaction);
  }

  /// Upserts all [Settings]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [Settings]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Settings>> upsert(
    _is.DatabaseSession session,
    List<Settings> rows, {
    required _is.ColumnSelections<SettingsTable> conflictColumns,
    _is.ColumnSelections<SettingsTable>? updateColumns,
    _is.WhereExpressionBuilder<SettingsTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Settings>(
      rows,
      conflictColumns: conflictColumns(Settings.t),
      updateColumns: updateColumns?.call(Settings.t),
      updateWhere: updateWhere?.call(Settings.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Settings] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [Settings] will have its `id` field set.
  Future<Settings?> upsertRow(
    _is.DatabaseSession session,
    Settings row, {
    required _is.ColumnSelections<SettingsTable> conflictColumns,
    _is.ColumnSelections<SettingsTable>? updateColumns,
    _is.WhereExpressionBuilder<SettingsTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Settings>(
      row,
      conflictColumns: conflictColumns(Settings.t),
      updateColumns: updateColumns?.call(Settings.t),
      updateWhere: updateWhere?.call(Settings.t),
      transaction: transaction,
    );
  }

  /// Updates all [Settings]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Settings>> update(
    _is.DatabaseSession session,
    List<Settings> rows, {
    _is.ColumnSelections<SettingsTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Settings>(
      rows,
      columns: columns?.call(Settings.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Settings]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Settings> updateRow(
    _is.DatabaseSession session,
    Settings row, {
    _is.ColumnSelections<SettingsTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Settings>(
      row,
      columns: columns?.call(Settings.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Settings] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Settings?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<SettingsUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Settings>(
      id,
      columnValues: columnValues(Settings.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Settings]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Settings>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SettingsUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SettingsTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SettingsTable>? orderBy,
    _is.OrderByListBuilder<SettingsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Settings>(
      columnValues: columnValues(Settings.t.updateTable),
      where: where(Settings.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Settings.t),
      orderByList: orderByList?.call(Settings.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Settings]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Settings>> delete(
    _is.DatabaseSession session,
    List<Settings> rows, {
    _is.OrderByBuilder<SettingsTable>? orderBy,
    _is.OrderByListBuilder<SettingsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Settings>(
      rows,
      orderBy: orderBy?.call(Settings.t),
      orderByList: orderByList?.call(Settings.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Settings].
  Future<Settings> deleteRow(
    _is.DatabaseSession session,
    Settings row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Settings>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Settings>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SettingsTable> where,
    _is.OrderByBuilder<SettingsTable>? orderBy,
    _is.OrderByListBuilder<SettingsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Settings>(
      where: where(Settings.t),
      orderBy: orderBy?.call(Settings.t),
      orderByList: orderByList?.call(Settings.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SettingsTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Settings>(
      where: where?.call(Settings.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Settings] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SettingsTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Settings>(
      where: where(Settings.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
