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
    String? department,
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
          department: 'cardiology',
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
        allowed(principal: other, projectOwner: 7, department: 'cardiology'),
        isFalse,
      );
    });

    test('a Principal has no departments unless a claim is configured', () {
      // Empty is the default everywhere, which is what keeps the clause inert
      // on an install that has not set `Settings.oidcDepartmentClaim`.
      expect(Principal.anonymous.departments, isEmpty);
      expect(const Principal(userId: 1).departments, isEmpty);
      expect(const Principal(userId: 1, isAdmin: true).departments, isEmpty);
    });

    test('a shared department grants access', () {
      expect(
        allowed(
          principal: const Principal(userId: 8, departments: ['cardiology']),
          projectOwner: 7,
          department: 'cardiology',
        ),
        isTrue,
      );
    });

    test('any one of several groups is enough', () {
      // People are in more than one, which is why this is a list. A rule that
      // only looked at the first would be wrong for most real users.
      expect(
        allowed(
          principal: const Principal(
            userId: 8,
            departments: ['research', 'cardiology', 'teaching'],
          ),
          projectOwner: 7,
          department: 'cardiology',
        ),
        isTrue,
      );
    });

    test('a different department is refused', () {
      expect(
        allowed(
          principal: const Principal(userId: 8, departments: ['research']),
          projectOwner: 7,
          department: 'cardiology',
        ),
        isFalse,
      );
    });

    test('⚠️ departments are compared verbatim, including case', () {
      // These are the provider's own strings on both sides. Folding case would
      // make `Cardiology` and `cardiology` the same department at a provider
      // that considers them different.
      expect(
        allowed(
          principal: const Principal(userId: 8, departments: ['Cardiology']),
          projectOwner: 7,
          department: 'cardiology',
        ),
        isFalse,
      );
    });

    test('⚠️ a project with no department is not shared with anybody', () {
      // The emptiness guard. Without it this describes every project and every
      // caller on an install with no claim configured, and the whole rule
      // becomes "anyone may touch anything".
      expect(
        allowed(
          principal: const Principal(userId: 8, departments: ['cardiology']),
          projectOwner: 7,
          department: null,
        ),
        isFalse,
      );
      expect(
        allowed(
          principal: const Principal(userId: 8, departments: ['cardiology']),
          projectOwner: 7,
          department: '',
        ),
        isFalse,
      );
    });

    test('⚠️ a caller with no departments matches no project', () {
      expect(
        allowed(
          principal: const Principal(userId: 8),
          projectOwner: 7,
          department: 'cardiology',
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
