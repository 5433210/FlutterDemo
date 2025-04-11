import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

import '../../../infrastructure/logging/logger.dart';
import '../../../infrastructure/storage/storage_interface.dart';

/// 字符图像存储服务
class CharacterStorageService {
  final IStorage _storage;

  CharacterStorageService(this._storage);

  /// 删除字符图像
  Future<void> deleteCharacterImage(String id) async {
    try {
      final dirPath = await _getCharacterDirectory(id);
      await _storage.deleteDirectory(dirPath);
    } catch (e, stack) {
      _handleError(
        '删除字符图像失败',
        e,
        stack,
        data: {'characterId': id},
      );
    }
  }

  /// 获取二值化图像路径
  Future<String> getBinaryImagePath(String id) async {
    return path.join(await _getCharacterDirectory(id), '$id-binary.png');
  }

  /// 获取字符图像文件大小
  Future<int> getCharacterImageSize(String path) async {
    try {
      return await _storage.getFileSize(path);
    } catch (e, stack) {
      _handleError(
        '获取字符图像大小失败',
        e,
        stack,
        data: {'path': path},
      );
      rethrow;
    }
  }

  /// 获取原始图像路径
  Future<String> getOriginalImagePath(String id) async {
    return path.join(await _getCharacterDirectory(id), '$id-original.png');
  }

  /// 获取方形二值化图像路径
  Future<String> getSquareBinaryPath(String id) async {
    return path.join(await _getCharacterDirectory(id), '$id-square-binary.png');
  }

  /// 获取方形SVG轮廓路径
  Future<String> getSquareSvgOutlinePath(String id) async {
    return path.join(
        await _getCharacterDirectory(id), '$id-square-outline.svg');
  }

  /// 获取方形透明PNG路径
  Future<String> getSquareTransparentPngPath(String id) async {
    return path.join(
        await _getCharacterDirectory(id), '$id-square-transparent.png');
  }

  /// 获取SVG轮廓路径
  Future<String> getSvgOutlinePath(String id) async {
    return path.join(await _getCharacterDirectory(id), '$id-outline.svg');
  }

  /// 获取缩略图路径
  Future<String> getThumbnailPath(String id) async {
    return path.join(await _getCharacterDirectory(id), '$id-thumbnail.jpg');
  }

  /// 获取透明PNG图像路径
  Future<String> getTransparentPngPath(String id) async {
    return path.join(await _getCharacterDirectory(id), '$id-transparent.png');
  }

  /// 检查字符图像是否存在
  Future<bool> hasCharacterImage(String path) async {
    try {
      return await _storage.fileExists(path);
    } catch (e, stack) {
      _handleError(
        '检查字符图像是否存在失败',
        e,
        stack,
        data: {'path': path},
      );
      return false;
    }
  }

  /// 列出字符所有文件路径
  Future<List<String>> listCharacterFiles(String id) async {
    try {
      final dirPath = await _getCharacterDirectory(id);
      return await _storage.listDirectoryFiles(dirPath);
    } catch (e, stack) {
      _handleError(
        '获取字符文件列表失败',
        e,
        stack,
        data: {'characterId': id},
      );
      return [];
    }
  }

  /// 保存二值化图像
  Future<void> saveBinaryImage(String id, Uint8List bytes) async {
    final filePath = await getBinaryImagePath(id);
    await _saveImage(filePath, bytes);
  }

  /// 保存原始图像
  Future<void> saveOriginalImage(String id, Uint8List bytes) async {
    final filePath = await getOriginalImagePath(id);
    await _saveImage(filePath, bytes);
  }

  /// 保存方形二值化图像
  Future<void> saveSquareBinary(String id, Uint8List bytes) async {
    final filePath = await getSquareBinaryPath(id);
    await _saveImage(filePath, bytes);
  }

  /// 保存方形SVG轮廓
  Future<void> saveSquareSvgOutline(String id, String svgContent) async {
    final filePath = await getSquareSvgOutlinePath(id);
    await _saveTextFile(filePath, svgContent);
  }

  /// 保存方形透明PNG
  Future<void> saveSquareTransparentPng(String id, Uint8List imageData) async {
    final filePath = await getSquareTransparentPngPath(id);
    await _saveImage(filePath, imageData);
  }

  /// 保存SVG轮廓
  Future<void> saveSvgOutline(String id, String svgContent) async {
    final filePath = await getSvgOutlinePath(id);
    await _saveTextFile(filePath, svgContent);
  }

  /// 保存缩略图
  Future<void> saveThumbnail(String id, Uint8List bytes) async {
    final filePath = await getThumbnailPath(id);
    await _saveImage(filePath, bytes);
  }

  /// 保存透明PNG图像（去背景）
  Future<void> saveTransparentPng(String id, Uint8List bytes) async {
    final filePath = await getTransparentPngPath(id);
    await _saveImage(filePath, bytes);
  }

  // 辅助方法: 获取字符目录
  Future<String> _getCharacterDirectory(String id) async {
    final baseDir = _storage.getAppDataPath();
    final charDir = path.join(baseDir, 'characters', id);
    if (!await _storage.directoryExists(charDir)) {
      await _storage.createDirectory(charDir);
    }
    // 确保目录存在
    return charDir;
  }

  /// 统一错误处理
  void _handleError(
    String message,
    Object error,
    StackTrace stack, {
    Map<String, dynamic>? data,
  }) {
    AppLogger.error(
      message,
      error: error,
      stackTrace: stack,
      tag: 'CharacterStorageService',
      data: data,
    );
  }

  // 辅助方法: 保存图像
  Future<void> _saveImage(String filePath, Uint8List bytes) async {
    try {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
    } catch (e) {
      AppLogger.error('保存图像文件失败', error: e, data: {'path': filePath});
      rethrow;
    }
  }

  // 辅助方法: 保存文本文件
  Future<void> _saveTextFile(String filePath, String content) async {
    try {
      final file = File(filePath);
      await file.writeAsString(content);
    } catch (e) {
      AppLogger.error('保存文本文件失败', error: e, data: {'path': filePath});
      rethrow;
    }
  }
}
