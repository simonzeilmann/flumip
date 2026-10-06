import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

/// Every editable value on the settings tab, in one place.
///
/// This was 28 `TextEditingController`s, four `ValueNotifier<bool>`s and a
/// 34-line `dispose` on `_SettingsTabState`, with the read half (`_loadSettings`)
/// and the write half (`updateSettings`) 60 lines apart. Both halves are here
/// now, next to each other, where [load] and [toSettings] can be checked against
/// one another by a test.
///
/// ⚠️ **Created once and owned by the tab's state, never rebuilt.** Three fields
/// depend on that and fail *silently* if it changes:
///
///  * [password] is the credential every settings call is authenticated with. It
///    is typed into the password gate, and must survive that gate unmounting —
///    it looks like a leak when read in isolation and is load-bearing.
///  * [smtpPassword] and [oidcClientSecret] are write-only. The save path reads
///    `.text`, sends it and clears it, so an empty box means "keep what is
///    stored". A controller recreated on every rebuild would always read empty,
///    and the contract would degrade from "typing replaces" to "never replaces" —
///    invisible until somebody tried to change an SMTP password in production.
///
/// ⚠️ The four booleans are plain fields, not `ValueNotifier`s. They were
/// notifiers for a `ValueListenableBuilder` that no longer exists; every reader
/// now goes through the tab's `setState`, so a notifier was four extra objects to
/// create, dispose and keep in step for nothing.
class SettingsForm {
  /// The settings password, used to authenticate every call on this tab.
  ///
  /// Not touched by [load] or [toSettings] — see [newPassword] for the field that
  /// *changes* it.
  final password = TextEditingController();

  final baseDir = TextEditingController();
  final projectDir = TextEditingController();
  final genomeDir = TextEditingController();
  final customSnpDir = TextEditingController();
  final snpSourceAllowedHosts = TextEditingController();

  final toolsDir = TextEditingController();
  final mipgenExecutable = TextEditingController();
  final exonExtractScript = TextEditingController();
  final bigGenePredToGenePred = TextEditingController();

  final smtpServer = TextEditingController();
  final smtpPort = TextEditingController();
  final smtpUser = TextEditingController();
  final smtpFrom = TextEditingController();

  /// ⚠️ Write-only. Never filled by [load]; cleared by the caller after sending.
  final smtpPassword = TextEditingController();

  /// Not a setting — the recipient for the "send test email" button.
  final testMail = TextEditingController();

  /// ⚠️ Write-only, like [smtpPassword] and [oidcClientSecret]. Never filled by
  /// [load]; cleared by the caller after sending, so an empty field means "keep
  /// the current password".
  ///
  /// It used to be loaded with the stored password and sent back verbatim on
  /// every save — which is what made the password readable in the browser, and
  /// meant clearing the box set an empty password. The server now stores only a
  /// hash and has nothing to load here.
  final newPassword = TextEditingController();

  final demoRetentionHours = TextEditingController();

  final oidcIssuer = TextEditingController();
  final oidcClientId = TextEditingController();

  /// ⚠️ Write-only, and `serverOnly` on the model — it has no counterpart on
  /// [Settings] and travels through its own endpoint.
  final oidcClientSecret = TextEditingController();

  final oidcScopes = TextEditingController();
  final oidcButtonLabel = TextEditingController();
  final oidcAllowedDomains = TextEditingController();
  final oidcAdminEmails = TextEditingController();
  final oidcDepartmentClaim = TextEditingController();
  final authPublicUrl = TextEditingController();

  bool mailActive = false;
  bool startTLS = false;
  bool loginRequired = false;
  bool demoMode = false;

  /// Fills the form from what the server holds.
  void load(Settings settings) {
    baseDir.text = settings.baseDir;
    projectDir.text = settings.projectDir;
    genomeDir.text = settings.genomeDir;
    customSnpDir.text = settings.customSnpDir;
    snpSourceAllowedHosts.text = settings.snpSourceAllowedHosts;
    toolsDir.text = settings.toolsDir;
    mipgenExecutable.text = settings.mipgenExecutable;
    exonExtractScript.text = settings.exonExtractScript;
    bigGenePredToGenePred.text = settings.bigGenePredToGenePredExecutable;
    smtpServer.text = settings.smtpServer;
    smtpPort.text = '${settings.smtpPort}';
    smtpUser.text = settings.smtpUser;
    smtpFrom.text = settings.smtpFrom;
    demoRetentionHours.text = '${settings.demoModeRetentionHours}';
    oidcIssuer.text = settings.oidcIssuer;
    oidcClientId.text = settings.oidcClientId;
    oidcScopes.text = settings.oidcScopes;
    oidcButtonLabel.text = settings.oidcButtonLabel;
    oidcAllowedDomains.text = settings.oidcAllowedEmailDomains;
    oidcAdminEmails.text = settings.oidcAdminEmails;
    oidcDepartmentClaim.text = settings.oidcDepartmentClaim;
    authPublicUrl.text = settings.authPublicUrl;

    mailActive = settings.mailActive;
    startTLS = settings.startTLS;
    loginRequired = settings.loginRequired;
    demoMode = settings.demoMode;

    // ⚠️ Cleared, never populated. The server does not send any of these three
    // back, so leaving a stale value here would offer to re-send something this
    // browser cannot know.
    smtpPassword.clear();
    oidcClientSecret.clear();
    newPassword.clear();
  }

  /// What the form currently says, as the object the server stores.
  ///
  /// [id] comes from the loaded settings row; there is only ever one. Nullable
  /// because `Settings.id` is, and passing the loaded value straight through is
  /// safer than asserting on it in the one place a save would go wrong.
  Settings toSettings({required int? id}) => Settings(
    id: id,
    baseDir: baseDir.text,
    projectDir: projectDir.text,
    genomeDir: genomeDir.text,
    customSnpDir: customSnpDir.text,
    snpSourceAllowedHosts: snpSourceAllowedHosts.text,
    toolsDir: toolsDir.text,
    mipgenExecutable: mipgenExecutable.text,
    exonExtractScript: exonExtractScript.text,
    bigGenePredToGenePredExecutable: bigGenePredToGenePred.text,
    mailActive: mailActive,
    smtpServer: smtpServer.text,
    smtpPort: int.tryParse(smtpPort.text) ?? 25,
    smtpUser: smtpUser.text,
    smtpFrom: smtpFrom.text,
    startTLS: startTLS,
    loginRequired: loginRequired,
    demoMode: demoMode,
    // The server clamps this to 1..8760, so a nonsense entry becomes the nearest
    // sane value rather than being rejected.
    demoModeRetentionHours: int.tryParse(demoRetentionHours.text) ?? 168,
    // ⚠️ Trimmed, and only these. A trailing space on an issuer URL breaks
    // discovery with an error that names the wrong cause; a trailing space on a
    // filesystem path is at least visible in the field beside it.
    oidcIssuer: oidcIssuer.text.trim(),
    oidcClientId: oidcClientId.text.trim(),
    oidcScopes: oidcScopes.text.trim(),
    oidcButtonLabel: oidcButtonLabel.text.trim(),
    oidcAllowedEmailDomains: oidcAllowedDomains.text.trim(),
    oidcAdminEmails: oidcAdminEmails.text.trim(),
    oidcDepartmentClaim: oidcDepartmentClaim.text.trim(),
    authPublicUrl: authPublicUrl.text.trim(),
  );

  void dispose() {
    for (final controller in [
      password,
      baseDir,
      projectDir,
      genomeDir,
      customSnpDir,
      snpSourceAllowedHosts,
      toolsDir,
      mipgenExecutable,
      exonExtractScript,
      bigGenePredToGenePred,
      smtpServer,
      smtpPort,
      smtpUser,
      smtpFrom,
      smtpPassword,
      testMail,
      newPassword,
      demoRetentionHours,
      oidcIssuer,
      oidcClientId,
      oidcClientSecret,
      oidcScopes,
      oidcButtonLabel,
      oidcAllowedDomains,
      oidcAdminEmails,
      oidcDepartmentClaim,
      authPublicUrl,
    ]) {
      controller.dispose();
    }
  }
}
