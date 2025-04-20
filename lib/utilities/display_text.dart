class DisplayText {
  DisplayText._();

  /// 'mm:ss'
  /// 會補零，分鐘數超過 99 會顯示 99
  static String formatMinuteAndSeconds(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).clamp(0, 99);
    final minutesText = minutes.toString().padLeft(2, '0');
    final secondsText = seconds.toString().padLeft(2, '0');
    return '$minutesText:$secondsText';
  }

}