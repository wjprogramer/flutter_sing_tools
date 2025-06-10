part of 'audio_graph_bloc.dart';

sealed class AudioGraphEvent extends Equatable {
  const AudioGraphEvent();
}

class AudioGraphUpdate extends AudioGraphEvent {
  const AudioGraphUpdate({
    this.volumePoints,
    this.pitchPoints,
    this.recordDurationInMilliseconds,
    this.recordDuration,
  });

  final List<FlSpot>? volumePoints;

  final List<FlSpot>? pitchPoints;

  final int? recordDurationInMilliseconds;

  final Duration? recordDuration;

  @override
  List<Object?> get props => [
        volumePoints,
        pitchPoints,
        recordDurationInMilliseconds,
        recordDuration,
      ];
}

class AudioGraphStartRecording extends AudioGraphEvent {
  const AudioGraphStartRecording({
    this.getLatestVolume,
    this.getLatestPitchState,
  });

  final double Function()? getLatestVolume;

  final PitchState Function()? getLatestPitchState;

  @override
  List<Object?> get props => [
        getLatestVolume,
        getLatestPitchState,
      ];
}

class AudioGraphPause extends AudioGraphEvent {
  const AudioGraphPause();

  @override
  List<Object> get props => [];
}

class AudioGraphStop extends AudioGraphEvent {
  const AudioGraphStop();

  @override
  List<Object> get props => [];
}

class AudioGraphClear extends AudioGraphEvent {
  const AudioGraphClear();

  @override
  List<Object> get props => [];
}
