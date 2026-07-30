import 'package:flumip_server/src/auth/project_access.dart';
import 'package:test/test.dart';

/// Pure tests: [projectIsAccessible] does no I/O, so none of this needs a
/// database or a server.
///
/// This is the whole authorization policy in one function, so these are the
/// load-bearing tests of the change. Two of them exist because of specific ways
/// this rule could go wrong rather than to cover a line — see the department
/// group and "the default install".
void main() {
  const owner = Principal(userId: 7);
  const other = Principal(userId: 8);
  const admin = Principal(userId: 9, isAdmin: true);

  bool allowed({
    bool enforcing = true,
    Principal principal = Principal.anonymous,
    int? projectOwner,
    int? department,
  }) => projectIsAccessible(
    enforcing: enforcing,
    principal: principal,
    owner: projectOwner,
    department: department,
  );

  group('the default install (no authentication)', () {
    // If any of these ever fails, the standard deployment has lost access to its
    // own data. Nothing else in this file matters as much.
    test('everything is allowed when not enforcing', () {
      expect(allowed(enforcing: false, projectOwner: null), isTrue);
      expect(allowed(enforcing: false, projectOwner: 7), isTrue);
      expect(
        allowed(enforcing: false, principal: other, projectOwner: 7),
        isTrue,
      );
    });

    test('an anonymous caller keeps full access when not enforcing', () {
      expect(
        allowed(
          enforcing: false,
          principal: Principal.anonymous,
          projectOwner: 7,
          department: 3,
        ),
        isTrue,
      );
    });
  });

  group('ownership', () {
    test('the owner is allowed', () {
      expect(allowed(principal: owner, projectOwner: 7), isTrue);
    });

    test('a different signed-in user is refused', () {
      expect(allowed(principal: other, projectOwner: 7), isFalse);
    });

    test('an admin is allowed regardless of owner', () {
      expect(allowed(principal: admin, projectOwner: 7), isTrue);
    });

    test('an anonymous caller is refused an owned project while enforcing', () {
      expect(allowed(projectOwner: 7), isFalse);
    });
  });

  group('unowned projects', () {
    // Every project on an install that predates authorization has owner == null.
    // Refusing these would make switching SSO on look like data loss.
    test('are accessible to any signed-in user', () {
      expect(allowed(principal: owner, projectOwner: null), isTrue);
      expect(allowed(principal: other, projectOwner: null), isTrue);
    });

    test('are accessible to an admin', () {
      expect(allowed(principal: admin, projectOwner: null), isTrue);
    });

    test('are accessible even to an anonymous caller while enforcing', () {
      // Reachable only if an endpoint is enforcing but requireLogin let the call
      // through. Deliberately allowed: unowned means shared, and the endpoint
      // gate — not this predicate — is what keeps strangers out.
      expect(allowed(projectOwner: null), isTrue);
    });
  });

  group('the department clause is inert until a claim is wired up', () {
    test('two null departments do NOT grant access', () {
      // The trap this whole group exists for. `null == null` is true in Dart, so
      // a clause without the null guards would hand every department-less
      // project to every department-less caller — which today is all of them and
      // all of us — silently turning the rule into "anyone may touch anything".
      expect(
        allowed(principal: other, projectOwner: 7, department: null),
        isFalse,
      );
    });

    test('a project with a department is not shared with a null-department '
        'caller', () {
      expect(
        allowed(principal: other, projectOwner: 7, department: 3),
        isFalse,
      );
    });

    test('no Principal the server can build today has a department', () {
      // Guards the claim made in Principal's and the model's documentation. If
      // somebody wires a claim up, this fails and points at the docs to update.
      expect(Principal.anonymous.departmentId, isNull);
      expect(const Principal(userId: 1).departmentId, isNull);
      expect(const Principal(userId: 1, isAdmin: true).departmentId, isNull);
    });

    test('matching departments grant access once one is set', () {
      // The seam works — this is what switching the claim on would buy.
      expect(
        allowed(
          principal: const Principal(userId: 8, departmentId: 3),
          projectOwner: 7,
          department: 3,
        ),
        isTrue,
      );
    });

    test('mismatched departments are refused', () {
      expect(
        allowed(
          principal: const Principal(userId: 8, departmentId: 4),
          projectOwner: 7,
          department: 3,
        ),
        isFalse,
      );
    });
  });

  group('an admin flag without a user id', () {
    // What AuthorizationService falls back to when authId cannot be parsed.
    // Dropping the flag there would silently demote an admin, so the predicate
    // has to honour it.
    test('still grants access', () {
      expect(
        allowed(principal: const Principal(isAdmin: true), projectOwner: 7),
        isTrue,
      );
    });
  });
}
