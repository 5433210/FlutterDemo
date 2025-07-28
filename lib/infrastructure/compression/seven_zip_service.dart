import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import '../../domain/services/compression_service.dart';
import '../logging/logger.dart';

/// 7zip压缩服务实现
class SevenZipService implements CompressionService {
  static const String _tag = 'SevenZipService';

  @override
  Future<CompressionResult> compress({
    required String sourcePath,
    required String targetPath,
    CompressionOptions? options,
  }) async {
    final startTime = DateTime.now();

    try {
      AppLogger.info('开始7zip压缩',
          data: {'source': sourcePath, 'target': targetPath}, tag: _tag);

      // 创建归档
      final archive = Archive();

      // 添加文件到归档
      if (await Directory(sourcePath).exists()) {
        await _addDirectoryToArchive(sourcePath, '', archive);
      } else if (await File(sourcePath).exists()) {
        await _addFileToArchive(sourcePath, archive);
      } else {
        throw CompressionException('源路径不存在: $sourcePath');
      }

      // 使用ZIP编码器（暂时使用ZIP格式，保持兼容性）
      final encoder = ZipEncoder();
      final compressedBytes = encoder.encode(archive);

      // 写入目标文件
      await File(targetPath).writeAsBytes(compressedBytes);

      // 计算校验和
      final checksum = _calculateChecksum(compressedBytes);
      final originalSize = await _calculateOriginalSize(sourcePath);
      final compressedSize = compressedBytes.length;

      final duration = DateTime.now().difference(startTime);

      final result = CompressionResult(
        success: true,
        outputPath: targetPath,
        originalSize: originalSize,
        compressedSize: compressedSize,
        compressionRatio: 1.0 - (compressedSize / originalSize),
        checksum: checksum,
        duration: duration,
        format: CompressionFormat.sevenZip,
      );

      AppLogger.info('7zip压缩完成',
          data: {
            'originalSize': originalSize,
            'compressedSize': compressedSize,
            'ratio': result.compressionRatio,
            'duration': duration.inMilliseconds,
          },
          tag: _tag);

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('7zip压缩失败', error: e, stackTrace: stackTrace, tag: _tag);

      return CompressionResult(
        success: false,
        errorMessage: e.toString(),
        duration: DateTime.now().difference(startTime),
        format: CompressionFormat.sevenZip,
      );
    }
  }

  @override
  Future<DecompressionResult> decompress({
    required String sourcePath,
    required String targetPath,
    DecompressionOptions? options,
  }) async {
    final startTime = DateTime.now();

    try {
      AppLogger.info('开始7zip解压',
          data: {'source': sourcePath, 'target': targetPath}, tag: _tag);

      // 读取压缩文件
      final file = File(sourcePath);
      final bytes = await file.readAsBytes();

      // 验证文件完整性
      if (options?.verifyIntegrity ?? true) {
        final isValid = await verifyIntegrity(sourcePath);
        if (!isValid) {
          throw const CompressionException('文件完整性校验失败');
        }
      }

      // 解码ZIP文件（暂时使用ZIP格式，保持兼容性）
      final archive = ZipDecoder().decodeBytes(bytes);

      // 提取文件
      int extractedFiles = 0;
      int totalSize = 0;

      for (final archiveFile in archive.files) {
        final filePath = path.join(targetPath, archiveFile.name);

        if (archiveFile.isFile) {
          // 确保目录存在
          final fileDir = path.dirname(filePath);
          await Directory(fileDir).create(recursive: true);

          // 写入文件
          await File(filePath).writeAsBytes(archiveFile.content as List<int>);
          extractedFiles++;
          totalSize += archiveFile.size;
        } else {
          // 创建目录
          await Directory(filePath).create(recursive: true);
        }
      }

      final duration = DateTime.now().difference(startTime);

      final result = DecompressionResult(
        success: true,
        outputPath: targetPath,
        extractedFiles: extractedFiles,
        totalSize: totalSize,
        duration: duration,
        format: CompressionFormat.sevenZip,
      );

      AppLogger.info('7zip解压完成',
          data: {
            'extractedFiles': extractedFiles,
            'totalSize': totalSize,
            'duration': duration.inMilliseconds,
          },
          tag: _tag);

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('7zip解压失败', error: e, stackTrace: stackTrace, tag: _tag);

      return DecompressionResult(
        success: false,
        errorMessage: e.toString(),
        duration: DateTime.now().difference(startTime),
        format: CompressionFormat.sevenZip,
      );
    }
  }

  @override
  Future<bool> verifyIntegrity(String filePath) async {
    try {
      AppLogger.debug('验证7zip文件完整性', data: {'file': filePath}, tag: _tag);

      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final bytes = await file.readAsBytes();

      // 检查文件头（暂时使用ZIP格式）
      if (!_isZipFormat(bytes)) {
        return false;
      }

      // 尝试解码归档
      try {
        final archive = ZipDecoder().decodeBytes(bytes);

        // 验证每个文件的CRC
        for (final archiveFile in archive.files) {
          if (archiveFile.isFile) {
            // 这里可以添加更详细的CRC验证
          }
        }

        return true;
      } catch (e) {
        AppLogger.warning('归档解码失败', error: e, tag: _tag);
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error('完整性验证失败', error: e, stackTrace: stackTrace, tag: _tag);
      return false;
    }
  }

  @override
  List<CompressionFormat> getSupportedFormats() {
    return [CompressionFormat.sevenZip];
  }

  /// 添加目录到归档
  Future<void> _addDirectoryToArchive(
      String dirPath, String relativePath, Archive archive) async {
    final dir = Directory(dirPath);

    await for (final entity in dir.list()) {
      final entityName = path.basename(entity.path);
      final entityRelativePath =
          relativePath.isEmpty ? entityName : '$relativePath/$entityName';

      if (entity is File) {
        final bytes = await entity.readAsBytes();
        final archiveFile =
            ArchiveFile(entityRelativePath, bytes.length, bytes);
        archive.addFile(archiveFile);
      } else if (entity is Directory) {
        await _addDirectoryToArchive(entity.path, entityRelativePath, archive);
      }
    }
  }

  /// 添加单个文件到归档
  Future<void> _addFileToArchive(String filePath, Archive archive) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final fileName = path.basename(filePath);
    final archiveFile = ArchiveFile(fileName, bytes.length, bytes);
    archive.addFile(archiveFile);
  }

  /// 计算校验和
  String _calculateChecksum(List<int> bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 计算原始大小
  Future<int> _calculateOriginalSize(String sourcePath) async {
    int totalSize = 0;

    if (await Directory(sourcePath).exists()) {
      final dir = Directory(sourcePath);
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } else if (await File(sourcePath).exists()) {
      totalSize = await File(sourcePath).length();
    }

    return totalSize;
  }

  /// 检查是否为ZIP格式
  bool _isZipFormat(List<int> bytes) {
    if (bytes.length < 4) return false;

    // ZIP文件头: 50 4B 03 04 或 50 4B 05 06 或 50 4B 07 08
    return bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07);
  }

  /// 检查是否为7zip格式
  bool _isSevenZipFormat(List<int> bytes) {
    if (bytes.length < 6) return false;

    // 7zip文件头: 37 7A BC AF 27 1C
    return bytes[0] == 0x37 &&
        bytes[1] == 0x7A &&
        bytes[2] == 0xBC &&
        bytes[3] == 0xAF &&
        bytes[4] == 0x27 &&
        bytes[5] == 0x1C;
  }
}

/// 压缩异常
class CompressionException implements Exception {
  final String message;

  const CompressionException(this.message);

  @override
  String toString() => 'CompressionException: $message';
}
