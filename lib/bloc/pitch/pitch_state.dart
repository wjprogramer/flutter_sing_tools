part of 'pitch_bloc.dart';

class PitchState extends Equatable {
  PitchState({
    PitchResult? value,
    this.note = '',
    this.status = '',
  }) : value = value ?? _emptyResult;

  final PitchResult value;
  final String note;
  final String status;

  factory PitchState.empty() {
    return PitchState(
      note: 'N/A',
      status: 'Play something',
    );
  }

  static PitchResult get _emptyResult => PitchResult(
    'N/A',
    TuningStatus.undefined,
    0,
    0,
    0,
  );

  // region PitchResult value properties
  TuningStatus get tuningStatus => value.tuningStatus;
  double get expectedFrequency => value.expectedFrequency;
  double get diffFrequency => value.diffFrequency;
  double get diffCents => value.diffCents;
  // endregion

  @override
  List<Object?> get props => [
        value,
        note,
        status,
      ];

  PitchState copyWith({
    PitchResult? value,
    String? note,
    String? status,
  }) {
    return PitchState(
      value: value ?? this.value,
      note: note ?? this.note,
      status: status ?? this.status,
    );
  }
}
