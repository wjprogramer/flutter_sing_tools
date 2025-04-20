import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sing_tools/extensions/extensions.dart';
import 'package:flutter_sing_tools/utilities/io/file_utility.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:permission_handler/permission_handler.dart';

const _theSource = AudioSource.microphone;

/// ref: flutter_sound/example/simple_recorder (commit: fba4b05e)
class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});

  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  /// 是否在錄音完成後立即播放
  bool _playImmediatelyAfterRecord = true;

  final _fileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initPlayer();

    openTheRecorder().then((value) {
      safeSetState(() {
        _mRecorderIsInitialized = true;
      });
    });
  }

  @override
  void dispose() {
    _mPlayer.closePlayer();
    cancelPlayerSubscriptions();

    _mRecorder!.closeRecorder();
    _mRecorder = null;
    super.dispose();
  }

  Future<void> _initPlayer() async {
    await _mPlayer.openPlayer();
    _mPlayerSubscription = _mPlayer.onProgress!.listen((e) {
      setState(() {
        _playbackDisposition = e.position;
        pos = e.position.inMilliseconds;
      });
    });

    safeSetState(() {
      _mPlayerIsInited = true;
    });
  }

  // ------------------------------ This is the recorder stuff -----------------------------

  final Codec _codec = Codec.aacMP4;
  final String _mPath = 'tau_file.mp4';
  bool _mRecorderIsInitialized = false;

  /// Our player
  final FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();

  /// Our recorder
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();

  /// Request permission to record something and open the recorder
  Future<void> openTheRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _mRecorder!.openRecorder();
    _mRecorderIsInitialized = true;
  }

  /// Begin to record.
  /// This is our main function.
  /// We ask Flutter Sound to record to a File.
  Future<void> record() async {
    await _mRecorder!.startRecorder(
      toFile: _mPath,
      codec: _codec,
      audioSource: _theSource,
    );
    safeSetState();
  }

  /// Stop the recorder
  void stopRecorder() async {
    await _mRecorder!.stopRecorder();
    //var url = value;
    _playbackReady = true;
    if (_playImmediatelyAfterRecord) {
      await _play();
    }
    safeSetState();
  }

// ----------------------------- This is the player stuff ---------------------------------

  bool _playbackReady = false;
  bool _mPlayerIsInited = false;
  Duration? _playerDuration;
  Duration? _playbackDisposition;
  StreamSubscription? _mPlayerSubscription;
  int pos = 0;

  /// Begin to play the recorded sound
  Future<void> _play() async {
    assert(_mPlayerIsInited &&
        _playbackReady &&
        _mRecorder!.isStopped &&
        _mPlayer.isStopped);
    _playerDuration = await _mPlayer.startPlayer(
      fromURI: _mPath,
      whenFinished: () {
        safeSetState();
      },
    );
    safeSetState();
  }

  /// Stop the player
  void _stopPlayer() async {
    await _mPlayer.stopPlayer();
    safeSetState();
  }

  void cancelPlayerSubscriptions() {
    if (_mPlayerSubscription != null) {
      _mPlayerSubscription!.cancel();
      _mPlayerSubscription = null;
    }
  }

  // region Others

  Future<void> _onSave() async {
    try {
      final tmpFolder = MyFileUtility.getTemporaryDirectory();
      final filePath = path_pkg.join(tmpFolder.path, _mPath);

      final fileName = _fileNameController.text;
      final newFile = await MyFileUtility.buildAudioFilePath('$fileName.mp4')
        ..createSync();
      await File(filePath).copy(newFile.path);
    } catch (e) {
      _showDialog(
        titleText: 'Error',
        contentText: e.toString(),
      );
    }
  }

  void _showDialog({
    String? titleText,
    String? contentText,
  }) {
    callback() {
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text(titleText ?? ''),
            content: contentText == null ? null : Text(
              contentText,
            ),
          );
        },
      );
    }

    if (mounted) {
      callback();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => callback());
    }
  }

  // endregion

  // region UI

  VoidCallback? _getRecorderFn() {
    if (!_mRecorderIsInitialized || !_mPlayer.isStopped) {
      return null;
    }
    return _mRecorder!.isStopped ? record : stopRecorder;
  }

  VoidCallback? _getPlaybackFn() {
    if (!_mPlayerIsInited || !_playbackReady || !_mRecorder!.isStopped) {
      return null;
    }
    return _mPlayer.isStopped ? _play : _stopPlayer;
  }

  String _getStatusText() {
    if (_mRecorder!.isRecording) {
      return 'Recording';
    } else if (_mPlayer.isPlaying) {
      return 'Playing';
    } else {
      return 'Stopped';
    }
  }

  // endregion

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recorderFn = _getRecorderFn();
    final playbackFn = _getPlaybackFn();
    final playerDuration = _playerDuration;

    return Scaffold(
      appBar: AppBar(
        title: const Text('錄音'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: Divider.createBorderSide(context),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            _getStatusText(),
                            style: theme.textTheme.headlineLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (_playbackReady) ...[
                          if (playerDuration != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('Duration: $playerDuration'),
                            ), // ${_playbackDisposition}/
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _fileNameController,
                                ),
                              ),
                              IconButton(
                                onPressed: _onSave,
                                icon: Icon(Icons.save_outlined),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: Divider.createBorderSide(context),
                      ),
                    ),
                    child: SwitchListTile(
                      value: _playImmediatelyAfterRecord,
                      onChanged: (v) {
                        setState(() {
                          _playImmediatelyAfterRecord = v;
                        });
                      },
                      title: Text('Play immediately after record', maxLines: 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: recorderFn,
                          icon: Icon(
                            _mRecorder!.isRecording ? Icons.stop : Icons.mic,
                            size: 40,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: recorderFn,
                          child: Text(_mRecorder!.isRecording ? 'Stop' : 'Record'),
                        ),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: playbackFn,
                          icon: Icon(
                            _mPlayer.isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 40,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: playbackFn,
                          child: Text(_mPlayer.isPlaying ? 'Stop' : 'Play'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
