import 'dart:async';
import 'dart:js_interop';

import 'package:flumip_flutter/auth/auth_controller.dart';
import 'package:flumip_flutter/auth/signed_in_menu.dart';
import 'package:flumip_flutter/genome/genome_tab.dart';
import 'package:flumip_flutter/project/projects_tab.dart';
import 'package:flumip_flutter/search/search_button.dart';
import 'package:flumip_flutter/services.dart';
import 'package:flumip_flutter/snp/file_picker.dart';
import 'package:flumip_flutter/settings/settings_tab.dart';
import 'package:flumip_flutter/snp/web_snp_transport.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;

/// ⚠️ **The browser-only end of the app, and the only file that may be.**
///
/// `dart:js_interop` and `package:web` exist when compiling to JavaScript or
/// Wasm and nowhere else, so importing this file from a VM test is a
/// *compile-time* error — not a runtime one, and not something a fake or a
/// guard can work around:
///
///     lib/main.dart:2:8: Error: Dart library 'dart:js_interop' is not
///     available on this platform.
///
/// Everything the rest of the app needs from here therefore lives in
/// `services.dart`, which stays free of both. This file is the entry point plus
/// the three lines of wiring that genuinely need a window.
///
/// ⚠️ **Nothing under `lib/` may import `main.dart`.** Seven files used to —
/// every tab among them — which is why no tab could be tested.
const String siteTitle = String.fromEnvironment(
  'SITE_TITLE',
  defaultValue: 'Flumip Development',
);

const String appVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: 'debug',
);

/// Asks the browser to confirm before the page goes away.
///
/// Returning a string is the old contract and still what triggers the prompt;
/// browsers show their own wording rather than this text.
String _warnBeforeUnload(web.BeforeUnloadEvent event) {
  event.preventDefault();
  return 'An upload is still in progress.';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Everything that needs a browser, handed to the rest of the app as plain
  // callbacks. This is the whole of what `services.dart` cannot do for itself.
  installServices(
    navigate: (url) => web.window.location.href = url,
    openUrl: (url) => web.window.open(url, '_blank'),
    filePicker: pickFileFromBrowser,
    snpTransport: WebSnpTransport(siteUrl: siteUrl),
  );

  // Asks the server whether it wants a sign-in, and picks up an existing session
  // if there is one. On a default install this answers "no" and the app runs
  // exactly as it always has, with no Authorization header on any request.
  //
  // bootstrap() never throws, so a server that cannot answer still yields a
  // usable app rather than a blank screen.
  await authController.bootstrap();
  client.authKeyProvider = authController.authKeyProvider;

  // After the bearer is installed, so the first answer describes the real caller
  // rather than an anonymous one. Not awaited: it never throws, and the app must
  // not wait on it to draw.
  unawaited(accessController.reload());

  // ⚠️ Warn before leaving with an upload in flight. Closing the tab aborts the
  // transfer and leaves a `pending` row behind: the partial file in `.incoming/`
  // is swept after a day, and the row itself is failed by the next reconcile
  // pass once nothing has been written to it for half an hour. Recoverable
  // either way, but the set has to be uploaded again, so it is worth asking.
  snpUploads.addListener(() {
    web.window.onbeforeunload = snpUploads.anyLive
        ? _warnBeforeUnload.toJS
        : null;
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: siteTitle,
      theme: buildAppTheme(),
      home: const _AuthGate(child: MyHomePage(title: 'Flumip')),
    );
  }
}

/// Shows the sign-in screen instead of the app when this server requires a
/// sign-in and there is none.
///
/// On a default install [AuthState.disabled] is the answer and this widget is a
/// pass-through, so nothing about the no-authentication case changes.
class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authController,
      builder: (context, _) {
        switch (authController.state) {
          case AuthState.unknown:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthState.disabled:
          case AuthState.signedIn:
            return child;
          case AuthState.signedOut:
            return _SignInScreen(
              label: authController.buttonLabel,
              onSignIn: () => authController.signIn(siteUrl),
            );
        }
      },
    );
  }
}

class _SignInScreen extends StatelessWidget {
  const _SignInScreen({required this.label, required this.onSignIn});

  final String label;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(siteTitle), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 20,
          children: [
            const Icon(Icons.lock_outline, size: 64),
            Text(
              'This FLUMIP server requires you to sign in.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ElevatedButton.icon(
              onPressed: onSignIn,
              icon: const Icon(Icons.login),
              label: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  Future<String> _appVersion() async {
    // Dart define is available at compile time, so just return it
    return appVersion;
  }

  // Helper to launch the GitHub URL. Uses url_launcher package.
  Future<void> _launchGitHub() async {
    const url = 'https://github.com/simonzeilmann/flumip';
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // If the platform cannot open the URL, optionally show a snackbar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open GitHub link')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
          actions: [
            // The only entry point that reaches all three kinds of thing, so it
            // sits in the one place visible from every tab.
            const SearchButton(),
            // Only present when someone is actually signed in, so the default
            // install shows an unchanged app bar.
            if (authController.state == AuthState.signedIn)
              SignedInMenu(
                user: authController.user!,
                onSignOut: () => authController.signOut(siteUrl),
              ),
          ],
          // Scrollable + centred so the three tabs sit at their natural width
          // in the middle. Stretched across a full-width app bar they end up
          // hundreds of pixels apart, and the selected tab's highlight covers a
          // third of the screen.
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
        // Ctrl+K, and Cmd+K for the Macs. Bound here rather than on the button
        // because a shortcut has to be an ancestor of whatever holds focus.
        //
        // ⚠️ The `Focus(autofocus: true)` is load-bearing: key events travel up
        // from the focused node, so with nothing in the app focused they would go
        // to the root scope — which is *above* this widget — and the binding would
        // never fire. Taking focus here puts this subtree in the chain, and it
        // stays in the chain once the user clicks into a field further down.
        body: Builder(
          // A context under the DefaultTabController, which is what the dialog's
          // own context is not. See `SearchButton.open`.
          builder: (context) => CallbackShortcuts(
            bindings: {
              const SingleActivator(
                LogicalKeyboardKey.keyK,
                control: true,
              ): () =>
                  const SearchButton().open(context),
              const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
                  const SearchButton().open(context),
            },
            child: const Focus(
              autofocus: true,
              // ⚠️ `SelectionArea` wraps the whole app body, because in a Flutter
              // web build ordinary `Text` cannot be selected at all — which for
              // an app full of gene names, file paths and genome coordinates is
              // the wrong default. Fields and buttons keep their own behaviour;
              // this only makes static text selectable.
              child: SelectionArea(
                child: TabBarView(
                  children: [ProjectsTab(), GenomeTab(), SettingsTab()],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SizedBox(
          height: 52,
          child: BottomAppBar(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              child: Row(
                children: [
                  // Fill remaining space so version stays at bottom-right
                  const Spacer(),
                  // Clickable GitHub link
                  InkWell(
                    onTap: _launchGitHub,
                    child: Semantics(
                      button: true,
                      label: 'Open project on GitHub',
                      child: Text(
                        'Github: https://github.com/simonzeilmann/flumip',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FutureBuilder<String>(
                    future: _appVersion(),
                    builder: (context, snapshot) {
                      final version = snapshot.data ?? '';
                      return Text(
                        version.isNotEmpty ? 'v: $version' : '',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
