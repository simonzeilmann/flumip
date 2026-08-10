import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/project_options_view.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpOptions(WidgetTester tester, ProjectOptions options) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: ProjectOptionsView(options: options),
          ),
        ),
      ),
    ),
  );
}

void main() {
  test('optional parameters are omitted rather than shown empty', () {
    final labels = ProjectOptionsView.rowsFor(
      ProjectOptions(),
    ).map((r) => r.$1);

    expect(labels, isNot(contains('Arm lengths')));
    expect(labels, isNot(contains('Genome dir')));
  });

  test('an arm length that is set is listed', () {
    final rows = ProjectOptionsView.rowsFor(
      ProjectOptions(armLengths: '16,17,18'),
    );
    expect(rows, contains(('Arm lengths', '16,17,18')));
  });

  test('an empty arm length string counts as unset', () {
    final labels = ProjectOptionsView.rowsFor(
      ProjectOptions(armLengths: ''),
    ).map((r) => r.$1);
    expect(labels, isNot(contains('Arm lengths')));
  });

  test('⚠️ booleans read as on and off, never as true and false', () {
    // They used to be spelled out twice as an `if/else` pair per parameter.
    final rows = ProjectOptionsView.rowsFor(
      ProjectOptions(trf: true, checkCopyNumber: false),
    );

    expect(rows, contains(('Tandem Repeats Finder', 'on')));
    expect(rows, contains(('Check copy number', 'off')));
    expect(rows.map((r) => r.$2), isNot(contains('true')));
    expect(rows.map((r) => r.$2), isNot(contains('false')));
  });

  test('⚠️ the score method is the name, not the enum', () {
    // `'${o.scoreMethod}'` prints `ScoreMethod.logistic`.
    final rows = ProjectOptionsView.rowsFor(
      ProjectOptions(scoreMethod: ScoreMethod.logistic),
    );
    expect(rows, contains(('Score method', 'logistic')));
  });

  testWidgets('renders every row it was given, under one heading', (
    tester,
  ) async {
    final options = ProjectOptions();
    await pumpOptions(tester, options);

    expect(find.text('Design options'), findsOneWidget);
    for (final (label, _) in ProjectOptionsView.rowsFor(options)) {
      expect(find.text(label), findsOneWidget, reason: 'missing row: $label');
    }
    expect(tester.takeException(), isNull);
  });
}
