import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_sing_tools/utilities/formatter.dart';
import 'package:flutter_sing_tools/widgets/audio/graph/audio_graph.dart';

part 'audio_graph_event.dart';
part 'audio_graph_state.dart';

class AudioGraphBloc extends Bloc<AudioGraphEvent, AudioGraphState> {
  AudioGraphBloc() : super(AudioGraphState()) {
    _init();

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
  final List<FlSpot> _volumePoints = [];

  void _init() {}

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  void _onStartRecording(
      AudioGraphStartRecording event, Emitter<AudioGraphState> emit) {
    _timer?.cancel();
    _timer = Timer.periodic(_graphSampleDuration, (Timer t) {
      final volume = event.getLatestVolume?.call();
      if (volume == null) return;

      final volumePoints = state.volumePoints.toList();

      _elapsedMilliseconds += _graphSampleDuration.inMilliseconds;
      volumePoints.add(FlSpot(
        _elapsedMilliseconds / _graphSampleDuration.inMilliseconds,
        Formatter.volume0to(volume, 100)
            .clamp(0.0, AudioGraph.maxVolume)
            .toDouble(), // 確保在合法範圍
      ));
      final int skip = volumePoints.length - AudioGraph.maxGraphCount;
      if (skip > 0) {
        volumePoints.removeRange(0, skip);
      }

      add(AudioGraphUpdate(
        volumePoints: volumePoints,
        recordDuration: state.recordDuration + _graphSampleDuration,
      ));
    });
  }

  void _update(AudioGraphUpdate event, Emitter<AudioGraphState> emit) {
    emit(state.copyWith(
      volumePoints: _volumePoints,
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
