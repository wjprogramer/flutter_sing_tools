part of 'audio_graph_bloc.dart';

class AudioGraphState extends Equatable {
  const AudioGraphState({
    this.volumePoints = const [],
    this.recordDurationInMilliseconds = 0,
    this.recordDuration = const Duration(),
  });

  final List<FlSpot> volumePoints;

  final int recordDurationInMilliseconds;

  final Duration recordDuration;

  @override
  List<Object> get props => [
        volumePoints,
        recordDurationInMilliseconds,
        recordDuration,
      ];

  AudioGraphState copyWith({
    List<FlSpot>? volumePoints,
    int? recordDurationInMilliseconds,
    Duration? recordDuration,
  }) {
    return AudioGraphState(
      volumePoints: volumePoints ?? this.volumePoints,
      recordDurationInMilliseconds:
          recordDurationInMilliseconds ?? this.recordDurationInMilliseconds,
      recordDuration: recordDuration ?? this.recordDuration,
    );
  }
}
