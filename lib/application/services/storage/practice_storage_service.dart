import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// import '../../../infrastructure/logging/logger.dart';
import '../../../infrastructure/storage/storage_interface.dart';

/// 字帖练习存储服务
///
/// 职责:
/// 1. 字帖文件目录管理
/// 2. 字帖文件命名规则
/// 3. 缩略图存储和读取
class PracticeStorageService {
  final IStorage _storage;

  PracticeStorageService({
    required IStorage storage,
  }) : _storage = storage;

  /// 检查字帖封面缩略图是否存在
  Future<bool> coverThumbnailExists(String practiceId) async {
    try {
      final thumbnailPath = getPracticeCoverThumbnailPath(practiceId);
      return await _storage.fileExists(thumbnailPath);
    } catch (e, stack) {
      _handleError(
        '检查字帖封面缩略图是否存在失败',
        e,
        stack,
        data: {'practiceId': practiceId},
      );
      return false;
    }
  }

  /// 创建字帖目录结构
  Future<void> createPracticeDirectories(String practiceId) async {
    try {
      await _storage.createDirectory(getPracticePath(practiceId));
      await _storage.createDirectory(getPracticeCoverPath(practiceId));
    } catch (e, stack) {
      _handleError(
        '创建字帖目录失败',
        e,
        stack,
        data: {'practiceId': practiceId},
      );
    }
  }

  /// 删除字帖目录
  Future<void> deletePracticeDirectory(String practiceId) async {
    try {
      final practicePath = getPracticePath(practiceId);
      await _storage.deleteDirectory(practicePath);
    } catch (e, stack) {
      _handleError(
        '删除字帖目录失败',
        e,
        stack,
        data: {'practiceId': practiceId},
      );
    }
  }

  /// 确保字帖目录存在
  Future<void> ensurePracticeDirectoryExists(String practiceId) async {
    try {
      await _storage.ensureDirectoryExists(getPracticePath(practiceId));
      await _storage.ensureDirectoryExists(getPracticeCoverPath(practiceId));
    } catch (e, stack) {
      _handleError(
        '创建字帖目录失败',
        e,
        stack,
        data: {'practiceId': practiceId},
      );
    }
  }

  /// 获取应用文档目录路径
  Future<Directory> getAppDocumentsDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (e, stack) {
      _handleError('获取应用文档目录路径失败', e, stack);
      // 如果无法获取应用文档目录，则返回一个临时目录
      return Directory(path.join(_storage.getAppTempPath(), 'documents'));
    }
  }

  /// 获取字帖封面目录路径
  String getPracticeCoverPath(String practiceId) =>
      path.join(getPracticePath(practiceId), 'cover');

  /// 获取字帖封面缩略图路径
  String getPracticeCoverThumbnailPath(String practiceId) =>
      path.join(getPracticeCoverPath(practiceId), 'thumbnail.jpg');

  /// 获取字帖目录路径
  String getPracticePath(String practiceId) =>
      path.join(_storage.getAppDataPath(), 'practices', practiceId);

  /// 读取字帖封面缩略图
  Future<Uint8List?> loadCoverThumbnail(String practiceId) async {
    try {
      final thumbnailPath = getPracticeCoverThumbnailPath(practiceId);
      if (await _storage.fileExists(thumbnailPath)) {
        // 使用File API读取二进制数据
        final file = File(thumbnailPath);
        return await file.readAsBytes();
      }
      return null;
    } catch (e, stack) {
      _handleError(
        '读取字帖封面缩略图失败',
        e,
        stack,
        data: {'practiceId': practiceId},
      );
      return null;
    }
  }

  /// 保存字帖封面缩略图 (从 Uint8List)
  Future<void> saveCoverThumbnail(String practiceId, Uint8List bytes) async {
    try {
      await ensurePracticeDirectoryExists(practiceId);
      final targetPath = getPracticeCoverThumbnailPath(practiceId);
      // 使用File API写入二进制数据
      final file = File(targetPath);
      await file.writeAsBytes(bytes);
    } catch (e, stack) {
      _handleError(
        '保存字帖封面缩略图失败',
        e,
        stack,
        data: {'practiceId': practiceId, 'bytesLength': bytes.length},
      );
    }
  }

  /// 保存字帖封面缩略图 (从 File)
  Future<void> saveCoverThumbnailFromFile(String practiceId, File file) async {
    try {
      await ensurePracticeDirectoryExists(practiceId);
      final targetPath = getPracticeCoverThumbnailPath(practiceId);
      await _storage.copyFile(file.path, targetPath);
    } catch (e, stack) {
      _handleError(
        '保存字帖封面缩略图失败',
        e,
        stack,
        data: {'practiceId': practiceId, 'filePath': file.path},
      );
    }
  }

  /// 统一错误处理
  void _handleError(
    String message,
    Object error,
    StackTrace stack, {
    Map<String, dynamic>? data,
  }) {
    debugPrint('ERROR: $message - $error');
    // Full logging will be implemented when logger is properly set up
    // logger.e(
    //   message,
    //   error: error,
    //   stackTrace: stack,
    //   data: data,
    // );
  }
}
