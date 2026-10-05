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

  /// The groups the identity provider reported at this session's sign-in.
  ///
  /// **A list, because people are in several.** `groups` is an array at every
  /// provider that sends one, and modelling it as a single value would mean
  /// picking one arbitrarily and calling the others wrong.
  ///
  /// Empty whenever `Settings.oidcDepartmentClaim` is unset, which is the
  /// default — so the department clause below stays inert on an install that
  /// has not asked for it. Values are compared verbatim; they are the
  /// provider's strings, not ids.
  final List<String> departments;

  const Principal({
    this.userId,
    this.isAdmin = false,
    this.departments = const [],
  });

  /// Nobody. What every request carries while single sign-on is switched off.
  static const Principal anonymous = Principal();

  @override
  String toString() =>
      'Principal(userId: $userId, isAdmin: $isAdmin, '
      'departments: ${departments.join('|')})';
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
  required String? department,
}) {
  if (!enforcing) return true;
  if (principal.isAdmin) return true;
  if (owner == null) return true;

  final userId = principal.userId;
  if (userId == null) return false;
  if (owner == userId) return true;

  // ⚠️ Both sides must be present, and the emptiness check is doing real work
  // rather than being defensive. A project with no department must not be
  // handed to a caller with no departments — that describes every project and
  // every caller on an install with no claim configured, and would turn the
  // whole rule into "anyone may touch anything".
  //
  // Compared verbatim, including case: these are the provider's own strings on
  // both sides, and folding case would make `Cardiology` and `cardiology` the
  // same department at a provider that considers them different.
  if (department != null &&
      department.isNotEmpty &&
      principal.departments.contains(department)) {
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
