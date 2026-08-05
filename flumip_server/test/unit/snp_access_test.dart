import 'package:flumip_server/src/auth/project_access.dart';
import 'package:test/test.dart';

/// Pure tests: neither predicate does any I/O, so none of this needs a database.
///
/// These are the load-bearing tests for custom SNPs. `snpIsAccessible` decides
/// whether one user's uploaded file can be seen by another, and `snpIsWritable`
/// decides who can delete it — including the rule that keeps an ordinary user's
/// delete button away from the shared genome tree.
void main() {
  const owner = Principal(userId: 7);
  const other = Principal(userId: 8);
  const admin = Principal(userId: 9, isAdmin: true);

  bool visible({
    bool enforcing = true,
    Principal principal = Principal.anonymous,
    bool private = true,
    int? snpOwner,
  }) => snpIsAccessible(
    enforcing: enforcing,
    principal: principal,
    private: private,
    owner: snpOwner,
  );

  bool writable({
    bool enforcing = true,
    Principal principal = Principal.anonymous,
    int? snpOwner,
  }) =>
      snpIsWritable(enforcing: enforcing, principal: principal, owner: snpOwner);

  group('snpIsAccessible: shared and global SNPs', () {
    test('a non-private SNP is visible to everyone, signed in or not', () {
      expect(visible(private: false, snpOwner: null), isTrue);
      expect(visible(private: false, principal: other, snpOwner: 7), isTrue);
      expect(
        visible(private: false, principal: Principal.anonymous, snpOwner: 7),
        isTrue,
      );
    });

    test('a global SNP stays visible while nobody is signed in', () {
      // Globals are what the picker is made of on a fresh install. If this ever
      // fails, switching single sign-on on empties everybody's SNP dropdown.
      expect(
        visible(private: false, principal: Principal.anonymous, snpOwner: null),
        isTrue,
      );
    });
  });

  group('snpIsAccessible: the default install (no authentication)', () {
    test('everything is visible when not enforcing', () {
      expect(visible(enforcing: false, snpOwner: null), isTrue);
      expect(visible(enforcing: false, principal: other, snpOwner: 7), isTrue);
    });
  });

  group('snpIsAccessible: private SNPs', () {
    test('the owner sees their own', () {
      expect(visible(principal: owner, snpOwner: 7), isTrue);
    });

    test('another signed-in user does not', () {
      expect(visible(principal: other, snpOwner: 7), isFalse);
    });

    test('an anonymous caller does not', () {
      expect(visible(snpOwner: 7), isFalse);
    });

    test('an admin does', () {
      expect(visible(principal: admin, snpOwner: 7), isTrue);
    });

    test('an admin flag without a user id still grants access', () {
      // What AuthorizationService falls back to when authId cannot be parsed.
      expect(
        visible(principal: const Principal(isAdmin: true), snpOwner: 7),
        isTrue,
      );
    });
  });

  group('snpIsAccessible: a private SNP with no owner', () {
    // ⚠️ The one place this predicate deliberately disagrees with
    // projectIsAccessible, where a null owner grants access to everybody. There
    // that rule exists so switching sign-on on does not look like data loss for
    // projects that predate ownership. No such body of SNPs exists — `private`
    // has never been written — so this can fall closed, which is what keeps an
    // upload private after its uploader's identity is deleted (onDelete=SetNull).
    test('is hidden from an ordinary user rather than shared', () {
      expect(visible(principal: other, snpOwner: null), isFalse);
    });

    test('is hidden from an anonymous caller', () {
      expect(visible(snpOwner: null), isFalse);
    });

    test('is still visible to an admin, who can then clean it up', () {
      expect(visible(principal: admin, snpOwner: null), isTrue);
    });
  });

  group('snpIsWritable: the default install', () {
    test('everything is writable when not enforcing', () {
      // A no-auth install has no identities, so there is nobody to attribute an
      // upload to and nobody to withhold it from. Matches every other gate.
      expect(writable(enforcing: false, snpOwner: null), isTrue);
      expect(writable(enforcing: false, principal: other, snpOwner: 7), isTrue);
    });
  });

  group('snpIsWritable: ownership survives sharing', () {
    test('the owner may change their own', () {
      expect(writable(principal: owner, snpOwner: 7), isTrue);
    });

    test('another signed-in user may not, even though they can see it', () {
      // The whole point of having two predicates: putting a panel up for the lab
      // to use is not the same as handing them the ability to delete it.
      expect(visible(private: false, principal: other, snpOwner: 7), isTrue);
      expect(writable(principal: other, snpOwner: 7), isFalse);
    });

    test('an anonymous caller may not', () {
      expect(writable(snpOwner: 7), isFalse);
    });

    test('an admin may', () {
      expect(writable(principal: admin, snpOwner: 7), isTrue);
    });
  });

  group('snpIsWritable: an SNP with no owner', () {
    // Every global scanned SNP. Deleting one removes files from the shared
    // genome tree, so it must never be reachable from an ordinary user's delete
    // button — the admin-only path is a separate endpoint with its own gate.
    test('is not writable by a signed-in user', () {
      expect(writable(principal: owner, snpOwner: null), isFalse);
      expect(writable(principal: other, snpOwner: null), isFalse);
    });

    test('is writable by an admin', () {
      expect(writable(principal: admin, snpOwner: null), isTrue);
    });
  });
}
