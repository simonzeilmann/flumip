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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class Settings implements _i1.SerializableModel {
  Settings._({
    this.id,
    bool? demoMode,
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
    String? smtpFrom,
    bool? startTLS,
    bool? loginRequired,
    String? settingsPassword,
    String? oidcIssuer,
    String? oidcClientId,
    String? oidcScopes,
    String? oidcButtonLabel,
    String? oidcAllowedEmailDomains,
    String? oidcAdminEmails,
    String? authPublicUrl,
  }) : demoMode = demoMode ?? false,
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
       settingsPassword = settingsPassword ?? 'changeme',
       oidcIssuer = oidcIssuer ?? '',
       oidcClientId = oidcClientId ?? '',
       oidcScopes = oidcScopes ?? 'openid email profile',
       oidcButtonLabel = oidcButtonLabel ?? 'Sign in with SSO',
       oidcAllowedEmailDomains = oidcAllowedEmailDomains ?? '',
       oidcAdminEmails = oidcAdminEmails ?? '',
       authPublicUrl = authPublicUrl ?? '';

  factory Settings({
    int? id,
    bool? demoMode,
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
    String? smtpFrom,
    bool? startTLS,
    bool? loginRequired,
    String? settingsPassword,
    String? oidcIssuer,
    String? oidcClientId,
    String? oidcScopes,
    String? oidcButtonLabel,
    String? oidcAllowedEmailDomains,
    String? oidcAdminEmails,
    String? authPublicUrl,
  }) = _SettingsImpl;

  factory Settings.fromJson(Map<String, dynamic> jsonSerialization) {
    return Settings(
      id: jsonSerialization['id'] as int?,
      demoMode: jsonSerialization['demoMode'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['demoMode']),
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
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['mailActive']),
      smtpServer: jsonSerialization['smtpServer'] as String?,
      smtpPort: jsonSerialization['smtpPort'] as int?,
      smtpUser: jsonSerialization['smtpUser'] as String?,
      smtpFrom: jsonSerialization['smtpFrom'] as String?,
      startTLS: jsonSerialization['startTLS'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['startTLS']),
      loginRequired: jsonSerialization['loginRequired'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['loginRequired']),
      settingsPassword: jsonSerialization['settingsPassword'] as String?,
      oidcIssuer: jsonSerialization['oidcIssuer'] as String?,
      oidcClientId: jsonSerialization['oidcClientId'] as String?,
      oidcScopes: jsonSerialization['oidcScopes'] as String?,
      oidcButtonLabel: jsonSerialization['oidcButtonLabel'] as String?,
      oidcAllowedEmailDomains:
          jsonSerialization['oidcAllowedEmailDomains'] as String?,
      oidcAdminEmails: jsonSerialization['oidcAdminEmails'] as String?,
      authPublicUrl: jsonSerialization['authPublicUrl'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  bool demoMode;

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

  String smtpFrom;

  bool startTLS;

  bool loginRequired;

  String settingsPassword;

  String oidcIssuer;

  String oidcClientId;

  String oidcScopes;

  String oidcButtonLabel;

  String oidcAllowedEmailDomains;

  String oidcAdminEmails;

  String authPublicUrl;

  /// Returns a shallow copy of this [Settings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Settings copyWith({
    int? id,
    bool? demoMode,
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
    String? smtpFrom,
    bool? startTLS,
    bool? loginRequired,
    String? settingsPassword,
    String? oidcIssuer,
    String? oidcClientId,
    String? oidcScopes,
    String? oidcButtonLabel,
    String? oidcAllowedEmailDomains,
    String? oidcAdminEmails,
    String? authPublicUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Settings',
      if (id != null) 'id': id,
      'demoMode': demoMode,
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
      'settingsPassword': settingsPassword,
      'oidcIssuer': oidcIssuer,
      'oidcClientId': oidcClientId,
      'oidcScopes': oidcScopes,
      'oidcButtonLabel': oidcButtonLabel,
      'oidcAllowedEmailDomains': oidcAllowedEmailDomains,
      'oidcAdminEmails': oidcAdminEmails,
      'authPublicUrl': authPublicUrl,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SettingsImpl extends Settings {
  _SettingsImpl({
    int? id,
    bool? demoMode,
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
    String? smtpFrom,
    bool? startTLS,
    bool? loginRequired,
    String? settingsPassword,
    String? oidcIssuer,
    String? oidcClientId,
    String? oidcScopes,
    String? oidcButtonLabel,
    String? oidcAllowedEmailDomains,
    String? oidcAdminEmails,
    String? authPublicUrl,
  }) : super._(
         id: id,
         demoMode: demoMode,
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
         smtpFrom: smtpFrom,
         startTLS: startTLS,
         loginRequired: loginRequired,
         settingsPassword: settingsPassword,
         oidcIssuer: oidcIssuer,
         oidcClientId: oidcClientId,
         oidcScopes: oidcScopes,
         oidcButtonLabel: oidcButtonLabel,
         oidcAllowedEmailDomains: oidcAllowedEmailDomains,
         oidcAdminEmails: oidcAdminEmails,
         authPublicUrl: authPublicUrl,
       );

  /// Returns a shallow copy of this [Settings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Settings copyWith({
    Object? id = _Undefined,
    bool? demoMode,
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
    String? smtpFrom,
    bool? startTLS,
    bool? loginRequired,
    String? settingsPassword,
    String? oidcIssuer,
    String? oidcClientId,
    String? oidcScopes,
    String? oidcButtonLabel,
    String? oidcAllowedEmailDomains,
    String? oidcAdminEmails,
    String? authPublicUrl,
  }) {
    return Settings(
      id: id is int? ? id : this.id,
      demoMode: demoMode ?? this.demoMode,
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
      smtpFrom: smtpFrom ?? this.smtpFrom,
      startTLS: startTLS ?? this.startTLS,
      loginRequired: loginRequired ?? this.loginRequired,
      settingsPassword: settingsPassword ?? this.settingsPassword,
      oidcIssuer: oidcIssuer ?? this.oidcIssuer,
      oidcClientId: oidcClientId ?? this.oidcClientId,
      oidcScopes: oidcScopes ?? this.oidcScopes,
      oidcButtonLabel: oidcButtonLabel ?? this.oidcButtonLabel,
      oidcAllowedEmailDomains:
          oidcAllowedEmailDomains ?? this.oidcAllowedEmailDomains,
      oidcAdminEmails: oidcAdminEmails ?? this.oidcAdminEmails,
      authPublicUrl: authPublicUrl ?? this.authPublicUrl,
    );
  }
}
