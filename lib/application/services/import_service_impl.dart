import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import '../../domain/models/character/character_entity.dart';
import '../../domain/models/import_export/export_data_model.dart';
import '../../domain/models/import_export/import_data_model.dart';
import '../../domain/models/import_export/import_export_exceptions.dart';
import '../../domain/models/import_export/model_factories.dart';
import '../../domain/models/work/work_entity.dart';
import '../../domain/models/work/work_image.dart';
import '../../domain/repositories/work_image_repository.dart';
import '../../domain/repositories/work_repository.dart';
import '../../domain/repositories/character_repository.dart';
import '../../domain/services/import_service.dart';
import '../../infrastructure/logging/logger.dart';
import '../../utils/path_privacy_helper.dart';

/// 导入服务的具体实现
class ImportServiceImpl implements ImportService {
  final WorkImageRepository? _workImageRepository;
  final WorkRepository? _workRepository;
  final CharacterRepository? _characterRepository;
  final String? _storageBasePath;

  const ImportServiceImpl({
    WorkImageRepository? workImageRepository,
    WorkRepository? workRepository,
    CharacterRepository? characterRepository,
    String? storageBasePath,
  }) : _workImageRepository = workImageRepository,
       _workRepository = workRepository,
       _characterRepository = characterRepository,
       _storageBasePath = storageBasePath;

  @override
  Future<ImportValidationResult> validateImportFile(
    String filePath,
    ImportOptions options,
  ) async {
    AppLogger.info(
      '验证导入文件',
      data: {
        'filePath': filePath,
        'operation': 'validate_import_file',
      },
      tag: 'import',
    );

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ModelFactories.createFailedValidationResult('文件不存在');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        return ModelFactories.createFailedValidationResult('文件为空');
      }

      // 基础文件扩展名检查
      if (!filePath.toLowerCase().endsWith('.zip')) {
        return ModelFactories.createFailedValidationResult('不支持的文件格式，请选择ZIP文件');
      }

      // 尝试打开ZIP文件进行基本验证
      try {
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        
        // 检查是否包含必需的文件
        final hasExportData = archive.files.any((f) => f.name == 'export_data.json');
        final hasManifest = archive.files.any((f) => f.name == 'manifest.json');
        
        if (!hasExportData) {
          return ModelFactories.createFailedValidationResult('缺少导出数据文件');
        }
        
        if (!hasManifest) {
          return ModelFactories.createFailedValidationResult('缺少清单文件');
        }
        
      } catch (e) {
        return ModelFactories.createFailedValidationResult('ZIP文件格式无效: ${e.toString()}');
      }

      return ModelFactories.createSuccessValidationResult();
      
    } catch (e, stackTrace) {
      AppLogger.error(
        '验证导入文件失败',
        data: {
          'filePath': filePath,
          'error': e.toString(),
        },
        tag: 'import',
        error: e,
        stackTrace: stackTrace,
      );
      return ModelFactories.createFailedValidationResult('文件验证失败: ${e.toString()}');
    }
  }

  @override
  Future<ImportDataModel> parseImportData(
    String filePath,
    ImportOptions options,
  ) async {
    AppLogger.info(
      '解析导入数据',
      data: {
        'filePath': filePath,
        'operation': 'parse_import_data',
      },
      tag: 'import',
    );

    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // 查找导出数据文件
      final exportDataFile = archive.files.firstWhere(
        (f) => f.name == 'export_data.json',
        orElse: () => throw const ImportException(
          ImportExportErrorCodes.importFileCorrupted,
          '找不到导出数据文件',
        ),
      );
      
      // 解析JSON数据 - 使用增强的UTF-8解码处理
      final jsonString = _decodeJsonFromBytes(exportDataFile.content as List<int>);
      
      // 修复JSON中的无效转义字符
      final fixedJsonString = _fixInvalidEscapeCharacters(jsonString);
      
      final jsonData = jsonDecode(fixedJsonString) as Map<String, dynamic>;
      
      // 创建导出数据模型
      final exportData = ExportDataModel.fromJson(jsonData);
      
      // 将WorkImage中的相对路径转换为绝对路径
      final convertedWorkImages = exportData.workImages.map((image) => _convertWorkImagePaths(image)).toList();
      
      // 创建转换后的导出数据模型
      final convertedExportData = exportData.copyWith(workImages: convertedWorkImages);
      
      // 创建导入数据模型
      return ModelFactories.createBasicImportData(
        exportData: convertedExportData,
        options: options,
      );
      
    } catch (e, stackTrace) {
      AppLogger.error(
        '解析导入数据失败',
        data: {
          'filePath': filePath,
          'error': e.toString(),
        },
        tag: 'import',
        error: e,
        stackTrace: stackTrace,
      );
      
      if (e is ImportException) {
        rethrow;
      } else {
        throw ImportException(
          ImportExportErrorCodes.importFileCorrupted,
          '解析导入数据失败: ${e.toString()}',
        );
      }
    }
  }

  @override
  Future<List<ImportConflictInfo>> checkConflicts(ImportDataModel importData) async {
    AppLogger.info(
      '检查数据冲突',
      data: {
        'workCount': importData.exportData.works.length,
        'characterCount': importData.exportData.characters.length,
        'operation': 'check_conflicts',
      },
      tag: 'import',
    );

    // 简化实现：暂时返回空列表，表示无冲突
    // TODO: 实现实际的冲突检测逻辑
    return [];
  }

  @override
  Future<ImportResult> performImport(
    ImportDataModel importData, {
    String? sourceFilePath,
    ImportProgressCallback? progressCallback,
    ConflictResolutionCallback? conflictCallback,
  }) async {
    final transactionId = 'import_${DateTime.now().millisecondsSinceEpoch}';
    
    AppLogger.info(
      '执行导入',
      data: {
        'transactionId': transactionId,
        'workCount': importData.exportData.works.length,
        'characterCount': importData.exportData.characters.length,
        'sourceFilePath': sourceFilePath,
        'operation': 'perform_import',
      },
      tag: 'import',
    );

    final startTime = DateTime.now();
    
    try {
      // 步骤1：准备导入
      progressCallback?.call(0.1, '准备导入...', {'step': 'preparing'});
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 步骤2：导入作品数据
      progressCallback?.call(0.3, '导入作品数据...', {'step': 'importing_works'});
      final worksImported = await _importWorks(importData.exportData.works);
      await Future.delayed(const Duration(milliseconds: 200));
      
      // 步骤3：导入集字数据
      progressCallback?.call(0.6, '导入集字数据...', {'step': 'importing_characters'});
      final charactersImported = await _importCharacters(importData.exportData.characters);
      await Future.delayed(const Duration(milliseconds: 200));
      
      // 步骤4：导入图片数据（需要原始文件路径来提取图片文件）
      progressCallback?.call(0.7, '导入图片数据...', {'step': 'importing_images'});
      final imagesImported = await _importImages(importData.exportData.workImages, sourceFilePath);
      
      // 步骤4.1：保存WorkImage数据到数据库
      if (imagesImported > 0 && _workImageRepository != null) {
        progressCallback?.call(0.75, '保存图片数据到数据库...', {'step': 'saving_image_data'});
        await _saveWorkImagesToDatabase(importData.exportData.workImages);
      }
      
      await Future.delayed(const Duration(milliseconds: 200));
      
      // 步骤5：导入集字图片数据
      progressCallback?.call(0.85, '导入集字图片...', {'step': 'importing_character_images'});
      final characterImagesImported = await _importCharacterImages(importData.exportData.characters, sourceFilePath);
      await Future.delayed(const Duration(milliseconds: 200));
      
      // 步骤6：验证封面文件（如果导入的ZIP文件包含封面，则无需重新生成）
      progressCallback?.call(0.9, '验证作品封面...', {'step': 'verifying_covers'});
      await _verifyWorkCovers(importData.exportData.works, importData.exportData.workImages);
      await Future.delayed(const Duration(milliseconds: 200));
      
      // 处理自定义字段
      await _processCustomFields(
        importData.exportData.works,
        importData.exportData.characters,
      );
      
      // 步骤6：完成导入
      progressCallback?.call(1.0, '导入完成', {'step': 'completed'});
      
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      final result = ImportResult(
        success: true,
        transactionId: transactionId,
        importedWorks: worksImported,
        importedCharacters: charactersImported,
        importedImages: imagesImported,
        duration: duration,
      );
      
      AppLogger.info(
        '导入完成',
        data: {
          'transactionId': transactionId,
          'importedWorks': worksImported,
          'importedCharacters': charactersImported,
          'importedImages': imagesImported,
          'importedCharacterImages': characterImagesImported,
          'duration': duration,
          'operation': 'perform_import_completed',
        },
        tag: 'import',
      );
      
      return result;
      
    } catch (e, stackTrace) {
      AppLogger.error(
        '导入失败',
        data: {
          'transactionId': transactionId,
          'error': e.toString(),
          'operation': 'perform_import_failed',
        },
        tag: 'import',
        error: e,
        stackTrace: stackTrace,
      );
      
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      return ImportResult(
        success: false,
        transactionId: transactionId,
        errors: [e.toString()],
        duration: duration,
      );
    }
  }

  @override
  Future<RollbackResult> rollbackImport(
    String transactionId, {
    ImportProgressCallback? progressCallback,
  }) async {
    AppLogger.info(
      '开始回滚导入',
      data: {
        'transactionId': transactionId,
        'operation': 'rollback_import',
      },
      tag: 'import',
    );
    
    try {
      // 检查事务是否存在（这里需要实际的事务存储机制）
      // 暂时使用模拟实现
      
      // 创建回滚结果
      final rollbackResult = RollbackResult(
        success: true,
        rolledBackWorks: 0,
        rolledBackCharacters: 0,
        rolledBackImages: 0,
        errors: [],
        duration: 0,
      );
      
      // 如果有实际的事务管理器实例，应该这样调用：
      // final transactionManager = _getTransactionManager(transactionId);
      // if (transactionManager != null) {
      //   final rollbackResult = await transactionManager.rollback();
      //   return rollbackResult;
      // }
      
      AppLogger.info(
        '导入回滚完成',
        data: {
          'transactionId': transactionId,
          'success': rollbackResult.success,
          'errors': rollbackResult.errors,
          'operation': 'rollback_import_completed',
        },
        tag: 'import',
      );
      
      return rollbackResult;
      
    } catch (e, stackTrace) {
      AppLogger.error(
        '导入回滚失败',
        data: {
          'transactionId': transactionId,
          'error': e.toString(),
          'operation': 'rollback_import_failed',
        },
        tag: 'import',
        error: e,
        stackTrace: stackTrace,
      );
      
      return RollbackResult(
        success: false,
        errors: [e.toString()],
        duration: 0,
      );
    }
  }

  @override
  Future<ImportPreview> previewImport(ImportDataModel importData) async {
    AppLogger.info(
      '预览导入',
      data: {
        'workCount': importData.exportData.works.length,
        'characterCount': importData.exportData.characters.length,
        'operation': 'preview_import',
      },
      tag: 'import',
    );
    
    // 创建预览项目
    final workPreviews = importData.exportData.works.map((work) => 
      ImportPreviewItem(
        id: work.id,
        title: work.title,
        type: EntityType.work,
        action: ImportAction.create,
      )
    ).toList();
    
    final characterPreviews = importData.exportData.characters.map((character) => 
      ImportPreviewItem(
        id: character.id,
        title: character.character,
        type: EntityType.character,
        action: ImportAction.create,
      )
    ).toList();
    
    final imagePreviews = importData.exportData.workImages.map((image) => 
      ImportPreviewItem(
        id: image.id,
        title: 'Image ${image.id}',
        type: EntityType.workImage,
        action: ImportAction.create,
      )
    ).toList();
    
    final summary = ImportPreviewSummary(
      totalItems: workPreviews.length + characterPreviews.length + imagePreviews.length,
      newItems: workPreviews.length + characterPreviews.length + imagePreviews.length,
      estimatedTime: await estimateImportTime(importData),
    );
    
    return ImportPreview(
      works: workPreviews,
      characters: characterPreviews,
      images: imagePreviews,
      summary: summary,
    );
  }

  @override
  Future<int> estimateImportTime(ImportDataModel importData) async {
    // 简单的时间估算：每个项目大约需要0.1秒
    final workCount = importData.exportData.works.length;
    final characterCount = importData.exportData.characters.length;
    final imageCount = importData.exportData.workImages.length;
    
    return ((workCount + characterCount + imageCount) * 0.1).round();
  }

  @override
  Future<ImportRequirements> checkImportRequirements(ImportDataModel importData) async {
    AppLogger.info(
      '检查导入要求',
      data: {
        'operation': 'check_import_requirements',
      },
      tag: 'import',
    );
    
    // 简化实现：假设总是满足要求
    return const ImportRequirements(
      satisfied: true,
      requiredStorage: 0,
      availableStorage: 1000000000, // 1GB
    );
  }

  @override
  Future<void> cancelImport([String? operationId]) async {
    AppLogger.info(
      '取消导入',
      data: {
        'operationId': operationId,
        'operation': 'cancel_import',
      },
      tag: 'import',
    );
    
    // TODO: 实现取消导入逻辑
  }

  @override
  Future<List<ImportHistoryRecord>> getImportHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    AppLogger.info(
      '获取导入历史',
      data: {
        'limit': limit,
        'offset': offset,
        'operation': 'get_import_history',
      },
      tag: 'import',
    );
    
    try {
      // 这里应该从数据库或持久化存储中获取导入历史
      // 暂时返回模拟数据，实际实现需要：
      // 1. 创建import_history表
      // 2. 在每次导入完成后记录历史
      // 3. 从数据库查询历史记录
      
      final mockHistory = <ImportHistoryRecord>[
        ImportHistoryRecord(
          id: 'import_${DateTime.now().millisecondsSinceEpoch}',
          fileName: 'example_export.zip',
          importTime: DateTime.now().subtract(const Duration(hours: 1)),
          success: true,
          importedItems: 30, // 总计：5作品 + 10集字 + 15图片
          duration: 5000,
        ),
      ];
      
      // 应用分页
      final startIndex = offset;
      final endIndex = (offset + limit).clamp(0, mockHistory.length);
      
      if (startIndex >= mockHistory.length) {
        return [];
      }
      
      return mockHistory.sublist(startIndex, endIndex);
      
    } catch (e, stackTrace) {
      AppLogger.error(
        '获取导入历史失败',
        data: {
          'limit': limit,
          'offset': offset,
          'error': e.toString(),
          'operation': 'get_import_history_failed',
        },
        tag: 'import',
        error: e,
        stackTrace: stackTrace,
      );
      
      return [];
    }
  }

  @override
  Future<void> cleanupTempFiles([int olderThanDays = 7]) async {
    AppLogger.info(
      '清理临时文件',
      data: {
        'olderThanDays': olderThanDays,
        'operation': 'cleanup_temp_files',
      },
      tag: 'import',
    );
    
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
      int deletedCount = 0;
      int totalSize = 0;
      
      // 临时文件可能存在的目录列表
      final tempDirs = [
        'temp',
        'import_temp',
        'extraction_temp',
      ];
      
      for (final tempDirName in tempDirs) {
        if (_storageBasePath != null) {
          final tempDirPath = path.join(_storageBasePath!, tempDirName);
          final tempDir = Directory(tempDirPath);
          
          if (await tempDir.exists()) {
            await for (final entity in tempDir.list(recursive: true)) {
              if (entity is File) {
                try {
                  final stat = await entity.stat();
                  if (stat.modified.isBefore(cutoffDate)) {
                    final fileSize = await entity.length();
                    await entity.delete();
                    deletedCount++;
                    totalSize += fileSize;
                    
                    AppLogger.debug(
                      '删除临时文件',
                      data: {
                        'filePath': entity.path.sanitizedForLogging,
                        'fileSize': fileSize,
                        'modifiedTime': stat.modified.toIso8601String(),
                      },
                      tag: 'import',
                    );
                  }
                } catch (e) {
                  AppLogger.warning(
                    '删除临时文件失败',
                    data: {
                      'filePath': entity.path.sanitizedForLogging,
                      'error': e.toString(),
                    },
                    tag: 'import',
                  );
                }
              }
            }
          }
        }
      }
      
      AppLogger.info(
        '临时文件清理完成',
        data: {
          'deletedCount': deletedCount,
          'totalSize': totalSize,
          'olderThanDays': olderThanDays,
          'operation': 'cleanup_temp_files_completed',
        },
        tag: 'import',
      );
      
    } catch (e, stackTrace) {
      AppLogger.error(
        '临时文件清理失败',
        data: {
          'olderThanDays': olderThanDays,
          'error': e.toString(),
          'operation': 'cleanup_temp_files_failed',
        },
        tag: 'import',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  List<String> getSupportedFormats() {
    return ['zip'];
  }

  @override
  ImportOptions getDefaultOptions() {
    return ModelFactories.createBasicImportOptions();
  }

  // ===================
  // Private Helper Methods
  // ===================

  Future<int> _importWorks(List<WorkEntity> works) async {
    AppLogger.debug(
      '导入作品',
      data: {
        'count': works.length,
        'operation': 'import_works',
      },
      tag: 'import',
    );
    
    int importedCount = 0;
    
    try {
      for (final work in works) {
        try {
          // 如果有WorkRepository，使用实际的数据库操作
          if (_workRepository != null) {
            await _workRepository!.create(work);
            importedCount++;
          } else {
            // 模拟导入（用于测试）
            AppLogger.debug(
              '模拟导入作品',
              data: {
                'workId': work.id,
                'title': work.title,
                'operation': 'mock_import_work',
              },
              tag: 'import',
            );
            importedCount++;
          }
        } catch (e) {
          AppLogger.warning(
            '导入单个作品失败',
            data: {
              'workId': work.id,
              'title': work.title,
              'error': e.toString(),
              'operation': 'import_single_work_failed',
            },
            tag: 'import',
          );
        }
      }
      
      AppLogger.info(
        '作品导入完成',
        data: {
          'totalWorks': works.length,
          'importedCount': importedCount,
          'operation': 'import_works_completed',
        },
        tag: 'import',
      );
      
    } catch (e, stackTrace) {
      AppLogger.error(
        '作品导入失败',
        error: e,
        stackTrace: stackTrace,
        data: {
          'totalWorks': works.length,
          'importedCount': importedCount,
          'operation': 'import_works_failed',
        },
        tag: 'import',
      );
    }
    
    return importedCount;
  }

  Future<int> _importCharacters(List<CharacterEntity> characters) async {
    AppLogger.debug(
      '导入集字',
      data: {
        'count': characters.length,
        'operation': 'import_characters',
      },
      tag: 'import',
    );
    
    int importedCount = 0;
    
    try {
      for (final character in characters) {
        try {
          // 如果有CharacterRepository，使用实际的数据库操作
          if (_characterRepository != null) {
            await _characterRepository!.create(character);
            importedCount++;
          } else {
            // 模拟导入（用于测试）
            AppLogger.debug(
              '模拟导入集字',
              data: {
                'characterId': character.id,
                'character': character.character,
                'operation': 'mock_import_character',
              },
              tag: 'import',
            );
            importedCount++;
          }
        } catch (e) {
          AppLogger.warning(
            '导入单个集字失败',
            data: {
              'characterId': character.id,
              'character': character.character,
              'error': e.toString(),
              'operation': 'import_single_character_failed',
            },
            tag: 'import',
          );
        }
      }
      
      AppLogger.info(
        '集字导入完成',
        data: {
          'totalCharacters': characters.length,
          'importedCount': importedCount,
          'operation': 'import_characters_completed',
        },
        tag: 'import',
      );
      
    } catch (e, stackTrace) {
      AppLogger.error(
        '集字导入失败',
        error: e,
        stackTrace: stackTrace,
        data: {
          'totalCharacters': characters.length,
          'importedCount': importedCount,
          'operation': 'import_characters_failed',
        },
        tag: 'import',
      );
    }
    
    return importedCount;
  }

  /// 导入集字图片文件
  Future<int> _importCharacterImages(List<CharacterEntity> characters, String? sourceFilePath) async {
    AppLogger.debug(
      '导入集字图片',
      data: {
        'count': characters.length,
        'sourceFilePath': sourceFilePath,
        'operation': 'import_character_images',
      },
      tag: 'import',
    );
    
    if (sourceFilePath == null) {
      AppLogger.warning(
        '缺少源文件路径，无法提取集字图片文件',
        data: {
          'characterCount': characters.length,
          'operation': 'import_character_images',
        },
        tag: 'import',
      );
      return 0;
    }
    
    int extractedCount = 0;
    
    try {
      // 读取ZIP文件
      final file = File(sourceFilePath);
      if (!await file.exists()) {
        AppLogger.error(
          '源文件不存在',
          data: {
            'sourceFilePath': sourceFilePath,
            'operation': 'import_character_images',
          },
          tag: 'import',
        );
        return 0;
      }
      
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // 提取集字图片文件
      for (final character in characters) {
        try {
          final characterId = character.id;
          
          // 定义所有可能的集字图片文件类型
          final imageTypes = [
            'original',
            'binary', 
            'transparent',
            'thumbnail',
            'square-binary',
            'square-transparent',
            'outline',
            'square-outline',
          ];
          
          int characterFilesExtracted = 0;
          
          for (final imageType in imageTypes) {
            final extracted = await _extractCharacterImageFile(archive, character, imageType);
            if (extracted) {
              characterFilesExtracted++;
            }
          }
          
          if (characterFilesExtracted > 0) {
            extractedCount++;
            AppLogger.debug(
              '集字图片文件提取成功',
              data: {
                'characterId': characterId,
                'character': character.character,
                'extractedFiles': characterFilesExtracted,
                'operation': 'extract_character_images',
              },
              tag: 'import',
            );
          }
          
        } catch (e) {
          AppLogger.warning(
            '提取集字图片文件失败',
            data: {
              'characterId': character.id,
              'character': character.character,
              'error': e.toString(),
              'operation': 'extract_character_images',
            },
            tag: 'import',
          );
        }
      }
      
      AppLogger.info(
        '集字图片导入完成',
        data: {
          'totalCharacters': characters.length,
          'extractedCount': extractedCount,
          'operation': 'import_character_images_completed',
        },
        tag: 'import',
      );
      
    } catch (e, stackTrace) {
      AppLogger.error(
        '集字图片导入失败',
        error: e,
        stackTrace: stackTrace,
        data: {
          'sourceFilePath': sourceFilePath,
          'characterCount': characters.length,
          'operation': 'import_character_images_failed',
        },
        tag: 'import',
      );
    }
    
    return extractedCount;
  }

  /// 提取单个集字图片文件
  Future<bool> _extractCharacterImageFile(Archive archive, CharacterEntity character, String imageType) async {
    try {
      final characterId = character.id;
      
      // 根据文件类型确定扩展名
      String extension;
      switch (imageType) {
        case 'outline':
        case 'square-outline':
          extension = '.svg';
          break;
        case 'thumbnail':
          extension = '.jpg';
          break;
        default:
          extension = '.png';
      }
      
      // 构建归档内的文件路径
      final archivePath = 'characters/$characterId/$imageType$extension';
      
      // 构建目标路径
      final targetPath = _convertToAbsolutePath('characters/$characterId/$characterId-$imageType$extension');
      
      AppLogger.debug(
        '尝试提取集字图片文件',
        data: {
          'archivePath': archivePath,
          'targetPath': targetPath,
          'imageType': imageType,
          'operation': 'extract_character_image_file',
        },
        tag: 'import',
      );
      
      // 在归档中查找文件
      final archiveFile = archive.files.firstWhere(
        (f) => f.name == archivePath,
        orElse: () {
          AppLogger.debug(
            '在归档中找不到集字图片文件（可能不存在）',
            data: {
              'requestedPath': archivePath,
              'operation': 'extract_character_image_file',
            },
            tag: 'import',
          );
          throw Exception('文件不存在: $archivePath');
        },
      );
      
      // 确保目标目录存在
      final targetFile = File(targetPath);
      final targetDir = Directory(path.dirname(targetPath));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
        AppLogger.debug(
          '创建集字目标目录',
          data: {
            'targetDir': targetDir.path,
            'operation': 'extract_character_image_file',
          },
          tag: 'import',
        );
      }
      
      // 写入文件
      await targetFile.writeAsBytes(archiveFile.content as List<int>);
      
      // 验证文件是否成功写入
      final writtenFileExists = await targetFile.exists();
      final writtenFileSize = writtenFileExists ? await targetFile.length() : 0;
      
      AppLogger.info(
        '集字图片文件提取成功',
        data: {
          'characterId': characterId,
          'character': character.character,
          'imageType': imageType,
          'archivePath': archivePath,
          'targetPath': targetPath,
          'archiveFileSize': archiveFile.content.length,
          'writtenFileSize': writtenFileSize,
          'fileExists': writtenFileExists,
          'operation': 'extract_character_image_file',
        },
        tag: 'import',
      );
      
      return writtenFileExists;
      
    } catch (e) {
      // 这里使用debug级别，因为某些文件可能确实不存在
      AppLogger.debug(
        '提取集字图片文件失败或文件不存在',
        data: {
          'characterId': character.id,
          'character': character.character,
          'imageType': imageType,
          'error': e.toString(),
          'operation': 'extract_character_image_file',
        },
        tag: 'import',
      );
      return false;
    }
  }

  /// 导入图片数据
  Future<int> _importImages(List<WorkImage> workImages, String? sourceFilePath) async {
    if (sourceFilePath == null) {
      AppLogger.warning(
        '源文件路径为空，跳过图片导入',
        data: {
          'operation': 'import_images',
        },
        tag: 'import',
      );
      return 0;
    }
    
    AppLogger.info(
      '开始导入图片',
      data: {
        'imageCount': workImages.length,
        'sourceFilePath': sourceFilePath,
        'operation': 'import_images',
      },
      tag: 'import',
    );
    
    try {
      final file = File(sourceFilePath);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      int importedCount = 0;
      
      for (final image in workImages) {
        try {
          // 提取三种类型的图片文件
          final originalExtracted = await _extractImageFile(archive, image, 'original');
          final importedExtracted = await _extractImageFile(archive, image, 'imported');
          final thumbnailExtracted = await _extractImageFile(archive, image, 'thumbnail');
          
          if (originalExtracted && importedExtracted && thumbnailExtracted) {
            importedCount++;
            AppLogger.debug(
              '图片文件提取成功',
              data: {
                'imageId': image.id,
                'workId': image.workId,
                'operation': 'import_images',
              },
              tag: 'import',
            );
          } else {
            AppLogger.warning(
              '图片文件提取不完整',
              data: {
                'imageId': image.id,
                'workId': image.workId,
                'originalExtracted': originalExtracted,
                'importedExtracted': importedExtracted,
                'thumbnailExtracted': thumbnailExtracted,
                'operation': 'import_images',
              },
              tag: 'import',
            );
          }
          
        } catch (e) {
          AppLogger.error(
            '提取图片文件失败',
            error: e,
            data: {
              'imageId': image.id,
              'workId': image.workId,
              'operation': 'import_images',
            },
            tag: 'import',
          );
        }
      }
      
      // 提取作品封面文件
      await _extractWorkCoverFiles(archive, workImages);
      
      AppLogger.info(
        '图片导入完成',
        data: {
          'totalImages': workImages.length,
          'importedCount': importedCount,
          'operation': 'import_images',
        },
        tag: 'import',
      );
      
      return importedCount;
      
    } catch (e) {
      AppLogger.error(
        '导入图片失败',
        error: e,
        data: {
          'sourceFilePath': sourceFilePath,
          'operation': 'import_images',
        },
        tag: 'import',
      );
      return 0;
    }
  }

  /// 提取作品封面文件
  Future<void> _extractWorkCoverFiles(Archive archive, List<WorkImage> workImages) async {
    // 按作品分组图片
    final workIds = <String>{};
    for (final image in workImages) {
      workIds.add(image.workId);
    }
    
    AppLogger.info(
      '开始提取作品封面文件',
      data: {
        'workCount': workIds.length,
        'operation': 'extract_work_cover_files',
      },
      tag: 'import',
    );
    
    int extractedCovers = 0;
    
    for (final workId in workIds) {
      try {
        // 提取封面导入图
        final coverImportedExtracted = await _extractWorkCoverFile(archive, workId, 'imported');
        
        // 提取封面缩略图
        final coverThumbnailExtracted = await _extractWorkCoverFile(archive, workId, 'thumbnail');
        
        if (coverImportedExtracted && coverThumbnailExtracted) {
          extractedCovers++;
          AppLogger.info(
            '作品封面文件提取成功',
            data: {
              'workId': workId,
              'operation': 'extract_work_cover_files',
            },
            tag: 'import',
          );
        } else {
          AppLogger.warning(
            '作品封面文件提取不完整',
            data: {
              'workId': workId,
              'coverImportedExtracted': coverImportedExtracted,
              'coverThumbnailExtracted': coverThumbnailExtracted,
              'operation': 'extract_work_cover_files',
            },
            tag: 'import',
          );
        }
        
      } catch (e) {
        AppLogger.error(
          '提取作品封面文件失败',
          error: e,
          data: {
            'workId': workId,
            'operation': 'extract_work_cover_files',
          },
          tag: 'import',
        );
      }
    }
    
    AppLogger.info(
      '作品封面文件提取完成',
      data: {
        'totalWorks': workIds.length,
        'extractedCovers': extractedCovers,
        'operation': 'extract_work_cover_files',
      },
      tag: 'import',
    );
  }

  /// 提取单个作品封面文件
  Future<bool> _extractWorkCoverFile(Archive archive, String workId, String type) async {
    try {
      // 确保存储基础路径存在
      if (_storageBasePath == null) {
        AppLogger.warning(
          '缺少存储基础路径，无法提取封面文件',
          data: {
            'workId': workId,
            'type': type,
            'operation': 'extract_work_cover_file',
          },
          tag: 'import',
        );
        return false;
      }
      
      // 构建归档内的文件路径和目标路径
      String archivePath;
      String targetPath;
      
      switch (type) {
        case 'imported':
          archivePath = 'covers/$workId/imported.png';
          targetPath = path.join(_storageBasePath!, 'works', workId, 'cover', 'imported.png');
          break;
        case 'thumbnail':
          archivePath = 'covers/$workId/thumbnail.jpg';
          targetPath = path.join(_storageBasePath!, 'works', workId, 'cover', 'thumbnail.jpg');
          break;
        default:
          AppLogger.warning(
            '未知的封面文件类型',
            data: {
              'type': type,
              'workId': workId,
              'operation': 'extract_work_cover_file',
            },
            tag: 'import',
          );
          return false;
      }
      
      AppLogger.debug(
        '尝试提取封面文件',
        data: {
          'archivePath': archivePath,
          'targetPath': targetPath,
          'type': type,
          'operation': 'extract_work_cover_file',
        },
        tag: 'import',
      );
      
      // 在归档中查找文件
      final archiveFile = archive.files.firstWhere(
        (f) => f.name == archivePath,
        orElse: () {
          AppLogger.debug(
            '在归档中找不到封面文件，可能是旧版本导出文件',
            data: {
              'requestedPath': archivePath,
              'operation': 'extract_work_cover_file',
            },
            tag: 'import',
          );
          throw Exception('封面文件不存在: $archivePath');
        },
      );
      
      // 确保目标目录存在
      final targetFile = File(targetPath);
      final targetDir = Directory(path.dirname(targetPath));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
        AppLogger.debug(
          '创建封面目录',
          data: {
            'targetDir': targetDir.path,
            'operation': 'extract_work_cover_file',
          },
          tag: 'import',
        );
      }
      
      // 写入文件
      await targetFile.writeAsBytes(archiveFile.content as List<int>);
      
      // 验证文件是否成功写入
      final writtenFileExists = await targetFile.exists();
      final writtenFileSize = writtenFileExists ? await targetFile.length() : 0;
      
      AppLogger.info(
        '封面文件提取成功',
        data: {
          'archivePath': archivePath,
          'targetPath': targetPath,
          'archiveFileSize': archiveFile.content.length,
          'writtenFileSize': writtenFileSize,
          'fileExists': writtenFileExists,
          'operation': 'extract_work_cover_file',
        },
        tag: 'import',
      );
      
      return writtenFileExists;
      
    } catch (e) {
      AppLogger.debug(
        '提取封面文件失败（可能是旧版本导出文件）',
        data: {
          'workId': workId,
          'type': type,
          'error': e.toString(),
          'operation': 'extract_work_cover_file',
        },
        tag: 'import',
      );
      return false;
    }
  }

  /// 提取单个图片文件
  Future<bool> _extractImageFile(Archive archive, WorkImage image, String type) async {
    try {
      // 构建归档内的文件路径 - 修复路径构建逻辑
      String archivePath;
      String targetPath;
      
      switch (type) {
        case 'original':
          archivePath = 'images/${image.workId}/${image.id}/original${path.extension(image.originalPath)}';
          targetPath = image.originalPath;
          break;
        case 'imported':
          archivePath = 'images/${image.workId}/${image.id}/imported${path.extension(image.path)}';
          targetPath = image.path;
          break;
        case 'thumbnail':
          archivePath = 'images/${image.workId}/${image.id}/thumbnail${path.extension(image.thumbnailPath)}';
          targetPath = image.thumbnailPath;
          break;
        default:
          AppLogger.warning(
            '未知的图片类型',
            data: {
              'type': type,
              'imageId': image.id,
              'operation': 'extract_image_file',
            },
            tag: 'import',
          );
          return false;
      }
      
      AppLogger.debug(
        '尝试提取图片文件',
        data: {
          'archivePath': archivePath,
          'targetPath': targetPath,
          'type': type,
          'operation': 'extract_image_file',
        },
        tag: 'import',
      );
      
      // 在归档中查找文件
      final archiveFile = archive.files.firstWhere(
        (f) => f.name == archivePath,
        orElse: () {
          // 如果找不到文件，记录所有可用的文件名用于调试
          final availableFiles = archive.files.map((f) => f.name).toList();
          AppLogger.warning(
            '在归档中找不到指定文件',
            data: {
              'requestedPath': archivePath,
              'availableFiles': availableFiles.take(10).toList(), // 只显示前10个文件
              'totalFiles': availableFiles.length,
              'operation': 'extract_image_file',
            },
            tag: 'import',
          );
          throw Exception('文件不存在: $archivePath');
        },
      );
      
      // 确保目标目录存在
      final targetFile = File(targetPath);
      final targetDir = Directory(path.dirname(targetPath));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
        AppLogger.debug(
          '创建目标目录',
          data: {
            'targetDir': targetDir.path,
            'operation': 'extract_image_file',
          },
          tag: 'import',
        );
      }
      
      // 写入文件
      await targetFile.writeAsBytes(archiveFile.content as List<int>);
      
      // 验证文件是否成功写入
      final writtenFileExists = await targetFile.exists();
      final writtenFileSize = writtenFileExists ? await targetFile.length() : 0;
      
      AppLogger.info(
        '图片文件提取成功',
        data: {
          'archivePath': archivePath,
          'targetPath': targetPath,
          'archiveFileSize': archiveFile.content.length,
          'writtenFileSize': writtenFileSize,
          'fileExists': writtenFileExists,
          'operation': 'extract_image_file',
        },
        tag: 'import',
      );
      
      return writtenFileExists;
      
    } catch (e) {
      AppLogger.error(
        '提取图片文件失败',
        error: e,
        data: {
          'imageId': image.id,
          'type': type,
          'operation': 'extract_image_file',
        },
        tag: 'import',
      );
      return false;
    }
  }

  /// 验证作品封面文件，如果缺失则生成
  Future<void> _verifyWorkCovers(List<WorkEntity> works, List<WorkImage> workImages) async {
    AppLogger.info(
      '开始验证作品封面',
      data: {
        'workCount': works.length,
        'imageCount': workImages.length,
        'operation': 'verify_work_covers',
      },
      tag: 'import',
    );
    
    // 按作品ID分组图片
    final imagesByWork = <String, List<WorkImage>>{};
    for (final image in workImages) {
      imagesByWork.putIfAbsent(image.workId, () => []).add(image);
    }
    
    int verifiedCount = 0;
    int generatedCount = 0;
    
    for (final work in works) {
      try {
        final workId = work.id;
        final images = imagesByWork[workId] ?? [];
        
        if (images.isEmpty) {
          AppLogger.warning(
            '作品没有图片，跳过封面验证',
            data: {
              'workId': workId,
              'title': work.title,
              'operation': 'verify_work_covers',
            },
            tag: 'import',
          );
          continue;
        }
        
        // 确保存储基础路径存在
        if (_storageBasePath == null) {
          AppLogger.warning(
            '缺少存储基础路径，无法验证封面',
            data: {
              'workId': workId,
              'operation': 'verify_work_covers',
            },
            tag: 'import',
          );
          continue;
        }
        
        // 构建封面路径
        final coverImportedPath = path.join(_storageBasePath!, 'works', workId, 'cover', 'imported.png');
        final coverThumbnailPath = path.join(_storageBasePath!, 'works', workId, 'cover', 'thumbnail.jpg');
        
        // 检查封面文件是否存在
        final coverExists = await File(coverImportedPath).exists();
        final thumbnailExists = await File(coverThumbnailPath).exists();
        
        if (coverExists && thumbnailExists) {
          verifiedCount++;
          AppLogger.debug(
            '作品封面文件已存在',
            data: {
              'workId': workId,
              'title': work.title,
              'operation': 'verify_work_covers',
            },
            tag: 'import',
          );
        } else {
          // 封面文件缺失，需要重新生成
          AppLogger.info(
            '封面文件缺失，开始生成',
            data: {
              'workId': workId,
              'title': work.title,
              'coverExists': coverExists,
              'thumbnailExists': thumbnailExists,
              'operation': 'verify_work_covers',
            },
            tag: 'import',
          );
          
          // 按索引排序，获取第一张图片
          images.sort((a, b) => a.index.compareTo(b.index));
          final firstImage = images.first;
          
          // 检查第一张图片的导入文件是否存在
          final importedImagePath = firstImage.path;
          final importedFile = File(importedImagePath);
          
          if (await importedFile.exists()) {
            try {
              // 生成封面文件
              await _generateSingleWorkCover(workId, firstImage, importedFile);
              generatedCount++;
              
              AppLogger.info(
                '作品封面生成成功',
                data: {
                  'workId': workId,
                  'title': work.title,
                  'operation': 'verify_work_covers',
                },
                tag: 'import',
              );
            } catch (e) {
              AppLogger.error(
                '生成作品封面失败',
                error: e,
                data: {
                  'workId': workId,
                  'title': work.title,
                  'firstImageId': firstImage.id,
                  'operation': 'verify_work_covers',
                },
                tag: 'import',
              );
            }
          } else {
            AppLogger.warning(
              '第一张图片文件不存在，无法生成封面',
              data: {
                'workId': workId,
                'imageId': firstImage.id,
                'imagePath': importedImagePath,
                'operation': 'verify_work_covers',
              },
              tag: 'import',
            );
          }
        }
        
      } catch (e) {
        AppLogger.error(
          '验证作品封面失败',
          error: e,
          data: {
            'workId': work.id,
            'title': work.title,
            'operation': 'verify_work_covers',
          },
          tag: 'import',
        );
      }
    }
    
    AppLogger.info(
      '作品封面验证完成',
      data: {
        'totalWorks': works.length,
        'verifiedCount': verifiedCount,
        'generatedCount': generatedCount,
        'operation': 'verify_work_covers_completed',
      },
      tag: 'import',
    );
  }

  /// 为单个作品生成封面
  Future<void> _generateSingleWorkCover(String workId, WorkImage firstImage, File importedFile) async {
    // 确保存储基础路径存在
    if (_storageBasePath == null) {
      throw Exception('缺少存储基础路径');
    }
    
    // 构建封面路径
    final coverDir = path.join(_storageBasePath!, 'works', workId, 'cover');
    final coverImportedPath = path.join(coverDir, 'imported.png');
    final coverThumbnailPath = path.join(coverDir, 'thumbnail.jpg');
    
    // 确保封面目录存在
    final coverDirectory = Directory(coverDir);
    if (!await coverDirectory.exists()) {
      await coverDirectory.create(recursive: true);
    }
    
    // 复制导入图片作为封面
    await importedFile.copy(coverImportedPath);
    
    // 生成封面缩略图（简化处理：直接复制缩略图文件）
    final thumbnailImagePath = firstImage.thumbnailPath;
    final thumbnailFile = File(thumbnailImagePath);
    
    if (await thumbnailFile.exists()) {
      await thumbnailFile.copy(coverThumbnailPath);
    } else {
      // 如果缩略图不存在，直接复制导入图片并重命名
      await importedFile.copy(coverThumbnailPath);
      AppLogger.debug(
        '缩略图文件不存在，使用导入图片作为封面缩略图',
        data: {
          'workId': workId,
          'thumbnailPath': thumbnailImagePath,
          'operation': 'generate_single_work_cover',
        },
        tag: 'import',
      );
    }
    
    // 验证封面文件是否成功生成
    final coverExists = await File(coverImportedPath).exists();
    final thumbnailExists = await File(coverThumbnailPath).exists();
    
    if (!coverExists || !thumbnailExists) {
      throw Exception('封面文件生成后验证失败');
    }
  }

  /// 生成作品封面缩略图
  Future<void> _generateWorkCovers(List<WorkEntity> works, List<WorkImage> workImages) async {
    AppLogger.info(
      '开始生成作品封面',
      data: {
        'workCount': works.length,
        'imageCount': workImages.length,
        'operation': 'generate_work_covers',
      },
      tag: 'import',
    );
    
    // 按作品ID分组图片
    final imagesByWork = <String, List<WorkImage>>{};
    for (final image in workImages) {
      imagesByWork.putIfAbsent(image.workId, () => []).add(image);
    }
    
    int generatedCount = 0;
    
    for (final work in works) {
      try {
        final workId = work.id;
        final images = imagesByWork[workId] ?? [];
        
        if (images.isEmpty) {
          AppLogger.warning(
            '作品没有图片，跳过封面生成',
            data: {
              'workId': workId,
              'title': work.title,
              'operation': 'generate_work_covers',
            },
            tag: 'import',
          );
          continue;
        }
        
        // 按索引排序，获取第一张图片
        images.sort((a, b) => a.index.compareTo(b.index));
        final firstImage = images.first;
        
        // 检查第一张图片的导入文件是否存在
        final importedImagePath = firstImage.path;
        final importedFile = File(importedImagePath);
        
        if (!await importedFile.exists()) {
          AppLogger.warning(
            '第一张图片文件不存在，无法生成封面',
            data: {
              'workId': workId,
              'imageId': firstImage.id,
              'imagePath': importedImagePath,
              'operation': 'generate_work_covers',
            },
            tag: 'import',
          );
          continue;
        }
        
        // 确保存储基础路径存在
        if (_storageBasePath == null) {
          AppLogger.warning(
            '缺少存储基础路径，无法生成封面',
            data: {
              'workId': workId,
              'operation': 'generate_work_covers',
            },
            tag: 'import',
          );
          continue;
        }
        
        // 构建封面路径
        final coverDir = path.join(_storageBasePath!, 'works', workId, 'cover');
        final coverImportedPath = path.join(coverDir, 'imported.png');
        final coverThumbnailPath = path.join(coverDir, 'thumbnail.jpg');
        
        // 确保封面目录存在
        final coverDirectory = Directory(coverDir);
        if (!await coverDirectory.exists()) {
          await coverDirectory.create(recursive: true);
          AppLogger.debug(
            '创建封面目录',
            data: {
              'coverDir': coverDir,
              'operation': 'generate_work_covers',
            },
            tag: 'import',
          );
        }
        
        try {
          // 复制导入图片作为封面
          await importedFile.copy(coverImportedPath);
          
          // 生成封面缩略图（简化处理：直接复制缩略图文件）
          final thumbnailImagePath = firstImage.thumbnailPath;
          final thumbnailFile = File(thumbnailImagePath);
          
          if (await thumbnailFile.exists()) {
            await thumbnailFile.copy(coverThumbnailPath);
          } else {
            // 如果缩略图不存在，直接复制导入图片并重命名
            await importedFile.copy(coverThumbnailPath);
            AppLogger.debug(
              '缩略图文件不存在，使用导入图片作为封面缩略图',
              data: {
                'workId': workId,
                'thumbnailPath': thumbnailImagePath,
                'operation': 'generate_work_covers',
              },
              tag: 'import',
            );
          }
          
          // 验证封面文件是否成功生成
          final coverExists = await File(coverImportedPath).exists();
          final thumbnailExists = await File(coverThumbnailPath).exists();
          
          if (coverExists && thumbnailExists) {
            generatedCount++;
            AppLogger.info(
              '作品封面生成成功',
              data: {
                'workId': workId,
                'title': work.title,
                'coverImportedPath': coverImportedPath,
                'coverThumbnailPath': coverThumbnailPath,
                'operation': 'generate_work_covers',
              },
              tag: 'import',
            );
          } else {
            AppLogger.error(
              '封面文件生成后验证失败',
              data: {
                'workId': workId,
                'coverExists': coverExists,
                'thumbnailExists': thumbnailExists,
                'operation': 'generate_work_covers',
              },
              tag: 'import',
            );
          }
          
        } catch (e) {
          AppLogger.error(
            '生成作品封面失败',
            error: e,
            data: {
              'workId': workId,
              'title': work.title,
              'firstImageId': firstImage.id,
              'operation': 'generate_work_covers',
            },
            tag: 'import',
          );
        }
        
      } catch (e) {
        AppLogger.error(
          '处理作品封面生成失败',
          error: e,
          data: {
            'workId': work.id,
            'title': work.title,
            'operation': 'generate_work_covers',
          },
          tag: 'import',
        );
      }
    }
    
    AppLogger.info(
      '作品封面生成完成',
      data: {
        'totalWorks': works.length,
        'generatedCount': generatedCount,
        'operation': 'generate_work_covers_completed',
      },
      tag: 'import',
    );
  }

  WorkImage _convertWorkImagePaths(WorkImage image) {
    // 将相对路径转换为绝对路径
    AppLogger.debug(
      '转换图片路径',
      data: {
        'imageId': image.id,
        'originalPath': image.originalPath,
        'path': image.path,
        'thumbnailPath': image.thumbnailPath,
        'operation': 'convert_work_image_paths',
      },
      tag: 'import',
    );
    
    return image.copyWith(
      originalPath: _convertToAbsolutePath(image.originalPath),
      path: _convertToAbsolutePath(image.path),
      thumbnailPath: _convertToAbsolutePath(image.thumbnailPath),
    );
  }

  /// 将绝对路径转换为相对路径
  String _convertToAbsolutePath(String relativePath) {
    if (_storageBasePath == null) {
      // 如果没有存储基础路径，返回原路径
      AppLogger.warning(
        '缺少存储基础路径，无法转换相对路径',
        data: {
          'relativePath': relativePath,
          'operation': 'convert_to_absolute_path',
        },
        tag: 'import',
      );
      return relativePath;
    }
    
    return PathPrivacyHelper.toAbsolutePath(relativePath, _storageBasePath!);
  }
  
  /// 处理自定义字段（style和tool）
  Future<void> _processCustomFields(
    List<WorkEntity> works,
    List<CharacterEntity> characters,
  ) async {
    try {
      // 收集自定义字段值
      final customStyles = <String>{};
      final customTools = <String>{};
      
      // 从作品中收集自定义值
      for (final work in works) {
        if (work.style.isNotEmpty && !_isStandardStyle(work.style)) {
          customStyles.add(work.style);
        }
        if (work.tool.isNotEmpty && !_isStandardTool(work.tool)) {
          customTools.add(work.tool);
        }
      }
      
      if (customStyles.isNotEmpty || customTools.isNotEmpty) {
        AppLogger.info(
          '检测到自定义字段',
          data: {
            'customStyles': customStyles.toList(),
            'customTools': customTools.toList(),
            'operation': 'process_custom_fields',
          },
          tag: 'import',
        );
        
        // 这里可以添加实际的配置更新逻辑
        // 例如：await _configService.addCustomStyles(customStyles);
        // 例如：await _configService.addCustomTools(customTools);
      }
      
    } catch (e) {
      AppLogger.warning(
        '处理自定义字段失败',
        data: {
          'error': e.toString(),
          'operation': 'process_custom_fields_failed',
        },
        tag: 'import',
      );
      // 不抛出异常，自定义字段处理失败不应该影响导入
    }
  }
  
  /// 检查是否为标准风格
  bool _isStandardStyle(String style) {
    const standardStyles = [
      'regular',
      'running',
      'cursive',
      'clerical',
      'seal',
      'other',
    ];
    return standardStyles.contains(style);
  }
  
  /// 检查是否为标准工具
  bool _isStandardTool(String tool) {
    const standardTools = [
      'brush',
      'hardPen',
      'other',
    ];
    return standardTools.contains(tool);
  }

  /// 修复JSON字符串中的无效转义字符和编码问题
  String _fixInvalidEscapeCharacters(String jsonString) {
    try {
      // 首先尝试直接解析，如果成功则不需要修复
      jsonDecode(jsonString);
      AppLogger.debug(
        'JSON字符串无需修复',
        data: {
          'stringLength': jsonString.length,
          'operation': 'fix_invalid_escape_characters',
        },
        tag: 'import',
      );
      return jsonString;
    } catch (e) {
      AppLogger.warning(
        '检测到JSON格式问题，开始修复',
        data: {
          'error': e.toString(),
          'errorType': e.runtimeType.toString(),
          'stringLength': jsonString.length,
          'operation': 'fix_invalid_escape_characters',
        },
        tag: 'import',
      );
      
      // 开始修复过程
      String fixed = jsonString;
      bool hasChanges = false;
      
      // 1. 修复常见的UTF-8编码问题导致的转义字符问题
      if (e is FormatException && e.message.contains('Missing extension byte')) {
        AppLogger.info(
          '检测到UTF-8编码问题，尝试字符修复',
          data: {
            'operation': 'fix_invalid_escape_characters',
          },
          tag: 'import',
        );
        
        // 移除或替换可能有问题的字符序列
        final originalLength = fixed.length;
        
        // 移除不可见的控制字符（除了合法的JSON空白字符）
        fixed = fixed.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]'), '');
        
        if (fixed.length != originalLength) {
          hasChanges = true;
          AppLogger.info(
            '移除了控制字符',
            data: {
              'removedCharacters': originalLength - fixed.length,
              'operation': 'fix_invalid_escape_characters',
            },
            tag: 'import',
          );
        }
      }
      
      // 2. 修复无效的转义字符
      if (e is FormatException && 
          (e.message.contains('Unrecognized string escape') || 
           e.message.contains('Unexpected character'))) {
        
        // 修复反斜杠后跟非法字符的情况
        final beforeEscapeFix = fixed;
        fixed = fixed.replaceAllMapped(
          RegExp(r'\\([^"\\\/bfnrtu]|$)'),
          (match) {
            final char = match.group(1);
            if (char == null || char.isEmpty) {
              return '\\\\'; // 单独的反斜杠
            }
            // 如果不是有效的转义字符，则转义反斜杠
            return '\\\\$char';
          },
        );
        
        if (fixed != beforeEscapeFix) {
          hasChanges = true;
          AppLogger.info(
            '修复了无效转义字符',
            data: {
              'operation': 'fix_invalid_escape_characters',
            },
            tag: 'import',
          );
        }
        
        // 修复不完整的Unicode转义序列
        final beforeUnicodeFix = fixed;
        fixed = fixed.replaceAllMapped(
          RegExp(r'\\u([0-9a-fA-F]{0,3}[^0-9a-fA-F])'),
          (match) {
            // 不完整的Unicode转义序列，转义反斜杠
            return '\\\\u${match.group(1)}';
          },
        );
        
        if (fixed != beforeUnicodeFix) {
          hasChanges = true;
          AppLogger.info(
            '修复了不完整的Unicode转义序列',
            data: {
              'operation': 'fix_invalid_escape_characters',
            },
            tag: 'import',
          );
        }
        
        // 修复字符串末尾的单独反斜杠
        final beforeEndFix = fixed;
        fixed = fixed.replaceAll(RegExp(r'\\"\s*,'), '\\\\"",');
        fixed = fixed.replaceAll(RegExp(r'\\"\s*}'), '\\\\""}');
        
        if (fixed != beforeEndFix) {
          hasChanges = true;
          AppLogger.info(
            '修复了字符串末尾的反斜杠',
            data: {
              'operation': 'fix_invalid_escape_characters',
            },
            tag: 'import',
          );
        }
      }
      
             // 3. 尝试修复其他常见的JSON格式问题
       // 移除字符串中的空字符
       final beforeNullFix = fixed;
       fixed = fixed.replaceAll('\u0000', '');
       if (fixed != beforeNullFix) {
         hasChanges = true;
         AppLogger.info(
           '移除了空字符',
           data: {
             'operation': 'fix_invalid_escape_characters',
           },
           tag: 'import',
         );
       }
       
       // 4. 修复损坏的UTF-8替换字符
       final beforeReplacementFix = fixed;
       // 替换UTF-8替换字符 � (U+FFFD) 为空字符串或合适的占位符
       fixed = fixed.replaceAll('\uFFFD', '');
       // 也处理可能的其他损坏字符模式
       fixed = fixed.replaceAll('�', '');
       
       if (fixed != beforeReplacementFix) {
         hasChanges = true;
         AppLogger.info(
           '移除了损坏的UTF-8替换字符',
           data: {
             'operation': 'fix_invalid_escape_characters',
           },
           tag: 'import',
         );
       }
       
       // 5. 修复可能的字节序列问题导致的特殊字符
       final beforeSpecialCharFix = fixed;
       // 移除或替换可能有问题的字符序列，如 (\
       fixed = fixed.replaceAllMapped(
         RegExp(r'"[^"]*[^\x20-\x7E\u00A0-\uFFFF][^"]*"'),
         (match) {
           final originalString = match.group(0)!;
           // 清理字符串，只保留可打印的ASCII和Unicode字符
           final cleanedString = originalString.replaceAll(
             RegExp(r'[^\x20-\x7E\u00A0-\uFFFF]'), 
             '',
           );
           AppLogger.debug(
             '清理了包含特殊字符的字符串',
             data: {
               'original': originalString,
               'cleaned': cleanedString,
               'operation': 'fix_invalid_escape_characters',
             },
             tag: 'import',
           );
           return cleanedString;
         },
       );
       
       if (fixed != beforeSpecialCharFix) {
         hasChanges = true;
         AppLogger.info(
           '清理了包含特殊字符的字符串',
           data: {
             'operation': 'fix_invalid_escape_characters',
           },
           tag: 'import',
         );
       }
      
      AppLogger.info(
        'JSON修复操作完成',
        data: {
          'originalLength': jsonString.length,
          'fixedLength': fixed.length,
          'hasChanges': hasChanges,
          'operation': 'fix_invalid_escape_characters',
        },
        tag: 'import',
      );
      
      // 验证修复后的JSON是否有效
      try {
        jsonDecode(fixed);
        AppLogger.info(
          'JSON修复成功',
          data: {
            'hasChanges': hasChanges,
            'operation': 'fix_invalid_escape_characters',
          },
          tag: 'import',
        );
        return fixed;
      } catch (e2) {
        AppLogger.error(
          'JSON修复后仍然无效',
          data: {
            'originalError': e.toString(),
            'fixedError': e2.toString(),
            'hasChanges': hasChanges,
            'operation': 'fix_invalid_escape_characters',
          },
          tag: 'import',
          error: e2,
        );
        
        // 如果修复失败，抛出更详细的异常信息
        throw ImportException(
          ImportExportErrorCodes.importFileCorrupted,
          'JSON数据格式错误，修复尝试失败。原始错误: ${e.toString()}，修复后错误: ${e2.toString()}',
        );
      }
    }
  }

  /// 增强的字节解码方法，能处理各种编码问题
  String _decodeJsonFromBytes(List<int> bytes) {
    AppLogger.debug(
      '开始解码JSON字节数据',
      data: {
        'byteLength': bytes.length,
        'firstBytes': bytes.take(20).toList(), // 显示前20个字节用于调试
        'operation': 'decode_json_from_bytes',
      },
      tag: 'import',
    );

    // 策略1: 尝试标准UTF-8解码
    try {
      final result = utf8.decode(bytes);
      
      AppLogger.debug(
        'UTF-8解码成功',
        data: {
          'stringLength': result.length,
          'operation': 'decode_json_from_bytes',
        },
        tag: 'import',
      );
      
      return result;
    } catch (e) {
      AppLogger.warning(
        'UTF-8解码失败，尝试其他解码策略',
        data: {
          'error': e.toString(),
          'operation': 'decode_json_from_bytes',
        },
        tag: 'import',
      );
    }

    // 策略2: 使用allowMalformed参数的UTF-8解码
    try {
      final result = utf8.decode(bytes, allowMalformed: true);
      
      // 检查是否包含替换字符，这表示存在损坏的字节
      final hasReplacementChars = result.contains('\uFFFD') || result.contains('�');
      
      AppLogger.info(
        '容错UTF-8解码成功',
        data: {
          'stringLength': result.length,
          'hasReplacementChars': hasReplacementChars,
          'operation': 'decode_json_from_bytes',
        },
        tag: 'import',
      );
      
      if (hasReplacementChars) {
        AppLogger.warning(
          '检测到损坏的UTF-8字符，数据可能不完整',
          data: {
            'replacementCharCount': result.split('\uFFFD').length - 1,
            'operation': 'decode_json_from_bytes',
          },
          tag: 'import',
        );
      }
      
      return result;
    } catch (e) {
      AppLogger.warning(
        '容错UTF-8解码失败，尝试其他编码',
        data: {
          'error': e.toString(),
          'operation': 'decode_json_from_bytes',
        },
        tag: 'import',
      );
    }

    // 策略3: 尝试Latin-1解码（兼容性更好）
    try {
      final result = latin1.decode(bytes);
      
      AppLogger.info(
        'Latin-1解码成功',
        data: {
          'stringLength': result.length,
          'operation': 'decode_json_from_bytes',
        },
        tag: 'import',
      );
      
      return result;
    } catch (e) {
      AppLogger.warning(
        'Latin-1解码失败',
        data: {
          'error': e.toString(),
          'operation': 'decode_json_from_bytes',
        },
        tag: 'import',
      );
    }

    // 策略4: 字节清理 - 移除可能导致问题的字节
    try {
      // 移除null字节和其他可能有问题的控制字符
      final cleanedBytes = bytes.where((byte) => 
        byte != 0 && // null字节
        (byte >= 32 || byte == 9 || byte == 10 || byte == 13) // 保留可打印字符和基本空白字符
      ).toList();
      
      final result = utf8.decode(cleanedBytes, allowMalformed: true);
      
      AppLogger.info(
        '字节清理后UTF-8解码成功',
        data: {
          'originalLength': bytes.length,
          'cleanedLength': cleanedBytes.length,
          'removedBytes': bytes.length - cleanedBytes.length,
          'stringLength': result.length,
          'operation': 'decode_json_from_bytes',
        },
        tag: 'import',
      );
      
      return result;
    } catch (e) {
      AppLogger.error(
        '所有解码策略都失败',
        data: {
          'error': e.toString(),
          'byteLength': bytes.length,
          'operation': 'decode_json_from_bytes',
        },
        tag: 'import',
        error: e,
      );
      
      // 如果所有策略都失败，抛出详细的异常
      throw ImportException(
        ImportExportErrorCodes.importFileCorrupted,
        '无法解码导入文件中的JSON数据，文件可能损坏或使用了不支持的字符编码',
      );
    }
  }

  /// 保存WorkImage数据到数据库
  Future<void> _saveWorkImagesToDatabase(List<WorkImage> workImages) async {
    if (_workImageRepository == null) {
      AppLogger.warning(
        'WorkImageRepository未提供，跳过图片数据保存',
        data: {
          'imageCount': workImages.length,
          'operation': 'save_work_images_to_database',
        },
        tag: 'import',
      );
      return;
    }
    
    AppLogger.info(
      '开始保存WorkImage数据到数据库',
      data: {
        'imageCount': workImages.length,
        'operation': 'save_work_images_to_database',
      },
      tag: 'import',
    );
    
    try {
      // 按作品分组图片
      final imagesByWork = <String, List<WorkImage>>{};
      for (final image in workImages) {
        imagesByWork.putIfAbsent(image.workId, () => []).add(image);
      }
      
      int savedCount = 0;
      
      // 为每个作品保存图片数据
      for (final entry in imagesByWork.entries) {
        final workId = entry.key;
        final images = entry.value;
        
        try {
          // 按索引排序图片
          images.sort((a, b) => a.index.compareTo(b.index));
          
          // 批量保存图片数据
          await _workImageRepository!.createMany(workId, images);
          savedCount += images.length;
          
          AppLogger.debug(
            '作品图片数据保存成功',
            data: {
              'workId': workId,
              'imageCount': images.length,
              'operation': 'save_work_images_to_database',
            },
            tag: 'import',
          );
          
        } catch (e) {
          AppLogger.error(
            '保存作品图片数据失败',
            error: e,
            data: {
              'workId': workId,
              'imageCount': images.length,
              'operation': 'save_work_images_to_database',
            },
            tag: 'import',
          );
          // 继续处理其他作品的图片
        }
      }
      
      AppLogger.info(
        'WorkImage数据保存完成',
        data: {
          'totalImages': workImages.length,
          'savedCount': savedCount,
          'workCount': imagesByWork.length,
          'operation': 'save_work_images_to_database',
        },
        tag: 'import',
      );
      
    } catch (e, stackTrace) {
      AppLogger.error(
        '保存WorkImage数据到数据库失败',
        error: e,
        stackTrace: stackTrace,
        data: {
          'imageCount': workImages.length,
          'operation': 'save_work_images_to_database',
        },
        tag: 'import',
      );
      throw e;
    }
  }
} 