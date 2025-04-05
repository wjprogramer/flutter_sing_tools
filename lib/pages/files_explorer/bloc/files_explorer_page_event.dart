part of 'files_explorer_page_bloc.dart';

sealed class FilesExplorerPageEvent extends Equatable {
  const FilesExplorerPageEvent();
}

class FilesExplorerPageLoad extends FilesExplorerPageEvent {
  const FilesExplorerPageLoad({
    this.directory,
  });

  final Directory? directory;

  @override
  List<Object?> get props => [directory];
}
