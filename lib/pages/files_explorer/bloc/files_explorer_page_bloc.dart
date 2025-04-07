import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_sing_tools/models/io/io.dart';
import 'package:flutter_sing_tools/utilities/utilities.dart';

part 'files_explorer_page_event.dart';
part 'files_explorer_page_state.dart';

typedef _Emitter = Emitter<FilesExplorerPageState>;

class FilesExplorerPageBloc extends Bloc<FilesExplorerPageEvent, FilesExplorerPageState> {
  FilesExplorerPageBloc() : super(FilesExplorerPageLoaded()) {
    on<FilesExplorerPageEvent>((event, emit) => switch (event) {
      FilesExplorerPageLoad() => _load(event, emit),
    });
  }

  Future<void> _load(FilesExplorerPageLoad event, _Emitter emit) async {
    try {
      final currentState = state;
      emit(FilesExplorerPageLoading());

      final currentDir = currentState is FilesExplorerPageLoaded ? currentState.currentDir : null;
      final targetDir = event.directory ?? currentDir ?? MyFileUtility.getApplicationDirectory();
      final files = await targetDir.list().toList();

      emit(FilesExplorerPageLoaded(
        currentDir: targetDir,
        files: files,
      ));
    } catch (e, s) {
      emit(FilesExplorerPageError(e));
    }
  }
}
