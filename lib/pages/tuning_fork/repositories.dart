import 'models.dart';

class PitchFrequencyRepository {
  final List<String> _octaves = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  final List<String> _notes = [
    'C', 'C#/Db', 'D', 'D#/Eb', 'E', 'F',
    'F#/Gb', 'G', 'G#/Ab', 'A', 'A#/Bb', 'B'
  ];

  final List<List<FrequencyItem>> _frequencies = [
    [FrequencyItem(16.352, -48), FrequencyItem(32.703, -36), FrequencyItem(65.406, -24), FrequencyItem(130.81, -12), FrequencyItem(261.63, 0), FrequencyItem(523.25, 12),
      FrequencyItem(1046.5, 24), FrequencyItem(2093.0, 36), FrequencyItem(4186.0, 48), FrequencyItem(8372.0, 60)],
    [FrequencyItem(17.324, -47), FrequencyItem(34.648, -35), FrequencyItem(69.296, -23), FrequencyItem(138.59, -11), FrequencyItem(277.18, 1), FrequencyItem(554.37, 13),
      FrequencyItem(1108.7, 25), FrequencyItem(2217.5, 37), FrequencyItem(4434.9, 49), FrequencyItem(8869.8, 61)],
    [FrequencyItem(18.354, -46), FrequencyItem(36.708, -34), FrequencyItem(73.416, -22), FrequencyItem(146.83, -10), FrequencyItem(293.66, 2), FrequencyItem(587.33, 14),
      FrequencyItem(1174.7, 26), FrequencyItem(2349.3, 38), FrequencyItem(4698.6, 50), FrequencyItem(9397.3, 62)],
    [FrequencyItem(19.445, -45), FrequencyItem(38.891, -33), FrequencyItem(77.782, -21), FrequencyItem(155.56, -9), FrequencyItem(311.13, 3), FrequencyItem(622.25, 15),
      FrequencyItem(1244.5, 27), FrequencyItem(2489.0, 39), FrequencyItem(4978.0, 51), FrequencyItem(9956.1, 63)],
    [FrequencyItem(20.602, -44), FrequencyItem(41.203, -32), FrequencyItem(82.407, -20), FrequencyItem(164.81, -8), FrequencyItem(329.63, 4), FrequencyItem(659.26, 16),
      FrequencyItem(1318.5, 28), FrequencyItem(2637.0, 40), FrequencyItem(5274.0, 52), FrequencyItem(10548, 64)],
    [FrequencyItem(21.827, -43), FrequencyItem(43.654, -31), FrequencyItem(87.307, -19), FrequencyItem(174.61, -7), FrequencyItem(349.23, 5), FrequencyItem(698.46, 17),
      FrequencyItem(1396.9, 29), FrequencyItem(2793.8, 41), FrequencyItem(5587.7, 53), FrequencyItem(11175, 65)],
    [FrequencyItem(23.125, -42), FrequencyItem(46.249, -30), FrequencyItem(92.499, -18), FrequencyItem(185.00, -6), FrequencyItem(369.99, 6), FrequencyItem(739.99, 18),
      FrequencyItem(1480.0, 30), FrequencyItem(2960.0, 42), FrequencyItem(5919.0, 54), FrequencyItem(11840, 66)],
    [FrequencyItem(24.500, -41), FrequencyItem(48.999, -29), FrequencyItem(97.999, -17), FrequencyItem(196.00, -5), FrequencyItem(392.00, 7), FrequencyItem(783.99, 19),
      FrequencyItem(1568.0, 31), FrequencyItem(3136.0, 43), FrequencyItem(6271.9, 55), FrequencyItem(12544, 67)],
    [FrequencyItem(25.957, -40), FrequencyItem(51.913, -28), FrequencyItem(103.83, -16), FrequencyItem(207.65, -4), FrequencyItem(415.30, 8), FrequencyItem(830.61, 20),
      FrequencyItem(1661.2, 32), FrequencyItem(3322.4, 44), FrequencyItem(6644.9, 56), FrequencyItem(13290, 68)],
    [FrequencyItem(27.500, -39), FrequencyItem(55.000, -27), FrequencyItem(110.00, -15), FrequencyItem(220.00, -3), FrequencyItem(440.00, 9), FrequencyItem(880.00, 21),
      FrequencyItem(1760.0, 33), FrequencyItem(3520.0, 45), FrequencyItem(7040.0, 57), FrequencyItem(14080, 69)],
    [FrequencyItem(29.135, -38), FrequencyItem(58.270, -26), FrequencyItem(116.54, -14), FrequencyItem(233.08, -2), FrequencyItem(466.16, 10), FrequencyItem(932.33, 22),
      FrequencyItem(1864.7, 34), FrequencyItem(3729.3, 46), FrequencyItem(7458.6, 58), FrequencyItem(14917, 70)],
    [FrequencyItem(30.868, -37), FrequencyItem(61.735, -25), FrequencyItem(123.47, -13), FrequencyItem(246.94, -1), FrequencyItem(493.88, 11), FrequencyItem(987.77, 23),
      FrequencyItem(1975.5, 35), FrequencyItem(3951.1, 47), FrequencyItem(7902.1, 59), FrequencyItem(15804, 71)],
  ];

  List<String> getOctaves() {
    return _octaves.toList();
  }

  List<String> getNotes() {
    return _notes.toList();
  }

  List<List<FrequencyItem>> getFrequencies() {
    final List<List<FrequencyItem>> result = [];

    for (var i = 0; i < _notes.length; i++) {
      final List<FrequencyItem> octaveFrequencies = _frequencies[i];
      final List<FrequencyItem> octaveItems = octaveFrequencies.map((item) {
        return item.copyWith(note: _notes[i], octave: 0);
      }).toList();
      result.add(octaveItems);
    }

    return result;
  }
}