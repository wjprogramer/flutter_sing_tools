part of 'pitch_bloc.dart';

sealed class PitchEvent extends Equatable {
  const PitchEvent();
}

class PitchUpdate extends PitchEvent {
  const PitchUpdate(this.result);

  final PitchResult result;

  @override
  List<Object?> get props => [result];
}

class PitchStart extends PitchEvent {
  const PitchStart(this.audioSampleBufferedStream);

  final Stream<List<int>> audioSampleBufferedStream;

  @override
  List<Object?> get props => [audioSampleBufferedStream];
}

