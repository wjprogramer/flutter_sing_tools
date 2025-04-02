import 'package:flutter/material.dart';
import 'package:flutter_sing_tools/pages/monitor_playback_page.dart';
import 'package:flutter_sing_tools/pages/recorder_page.dart';

import 'widgets/widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Singer'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MyTitle('重播'),
          MyButton(
            text: '錄音',
            page: RecorderPage(),
          ),
          MyButton(
            text: '即時重播',
            page: MonitorPlaybackPage(),
          ),
        ],
      ),
    );
  }
}
