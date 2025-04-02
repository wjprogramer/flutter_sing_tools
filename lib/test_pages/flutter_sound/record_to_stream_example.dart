import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

// 模擬播放：你可以改成接 Native 播放（如透過 Platform Channel 傳 buffer）
void simulatePlayback(Uint8List buffer) {
  // ⚠️ 此處應使用 Native Plugin 播放 raw PCM buffer
  print("Simulated playback of ${buffer.length} bytes");
}

/// 播放器：呼叫原生 Android 播放 PCM buffer
class RealTimeAudioPlayer {
  static const MethodChannel _channel = MethodChannel('real_time_audio');

  static Future<void> write(Uint8List buffer) async {
    try {
      await _channel.invokeMethod('write', buffer);
    } catch (e) {
      debugPrint("[AudioPlayer] Failed to write buffer: \$e");
    }
  }
}

class RealTimePlaybackDemo extends StatefulWidget {
  const RealTimePlaybackDemo({super.key});

  @override
  State<RealTimePlaybackDemo> createState() => _RealTimePlaybackDemoState();
}

class _RealTimePlaybackDemoState extends State<RealTimePlaybackDemo> {
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  StreamSubscription? _audioSub;
  StreamController<Uint8List> _audioStreamController = StreamController.broadcast();

  @override
  void initState() {
    super.initState();
    _initRecorder();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('即時回放 demo')),
      body: Center(
        child: ElevatedButton(
          onPressed: _isRecording ? stopRecording : startRecording,
          child: Text(_isRecording ? '停止錄音' : '開始錄音'),
        ),
      ),
    );
  }
}
