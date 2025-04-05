import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
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
      emit(FilesExplorerPageLoading());

      final targetDir = event.directory ?? MyFileUtility.getApplicationDirectory();
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
