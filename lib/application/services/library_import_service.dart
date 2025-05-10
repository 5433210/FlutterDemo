import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../domain/entities/library_item.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/storage/library_storage_service.dart';
import '../repositories/library_repository_impl.dart';

/// 图库导入服务
class LibraryImportService {
  final LibraryRepositoryImpl _repository;
  final LibraryStorageService _storageService;
  final _uuid = const Uuid();

  /// 构造函数
  LibraryImportService(this._repository, this._storageService);

  /// 导入目录
  Future<List<LibraryItem>> importDirectory(
    String dirPath, {
    bool recursive = false,
    List<String> categories = const [],
  }) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        throw Exception('目录不存在：$dirPath');
      }

      final items = <LibraryItem>[];
      final files = await _listImageFiles(dir, recursive: recursive);

      for (final file in files) {
        try {
          final item = await importFile(file.path);
          if (item != null) {
            // 添加分类
            if (categories.isNotEmpty) {
              final updatedItem = item.copyWith(categories: categories);
              await _repository.update(updatedItem);
              items.add(updatedItem);
            } else {
              items.add(item);
            }
          }
        } catch (e) {
          AppLogger.warning('导入文件失败，继续处理下一个文件', error: e);
          continue;
        }
      }

      AppLogger.info('导入目录完成', data: {
        'dirPath': dirPath,
        'totalFiles': files.length,
        'successCount': items.length,
      });

      return items;
    } catch (e, stackTrace) {
      AppLogger.error('导入目录失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 导入单个文件
  Future<LibraryItem?> importFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在：$filePath');
      }

      // 读取文件信息
      final fileStats = await file.stat();
      final fileName = path.basename(filePath);
      final fileExtension =
          path.extension(filePath).toLowerCase().replaceAll('.', '');
      final mimeType = lookupMimeType(filePath);

      // 验证文件类型
      if (mimeType == null || !mimeType.startsWith('image/')) {
        throw Exception('不支持的文件类型：$mimeType');
      }

      // 读取文件数据
      final bytes = await file.readAsBytes();

      // 获取图片尺寸
      final imageSize = await _getImageSize(bytes);

      // 生成唯一ID
      final itemId = _uuid.v4();

      // 将文件保存到应用的存储目录
      final managedFilePath =
          await _storageService.saveLibraryItem(itemId, bytes, fileExtension);

      // 生成缩略图
      final thumbnail = await _repository.generateThumbnail(bytes);
      if (thumbnail == null) {
        throw Exception('生成缩略图失败');
      }

      // 保存缩略图到应用的存储目录
      await _storageService.saveThumbnail(itemId, thumbnail);

      // 创建图库项目
      final item = LibraryItem(
        id: itemId,
        fileName: fileName,
        type: 'image',
        format: fileExtension,
        path: managedFilePath, // 使用应用管理的文件路径
        width: imageSize.width.toInt(),
        height: imageSize.height.toInt(),
        fileSize: fileStats.size,
        tags: [],
        categories: [],
        metadata: {},
        isFavorite: false,
        thumbnail: thumbnail,
        fileCreatedAt: fileStats.changed, // Use file creation time
        fileUpdatedAt: fileStats.modified, // Use file modification time
      );

      // 保存到数据库
      await _repository.add(item);
      AppLogger.info('导入文件成功', data: {
        'fileName': fileName,
        'fileSize': fileStats.size,
        'mimeType': mimeType,
        'managedPath': managedFilePath,
      });

      return item;
    } catch (e, stackTrace) {
      AppLogger.error('导入文件失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 获取图片尺寸
  Future<Size> _getImageSize(Uint8List bytes) async {
    try {
      final image = await decodeImageFromList(bytes);
      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (e) {
      AppLogger.warning('获取图片尺寸失败', error: e);
      return Size.zero;
    }
  }

  /// 列出目录中的所有图片文件
  Future<List<File>> _listImageFiles(Directory dir,
      {bool recursive = false}) async {
    final files = <File>[];
    final stream = dir.list(recursive: recursive);

    await for (final entity in stream) {
      if (entity is File) {
        final mimeType = lookupMimeType(entity.path);
        if (mimeType != null && mimeType.startsWith('image/')) {
          files.add(entity);
        }
      }
    }

    return files;
  }
}
