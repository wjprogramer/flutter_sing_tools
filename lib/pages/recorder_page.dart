import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sing_tools/extensions/extensions.dart';
import 'package:flutter_sing_tools/utilities/utilities.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path_pkg;

const theSource = AudioSource.microphone;

/// ref: flutter_sound/example/simple_recorder (commit: fba4b05e)
class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});

  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  /// 是否在錄音完成後立即播放
  bool _playImmediatelyAfterRecord = true;

  @override
  void initState() {
    _mPlayer!.openPlayer().then((value) {
      safeSetState(() {
        _mPlayerIsInited = true;
      });
    });

    openTheRecorder().then((value) {
      safeSetState(() {
        _mRecorderIsInitialized = true;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _mPlayer!.closePlayer();
    _mPlayer = null;

    _mRecorder!.closeRecorder();
    _mRecorder = null;
    super.dispose();
  }

  // ------------------------------ This is the recorder stuff -----------------------------

  final Codec _codec = Codec.aacMP4;
  final String _mPath = 'tau_file.mp4';
  bool _mRecorderIsInitialized = false;

  /// Our player
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();

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
      audioSource: theSource,
    );
    safeSetState();
  }

  /// Stop the recorder
  void stopRecorder() async {
    await _mRecorder!.stopRecorder();
    //var url = value;
    _mplaybackReady = true;
    if (_playImmediatelyAfterRecord) {
      await play();
    }
    x();
    safeSetState();
  }

  void x() async {
    // final tmpFolder = MyFileUtility.getTemporaryDirectory();
    // final filePath = path_pkg.join(tmpFolder.path, _mPath);
    // print('===> exist ${File(filePath).existsSync()}');
    //
    // final newFile = await MyFileUtility.buildAudioFilePath('new_file.mp4')
    //   ..createSync();
    // await File(filePath).copy(newFile.path);
  }

// ----------------------------- This is the player stuff ---------------------------------

  bool _mplaybackReady = false;
  bool _mPlayerIsInited = false;
  Duration? _playerDuration;

  /// Begin to play the recorded sound
  Future<void> play() async {
    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder!.isStopped &&
        _mPlayer!.isStopped);
    _playerDuration = await _mPlayer!.startPlayer(
      fromURI: _mPath,
      whenFinished: () {
        safeSetState();
      },
    );
    safeSetState();
  }

  /// Stop the player
  void stopPlayer() async {
    await _mPlayer!.stopPlayer();
    safeSetState();
  }

// ----------------------------- UI --------------------------------------------

  VoidCallback? getRecorderFn() {
    if (!_mRecorderIsInitialized || !_mPlayer!.isStopped) {
      return null;
    }
    return _mRecorder!.isStopped ? record : stopRecorder;
  }

  VoidCallback? getPlaybackFn() {
    if (!_mPlayerIsInited || !_mplaybackReady || !_mRecorder!.isStopped) {
      return null;
    }
    return _mPlayer!.isStopped ? play : stopPlayer;
  }

  String _getStatusText() {
    if (_mRecorder!.isRecording) {
      return 'Recording';
    } else if (_mPlayer!.isPlaying) {
      return 'Playing';
    } else {
      return 'Stopped';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recorderFn = getRecorderFn();
    final playbackFn = getPlaybackFn();

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
                    child: Center(
                      child: Text(
                        _getStatusText(),
                        style: theme.textTheme.headlineLarge,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    value: _playImmediatelyAfterRecord,
                    onChanged: (v) {
                      setState(() {
                        _playImmediatelyAfterRecord = v;
                      });
                    },
                    title: Text('Play immediately after record', maxLines: 2),
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
                            _mPlayer!.isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 40,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: playbackFn,
                          child: Text(_mPlayer!.isPlaying ? 'Stop' : 'Play'),
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
