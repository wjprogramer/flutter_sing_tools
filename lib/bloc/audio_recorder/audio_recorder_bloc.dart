import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

part 'audio_recorder_event.dart';
part 'audio_recorder_state.dart';

/// 控制 audio_recorder
class AudioRecorderBloc extends Bloc<AudioRecorderEvent, AudioRecorderState> {
  AudioRecorderBloc(this._audioRecorder) : super(AudioRecorderState()) {
    _init();

    on<AudioRecorderEvent>((event, emit) => switch (event) {
      AudioRecorderUpdate() => _update(event, emit),
      AudioRecorderStart() => _start(event, emit),
      AudioRecorderPause() => _pause(event, emit),
      AudioRecorderResume() => _resume(event, emit),
      AudioRecorderStop() => _stop(event, emit),
    });
  }

  late final AudioRecorder _audioRecorder;
  AudioRecorder get audioRecorder => _audioRecorder;

  // recorder listeners
  StreamSubscription<RecordState>? _recordSub;

  void _init() async {
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      add(AudioRecorderUpdate(
        recordState: recordState,
      ));
    });
  }

  @override
  Future<void> close() {
    _audioRecorder.dispose();
    _recordSub?.cancel();
    return super.close();
  }

  void _update(AudioRecorderUpdate event, Emitter<AudioRecorderState> emit) {


    emit(state.copyWith(
      recordState: event.recordState,
    ));
  }

  Future<void> _start(AudioRecorderStart event, Emitter<AudioRecorderState> emit) async {
    try {
      if (await _audioRecorder.hasPermission()) {
        const encoder = AudioEncoder.aacLc;

        if (!await _isEncoderSupported(encoder)) {
          return;
        }

        final devs = await _audioRecorder.listInputDevices();
        debugPrint(devs.toString());

        const config = RecordConfig(encoder: encoder, numChannels: 1);
        await event.onPreStart(config);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _pause(AudioRecorderPause event, Emitter<AudioRecorderState> emit) async {
    await _audioRecorder.pause();
  }

  Future<void> _resume(AudioRecorderResume event, Emitter<AudioRecorderState> emit) async {
    await _audioRecorder.resume();
  }

  Future<void> _stop(AudioRecorderStop event, Emitter<AudioRecorderState> emit) async {
    final path = await _audioRecorder.stop();

    if (path != null) {
      event.onStop?.call(path);
    }
  }

  Future<bool> _isEncoderSupported(AudioEncoder encoder) async {
    final isSupported = await _audioRecorder.isEncoderSupported(
      encoder,
    );

    if (!isSupported) {
      debugPrint('${encoder.name} is not supported on this platform.');
      debugPrint('Supported encoders are:');

      for (final e in AudioEncoder.values) {
        if (await _audioRecorder.isEncoderSupported(e)) {
          debugPrint('- ${e.name}');
        }
      }
    }

    return isSupported;
  }
}
