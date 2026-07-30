import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
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
}
