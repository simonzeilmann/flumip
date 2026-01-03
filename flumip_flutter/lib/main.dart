import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/projects_tab.dart';
import 'package:flumip_flutter/settings/settings_tab.dart';
import 'package:flumip_flutter/genome/genome_tab.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const String siteTitle = String.fromEnvironment(
  'SITE_TITLE',
  defaultValue: 'Flumip Development',
);

const String apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8080/',
);

const String appVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: 'debug',
);

var client = Client(apiUrl)
  ..connectivityMonitor = FlutterConnectivityMonitor();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: siteTitle,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(title: 'Flumip'),
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
