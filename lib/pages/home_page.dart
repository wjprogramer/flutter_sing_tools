import 'package:flutter/material.dart';
import 'package:flutter_sing_tools/pages/files_explorer/files_explorer_page.dart';
import 'package:flutter_sing_tools/pages/metronome_page.dart';
import 'package:flutter_sing_tools/pages/monitor_playback_page.dart';
import 'package:flutter_sing_tools/pages/pitch_detector/pitch_detector_page.dart';
import 'package:flutter_sing_tools/pages/recorder_page.dart';
import 'package:flutter_sing_tools/pages/tuning_fork/tuning_fork_page.dart';
import 'package:flutter_sing_tools/pages/volume_detect_page.dart';
import 'package:flutter_sing_tools/widgets/widgets.dart';

import 'audio_detector/audio_detector_page.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Singer'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MyTitle('一般'),
          MyButton(
            text: '音叉 (電子振盪器)',
            page: TuningForkPage(),
          ),
          MyButton(
            text: '節拍器',
            page: MetronomePage(),
          ),
          MyTitle('聲音檢測'),
          MyButton(
            text: '音量偵測',
            page: VolumeDetectPage(),
          ),
          MyButton(
            text: '音高檢測',
            page: PitchDetectorPage(),
          ),
          MyButton(
            text: '聲音檢測 (綜合)',
            page: AudioDetectorPage(),
          ),
          MyTitle('重播'),
          MyButton(
            text: '錄音',
            page: RecorderPage(),
          ),
          MyButton(
            text: '即時重播',
            page: MonitorPlaybackPage(),
          ),
          MyTitle('其他'),
          MyButton(
            text: '檔案瀏覽器',
            page: FilesExplorerPage(),
          ),
        ],
      ),
    );
  }
}