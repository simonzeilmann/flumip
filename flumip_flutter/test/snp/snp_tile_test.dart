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
  String vcfPath = '/opt/flumip/data/custom_snp/user/42/set.vcf.gz',
  String? sourceVcfUrl,
}) => Snp(
  id: 42,
  name: name,
  vcfPath: vcfPath,
  sourceVcfUrl: sourceVcfUrl,
  tbiPath: '/opt/flumip/data/custom_snp/user/42/set.vcf.gz.tbi',
  folder: '/opt/flumip/data/custom_snp/user/42',
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
          // ⚠️ A URL import, so Retry is a real offer. It used to be an upload,
          // which asserted a Retry button that could only ever answer "There is
          // nothing to retry" — and a `vcfPath` that the server clears on its
          // way to `failed`, so the row was not one the server can produce.
          vcfPath: '',
          sourceVcfUrl: 'https://example.org/panel.vcf.gz',
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

  group('⚠️ Retry is only offered when there is something to retry', () {
    // The abandoned-upload sweep turns a slot nobody filled into a *failed* row,
    // and a failed row grew a Retry button. For an upload slot there is nothing
    // to retry with — no source URL, no bytes on disk — so the endpoint answers
    // "There is nothing to retry — upload the files again." A button whose only
    // outcome is that message is a dead end.
    testWidgets('an abandoned upload slot offers none', (tester) async {
      await pumpTile(
        tester,
        snp: snpFixture(
          custom: true,
          status: SnpImportStatus.failed,
          statusMessage: 'No files arrived. The upload was interrupted.',
          vcfPath: '',
        ),
        isMine: true,
      );

      expect(find.text('Retry'), findsNothing);

      await tester.tap(find.byType(PopupMenuButton<SnpAction>));
      await tester.pumpAndSettle();
      expect(find.text('Retry import'), findsNothing);
      expect(find.text('Delete…'), findsOneWidget);
    });

    testWidgets('a failed URL import offers it', (tester) async {
      await pumpTile(
        tester,
        snp: snpFixture(
          custom: true,
          status: SnpImportStatus.failed,
          statusMessage: 'Interrupted — the download never started.',
          vcfPath: '',
          sourceVcfUrl: 'https://example.org/panel.vcf.gz',
        ),
        isMine: true,
      );

      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('⚠️ a set with nothing in it can only be deleted', () {
    // Reported from a real interrupted upload: the menu still offered "Rename…"
    // and "Share with everyone" for a set whose directory is empty. Sharing
    // nothing is not a thing anybody wants to do, and it reads as though the
    // set is fine.
    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byType(PopupMenuButton<SnpAction>));
      // ⚠️ `pump`, not `pumpAndSettle`. A queued row carries an indeterminate
      // progress bar, and nothing settles while one is on screen — the same
      // trap as the design-progress panel.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('a failed upload offers delete alone', (tester) async {
      await pumpTile(
        tester,
        snp: snpFixture(
          custom: true,
          status: SnpImportStatus.failed,
          statusMessage: 'The upload did not finish.',
          vcfPath: '',
        ),
        isMine: true,
      );
      await openMenu(tester);

      expect(find.text('Delete…'), findsOneWidget);
      expect(find.text('Rename…'), findsNothing);
      expect(find.text('Share with everyone'), findsNothing);
      expect(find.text('Make private'), findsNothing);
      expect(find.text('Retry import'), findsNothing);
    });

    testWidgets('a queued set does not offer to share nothing either', (
      tester,
    ) async {
      await pumpTile(
        tester,
        snp: snpFixture(
          custom: true,
          status: SnpImportStatus.pending,
          vcfPath: '',
        ),
        isMine: true,
      );
      await openMenu(tester);

      expect(find.text('Cancel — no files arrived'), findsOneWidget);
      expect(find.text('Rename…'), findsNothing);
      expect(find.text('Share with everyone'), findsNothing);
    });

    testWidgets('a failed URL import still offers retry, but not sharing', (
      tester,
    ) async {
      await pumpTile(
        tester,
        snp: snpFixture(
          custom: true,
          status: SnpImportStatus.failed,
          vcfPath: '',
          sourceVcfUrl: 'https://example.org/panel.vcf.gz',
        ),
        isMine: true,
      );
      await openMenu(tester);

      expect(find.text('Retry import'), findsOneWidget);
      expect(find.text('Rename…'), findsNothing);
    });

    testWidgets('a ready set keeps the full menu', (tester) async {
      // The regression guard for the gate itself.
      await pumpTile(
        tester,
        snp: snpFixture(custom: true, private: true),
        isMine: true,
      );
      await openMenu(tester);

      expect(find.text('Rename…'), findsOneWidget);
      expect(find.text('Share with everyone'), findsOneWidget);
      expect(find.text('Delete…'), findsOneWidget);
    });
  });
}
