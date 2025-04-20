part of 'volume_bloc.dart';

sealed class VolumeEvent extends Equatable {
  const VolumeEvent();
}

class VolumeUpdate extends VolumeEvent {
  const VolumeUpdate({
    required this.amplitude,
  });

  final Amplitude amplitude;

  @override
  List<Object?> get props => [
        amplitude,
      ];
}
