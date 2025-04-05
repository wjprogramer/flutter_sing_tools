import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sing_tools/extensions/extensions.dart';
import 'package:flutter_sing_tools/utilities/utilities.dart';

import 'bloc/files_explorer_page_bloc.dart';

class FilesExplorerPage extends StatefulWidget {
  const FilesExplorerPage({super.key});

  @override
  State<FilesExplorerPage> createState() => _FilesExplorerPageState();
}

class _FilesExplorerPageState extends State<FilesExplorerPage> {
  final _bloc = FilesExplorerPageBloc();

  @override
  void initState() {
    super.initState();
    _bloc.add(const FilesExplorerPageLoad());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Builder(
        builder: (context) {
          final currentDir = context.select<FilesExplorerPageBloc, Directory?>((m) => switch (m.state) {
            FilesExplorerPageLoaded s => s.currentDir,
            FilesExplorerPageLoading() => null,
            FilesExplorerPageError() => null,
          });

          return PopScope(
            canPop: currentDir?.path == MyFileUtility.getApplicationDirectory().path,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop || currentDir == null) {
                return;
              }
              context.read<FilesExplorerPageBloc>()
                  .add(FilesExplorerPageLoad(directory: currentDir.parent));
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Files Explorer'),
                leading: BackButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              body: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Builder(
                    builder: (context) {
                      if (currentDir == null) {
                        return Text('');
                      }
                      return Text(MyFileUtility.formatAppDirSubFilePath(currentDir));
                    }
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final state = context.watch<FilesExplorerPageBloc>().state;

                        switch (state) {
                          case FilesExplorerPageLoaded():
                            return _FileListView(state);
                          case FilesExplorerPageLoading():
                            return const Center(child: CircularProgressIndicator());
                          case FilesExplorerPageError():
                            return const Center(child: Text('Error'));
                        }
                      }
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

class _FileListView extends StatelessWidget {
  const _FileListView(this.loadedState);

  final FilesExplorerPageLoaded loadedState;

  @override
  Widget build(BuildContext context) {
    //  = loadedState.files
    final List<Directory> dirs = [];
    final List<File> files = [];

    for (final f in loadedState.files) {
      if (f is Directory) {
        dirs.add(f);
      } else if (f is File) {
        files.add(f);
      }
    }

    return ListView.builder(
      itemCount: dirs.length + files.length,
      itemBuilder: (context, index) {
        if (index < dirs.length) {
          return ListTile(
            leading: Icon(Icons.folder),
            title: Text(dirs[index].basename),
            onTap: () {
              context.read<FilesExplorerPageBloc>()
                  .add(FilesExplorerPageLoad(directory: dirs[index]));
            },
          );
        } else {
          final f = files[index - dirs.length];
          return ListTile(
            leading: Icon(Icons.file_present),
            title: Text(f.basename),
            onTap: () {
            },
            trailing: IconButton(
              onPressed: () {
                final bloc = context.read<FilesExplorerPageBloc>();
                f.deleteSync();
                bloc.add(FilesExplorerPageLoad());
              },
              icon: Icon(Icons.delete_outline),
            ),
          );
        }
      }
    );
  }
}

