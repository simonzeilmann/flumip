import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/owner_picker.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FlumipUserDto user({
  required int id,
  String email = 'a@example.com',
  String displayName = '',
}) => FlumipUserDto(id: id, email: email, displayName: displayName);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<FlumipUserDto> owners,
    int? ownerId,
    void Function(int?)? onChanged,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: OwnerPicker(
          owners: owners,
          ownerId: ownerId,
          onChanged: onChanged ?? (_) {},
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
