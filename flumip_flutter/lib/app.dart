import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth/auth_controller.dart';
import 'auth/public_notice_screen.dart';
import 'auth/signed_in_menu.dart';
import 'genome/genome_tab.dart';
import 'project/projects_tab.dart';
import 'search/search_button.dart';
import 'services.dart';
import 'settings/settings_tab.dart';
import 'ui/theme.dart';

/// The app's shell: the sign-in gate, the app bar, the three tabs and the footer.
///
/// ⚠️ **Lives here rather than in `main.dart` so that it can be tested.**
/// `main.dart` imports `dart:js_interop` and `package:web`, which do not exist on
/// the Dart VM, so nothing written there can even be named from a test. Every
/// tab and the app-bar actions had already been moved out for that reason; this
/// was the last of it. `main.dart` is now only the browser wiring and `runApp`.
///
/// Each widget below takes its dependencies as optional parameters and falls
/// back to the app-wide ones in `services.dart` — the convention the tabs follow
/// too. Only a test passes them.
const String siteTitle = String.fromEnvironment(
  'SITE_TITLE',
  defaultValue: 'Flumip Development',
);

const String appVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: 'debug',
);

const String _githubUrl = 'https://github.com/simonzeilmann/flumip';

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.auth, this.home});

  /// Sign-in state, or null for the app-wide [authController].
  final AuthController? auth;

  /// What the gate lets through, or null for the real [MyHomePage].
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: siteTitle,
      scaffoldMessengerKey: messengerKey,
      theme: buildAppTheme(),
      home: AuthGate(
        auth: auth ?? authController,
        child: home ?? const MyHomePage(title: siteTitle),
      ),
    );
  }
}

/// Shows the sign-in screen instead of the app when this server requires a
/// sign-in and there is none.
///
/// On a default install [AuthState.disabled] is the answer and this widget is a
/// pass-through, so nothing about the no-authentication case changes.
///
/// On a public instance it shows the entry notice instead, until the visitor
/// accepts it.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.auth,
    required this.child,
    this.openUrl,
  });

  final AuthController auth;
  final Widget child;

  /// Opens a link in a new tab, or null for the app-wide [openExternalUrl].
  final void Function(String url)? openUrl;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        switch (auth.state) {
          case AuthState.unknown:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthState.disabled:
          case AuthState.signedIn:
            return child;
          case AuthState.signedOut:
            return _SignInScreen(
              label: auth.buttonLabel,
              onSignIn: () => auth.signIn(siteUrl),
            );
          case AuthState.needsAcceptance:
            return PublicNoticeScreen(
              auth: auth,
              onSignIn: () => auth.signIn(siteUrl),
              openUrl: openUrl ?? openExternalUrl,
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

class MyHomePage extends StatelessWidget {
  const MyHomePage({
    super.key,
    required this.title,
    this.version = appVersion,
    this.auth,
    this.tabs,
    this.openUrl,
  });

  final String title;

  /// Shown in the footer. A parameter only so a test can pin it.
  final String version;

  /// Sign-in state, or null for the app-wide [authController].
  final AuthController? auth;

  /// The three panes, in [TabBar] order, or null for the real tabs.
  ///
  /// A test passes stand-ins: the real tabs fetch through the app-wide client as
  /// soon as they are built, and this test has no server.
  final List<Widget>? tabs;

  /// Opens a link in a new tab, or null for the app-wide [openExternalUrl].
  final void Function(String url)? openUrl;

  @override
  Widget build(BuildContext context) {
    final auth = this.auth ?? authController;
    // A guest on a public instance has nothing in Settings they could change —
    // the server answers them with "no settings" — so the tab is not offered.
    // It is the last tab on purpose: dropping it moves no other index, and
    // `projectsTabIndex` / `genomesTabIndex` stay true.
    final showSettings =
        !(auth.state == AuthState.signedIn && auth.user!.isGuest);
    final views = tabs ?? const [ProjectsTab(), GenomeTab(), SettingsTab()];
    final shown = showSettings ? views : views.take(2).toList();
    return DefaultTabController(
      // Keyed on the count: a controller cannot change length in place.
      key: ValueKey(shown.length),
      length: shown.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
          actions: [
            // The only entry point that reaches all three kinds of thing, so it
            // sits in the one place visible from every tab.
            const SearchButton(),
            // Only present when someone is actually signed in, so the default
            // install shows an unchanged app bar.
            if (auth.state == AuthState.signedIn && auth.user!.isGuest)
              GuestMenu(
                onSignIn: auth.config.enabled
                    ? () => auth.signIn(siteUrl)
                    : null,
              )
            else if (auth.state == AuthState.signedIn)
              SignedInMenu(
                user: auth.user!,
                onSignOut: () => auth.signOut(siteUrl),
              ),
          ],
          // Scrollable + centred so the three tabs sit at their natural width
          // in the middle. Stretched across a full-width app bar they end up
          // hundreds of pixels apart, and the selected tab's highlight covers a
          // third of the screen.
          //
          // ⚠️ The order is a contract: `projectsTabIndex` and `genomesTabIndex`
          // in `services.dart` name these positions, and search sends its hits
          // by them. `test/app_test.dart` holds the two together.
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            tabs: [
              const Tab(text: 'Projects', icon: Icon(Icons.folder)),
              const Tab(text: 'Genomes & SNP', icon: Icon(Icons.dns)),
              if (showSettings)
                const Tab(text: 'Settings', icon: Icon(Icons.settings)),
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
            child: Focus(
              autofocus: true,
              // ⚠️ `SelectionArea` wraps the whole app body, because in a Flutter
              // web build ordinary `Text` cannot be selected at all — which for
              // an app full of gene names, file paths and genome coordinates is
              // the wrong default. Fields and buttons keep their own behaviour;
              // this only makes static text selectable.
              child: SelectionArea(child: TabBarView(children: shown)),
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
                  // A public site in Germany has to link both from every page.
                  // Empty on an internal install, where neither is set.
                  if (auth.config.imprintUrl.isNotEmpty)
                    _FooterLink(
                      label: 'Imprint',
                      onTap: () =>
                          (openUrl ?? openExternalUrl)(auth.config.imprintUrl),
                    ),
                  if (auth.config.privacyUrl.isNotEmpty)
                    _FooterLink(
                      label: 'Privacy policy',
                      onTap: () =>
                          (openUrl ?? openExternalUrl)(auth.config.privacyUrl),
                    ),
                  // Fill remaining space so version stays at bottom-right
                  const Spacer(),
                  // Clickable GitHub link
                  InkWell(
                    onTap: () => (openUrl ?? openExternalUrl)(_githubUrl),
                    child: Semantics(
                      button: true,
                      label: 'Open project on GitHub',
                      child: Text(
                        'Github: $_githubUrl',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    version.isNotEmpty ? 'v: $version' : '',
                    style: Theme.of(context).textTheme.bodySmall,
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

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(decoration: TextDecoration.underline),
        ),
      ),
    );
  }
}
