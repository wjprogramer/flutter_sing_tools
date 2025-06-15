class FrequencyItem {
  FrequencyItem(this.value, this.diff, {
    this.note = '',
    this.octave = 0,
  });

  /// 音名
  final String note;

  /// 八度
  final int octave;

  /// 頻率
  final double value;

  final double diff;

  FrequencyItem copyWith({
    String? note,
    int? octave,
    double? value,
    double? diff,
  }) {
    return FrequencyItem(
      value ?? this.value,
      diff ?? this.diff,
      note: note ?? this.note,
      octave: octave ?? this.octave,
    );
  }
}