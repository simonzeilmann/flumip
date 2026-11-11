import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/authentication_handler.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/password_hash.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

/// What a brand-new install's settings password is in development and test
/// run modes, before anybody changes it.
///
/// Stored hashed like any other, so this constant is the only place the word
/// appears — `settingsPasswordIsDefault` is what tells the settings tab to nag
/// about it.
///
/// ⚠️ **Never the first password of a production install.** The word is
/// public, and the settings it opens include `mipgenExecutable`, so knowing
/// it on a reachable server is code execution. Production and staging start
/// from [initialSettingsPasswordEnv] or a random password instead; see
/// `SettingsService._initialPassword`. Older installs that still have it keep
/// working, and keep being nagged.
const defaultSettingsPassword = 'changeme';

/// The environment variable a production install takes its first settings
/// password from. Read once, when the settings row is created, and never
/// again: changing it later does nothing, because the password then lives
/// (hashed) in the database and is changed in the Settings tab.
const initialSettingsPasswordEnv = 'FLUMIP_INITIAL_SETTINGS_PASSWORD';

/// The start of the log line that carries a generated first password. Fixed so
/// that installers and admins can find it with `grep`.
const initialSettingsPasswordLogPrefix = 'FLUMIP INITIAL SETTINGS PASSWORD: ';

/// How long a project survives on a demo install.
///
/// Clamped, because the value is typed into a settings box and both ends are
/// reachable by accident. Zero or negative would delete a project the instant it
/// was created — including the one whose creation scheduled the call — and an
/// absurd figure would schedule a future call so far out that it is effectively
/// a leak. One hour to a year.
Duration demoRetention(Settings settings) {
  final hours = settings.demoModeRetentionHours.clamp(1, 24 * 365);
  return Duration(hours: hours);
}

/// How long a guest's SNP set is kept. Clamped like [demoRetention]: one day to
/// a year.
Duration guestSnpRetention(Settings settings) =>
    Duration(days: settings.guestSnpRetentionDays.clamp(1, 365));

/// The largest file a guest may upload as part of an SNP set, or null when
/// guests cannot add SNP sets. Never above `SnpService.maxImportBytes`, which
/// the upload route applies to everybody.
int? guestSnpMaxBytes(Settings settings) {
  final megabytes = settings.guestSnpMaxMegabytes;
  if (megabytes <= 0) return null;
  return (megabytes * 1024 * 1024).clamp(1, 4 * 1024 * 1024 * 1024);
}

/// The furthest "Keep longer" can push a project's deletion, measured from its
/// creation — and how long a guest's session lasts between visits.
///
/// Never shorter than [demoRetention]: a maximum below the initial window would
/// make extending a project *shorten* it.
Duration maxProjectLifetime(Settings settings) {
  final days = Duration(days: settings.maxProjectLifetimeDays.clamp(1, 365));
  final initial = demoRetention(settings);
  return days < initial ? initial : days;
}

/// Slows down guessing the settings password, without locking anybody out
/// for long.
///
/// In memory and **global** rather than per client. Per-client would be
/// nicer for an administrator sharing a server with a guesser, but nothing
/// here can tell clients apart: behind the reverse proxy this deployment
/// assumes every request comes from the proxy's address, `/api` calls are
/// relayed in-process by `ApiRoute`, and `X-Forwarded-For` is whatever the
/// client wrote. A key the attacker chooses is no key.
///
/// How it works: the first [freeAttempts] attempts since the last quiet spell
/// are checked at once. After that each attempt is given a turn, one
/// [delayFor] after the previous turn, so that *parallel* requests queue
/// rather than each getting their own guess — a sleep per request alone would
/// be no limit at all against concurrency. Throughput for a guesser therefore
/// drops to one check per [maxDelay] (30 s by default: under 3,000 a day).
///
/// What keeps an administrator from being locked out:
///
/// - Nothing is ever refused for good. A request whose turn is more than
///   [maxWait] away is refused with a "wait and try again" message instead of
///   queueing, which is also what bounds the memory and the open requests.
/// - The failures are forgotten after [forgetAfter] without one.
/// - A correct password undoes its own attempt and clears the backoff
///   (leaving the count one short of [freeAttempts]), so an administrator who
///   got in once is not slowed on the next call. That gives a guesser one
///   extra free guess per administrator success — the trade-off chosen over
///   keeping a busy settings tab slow for a quarter of an hour.
/// - A signed-in administrator never reaches this at all (see
///   `SettingsService._isAdmin`), and the escapes in docs/authentication.md
///   do not go through it either.
///
/// ⚠️ While somebody is actively guessing, the correct password waits its
/// turn like any other. That is unavoidable without telling the two apart,
/// and the wait is bounded by [maxWait].
class SettingsPasswordThrottle {
  SettingsPasswordThrottle({
    this.freeAttempts = 10,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.maxWait = const Duration(seconds: 60),
    this.forgetAfter = const Duration(minutes: 15),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Attempts let through without any delay. Generous enough that a settings
  /// tab firing several password-carrying calls at once is never slowed.
  final int freeAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final Duration maxWait;
  final Duration forgetAfter;
  final DateTime Function() _clock;

  int _failures = 0;
  int _inFlight = 0;
  DateTime? _lastFailure;
  DateTime? _nextTurn;

  /// The spacing before the [excess]-th attempt beyond [freeAttempts]:
  /// doubling from [baseDelay], capped at [maxDelay].
  Duration delayFor(int excess) {
    if (excess <= 0) return Duration.zero;
    final factor = 1 << min(excess - 1, 20);
    final delay = baseDelay * factor;
    return delay > maxDelay ? maxDelay : delay;
  }

  /// Takes a turn: returns how long to wait before checking the password.
  ///
  /// Every successful call must be followed by exactly one [release].
  ///
  /// \throws [ArgumentException] when the turn is more than [maxWait] away.
  Duration acquire() {
    final now = _clock();
    if (_lastFailure != null && now.difference(_lastFailure!) > forgetAfter) {
      _failures = 0;
      _lastFailure = null;
    }

    final excess = _failures + _inFlight + 1 - freeAttempts;
    if (excess <= 0) {
      _inFlight++;
      return Duration.zero;
    }

    final previous = _nextTurn;
    final start = (previous == null || previous.isBefore(now)) ? now : previous;
    final turn = start.add(delayFor(excess));
    final wait = turn.difference(now);
    if (wait > maxWait) {
      final seconds = (start.difference(now).inSeconds + 1).clamp(1, 3600);
      throw ArgumentException(
        message:
            'Too many wrong settings passwords have been tried recently. '
            'Wait $seconds seconds and try again.',
      );
    }
    _nextTurn = turn;
    _inFlight++;
    return wait;
  }

  /// Records the outcome of the check [acquire] made room for.
  void release({required bool success}) {
    if (_inFlight > 0) _inFlight--;
    if (success) {
      _failures = min(_failures, freeAttempts - 1);
      _nextTurn = null;
    } else {
      _failures++;
      _lastFailure = _clock();
    }
  }
}

/// A service class for handling settings-related operations.
class SettingsService {
  SettingsService({
    SettingsPasswordThrottle? throttle,
    Future<void> Function(Duration)? sleep,
    this._environment,
    this._runMode,
    void Function(String line)? announce,
  }) : throttle = throttle ?? SettingsPasswordThrottle(),
       _sleep = sleep ?? Future<void>.delayed,
       _announce = announce ?? _printToConsole;

  /// Exposed so tests can drive the clock-independent parts directly.
  final SettingsPasswordThrottle throttle;
  final Future<void> Function(Duration) _sleep;
  final Map<String, String>? _environment;

  /// Overrides the server's run mode, so tests can create the settings row the
  /// way a production install does.
  final String? _runMode;
  final void Function(String line) _announce;

  Map<String, String> get _env => _environment ?? Platform.environment;

  /// Straight to the process output — the journal under systemd, `docker
  /// compose logs` under Docker — and deliberately **not** `session.log`,
  /// which in production writes to the database's log table. The point of
  /// generating the password is that the database holds only its hash.
  static void _printToConsole(String line) => stdout.writeln(line);

  /// Retrieves the settings from the database.
  ///
  /// \param session The current session.
  /// \returns The retrieved [Settings] object.
  /// \throws [Exception] if the settings could not be loaded.
  Future<Settings> getSettings(Session session) async {
    session.log("Retrieving settings", level: LogLevel.info);
    await _checkAndCreateSettings(session);
    var settings = await Settings.db.find(session, where: (t) => t.id > 0);
    if (settings.isEmpty) {
      session.log("Failed to load settings", level: LogLevel.error);
      throw Exception('Failed to load settings');
    }
    session.log("Settings retrieved successfully", level: LogLevel.info);
    return settings.first;
  }

  Future<Settings> getSettingsExternal(
    Session session,
    String? password,
  ) async {
    var settings = await getSettings(session);
    if (!await _isAdmin(session, settings, password)) {
      throw ArgumentException(message: 'This password is not correct.');
    }
    return settings;
  }

  /// Throws unless the caller may administer this server.
  ///
  /// Use this for operations that need admin rights but must not read the
  /// settings out — notably writing the OIDC client secret, which is write-only.
  Future<void> requireAdmin(Session session, String? password) async {
    await getSettingsExternal(session, password);
  }

  /// Either a signed-in session whose email is on the admin list, or — **only
  /// while sign-in is not being enforced** — the settings password.
  ///
  /// Once single sign-on is enforcing, the password stops being accepted
  /// entirely. Identity is then the only way in, so a user who happens to know
  /// the shared password cannot use it to reach an administrator's settings.
  ///
  /// ⚠️ **This trades away part of the lockout escape**, knowingly. The password
  /// used to work regardless, precisely because the identity provider can be the
  /// thing that is broken. What is left:
  ///
  /// - A provider that has **never** answered discovery, on an install where
  ///   nobody has ever signed in with that issuer, leaves `isEnforcing` false —
  ///   the fail-open rule — so the password still works. This is the common
  ///   misconfiguration, and it is still recoverable from the UI.
  /// - A provider that answered once and **then** broke keeps enforcing from the
  ///   cached document — and so does one that is down across a restart, once
  ///   somebody has signed in with it (see `AuthRuntime.isEnforcing`). Nobody
  ///   new can sign in, and the password no longer helps.
  ///   Recovery is `FLUMIP_AUTH_ENABLED=false` plus a restart, or
  ///   `UPDATE settings SET "loginRequired" = false;`. Both are in
  ///   docs/authentication.md and HANDOFF.md.
  ///
  /// Every password check takes a turn from [throttle], so guessing is slow;
  /// a throttled request either waits (at most a minute) or is refused with a
  /// "wait and try again" [ArgumentException]. A missing password, an admin
  /// session and an enforcing server never reach it.
  ///
  /// Never throws on the runtime lookup, for the reason given on
  /// `FlumipEndpoint.requireLogin`: a half-initialised process must not turn
  /// every settings call into a 500. An unavailable runtime means "not
  /// enforcing", which keeps the password working — the safe direction, since
  /// the alternative is a server nobody can configure.
  ///
  /// ⚠️ **An admin session short-circuits before any hashing happens.** That is
  /// worth keeping: verifying a PBKDF2 hash costs a few hundred milliseconds by
  /// design, and a signed-in administrator never supplies a password at all.
  Future<bool> _isAdmin(
    Session session,
    Settings settings,
    String? password,
  ) async {
    if (session.authenticated?.scopes.contains(adminScope) ?? false) {
      return true;
    }

    var enforcing = false;
    if (sl.isRegistered<AuthRuntime>()) {
      try {
        enforcing = sl<AuthRuntime>().isEnforcing;
      } catch (_) {
        enforcing = false;
      }
    }
    if (enforcing) return false;

    if (password == null) return false;
    final stored = settings.settingsPassword;
    if (stored == null || stored.isEmpty) return false;

    // Everything from here is a guess being checked, so it takes a turn. See
    // [SettingsPasswordThrottle] for what that costs a real administrator.
    final wait = throttle.acquire();
    var success = false;
    try {
      if (wait > Duration.zero) {
        session.log(
          'Delaying a settings password check by ${wait.inSeconds} s after '
          'repeated wrong passwords',
          level: LogLevel.warning,
        );
        await _sleep(wait);
      }
      success = await _checkPassword(session, settings, password, stored);
      return success;
    } finally {
      throttle.release(success: success);
    }
  }

  Future<bool> _checkPassword(
    Session session,
    Settings settings,
    String password,
    String stored,
  ) async {
    if (looksLikePasswordHash(stored)) {
      return verifyPassword(password, stored);
    }

    // Everything below is the one-way door out of plaintext.
    //
    // An install created before hashing still has its password sitting in the
    // column as typed. It has to keep working — this is the credential that gets
    // an administrator back into a server whose identity provider is broken, and
    // silently invalidating it on upgrade would be a lockout delivered by
    // deployment. So it is accepted once, and the accepting is what replaces it.
    //
    // ⚠️ The upgrade writes only this column. `updateRow` would otherwise write
    // every field of the row we happen to be holding, and this runs inside a
    // *read* — a settings save landing concurrently would be silently rolled
    // back to whatever this session loaded.
    if (!constantTimeEquals(utf8.encode(password), utf8.encode(stored))) {
      return false;
    }

    settings.settingsPassword = hashPassword(password);
    await Settings.db.updateRow(
      session,
      settings,
      columns: (t) => [t.settingsPassword],
    );
    session.log(
      "Replaced the plaintext settings password with a hash",
      level: LogLevel.info,
    );
    return true;
  }

  /// Ensures exactly one settings row exists, without ever discarding it.
  ///
  /// An existing row is never deleted. It holds the settings password and (once
  /// SSO is configured) the OIDC credentials, so replacing it with defaults
  /// would silently restore `settingsPassword = "changeme"` and
  /// `loginRequired = false` — reverting an authenticated install to wide-open
  /// access with a publicly known admin password.
  ///
  /// \param session The current session.
  Future<void> _checkAndCreateSettings(Session session) async {
    var settings = await Settings.db.find(
      session,
      where: (t) => t.id > 0,
      orderBy: (t) => t.id,
    );

    if (settings.isEmpty) {
      session.log("No settings found, creating defaults", level: LogLevel.info);
      // ⚠️ The settings password is seeded here rather than as a model default,
      // because a hash cannot be written into the yaml. A fresh install with a
      // null column would have no break-glass credential at all, so — with
      // single sign-on off, which is the default — nobody could open the
      // settings tab to configure the server they just installed.
      final initial = _initialPassword(session);
      final inserted = await Settings.db.insertRow(
        session,
        Settings(settingsPassword: hashPassword(initial.password)),
      );
      if (initial.generated) {
        // Two first reads racing on an empty table both insert, and the
        // duplicate clean-up below keeps the oldest row. Announce only the
        // password that survives, or the log would offer one that never works.
        final oldest = await Settings.db.findFirstRow(
          session,
          where: (t) => t.id > 0,
          orderBy: (t) => t.id,
        );
        if (oldest?.id == inserted.id) {
          _announce(
            '$initialSettingsPasswordLogPrefix${initial.password}\n'
            'This is the password for the Settings tab of this new FLUMIP '
            'install. It is shown once and stored only as a hash; change it in '
            'Settings. To choose it yourself on the next new install, set '
            '$initialSettingsPasswordEnv.',
          );
        }
      }
      return;
    }

    if (settings.length > 1) {
      // Keep the oldest row — it is the one the install has been using — and
      // drop the duplicates rather than resetting everything to defaults.
      final keep = settings.first.id!;
      session.log(
        "Found ${settings.length} settings rows, keeping id $keep and "
        "deleting the duplicates",
        level: LogLevel.warning,
      );
      await Settings.db.deleteWhere(
        session,
        where: (t) => t.id.notEquals(keep),
      );
    }
  }

  /// The first settings password of a new install.
  ///
  /// `changeme` in development and test run modes, so the dev workflow and the
  /// test suite need nothing set up. Anywhere else — production, staging —
  /// [initialSettingsPasswordEnv] if the installer set it, otherwise a random
  /// one that [_checkAndCreateSettings] writes to the console once.
  ({String password, bool generated}) _initialPassword(Session session) {
    final runMode = _runMode ?? session.server.serverpod.runMode;
    if (runMode == ServerpodRunMode.development ||
        runMode == ServerpodRunMode.test) {
      return (password: defaultSettingsPassword, generated: false);
    }
    final fromEnv = _env[initialSettingsPasswordEnv];
    if (fromEnv != null && fromEnv.trim().isNotEmpty) {
      session.log(
        'Set the first settings password from $initialSettingsPasswordEnv',
        level: LogLevel.info,
      );
      return (password: fromEnv, generated: false);
    }
    return (password: generateSettingsPassword(), generated: true);
  }

  /// Updates the settings in the database.
  ///
  /// Merges [settings] into the stored row instead of replacing it: only the
  /// fields listed here are taken from the client. Everything else keeps its
  /// stored value.
  ///
  /// This matters for two reasons. The Flutter settings tab builds a fresh
  /// [Settings] object from its text controllers, so any field it does not
  /// populate would otherwise be written back as its *default* on every save.
  /// And [Settings.oidcClientSecret] is `serverOnly`, so it is absent from the
  /// object the client sends and can only be written through
  /// `SettingsEndpoint.setOidcClientSecret`.
  ///
  /// \param session The current session.
  /// \param settings The [Settings] object to merge in.
  Future<void> updateSettings(Session session, Settings settings) async {
    session.log("Updating settings", level: LogLevel.info);
    final stored = await getSettings(session);

    stored
      ..demoMode = settings.demoMode
      ..demoModeRetentionHours = settings.demoModeRetentionHours
      ..publicMode = settings.publicMode
      ..maxProjectLifetimeDays = settings.maxProjectLifetimeDays
      ..guestMaxProjects = settings.guestMaxProjects
      ..guestSnpMaxMegabytes = settings.guestSnpMaxMegabytes
      ..guestMaxSnps = settings.guestMaxSnps
      ..guestSnpRetentionDays = settings.guestSnpRetentionDays
      ..termsVersion = settings.termsVersion
      ..publicNoticeText = settings.publicNoticeText
      ..imprintUrl = settings.imprintUrl
      ..privacyUrl = settings.privacyUrl
      ..maxConcurrentRuns = settings.maxConcurrentRuns
      ..maxBwaThreads = settings.maxBwaThreads
      ..baseDir = settings.baseDir
      ..projectDir = settings.projectDir
      ..genomeDir = settings.genomeDir
      ..customSnpDir = settings.customSnpDir
      ..snpSourceAllowedHosts = settings.snpSourceAllowedHosts
      ..toolsDir = settings.toolsDir
      ..mipgenExecutable = settings.mipgenExecutable
      ..exonExtractScript = settings.exonExtractScript
      ..bigGenePredToGenePredExecutable =
          settings.bigGenePredToGenePredExecutable
      ..mailActive = settings.mailActive
      ..smtpServer = settings.smtpServer
      ..smtpPort = settings.smtpPort
      ..smtpUser = settings.smtpUser
      ..smtpFrom = settings.smtpFrom
      ..startTLS = settings.startTLS
      ..loginRequired = settings.loginRequired
      ..oidcIssuer = settings.oidcIssuer
      ..oidcClientId = settings.oidcClientId
      ..oidcScopes = settings.oidcScopes
      ..oidcButtonLabel = settings.oidcButtonLabel
      ..oidcAllowedEmailDomains = settings.oidcAllowedEmailDomains
      ..oidcAdminEmails = settings.oidcAdminEmails
      ..oidcDepartmentClaim = settings.oidcDepartmentClaim
      ..authPublicUrl = settings.authPublicUrl;
    // oidcClientSecret is deliberately absent: it is serverOnly, so it arrives
    // as null from the client and is written only by setOidcClientSecret.

    // settingsPassword is deliberately absent, alongside oidcClientSecret: it is
    // serverOnly, arrives as null from the client, and is written only by
    // setSettingsPassword.

    await Settings.db.updateRow(session, stored);
    session.log("Settings updated successfully", level: LogLevel.info);
  }

  /// Replaces the settings password, which is stored hashed.
  ///
  /// ⚠️ **An empty password is refused rather than stored**, unlike the SMTP
  /// password and the OIDC client secret, where empty means "clear it". Those
  /// two are optional; this one is the way back into a server whose identity
  /// provider has broken. Clearing it would leave an install with single sign-on
  /// off and no way to reach its own settings, recoverable only by editing the
  /// database directly.
  ///
  /// \throws [ArgumentException] if [newPassword] is empty or only whitespace.
  Future<void> setSettingsPassword(Session session, String newPassword) async {
    if (newPassword.trim().isEmpty) {
      throw ArgumentException(
        message:
            'The settings password cannot be blank. Type the password you '
            'want to use, or leave the box empty to keep the current one.',
      );
    }

    final settings = await getSettings(session);
    settings.settingsPassword = hashPassword(newPassword);
    await Settings.db.updateRow(
      session,
      settings,
      columns: (t) => [t.settingsPassword],
    );
    session.log("Settings password changed", level: LogLevel.info);
  }

  /// Whether the settings password is still `changeme`.
  ///
  /// The settings tab used to show the password in a box, so "this install is
  /// still on the shipped default" was visible by reading it. Hashing takes that
  /// away, and saying nothing would leave the default quietly in place on every
  /// install that never got round to changing it — so the tab asks instead.
  ///
  /// Nothing is leaked by answering: only an administrator can get this far.
  Future<bool> settingsPasswordIsDefault(Session session) async {
    final stored = (await getSettings(session)).settingsPassword;
    if (stored == null || stored.isEmpty) return false;
    // A row that predates hashing still holds the password as typed, and it is
    // just as much the default when it says so in plaintext.
    if (!looksLikePasswordHash(stored)) {
      return stored == defaultSettingsPassword;
    }
    return verifyPassword(defaultSettingsPassword, stored);
  }
}

/// A random settings password: 20 characters from an alphabet with no
/// look-alikes (no 0/O, 1/l/I), in groups of five so it can be read off a
/// terminal and typed. Over 110 bits.
String generateSettingsPassword({Random? random}) {
  const alphabet = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rng = random ?? Random.secure();
  final groups = List.generate(
    4,
    (_) =>
        List.generate(5, (_) => alphabet[rng.nextInt(alphabet.length)]).join(),
  );
  return groups.join('-');
}
