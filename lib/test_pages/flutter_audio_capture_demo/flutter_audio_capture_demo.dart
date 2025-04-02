// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_audio_capture/flutter_audio_capture.dart';
//
// class AudioCaptureDemoPage extends StatefulWidget {
//   const AudioCaptureDemoPage({super.key});
//
//   @override
//   State<AudioCaptureDemoPage> createState() => _AudioCaptureDemoPageState();
// }
//
// class _AudioCaptureDemoPageState extends State<AudioCaptureDemoPage> {
//   final FlutterAudioCapture _plugin = FlutterAudioCapture();
//
//   @override
//   void initState() {
//     super.initState();
//     // Need to initialize before use note that this is async!
//     _plugin.init();
//   }
//
//   Future<void> _startCapture() async {
//     await _plugin.start(listener, onError, sampleRate: 16000, bufferSize: 3000);
//   }
//
//   Future<void> _stopCapture() async {
//     await _plugin.stop();
//   }
//
//   void listener(dynamic obj) {
//     print(obj);
//   }
//
//   void onError(Object e) {
//     print(e);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Flutter Audio Capture Plugin'),
//         ),
//         body: Column(children: [
//           Expanded(
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Center(
//                     child: FloatingActionButton(
//                       onPressed: _startCapture,
//                       child: const Text("Start"),
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: Center(
//                     child: FloatingActionButton(
//                       onPressed: _stopCapture,
//                       child: const Text("Stop"),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ]),
//       ),
//     );
//   }
// }
