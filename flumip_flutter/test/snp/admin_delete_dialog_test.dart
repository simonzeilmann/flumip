import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/snp/delete_snp_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The first real widget tests in this app, on the single highest-consequence
/// piece of interface in it: the confirmation that stands between an
/// administrator and permanently deleting the server's reference SNP data.
///
/// They are possible at all because the dialog takes its data as parameters and
/// returns its answer, touching no global client — a constraint worth keeping for
/// its own sake, of which this is the dividend.
Snp snpFixture({String name = 'dbSNP common', bool custom = false}) => Snp(
  id: 42,
  name: name,
  vcfPath: '/opt/flumip/data/genomes/human/hg38/snp/common/common.vcf.gz',
  tbiPath: '/opt/flumip/data/genomes/human/hg38/snp/common/common.vcf.gz.tbi',
  folder: '/opt/flumip/data/genomes/human/hg38/snp/common',
  active: true,
  custom: custom,
  created: DateTime(2026, 1, 1),
);

Future<AdminDeleteConfirmation?> pumpDialog(
  WidgetTester tester, {
  required Snp snp,
  List<SnpUsageDto> usage = const [],
  bool needsPassword = false,
}) async {
  AdminDeleteConfirmation? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<AdminDeleteConfirmation>(
                context: context,
                builder: (_) => AdminDeleteSnpDialog(
                  snp: snp,
                  usage: usage,
                  needsPassword: needsPassword,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

ElevatedButton deleteButton(WidgetTester tester) =>
    tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Delete permanently'),
    );

void main() {
  testWidgets('the delete button stays disabled until the name is typed', (
    tester,
  ) async {
    await pumpDialog(tester, snp: snpFixture());

    expect(deleteButton(tester).onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm the name'),
      'dbSNP common',
    );
    await tester.pump();

    expect(deleteButton(tester).onPressed, isNotNull);
  });

  testWidgets('a near miss is not good enough', (tester) async {
    await pumpDialog(tester, snp: snpFixture());

    for (final attempt in ['dbsnp common', 'dbSNP', 'dbSNP  common', '']) {
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm the name'),
        attempt,
      );
      await tester.pump();
      expect(
        deleteButton(tester).onPressed,
        isNull,
        reason: '"$attempt" should not confirm "dbSNP common"',
      );
    }
  });

  testWidgets('surrounding whitespace is forgiven', (tester) async {
    await pumpDialog(tester, snp: snpFixture());
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm the name'),
      '  dbSNP common  ',
    );
    await tester.pump();
    expect(deleteButton(tester).onPressed, isNotNull);
  });

  testWidgets('the paths about to be deleted are shown', (tester) async {
    // The most useful element in the dialog: an administrator who sees a path
    // they did not expect stops.
    await pumpDialog(tester, snp: snpFixture());
    expect(
      find.textContaining('/opt/flumip/data/genomes/human/hg38/snp/common'),
      findsOneWidget,
    );
  });

  testWidgets('a global SNP says so, in as many words', (tester) async {
    await pumpDialog(tester, snp: snpFixture(custom: false));
    expect(
      find.textContaining('part of the server\'s reference data'),
      findsOneWidget,
    );
  });

  testWidgets('projects still using it are named, and block the button', (
    tester,
  ) async {
    await pumpDialog(
      tester,
      snp: snpFixture(),
      usage: [
        SnpUsageDto(projectId: 1, projectName: 'Cardio panel'),
        SnpUsageDto(projectId: 2, projectName: 'BRCA follow-up'),
      ],
    );

    expect(find.textContaining('Cardio panel'), findsOneWidget);
    expect(find.textContaining('BRCA follow-up'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm the name'),
      'dbSNP common',
    );
    await tester.pump();

    // The name alone is not enough while something depends on it.
    expect(deleteButton(tester).onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(deleteButton(tester).onPressed, isNotNull);
  });

  testWidgets('force is never passed implicitly', (tester) async {
    late AdminDeleteConfirmation? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                captured = await showDialog<AdminDeleteConfirmation>(
                  context: context,
                  builder: (_) => AdminDeleteSnpDialog(
                    snp: snpFixture(),
                    usage: const [],
                    needsPassword: false,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm the name'),
      'dbSNP common',
    );
    await tester.pump();
    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.force, isFalse);
    expect(captured!.settingsPassword, isNull);
  });

  testWidgets('a signed-in admin is never asked for a password', (
    tester,
  ) async {
    await pumpDialog(tester, snp: snpFixture(), needsPassword: false);
    expect(find.widgetWithText(TextField, 'Settings password'), findsNothing);
  });

  testWidgets('on a no-auth install the password is required', (tester) async {
    await pumpDialog(tester, snp: snpFixture(), needsPassword: true);

    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm the name'),
      'dbSNP common',
    );
    await tester.pump();
    expect(
      deleteButton(tester).onPressed,
      isNull,
      reason: 'the name alone must not be enough without the password',
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Settings password'),
      'changeme',
    );
    await tester.pump();
    expect(deleteButton(tester).onPressed, isNotNull);
  });

  testWidgets('cancelling returns nothing', (tester) async {
    final result = await pumpDialog(tester, snp: snpFixture());
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
