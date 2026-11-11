import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/snp/add_custom_snp_dialog.dart';
import 'package:flumip_flutter/snp/picked_file.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The add dialog as a guest on a public instance sees it: upload only, small
/// files only, never shared.
void main() {
  final genome = Genome(
    id: 3,
    name: 'hg38',
    description: '',
    category: 'Homo sapiens',
    path: '/opt/flumip/data/genomes/human/hg38',
    size: 3_100_000_000,
    indexed: true,
    indexing: false,
    active: true,
  );

  const limits = GuestSnpLimits(
    maxBytes: 10 * 1024 * 1024,
    retention: Duration(days: 7),
  );

  Future<void> pumpDialog(WidgetTester tester, PickedFile vcf) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: AddCustomSnpDialog(
            genome: genome,
            uploadAvailable: true,
            pickFile: ({required accept}) async => vcf,
            guestLimits: limits,
          ),
        ),
      ),
    );
  }

  Finder addButton() => find.widgetWithText(ElevatedButton, 'Add');

  testWidgets('offers only an upload, and no sharing', (tester) async {
    await pumpDialog(
      tester,
      const PickedFile(name: 'panel.vcf.gz', size: 2000, handle: Object()),
    );

    expect(find.text('Fetch from a URL'), findsNothing);
    expect(find.text('Choose the .vcf.gz file'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.textContaining('deleted automatically after 7 days'), findsOne);
  });

  testWidgets('a small file can be added', (tester) async {
    await pumpDialog(
      tester,
      const PickedFile(name: 'panel.vcf.gz', size: 2000, handle: Object()),
    );
    await tester.enterText(find.byType(TextField).first, 'my panel');
    await tester.tap(find.text('Choose the .vcf.gz file'));
    await tester.pumpAndSettle();

    expect(tester.widget<ElevatedButton>(addButton()).onPressed, isNotNull);
    // Small is expected here, so no "did you pick the index?" warning.
    expect(find.textContaining('looks small'), findsNothing);
  });

  testWidgets('a file over the limit is refused before it is sent', (
    tester,
  ) async {
    await pumpDialog(
      tester,
      const PickedFile(
        name: 'genome-wide.vcf.gz',
        size: 11 * 1024 * 1024,
        handle: Object(),
      ),
    );
    await tester.enterText(find.byType(TextField).first, 'too big');
    await tester.tap(find.text('Choose the .vcf.gz file'));
    await tester.pumpAndSettle();

    expect(find.textContaining('this server accepts'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(addButton()).onPressed, isNull);
  });
}
