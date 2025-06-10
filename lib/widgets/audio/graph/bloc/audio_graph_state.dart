part of 'audio_graph_bloc.dart';

class AudioGraphState extends Equatable {
  const AudioGraphState({
    this.volumePoints = const [],
    this.pitchPoints = const [],
    this.recordDuration = const Duration(),
  });

  final List<FlSpot> volumePoints;

  final List<FlSpot> pitchPoints;

  final Duration recordDuration;

  @override
  List<Object> get props => [
        volumePoints,
        pitchPoints,
        recordDuration,
      ];

  AudioGraphState copyWith({
    List<FlSpot>? volumePoints,
    List<FlSpot>? pitchPoints,
    Duration? recordDuration,
  }) {
    return AudioGraphState(
      volumePoints: volumePoints ?? this.volumePoints,
      pitchPoints: pitchPoints ?? this.pitchPoints,
      recordDuration: recordDuration ?? this.recordDuration,
    );
  }
}
