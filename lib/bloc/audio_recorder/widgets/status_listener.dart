import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sing_tools/bloc/audio_recorder/audio_recorder_bloc.dart';
import 'package:record/record.dart';

class AudioRecorderStatusListener extends StatelessWidget {
  const AudioRecorderStatusListener({
    super.key,
    required this.listener,
    this.child,
  });

  final void Function(BuildContext context, RecordState recordState) listener;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AudioRecorderBloc, AudioRecorderState>(
      bloc: context.read<AudioRecorderBloc>(),
      listenWhen: (previous, current) {
        return previous.recordState != current.recordState;
      },
      listener: (context, state) {
        listener(context, state.recordState);
      },
      child: child,
    );
  }
}
