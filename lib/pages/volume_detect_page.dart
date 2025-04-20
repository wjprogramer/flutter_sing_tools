import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sing_tools/bloc/audio_recorder/audio_recorder_bloc.dart';
import 'package:flutter_sing_tools/bloc/audio_recorder/widgets/status_listener.dart';
import 'package:flutter_sing_tools/bloc/volume/volume_bloc.dart';
import 'package:flutter_sing_tools/utilities/audio_recorder/audio_recorder_io.dart';
import 'package:flutter_sing_tools/widgets/audio/graph/audio_graph.dart';
import 'package:record/record.dart';

class VolumeDetectPage extends StatelessWidget {
  const VolumeDetectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        RepositoryProvider<AudioRecorder>(
          create: (context) => AudioRecorder(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AudioRecorderBloc(
              context.read<AudioRecorder>(),
            ),
          ),
          BlocProvider(
            create: (context) => VolumeBloc(
              context.read<AudioRecorder>(),
            ),
          ),
        ],
        child: Builder(
          builder: (context) {
            final bloc = context.read<AudioRecorderBloc>();
            final volumeBloc = context.read<VolumeBloc>();

            return _VolumeDetectPage(
              audioRecorderBloc: bloc,
              volumeBloc: volumeBloc,
            );
          },
        ),
      ),
    );
  }
}

/// Ref:
/// - https://gist.github.com/martusheff/57e321a31c2acb9154b5b5f4394c64e7
/// - https://github.com/llfbandit/record , record/examples
class _VolumeDetectPage extends StatefulWidget {
  const _VolumeDetectPage({
    required this.audioRecorderBloc,
    required this.volumeBloc,
  });

  final AudioRecorderBloc audioRecorderBloc;

  final VolumeBloc volumeBloc;

  @override
  State<_VolumeDetectPage> createState() => _VolumeDetectPageState();
}

class _VolumeDetectPageState extends State<_VolumeDetectPage>
    with AudioRecorderMixin {
  AudioRecorderBloc get _recorderBloc => widget.audioRecorderBloc;

  RecordState get _recordState => _recorderBloc.state.recordState;

  AudioRecorder get _audioRecorder => _recorderBloc.audioRecorder;

  Timer? _timer;
  int _recordDurationInMilliseconds = 0;
  final List<FlSpot> _volumePoints = [];
  int _elapsedMilliseconds = 0;

  Duration get _graphSampleDuration => AudioGraph.graphSampleDuration;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int volume0to(double volume, int maxVolumeToDisplay) {
    return (volume * maxVolumeToDisplay).round().abs();
  }

  void _start() => _recorderBloc.add(AudioRecorderStart(
        onPreStart: (config) async {
          // Record to file
          await recordFile(_audioRecorder, config);

          _recordDurationInMilliseconds = 0;

          // Record to stream
          // await recordStream(_audioRecorder, config);
        },
      ));

  void _stop() {
    _recorderBloc.add(AudioRecorderStop(onStop: (path) {
      downloadWebData(path);
    }));
  }

  void _pause() => _recorderBloc.add(const AudioRecorderPause());

  void _resume() => _recorderBloc.add(const AudioRecorderResume());

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(_graphSampleDuration, (Timer t) {
      final volumeBloc = context.read<VolumeBloc>();
      final volume = volumeBloc.state.volume;

      _recordDurationInMilliseconds += _graphSampleDuration.inMilliseconds;
      _elapsedMilliseconds += _graphSampleDuration.inMilliseconds;
      _volumePoints.add(FlSpot(
        _elapsedMilliseconds / _graphSampleDuration.inMilliseconds,
        volume0to(volume, 100)
            .clamp(0.0, AudioGraph.maxVolume)
            .toDouble(), // 確保在合法範圍
      ));
      final int skip = _volumePoints.length - AudioGraph.maxGraphCount;
      if (skip > 0) {
        _volumePoints.removeRange(0, skip);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final volumeBloc = context.watch<VolumeBloc>();
    final amplitude = volumeBloc.state.amplitude;
    final volume = volumeBloc.state.volume;

    return AudioRecorderStatusListener(
      listener: (context, status) {
        switch (status) {
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
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Volume Detect')),
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
            if (amplitude != null) ...[
              const SizedBox(height: 40),
              Text('Current: ${amplitude.current}'),
              Text('Volume: ${volume0to(volume, 100)}'),
              Text('Max: ${amplitude.max}'),
              if (_volumePoints.isNotEmpty) ...[
                const SizedBox(height: 32),
                AudioGraph(
                  volumePoints: _volumePoints,
                ),
              ],
            ],
          ],
        ),
      ),
    );
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
}
