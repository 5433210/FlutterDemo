import 'dart:convert';
import 'dart:io';

import '../../../domain/interfaces/data_version_adapter.dart';
import '../../../infrastructure/logging/logger.dart';
import '../database_migration_integration.dart';

/// v1 到 v2 数据版本适配器
/// 主要变化：添加练习功能相关的数据结构和配置
class DataAdapter_v1_to_v2 implements DataVersionAdapter {
  @override
  bool get requiresRestart => true;
  @override
  String get sourceDataVersion => 'v1';

  @override
  String get targetDataVersion => 'v2';

  @override
  String get description => '添加练习功能支持';

  @override
  int get estimatedProcessingTime => 45; // 45秒

  @override
  Future<PreProcessResult> preProcess(String dataPath) async {
    final stopwatch = Stopwatch()..start();
    int processedFiles = 0;
    int skippedFiles = 0;

    try {
      AppLogger.info('开始 v1→v2 预处理', tag: 'DataAdapter_v1_to_v2', data: {
        'dataPath': dataPath,
      });

      // 1. 创建练习功能目录结构
      await _createPracticeDirectories(dataPath);
      processedFiles++;

      // 2. 初始化练习配置文件
      await _initializePracticeConfig(dataPath);
      processedFiles++;

      // 3. 迁移现有用户偏好设置
      final migrated = await _migratePracticeSettings(dataPath);
      if (migrated) {
        processedFiles++;
      } else {
        skippedFiles++;
      }

      // 4. 创建练习数据索引
      await _createPracticeIndex(dataPath);
      processedFiles++;

      stopwatch.stop();

      AppLogger.info('v1→v2 预处理完成', tag: 'DataAdapter_v1_to_v2', data: {
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
          'practiceDirectoriesCreated': true,
          'practiceConfigInitialized': true,
          'practiceSettingsMigrated': migrated,
        },
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      AppLogger.error('v1→v2 预处理失败',
          error: e, stackTrace: stackTrace, tag: 'DataAdapter_v1_to_v2');

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
      AppLogger.info('开始 v1→v2 后处理', tag: 'DataAdapter_v1_to_v2', data: {
        'dataPath': dataPath,
      });

      // 1. 验证练习目录结构
      await _validatePracticeStructure(dataPath);
      executedSteps.add('验证练习目录结构');

      // 2. 执行数据库迁移 (v1 → v2)
      final databasePath = '$dataPath/database/app.db';
      await DatabaseMigrationIntegration.integrateWithExistingMigrations(
          'v1', 'v2', databasePath);
      executedSteps.add('执行数据库迁移 v1→v2');

      // 3. 更新配置文件版本标记
      await _updateConfigVersion(dataPath);
      executedSteps.add('更新配置文件版本');
      updatedRecords++;

      // 4. 初始化练习数据库表
      await _initializePracticeTables(dataPath);
      executedSteps.add('初始化练习数据库表');
      processedRecords++;

      // 4. 清理临时文件
      await _cleanupTempFiles(dataPath);
      executedSteps.add('清理临时文件');

      stopwatch.stop();

      AppLogger.info('v1→v2 后处理完成', tag: 'DataAdapter_v1_to_v2', data: {
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
      AppLogger.error('v1→v2 后处理失败',
          error: e, stackTrace: stackTrace, tag: 'DataAdapter_v1_to_v2');

      return PostProcessResult.failure('后处理失败: $e',
          executedSteps: executedSteps);
    }
  }

  @override
  Future<bool> validateAdaptation(String dataPath) async {
    try {
      // 验证练习功能目录结构
      final practicesDir = Directory('$dataPath/practices');
      if (!await practicesDir.exists()) return false;

      // 验证配置文件格式
      final configFile = File('$dataPath/config.json');
      if (await configFile.exists()) {
        final config = jsonDecode(await configFile.readAsString());
        if (!config.containsKey('practiceSettings')) return false;
      }

      // 验证练习索引文件
      final indexFile = File('$dataPath/practices/index.json');
      if (!await indexFile.exists()) return false;

      AppLogger.info('v1→v2 适配验证成功', tag: 'DataAdapter_v1_to_v2');
      return true;
    } catch (e) {
      AppLogger.error('v1→v2 适配验证失败', error: e, tag: 'DataAdapter_v1_to_v2');
      return false;
    }
  }

  @override
  Future<void> integrateDatabaseMigration(String dataPath) async {
    // 集成现有数据库迁移：v1(db版本5) -> v2(db版本10)
    await DatabaseMigrationIntegration.integrateWithExistingMigrations(
        'v1', 'v2', '$dataPath/app.db');
  }

  /// 创建练习功能目录结构
  Future<void> _createPracticeDirectories(String dataPath) async {
    final directories = [
      '$dataPath/practices',
      '$dataPath/practices/templates',
      '$dataPath/practices/user_practices',
      '$dataPath/practices/exports',
    ];

    for (final dir in directories) {
      final directory = Directory(dir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        AppLogger.debug('创建练习目录: $dir', tag: 'DataAdapter_v1_to_v2');
      }
    }
  }

  /// 初始化练习配置文件
  Future<void> _initializePracticeConfig(String dataPath) async {
    final configFile = File('$dataPath/config.json');
    Map<String, dynamic> config = {};

    // 读取现有配置
    if (await configFile.exists()) {
      try {
        config = jsonDecode(await configFile.readAsString());
      } catch (e) {
        AppLogger.warning('读取现有配置失败，使用默认配置',
            error: e, tag: 'DataAdapter_v1_to_v2');
      }
    }

    // 添加练习设置
    config['practiceSettings'] = {
      'defaultTemplate': 'basic',
      'autoSave': true,
      'showGrid': true,
      'gridSize': 20,
      'enableGuides': true,
    };

    // 写入配置文件
    await configFile.writeAsString(jsonEncode(config));
    AppLogger.debug('初始化练习配置完成', tag: 'DataAdapter_v1_to_v2');
  }

  /// 迁移练习设置
  Future<bool> _migratePracticeSettings(String dataPath) async {
    // 这里可以添加从旧版本迁移练习相关设置的逻辑
    // 目前 v1 版本没有练习功能，所以直接返回 false
    AppLogger.debug('v1 版本无练习设置需要迁移', tag: 'DataAdapter_v1_to_v2');
    return false;
  }

  /// 创建练习数据索引
  Future<void> _createPracticeIndex(String dataPath) async {
    final indexFile = File('$dataPath/practices/index.json');
    final index = {
      'version': '2.0',
      'createdAt': DateTime.now().toIso8601String(),
      'practices': [],
      'templates': [],
    };

    await indexFile.writeAsString(jsonEncode(index));
    AppLogger.debug('创建练习索引文件', tag: 'DataAdapter_v1_to_v2');
  }

  /// 验证练习结构
  Future<void> _validatePracticeStructure(String dataPath) async {
    final requiredDirs = [
      '$dataPath/practices',
      '$dataPath/practices/templates',
      '$dataPath/practices/user_practices',
    ];

    for (final dir in requiredDirs) {
      final directory = Directory(dir);
      if (!await directory.exists()) {
        throw Exception('练习目录不存在: $dir');
      }
    }
  }

  /// 更新配置版本
  Future<void> _updateConfigVersion(String dataPath) async {
    final configFile = File('$dataPath/config.json');
    if (await configFile.exists()) {
      final config = jsonDecode(await configFile.readAsString());
      config['dataVersion'] = 'v2';
      config['lastUpgraded'] = DateTime.now().toIso8601String();
      await configFile.writeAsString(jsonEncode(config));
    }
  }

  /// 初始化练习数据库表
  Future<void> _initializePracticeTables(String dataPath) async {
    // 这里会通过数据库迁移集成来处理
    AppLogger.debug('练习数据库表将通过数据库迁移处理', tag: 'DataAdapter_v1_to_v2');
  }

  /// 清理临时文件
  Future<void> _cleanupTempFiles(String dataPath) async {
    final tempDir = Directory('$dataPath/temp');
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
      AppLogger.debug('清理临时文件完成', tag: 'DataAdapter_v1_to_v2');
    }
  }
}
