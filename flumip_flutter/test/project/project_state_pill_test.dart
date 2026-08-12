import 'package:flumip_flutter/project/project_state.dart';
import 'package:flumip_flutter/project/project_state_pill.dart';
import 'package:flumip_flutter/ui/status_pill.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<StatusPill> pumpPill(WidgetTester tester, ProjectState state) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: Center(child: ProjectStatePill(state: state)),
      ),
    ),
  );
  return tester.widget<StatusPill>(find.byType(StatusPill));
}

void main() {
  testWidgets('every state has a badge, and says what it is', (tester) async {
    for (final state in ProjectState.values) {
      final pill = await pumpPill(tester, state);
      expect(pill.label, state.label);
      expect(pill.icon, isNotNull);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('⚠️ a warning is amber where a plain success is green', (
    tester,
  ) async {
    // The whole reason completeWithWarning exists as a separate state: the row
    // has to say there is something to read without claiming the run failed.
    final complete = await pumpPill(tester, ProjectState.complete);
    final warned = await pumpPill(tester, ProjectState.completeWithWarning);
    final failed = await pumpPill(tester, ProjectState.failed);

    expect(warned.label, complete.label, reason: 'both read as Complete');
    expect(warned.colour, isNot(complete.colour));
    expect(warned.colour, isNot(failed.colour));
    // Same tick, so the two complete states are not mistaken for each other's
    // opposite at a glance.
    expect(warned.icon, complete.icon);
  });

  testWidgets('a failure is the error colour', (tester) async {
    late Color scheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              scheme = context.colours.error;
              return const ProjectStatePill(state: ProjectState.failed);
            },
          ),
        ),
      ),
    );

    final pill = tester.widget<StatusPill>(find.byType(StatusPill));
    expect(pill.colour, scheme);
  });
}
