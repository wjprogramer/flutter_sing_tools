import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  static Future<List<Map<Object?, Object?>>> getInputDevices() async {
    final List devices = await _channel.invokeMethod('getInputDevices');
    return List<Map<Object?, Object?>>.from(devices);
  }

  static Future<List<Map<Object?, Object?>>> getOutputDevices() async {
    final List devices = await _channel.invokeMethod('getOutputDevices');
    return List<Map<Object?, Object?>>.from(devices);
  }

  static Future<void> setInputDevice(int deviceId) async {
    try {
      await _channel.invokeMethod('setInputDevice', {'id': deviceId});
    } catch (e) {
      debugPrint("[AudioPlayer] Failed to set input device: \$e");
    }
  }

  static Future<void> setOutputDevice(int deviceId) async {
    try {
      await _channel.invokeMethod('setOutputDevice', {'id': deviceId});
    } catch (e) {
      debugPrint("[AudioPlayer] Failed to set output device: \$e");
    }
  }
}
