import 'dart:convert';

import 'package:flumip_server/src/auth/claims.dart';
import 'package:test/test.dart';

/// Reading the group claim out of a payload.
///
/// ⚠️ **The shapes below are the whole point of this file.** There is no
/// standard claim for organisational membership, so every provider sends a
/// different name, a different nesting and a different value type. Supporting
/// only the shape the provider in front of you happens to use is the standard
/// way to be quietly incompatible with the next one.
void main() {
  Map<String, dynamic> payload(String json) =>
      jsonDecode(json) as Map<String, dynamic>;

  group('the shapes real providers send', () {
    test('Okta, Auth0, Entra: a top-level array', () {
      expect(
        claimValues(
          payload('{"groups": ["cardiology", "research"]}'),
          'groups',
        ),
        ['cardiology', 'research'],
      );
    });

    test('LDAP-backed: a single string', () {
      expect(
        claimValues(payload('{"department": "cardiology"}'), 'department'),
        ['cardiology'],
      );
    });

    test('Keycloak realm roles: nested one level', () {
      expect(
        claimValues(
          payload('{"realm_access": {"roles": ["cardiology", "offline"]}}'),
          'realm_access.roles',
        ),
        ['cardiology', 'offline'],
      );
    });

    test('Keycloak client roles: nested twice', () {
      expect(
        claimValues(
          payload('{"resource_access": {"flumip": {"roles": ["research"]}}}'),
          'resource_access.flumip.roles',
        ),
        ['research'],
      );
    });
  });

  group('absent, empty and unreadable claims all answer the same thing', () {
    // The caller never has to tell "no such claim" from "no groups": both mean
    // the person is in nothing, everywhere this is used.
    test('an empty list', () {
      for (final (json, path) in [
        ('{}', 'groups'),
        ('{"groups": null}', 'groups'),
        ('{"groups": []}', 'groups'),
        ('{"groups": ""}', 'groups'),
        ('{"groups": ["", "   "]}', 'groups'),
        ('{"other": ["a"]}', 'groups'),
        ('{"realm_access": {}}', 'realm_access.roles'),
        ('{"realm_access": null}', 'realm_access.roles'),
        // The path walks into something that is not an object.
        ('{"realm_access": "nope"}', 'realm_access.roles'),
        ('{"groups": ["a"]}', 'groups.roles'),
        // A number, a bool or an object is not a group name, and guessing what
        // the provider meant would be worse than saying nothing.
        ('{"groups": 3}', 'groups'),
        ('{"groups": true}', 'groups'),
        ('{"groups": {"a": 1}}', 'groups'),
      ]) {
        expect(
          claimValues(payload(json), path),
          isEmpty,
          reason: '$json at "$path"',
        );
      }
    });

    test('an empty or blank path reads nothing, which is the feature off', () {
      expect(claimValues(payload('{"groups": ["a"]}'), ''), isEmpty);
      expect(claimValues(payload('{"groups": ["a"]}'), '   '), isEmpty);
    });

    test('a null payload', () {
      expect(claimValues(null, 'groups'), isEmpty);
    });
  });

  group('tidying the values', () {
    test('trims, drops empties and keeps the order', () {
      expect(claimValues(payload('{"g": ["  a ", "", "b", "   "]}'), 'g'), [
        'a',
        'b',
      ]);
    });

    test('drops duplicates, keeping the first', () {
      expect(claimValues(payload('{"g": ["a", "b", "a"]}'), 'g'), ['a', 'b']);
    });

    test('drops non-strings from a mixed array rather than throwing', () {
      // A malformed claim should cost the caller that claim, not the sign-in.
      expect(claimValues(payload('{"g": ["a", 3, null, "b"]}'), 'g'), [
        'a',
        'b',
      ]);
    });

    test('does not fold case', () {
      // These are the provider's strings. Two spellings may well be two groups.
      expect(claimValues(payload('{"g": ["A", "a"]}'), 'g'), ['A', 'a']);
    });
  });

  group('singleClaimValue', () {
    test('answers a lone value, however it was wrapped', () {
      expect(singleClaimValue(payload('{"d": "cardio"}'), 'd'), 'cardio');
      expect(singleClaimValue(payload('{"d": ["cardio"]}'), 'd'), 'cardio');
    });

    test('⚠️ answers null when there are several, rather than picking', () {
      // Which one was meant is not something this can know, and choosing the
      // first would be an arbitrary decision presented as a fact.
      expect(singleClaimValue(payload('{"d": ["a", "b"]}'), 'd'), isNull);
    });

    test('answers null when there are none', () {
      expect(singleClaimValue(payload('{}'), 'd'), isNull);
    });
  });
}
