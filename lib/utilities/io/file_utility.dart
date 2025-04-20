import 'dart:io';

import 'package:flutter_sing_tools/models/models.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:path_provider/path_provider.dart' as path_provider;

const _userAudioFolder = 'user_audio_folder';

class MyFileUtility {
  MyFileUtility._();

  static late MyDirectory _tempDir;
  static late MyDirectory _appDir;

  static Future<void> init() async {
    _tempDir = MyDirectory.from(await path_provider.getTemporaryDirectory());
    _appDir = MyDirectory.from(await path_provider.getApplicationDocumentsDirectory());

    (await getAudioDirectory()).create(recursive: true);
  }

  static MyDirectory getTemporaryDirectory() {
    return _tempDir;
  }

  static MyDirectory getApplicationDirectory() {
    return _appDir;
  }

  static MyDirectory getAudioDirectory() {
    return MyDirectory(path_pkg.join(_appDir.path, _userAudioFolder));
  }

  /// [fileName] includes extension
  static Future<File> buildAudioFilePath(String fileName) async {
    final dir = getAudioDirectory();
    return File(path_pkg.join(dir.path, fileName));
  }

  static String formatAppDirSubFilePath(FileSystemEntity file) {
    if (file.path.startsWith(_appDir.path)) {
      return file.path.substring(_appDir.path.length);
    } else {
      return file.path;
    }
  }
}