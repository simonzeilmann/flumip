import 'package:flumip_flutter/project/department_picker.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which group a project belongs to.
///
/// Shown to the owner rather than to administrators only, unlike the owner
/// picker beside it — so the cases that matter are about what a non-admin is
/// offered, and about a project sitting in a group this caller is not in.
Future<List<String?>> pumpPicker(
  WidgetTester tester, {
  required List<String> departments,
  String? department,
}) async {
  final chosen = <String?>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: DepartmentPicker(
          departments: departments,
          department: department,
          onChanged: chosen.add,
        ),
      ),
    ),
  );
  return chosen;
}

void main() {
  testWidgets('offers every department the caller may use', (tester) async {
    await pumpPicker(tester, departments: ['cardiology', 'research']);

    await tester.tap(find.byType(DropdownButton<String?>));
    await tester.pumpAndSettle();

    expect(find.text('cardiology'), findsWidgets);
    expect(find.text('research'), findsWidgets);
    expect(find.text('None — only you and administrators'), findsWidgets);
  });

  testWidgets('reports the chosen department', (tester) async {
    final chosen = await pumpPicker(
      tester,
      departments: ['cardiology', 'research'],
    );

    await tester.tap(find.byType(DropdownButton<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('research').last);
    await tester.pumpAndSettle();

    expect(chosen, ['research']);
  });

  testWidgets('taking a project out of a department reports null', (
    tester,
  ) async {
    final chosen = await pumpPicker(
      tester,
      departments: ['cardiology'],
      department: 'cardiology',
    );

    await tester.tap(find.byType(DropdownButton<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('None — only you and administrators').last);
    await tester.pumpAndSettle();

    expect(chosen, [null]);
  });

  testWidgets('⚠️ shows a department the caller is not a member of', (
    tester,
  ) async {
    // A DropdownButton whose value matches no item throws, and this happens for
    // real: an admin moved the project, or the group was renamed in the
    // provider. Dropping it would silently claim the project has no department.
    await pumpPicker(
      tester,
      departments: ['cardiology'],
      department: 'a-group-i-left',
    );

    expect(tester.takeException(), isNull);
    expect(find.text('a-group-i-left'), findsOneWidget);
  });

  testWidgets('an empty department reads as none, not as a broken value', (
    tester,
  ) async {
    await pumpPicker(tester, departments: ['cardiology'], department: '');

    expect(tester.takeException(), isNull);
    expect(find.text('None — only you and administrators'), findsOneWidget);
  });
}
