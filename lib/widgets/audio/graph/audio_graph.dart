import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sing_tools/bloc/audio_recorder/audio_recorder_bloc.dart';
import 'package:flutter_sing_tools/bloc/volume/volume_bloc.dart';

const Duration _graphBottomIntervalDuration = Duration(seconds: 5);

const Duration _graphSampleDuration = Duration(milliseconds: 200);

const int _maxGraphCount = 200;

const double _maxVolume = 120;

/// 目前只用在音量，之後可以採用不同數據 (例如: 音高等)，依據需求傳入
///
/// Required bloc: [AudioRecorderBloc]
/// Optional bloc (根據參數決定): [VolumeBloc]
class AudioGraph extends StatefulWidget {
  const AudioGraph({
    super.key,
    required this.volumePoints,
  });

  final List<FlSpot> volumePoints;

  static const Duration graphSampleDuration = _graphSampleDuration;

  static const int maxGraphCount = _maxGraphCount;

  static const double maxVolume = _maxVolume;

  @override
  State<AudioGraph> createState() => _AudioGraphState();
}

class _AudioGraphState extends State<AudioGraph> {
  List<FlSpot> get _volumePoints => widget.volumePoints;

  @override
  Widget build(BuildContext context) {
    final bottomInterval = _graphBottomIntervalDuration.inMilliseconds ~/
        _graphSampleDuration.inMilliseconds;

    return Padding(
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
                    final seconds =
                        (value * _graphSampleDuration.inMilliseconds) ~/ 1000;
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
    );
  }
}
