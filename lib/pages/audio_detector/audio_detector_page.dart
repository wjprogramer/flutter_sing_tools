import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sing_tools/bloc/audio_recorder/audio_recorder_bloc.dart';
import 'package:flutter_sing_tools/bloc/pitch/pitch_bloc.dart';
import 'package:flutter_sing_tools/bloc/volume/volume_bloc.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitchupdart/instrument_type.dart';
import 'package:pitchupdart/pitch_handler.dart';
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
        ],
        child: const _Page(),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
