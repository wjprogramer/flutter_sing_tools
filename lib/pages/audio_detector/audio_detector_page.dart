import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sing_tools/bloc/audio_recorder/audio_recorder_bloc.dart';
import 'package:flutter_sing_tools/bloc/audio_recorder/widgets/status_listener.dart';
import 'package:flutter_sing_tools/bloc/pitch/pitch_bloc.dart';
import 'package:flutter_sing_tools/bloc/volume/volume_bloc.dart';
import 'package:flutter_sing_tools/widgets/audio/graph/bloc/audio_graph_bloc.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitchupdart/instrument_type.dart';
import 'package:pitchupdart/pitch_handler.dart';
import 'package:record/record.dart';
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

class AudioDetectorPage extends StatelessWidget {
  const AudioDetectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        RepositoryProvider<AudioRecorder>(
          create: (context) => AudioRecorder(),
        ),
        RepositoryProvider<PitchDetector>(
          create: (context) => PitchDetector(),
        ),
        RepositoryProvider<PitchHandler>(
          create: (context) => PitchHandler(InstrumentType.guitar),
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
            create: (context) => PitchBloc(
              context.read<AudioRecorder>(),
              context.read<PitchDetector>(),
              context.read<PitchHandler>(),
            ),
          ),
          BlocProvider(
            create: (context) => AudioGraphBloc(),
          ),
        ],
        child: _Page(),
      ),
    );
  }
}

class _Page extends StatefulWidget {
  const _Page();

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> with AudioRecorderMixin {
  AudioRecorderBloc get _recorderBloc => context.read<AudioRecorderBloc>();

  RecordState get _recordState => _recorderBloc.state.recordState;

  AudioRecorder get _audioRecorder => _recorderBloc.audioRecorder;

  void _start() => _recorderBloc.add(AudioRecorderStart(
        onPreStart: (config) async {
          context.read<AudioGraphBloc>().add(AudioGraphClear());
          // await recordFile(_audioRecorder, config);
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
    final recorderBloc = context.read<AudioRecorderBloc>();
    final audioGraphBloc = context.read<AudioGraphBloc>();

    switch (status) {
      case RecordState.pause:
        audioGraphBloc.add(AudioGraphPause());
        break;
      case RecordState.record:
        final pitchBloc = context.read<PitchBloc>();

        if (recorderBloc.audioSampleBufferedStream != null) {
          pitchBloc.add(PitchStart(recorderBloc.audioSampleBufferedStream!));
        }

        audioGraphBloc.add(
          AudioGraphStartRecording(
            getLatestVolume: () {
              final volumeBloc = context.read<VolumeBloc>();
              final volume = volumeBloc.state.volume;
              return volume;
            },
            getLatestPitchState: () {
              return pitchBloc.state;
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
      final recordDuration =
          context.read<AudioGraphBloc>().state.recordDuration;
      return Text(
        DisplayText.formatMinuteAndSeconds(recordDuration),
        style: const TextStyle(color: Colors.red),
      );
    }

    return const Text("Waiting to record");
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AudioRecorderBloc>();

    final volumeBloc = context.watch<VolumeBloc>();
    final amplitude = volumeBloc.state.amplitude;
    final volume = volumeBloc.state.volume;

    final audioGraphBloc = context.watch<AudioGraphBloc>();
    final volumePoints = audioGraphBloc.state.volumePoints;
    final pitchPoints = audioGraphBloc.state.pitchPoints;

    return AudioRecorderStatusListener(
      listener: _listenRecorderStatus,
      child: Scaffold(
        appBar: AppBar(title: Text('Audio Detector')),
        body: ListView(
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
              if (volumePoints.isNotEmpty || pitchPoints.isNotEmpty) ...[
                const SizedBox(height: 32),
                AudioGraph(
                  volumePoints: volumePoints,
                  pitchPoints: pitchPoints,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
