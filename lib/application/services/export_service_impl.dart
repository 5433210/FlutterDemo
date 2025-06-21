import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import '../../domain/models/character/character_entity.dart';
import '../../domain/models/import_export/export_data_model.dart';
import '../../domain/models/import_export/import_export_exceptions.dart';
import '../../domain/models/work/work_entity.dart';
import '../../domain/models/work/work_image.dart';
import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../domain/repositories/work_image_repository.dart';
import '../../domain/repositories/work_repository.dart';
import '../../domain/services/export_service.dart';
import '../../infrastructure/logging/logger.dart';

/// 导出服务的具体实现
class ExportServiceImpl implements ExportService {
  final WorkRepository _workRepository;
  final WorkImageRepository _workImageRepository;
  final CharacterRepository _characterRepository;

  ExportServiceImpl({
    required WorkRepository workRepository,
    required WorkImageRepository workImageRepository,
    required CharacterRepository characterRepository,
    required PracticeRepository practiceRepository, // 保留参数但不存储
  }) : _workRepository = workRepository,
       _workImageRepository = workImageRepository,
       _characterRepository = characterRepository;

  @override
  Future<ExportManifest> exportWorks(
    List<String> workIds,
    ExportType exportType,
    ExportOptions options,
    String targetPath, {
    ExportProgressCallback? progressCallback,
  }) async {
    final exportId = _generateExportId();
    
    try {
      progressCallback?.call(0.0, '开始导出作品...', {'exportId': exportId});
      
      // 简化实现：创建基本的导出数据
      final works = <WorkEntity>[];
      final workImages = <WorkImage>[];
      final characters = <CharacterEntity>[];
      
      // 模拟数据查询
      for (final workId in workIds) {
        final work = await _workRepository.get(workId);
        if (work != null) {
          works.add(work);
        }
        
        final images = await _workImageRepository.getAllByWorkId(workId);
        workImages.addAll(images);
        
        if (exportType == ExportType.worksWithCharacters) {
          final workCharacters = await _characterRepository.getByWorkId(workId);
          characters.addAll(workCharacters);
        }
      }
      
      if (works.isEmpty) {
        throw const ExportException(
          ImportExportErrorCodes.exportDataQueryFailed,
          '未找到要导出的作品数据',
        );
      }
      
      progressCallback?.call(0.5, '生成导出数据...', null);
      
      // 创建导出数据模型
      final exportData = _createExportDataModel(
        works, 
        workImages, 
        characters, 
        options,
        exportType: exportType,
      );
      
      progressCallback?.call(0.8, '创建导出文件...', null);
      
      // 创建简化的导出文件
      await _createExportFile(exportData, targetPath);
      
      progressCallback?.call(1.0, '导出完成', {'outputPath': targetPath});
      
      AppLogger.info(
        '作品导出完成',
        data: {
          'exportId': exportId,
          'workCount': works.length,
          'characterCount': characters.length,
          'outputPath': targetPath,
          'operation': 'export_works',
        },
        tag: 'export',
      );
      
      return exportData.manifest;
      
    } catch (e, stackTrace) {
      AppLogger.error(
        '作品导出失败',
        error: e,
        stackTrace: stackTrace,
        data: {
          'exportId': exportId,
          'workIds': workIds,
          'operation': 'export_works',
        },
        tag: 'export',
      );
      
      if (e is ExportException) {
        rethrow;
      } else {
        throw ExportException(
          ImportExportErrorCodes.systemResourceExhausted,
          '导出过程中发生未知错误: ${e.toString()}',
        );
      }
    }
  }

  @override
  Future<ExportManifest> exportCharacters(
    List<String> characterIds,
    ExportType exportType,
    ExportOptions options,
    String targetPath, {
    ExportProgressCallback? progressCallback,
  }) async {
    final exportId = _generateExportId();
    
    try {
      progressCallback?.call(0.0, '开始导出集字...', {'exportId': exportId});
      
      // 简化实现：创建基本的导出数据
      final characters = <CharacterEntity>[];
      final works = <WorkEntity>[];
      final workImages = <WorkImage>[];
      
      // 模拟数据查询
      for (final characterId in characterIds) {
        final character = await _characterRepository.get(characterId);
        if (character != null) {
          characters.add(character);
          
          if (exportType == ExportType.charactersWithWorks && character.workId != null) {
             final work = await _workRepository.get(character.workId!);
             if (work != null) {
               final isDuplicate = works.any((w) => w.id == work.id);
               if (!isDuplicate) {
                 works.add(work);
                 final images = await _workImageRepository.getAllByWorkId(work.id);
                 workImages.addAll(images);
               }
             }
          }
        }
      }
      
      if (characters.isEmpty) {
        throw const ExportException(
          ImportExportErrorCodes.exportDataQueryFailed,
          '未找到要导出的集字数据',
        );
      }
      
      progressCallback?.call(0.5, '生成导出数据...', null);
      
      // 创建导出数据模型
      final exportData = _createExportDataModel(
        works, 
        workImages, 
        characters, 
        options,
        exportType: exportType,
      );
      
      progressCallback?.call(0.8, '创建导出文件...', null);
      
      // 创建简化的导出文件
      await _createExportFile(exportData, targetPath);
      
      progressCallback?.call(1.0, '导出完成', {'outputPath': targetPath});
      
      AppLogger.info(
        '集字导出完成',
        data: {
          'exportId': exportId,
          'characterCount': characters.length,
          'workCount': works.length,
          'outputPath': targetPath,
          'operation': 'export_characters',
        },
        tag: 'export',
      );
      
      return exportData.manifest;
      
    } catch (e, stackTrace) {
      AppLogger.error(
        '集字导出失败',
        error: e,
        stackTrace: stackTrace,
        data: {
          'exportId': exportId,
          'characterIds': characterIds,
          'operation': 'export_characters',
        },
        tag: 'export',
      );
      
      if (e is ExportException) {
        rethrow;
      } else {
        throw ExportException(
          ImportExportErrorCodes.systemResourceExhausted,
          '导出过程中发生未知错误: ${e.toString()}',
        );
      }
    }
  }

  @override
  Future<ExportManifest> exportFullData(
    ExportOptions options,
    String targetPath, {
    List<String>? workIds,
    List<String>? characterIds,
    ExportProgressCallback? progressCallback,
  }) async {
    throw UnimplementedError('完整数据导出功能尚未实现');
  }

  @override
  Future<List<ExportValidation>> validateExportData(ExportDataModel exportData) async {
    final validations = <ExportValidation>[];
    
    // 验证作品数据
    for (final work in exportData.works) {
      if (work.id.isEmpty) {
        validations.add(ExportValidation(
          type: ExportValidationType.dataIntegrity,
          status: ValidationStatus.failed,
          message: '作品ID不能为空',
          details: {'workId': work.id},
          timestamp: DateTime.now(),
        ));
      }
    }
    
    // 验证集字数据
    for (final character in exportData.characters) {
      if (character.id.isEmpty) {
        validations.add(ExportValidation(
          type: ExportValidationType.dataIntegrity,
          status: ValidationStatus.failed,
          message: '集字ID不能为空',
          details: {'characterId': character.id},
          timestamp: DateTime.now(),
        ));
      }
    }
    
    return validations;
  }

  @override
  Future<int> estimateExportSize(
    List<String> workIds,
    List<String> characterIds,
    ExportOptions options,
  ) async {
    // 简单估算：每个作品约1MB，每个集字约100KB
    final worksSize = workIds.length * 1024 * 1024;
    final charactersSize = characterIds.length * 100 * 1024;
    return worksSize + charactersSize;
  }

  @override
  Future<bool> checkStorageSpace(String targetPath, int requiredSize) async {
    try {
      final directory = Directory(path.dirname(targetPath));
      if (!await directory.exists()) {
        return false;
      }
      
      // 简化实现：假设总是有足够空间
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> cancelExport([String? operationId]) async {
    AppLogger.info(
      '取消导出操作',
      data: {
        'operationId': operationId,
        'operation': 'cancel_export',
      },
      tag: 'export',
    );
  }

  @override
  List<String> getSupportedFormats() {
    return ['zip', 'json'];
  }

  @override
  ExportOptions getDefaultOptions() {
    return const ExportOptions(
      type: ExportType.worksOnly,
      format: ExportFormat.zip,
      includeImages: true,
      includeMetadata: true,
      compressData: true,
      version: '1.0',
      includeRelatedData: true,
      compressionLevel: 6,
      generateThumbnails: true,
    );
  }

  // ===================
  // Private Helper Methods
  // ===================

  String _generateExportId() {
    return 'export_${DateTime.now().millisecondsSinceEpoch}';
  }

  ExportDataModel _createExportDataModel(
    List<WorkEntity> works,
    List<WorkImage> workImages,
    List<CharacterEntity> characters,
    ExportOptions options, {
    ExportType exportType = ExportType.worksOnly,
  }) {
    final metadata = ExportMetadata(
      version: '1.0',
      platform: 'flutter',
      exportTime: DateTime.now(),
      options: options,
      exportType: exportType,
      appVersion: '1.0.0',
      compatibility: const CompatibilityInfo(
        minSupportedVersion: '1.0.0',
        recommendedVersion: '1.0.0',
      ),
    );

    final summary = ExportSummary(
      workCount: works.length,
      characterCount: characters.length,
      imageCount: workImages.length,
      totalSize: 0,
    );

    final statistics = ExportStatistics(
      customConfigs: const CustomConfigStatistics(),
    );

    final fileInfos = <ExportFileInfo>[];
    
    // 添加作品文件信息
    for (final work in works) {
      fileInfos.add(ExportFileInfo(
        fileName: 'data.json',
        filePath: 'works/${work.id}/data.json',
        fileType: ExportFileType.data,
        fileSize: 0,
        checksum: '',
      ));
    }
    
    // 添加集字文件信息
    for (final character in characters) {
      fileInfos.add(ExportFileInfo(
        fileName: 'data.json',
        filePath: 'characters/${character.id}/data.json',
        fileType: ExportFileType.data,
        fileSize: 0,
        checksum: '',
      ));
    }

    final manifest = ExportManifest(
      summary: summary,
      files: fileInfos,
      statistics: statistics,
      validations: [],
    );

    return ExportDataModel(
      metadata: metadata,
      works: works,
      workImages: workImages,
      characters: characters,
      manifest: manifest,
    );
  }

  Future<void> _createExportFile(ExportDataModel exportData, String targetPath) async {
    if (exportData.metadata.options.format == ExportFormat.json) {
      // 创建JSON文件
      final file = File(targetPath);
      await file.writeAsString(jsonEncode(exportData.toJson()));
    } else {
      // 创建ZIP文件
      final archive = Archive();
      
      // 添加主数据文件
      final dataJson = jsonEncode(exportData.toJson());
      final dataFile = ArchiveFile('export_data.json', dataJson.length, dataJson.codeUnits);
      archive.addFile(dataFile);
      
      // 添加清单文件
      final manifestJson = jsonEncode(exportData.manifest.toJson());
      final manifestFile = ArchiveFile('manifest.json', manifestJson.length, manifestJson.codeUnits);
      archive.addFile(manifestFile);
      
      // 压缩并保存
      final encoder = ZipEncoder();
      final compressedBytes = encoder.encode(archive);
      
      final file = File(targetPath);
      await file.writeAsBytes(compressedBytes);
    }
  }
} 