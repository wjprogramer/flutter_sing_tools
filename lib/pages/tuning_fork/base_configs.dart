class TuningForkBaseConfigs {
  final double minFrequency = 100;
  final double maxFrequency = 2000;

  double clampFrequency(double frequency) {
    return frequency.clamp(minFrequency, maxFrequency);
  }

  bool isFrequencyValid(double frequency) {
    return frequency >= minFrequency && frequency <= maxFrequency;
  }
}