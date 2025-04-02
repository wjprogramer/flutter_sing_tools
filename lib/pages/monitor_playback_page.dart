import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sing_tools/utilities/utilities.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

/// real-time monitoring / monitoring playback
/// FIXME: 被註解的 Code，切換輸入輸出裝置會導致沒辦法繼續播放
class MonitorPlaybackPage extends StatefulWidget {
  const MonitorPlaybackPage({super.key});

  @override
  State<MonitorPlaybackPage> createState() => _MonitorPlaybackPageState();
}

class _MonitorPlaybackPageState extends State<MonitorPlaybackPage> {
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  StreamSubscription? _audioSub;
  final StreamController<Uint8List> _audioStreamController = StreamController.broadcast();

  List<Map<Object?, Object?>> inputDevices = [];
  List<Map<Object?, Object?>> outputDevices = [];
  int? selectedInputId;
  int? selectedOutputId;

  @override
  void initState() {
    super.initState();
    _loadAudioDevices();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initRecorder();
      await startRecording();
    });
  }

  Future<void> _loadAudioDevices() async {
    final inputs = await RealTimeAudioPlayer.getInputDevices();
    final outputs = await RealTimeAudioPlayer.getOutputDevices();
    setState(() {
      inputDevices = inputs;
      outputDevices = outputs;
      // selectedInputId = inputs.isNotEmpty ? (inputs.first['id'] as int) : null;
      // selectedOutputId = outputs.isNotEmpty ? (outputs.first['id'] as int) : null;
    });
  }

  Future<void> _applyDeviceSelection() async {
    // if (selectedInputId != null) {
    //   await RealTimeAudioPlayer.setInputDevice(selectedInputId!);
    // }
    // if (selectedOutputId != null) {
    //   await RealTimeAudioPlayer.setOutputDevice(selectedOutputId!);
    // }
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException("Mic permission not granted");
    }

    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(const Duration(milliseconds: 50));

    _audioSub = _audioStreamController.stream.listen((buffer) {
      RealTimeAudioPlayer.write(buffer); // ✅ 呼叫原生 Android 播放器
    });
  }

  Future<void> startRecording() async {
    await _applyDeviceSelection();
    setState(() => _isRecording = true);
    await _recorder.startRecorder(
      toStream: _audioStreamController.sink,
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
      bufferSize: 4096,
    );
  }

  Future<void> stopRecording() async {
    await _recorder.stopRecorder();
    await _audioStreamController.close();
    setState(() => _isRecording = false);
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _audioSub?.cancel();
    _recorder = FlutterSoundRecorder();
    super.dispose();
  }

  // Widget _buildDropdown(String title, List<Map<Object?, Object?>> devices, int? selectedId, void Function(int?)? onChanged) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
  //       DropdownButton<int>(
  //         value: selectedId,
  //         hint: const Text("選擇裝置"),
  //         isExpanded: true,
  //         items: devices.map((d) {
  //           return DropdownMenuItem<int>(
  //             value: d['id'] as int,
  //             child: Text("[${d['id']}] ${d['productName']} (${d['type']})"),
  //           );
  //         }).toList(),
  //         onChanged: onChanged,
  //       ),
  //     ],
  //   );
  // }
  //
  // Future<void> _onAfterChangeDevice() async {
  //   await _applyDeviceSelection();
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('即時重播')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // _buildDropdown("輸入裝置", inputDevices, selectedInputId, (val) async {
            //   selectedInputId = val;
            //   await _onAfterChangeDevice();
            // }),
            // const SizedBox(height: 12),
            // _buildDropdown("輸出裝置", outputDevices, selectedOutputId, (val) async {
            //   selectedOutputId = val;
            //   await _onAfterChangeDevice();
            // }),
            // const SizedBox(height: 24),
            Text('🎧 使用耳機是必要的，為了避免「聲音從喇叭播出 → 再被麥克風收音 → 產生回音與疊音」，建議用耳機監聽'),
            // Expanded(
            //   child: Center(
            //     child: ElevatedButton(
            //       onPressed: _isRecording ? stopRecording : startRecording,
            //       child: Text(_isRecording ? '停止錄音' : '開始錄音'),
            //     ),
            //   ),
            // ),
            Expanded(
              child: Center(
                child: Text(
                  '錄音中',
                  style: theme.textTheme.headlineLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
