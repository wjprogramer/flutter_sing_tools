import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_sing_tools/utilities/assets.dart';
import 'package:gap/gap.dart';
import 'package:rxdart/rxdart.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Ref:
///
/// - [wiki:音高](https://zh.wikipedia.org/zh-tw/%E9%9F%B3%E9%AB%98)
class TuningForkPage extends StatefulWidget {
  const TuningForkPage({super.key});

  @override
  State<TuningForkPage> createState() => _TuningForkPageState();
}

class _TuningForkPageState extends State<TuningForkPage> {
  late WebViewController _controller;

  final _frequency$ = BehaviorSubject.seeded(440.0);
  final _volume$ = BehaviorSubject.seeded(0.1);
  final _waveform$ = BehaviorSubject.seeded(_Waveform.sine);

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadFlutterAsset(Assets.tuning_fork_html);
    // initialUrl: 'about:blank', // 預設空白
  }

  @override
  void deactivate() {
    _controller.runJavaScript('stop()');
    super.deactivate();
  }

  @override
  void dispose() {
    _frequency$.close();
    _volume$.close();
    _waveform$.close();
    super.dispose();
  }

  Future<void> _setFrequency(double frequency) async {
    final clamped = frequency.clamp(100.0, 2000.0);
    _frequency$.add(clamped);
    await _controller.runJavaScript('setFrequency(${clamped.toInt()})');
  }

  Future<void> _setVolume(double volume) async {
    _volume$.add(volume);
    await _controller.runJavaScript('setVolume(${volume.toStringAsFixed(2)})');
  }

  Future<void> _setWaveform(_Waveform? waveform) async {
    if (waveform == null || waveform == _waveform$.value) return;
    _waveform$.add(waveform);
    await _controller.runJavaScript("setWaveform('${waveform.code}')");
    await _play();
  }

  Future<void> _play() async {
    final options = {
      'frequency': _frequency$.value.toInt(),
      'volume': _volume$.value.toStringAsFixed(2),
      'waveform': _waveform$.value.code,
    };
    final optionsJson = jsonEncode(options);
    await _controller.runJavaScript("play($optionsJson)");
  }

  Future<void> _stop() async {
    await _controller.runJavaScript("stop()");
  }

  @override
  Widget build(BuildContext context) {
    const values = [1, 5, 10, 100];

    return Scaffold(
      appBar: AppBar(
        title: Text('音叉'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text('電子振盪器 Oscillator')),
                    body: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '電子振盪器 (Oscillator) 可以模擬音叉 (Tuning Fork) 的功能',
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 可選：隱藏 WebView（設成 1px）
          IgnorePointer(
            child: Opacity(
              opacity: 0,
              child: SizedBox(
                width: 1,
                height: 1,
                child: WebViewWidget(
                  controller: _controller,
                ),
              ),
            ),
          ),
          // Flutter 控制面板
          Positioned.fill(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      StreamBuilder<double>(
                        stream: _volume$,
                        builder: (context, snapshot) {
                          final value = snapshot.data ?? 0.1;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Padding(
                                child: _Title('# Volume: ${value.toStringAsFixed(2)}'),
                              ),
                              Slider(
                                min: 0,
                                max: 1,
                                value: value,
                                onChanged: _setVolume,
                              ),
                            ],
                          );
                        },
                      ),
                      _Padding(
                        child: _Title('# Waveform'),
                      ),
                      StreamBuilder<_Waveform>(
                        stream: _waveform$,
                        builder: (context, snapshot) {
                          final value = snapshot.data ?? _Waveform.sine;
                          return _Padding(
                            child: DropdownButton<_Waveform>(
                              value: value,
                              items: _Waveform.values.map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.displayName),
                              )).toList(),
                              onChanged: _setWaveform,
                            ),
                          );
                        },
                      ),
                      StreamBuilder<double>(
                        stream: _frequency$,
                        builder: (context, snapshot) {
                          final value = snapshot.data ?? 440.0;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Padding(
                                child: _Title('# Frequency: ${value.toInt()} Hz'),
                              ),
                              Slider(
                                min: 100,
                                max: 2000,
                                value: value,
                                onChanged: _setFrequency,
                              ),
                            ],
                          );
                        },
                      ),
                      ...[-1, 1].map((sign) {
                        return SizedBox(
                          height: 60,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            children: values.map((value) => Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final frequency = _frequency$.value;
                                    final newFrequency = (frequency + value * sign).clamp(100.0, 2000.0)
                                        .toInt().toDouble();
                                    await _setFrequency(newFrequency);
                                  },
                                  child: Text(
                                    '${sign < 0 ? '－' : '＋'}$value',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                            )).toList(),
                          ),
                        );
                      }),
                      Gap(24),
                      _Padding(
                        child: Text('頻率，單位為赫茲。括號內為距離中央C（261.63赫茲）的半音距離。'),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 16,
                        ),
                        scrollDirection: Axis.horizontal,
                        child: PitchFrequencyTable(),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: Divider.createBorderSide(context),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _play,
                        child: Text('Play'),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _stop,
                        child: Text('Stop'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Waveform {
  sine,
  square,
  triangle,
  sawtooth;

  String get code => switch (this) {
    _Waveform.sine => 'sine',
    _Waveform.square => 'square',
    _Waveform.triangle => 'triangle',
    _Waveform.sawtooth => 'sawtooth',
  };

  String get displayName => switch (this) {
    _Waveform.sine => 'sine (正弦波)',
    _Waveform.square => 'square (方波)',
    _Waveform.triangle => 'triangle (三角波)',
    _Waveform.sawtooth => 'sawtooth (鋸齒波)',
  };
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: 24,
        bottom: 12,
      ),
      child: Text(
        text,
        style: theme.textTheme.titleMedium,
      ),
    );
  }
}

class _Padding extends StatelessWidget {
  const _Padding({
    this.child,
  });

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      child: child,
    );
  }
}

/// 音高頻率表
class PitchFrequencyTable extends StatelessWidget {
  PitchFrequencyTable({super.key});

  final List<String> octaves = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  final List<String> notes = [
    'C', 'C#/Db', 'D', 'D#/Eb', 'E', 'F',
    'F#/Gb', 'G', 'G#/Ab', 'A', 'A#/Bb', 'B'
  ];

  final List<List<_FrequencyItem>> _frequencies = [
    [_FrequencyItem(16.352, -48), _FrequencyItem(32.703, -36), _FrequencyItem(65.406, -24), _FrequencyItem(130.81, -12), _FrequencyItem(261.63, 0), _FrequencyItem(523.25, 12),
      _FrequencyItem(1046.5, 24), _FrequencyItem(2093.0, 36), _FrequencyItem(4186.0, 48), _FrequencyItem(8372.0, 60)],
    [_FrequencyItem(17.324, -47), _FrequencyItem(34.648, -35), _FrequencyItem(69.296, -23), _FrequencyItem(138.59, -11), _FrequencyItem(277.18, 1), _FrequencyItem(554.37, 13),
      _FrequencyItem(1108.7, 25), _FrequencyItem(2217.5, 37), _FrequencyItem(4434.9, 49), _FrequencyItem(8869.8, 61)],
    [_FrequencyItem(18.354, -46), _FrequencyItem(36.708, -34), _FrequencyItem(73.416, -22), _FrequencyItem(146.83, -10), _FrequencyItem(293.66, 2), _FrequencyItem(587.33, 14),
      _FrequencyItem(1174.7, 26), _FrequencyItem(2349.3, 38), _FrequencyItem(4698.6, 50), _FrequencyItem(9397.3, 62)],
    [_FrequencyItem(19.445, -45), _FrequencyItem(38.891, -33), _FrequencyItem(77.782, -21), _FrequencyItem(155.56, -9), _FrequencyItem(311.13, 3), _FrequencyItem(622.25, 15),
      _FrequencyItem(1244.5, 27), _FrequencyItem(2489.0, 39), _FrequencyItem(4978.0, 51), _FrequencyItem(9956.1, 63)],
    [_FrequencyItem(20.602, -44), _FrequencyItem(41.203, -32), _FrequencyItem(82.407, -20), _FrequencyItem(164.81, -8), _FrequencyItem(329.63, 4), _FrequencyItem(659.26, 16),
      _FrequencyItem(1318.5, 28), _FrequencyItem(2637.0, 40), _FrequencyItem(5274.0, 52), _FrequencyItem(10548, 64)],
    [_FrequencyItem(21.827, -43), _FrequencyItem(43.654, -31), _FrequencyItem(87.307, -19), _FrequencyItem(174.61, -7), _FrequencyItem(349.23, 5), _FrequencyItem(698.46, 17),
      _FrequencyItem(1396.9, 29), _FrequencyItem(2793.8, 41), _FrequencyItem(5587.7, 53), _FrequencyItem(11175, 65)],
    [_FrequencyItem(23.125, -42), _FrequencyItem(46.249, -30), _FrequencyItem(92.499, -18), _FrequencyItem(185.00, -6), _FrequencyItem(369.99, 6), _FrequencyItem(739.99, 18),
      _FrequencyItem(1480.0, 30), _FrequencyItem(2960.0, 42), _FrequencyItem(5919.0, 54), _FrequencyItem(11840, 66)],
    [_FrequencyItem(24.500, -41), _FrequencyItem(48.999, -29), _FrequencyItem(97.999, -17), _FrequencyItem(196.00, -5), _FrequencyItem(392.00, 7), _FrequencyItem(783.99, 19),
      _FrequencyItem(1568.0, 31), _FrequencyItem(3136.0, 43), _FrequencyItem(6271.9, 55), _FrequencyItem(12544, 67)],
    [_FrequencyItem(25.957, -40), _FrequencyItem(51.913, -28), _FrequencyItem(103.83, -16), _FrequencyItem(207.65, -4), _FrequencyItem(415.30, 8), _FrequencyItem(830.61, 20),
      _FrequencyItem(1661.2, 32), _FrequencyItem(3322.4, 44), _FrequencyItem(6644.9, 56), _FrequencyItem(13290, 68)],
    [_FrequencyItem(27.500, -39), _FrequencyItem(55.000, -27), _FrequencyItem(110.00, -15), _FrequencyItem(220.00, -3), _FrequencyItem(440.00, 9), _FrequencyItem(880.00, 21),
      _FrequencyItem(1760.0, 33), _FrequencyItem(3520.0, 45), _FrequencyItem(7040.0, 57), _FrequencyItem(14080, 69)],
    [_FrequencyItem(29.135, -38), _FrequencyItem(58.270, -26), _FrequencyItem(116.54, -14), _FrequencyItem(233.08, -2), _FrequencyItem(466.16, 10), _FrequencyItem(932.33, 22),
      _FrequencyItem(1864.7, 34), _FrequencyItem(3729.3, 46), _FrequencyItem(7458.6, 58), _FrequencyItem(14917, 70)],
    [_FrequencyItem(30.868, -37), _FrequencyItem(61.735, -25), _FrequencyItem(123.47, -13), _FrequencyItem(246.94, -1), _FrequencyItem(493.88, 11), _FrequencyItem(987.77, 23),
      _FrequencyItem(1975.5, 35), _FrequencyItem(3951.1, 47), _FrequencyItem(7902.1, 59), _FrequencyItem(15804, 71)],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerBackground = theme.colorScheme.primaryContainer;

    return Table(
      border: TableBorder.all(),
      defaultColumnWidth: FixedColumnWidth(80),
      children: [
        // 表頭 Row（八度 0～9）
        TableRow(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              color: headerBackground,
              child: Text(
                '八度 →\n音名 ↓', style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...octaves.map((o) => TableCell(
              verticalAlignment: TableCellVerticalAlignment.fill,
              child: Container(
                alignment: Alignment.center,
                color: headerBackground,
                child: Text(o, textAlign: TextAlign.center),
              ),
            )),
          ],
        ),
        // 每一個音名 Row
        for (int i = 0; i < _frequencies.length; i++)
          TableRow(
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.fill,
                child: Container(
                  alignment: AlignmentDirectional.centerStart,
                  padding: EdgeInsets.all(8),
                  color: headerBackground,
                  child: Text(notes[i], style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              for (var freq in _frequencies[i])
                Container(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    '${freq.value}\n(${freq.diff >= 0 ? '+' : ''}${freq.diff})',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _FrequencyItem {
  _FrequencyItem(this.value, this.diff);

  /// 頻率
  final double value;

  final double diff;
}
