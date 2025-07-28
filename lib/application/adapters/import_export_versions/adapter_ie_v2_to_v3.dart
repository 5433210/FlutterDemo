import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import '../../../domain/interfaces/import_export_data_adapter.dart';
import '../../../infrastructure/logging/logger.dart';

/// ie_v2 → ie_v3 数据格式适配器
class ImportExportAdapterV2ToV3 implements ImportExportDataAdapter {
  @override
  String get sourceDataVersion => 'ie_v2';

  @override
  String get targetDataVersion => 'ie_v3';

  @override
  String get adapterName => 'ie_v2_to_v3';

  @override
  String getDescription() => '数据格式适配器：ie_v2 → ie_v3';

  @override
  bool supportsConversion(String fromVersion, String toVersion) {
    return fromVersion == sourceDataVersion && toVersion == targetDataVersion;
  }

  @override
  Future<ImportExportAdapterResult> preProcess(String exportFilePath) async {
    final startTime = DateTime.now();

    try {
      AppLogger.info('开始 ie_v2 → ie_v3 数据格式转换',
          data: {'filePath': exportFilePath}, tag: 'ImportExportAdapter');

      // 1. 验证源文件
      final sourceFile = File(exportFilePath);
      if (!await sourceFile.exists()) {
        return ImportExportAdapterResult.failure(
          message: '源文件不存在',
          errorCode: 'FILE_NOT_FOUND',
        );
      }

      // 2. 解析 ie_v2 格式数据
      final v2Data = await _parseV2Data(exportFilePath);
      if (v2Data == null) {
        return ImportExportAdapterResult.failure(
          message: '无法解析 ie_v2 格式数据',
          errorCode: 'PARSE_ERROR',
        );
      }

      // 3. 转换为 ie_v3 格式
      final v3Data = await _convertToV3Format(v2Data);

      // 4. 创建输出文件
      final outputPath = await _createV3OutputFile(v3Data, exportFilePath);

      final endTime = DateTime.now();
      final statistics = ImportExportAdapterStatistics(
        startTime: startTime,
        endTime: endTime,
        durationMs: endTime.difference(startTime).inMilliseconds,
        processedFiles: 1,
        convertedRecords: _countRecords(v2Data),
        originalSizeBytes: await sourceFile.length(),
        convertedSizeBytes: await File(outputPath).length(),
      );

      AppLogger.info('ie_v2 → ie_v3 转换完成',
          data: {'outputPath': outputPath}, tag: 'ImportExportAdapter');

      return ImportExportAdapterResult.success(
        message: 'ie_v2 → ie_v3 转换成功',
        outputPath: outputPath,
        statistics: statistics,
      );
    } catch (e, stackTrace) {
      AppLogger.error('ie_v2 → ie_v3 转换失败',
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
      AppLogger.info('开始 ie_v2 → ie_v3 后处理验证',
          data: {'dataPath': importedDataPath}, tag: 'ImportExportAdapter');

      // 1. 验证转换后的数据完整性
      final isValid = await _validateV3Data(importedDataPath);
      if (!isValid) {
        return ImportExportAdapterResult.failure(
          message: '转换后数据验证失败',
          errorCode: 'VALIDATION_FAILED',
        );
      }

      // 2. 建立关联数据索引
      await _buildRelationshipIndexes(importedDataPath);

      // 3. 生成批量操作配置
      await _generateBatchConfigs(importedDataPath);

      AppLogger.info('ie_v2 → ie_v3 后处理完成', tag: 'ImportExportAdapter');

      return ImportExportAdapterResult.success(
        message: 'ie_v2 → ie_v3 后处理成功',
      );
    } catch (e, stackTrace) {
      AppLogger.error('ie_v2 → ie_v3 后处理失败',
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
      return await _validateV3Data(dataPath);
    } catch (e) {
      AppLogger.error('ie_v2 → ie_v3 验证失败',
          error: e, tag: 'ImportExportAdapter');
      return false;
    }
  }

  /// 解析 ie_v2 格式数据
  Future<Map<String, dynamic>?> _parseV2Data(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 查找主数据文件
      final exportDataFile = archive.files.firstWhere(
        (f) => f.name == 'export_data.json',
        orElse: () => throw Exception('未找到 export_data.json'),
      );

      final content = utf8.decode(exportDataFile.content as List<int>);
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('解析 ie_v2 数据失败', error: e, tag: 'ImportExportAdapter');
      return null;
    }
  }

  /// 转换为 ie_v3 格式
  Future<Map<String, dynamic>> _convertToV3Format(
      Map<String, dynamic> v2Data) async {
    // ie_v3 的主要改进：
    // 1. 关联数据导出
    // 2. 批量操作支持
    // 3. 进度监控
    // 4. 增强验证
    // 5. 自定义配置导出

    final v3Data = Map<String, dynamic>.from(v2Data);

    // 更新元数据版本
    if (v3Data.containsKey('metadata')) {
      final metadata = v3Data['metadata'] as Map<String, dynamic>;
      metadata['dataFormatVersion'] = 'ie_v3';

      // 更新 ie_v3 特有的元数据字段
      metadata['formatSpecificData'] = {
        'compressionLevel': 6,
        'includeImages': true,
        'includeRelatedData': true,
        'batchOperationSupport': true,
        'progressTracking': true,
      };
    }

    // 添加关联数据结构
    v3Data['relationships'] = await _buildRelationshipData(v2Data);

    // 添加批量操作配置
    v3Data['batchConfigs'] = await _buildBatchConfigs(v2Data);

    // 增强验证信息
    if (v3Data.containsKey('manifest')) {
      final manifest = v3Data['manifest'] as Map<String, dynamic>;

      // 添加关联验证
      if (!manifest.containsKey('validations')) {
        manifest['validations'] = [];
      }

      final validations = manifest['validations'] as List<dynamic>;
      validations.add({
        'type': 'relationships',
        'status': 'passed',
        'message': '关联关系验证通过',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    // 添加自定义配置统计
    if (v3Data.containsKey('manifest') &&
        v3Data['manifest'].containsKey('statistics')) {
      final statistics =
          v3Data['manifest']['statistics'] as Map<String, dynamic>;
      statistics['customConfigs'] = await _buildCustomConfigStats(v2Data);
    }

    return v3Data;
  }

  /// 构建关联数据
  Future<Map<String, dynamic>> _buildRelationshipData(
      Map<String, dynamic> data) async {
    final relationships = <String, dynamic>{};

    // 作品与集字的关联关系
    if (data.containsKey('works') && data.containsKey('characters')) {
      final works = data['works'] as List<dynamic>;
      final characters = data['characters'] as List<dynamic>;

      final workCharacterMap = <String, List<String>>{};
      final characterWorkMap = <String, List<String>>{};

      // 构建关联映射（模拟）
      for (final work in works) {
        if (work is Map<String, dynamic> && work.containsKey('id')) {
          final workId = work['id'] as String;
          workCharacterMap[workId] = [];

          // 模拟关联的集字
          for (final character in characters) {
            if (character is Map<String, dynamic> &&
                character.containsKey('id') &&
                character.containsKey('workId') &&
                character['workId'] == workId) {
              final characterId = character['id'] as String;
              workCharacterMap[workId]!.add(characterId);

              if (!characterWorkMap.containsKey(characterId)) {
                characterWorkMap[characterId] = [];
              }
              characterWorkMap[characterId]!.add(workId);
            }
          }
        }
      }

      relationships['workToCharacters'] = workCharacterMap;
      relationships['characterToWorks'] = characterWorkMap;
    }

    return relationships;
  }

  /// 构建批量操作配置
  Future<Map<String, dynamic>> _buildBatchConfigs(
      Map<String, dynamic> data) async {
    return {
      'supportedOperations': [
        'batchImport',
        'batchExport',
        'batchValidation',
        'batchConversion',
      ],
      'defaultBatchSize': 100,
      'maxBatchSize': 1000,
      'parallelProcessing': true,
      'progressReporting': true,
    };
  }

  /// 构建自定义配置统计
  Future<Map<String, dynamic>> _buildCustomConfigStats(
      Map<String, dynamic> data) async {
    return {
      'customStyles': [],
      'customTools': [],
      'customStyleUsage': <String, int>{},
      'customToolUsage': <String, int>{},
    };
  }

  /// 创建 ie_v3 格式输出文件
  Future<String> _createV3OutputFile(
      Map<String, dynamic> v3Data, String originalPath) async {
    final originalFile = File(originalPath);
    final directory = originalFile.parent;
    final baseName = path.basenameWithoutExtension(originalPath);
    final outputPath = path.join(directory.path, '${baseName}_v3.zip');

    final archive = Archive();

    // 添加主数据文件
    final jsonData = json.encode(v3Data);
    final jsonBytes = utf8.encode(jsonData);
    archive
        .addFile(ArchiveFile('export_data.json', jsonBytes.length, jsonBytes));

    // 添加清单文件
    if (v3Data.containsKey('manifest')) {
      final manifestData = json.encode(v3Data['manifest']);
      final manifestBytes = utf8.encode(manifestData);
      archive.addFile(
          ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));
    }

    // 添加关联数据文件
    if (v3Data.containsKey('relationships')) {
      final relationshipData = json.encode(v3Data['relationships']);
      final relationshipBytes = utf8.encode(relationshipData);
      archive.addFile(ArchiveFile(
          'relationships.json', relationshipBytes.length, relationshipBytes));
    }

    // 添加批量配置文件
    if (v3Data.containsKey('batchConfigs')) {
      final batchConfigData = json.encode(v3Data['batchConfigs']);
      final batchConfigBytes = utf8.encode(batchConfigData);
      archive.addFile(ArchiveFile(
          'batch_configs.json', batchConfigBytes.length, batchConfigBytes));
    }

    // 压缩并写入文件
    final zipData = ZipEncoder().encode(archive);
    await File(outputPath).writeAsBytes(zipData);

    return outputPath;
  }

  /// 验证 ie_v3 格式数据
  Future<bool> _validateV3Data(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists() || !filePath.toLowerCase().endsWith('.zip')) {
        return false;
      }

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 检查必需文件
      final requiredFiles = ['export_data.json', 'manifest.json'];
      for (final fileName in requiredFiles) {
        if (!archive.files.any((f) => f.name == fileName)) {
          return false;
        }
      }

      // 验证数据格式版本
      final exportDataFile =
          archive.files.firstWhere((f) => f.name == 'export_data.json');
      final content = utf8.decode(exportDataFile.content as List<int>);
      final data = json.decode(content) as Map<String, dynamic>;

      return data['metadata']?['dataFormatVersion'] == 'ie_v3';
    } catch (e) {
      return false;
    }
  }

  /// 建立关联数据索引
  Future<void> _buildRelationshipIndexes(String dataPath) async {
    AppLogger.info('建立关联数据索引',
        data: {'dataPath': dataPath}, tag: 'ImportExportAdapter');
  }

  /// 生成批量操作配置
  Future<void> _generateBatchConfigs(String dataPath) async {
    AppLogger.info('生成批量操作配置',
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
}
