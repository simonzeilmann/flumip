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
  }) : demoMode = demoMode ?? false,
       baseDir = baseDir ?? '/opt/flumip',
       projectDir = projectDir ?? '/opt/flumip/projects',
       genomeDir = genomeDir ?? '/opt/flumip/data/genomes',
       customSnpDir = customSnpDir ?? '/opt/flumip/data/custom_snp',
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
       smtpPassword = smtpPassword ?? '',
       smtpFrom = smtpFrom ?? 'flumip@yourdomain.com',
       startTLS = startTLS ?? true,
       loginRequired = loginRequired ?? false,
       settingsPassword = settingsPassword ?? 'changeme';

  factory Settings({
    int? id,
    bool? demoMode,
    String? baseDir,
    String? projectDir,
    String? genomeDir,
    String? customSnpDir,
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
  }) = _SettingsImpl;

  factory Settings.fromJson(Map<String, dynamic> jsonSerialization) {
    return Settings(
      id: jsonSerialization['id'] as int?,
      demoMode: jsonSerialization['demoMode'] as bool,
      baseDir: jsonSerialization['baseDir'] as String,
      projectDir: jsonSerialization['projectDir'] as String,
      genomeDir: jsonSerialization['genomeDir'] as String,
      customSnpDir: jsonSerialization['customSnpDir'] as String,
      toolsDir: jsonSerialization['toolsDir'] as String,
      mipgenExecutable: jsonSerialization['mipgenExecutable'] as String,
      exonExtractScript: jsonSerialization['exonExtractScript'] as String,
      ucscTrackGenerator: jsonSerialization['ucscTrackGenerator'] as String,
      binCreationScript: jsonSerialization['binCreationScript'] as String,
      bigGenePredToGenePredExecutable:
          jsonSerialization['bigGenePredToGenePredExecutable'] as String,
      mailActive: jsonSerialization['mailActive'] as bool,
      smtpServer: jsonSerialization['smtpServer'] as String,
      smtpPort: jsonSerialization['smtpPort'] as int,
      smtpUser: jsonSerialization['smtpUser'] as String,
      smtpPassword: jsonSerialization['smtpPassword'] as String,
      smtpFrom: jsonSerialization['smtpFrom'] as String,
      startTLS: jsonSerialization['startTLS'] as bool,
      loginRequired: jsonSerialization['loginRequired'] as bool,
      settingsPassword: jsonSerialization['settingsPassword'] as String,
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

  String smtpPassword;

  String smtpFrom;

  bool startTLS;

  bool loginRequired;

  String settingsPassword;

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
      'smtpPassword': smtpPassword,
      'smtpFrom': smtpFrom,
      'startTLS': startTLS,
      'loginRequired': loginRequired,
      'settingsPassword': settingsPassword,
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
  }) : super._(
         id: id,
         demoMode: demoMode,
         baseDir: baseDir,
         projectDir: projectDir,
         genomeDir: genomeDir,
         customSnpDir: customSnpDir,
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
  }) {
    return Settings(
      id: id is int? ? id : this.id,
      demoMode: demoMode ?? this.demoMode,
      baseDir: baseDir ?? this.baseDir,
      projectDir: projectDir ?? this.projectDir,
      genomeDir: genomeDir ?? this.genomeDir,
      customSnpDir: customSnpDir ?? this.customSnpDir,
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
      smtpPassword: smtpPassword ?? this.smtpPassword,
      smtpFrom: smtpFrom ?? this.smtpFrom,
      startTLS: startTLS ?? this.startTLS,
      loginRequired: loginRequired ?? this.loginRequired,
      settingsPassword: settingsPassword ?? this.settingsPassword,
    );
  }
}
