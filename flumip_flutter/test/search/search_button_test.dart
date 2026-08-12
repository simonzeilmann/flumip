import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/projects_controller.dart';
import 'package:flumip_flutter/search/reveal.dart';
import 'package:flumip_flutter/search/search_button.dart';
import 'package:flumip_flutter/search/search_dialog.dart';
import 'package:flumip_flutter/services.dart';
import 'package:flumip_flutter/ui/layout.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'search_controller_test.dart' show Harness, hitFixture;

/// The app-bar button, and where choosing a hit sends you.
void main() {
  /// The button inside an app bar with the real tab controller above it, which is
  /// the arrangement `main.dart` builds and the one `DefaultTabController.of`
  /// depends on.
  Future<void> pumpButton(
    WidgetTester tester, {
    required Harness harness,
    void Function(SearchHitDto hit)? onOpen,
    Size size = const Size(1000, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              actions: [
                SearchButton(controller: harness.controller, onOpen: onOpen),
              ],
            ),
            body: const TabBarView(
              children: [
                Center(child: Text('projects pane')),
                Center(child: Text('genomes pane')),
                Center(child: Text('settings pane')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  group('⚠️ being discoverable without being told', () {
    // The whole reason this is a field and not just an icon: an icon in the
    // corner is found only by somebody who already suspects search exists. These
    // pin the visible affordance, which is otherwise the kind of thing that gets
    // quietly reverted to an IconButton by a later tidy-up.
    testWidgets('a wide window shows a labelled field, not a bare icon', (
      tester,
    ) async {
      await pumpButton(tester, harness: Harness());

      expect(find.textContaining('Search projects'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('the shortcut is shown, not hidden in a tooltip', (
      tester,
    ) async {
      // The only place Ctrl+K is advertised at all.
      await pumpButton(tester, harness: Harness());

      expect(find.text('Ctrl K'), findsOneWidget);
    });

    testWidgets('⚠️ the field is wide enough to read the whole hint', (
      tester,
    ) async {
      // ⚠️ The number is pinned, not derived, and it cannot be: `flutter test`
      // substitutes a font whose every glyph is a square em box, so the hint
      // measures 406px here and about 200px in Roboto. Measuring the text and
      // asserting it fits would therefore be measuring the wrong font. What is
      // checkable is the box: at 300 the hint was cut short by a word, which made
      // a field whose whole purpose is to say what it searches say two thirds of
      // it. Change this only together with the hint.
      await pumpButton(tester, harness: Harness());

      final field = tester.getRect(
        find.descendant(
          of: find.byType(SearchButton),
          matching: find.byType(Material),
        ),
      );

      expect(field.width, 360);
    });

    testWidgets('a narrow window collapses to the icon', (tester) async {
      // No room for a field beside the title, the account menu and the TabBar.
      await pumpButton(tester, harness: Harness(), size: const Size(800, 900));

      expect(find.textContaining('Search projects'), findsNothing);
      expect(find.byTooltip('Search (Ctrl+K)'), findsOneWidget);
    });
  });

  testWidgets('the field opens the dialog', (tester) async {
    await pumpButton(tester, harness: Harness());

    expect(find.byType(SearchDialog), findsNothing);

    await tester.tap(find.textContaining('Search projects'));
    await tester.pumpAndSettle();

    expect(find.byType(SearchDialog), findsOneWidget);
  });

  testWidgets('the collapsed icon opens the same dialog', (tester) async {
    await pumpButton(tester, harness: Harness(), size: const Size(800, 900));

    await tester.tap(find.byTooltip('Search (Ctrl+K)'));
    await tester.pumpAndSettle();

    expect(find.byType(SearchDialog), findsOneWidget);
  });

  testWidgets('a hit reaches onOpen from inside the dialog route', (
    tester,
  ) async {
    // Proves the callback actually crosses the route boundary: the dialog's own
    // context sits under the root Navigator, which is *above* the tab controller,
    // so the tab hook has to be captured at press time and passed down. Looking it
    // up inside the dialog throws, and this is what would catch that.
    final h = Harness(hits: [hitFixture(id: 5, name: 'BRCA panel')]);
    final opened = <SearchHitDto>[];
    await pumpButton(tester, harness: h, onOpen: opened.add);

    await tester.tap(find.textContaining('Search projects'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'brca');
    await tester.pumpAndSettle();
    await tester.tap(find.text('BRCA panel'));
    await tester.pumpAndSettle();

    expect(opened.map((h) => h.id), [5]);
  });

  /// ⚠️ The only test of the tab-index contract, which is otherwise invisible:
  /// `services.dart` names indices 0 and 1 and `main.dart`'s `TabBar` supplies the
  /// order they refer to. Nothing enforces the agreement — there is no router to
  /// ask — so inserting a tab in the middle would silently send every search result
  /// to the wrong pane, with nothing failing anywhere else.
  group('openSearchHit sends each kind to its own tab', () {
    setUp(() {
      // Both are app-wide, so they carry state between tests unless drained.
      genomeReveals.take();
      projectsController = ProjectsController(
        loadProjects: () async => const [],
        deleteProject: (_) async {},
        setOwner: (_, _) async {},
        loadNotificationsAvailable: () async => false,
        loadAssignableOwners: () async => const [],
        isAdmin: () => false,
      );
    });

    test('a project goes to the projects tab, and is asked to open', () {
      final moves = <int>[];

      openSearchHit(hitFixture(kind: SearchHitKind.project, id: 3), moves.add);

      expect(moves, [projectsTabIndex]);
      expect(projectsTabIndex, 0, reason: 'the TabBar order in main.dart');
      expect(projectsController.openProjectId, 3);
    });

    test('a genome goes to the genomes tab, and asks for the genome', () {
      final moves = <int>[];

      openSearchHit(
        hitFixture(
          kind: SearchHitKind.genome,
          id: 9,
          genomeId: 9,
          category: 'Homo sapiens',
        ),
        moves.add,
      );

      expect(moves, [genomesTabIndex]);
      expect(genomesTabIndex, 1, reason: 'the TabBar order in main.dart');
      expect(
        genomeReveals.take(),
        const GenomeReveal(genomeId: 9, category: 'Homo sapiens'),
      );
    });

    test('an SNP set goes to the genomes tab, via its genome', () {
      final moves = <int>[];

      openSearchHit(
        hitFixture(
          kind: SearchHitKind.snpSet,
          id: 44,
          genomeId: 9,
          category: 'Homo sapiens',
        ),
        moves.add,
      );

      expect(moves, [genomesTabIndex]);
      // The genome id, not the set's: opening an SNP set means opening the genome
      // that lists it.
      expect(
        genomeReveals.take(),
        const GenomeReveal(genomeId: 9, category: 'Homo sapiens'),
      );
    });

    test('an SNP set with no genome goes nowhere at all', () {
      final moves = <int>[];

      openSearchHit(
        hitFixture(kind: SearchHitKind.snpSet, id: 44, genomeId: null),
        moves.add,
      );

      expect(moves, isEmpty);
      expect(genomeReveals.hasPending, isFalse);
    });
  });

  group('⚠️ it fits in the real app bar', () {
    // The tests above pump an app bar with nothing else in it. `main.dart`'s has a
    // centred title, a `TabBar` underneath, *and* a signed-in menu carrying a full
    // email address — so the field competes for width with about 250px of account
    // chrome. An overflow is a thrown exception in a test and a yellow-and-black
    // stripe across the app bar in the browser, which is the failure this catches.
    Future<void> pumpAppBar(
      WidgetTester tester,
      double width, {
      bool signedIn = true,
    }) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Flumip'),
                centerTitle: true,
                actions: [
                  const SearchButton(),
                  // ⚠️ Deliberately **not** `SignedInMenu`, which caps its label
                  // and drops it below the breakpoint. This is an unconstrained
                  // address, i.e. more account chrome than the real bar can ever
                  // show — so the field is measured against a worse neighbour
                  // than it has, and a change to `SignedInMenu` cannot quietly
                  // relax this bound.
                  if (signedIn)
                    Row(
                      children: [
                        const Text('simon.zeilmann@it-gmbh.de'),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: () {},
                        ),
                      ],
                    ),
                ],
                bottom: const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  tabs: [
                    Tab(text: 'Projects', icon: Icon(Icons.folder)),
                    Tab(text: 'Genomes & SNP', icon: Icon(Icons.dns)),
                    Tab(text: 'Settings', icon: Icon(Icons.settings)),
                  ],
                ),
              ),
              body: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('⚠️ at the breakpoint, with a signed-in user', (tester) async {
      // The case that caught the first attempt: a fixed 300px field overflowed
      // this exact arrangement by 12px. It now shrinks instead.
      await pumpAppBar(tester, kSplitWidth);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Search projects'), findsOneWidget);
    });

    testWidgets('just below the breakpoint it is the icon, still no overflow', (
      tester,
    ) async {
      await pumpAppBar(tester, kSplitWidth - 1);

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Search (Ctrl+K)'), findsOneWidget);
    });

    testWidgets('on a phone-width window, signed out', (tester) async {
      // ⚠️ Signed *out*, and the distinction is not laziness: the signed-in half
      // of this bar is the unconstrained `Row` above, which overflows at 375px
      // with **no search button at all** — measured at 29px. That is the shape
      // `SignedInMenu` used to have, and `test/auth/signed_in_menu_test.dart`
      // covers the real widget at this width. Asserting no overflow here would be
      // asserting a property of the stand-in, not of anything shipped.
      await pumpAppBar(tester, 375, signedIn: false);

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Search (Ctrl+K)'), findsOneWidget);
    });

    testWidgets('on a wide monitor', (tester) async {
      await pumpAppBar(tester, 2560);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Search projects'), findsOneWidget);
    });

    testWidgets('⚠️ it does not sit flush against the window edge', (
      tester,
    ) async {
      // Material defaults `AppBar.actionsPadding` to `EdgeInsets.zero`, so the
      // last action ends exactly at the window edge. An `IconButton` gets away
      // with it — most of its box is splash radius — but this field has a visible
      // border, and a border touching the edge reads as clipped. The theme sets
      // the padding; this is the assertion that it is still set, because the
      // symptom is cosmetic and nothing else here would fail.
      await pumpAppBar(tester, 1400, signedIn: false);

      final field = tester.getRect(
        find.descendant(
          of: find.byType(SearchButton),
          matching: find.byType(Material),
        ),
      );

      expect(1400 - field.right, greaterThanOrEqualTo(12));
    });
  });
}
