part of 'audio_recorder_bloc.dart';

sealed class AudioRecorderEvent extends Equatable {
  const AudioRecorderEvent();
}

class AudioRecorderUpdate extends AudioRecorderEvent {
  const AudioRecorderUpdate({
    this.recordState,
  });

  final RecordState? recordState;

  @override
  List<Object?> get props => [
        recordState,
      ];
}

class AudioRecorderStart extends AudioRecorderEvent {
  const AudioRecorderStart({
    required this.onPreStart,
  });

  final Future<void> Function(RecordConfig config) onPreStart;

  @override
  List<Object?> get props => [];
}

class AudioRecorderPause extends AudioRecorderEvent {
  const AudioRecorderPause();

  @override
  List<Object?> get props => [];
}

class AudioRecorderResume extends AudioRecorderEvent {
  const AudioRecorderResume();

  @override
  List<Object?> get props => [];
}

class AudioRecorderStop extends AudioRecorderEvent {
  const AudioRecorderStop({
    this.onStop,
  });

  final void Function(String path)? onStop;

  @override
  List<Object?> get props => [];
}

