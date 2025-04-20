part of 'audio_recorder_bloc.dart';

class AudioRecorderState extends Equatable {
  const AudioRecorderState({
    this.recordState = RecordState.stop,
  });

  final RecordState recordState;

  @override
  List<Object?> get props => [
        recordState,
      ];

  // copy with
  AudioRecorderState copyWith({
    RecordState? recordState,
  }) {
    return AudioRecorderState(
      recordState: recordState ?? this.recordState,
    );
  }
}
