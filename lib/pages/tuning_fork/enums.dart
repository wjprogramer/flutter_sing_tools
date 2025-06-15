enum Waveform {
  sine,
  square,
  triangle,
  sawtooth;

  String get code => switch (this) {
    Waveform.sine => 'sine',
    Waveform.square => 'square',
    Waveform.triangle => 'triangle',
    Waveform.sawtooth => 'sawtooth',
  };

  String get displayName => switch (this) {
    Waveform.sine => 'sine (正弦波)',
    Waveform.square => 'square (方波)',
    Waveform.triangle => 'triangle (三角波)',
    Waveform.sawtooth => 'sawtooth (鋸齒波)',
  };

  double get limitMaxVolume => switch (this) {
    Waveform.sine => 1,
    Waveform.square => 0.01,
    Waveform.triangle => 0.03,
    Waveform.sawtooth => 0.015,
  };
}