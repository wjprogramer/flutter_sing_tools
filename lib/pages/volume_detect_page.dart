import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:flutter_sing_tools/utilities/audio_recorder/audio_recorder_io.dart';

const double _maxVolume = 120;

const Duration _graphSampleDuration = Duration(milliseconds: 200);

const Duration _graphBottomIntervalDuration = Duration(seconds: 5);

const int _maxGraphCount = 200;

/// Ref:
/// - https://gist.github.com/martusheff/57e321a31c2acb9154b5b5f4394c64e7
/// - https://github.com/llfbandit/record , record/examples
class VolumeDetectPage extends StatefulWidget {
  const VolumeDetectPage({
    super.key,
    required this.onStop,
  });

  final void Function(String path) onStop;

  @override
  State<VolumeDetectPage> createState() => _VolumeDetectPageState();
}

class _VolumeDetectPageState extends State<VolumeDetectPage> with AudioRecorderMixin {
  int _recordDurationInMilliseconds = 0;
  Timer? _timer;
  late final AudioRecorder _audioRecorder;
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Amplitude? _amplitude;
  double _volume = 0.0;
  final double _minVolume = -45.0;
  final List<FlSpot> _volumePoints = [];
  int _elapsedMilliseconds = 0;

  @override
  void initState() {
    _audioRecorder = AudioRecorder();

    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      _updateRecordState(recordState);
    });

    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) {
      _amplitude = amp;
      // if (amp.current > minVolume) {
      _volume = (amp.current - _minVolume) / _minVolume;
      // }
      setState(() {});
    });

    super.initState();
  }

  int volume0to(double volume, int maxVolumeToDisplay) {
    return (volume * maxVolumeToDisplay).round().abs();
  }

  Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        const encoder = AudioEncoder.aacLc;

        if (!await _isEncoderSupported(encoder)) {
          return;
        }

        final devs = await _audioRecorder.listInputDevices();
        debugPrint(devs.toString());

        const config = RecordConfig(encoder: encoder, numChannels: 1);

        // Record to file
        await recordFile(_audioRecorder, config);

        // Record to stream
        // await recordStream(_audioRecorder, config);

        _recordDurationInMilliseconds = 0;

        _startTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _stop() async {
    final path = await _audioRecorder.stop();

    if (path != null) {
      widget.onStop(path);

      downloadWebData(path);
    }
  }

  Future<void> _pause() => _audioRecorder.pause();

  Future<void> _resume() => _audioRecorder.resume();

  void _updateRecordState(RecordState recordState) {
    setState(() => _recordState = recordState);

    switch (recordState) {
      case RecordState.pause:
        _timer?.cancel();
        break;
      case RecordState.record:
        _startTimer();
        break;
      case RecordState.stop:
        _timer?.cancel();
        _recordDurationInMilliseconds = 0;
        break;
    }
  }

  Future<bool> _isEncoderSupported(AudioEncoder encoder) async {
    final isSupported = await _audioRecorder.isEncoderSupported(
      encoder,
    );

    if (!isSupported) {
      debugPrint('${encoder.name} is not supported on this platform.');
      debugPrint('Supported encoders are:');

      for (final e in AudioEncoder.values) {
        if (await _audioRecorder.isEncoderSupported(e)) {
          debugPrint('- ${e.name}');
        }
      }
    }

    return isSupported;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInterval = _graphBottomIntervalDuration.inMilliseconds ~/ _graphSampleDuration.inMilliseconds;
    // print('${_graphBottomIntervalDuration.inMilliseconds}, ${_graphSampleDuration.inMilliseconds}, $bottomInterval');

    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildRecordStopControl(),
                const SizedBox(width: 20),
                _buildPauseResumeControl(),
                const SizedBox(width: 20),
                _buildText(),
              ],
            ),
            if (_amplitude != null) ...[
              const SizedBox(height: 40),
              Text('Current: ${_amplitude?.current ?? 0.0}'),
              Text('Volume: ${volume0to(_volume, 100)}'),
              Text('Max: ${_amplitude?.max ?? 0.0}'),
              if (_volumePoints.isNotEmpty) ...[
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        minX: _volumePoints.firstOrNull?.x ?? 0,
                        maxX: math.max(
                          (_volumePoints.lastOrNull?.x ?? 0) + 5,
                          _maxGraphCount.toDouble(),
                        ),
                        minY: 0,
                        maxY: _maxVolume,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _volumePoints,
                            isCurved: true,
                            // colors: [Colors.blue],
                            belowBarData: BarAreaData(show: false),
                            dotData: FlDotData(show: false),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 30,
                              getTitlesWidget: (value, _) {
                                return Text(
                                  value.round().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(),
                          rightTitles: AxisTitles(),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: bottomInterval.toDouble(),
                              getTitlesWidget: (value, _) {
                                final seconds = (value * _graphSampleDuration.inMilliseconds) ~/ 1000;
                                return Text(
                                  '${seconds}s',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                        ),
                        borderData: FlBorderData(show: true),
                      ),
                      // 因為會清除過舊的資料，會導致畫面上同樣位置的線條跳動
                      duration: Duration(milliseconds: 0),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Widget _buildRecordStopControl() {
    late Icon icon;
    late Color color;

    if (_recordState != RecordState.stop) {
      icon = const Icon(Icons.stop, color: Colors.red, size: 30);
      color = Colors.red.withValues(alpha: 0.1);
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.mic, color: theme.primaryColor, size: 30);
      color = theme.primaryColor.withValues(alpha: 0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            (_recordState != RecordState.stop) ? _stop() : _start();
          },
        ),
      ),
    );
  }

  Widget _buildPauseResumeControl() {
    if (_recordState == RecordState.stop) {
      return const SizedBox.shrink();
    }

    late Icon icon;
    late Color color;

    if (_recordState == RecordState.record) {
      icon = const Icon(Icons.pause, color: Colors.red, size: 30);
      color = Colors.red.withValues(alpha: 0.1);
    } else {
      final theme = Theme.of(context);
      icon = const Icon(Icons.play_arrow, color: Colors.red, size: 30);
      color = theme.primaryColor.withValues(alpha: 0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            (_recordState == RecordState.pause) ? _resume() : _pause();
          },
        ),
      ),
    );
  }

  Widget _buildText() {
    if (_recordState != RecordState.stop) {
      return _buildTimer();
    }

    return const Text("Waiting to record");
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDurationInMilliseconds ~/ 60);
    final String seconds = _formatNumber(_recordDurationInMilliseconds % 60);

    return Text(
      '$minutes : $seconds',
      style: const TextStyle(color: Colors.red),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(_graphSampleDuration, (Timer t) {
      setState(() {
        _recordDurationInMilliseconds += _graphSampleDuration.inMilliseconds;
        _elapsedMilliseconds += _graphSampleDuration.inMilliseconds;
        _volumePoints.add(FlSpot(
          _elapsedMilliseconds / _graphSampleDuration.inMilliseconds,
          volume0to(_volume, 100).clamp(0.0, _maxVolume).toDouble(), // 確保在合法範圍
        ));
        final int skip = _volumePoints.length - _maxGraphCount;
        if (skip > 0) {
          _volumePoints.removeRange(0, skip);
        }
      });
    });
  }
}
