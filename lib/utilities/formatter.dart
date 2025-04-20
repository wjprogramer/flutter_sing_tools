class Formatter {
  Formatter._();

  static int volume0to(double volume, int maxVolumeToDisplay) {
    return (volume * maxVolumeToDisplay).round().abs();
  }
}