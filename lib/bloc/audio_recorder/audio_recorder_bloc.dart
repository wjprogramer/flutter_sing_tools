import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:buffered_list_stream/buffered_list_stream.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
  Stream<List<int>>? audioSampleBufferedStream;

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

        // 原本是單純檢測音量的 config 為上面這個，下面的 config 是取自音高檢測的 sample
        // 不確定哪個比較好
        // const config = RecordConfig(encoder: encoder, numChannels: 1);
        const config = RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          numChannels: 1,
          bitRate: 128000,
          sampleRate: PitchDetector.DEFAULT_SAMPLE_RATE,
        );

        await event.onPreStart(config);

        // await recordFile(config);

        final stream = await _recordStream(config);

        audioSampleBufferedStream = bufferedListStream(
          stream.map((event) {
            return event.toList();
          }),
          // The library converts a PCM16 to 8bits internally. So we need twice as many bytes
          PitchDetector.DEFAULT_BUFFER_SIZE * 2,
        );
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

  Future<Stream<Uint8List>> _recordStream(RecordConfig config) async {
    final path = await _getPath();

    final file = File(path);

    final stream = await _audioRecorder.startStream(config);

    audioSampleBufferedStream = stream;

    stream.listen(
      (data) {
        // print(
        //   _audioRecorder.convertBytesToInt16(Uint8List.fromList(data)),
        // );
        file.writeAsBytesSync(data, mode: FileMode.append);
      },
      onDone: () {
        print('End of stream. File written to $path.');
      },
    );

    return stream;
  }

  Future<void> recordFile(RecordConfig config) async {
    final path = await _getPath();

    await _audioRecorder.start(config, path: path);
  }

  Future<String> _getPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(
      dir.path,
      'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
  }
}
