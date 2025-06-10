import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_sing_tools/bloc/pitch/pitch_bloc.dart';
import 'package:flutter_sing_tools/utilities/formatter.dart';
import 'package:flutter_sing_tools/widgets/audio/graph/audio_graph.dart';

part 'audio_graph_event.dart';

part 'audio_graph_state.dart';

const double _minVolume = 0.0;
const double _maxVolume = AudioGraph.maxVolume;

class AudioGraphBloc extends Bloc<AudioGraphEvent, AudioGraphState> {
  AudioGraphBloc() : super(AudioGraphState()) {
    on<AudioGraphEvent>((event, emit) => switch (event) {
          AudioGraphUpdate() => _update(event, emit),
          AudioGraphStartRecording() => _onStartRecording(event, emit),
          AudioGraphPause() => _onPause(event, emit),
          AudioGraphStop() => _onStop(event, emit),
          AudioGraphClear() => _onClear(event, emit),
        });
  }

  Timer? _timer;

  Duration get _graphSampleDuration => AudioGraph.graphSampleDuration;
  int _elapsedMilliseconds = 0;

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  void _onStartRecording(
      AudioGraphStartRecording event, Emitter<AudioGraphState> emit) {
    _timer?.cancel();
    _timer = Timer.periodic(_graphSampleDuration, (Timer t) {
      _elapsedMilliseconds += _graphSampleDuration.inMilliseconds;
      final xValue = _elapsedMilliseconds / _graphSampleDuration.inMilliseconds;

      // volume
      final volume = event.getLatestVolume?.call();
      final volumePoints = state.volumePoints.toList();

      if (volume == null) {
        volumePoints.add(
          FlSpot(
            xValue,
            0.0,
          ),
        );
      } else {
        volumePoints.add(FlSpot(
          xValue,
          Formatter.volume0to(volume, 100)
              .clamp(_minVolume, _maxVolume)
              .toDouble(), // 確保在合法範圍
        ));
      }

      final int skip = volumePoints.length - AudioGraph.maxGraphCount;
      if (skip > 0) {
        volumePoints.removeRange(0, skip);
      }

      // pitch
      final pitchState = event.getLatestPitchState?.call();
      final pitchPoints = state.pitchPoints.toList();

      if (pitchState == null) {
        pitchPoints.add(
          FlSpot(
            xValue,
            0.0,
          ),
        );
      } else {
        pitchPoints.add(FlSpot(
          xValue,
          _normalizePitchToVolumeRange(pitchState.value.expectedFrequency),
        ));
      }

      final int pitchSkip = pitchPoints.length - AudioGraph.maxGraphCount;
      if (pitchSkip > 0) {
        pitchPoints.removeRange(0, pitchSkip);
      }

      add(AudioGraphUpdate(
        volumePoints: volumePoints,
        pitchPoints: pitchPoints,
        recordDuration: state.recordDuration + _graphSampleDuration,
      ));
    });
  }

  void _update(AudioGraphUpdate event, Emitter<AudioGraphState> emit) {
    emit(state.copyWith(
      volumePoints: event.volumePoints,
      pitchPoints: event.pitchPoints,
      recordDuration: event.recordDuration,
    ));
  }

  void _onPause(AudioGraphPause event, Emitter<AudioGraphState> emit) {
    _timer?.cancel();
  }

  void _onStop(AudioGraphStop event, Emitter<AudioGraphState> emit) {
    _timer?.cancel();
    _elapsedMilliseconds = 0;
    // _volumePoints.clear();
  }

  void _onClear(AudioGraphClear event, Emitter<AudioGraphState> emit) {
    emit(state.copyWith(
      recordDuration: const Duration(),
    ));
  }
}

/// 因為 fl_chart 不支援雙 y 軸，所以採用 workaround
double _normalizePitchToVolumeRange(double expectedFrequency) {
  const minFrequency = 100.0;
  const maxFrequency = 1000.0;
  const minVolume = _minVolume;
  const maxVolume = _maxVolume;
  final resolvedExpectedFrequency =
      expectedFrequency.clamp(minFrequency, maxFrequency);
  final normalizedFrequency = (resolvedExpectedFrequency - minFrequency) /
      (maxFrequency - minFrequency);
  return normalizedFrequency * (maxVolume - minVolume) + minVolume;
}
