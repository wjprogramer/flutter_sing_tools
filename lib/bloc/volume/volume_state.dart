part of 'volume_bloc.dart';

class VolumeState extends Equatable {
  const VolumeState({
    this.amplitude,
    this.volume = 0,
  });

  final Amplitude? amplitude;

  final double volume;

  @override
  List<Object?> get props => [
        amplitude,
        volume,
      ];

  VolumeState copyWith({
    Amplitude? amplitude,
    double? volume,
  }) {
    return VolumeState(
      amplitude: amplitude ?? this.amplitude,
      volume: volume ?? this.volume,
    );
  }
}
