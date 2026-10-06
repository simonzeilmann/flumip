import 'package:flumip_client/flumip_client.dart';

/// Turns a server error into something worth showing a person.
///
/// Every call site in the project UI used to interpolate the exception directly
/// (`'Failed to add gene: $e'`), which for a typed Serverpod exception yields its
/// `toString()` — class name, wrapper and all — rather than the message the
/// server actually wrote. That was tolerable while the only failures were
/// genuinely technical. It stops being tolerable with [ProjectAccessDeniedException],
/// which exists precisely to say one clear sentence to a user.
///
/// Unknown errors fall through to `'$error'`, i.e. exactly what the call sites
/// did before, so wrapping an existing message in this can only improve it.
String describeError(Object error) {
  if (error is ProjectAccessDeniedException) return error.message;
  if (error is FlumipFileNotFoundException) return error.message;
  if (error is ArgumentException) return error.message;
  if (error is BedCreationException) return error.message;
  return '$error';
}

/// Whether this error means "signed in, but not allowed to touch that".
///
/// Distinct from a transient failure: retrying will not fix it, so the caller
/// should stop polling rather than re-reporting every ten seconds.
bool isAccessDenied(Object error) => error is ProjectAccessDeniedException;
