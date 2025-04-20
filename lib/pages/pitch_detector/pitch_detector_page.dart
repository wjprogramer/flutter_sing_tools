import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitchupdart/instrument_type.dart';
import 'package:pitchupdart/pitch_handler.dart';
import 'package:record/record.dart';

import 'home/home_screen.dart';
import 'home/pitch_cubit.dart';

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
          BlocProvider<PitchCubit>(
            create: (context) => PitchCubit(
              context.read<AudioRecorder>(),
              context.read<PitchDetector>(),
              context.read<PitchHandler>(),
            ),
          ),
        ],
        child: HomeScreen(),
      ),
    );
  }
}
