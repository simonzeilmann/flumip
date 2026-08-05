import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/access_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

UserSettingsDto access({bool isAdmin = false, bool passwordAccepted = false}) =>
    UserSettingsDto(isAdmin: isAdmin, passwordAccepted: passwordAccepted);

void main() {
  test('starts out knowing nothing, and offers nothing', () {
    final controller =
        AccessController(fetchAccess: () async => access());
    expect(controller.loading, isTrue);
    expect(controller.isAdmin, isFalse);
    expect(controller.mayAdminister, isFalse);
  });

  test('a signed-in administrator needs no password', () async {
    final controller = AccessController(
      fetchAccess: () async => access(isAdmin: true),
    );
    await controller.reload();
    expect(controller.isAdmin, isTrue);
    expect(controller.mayAdminister, isTrue);
    expect(controller.passwordAccepted, isFalse);
  });

  test('on an install with no sign-in, the password is the credential',
      () async {
    // ⚠️ The case `authController.user?.isAdmin` cannot see: nobody is signed in,
    // so that shortcut says "not an administrator" — yet this is exactly the
    // install where an administrative action is possible, using the settings
    // password.
    final controller = AccessController(
      fetchAccess: () async => access(passwordAccepted: true),
    );
    await controller.reload();
    expect(controller.isAdmin, isFalse);
    expect(controller.passwordAccepted, isTrue);
    expect(controller.mayAdminister, isTrue);
  });

  test('an ordinary signed-in user may not administer anything', () async {
    final controller = AccessController(fetchAccess: () async => access());
    await controller.reload();
    expect(controller.mayAdminister, isFalse);
  });

  test('a failed lookup is its own state, not "no password needed"', () async {
    // Falling back to showing a password box on a transient failure turns every
    // network blip into "type a password", which teaches people to type it.
    final controller = AccessController(
      fetchAccess: () async => throw Exception('offline'),
    );
    await controller.reload();
    expect(controller.failed, isTrue);
    expect(controller.loading, isFalse);
    expect(controller.isAdmin, isFalse);
    expect(controller.passwordAccepted, isFalse);
    expect(controller.mayAdminister, isFalse);
  });

  test('it re-asks whenever sign-in state changes', () async {
    // The tabs are all built before the bearer token exists, so the first answer
    // describes an anonymous caller. Without this, a signed-in administrator
    // keeps being shown a password prompt.
    final auth = ChangeNotifier();
    var calls = 0;
    var admin = false;
    final controller = AccessController(
      fetchAccess: () async {
        calls++;
        return access(isAdmin: admin);
      },
      auth: auth,
    );

    await controller.reload();
    expect(controller.isAdmin, isFalse);

    admin = true;
    auth.notifyListeners();
    await Future<void>.delayed(Duration.zero);

    expect(calls, 2);
    expect(controller.isAdmin, isTrue);
  });

  test('it notifies its listeners on every answer', () async {
    var notifications = 0;
    final controller = AccessController(
      fetchAccess: () async => access(isAdmin: true),
    )..addListener(() => notifications++);

    await controller.reload();

    expect(notifications, 1);
  });
}
