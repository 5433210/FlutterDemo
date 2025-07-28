import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import '../../../domain/interfaces/import_export_data_adapter.dart';
import '../../../infrastructure/logging/logger.dart';

/// ie_v1 → ie_v2 数据格式适配器
class ImportExportAdapterV1ToV2 implements ImportExportDataAdapter {
  @override
  String get sourceDataVersion => 'ie_v1';

  @override
  String get targetDataVersion => 'ie_v2';

  @override
  String get adapterName => 'ie_v1_to_v2';

  @override
  String getDescription() => '数据格式适配器：ie_v1 → ie_v2';

  @override
  bool supportsConversion(String fromVersion, String toVersion) {
    return fromVersion == sourceDataVersion && toVersion == targetDataVersion;
  }

  @override
  Future<ImportExportAdapterResult> preProcess(String exportFilePath) async {
    final startTime = DateTime.now();

    try {
      AppLogger.info('开始 ie_v1 → ie_v2 数据格式转换',
          data: {'filePath': exportFilePath}, tag: 'ImportExportAdapter');

      // 1. 验证源文件
      final sourceFile = File(exportFilePath);
      if (!await sourceFile.exists()) {
        return ImportExportAdapterResult.failure(
          message: '源文件不存在',
          errorCode: 'FILE_NOT_FOUND',
        );
      }

      // 2. 解析 ie_v1 格式数据
      final v1Data = await _parseV1Data(exportFilePath);
      if (v1Data == null) {
        return ImportExportAdapterResult.failure(
          message: '无法解析 ie_v1 格式数据',
          errorCode: 'PARSE_ERROR',
        );
      }

      // 3. 转换为 ie_v2 格式
      final v2Data = await _convertToV2Format(v1Data);

      // 4. 创建输出文件
      final outputPath = await _createV2OutputFile(v2Data, exportFilePath);

      final endTime = DateTime.now();
      final statistics = ImportExportAdapterStatistics(
        startTime: startTime,
        endTime: endTime,
        durationMs: endTime.difference(startTime).inMilliseconds,
        processedFiles: 1,
        convertedRecords: _countRecords(v1Data),
        originalSizeBytes: await sourceFile.length(),
        convertedSizeBytes: await File(outputPath).length(),
      );

      AppLogger.info('ie_v1 → ie_v2 转换完成',
          data: {'outputPath': outputPath}, tag: 'ImportExportAdapter');

      return ImportExportAdapterResult.success(
        message: 'ie_v1 → ie_v2 转换成功',
        outputPath: outputPath,
        statistics: statistics,
      );
    } catch (e, stackTrace) {
      AppLogger.error('ie_v1 → ie_v2 转换失败',
          error: e, stackTrace: stackTrace, tag: 'ImportExportAdapter');

      return ImportExportAdapterResult.failure(
        message: '转换过程中发生错误: ${e.toString()}',
        errorCode: 'CONVERSION_ERROR',
        errorDetails: {'exception': e.toString()},
      );
    }
  }

  @override
  Future<ImportExportAdapterResult> postProcess(String importedDataPath) async {
    try {
      AppLogger.info('开始 ie_v1 → ie_v2 后处理验证',
          data: {'dataPath': importedDataPath}, tag: 'ImportExportAdapter');

      // 1. 验证转换后的数据完整性
      final isValid = await _validateV2Data(importedDataPath);
      if (!isValid) {
        return ImportExportAdapterResult.failure(
          message: '转换后数据验证失败',
          errorCode: 'VALIDATION_FAILED',
        );
      }

      // 2. 更新索引文件（如果需要）
      await _updateIndexes(importedDataPath);

      AppLogger.info('ie_v1 → ie_v2 后处理完成', tag: 'ImportExportAdapter');

      return ImportExportAdapterResult.success(
        message: 'ie_v1 → ie_v2 后处理成功',
      );
    } catch (e, stackTrace) {
      AppLogger.error('ie_v1 → ie_v2 后处理失败',
          error: e, stackTrace: stackTrace, tag: 'ImportExportAdapter');

      return ImportExportAdapterResult.failure(
        message: '后处理过程中发生错误: ${e.toString()}',
        errorCode: 'POST_PROCESS_ERROR',
      );
    }
  }

  @override
  Future<bool> validate(String dataPath) async {
    try {
      // 验证文件是否存在
      final file = File(dataPath);
      if (!await file.exists()) {
        return false;
      }

      // 验证是否为有效的 ie_v2 格式
      return await _validateV2Data(dataPath);
    } catch (e) {
      AppLogger.error('ie_v1 → ie_v2 验证失败',
          error: e, tag: 'ImportExportAdapter');
      return false;
    }
  }

  /// 解析 ie_v1 格式数据
  Future<Map<String, dynamic>?> _parseV1Data(String filePath) async {
    try {
      // ie_v1 格式通常是简单的 JSON 文件
      final file = File(filePath);
      final content = await file.readAsString();
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('解析 ie_v1 数据失败', error: e, tag: 'ImportExportAdapter');
      return null;
    }
  }

  /// 转换为 ie_v2 格式
  Future<Map<String, dynamic>> _convertToV2Format(
      Map<String, dynamic> v1Data) async {
    // ie_v2 的主要改进：
    // 1. 添加 ZIP 压缩支持
    // 2. 增强元数据结构
    // 3. 添加文件校验
    // 4. 支持压缩级别控制

    final v2Data = Map<String, dynamic>.from(v1Data);

    // 更新元数据版本
    if (v2Data.containsKey('metadata')) {
      final metadata = v2Data['metadata'] as Map<String, dynamic>;
      metadata['dataFormatVersion'] = 'ie_v2';
      metadata['compressionLevel'] = 6;
      metadata['includeImages'] = true;
      metadata['imageQuality'] = 85;
      metadata['thumbnailGeneration'] = true;

      // 添加 ie_v2 特有的元数据字段
      metadata['formatSpecificData'] = {
        'compressionLevel': 6,
        'includeImages': true,
        'imageQuality': 85,
        'thumbnailGeneration': true,
      };
    }

    // 添加文件校验信息
    if (v2Data.containsKey('manifest')) {
      final manifest = v2Data['manifest'] as Map<String, dynamic>;
      if (manifest.containsKey('files')) {
        final files = manifest['files'] as List<dynamic>;
        for (final file in files) {
          if (file is Map<String, dynamic>) {
            // 为每个文件添加校验和（模拟）
            file['checksum'] = _generateMockChecksum(file['fileName'] ?? '');
            file['checksumAlgorithm'] = 'MD5';
          }
        }
      }
    }

    return v2Data;
  }

  /// 创建 ie_v2 格式输出文件
  Future<String> _createV2OutputFile(
      Map<String, dynamic> v2Data, String originalPath) async {
    final originalFile = File(originalPath);
    final directory = originalFile.parent;
    final baseName = path.basenameWithoutExtension(originalPath);

    // 根据原始文件扩展名确定输出文件扩展名
    final originalExtension = path.extension(originalPath).toLowerCase();
    String outputExtension;
    switch (originalExtension) {
      case '.cgw':
      case '.cgc':
      case '.cgb':
        outputExtension = originalExtension;
        break;
      default:
        outputExtension = '.zip'; // 向后兼容
    }

    final outputPath =
        path.join(directory.path, '${baseName}_v2$outputExtension');

    // 创建 ZIP 文件（ie_v2 的主要特性）
    final archive = Archive();

    // 添加主数据文件
    final jsonData = json.encode(v2Data);
    final jsonBytes = utf8.encode(jsonData);
    archive
        .addFile(ArchiveFile('export_data.json', jsonBytes.length, jsonBytes));

    // 添加清单文件
    if (v2Data.containsKey('manifest')) {
      final manifestData = json.encode(v2Data['manifest']);
      final manifestBytes = utf8.encode(manifestData);
      archive.addFile(
          ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));
    }

    // 压缩并写入文件
    final zipData = ZipEncoder().encode(archive);
    await File(outputPath).writeAsBytes(zipData);

    return outputPath;
  }

  /// 验证 ie_v2 格式数据
  Future<bool> _validateV2Data(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // 检查是否为 ZIP 文件
      if (!filePath.toLowerCase().endsWith('.zip')) {
        return false;
      }

      // 验证 ZIP 内容
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 检查必需文件
      final hasExportData =
          archive.files.any((f) => f.name == 'export_data.json');
      final hasManifest = archive.files.any((f) => f.name == 'manifest.json');

      if (!hasExportData || !hasManifest) {
        return false;
      }

      // 验证数据格式版本
      final exportDataFile =
          archive.files.firstWhere((f) => f.name == 'export_data.json');
      final content = utf8.decode(exportDataFile.content as List<int>);
      final data = json.decode(content) as Map<String, dynamic>;

      if (data['metadata']?['dataFormatVersion'] != 'ie_v2') {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 更新索引文件
  Future<void> _updateIndexes(String dataPath) async {
    // 在实际实现中，这里会更新相关的索引文件
    // 目前为模拟实现
    AppLogger.info('更新索引文件',
        data: {'dataPath': dataPath}, tag: 'ImportExportAdapter');
  }

  /// 计算记录数量
  int _countRecords(Map<String, dynamic> data) {
    int count = 0;
    if (data.containsKey('works')) {
      count += (data['works'] as List?)?.length ?? 0;
    }
    if (data.containsKey('characters')) {
      count += (data['characters'] as List?)?.length ?? 0;
    }
    return count;
  }

  /// 生成模拟校验和
  String _generateMockChecksum(String fileName) {
    // 简单的模拟校验和生成
    return fileName.hashCode.toRadixString(16).padLeft(8, '0');
  }
}
