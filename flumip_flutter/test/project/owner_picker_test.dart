import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/owner_picker.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

FlumipUserDto user({
  required int id,
  String email = 'a@example.com',
  String displayName = '',
  bool isGuest = false,
}) => FlumipUserDto(
  id: id,
  email: email,
  displayName: displayName,
  isGuest: isGuest,
);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<FlumipUserDto> owners,
    int? ownerId,
    void Function(int?)? onChanged,
    bool publicMode = false,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: OwnerPicker(
          owners: owners,
          ownerId: ownerId,
          onChanged: onChanged ?? (_) {},
          publicMode: publicMode,
        ),
      ),
    ),
  );

  testWidgets('an unowned project reads as shared with everyone', (
    tester,
  ) async {
    await pump(tester, owners: [user(id: 1)], ownerId: null);
    expect(find.text('Unowned — shared with everyone'), findsOneWidget);
  });

  testWidgets('⚠️ on a public instance unowned reads as administrators only', (
    tester,
  ) async {
    // The server shows an unowned project to administrators alone there, so
    // "shared with everyone" promised the opposite of what releasing one does.
    await pump(tester, owners: [user(id: 1)], ownerId: null, publicMode: true);
    expect(find.text('Unowned — administrators only'), findsOneWidget);
    expect(find.text('Unowned — shared with everyone'), findsNothing);
  });

  testWidgets('a display name is preferred, and the address is the fallback', (
    tester,
  ) async {
    await pump(
      tester,
      owners: [user(id: 1, displayName: 'Ada Lovelace')],
      ownerId: 1,
    );
    expect(find.text('Ada Lovelace'), findsOneWidget);

    await pump(
      tester,
      owners: [user(id: 1, email: 'ada@example.com')],
      ownerId: 1,
    );
    expect(find.text('ada@example.com'), findsOneWidget);
  });

  testWidgets('⚠️ a guest has no name or address and is labelled by its id', (
    tester,
  ) async {
    // A guest on a public instance is a user with an empty email and an empty
    // display name. Labelled like everyone else it was a blank row, and a
    // public instance has many of them.
    await pump(
      tester,
      owners: [user(id: 7, email: '', isGuest: true)],
      ownerId: 7,
    );
    expect(find.text('Guest #7'), findsOneWidget);
  });

  testWidgets('a user with neither name nor address is never a blank row', (
    tester,
  ) async {
    await pump(tester, owners: [user(id: 3, email: '')], ownerId: 3);
    expect(find.text('User #3'), findsOneWidget);
  });

  testWidgets('⚠️ of the guests, only the one who owns the project is listed', (
    tester,
  ) async {
    // A public instance has a guest per visitor. Offering all of them buried
    // the handful of real users under rows nobody could tell apart.
    await pump(
      tester,
      owners: [
        user(id: 1, email: '', isGuest: true),
        user(id: 2, displayName: 'Ada'),
        user(id: 3, email: '', isGuest: true),
        user(id: 4, displayName: 'Grace'),
      ],
      ownerId: 3,
    );

    await tester.tap(find.byType(DropdownButton<int?>));
    await tester.pumpAndSettle();

    expect(find.text('Guest #1'), findsNothing);
    double top(String label) => tester.getTopLeft(find.text(label).last).dy;
    expect(top('Ada'), lessThan(top('Grace')));
    expect(top('Grace'), lessThan(top('Guest #3')));
  });

  testWidgets('no guest is offered for a project a guest does not own', (
    tester,
  ) async {
    await pump(
      tester,
      owners: [
        user(id: 1, email: '', isGuest: true),
        user(id: 2, displayName: 'Ada'),
      ],
      ownerId: 2,
    );

    await tester.tap(find.byType(DropdownButton<int?>));
    await tester.pumpAndSettle();

    expect(find.text('Guest #1'), findsNothing);
    expect(find.text('Ada'), findsWidgets);
  });

  testWidgets('⚠️ an owner missing from the list falls back to unowned', (
    tester,
  ) async {
    // A DropdownButton whose value matches no item throws, and the owner can
    // legitimately be gone: the identity may have been deleted since the project
    // was loaded, which is what ON DELETE SET NULL will have made it anyway.
    await pump(tester, owners: [user(id: 1)], ownerId: 999);

    expect(tester.takeException(), isNull);
    expect(find.text('Unowned — shared with everyone'), findsOneWidget);
  });

  testWidgets('picking someone reports their id', (tester) async {
    int? chosen;
    var called = false;
    await pump(
      tester,
      owners: [user(id: 4, displayName: 'Grace')],
      ownerId: null,
      onChanged: (id) {
        called = true;
        chosen = id;
      },
    );

    await tester.tap(find.byType(DropdownButton<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grace').last);
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(chosen, 4);
  });
}
