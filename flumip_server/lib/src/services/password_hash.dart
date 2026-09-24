/// PBKDF2-HMAC-SHA256 password hashing, for the one password this server stores
/// itself.
///
/// Everything here is pure — no `Session`, no database, no clock — so the format
/// and the derivation are tested directly against the published PBKDF2 vectors
/// in `test/unit/password_hash_test.dart`.
///
/// ⚠️ **This is hand-written cryptography, which normally deserves a raised
/// eyebrow.** The justification is narrow: PBKDF2 is fully specified in RFC
/// 8018, the whole construction below is twenty lines of HMAC and XOR, and it is
/// checked against the standard test vectors on every run. The alternative was a
/// new dependency for a single field, on a project with five of them. If a
/// hashing dependency ever arrives for another reason, replace this — the format
/// is self-describing, so a replacement can keep reading what it wrote.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// The name this file writes into every hash it produces.
const pbkdf2Algorithm = 'pbkdf2-sha256';

/// The iteration count used for new hashes.
///
/// Well under the 600k OWASP suggests for PBKDF2-HMAC-SHA256, and deliberately
/// so. This password authenticates *every* settings call rather than a
/// once-a-day login, so the cost is paid on each save, each test mail and each
/// status refresh. Measured on the dev box, JIT: 120k ≈ 290 ms, 200k ≈ 500 ms,
/// 600k ≈ 1.5 s. The last is not a usable settings tab.
///
/// What makes the lower figure defensible is what the password guards: a single
/// shared break-glass credential on an internal tool, which stops working
/// altogether once single sign-on is enforcing (see `SettingsService`). The hash
/// carries its own iteration count, so raising this later costs nothing — old
/// hashes keep verifying at the count they were written with.
const pbkdf2Iterations = 120000;

/// Salt and derived-key length, in bytes. 32 = the SHA-256 output width.
const pbkdf2SaltBytes = 16;
const pbkdf2KeyBytes = 32;

/// Hashes [password] with a fresh random salt.
///
/// The result is self-describing — algorithm, iteration count, salt and key,
/// `$`-separated — so a stored value can always be verified without knowing what
/// this file's constants happened to be when it was written.
String hashPassword(String password, {int iterations = pbkdf2Iterations}) {
  final salt = _randomBytes(pbkdf2SaltBytes);
  final key = pbkdf2(
    password: utf8.encode(password),
    salt: salt,
    iterations: iterations,
    length: pbkdf2KeyBytes,
  );
  return '$pbkdf2Algorithm\$$iterations\$'
      '${base64.encode(salt)}\$${base64.encode(key)}';
}

/// Whether [stored] is one of this file's hashes rather than something else.
///
/// The something else that matters is a plaintext password left in the column by
/// an install that predates hashing. `SettingsService` uses this to tell the two
/// apart, so a legacy value can be accepted once and immediately replaced with a
/// hash. Anything malformed answers false and is then treated as plaintext,
/// which fails to match and locks nothing open.
bool looksLikePasswordHash(String stored) => _parse(stored) != null;

/// Whether [password] is the one [stored] was made from.
///
/// False for any stored value this file did not write, including plaintext:
/// deciding what to do about those belongs to the caller, which is the only
/// place that can also fix them.
bool verifyPassword(String password, String stored) {
  final parts = _parse(stored);
  if (parts == null) return false;

  final derived = pbkdf2(
    password: utf8.encode(password),
    salt: parts.salt,
    iterations: parts.iterations,
    length: parts.key.length,
  );
  return constantTimeEquals(derived, parts.key);
}

/// Compares without leaking where the first difference is.
///
/// Length is not secret here — it is fixed by [pbkdf2KeyBytes] — so returning
/// early on a length mismatch gives nothing away.
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var difference = 0;
  for (var i = 0; i < a.length; i++) {
    difference |= a[i] ^ b[i];
  }
  return difference == 0;
}

/// PBKDF2 as specified in RFC 8018 §5.2, with HMAC-SHA256 as the PRF.
///
/// Exposed rather than private so the test can drive it with the published
/// vectors; nothing outside this file and its test should need it.
Uint8List pbkdf2({
  required List<int> password,
  required List<int> salt,
  required int iterations,
  required int length,
}) {
  if (iterations < 1) {
    throw ArgumentError.value(iterations, 'iterations', 'must be at least 1');
  }
  if (length < 1) {
    throw ArgumentError.value(length, 'length', 'must be at least 1');
  }

  final prf = Hmac(sha256, password);
  final out = Uint8List(length);
  var written = 0;

  for (var block = 1; written < length; block++) {
    // U1 = PRF(password, salt ‖ INT_BE32(block))
    var u = Uint8List.fromList(
      prf.convert([
        ...salt,
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ]).bytes,
    );
    final accumulated = Uint8List.fromList(u);

    // T_block = U1 ⊕ U2 ⊕ … ⊕ U_iterations, where U_n = PRF(password, U_n-1).
    for (var i = 1; i < iterations; i++) {
      u = Uint8List.fromList(prf.convert(u).bytes);
      for (var j = 0; j < accumulated.length; j++) {
        accumulated[j] ^= u[j];
      }
    }

    final take = min(accumulated.length, length - written);
    out.setRange(written, written + take, accumulated);
    written += take;
  }

  return out;
}

class _Parsed {
  const _Parsed(this.iterations, this.salt, this.key);
  final int iterations;
  final Uint8List salt;
  final Uint8List key;
}

/// Reads a stored hash back, or null if it is not one.
///
/// Every failure answers null rather than throwing. The caller's question is
/// always "does this password match", and a corrupt column must answer no — not
/// turn an ordinary settings call into a 500.
_Parsed? _parse(String stored) {
  final parts = stored.split(r'$');
  if (parts.length != 4) return null;
  if (parts[0] != pbkdf2Algorithm) return null;

  final iterations = int.tryParse(parts[1]);
  if (iterations == null || iterations < 1) return null;

  try {
    final salt = base64.decode(parts[2]);
    final key = base64.decode(parts[3]);
    if (salt.isEmpty || key.isEmpty) return null;
    return _Parsed(iterations, salt, key);
  } on FormatException {
    return null;
  }
}

final _random = Random.secure();

Uint8List _randomBytes(int count) =>
    Uint8List.fromList(List.generate(count, (_) => _random.nextInt(256)));
