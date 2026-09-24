import 'dart:convert';

import 'package:flumip_server/src/services/password_hash.dart';
import 'package:test/test.dart';

/// Hex, because every published PBKDF2 vector is written that way.
String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  // ⚠️ The reason this file exists. `pbkdf2` is hand-written, so it is worth
  // exactly as much as its agreement with the specification — these are the
  // standard PBKDF2-HMAC-SHA256 vectors (RFC 6070's inputs carried over to
  // SHA-256, plus RFC 7914 §11's). A typo in the block counter or the XOR
  // produces a hash that is perfectly self-consistent and still wrong; only a
  // vector catches that.
  group('pbkdf2 against the published vectors', () {
    void vector(
      String label, {
      required String password,
      required String salt,
      required int iterations,
      required int length,
      required String expected,
    }) {
      test(label, () {
        final key = pbkdf2(
          password: utf8.encode(password),
          salt: utf8.encode(salt),
          iterations: iterations,
          length: length,
        );
        expect(_hex(key), expected);
      });
    }

    vector(
      'c=1, dkLen=32',
      password: 'password',
      salt: 'salt',
      iterations: 1,
      length: 32,
      expected:
          '120fb6cffcf8b32c43e7225256c4f837'
          'a86548c92ccc35480805987cb70be17b',
    );

    vector(
      'c=2, dkLen=32',
      password: 'password',
      salt: 'salt',
      iterations: 2,
      length: 32,
      expected:
          'ae4d0c95af6b46d32d0adff928f06dd0'
          '2a303f8ef3c251dfd6e2d85a95474c43',
    );

    vector(
      'c=4096, dkLen=32',
      password: 'password',
      salt: 'salt',
      iterations: 4096,
      length: 32,
      expected:
          'c5e478d59288c841aa530db6845c4c8d'
          '962893a001ce4e11a4963873aa98134a',
    );

    // The one that needs more than one output block, which is the half of the
    // algorithm the other vectors never reach.
    vector(
      'c=4096, dkLen=40 — spans two blocks',
      password: 'passwordPASSWORDpassword',
      salt: 'saltSALTsaltSALTsaltSALTsaltSALTsalt',
      iterations: 4096,
      length: 40,
      expected:
          '348c89dbcbd32b2f32d814b8116e84cf2b17347e'
          'bc1800181c4e2a1fb8dd53e1c635518c7dac47e9',
    );

    vector(
      'RFC 7914 §11 — c=1, dkLen=64',
      password: 'passwd',
      salt: 'salt',
      iterations: 1,
      length: 64,
      expected:
          '55ac046e56e3089fec1691c22544b605f94185216dde0465'
          'e68b9d57c20dacbc49ca9cccf179b645991664b39d77ef31'
          '7c71b845b1e30bd509112041d3a19783',
    );
  });

  group('pbkdf2 argument checking', () {
    test('refuses zero iterations', () {
      expect(
        () => pbkdf2(
          password: utf8.encode('x'),
          salt: utf8.encode('y'),
          iterations: 0,
          length: 32,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('refuses a zero-length key', () {
      expect(
        () => pbkdf2(
          password: utf8.encode('x'),
          salt: utf8.encode('y'),
          iterations: 1,
          length: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('hashPassword', () {
    test('verifies the password it was made from', () {
      final stored = hashPassword('correct horse battery staple');
      expect(verifyPassword('correct horse battery staple', stored), isTrue);
    });

    test('refuses a different password', () {
      final stored = hashPassword('correct horse battery staple');
      expect(verifyPassword('correct horse battery stapler', stored), isFalse);
      expect(verifyPassword('', stored), isFalse);
    });

    test('is salted — the same password hashes differently every time', () {
      // If this ever fails, the salt is not random and two installs with the
      // same password would share a hash.
      final a = hashPassword('changeme');
      final b = hashPassword('changeme');
      expect(a, isNot(b));
      expect(verifyPassword('changeme', a), isTrue);
      expect(verifyPassword('changeme', b), isTrue);
    });

    test(
      'says what it is, so a stored value can be read without this file',
      () {
        final stored = hashPassword('changeme', iterations: 4096);
        final parts = stored.split(r'$');
        expect(parts, hasLength(4));
        expect(parts[0], 'pbkdf2-sha256');
        expect(parts[1], '4096');
      },
    );

    test('verifies at the iteration count it was written with', () {
      // The point of carrying the count in the string: raising the default must
      // not invalidate everything already stored.
      final old = hashPassword('changeme', iterations: 1000);
      expect(verifyPassword('changeme', old), isTrue);
    });

    test('handles a non-ASCII password', () {
      final stored = hashPassword('Paßwort—ünïcode');
      expect(verifyPassword('Paßwort—ünïcode', stored), isTrue);
      expect(verifyPassword('Passwort—unicode', stored), isFalse);
    });
  });

  group('looksLikePasswordHash', () {
    test('recognises what hashPassword writes', () {
      expect(looksLikePasswordHash(hashPassword('changeme')), isTrue);
    });

    // Everything below is what a settings column can hold on an install that
    // predates hashing. All of it must read as "not a hash" so the caller takes
    // the legacy branch rather than silently refusing a password that works.
    test('rejects a plaintext password', () {
      expect(looksLikePasswordHash('changeme'), isFalse);
      expect(looksLikePasswordHash(''), isFalse);
      expect(looksLikePasswordHash(r'a$b'), isFalse);
    });

    test('rejects a plaintext password that happens to contain dollars', () {
      expect(looksLikePasswordHash(r'my$secret$pass$word'), isFalse);
      expect(looksLikePasswordHash(r'pbkdf2-sha256$notanumber$aa$bb'), isFalse);
    });

    test('rejects another algorithm', () {
      expect(looksLikePasswordHash(r'bcrypt$12$aaaa$bbbb'), isFalse);
    });
  });

  group('verifyPassword on a value it did not write', () {
    // A corrupt or legacy column must answer "no" rather than throwing — a
    // settings call that 500s is harder to recover from than one that refuses.
    test('never throws, always refuses', () {
      for (final stored in [
        '',
        'changeme',
        r'pbkdf2-sha256$120000$!!!not-base64!!!$aaaa',
        r'pbkdf2-sha256$-1$aaaa$bbbb',
        r'pbkdf2-sha256$120000$$',
        r'pbkdf2-sha256$120000$aaaa',
      ]) {
        expect(
          verifyPassword('changeme', stored),
          isFalse,
          reason: 'stored value: "$stored"',
        );
      }
    });
  });

  group('constantTimeEquals', () {
    test('agrees with ordinary equality', () {
      expect(constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
      expect(constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
      expect(constantTimeEquals([1, 2, 3], [1, 2]), isFalse);
      expect(constantTimeEquals([], []), isTrue);
    });
  });
}
