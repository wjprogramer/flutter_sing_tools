import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:record/record.dart';

part 'volume_event.dart';
part 'volume_state.dart';

/// 音量檢測
class VolumeBloc extends Bloc<VolumeEvent, VolumeState> {
  VolumeBloc(this._audioRecorder) : super(VolumeState()) {
    _init();

    on<VolumeEvent>((event, emit) => switch (event) {
          VolumeUpdate() => _update(event, emit),
        });
  }

  final AudioRecorder _audioRecorder;

  StreamSubscription<Amplitude>? _amplitudeSub;
  final double _minVolume = -45.0;

  void _init() {
    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen(_listen);
  }

  @override
  Future<void> close() {
    _amplitudeSub?.cancel();
    return super.close();
  }

  void _listen(Amplitude amp) {
    add(VolumeUpdate(amplitude: amp));
  }

  void _update(VolumeUpdate event, Emitter<VolumeState> emit) {
    final amp = event.amplitude;
    // if (amp.current > minVolume) {
    final volume = (amp.current - _minVolume) / _minVolume;
    // }

    emit(state.copyWith(
      amplitude: amp,
      volume: volume,
    ));
  }
}
