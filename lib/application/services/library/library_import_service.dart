import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../domain/entities/library_item.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../presentation/utils/image_validator.dart' as validator;
import '../../repositories/library_repository_impl.dart';
import '../storage/library_storage_service.dart';

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

      // 检查文件是否已经存在于图库中
      final existingItem = await _findExistingItemByPath(filePath);
      if (existingItem != null) {
        AppLogger.info('文件已存在于图库中，跳过导入', data: {
          'filePath': filePath,
          'existingItemId': existingItem.id,
          'existingItemPath': existingItem.path,
        });
        return existingItem; // 返回已存在的项目而不是null，避免调用方认为导入失败
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

  /// 获取图片尺寸（修复Flutter 16384限制）
  Future<Size> _getImageSize(Uint8List bytes) async {
    try {
      // 🔧 关键修复：先尝试使用 image 包获取真实尺寸，绕过Flutter限制
      try {
        final image = validator.ImageValidator.decodeImage(bytes);
        if (image != null) {
          final realSize = Size(image.width.toDouble(), image.height.toDouble());
          AppLogger.debug('图库导入：使用 image 包检测到真实尺寸', data: {
            'width': image.width,
            'height': image.height,
            'method': 'image_package'
          });
          return realSize;
        }
      } catch (e) {
        AppLogger.debug('图库导入：image 包检测失败，降级到Flutter检测', data: {
          'error': e.toString()
        });
      }
      
      // 降级方案：使用Flutter的decodeImageFromList（可能受16384限制）
      final image = await decodeImageFromList(bytes);
      final flutterSize = Size(image.width.toDouble(), image.height.toDouble());
      
      AppLogger.debug('图库导入：使用 Flutter 检测尺寸', data: {
        'width': image.width,
        'height': image.height,
        'method': 'flutter_decode',
        'warning': '可能受到16384限制'
      });
      
      return flutterSize;
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

  /// 检查文件是否已经存在于图库中
  /// 通过比较绝对路径来检测重复
  Future<LibraryItem?> _findExistingItemByPath(String filePath) async {
    try {
      // 获取绝对路径用于比较
      final absolutePath = File(filePath).absolute.path;
      
      // 首先尝试通过数据库查询找到相同路径的项目
      // 由于路径可能以相对路径存储，我们需要查询所有项目并比较绝对路径
      final result = await _repository.getAll(
        page: 1,
        pageSize: 1000, // 使用较大的页面大小来减少查询次数
      );
      
      for (final item in result.items) {
        // 将存储的路径转换为绝对路径进行比较
        final itemAbsolutePath = File(item.path).absolute.path;
        if (itemAbsolutePath == absolutePath) {
          AppLogger.debug('找到重复文件', data: {
            'inputPath': filePath,
            'inputAbsolutePath': absolutePath,
            'existingItemPath': item.path,
            'existingItemAbsolutePath': itemAbsolutePath,
            'existingItemId': item.id,
          });
          return item;
        }
      }
      
      // 如果没有找到重复项，返回null
      return null;
    } catch (e) {
      AppLogger.warning('检查重复文件时出错', error: e, data: {
        'filePath': filePath,
      });
      // 如果检查失败，为了安全起见返回null，允许导入继续
      return null;
    }
  }
}
