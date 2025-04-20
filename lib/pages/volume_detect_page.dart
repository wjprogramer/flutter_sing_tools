import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sing_tools/bloc/audio_recorder/audio_recorder_bloc.dart';
import 'package:flutter_sing_tools/bloc/audio_recorder/widgets/status_listener.dart';
import 'package:flutter_sing_tools/bloc/volume/volume_bloc.dart';
import 'package:flutter_sing_tools/utilities/audio_recorder/audio_recorder_io.dart';
import 'package:flutter_sing_tools/utilities/utilities.dart';
import 'package:flutter_sing_tools/widgets/audio/graph/audio_graph.dart';
import 'package:flutter_sing_tools/widgets/audio/graph/bloc/audio_graph_bloc.dart';
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
          BlocProvider(
            create: (context) => AudioGraphBloc(),
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

  void _start() => _recorderBloc.add(AudioRecorderStart(
        onPreStart: (config) async {
          context.read<AudioGraphBloc>().add(AudioGraphClear());

          // Record to file
          await recordFile(_audioRecorder, config);

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

  void _listenRecorderStatus(BuildContext context, RecordState status) {
    final audioGraphBloc = context.read<AudioGraphBloc>();
    switch (status) {
      case RecordState.pause:
        audioGraphBloc.add(AudioGraphPause());
        break;
      case RecordState.record:
        audioGraphBloc.add(
          AudioGraphStartRecording(
            getLatestVolume: () {
              final volumeBloc = context.read<VolumeBloc>();
              final volume = volumeBloc.state.volume;
              return volume;
            },
          ),
        );
        break;
      case RecordState.stop:
        audioGraphBloc.add(AudioGraphStop());
        break;
    }
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
      final recordDuration = context.read<AudioGraphBloc>().state.recordDuration;
      return Text(
        DisplayText.formatMinuteAndSeconds(recordDuration),
        style: const TextStyle(color: Colors.red),
      );
    }

    return const Text("Waiting to record");
  }

  @override
  Widget build(BuildContext context) {
    final volumeBloc = context.watch<VolumeBloc>();
    final amplitude = volumeBloc.state.amplitude;
    final volume = volumeBloc.state.volume;

    final audioGraphBloc = context.watch<AudioGraphBloc>();
    final volumePoints = audioGraphBloc.state.volumePoints;

    return AudioRecorderStatusListener(
      listener: _listenRecorderStatus,
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
              Text('Volume: ${Formatter.volume0to(volume, 100)}'),
              Text('Max: ${amplitude.max}'),
            ],
            if (volumePoints.isNotEmpty) ...[
              const SizedBox(height: 32),
              AudioGraph(
                volumePoints: volumePoints,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
