import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/snp/snp_tile.dart';
import 'package:flumip_flutter/snp/snp_upload_controller.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Snp snpFixture({
  String name = 'dbSNP common',
  bool custom = false,
  bool private = false,
  SnpImportStatus status = SnpImportStatus.ready,
  String statusMessage = '',
  int size = 1500000000,
  int bytesDownloaded = 0,
  int totalBytes = 0,
}) => Snp(
  id: 42,
  name: name,
  vcfPath: '/opt/flumip/data/custom_snp/user/42/set.vcf.gz',
  tbiPath: '/opt/flumip/data/custom_snp/user/42/set.vcf.gz.tbi',
  folder: '/opt/flumip/data/custom_snp/user/42',
  active: true,
  custom: custom,
  private: private,
  status: status,
  statusMessage: statusMessage,
  size: size,
  bytesDownloaded: bytesDownloaded,
  totalBytes: totalBytes,
  created: DateTime(2026, 1, 1),
);

Future<void> pumpTile(
  WidgetTester tester, {
  required Snp snp,
  bool isMine = false,
  bool isAdmin = false,
  UploadJob? upload,
  void Function(SnpAction)? onAction,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: SizedBox(
          width: 500,
          child: SnpTile(
            snp: snp,
            isMine: isMine,
            isAdmin: isAdmin,
            upload: upload,
            onCancelUpload: () {},
            onAction: onAction ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('the overflow menu', () {
    testWidgets('an admin on a global set gets one item and no stray divider', (
      tester,
    ) async {
      // ⚠️ The bug: the divider was gated on `isAdmin` alone, but for a global
      // set `_mayEdit` is false, so every item above it was skipped and the menu
      // rendered as a bare divider followed by a single item.
      await pumpTile(tester, snp: snpFixture(custom: false), isAdmin: true);

      await tester.tap(find.byType(PopupMenuButton<SnpAction>));
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuDivider), findsNothing);
      expect(find.text('Delete as administrator…'), findsOneWidget);
      expect(find.text('Delete…'), findsNothing);
      expect(find.text('Rename…'), findsNothing);
    });

    testWidgets('an admin on a custom set gets both groups, separated', (
      tester,
    ) async {
      await pumpTile(
        tester,
        snp: snpFixture(custom: true),
        isAdmin: true,
        isMine: true,
      );

      await tester.tap(find.byType(PopupMenuButton<SnpAction>));
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuDivider), findsOneWidget);
      expect(find.text('Rename…'), findsOneWidget);
      expect(find.text('Delete…'), findsOneWidget);
      expect(find.text('Delete as administrator…'), findsOneWidget);
    });

    testWidgets('retry is offered only on a failed set', (tester) async {
      await pumpTile(
        tester,
        snp: snpFixture(custom: true, status: SnpImportStatus.ready),
        isMine: true,
      );
      await tester.tap(find.byType(PopupMenuButton<SnpAction>));
      await tester.pumpAndSettle();
      expect(find.text('Retry import'), findsNothing);
    });
  });

  group('the chips say who may see it', () {
    testWidgets('a global set is labelled Global', (tester) async {
      await pumpTile(tester, snp: snpFixture());
      expect(find.text('Global'), findsOneWidget);
    });

    testWidgets('my private set', (tester) async {
      await pumpTile(
        tester,
        snp: snpFixture(custom: true, private: true),
        isMine: true,
      );
      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Private'), findsOneWidget);
    });

    testWidgets('my shared set', (tester) async {
      await pumpTile(
        tester,
        snp: snpFixture(custom: true, private: false),
        isMine: true,
      );
      expect(find.text('Shared'), findsOneWidget);
    });

    testWidgets("someone else's shared set says so briefly", (tester) async {
      // Was 'Shared by someone else', which wrapped onto a second line in a
      // narrow tile and pushed the status chip down with it.
      await pumpTile(
        tester,
        snp: snpFixture(custom: true, private: false),
        isMine: false,
      );
      expect(find.text('Shared with you'), findsOneWidget);
      expect(find.text('Shared by someone else'), findsNothing);
    });

    testWidgets('a status chip is present even on a global set', (
      tester,
    ) async {
      // The reconcile pass can mark a global set failed; hiding the chip on
      // globals would hide that.
      await pumpTile(
        tester,
        snp: snpFixture(custom: false, status: SnpImportStatus.failed),
      );
      expect(find.text('Failed'), findsOneWidget);
    });
  });

  group('a failed import', () {
    testWidgets('shows its message in full and selectable', (tester) async {
      await pumpTile(
        tester,
        snp: snpFixture(
          custom: true,
          status: SnpImportStatus.failed,
          statusMessage: 'This is a plain gzip file. tabix needs bgzip.',
        ),
        isMine: true,
      );

      expect(
        find.widgetWithText(
          SelectableText,
          'This is a plain gzip file. tabix needs bgzip.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('offers no retry to someone who may not edit it', (
      tester,
    ) async {
      await pumpTile(
        tester,
        snp: snpFixture(custom: true, status: SnpImportStatus.failed),
        isMine: false,
      );
      expect(find.text('Retry'), findsNothing);
    });
  });

  testWidgets('an upload in flight wins over the row byte counts', (
    tester,
  ) async {
    // ⚠️ The invariant documented on SnpTile.upload, load-bearing and until now
    // untested: the server cannot know how far a PUT has got until it lands, so
    // the row would read zero for the whole transfer.
    await pumpTile(
      tester,
      snp: snpFixture(
        custom: true,
        status: SnpImportStatus.pending,
        bytesDownloaded: 0,
        totalBytes: 0,
      ),
      isMine: true,
      upload: UploadJob(fileLabel: 'set.vcf.gz', total: 1000000000)
        ..sent = 500000000,
    );

    expect(find.textContaining('500 MB of 1.00 GB'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
