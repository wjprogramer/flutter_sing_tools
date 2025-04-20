part of 'pitch_bloc.dart';

class PitchState extends Equatable {
  const PitchState({
    this.note = '',
    this.status = '',
  });

  final String note;
  final String status;

  factory PitchState.empty() {
    return const PitchState(
      note: 'N/A',
      status: 'Play something',
    );
  }

  @override
  List<Object?> get props => [
        note,
        status,
      ];
}
