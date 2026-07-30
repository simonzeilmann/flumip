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

  /// Loads a project and refuses if the caller may not touch it.
  ///
  /// Throws [FlumipFileNotFoundException] when there is no such project and
  /// [AccessDeniedException] when there is one but it is somebody else's.
  Future<Project> requireProjectAccess(Session session, int projectId) async {
    final project = await Project.db.findById(session, projectId);
    if (project == null) {
      session.log('Project not found with ID: $projectId',
          level: LogLevel.error);
      throw FlumipFileNotFoundException(message: 'Project not found');
    }
    await requireAccessTo(session, project);
    return project;
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
    throw AccessDeniedException();
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
        .where((p) => projectIsAccessible(
              enforcing: enforcing,
              principal: who,
              owner: p.owner,
              department: p.department,
            ))
        .toList();
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
