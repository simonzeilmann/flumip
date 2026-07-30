import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/api_config.dart';
import 'package:flumip_flutter/auth/auth_controller.dart';
import 'package:flumip_flutter/auth/session_auth_key_provider.dart';
import 'package:flumip_flutter/project/projects_tab.dart';
import 'package:flumip_flutter/settings/settings_tab.dart';
import 'package:flumip_flutter/genome/genome_tab.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;

const String siteTitle = String.fromEnvironment(
  'SITE_TITLE',
  defaultValue: 'Flumip Development',
);

final String apiUrl = resolveApiUrl();

/// Origin the app was served from, which is also the web server's — so it is
/// where the `/auth/*` routes and the session cookie live. See `api_config.dart`.
final String siteUrl = resolveSiteUrl();

const String appVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: 'debug',
);

var client = Client(apiUrl)..connectivityMonitor = FlutterConnectivityMonitor();

/// Sign-in state for the whole app.
///
/// Sign-in and sign-out are full-page navigations rather than popups: the session
/// cookie has to be set in the browsing context the app itself runs in, and the
/// redirect chain finishes by loading the app again.
final authController = AuthController.forApp(
  client: client,
  siteUrl: siteUrl,
  navigate: (url) => web.window.location.href = url,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Asks the server whether it wants a sign-in, and picks up an existing session
  // if there is one. On a default install this answers "no" and the app runs
  // exactly as it always has, with no Authorization header on any request.
  //
  // bootstrap() never throws, so a server that cannot answer still yields a
  // usable app rather than a blank screen.
  await authController.bootstrap();
  client.authKeyProvider = authController.authKeyProvider;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: siteTitle,
      theme: ThemeData(primarySwatch: Colors.blue),
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

/// Who is signed in, and the way out.
class _SignedInMenu extends StatelessWidget {
  const _SignedInMenu({required this.user});

  final SessionTokenResponse user;

  @override
  Widget build(BuildContext context) {
    final name = user.displayName.isEmpty ? user.email : user.displayName;
    return Row(
      children: [
        Tooltip(
          message: user.isAdmin ? '${user.email} (administrator)' : user.email,
          child: Text(name),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sign out',
          onPressed: () => authController.signOut(siteUrl),
        ),
      ],
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
          // Only present when someone is actually signed in, so the default
          // install shows an unchanged app bar.
          actions: [
            if (authController.state == AuthState.signedIn)
              _SignedInMenu(user: authController.user!),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Projects', icon: Icon(Icons.folder)),
              Tab(text: 'Genomes & SNP', icon: Icon(Icons.dns)),
              Tab(text: 'Settings', icon: Icon(Icons.settings)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [ProjectsTab(), GenomeTab(), SettingsTab()],
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
