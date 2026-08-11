import 'dart:io';

import 'package:flumip_flutter/genome/genome_tab.dart';
import 'package:flumip_flutter/project/project_tile.dart';
import 'package:flumip_flutter/project/projects_tab.dart';
import 'package:flumip_flutter/settings/settings_tab.dart';
import 'package:flumip_flutter/snp/add_custom_snp_dialog.dart';
import 'package:flumip_flutter/snp/snp_section.dart';
import 'package:flutter_test/flutter_test.dart';

/// The boundary between the app and the browser, held in place.
///
/// ⚠️ `dart:js_interop` and `package:web` exist only when compiling to
/// JavaScript or Wasm. `flutter test` compiles for the Dart VM, where importing
/// either is a **compile-time** error:
///
///     lib/main.dart:2:8: Error: Dart library 'dart:js_interop' is not
///     available on this platform.
///
/// It is a compile error, not a runtime one, so it cannot be caught, faked or
/// guarded around — one import anywhere in a file's transitive closure and no
/// test can so much as name a symbol from it. That is why every tab was
/// untestable: seven files imported `main.dart` for `client` and `siteUrl`, and
/// `main.dart` imports both libraries.
///
/// This file is two guards. The first is the compile itself — the imports above
/// are the assertion, and if a web-only import creeps back into the widget tree
/// this file stops building. The second is the grep below, which says the same
/// thing with a better error message.
void main() {
  /// The only three files allowed to name a browser API.
  ///
  /// `main.dart` is the entry point and installs the callbacks; the other two
  /// are the implementations it installs. Nothing else may, and nothing may
  /// import these three.
  const webOnly = {
    'lib/main.dart',
    'lib/snp/file_picker.dart',
    'lib/snp/web_snp_transport.dart',
  };

  List<File> libFiles() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  group('the web boundary', () {
    test(
      'only the entry point and its two implementations touch the browser',
      () {
        final offenders = <String>[];
        for (final file in libFiles()) {
          final path = file.path;
          if (webOnly.contains(path)) continue;
          final source = file.readAsStringSync();
          for (final line in source.split('\n')) {
            if (!line.startsWith('import ')) continue;
            if (line.contains('dart:js_interop') ||
                line.contains('package:web/web.dart')) {
              offenders.add('$path: ${line.trim()}');
            }
          }
        }

        expect(
          offenders,
          isEmpty,
          reason:
              'A web-only import outside ${webOnly.join(', ')} makes every file '
              'that reaches it impossible to compile for a VM test. Inject the '
              'browser call as a callback through services.dart instead — see '
              'openExternalUrl and pickFile.',
        );
      },
    );

    test('⚠️ nothing under lib/ imports main.dart', () {
      // Seven files did, which is how the browser-only imports reached every
      // tab. The app-wide singletons live in services.dart now precisely so
      // that this stays true.
      final offenders = <String>[];
      for (final file in libFiles()) {
        if (file.path == 'lib/main.dart') continue;
        for (final line in file.readAsStringSync().split('\n')) {
          if (line.startsWith('import ') && line.contains('main.dart')) {
            offenders.add('${file.path}: ${line.trim()}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'main.dart imports dart:js_interop and package:web, so importing '
            'it from anywhere under lib/ spreads that to every file downstream. '
            'Take client, siteUrl and the controllers from services.dart.',
      );
    });

    test('services.dart is the seam, and is itself clean', () {
      // ⚠️ Import lines only. services.dart *names* both libraries in its own
      // doc comment, explaining why it may not import them — a plain substring
      // search over the source fails on the very comment that documents the
      // rule, which is how this test first failed.
      final imports = File(
        'lib/services.dart',
      ).readAsLinesSync().where((line) => line.startsWith('import '));

      expect(imports, isNot(contains(contains('dart:js_interop'))));
      expect(imports, isNot(contains(contains('package:web/web.dart'))));
    });
  });

  test('every tab can be named from a VM test', () {
    // The imports at the top of this file are the real assertion — this body
    // only exists so the test is not vacuous. Before the split, this file would
    // not compile at all.
    expect(const ProjectsTab(), isA<ProjectsTab>());
    expect(const GenomeTab(), isA<GenomeTab>());
    expect(const SettingsTab(), isA<SettingsTab>());
    expect(SnpSection, isNotNull);
    expect(ProjectTile, isNotNull);
    expect(AddCustomSnpDialog, isNotNull);
  });
}
