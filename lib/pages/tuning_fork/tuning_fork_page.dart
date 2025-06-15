import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_sing_tools/pages/tuning_fork/repositories.dart';
import 'package:flutter_sing_tools/utilities/assets.dart';
import 'package:flutter_sing_tools/widgets/widgets.dart';
import 'package:gap/gap.dart';
import 'package:rxdart/rxdart.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'base_configs.dart';
import 'enums.dart';
import 'models.dart';

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

  final _baseConfigs = TuningForkBaseConfigs();
  final _showDiffToC = BehaviorSubject.seeded(false);
  final _frequency$ = BehaviorSubject.seeded(440.0);
  final _volume$ = BehaviorSubject.seeded(0.1);
  final _waveform$ = BehaviorSubject.seeded(Waveform.sine);

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
    final clamped = _baseConfigs.clampFrequency(frequency);
    _frequency$.add(clamped);
    await _controller.runJavaScript('setFrequency(${clamped.toInt()})');
  }

  Future<void> _setVolume(double volume) async {
    final maxVolume = _waveform$.value.limitMaxVolume;
    final realVolume = volume.clamp(0, maxVolume);
    _volume$.add(volume);
    await _controller.runJavaScript('setVolume(${realVolume.toStringAsFixed(2)})');
  }

  Future<void> _setWaveform(Waveform? waveform) async {
    if (waveform == null || waveform == _waveform$.value) return;
    _waveform$.add(waveform);
    await _controller.runJavaScript('setWaveform("${waveform.code}")');
    await _play();
  }

  Future<void> _play() async {
    final maxVolume = _waveform$.value.limitMaxVolume;
    final volume = _volume$.value.clamp(0, maxVolume);
    final options = {
      'frequency': _frequency$.value.toInt(),
      'volume': volume.toStringAsFixed(3),
      'waveform': _waveform$.value.code,
    };
    final optionsJson = jsonEncode(options);
    await _controller.runJavaScript('play($optionsJson)');
  }

  Future<void> _stop() async {
    await _controller.runJavaScript('stop()');
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
                              FSPadding(
                                child: FSTitle('# Volume: ${value.toStringAsFixed(2)}'),
                              ),
                              Slider(
                                min: 0,
                                max: 1,
                                value: value,
                                onChanged: _setVolume,
                              ),
                              StreamBuilder<Waveform>(
                                stream: _waveform$,
                                builder: (context, snapshot) {
                                  final wave = snapshot.data ?? Waveform.sine;
                                  final maxVolume = wave.limitMaxVolume;

                                  if (maxVolume == 1) {
                                    return SizedBox.shrink();
                                  }

                                  return FSPadding(
                                    child: Text(
                                      '為了保護聽力，${wave.displayName} 最大音量限制：${maxVolume.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      FSPadding(
                        child: FSTitle('# Waveform'),
                      ),
                      StreamBuilder<Waveform>(
                        stream: _waveform$,
                        builder: (context, snapshot) {
                          final value = snapshot.data ?? Waveform.sine;
                          return FSPadding(
                            child: DropdownButton<Waveform>(
                              value: value,
                              items: Waveform.values.map((type) => DropdownMenuItem(
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
                              FSPadding(
                                child: FSTitle('# Frequency: ${value.toInt()} Hz'),
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
                      ListTile(
                        title: Text('頻率，單位為赫茲。'),
                      ),
                      StreamBuilder<bool>(
                        stream: _showDiffToC,
                        builder: (context, snapshot) {
                          final showDiff = snapshot.data ?? false;
                          return CheckboxListTile(
                            value: showDiff,
                            onChanged: (value) {
                              _showDiffToC.add(value ?? false);
                            },
                            title: Text('顯示與中央C（261.63赫茲）的半音距離'),
                          );
                        },
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          top: 8,
                          bottom: 32,
                          right: 16,
                          left: 16,
                        ),
                        scrollDirection: Axis.horizontal,
                        child: StreamBuilder<bool>(
                          stream: _showDiffToC,
                          builder: (context, snapshot) {
                            final showDiff = snapshot.data ?? false;
                            return StreamBuilder<double>(
                              stream: _frequency$,
                              builder: (context, snapshot) {
                                final currentFrequency = snapshot.data ?? 440.0;
                                return PitchFrequencyTable(
                                  value: currentFrequency,
                                  showDiff: showDiff,
                                  onTap: (freqItem) {
                                    _setFrequency(freqItem.value);
                                  },
                                );
                              },
                            );
                          },
                        ),
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

/// 音高頻率表
///
/// 頻率，單位為赫茲。
class PitchFrequencyTable extends StatefulWidget {
  const PitchFrequencyTable({
    super.key,
    required this.value,
    this.onTap,
    this.showDiff = false,
  });

  /// 頻率值，單位為赫茲
  final double value;

  final void Function(FrequencyItem item)? onTap;

  final bool showDiff;

  @override
  State<PitchFrequencyTable> createState() => _PitchFrequencyTableState();
}

class _PitchFrequencyTableState extends State<PitchFrequencyTable> {
  final PitchFrequencyRepository _repository = PitchFrequencyRepository();
  List<String> _octaves = [];
  List<String> _notes = [];
  List<List<FrequencyItem>> _frequencies = [];

  @override
  void initState() {
    super.initState();
    _octaves = _repository.getOctaves();
    _notes = _repository.getNotes();
    _frequencies = _repository.getFrequencies();
  }

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
            ..._octaves.map((o) => TableCell(
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
                  child: Text(_notes[i], style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              for (var freq in _frequencies[i])
                FrequencyItemTableCell(
                  freq: freq,
                  onTap: widget.onTap == null ? null : (item) {
                    widget.onTap?.call(item);
                  },
                  currentValue: widget.value,
                  showDiff: widget.showDiff,
                ),
            ],
          ),
      ],
    );
  }
}

class FrequencyItemTableCell extends StatelessWidget {
  const FrequencyItemTableCell({
    super.key,
    required this.freq,
    this.onTap,
    this.currentValue = 0,
    this.showDiff = false,
  });

  final FrequencyItem freq;

  final void Function(FrequencyItem item)? onTap;

  /// 目前播放中的頻率值
  final double currentValue;

  /// 是否顯示差異值
  final bool showDiff;
 
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseConfigs = TuningForkBaseConfigs();
    final isValid = baseConfigs.isFrequencyValid(freq.value);
    final labelColor = theme.colorScheme.onSurface
        .withAlpha(isValid ? 160 : 80);
    final textColor = isValid ? null : theme.colorScheme.onSurface.withAlpha(100);
    final diffText = !showDiff ? '' : '\n(${freq.diff >= 0 ? '+' : ''}${freq.diff})';

    return TableCell(
      child: InkWell(
        onTap: onTap == null || !isValid ? null : () {
          onTap?.call(freq);
        },
        child: Container(
          decoration: BoxDecoration(
            color: freq.value.round() == currentValue.round()
                ? theme.colorScheme.tertiary.withAlpha(60)
                : Colors.transparent,
          ),
          padding: EdgeInsets.all(8),
          child: Column(
            children: [
              Text(
                '${freq.note} ${freq.octave}',
                style: TextStyle(
                  fontSize: 10,
                  color: labelColor,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '${freq.value}$diffText',
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


