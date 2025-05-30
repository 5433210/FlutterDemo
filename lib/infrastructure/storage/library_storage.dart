import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import 'library_storage_interface.dart';
import 'storage_interface.dart';

/// 图库存储实现
class LibraryStorage implements ILibraryStorage {
  final IStorage _storage;
  final String _libraryRootName = 'library';

  LibraryStorage(this._storage);

  // IStorage 接口实现
  @override
  Future<void> copyFile(String sourcePath, String destinationPath) =>
      _storage.copyFile(sourcePath, destinationPath);

  @override
  Future<Directory> createDirectory(String path) =>
      _storage.createDirectory(path);

  @override
  Future<Directory> createTempDirectory() => _storage.createTempDirectory();

  @override
  Future<void> deleteDirectory(String path) => _storage.deleteDirectory(path);

  @override
  Future<void> deleteFile(String path) => _storage.deleteFile(path);

  @override
  Future<void> deleteLibraryItem(String itemId) async {
    final itemDir = await getLibraryItemDirectory(itemId);
    await _storage.deleteDirectory(itemDir.path);
  }

  @override
  Future<bool> directoryExists(String path) => _storage.directoryExists(path);

  @override
  Future<void> ensureDirectoryExists(String path) =>
      _storage.ensureDirectoryExists(path);

  @override
  Future<bool> fileExists(String path) => _storage.fileExists(path);

  @override
  String getAppCachePath() => _storage.getAppCachePath();

  @override
  String getAppDataPath() => _storage.getAppDataPath();

  @override
  String getAppTempPath() => _storage.getAppTempPath();

  @override
  Future<DateTime> getFileModifiedTime(String path) =>
      _storage.getFileModifiedTime(path);

  @override
  Future<int> getFileSize(String path) => _storage.getFileSize(path);

  @override
  Future<Directory> getLibraryItemDirectory(String itemId) async {
    final root = await getLibraryRoot();
    final itemPath = path.join(root.path, itemId);
    await _storage.ensureDirectoryExists(itemPath);
    return Directory(itemPath);
  }

  @override
  Future<FileInfo> getLibraryItemInfo(String itemId, String extension) async {
    final filePath = await getLibraryItemPath(itemId, extension);
    if (!await _storage.fileExists(filePath)) {
      throw StorageException('Library item file not found: $filePath');
    }

    final size = await _storage.getFileSize(filePath);
    final modifiedTime = await _storage.getFileModifiedTime(filePath);
    final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';

    return FileInfo(
      path: filePath,
      size: size,
      modifiedTime: modifiedTime,
      mimeType: mimeType,
    );
  }

  @override
  Future<String> getLibraryItemPath(String itemId, String extension) async {
    final itemDir = await getLibraryItemDirectory(itemId);
    return path.join(itemDir.path, 'original.$extension');
  }

  @override
  Future<Directory> getLibraryRoot() async {
    final rootPath = path.join(_storage.getAppDataPath(), _libraryRootName);
    await _storage.ensureDirectoryExists(rootPath);
    return Directory(rootPath);
  }

  @override
  Future<Directory> getThumbnailDirectory(String itemId) async {
    final itemDir = await getLibraryItemDirectory(itemId);
    final thumbPath = path.join(itemDir.path, 'thumbnails');
    await _storage.ensureDirectoryExists(thumbPath);
    return Directory(thumbPath);
  }

  @override
  Future<FileInfo> getThumbnailInfo(String itemId) async {
    final thumbPath = await getThumbnailPath(itemId);
    if (!await _storage.fileExists(thumbPath)) {
      throw StorageException('Thumbnail file not found: $thumbPath');
    }

    final size = await _storage.getFileSize(thumbPath);
    final modifiedTime = await _storage.getFileModifiedTime(thumbPath);
    final mimeType = lookupMimeType(thumbPath) ?? 'image/jpeg';

    return FileInfo(
      path: thumbPath,
      size: size,
      modifiedTime: modifiedTime,
      mimeType: mimeType,
    );
  }

  @override
  Future<String> getThumbnailPath(String itemId) async {
    final thumbDir = await getThumbnailDirectory(itemId);
    return path.join(thumbDir.path, 'thumbnail.jpg');
  }

  @override
  Future<List<String>> listDirectoryFiles(String path) =>
      _storage.listDirectoryFiles(path);

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) =>
      _storage.moveFile(sourcePath, destinationPath);

  @override
  Future<List<int>> readFile(String path) => _storage.readFile(path);

  @override
  Future<void> renameFile(String oldPath, String newPath) =>
      _storage.renameFile(oldPath, newPath);

  @override
  Future<String> saveLibraryItem(
      String itemId, List<int> bytes, String extension) async {
    final itemDir = await getLibraryItemDirectory(itemId);
    final fileName = 'original.$extension';
    final filePath = path.join(itemDir.path, fileName);
    await _storage.writeFile(filePath, bytes);
    return filePath;
  }

  @override
  Future<String> saveTempFile(String sourcePath) =>
      _storage.saveTempFile(sourcePath);

  @override
  Future<String> saveThumbnail(String itemId, List<int> bytes) async {
    final thumbDir = await getThumbnailDirectory(itemId);
    final thumbPath = path.join(thumbDir.path, 'thumbnail.jpg');
    await _storage.writeFile(thumbPath, bytes);
    return thumbPath;
  }

  @override
  Future<void> writeFile(String path, List<int> bytes) =>
      _storage.writeFile(path, bytes);
}
