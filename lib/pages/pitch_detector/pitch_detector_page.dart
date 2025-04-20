import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sing_tools/bloc/audio_recorder/audio_recorder_bloc.dart';
import 'package:flutter_sing_tools/bloc/pitch/pitch_bloc.dart';
import 'package:gap/gap.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitchupdart/instrument_type.dart';
import 'package:pitchupdart/pitch_handler.dart';
import 'package:record/record.dart';

class PitchDetectorPage extends StatelessWidget {
  const PitchDetectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
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
            create: (context) => PitchBloc(
              context.read<AudioRecorder>(),
              context.read<PitchDetector>(),
              context.read<PitchHandler>(),
            ),
          ),
        ],
        child: _Page(),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) {
    final pitchCubitState = context.watch<PitchBloc>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text("PitchUp sample- Guitar tuner"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                pitchCubitState.note,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 65.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                pitchCubitState.status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18.0,
                ),
              ),
              Gap(16),
              ...[
                { 'key': 'expectedFrequency', 'value': pitchCubitState.expectedFrequency},
                { 'key': 'diffFrequency', 'value': pitchCubitState.diffFrequency},
                { 'key': 'diffCents', 'value': pitchCubitState.diffCents},
              ].map((e) => Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: Divider.createBorderSide(context),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e['key'] as String,
                        textAlign: TextAlign.start,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        (e['value'] as double).toStringAsFixed(1),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

