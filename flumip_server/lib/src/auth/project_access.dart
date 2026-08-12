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

/// Whether [principal] may *see* an SNP that is [private] and owned by [owner].
///
/// ⚠️ **The clause order differs from [projectIsAccessible], and the difference
/// is the point.** There, a null owner grants access to everybody, because every
/// project predating authorization is unowned and hiding them would look exactly
/// like data loss. Here a null owner is **not** a grant. `Snp.private` has never
/// been read by anything, so there is no body of existing private SNPs that a
/// stricter rule could strand — which means this can be strict from its first
/// day, and a private SNP whose owner was deleted (`onDelete=SetNull`) falls
/// closed rather than open.
///
/// The order of the clauses is the policy:
///
/// 1. **Not private → everyone.** Global scanned SNPs and shared custom ones.
///    First, so a global stays visible whether or not anybody is signed in.
/// 2. **Not enforcing → everything.** No identities exist on such an install, so
///    there is nobody to attribute an upload to and nobody to hide it from. The
///    same position the rest of the codebase takes.
/// 3. **Admins see everything.**
/// 4. Otherwise the owner matches, or access is refused.
bool snpIsAccessible({
  required bool enforcing,
  required Principal principal,
  required bool private,
  required int? owner,
}) {
  if (!private) return true;
  if (!enforcing) return true;
  if (principal.isAdmin) return true;

  final userId = principal.userId;
  if (userId == null) return false;
  return owner == userId;
}

/// Whether [principal] may *change or delete* an SNP owned by [owner].
///
/// Stricter than [snpIsAccessible] in the one way that matters: a **shared**
/// custom SNP is visible to everybody but writable only by whoever added it.
/// Ownership survives sharing, so putting a panel up for the lab to use is not
/// the same as handing them the ability to delete it.
///
/// An SNP with no owner — every global one — is writable by nobody but an
/// administrator. That is what keeps the ordinary delete button away from the
/// reference genome tree.
bool snpIsWritable({
  required bool enforcing,
  required Principal principal,
  required int? owner,
}) {
  if (!enforcing) return true;
  if (principal.isAdmin) return true;

  final userId = principal.userId;
  if (userId == null) return false;
  return owner != null && owner == userId;
}
