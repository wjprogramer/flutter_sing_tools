import 'dart:io';

import 'package:path/path.dart' as path_pkg;

extension FileSystemEntityX on FileSystemEntity {
  String get basename {
    return path_pkg.basename(path);
  }
}