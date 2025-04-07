part of 'files_explorer_page_bloc.dart';

sealed class FilesExplorerPageState extends Equatable {
  const FilesExplorerPageState();
}

final class FilesExplorerPageLoaded extends FilesExplorerPageState {
  const FilesExplorerPageLoaded({
    this.currentDir,
    this.files = const [],
  });

  final MyDirectory? currentDir;

  final List<MyFileSystemEntity> files;

  @override
  List<Object?> get props => [];
}

final class FilesExplorerPageLoading extends FilesExplorerPageState {
  @override
  List<Object?> get props => [];
}

final class FilesExplorerPageError extends FilesExplorerPageState {
  const FilesExplorerPageError(this.error, {
    this.stackTrace,
  });

  final Object? error;

  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [ error, stackTrace ];
}
