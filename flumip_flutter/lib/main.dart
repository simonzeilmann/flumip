import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/projects_tab.dart';
import 'package:flumip_flutter/settings/settings_tab.dart';
import 'package:flumip_flutter/genome/genome_tab.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

var client = Client('http://$localhost:8080/')
  ..connectivityMonitor = FlutterConnectivityMonitor();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flumip Development',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
              Tab(text: 'Genomes & SNP', icon: Icon(Icons.dns),),
              Tab(text: 'Settings', icon: Icon(Icons.settings),),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ProjectsTab(),
            GenomeTab(),
            SettingsTab(),
          ],
        ),
      ),
    );
  }
}
