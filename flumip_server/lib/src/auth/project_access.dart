/// Who is asking, reduced to the three things that decide project access.
///
/// Deliberately not a database model and deliberately not tied to [Session], so
/// that the rule below can be tested exhaustively as a pure function. Resolving
/// one of these from a request is `AuthorizationService`'s job.
class Principal {
  /// The `flumip_user` row id, or null when nobody is signed in.
  final int? userId;

  /// True when the address is on the administrator list. Admins bypass every
  /// project check — that is what makes an unowned-project cleanup possible.
  final bool isAdmin;

  /// Always null today.
  ///
  /// No department claim is collected from the identity provider, so nothing can
  /// populate this. It exists because [projectIsAccessible] takes departments
  /// into account, and building that clause now means switching it on later is a
  /// change to sign-in plus a Settings field — not a change to every call site
  /// that guards a project. See `docs/authorization.md`.
  final int? departmentId;

  const Principal({this.userId, this.isAdmin = false, this.departmentId});

  /// Nobody. What every request carries while single sign-on is switched off.
  static const Principal anonymous = Principal();

  @override
  String toString() =>
      'Principal(userId: $userId, isAdmin: $isAdmin, department: $departmentId)';
}

/// Whether [principal] may see and change a project owned by [owner] and
/// attached to [department].
///
/// One expression, one place, no database — every guarded path funnels through
/// this so the policy cannot drift between endpoints.
///
/// The order of the clauses is the policy:
///
/// 1. **Not enforcing → everything is allowed.** Running with no authentication
///    is the standard deployment, and in that mode there is no identity to
///    compare against. This has to be first, or the default install locks
///    itself out of its own data.
/// 2. **Admins see everything.** They already hold the settings password's
///    powers, and somebody has to be able to reassign an orphaned project.
/// 3. **Unowned projects are everyone's.** `owner` is null on every project that
///    predates this code, so anything stricter would make an admin's decision to
///    switch single sign-on on look like data loss.
/// 4. Otherwise the owner matches, or the departments match, or access is
///    refused.
bool projectIsAccessible({
  required bool enforcing,
  required Principal principal,
  required int? owner,
  required int? department,
}) {
  if (!enforcing) return true;
  if (principal.isAdmin) return true;
  if (owner == null) return true;

  final userId = principal.userId;
  if (userId == null) return false;
  if (owner == userId) return true;

  // Both sides must be present. Comparing two nulls would quietly hand every
  // department-less project to every department-less user — which is all of them
  // — and turn the whole rule into "anyone may touch anything". The nullness of
  // the caller's department is what keeps this clause inert until a claim is
  // actually wired up, so the guard is doing real work rather than being
  // defensive.
  final callerDepartment = principal.departmentId;
  if (callerDepartment != null &&
      department != null &&
      callerDepartment == department) {
    return true;
  }

  return false;
}
