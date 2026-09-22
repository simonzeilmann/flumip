import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/authorization_service.dart';
import 'package:serverpod/serverpod.dart';

/// Base class for the endpoints that require a signed-in user when — and only
/// when — single sign-on is switched on and working.
///
/// [Endpoint.requireLogin] is a synchronous getter that Serverpod reads on every
/// call, so this has to be a field read rather than a database query; see
/// [AuthRuntime] for how the answer gets there and stays current.
///
/// Notably **not** extended by `SettingsEndpoint`: the switch that turns
/// authentication off must never sit behind the thing it switches off, or a
/// misconfiguration becomes a lockout with no way back. That endpoint has its
/// own gate, satisfied by either the settings password or an admin session.
abstract class FlumipEndpoint extends Endpoint {
  @override
  bool get requireLogin {
    // Must never throw. Serverpod reads this while dispatching, so an exception
    // here surfaces as a 500 on the endpoint being called rather than as a
    // refused login — on *every* endpoint, with nothing in the UI to suggest
    // what went wrong. An unregistered runtime means the process is not fully
    // set up, and the fail-open policy applies: stay reachable, do not enforce.
    if (!sl.isRegistered<AuthRuntime>()) return false;
    try {
      return sl<AuthRuntime>().isEnforcing;
    } catch (_) {
      return false;
    }
  }

  /// Refuses unless the caller is allowed to touch this project.
  ///
  /// **Every endpoint method that takes a project id must start with this.**
  ///
  /// Adds [ProjectAccessDeniedException] and changes nothing else: an unknown id passes
  /// straight through so the operation still reports the not-found error it
  /// always reported.
  ///
  /// The check lives here, at the request boundary, rather than inside
  /// `ProjectService` — which would look like the tidier place — because the
  /// services are also called by things that have no user at all. `DemoModeCleanup`
  /// and the mipgen progress future calls run on unauthenticated sessions and go
  /// through `getProject`, `updateProject` and `deleteProject`; enforcing down
  /// there would have stopped demo-mode cleanup the moment a project had an
  /// owner, and `DemoModeCleanup` catches the failure and logs "Project not
  /// found", so it would have gone on reporting success while quietly doing
  /// nothing.
  ///
  /// ⚠️ [doNotGenerate] is load-bearing. These two are public methods whose
  /// first parameter is a [Session], which is exactly the generator's signature
  /// for an endpoint method — so without the annotation both were published as
  /// remotely callable methods on all seven [FlumipEndpoint] subclasses:
  /// fourteen authorization probes an unauthenticated caller could use to ask
  /// "does project 41 exist, and may I touch it?".
  ///
  /// Renaming them with a leading underscore does not work as an alternative:
  /// each subclass lives in its own library, so a private helper on the base
  /// class would be unreachable from any of them.
  @doNotGenerate
  Future<void> requireProject(Session session, int projectId) =>
      authz.requireProjectAccess(session, projectId);

  /// Checks that the caller may touch the project owning these options.
  @doNotGenerate
  Future<void> requireProjectOptions(Session session, int optionsId) =>
      authz.requireOptionsAccess(session, optionsId);
}
