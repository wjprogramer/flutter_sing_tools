import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:buffered_list_stream/buffered_list_stream.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitchupdart/pitch_handler.dart';
import 'package:pitchupdart/pitch_result.dart';
import 'package:pitchupdart/tuning_status.dart';
import 'package:record/record.dart';

part 'pitch_event.dart';
part 'pitch_state.dart';

/// 音高
class PitchBloc extends Bloc<PitchEvent, PitchState> {
  PitchBloc(this._audioRecorder, this._pitchDetectorDart, this._pitchupDart) : super(PitchState.empty()) {
    _init();

    on<PitchEvent>((event, emit) => switch (event) {
      PitchUpdate() => _onUpdate(event, emit),
    });
  }

  final AudioRecorder _audioRecorder;
  VoidCallback? _disposer;

  final PitchDetector _pitchDetectorDart;
  final PitchHandler _pitchupDart;

  void _init() async {
    final recordStream = await _audioRecorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      numChannels: 1,
      bitRate: 128000,
      sampleRate: PitchDetector.DEFAULT_SAMPLE_RATE,
    ));

    var audioSampleBufferedStream = bufferedListStream(
      recordStream.map((event) {
        return event.toList();
      }),
      // The library converts a PCM16 to 8bits internally. So we need twice as many bytes
      PitchDetector.DEFAULT_BUFFER_SIZE * 2,
    );

    final audioSampleBufferedStreamSubscription = audioSampleBufferedStream.listen((audioSample) {
      final intBuffer = Uint8List.fromList(audioSample);

      _pitchDetectorDart.getPitchFromIntBuffer(intBuffer).then((detectedPitch) {
        if (detectedPitch.pitched) {
          _pitchupDart.handlePitch(detectedPitch.pitch).then((pitchResult) {
            return add(PitchUpdate(pitchResult));
          });
        }
      });
    });

    _disposer = () {
      audioSampleBufferedStreamSubscription.cancel();
    };
  }

  @override
  Future<void> close() {
    _disposer?.call();
    return super.close();
  }

  void _onUpdate(PitchUpdate event, Emitter<PitchState> emit) {
    emit(state.copyWith(
      value: event.result,
      note: event.result.note,
      status: event.result.tuningStatus.getDescription(),
    ));
  }
}

extension Description on TuningStatus {
  String getDescription() => switch (this) {
    TuningStatus.tuned => "Tuned",
    TuningStatus.toolow => "Too low. Tighten the string",
    TuningStatus.toohigh => "Too hig. Give it some slack",
    TuningStatus.waytoolow => "Way too low. Tighten the string",
    TuningStatus.waytoohigh => "Way to high. Give it some slack",
    TuningStatus.undefined => "Note is not in the valid interval.",
  };
}
