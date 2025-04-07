import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sing_tools/extensions/extensions.dart';
import 'package:flutter_sing_tools/models/io/io.dart';
import 'package:flutter_sing_tools/utilities/utilities.dart';
import 'package:flutter_sound/flutter_sound.dart';

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
      child: Builder(builder: (context) {
        final currentDir = context.select<FilesExplorerPageBloc, MyDirectory?>(
            (m) => switch (m.state) {
                  FilesExplorerPageLoaded s => s.currentDir,
                  FilesExplorerPageLoading() => null,
                  FilesExplorerPageError() => null,
                });

        return PopScope(
          canPop:
              currentDir?.path == MyFileUtility.getApplicationDirectory().path,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop || currentDir == null) {
              return;
            }
            context
                .read<FilesExplorerPageBloc>()
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Builder(builder: (context) {
                    if (currentDir == null) {
                      return Text('/');
                    }
                    final displayPath =
                        MyFileUtility.formatAppDirSubFilePath(currentDir)
                            .trim();
                    return Text(
                      displayPath.isEmpty ? '/' : displayPath,
                      maxLines: 1,
                    );
                  }),
                ),
                Expanded(
                  child: Builder(builder: (context) {
                    final state = context.watch<FilesExplorerPageBloc>().state;

                    switch (state) {
                      case FilesExplorerPageLoaded():
                        return _FileListView(state);
                      case FilesExplorerPageLoading():
                        return const Center(child: CircularProgressIndicator());
                      case FilesExplorerPageError():
                        return const Center(child: Text('Error'));
                    }
                  }),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _FileListView extends StatelessWidget {
  const _FileListView(this.loadedState);

  final FilesExplorerPageLoaded loadedState;

  @override
  Widget build(BuildContext context) {
    final List<MyDirectory> dirs = [];
    final List<MyFile> files = [];

    for (final f in loadedState.files) {
      switch (f) {
        case MyFile():
          files.add(f);
          break;
        case MyDirectory():
          dirs.add(f);
          break;
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
              context
                  .read<FilesExplorerPageBloc>()
                  .add(FilesExplorerPageLoad(directory: dirs[index]));
            },
          );
        } else {
          final file = files[index - dirs.length];
          return _FileItem(file);
        }
      },
    );
  }
}

class _FileItem extends StatefulWidget {
  const _FileItem(this.file);

  final MyFile file;

  @override
  State<_FileItem> createState() => _FileItemState();
}

class _FileItemState extends State<_FileItem> {
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  bool _mPlayerIsInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    stopPlayer();
    _mPlayer?.closePlayer();
    _mPlayer = null;
    super.dispose();
  }

  Future<void> _init() async {
    await _mPlayer!.openPlayer();
    safeSetState(() {
      _mPlayerIsInitialized = true;
    });
  }

  Future<void> play() async {
    await _mPlayer!.startPlayer(
      fromURI: widget.file.path,
      codec: Codec.mp3,
      whenFinished: () {
        setState(() {});
      },
    );
    safeSetState(() {});
  }

  Future<void> stopPlayer() async {
    if (_mPlayer != null) {
      await _mPlayer!.stopPlayer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.file_present),
      title: Text(widget.file.basename),
      onTap: () async {
        final basename = widget.file.basename;
        final containsAudioTrack = basename.endsWith('.mp3') ||
            basename.endsWith('.mp4') ||
            basename.endsWith('.wav');
        if (!containsAudioTrack) {
          return;
        }
        if (_mPlayerIsInitialized) {
          await play();
        } else {
          await _init();
          await play();
        }
      },
      trailing: IconButton(
        onPressed: () {
          final bloc = context.read<FilesExplorerPageBloc>();
          widget.file.deleteSync();
          bloc.add(FilesExplorerPageLoad());
        },
        icon: Icon(Icons.delete_outline),
      ),
    );
  }
}
