import 'dart:io';

import 'package:flutter/cupertino.dart';

sealed class MyFileSystemEntity<T extends FileSystemEntity> implements FileSystemEntity {
  MyFileSystemEntity._();

  static MyFileSystemEntity from(FileSystemEntity entity) {
    if (entity is File) {
      return MyFile(entity.path);
    } else if (entity is Directory) {
      return MyDirectory.from(entity);
    }
    throw UnsupportedError('Unsupported FileSystemEntity type: ${entity.runtimeType}');
  }

  @protected
  T get value;

  // region implements FileSystemEntity
  @override
  FileSystemEntity get absolute => value.absolute;

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) {
    return value.delete(recursive: recursive);
  }

  @override
  void deleteSync({bool recursive = false}) {
    return value.deleteSync(recursive: recursive);
  }

  @override
  Future<bool> exists() {
    return value.exists();
  }

  @override
  bool existsSync() {
    return value.existsSync();
  }

  @override
  bool get isAbsolute => value.isAbsolute;

  @override
  MyDirectory get parent => MyDirectory.from(value.parent);

  @override
  String get path => value.path;

  @override
  Future<FileSystemEntity> rename(String newPath) {
    return value.rename(newPath);
  }

  @override
  FileSystemEntity renameSync(String newPath) {
    return value.renameSync(newPath);
  }

  @override
  Future<String> resolveSymbolicLinks() {
    return value.resolveSymbolicLinks();
  }

  @override
  String resolveSymbolicLinksSync() {
    return value.resolveSymbolicLinksSync();
  }

  @override
  Future<FileStat> stat() {
    return value.stat();
  }

  @override
  FileStat statSync() {
    return value.statSync();
  }

  @override
  Uri get uri => value.uri;

  @override
  Stream<FileSystemEvent> watch({int events = FileSystemEvent.all, bool recursive = false}) {
    return value.watch(events: events, recursive: recursive);
  }
  // endregion
}

class MyFile extends MyFileSystemEntity<File> {
  MyFile._(this._file): super._();

  factory MyFile(String path) {
    return MyFile._(File(path));
  }

  final File _file;

  @override
  File get value => _file;
}

class MyDirectory extends MyFileSystemEntity<Directory> implements Directory {
  MyDirectory._(this._directory): super._();

  factory MyDirectory(String path) {
    return MyDirectory._(Directory(path));
  }

  factory MyDirectory.from(Directory dir) {
    return MyDirectory._(dir);
  }

  final Directory _directory;

  @override
  Directory get value => _directory;

  // region implements FileSystemEntity
  @override
  MyDirectory get absolute => MyDirectory.from(value.absolute);

  @override
  Future<MyDirectory> rename(String newPath) async {
    return MyDirectory.from(await value.rename(newPath));
  }

  @override
  MyDirectory renameSync(String newPath) {
    return MyDirectory.from(value.renameSync(newPath));
  }
  // endregion

  // region implements Directory
  @override
  Future<Directory> create({bool recursive = false}) {
    return value.create(recursive: recursive);
  }

  @override
  void createSync({bool recursive = false}) {
    return value.createSync(recursive: recursive);
  }

  @override
  Future<Directory> createTemp([String? prefix]) {
    return value.createTemp(prefix);
  }

  @override
  Directory createTempSync([String? prefix]) {
    return value.createTempSync(prefix);
  }

  @override
  Stream<MyFileSystemEntity> list({bool recursive = false, bool followLinks = true}) {
    return value
        .list(recursive: recursive, followLinks: followLinks)
        .map((e) => MyFileSystemEntity.from(e));
  }

  @override
  List<FileSystemEntity> listSync({bool recursive = false, bool followLinks = true}) {
    return value.listSync(recursive: recursive, followLinks: followLinks);
  }
  // endregion
}
