import 'dart:convert';
import 'dart:io';

import '../../../domain/interfaces/data_version_adapter.dart';
import '../../../infrastructure/logging/logger.dart';
import '../database_migration_integration.dart';

/// v2 到 v3 数据版本适配器
/// 主要变化：增强作品管理，添加元数据支持
class DataAdapter_v2_to_v3 implements DataVersionAdapter {
  @override
  bool get requiresRestart => true;
  @override
  String get sourceDataVersion => 'v2';

  @override
  String get targetDataVersion => 'v3';

  @override
  String get description => '增强作品管理，添加元数据支持';

  @override
  int get estimatedProcessingTime => 60; // 60秒

  @override
  Future<PreProcessResult> preProcess(String dataPath) async {
    final stopwatch = Stopwatch()..start();
    int processedFiles = 0;
    int skippedFiles = 0;

    try {
      AppLogger.info('开始 v2→v3 预处理', tag: 'DataAdapter_v2_to_v3', data: {
        'dataPath': dataPath,
      });

      // 1. 重组作品目录结构
      await _reorganizeWorksStructure(dataPath);
      processedFiles++;

      // 2. 为现有作品添加元数据
      final metadataCount = await _addMetadataToExistingWorks(dataPath);
      processedFiles += metadataCount;

      // 3. 创建作品索引
      await _createWorksIndex(dataPath);
      processedFiles++;

      // 4. 升级配置文件格式
      await _upgradeConfigFormat(dataPath);
      processedFiles++;

      stopwatch.stop();

      AppLogger.info('v2→v3 预处理完成', tag: 'DataAdapter_v2_to_v3', data: {
        'processedFiles': processedFiles,
        'skippedFiles': skippedFiles,
        'processingTimeMs': stopwatch.elapsedMilliseconds,
      });

      return PreProcessResult.success(
        needsRestart: true,
        processedFiles: processedFiles,
        skippedFiles: skippedFiles,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        stateData: {
          'worksReorganized': true,
          'metadataAdded': metadataCount > 0,
          'indexCreated': true,
        },
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      AppLogger.error('v2→v3 预处理失败',
          error: e, stackTrace: stackTrace, tag: 'DataAdapter_v2_to_v3');

      return PreProcessResult.failure('预处理失败: $e');
    }
  }

  @override
  Future<PostProcessResult> postProcess(String dataPath) async {
    final stopwatch = Stopwatch()..start();
    final executedSteps = <String>[];
    int processedRecords = 0;
    int updatedRecords = 0;

    try {
      AppLogger.info('开始 v2→v3 后处理', tag: 'DataAdapter_v2_to_v3', data: {
        'dataPath': dataPath,
      });

      // 1. 验证作品目录结构
      await _validateWorksStructure(dataPath);
      executedSteps.add('验证作品目录结构');

      // 2. 执行数据库迁移 (v2 → v3)
      final databasePath = '$dataPath/database/app.db';
      await DatabaseMigrationIntegration.integrateWithExistingMigrations(
          'v2', 'v3', databasePath);
      executedSteps.add('执行数据库迁移 v2→v3');

      // 3. 更新作品数据库记录
      final updated = await _updateWorksDatabase(dataPath);
      executedSteps.add('更新作品数据库记录');
      processedRecords += updated;
      updatedRecords += updated;

      // 3. 生成作品缩略图
      final thumbnails = await _generateWorkThumbnails(dataPath);
      executedSteps.add('生成作品缩略图');
      processedRecords += thumbnails;

      // 4. 更新配置版本
      await _updateConfigVersion(dataPath);
      executedSteps.add('更新配置版本');
      updatedRecords++;

      stopwatch.stop();

      AppLogger.info('v2→v3 后处理完成', tag: 'DataAdapter_v2_to_v3', data: {
        'executedSteps': executedSteps,
        'processedRecords': processedRecords,
        'updatedRecords': updatedRecords,
        'processingTimeMs': stopwatch.elapsedMilliseconds,
      });

      return PostProcessResult.success(
        executedSteps: executedSteps,
        processedRecords: processedRecords,
        updatedRecords: updatedRecords,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      AppLogger.error('v2→v3 后处理失败',
          error: e, stackTrace: stackTrace, tag: 'DataAdapter_v2_to_v3');

      return PostProcessResult.failure('后处理失败: $e',
          executedSteps: executedSteps);
    }
  }

  @override
  Future<bool> validateAdaptation(String dataPath) async {
    try {
      // 验证作品目录结构重组
      final worksDir = Directory('$dataPath/works');
      if (!await worksDir.exists()) return false;

      // 验证元数据文件
      await for (final entity in worksDir.list()) {
        if (entity is Directory) {
          final metadataFile = File('${entity.path}/metadata.json');
          if (!await metadataFile.exists()) return false;

          // 验证元数据格式
          try {
            final metadata = jsonDecode(await metadataFile.readAsString());
            if (!metadata.containsKey('version') ||
                metadata['version'] != 'v3') {
              return false;
            }
          } catch (e) {
            return false;
          }
        }
      }

      // 验证作品索引
      final indexFile = File('$dataPath/works/index.json');
      if (!await indexFile.exists()) return false;

      AppLogger.info('v2→v3 适配验证成功', tag: 'DataAdapter_v2_to_v3');
      return true;
    } catch (e) {
      AppLogger.error('v2→v3 适配验证失败', error: e, tag: 'DataAdapter_v2_to_v3');
      return false;
    }
  }

  @override
  Future<void> integrateDatabaseMigration(String dataPath) async {
    // 集成现有数据库迁移：v2(db版本10) -> v3(db版本15)
    await DatabaseMigrationIntegration.integrateWithExistingMigrations(
        'v2', 'v3', '$dataPath/app.db');
  }

  /// 重组作品目录结构
  Future<void> _reorganizeWorksStructure(String dataPath) async {
    final worksDir = Directory('$dataPath/works');
    if (!await worksDir.exists()) {
      await worksDir.create(recursive: true);
      return;
    }

    // 为每个作品创建独立的子目录
    await for (final entity in worksDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final workId = entity.path.split('/').last.replaceAll('.json', '');
        final workSubDir = Directory('${worksDir.path}/$workId');

        if (!await workSubDir.exists()) {
          await workSubDir.create();

          // 移动作品文件到子目录
          final newPath = '${workSubDir.path}/work.json';
          await entity.rename(newPath);

          AppLogger.debug('重组作品目录: $workId', tag: 'DataAdapter_v2_to_v3');
        }
      }
    }
  }

  /// 为现有作品添加元数据
  Future<int> _addMetadataToExistingWorks(String dataPath) async {
    final worksDir = Directory('$dataPath/works');
    if (!await worksDir.exists()) return 0;

    int count = 0;
    await for (final entity in worksDir.list()) {
      if (entity is Directory) {
        final metadataFile = File('${entity.path}/metadata.json');
        if (!await metadataFile.exists()) {
          final metadata = {
            'version': 'v3',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'tags': [],
            'category': 'general',
            'difficulty': 'medium',
            'estimatedTime': 30,
            'thumbnailPath': 'thumbnail.png',
          };

          await metadataFile.writeAsString(jsonEncode(metadata));
          count++;
        }
      }
    }

    AppLogger.debug('添加元数据文件数量: $count', tag: 'DataAdapter_v2_to_v3');
    return count;
  }

  /// 创建作品索引
  Future<void> _createWorksIndex(String dataPath) async {
    final indexFile = File('$dataPath/works/index.json');
    final index = {
      'version': 'v3',
      'createdAt': DateTime.now().toIso8601String(),
      'works': [],
      'categories': ['general', 'practice', 'template'],
      'tags': [],
    };

    await indexFile.writeAsString(jsonEncode(index));
    AppLogger.debug('创建作品索引文件', tag: 'DataAdapter_v2_to_v3');
  }

  /// 升级配置文件格式
  Future<void> _upgradeConfigFormat(String dataPath) async {
    final configFile = File('$dataPath/config.json');
    if (!await configFile.exists()) return;

    final config = jsonDecode(await configFile.readAsString());

    // 添加新的配置项
    config['worksManagement'] = {
      'enableMetadata': true,
      'autoGenerateThumbnails': true,
      'defaultCategory': 'general',
      'sortBy': 'updatedAt',
      'sortOrder': 'desc',
    };

    await configFile.writeAsString(jsonEncode(config));
    AppLogger.debug('升级配置文件格式', tag: 'DataAdapter_v2_to_v3');
  }

  /// 验证作品结构
  Future<void> _validateWorksStructure(String dataPath) async {
    final worksDir = Directory('$dataPath/works');
    if (!await worksDir.exists()) {
      throw Exception('作品目录不存在');
    }

    final indexFile = File('$dataPath/works/index.json');
    if (!await indexFile.exists()) {
      throw Exception('作品索引文件不存在');
    }
  }

  /// 更新作品数据库
  Future<int> _updateWorksDatabase(String dataPath) async {
    // 这里会通过数据库迁移集成来处理
    AppLogger.debug('作品数据库更新将通过数据库迁移处理', tag: 'DataAdapter_v2_to_v3');
    return 0;
  }

  /// 生成作品缩略图
  Future<int> _generateWorkThumbnails(String dataPath) async {
    // 这里可以添加缩略图生成逻辑
    AppLogger.debug('缩略图生成功能待实现', tag: 'DataAdapter_v2_to_v3');
    return 0;
  }

  /// 更新配置版本
  Future<void> _updateConfigVersion(String dataPath) async {
    final configFile = File('$dataPath/config.json');
    if (await configFile.exists()) {
      final config = jsonDecode(await configFile.readAsString());
      config['dataVersion'] = 'v3';
      config['lastUpgraded'] = DateTime.now().toIso8601String();
      await configFile.writeAsString(jsonEncode(config));
    }
  }
}
