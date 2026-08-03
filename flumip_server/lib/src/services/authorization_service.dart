import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/authentication_handler.dart';
import 'package:flumip_server/src/auth/project_access.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/auth_service.dart';
import 'package:serverpod/serverpod.dart';

/// The registered [AuthorizationService], or a throwaway one.
///
/// The service holds no state, so building one on demand costs nothing and
/// behaves identically. The fallback is there because a test can exercise a
/// single service without calling `setup()`, and a locator lookup that throws in
/// that case would turn a missing registration into a failure on whatever
/// endpoint happened to be called — the same robustness rule
/// `FlumipEndpoint.requireLogin` follows. Tests steer this service by installing
/// an [AuthRuntime], not by replacing it.
AuthorizationService get authz => sl.isRegistered<AuthorizationService>()
    ? sl<AuthorizationService>()
    : AuthorizationService();

/// Turns a request into a [Principal] and enforces project access.
///
/// Every project-scoped operation goes through [requireProjectAccess] or
/// [visibleProjects]; the rule itself lives in [projectIsAccessible] so that
/// endpoints cannot each grow their own version of it.
class AuthorizationService {
  AuthorizationService();

  /// Whether project access is being enforced at all.
  ///
  /// Mirrors `FlumipEndpoint.requireLogin`, including its refusal to throw: an
  /// unregistered or broken [AuthRuntime] means the process is not fully set up,
  /// and the fail-open policy applies. Failing closed here would be worse than
  /// in the endpoint gate — it would make a half-initialised server look like it
  /// had lost every project.
  bool get isEnforcing {
    if (!sl.isRegistered<AuthRuntime>()) return false;
    try {
      return sl<AuthRuntime>().isEnforcing;
    } catch (_) {
      return false;
    }
  }

  /// Resolves who is making this request.
  ///
  /// [Principal.anonymous] when nothing is signed in, which is every request
  /// while single sign-on is off. Never throws: a failure to resolve has to come
  /// out as "nobody" so the caller can apply the fail-open rule, rather than
  /// turning a cache miss into a 500 on an unrelated endpoint.
  Future<Principal> principal(Session session) async {
    try {
      final info = session.authenticated;
      if (info == null) return Principal.anonymous;

      final isAdmin = info.scopes.contains(adminScope);
      final authSessionId = int.tryParse(info.authId);
      if (authSessionId == null) {
        // Should not happen — the handler always sets authId to an AuthSession
        // row id — but an admin flag without a user id is still usable, and
        // dropping it would silently demote an admin.
        return Principal(isAdmin: isAdmin);
      }

      final authSession = await _authSession(session, authSessionId);
      return Principal(userId: authSession?.userId, isAdmin: isAdmin);
    } catch (e, stackTrace) {
      session.log(
        'Resolving the principal failed; treating the request as anonymous.',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return Principal.anonymous;
    }
  }

  /// Refuses if the caller may not touch project [projectId].
  ///
  /// Says nothing about existence, deliberately. A missing project returns
  /// quietly and the operation goes on to fail with whatever error it already
  /// produced.
  ///
  /// The first version of this threw [FlumipFileNotFoundException] for an unknown
  /// id, which seemed tidier and was wrong: `FileEndpoint.showMipsProgress` has
  /// always answered a bad id with Serverpod's [FileNotFoundException], the app
  /// catches the two separately, and a guard bolted onto the front of an
  /// operation has no business changing the error that operation reports for an
  /// unrelated failure. A test caught it. Adding [ProjectAccessDeniedException] is the
  /// entire remit.
  ///
  /// Costs no query at all while single sign-on is off.
  Future<void> requireProjectAccess(Session session, int projectId) async {
    if (!isEnforcing) return;

    final project = await Project.db.findById(session, projectId);
    if (project == null) return;
    await requireAccessTo(session, project);
  }

  /// Refuses if the caller may not touch [project].
  Future<void> requireAccessTo(Session session, Project project) async {
    final enforcing = isEnforcing;
    if (!enforcing) return;

    final who = await principal(session);
    if (projectIsAccessible(
      enforcing: enforcing,
      principal: who,
      owner: project.owner,
      department: project.department,
    )) {
      return;
    }

    session.log(
      'Refused access to project ${project.id} for $who',
      level: LogLevel.warning,
    );
    throw ProjectAccessDeniedException();
  }

  /// Refuses if the caller may not touch the project that owns [optionsId].
  ///
  /// `ProjectOptions` rows are addressed by their own id and every one of them is
  /// reachable from the client, so guarding only `Project` would leave a
  /// project's entire mipgen configuration readable and writable by anyone
  /// willing to count upwards.
  ///
  /// Options no project references yet are allowed through: the create-project
  /// flow inserts the options row *before* the project that will point at it, so
  /// refusing an unreferenced row would break creating a project at all.
  Future<void> requireOptionsAccess(Session session, int optionsId) async {
    if (!isEnforcing) return;

    final project = await Project.db.findFirstRow(
      session,
      where: (t) => t.options.equals(optionsId),
    );
    if (project == null) return;
    await requireAccessTo(session, project);
  }

  /// Every project the caller is allowed to see.
  ///
  /// Filtered in Dart with the very same predicate the single-project gate uses,
  /// rather than as a SQL `where` clause. Two expressions of one rule is how a
  /// list ends up showing a project that opening then refuses, and the table is
  /// small enough that it does not matter — `getProjects` already loaded every
  /// row and sorted them in the client. `project_owner_idx` exists for the
  /// `ON DELETE SET NULL` scan, not for this.
  Future<List<Project>> visibleProjects(Session session) async {
    final all = await Project.db.find(session, where: (t) => t.id > 0);
    final enforcing = isEnforcing;
    if (!enforcing) return all;

    final who = await principal(session);
    return all
        .where(
          (p) => projectIsAccessible(
            enforcing: enforcing,
            principal: who,
            owner: p.owner,
            department: p.department,
          ),
        )
        .toList();
  }

  /// Refuses unless the caller is a signed-in administrator.
  ///
  /// ⚠️ **This inverts the fail-open ordering the rest of this class follows**,
  /// and does so on purpose. Everywhere else, "not enforcing" grants access
  /// immediately, because a no-auth install must never be locked out of its own
  /// projects. Here there is nothing to be locked out of: reassigning ownership
  /// needs identities to assign to, and while single sign-on is off there are no
  /// `flumip_user` rows and no notion of an administrator.
  ///
  /// Failing open instead would be actively harmful rather than merely useless.
  /// An install that ran with single sign-on on, collected owners, and then
  /// switched it off would expose an unauthenticated way to strip those owners —
  /// invisible at the time, because access is unrestricted anyway while off, and
  /// destructive the moment single sign-on came back on.
  Future<void> requireAdmin(Session session) async {
    if (!isEnforcing) {
      session.log(
        'Refused an admin-only operation: single sign-on is not enforcing, so '
        'there are no administrators.',
        level: LogLevel.warning,
      );
      throw ProjectAccessDeniedException(
        message: 'This action needs an administrator, and single sign-on is off',
      );
    }

    final who = await principal(session);
    if (who.isAdmin) return;

    session.log(
      'Refused an admin-only operation for $who',
      level: LogLevel.warning,
    );
    throw ProjectAccessDeniedException(
      message: 'This action is restricted to administrators',
    );
  }

  /// The `flumip_user` id to stamp on a project being created, or null.
  ///
  /// Null while single sign-on is off, which is what keeps every project on a
  /// no-auth install unowned and therefore shared.
  Future<int?> ownerForNewProject(Session session) async {
    if (!isEnforcing) return null;
    return (await principal(session)).userId;
  }

  /// Reads an [AuthSession] through the local cache.
  ///
  /// Shares [AuthService.cacheGroupForSession] with the bearer-token cache, so
  /// signing out drops this entry too and the next request re-resolves. Without
  /// that, a revoked session could keep its ownership rights until the entry
  /// aged out.
  Future<AuthSession?> _authSession(Session session, int authSessionId) async {
    final key = 'authz:session:$authSessionId';

    final cached = await session.caches.localPrio.get<AuthSession>(key);
    if (cached != null) {
      return DateTime.now().toUtc().isAfter(cached.expires) ? null : cached;
    }

    final row = await AuthSession.db.findById(session, authSessionId);
    if (row == null) return null;

    final remaining = row.expires.difference(DateTime.now().toUtc());
    if (remaining.isNegative) return null;

    await session.caches.localPrio.put(
      key,
      row,
      lifetime: remaining,
      group: AuthService.cacheGroupForSession(authSessionId),
    );
    return row;
  }
}
