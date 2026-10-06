import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/serverpod.dart';

/// Test seeding helpers that insert rows directly (no filesystem side effects),
/// so pure-DB tests don't depend on `/opt/flumip`. Use `projectService`'s own
/// methods when a real project directory is required.

Future<Genome> seedGenome(
  Session session, {
  String name = 'hg38',
  String description = '',
  String? path,
  String? fastaPath,
  String? refPath,
  String? snpFolder,
  String? category,
  bool indexed = false,
  bool indexing = false,
  int indexPID = 0,
}) {
  return Genome.db.insertRow(
    session,
    Genome(
      name: name,
      description: description,
      path: path,
      fastaPath: fastaPath,
      refPath: refPath,
      snpFolder: snpFolder,
      category: category,
      indexed: indexed,
      indexing: indexing,
      indexPID: indexPID,
    ),
  );
}

Future<Snp> seedSnp(
  Session session, {
  String name = 'common',
  String description = '',
  String vcfPath = '/tmp/snp.vcf.gz',
  String tbiPath = '/tmp/snp.vcf.gz.tbi',
  String folder = '/tmp/snp',
  bool private = false,
  int? genome,
  int? owner,
  bool custom = false,
  SnpImportStatus status = SnpImportStatus.ready,
  String statusMessage = '',
  DateTime? statusUpdated,
  int size = 0,
  String? sourceVcfUrl,
}) {
  return Snp.db.insertRow(
    session,
    Snp(
      name: name,
      description: description,
      sourceVcfUrl: sourceVcfUrl,
      vcfPath: vcfPath,
      tbiPath: tbiPath,
      folder: folder,
      private: private,
      genome: genome,
      owner: owner,
      custom: custom,
      status: status,
      statusMessage: statusMessage,
      statusUpdated: statusUpdated,
      size: size,
      created: DateTime.now().toUtc(),
    ),
  );
}

/// Inserts a [Project] row directly. [options] must reference an existing
/// [ProjectOptions] id (seed one with [seedOptions] first if needed).
Future<Project> seedProject(
  Session session, {
  String name = 'test',
  String description = '',
  required int options,
  String? folderName,
  int? genome,
  int? snp,
  List<String>? genes,
  int? pid,
  bool active = false,
  DateTime? started,
  int? owner,
  String? trackToken,
}) {
  return Project.db.insertRow(
    session,
    Project(
      name: name,
      description: description,
      options: options,
      folderName: folderName,
      genome: genome,
      snp: snp,
      genes: genes,
      pid: pid,
      active: active,
      started: started,
      // Null owner is the default on purpose: it is what every project on an
      // install that predates authorization has, and what projects created while
      // single sign-on is off keep having.
      owner: owner,
      trackToken: trackToken,
    ),
  );
}

/// Inserts a [FlumipUser] and an [AuthSession] for it, and returns both.
///
/// Authorization tests need a *real* AuthSession row, not just an
/// [AuthenticationOverride]: `AuthorizationService` resolves the caller's user id
/// by parsing `AuthenticationInfo.authId` as an AuthSession id and reading that
/// row. Overriding the authentication without seeding the row yields a principal
/// with a null `userId`, which can never own anything — so the ownership rules
/// would look broken while actually being untested.
Future<({FlumipUser user, AuthSession authSession})> seedSignedInUser(
  Session session, {
  required String email,
  String issuer = 'https://idp.example.org',
  bool isAdmin = false,
  Duration validFor = const Duration(hours: 1),
}) async {
  final user = await FlumipUser.db.insertRow(
    session,
    FlumipUser(email: email, subject: email, issuer: issuer),
  );
  final authSession = await AuthSession.db.insertRow(
    session,
    AuthSession(
      userId: user.id!,
      cookieHash: 'cookie-hash-for-$email',
      email: email,
      isAdmin: isAdmin,
      expires: DateTime.now().toUtc().add(validFor),
    ),
  );
  return (user: user, authSession: authSession);
}

Future<ProjectOptions> seedOptions(Session session) {
  // armLengths is nullable but generateMips dereferences it (armLengths!), so
  // seed a non-null (empty) value to mirror a real configured options row.
  return ProjectOptions.db.insertRow(session, ProjectOptions(armLengths: ''));
}

/// Loads the settings row and overrides the given directory fields, so
/// filesystem tests can point the service at a temp directory instead of
/// `/opt/flumip`.
Future<Settings> overrideSettingsDirs(
  Session session, {
  String? baseDir,
  String? projectDir,
  String? genomeDir,
  String? customSnpDir,
  String? exonExtractScript,
  String? mipgenExecutable,
  String? toolsDir,
}) async {
  final settings = await SettingsService().getSettings(session);
  if (baseDir != null) settings.baseDir = baseDir;
  if (projectDir != null) settings.projectDir = projectDir;
  if (genomeDir != null) settings.genomeDir = genomeDir;
  if (customSnpDir != null) settings.customSnpDir = customSnpDir;
  if (exonExtractScript != null) settings.exonExtractScript = exonExtractScript;
  if (mipgenExecutable != null) settings.mipgenExecutable = mipgenExecutable;
  if (toolsDir != null) settings.toolsDir = toolsDir;
  await SettingsService().updateSettings(session, settings);
  return settings;
}

/// Loads the settings row and overrides the mail/SMTP fields, so notification
/// tests can control the configuration the [MailSender] receives.
Future<Settings> overrideMailSettings(
  Session session, {
  bool? mailActive,
  String? smtpServer,
  int? smtpPort,
  String? smtpUser,
  String? smtpPassword,
  String? smtpFrom,
  bool? startTLS,
}) async {
  final settings = await SettingsService().getSettings(session);
  if (mailActive != null) settings.mailActive = mailActive;
  if (smtpServer != null) settings.smtpServer = smtpServer;
  if (smtpPort != null) settings.smtpPort = smtpPort;
  if (smtpUser != null) settings.smtpUser = smtpUser;
  if (smtpPassword != null) settings.smtpPassword = smtpPassword;
  if (smtpFrom != null) settings.smtpFrom = smtpFrom;
  if (startTLS != null) settings.startTLS = startTLS;
  await SettingsService().updateSettings(session, settings);
  return settings;
}
