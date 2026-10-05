/// Reading a claim out of an OpenID Connect payload, the way providers
/// actually send them.
///
/// There is **no standard claim for a department**. OpenID Connect Core §5.1
/// defines exactly twenty standard claims and none of them describe
/// organisational membership, so every provider invents its own:
///
/// | Provider | Where group membership lives |
/// | --- | --- |
/// | Okta, Auth0, Entra ID | `groups` |
/// | Keycloak (realm roles) | `realm_access.roles` — **nested** |
/// | Keycloak (client roles) | `resource_access.<client>.roles` — nested twice |
/// | LDAP-backed, various | `ou`, `department`, `division` |
///
/// That is why the claim is configured by name rather than hard-coded, why the
/// name is a **path** rather than a key, and why the value may be either a
/// single string or an array. Handling only one of those shapes is the standard
/// way to be incompatible with half the providers in the table.
library;

/// The values of the claim at [path], as a list, however the provider sent it.
///
/// [path] is dot-separated, so `realm_access.roles` walks into a nested object.
/// A claim name containing a literal dot cannot be addressed this way; no
/// provider in the table above uses one, and the nested case is the one that
/// actually occurs.
///
/// Accepts three shapes, because providers disagree about which is right:
///
///  * a string — `"department": "cardiology"`
///  * an array of strings — `"groups": ["cardiology", "research"]`
///  * an array containing non-strings, which are dropped rather than throwing.
///    A malformed claim should cost the caller that claim, not the sign-in.
///
/// Values are trimmed, empties dropped and duplicates removed, order preserved.
/// Returns an empty list for an absent, null, empty or unreadable claim, so the
/// caller never has to distinguish "no such claim" from "no groups" — both mean
/// the same thing everywhere this is used.
List<String> claimValues(Map<String, dynamic>? payload, String path) {
  if (payload == null) return const [];
  final trimmedPath = path.trim();
  if (trimmedPath.isEmpty) return const [];

  Object? value = payload;
  for (final segment in trimmedPath.split('.')) {
    if (value is! Map) return const [];
    value = value[segment];
    if (value == null) return const [];
  }

  final raw = switch (value) {
    String s => [s],
    List list => list.whereType<String>().toList(),
    // A number or a bool is not a group name. Neither is an object: a provider
    // that sends one means something this cannot interpret, and guessing would
    // be worse than saying nothing.
    _ => const <String>[],
  };

  final seen = <String>{};
  final result = <String>[];
  for (final entry in raw) {
    final trimmed = entry.trim();
    if (trimmed.isEmpty) continue;
    if (seen.add(trimmed)) result.add(trimmed);
  }
  return result;
}

/// The single value of the claim at [path], or null.
///
/// For claims that are conceptually one thing — a department rather than a list
/// of groups. An array with one entry answers that entry, because a provider
/// sending `["cardiology"]` means the same thing as `"cardiology"`; an array
/// with several answers **null** rather than picking one, since which of them
/// was meant is not something this can know.
String? singleClaimValue(Map<String, dynamic>? payload, String path) {
  final values = claimValues(payload, path);
  return values.length == 1 ? values.first : null;
}
