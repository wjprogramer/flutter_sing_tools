part of 'audio_graph_bloc.dart';

class AudioGraphState extends Equatable {
  const AudioGraphState({
    this.volumePoints = const [],
    this.recordDuration = const Duration(),
  });

  final List<FlSpot> volumePoints;

  final Duration recordDuration;

  @override
  List<Object> get props => [
        volumePoints,
        recordDuration,
      ];

  AudioGraphState copyWith({
    List<FlSpot>? volumePoints,
    Duration? recordDuration,
  }) {
    return AudioGraphState(
      volumePoints: volumePoints ?? this.volumePoints,
      recordDuration: recordDuration ?? this.recordDuration,
    );
  }
}
