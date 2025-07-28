import 'dart:io';

import '../../domain/interfaces/import_export_data_adapter.dart';
import '../../domain/models/import_export/import_export_data_version_definition.dart';
import '../../infrastructure/logging/logger.dart';
import 'import_export_versions/adapter_ie_v1_to_v2.dart';
import 'import_export_versions/adapter_ie_v2_to_v3.dart';
import 'import_export_versions/adapter_ie_v3_to_v4.dart';

/// 导入导出适配器管理器
class ImportExportAdapterManager {
  static final ImportExportAdapterManager _instance =
      ImportExportAdapterManager._internal();
  factory ImportExportAdapterManager() => _instance;
  ImportExportAdapterManager._internal();

  /// 所有可用的适配器
  final Map<String, ImportExportDataAdapter> _adapters = {};

  /// 初始化适配器管理器
  void initialize() {
    _registerAdapters();
    AppLogger.info('导入导出适配器管理器初始化完成',
        data: {'adapterCount': _adapters.length},
        tag: 'ImportExportAdapterManager');
  }

  /// 注册所有适配器
  void _registerAdapters() {
    final adapters = [
      ImportExportAdapterV1ToV2(),
      ImportExportAdapterV2ToV3(),
      ImportExportAdapterV3ToV4(),
    ];

    for (final adapter in adapters) {
      final key =
          '${adapter.sourceDataVersion}_to_${adapter.targetDataVersion}';
      _adapters[key] = adapter;
      AppLogger.debug('注册适配器: $key', tag: 'ImportExportAdapterManager');
    }
  }

  /// 获取指定版本转换的适配器
  ImportExportDataAdapter? getAdapter(
      String sourceVersion, String targetVersion) {
    final key = '${sourceVersion}_to_$targetVersion';
    return _adapters[key];
  }

  /// 获取所有已注册的适配器
  Map<String, ImportExportDataAdapter> getRegisteredAdapters() {
    return Map.unmodifiable(_adapters);
  }

  /// 注册自定义适配器
  void registerAdapter(String key, ImportExportDataAdapter adapter) {
    _adapters[key] = adapter;
    AppLogger.debug('注册自定义适配器: $key', tag: 'ImportExportAdapterManager');
  }

  /// 注销适配器
  void unregisterAdapter(String key) {
    _adapters.remove(key);
    AppLogger.debug('注销适配器: $key', tag: 'ImportExportAdapterManager');
  }

  /// 获取升级路径
  List<ImportExportDataAdapter> getUpgradePath(
      String sourceVersion, String targetVersion) {
    final path = <ImportExportDataAdapter>[];

    try {
      // 验证版本有效性
      if (!ImportExportDataVersionDefinition.isValidVersion(sourceVersion) ||
          !ImportExportDataVersionDefinition.isValidVersion(targetVersion)) {
        AppLogger.warning('无效的版本号',
            data: {'source': sourceVersion, 'target': targetVersion},
            tag: 'ImportExportAdapterManager');
        return path;
      }

      // 如果源版本和目标版本相同，无需升级
      if (sourceVersion == targetVersion) {
        return path;
      }

      // 获取版本升级路径
      final upgradePath = ImportExportDataVersionDefinition.getUpgradePath(
          sourceVersion, targetVersion);
      if (upgradePath.isEmpty) {
        AppLogger.warning('无法找到升级路径',
            data: {'source': sourceVersion, 'target': targetVersion},
            tag: 'ImportExportAdapterManager');
        return path;
      }

      // 构建适配器链
      for (int i = 0; i < upgradePath.length - 1; i++) {
        final currentVersion = upgradePath[i];
        final nextVersion = upgradePath[i + 1];

        final adapter = getAdapter(currentVersion, nextVersion);
        if (adapter == null) {
          AppLogger.error('缺少适配器',
              data: {'from': currentVersion, 'to': nextVersion},
              tag: 'ImportExportAdapterManager');
          return <ImportExportDataAdapter>[]; // 返回空列表表示失败
        }

        path.add(adapter);
      }

      AppLogger.info('找到升级路径',
          data: {
            'source': sourceVersion,
            'target': targetVersion,
            'pathLength': path.length,
            'adapters': path.map((a) => a.adapterName).toList(),
          },
          tag: 'ImportExportAdapterManager');
    } catch (e, stackTrace) {
      AppLogger.error('获取升级路径失败',
          error: e, stackTrace: stackTrace, tag: 'ImportExportAdapterManager');
      return <ImportExportDataAdapter>[];
    }

    return path;
  }

  /// 执行升级链
  Future<UpgradeChainResult> executeUpgradeChain(
    List<ImportExportDataAdapter> adapters,
    String sourceFilePath,
  ) async {
    final startTime = DateTime.now();
    final results = <ImportExportAdapterResult>[];
    String currentFilePath = sourceFilePath;

    try {
      AppLogger.info('开始执行升级链',
          data: {
            'adapterCount': adapters.length,
            'sourceFile': sourceFilePath,
            'adapters': adapters.map((a) => a.adapterName).toList(),
          },
          tag: 'ImportExportAdapterManager');

      // 逐个执行适配器
      for (int i = 0; i < adapters.length; i++) {
        final adapter = adapters[i];

        AppLogger.info('执行适配器 ${i + 1}/${adapters.length}',
            data: {
              'adapter': adapter.adapterName,
              'inputFile': currentFilePath
            },
            tag: 'ImportExportAdapterManager');

        // 执行预处理
        final result = await adapter.preProcess(currentFilePath);
        results.add(result);

        if (!result.success) {
          AppLogger.error('适配器执行失败',
              data: {
                'adapter': adapter.adapterName,
                'error': result.message,
                'errorCode': result.errorCode,
              },
              tag: 'ImportExportAdapterManager');

          return UpgradeChainResult.failed(
            results,
            errorMessage: '适配器 ${adapter.adapterName} 执行失败: ${result.message}',
            failedAdapterIndex: i,
          );
        }

        // 更新当前文件路径为下一个适配器的输入
        if (result.outputPath != null) {
          currentFilePath = result.outputPath!;
        }

        AppLogger.info('适配器执行成功',
            data: {
              'adapter': adapter.adapterName,
              'outputFile': currentFilePath
            },
            tag: 'ImportExportAdapterManager');
      }

      final endTime = DateTime.now();
      final statistics = UpgradeChainStatistics(
        startTime: startTime,
        endTime: endTime,
        totalDurationMs: endTime.difference(startTime).inMilliseconds,
        adapterCount: adapters.length,
        totalRecords: _calculateTotalRecords(results),
        totalFiles: results.length,
        originalSizeBytes: _calculateOriginalSize(results),
        finalSizeBytes: _calculateFinalSize(results),
        adapterDurations: _calculateAdapterDurations(results, adapters),
      );

      AppLogger.info('升级链执行完成',
          data: {
            'finalFile': currentFilePath,
            'totalDuration': statistics.totalDurationMs,
            'totalRecords': statistics.totalRecords,
          },
          tag: 'ImportExportAdapterManager');

      return UpgradeChainResult.success(
        results,
        finalOutputPath: currentFilePath,
        statistics: statistics,
      );
    } catch (e, stackTrace) {
      AppLogger.error('升级链执行失败',
          error: e, stackTrace: stackTrace, tag: 'ImportExportAdapterManager');

      return UpgradeChainResult.failed(
        results,
        errorMessage: '升级链执行过程中发生错误: ${e.toString()}',
      );
    }
  }

  /// 执行后处理
  Future<List<ImportExportAdapterResult>> executePostProcessing(
    List<ImportExportDataAdapter> adapters,
    String finalDataPath,
  ) async {
    final results = <ImportExportAdapterResult>[];

    try {
      AppLogger.info('开始执行后处理',
          data: {'adapterCount': adapters.length, 'dataPath': finalDataPath},
          tag: 'ImportExportAdapterManager');

      // 逆序执行后处理（从最新版本开始）
      for (int i = adapters.length - 1; i >= 0; i--) {
        final adapter = adapters[i];

        AppLogger.info('执行后处理 ${adapters.length - i}/${adapters.length}',
            data: {'adapter': adapter.adapterName},
            tag: 'ImportExportAdapterManager');

        final result = await adapter.postProcess(finalDataPath);
        results.add(result);

        if (!result.success) {
          AppLogger.warning('后处理失败，但继续执行',
              data: {
                'adapter': adapter.adapterName,
                'error': result.message,
              },
              tag: 'ImportExportAdapterManager');
        }
      }

      AppLogger.info('后处理执行完成',
          data: {'successCount': results.where((r) => r.success).length},
          tag: 'ImportExportAdapterManager');
    } catch (e, stackTrace) {
      AppLogger.error('后处理执行失败',
          error: e, stackTrace: stackTrace, tag: 'ImportExportAdapterManager');
    }

    return results;
  }

  /// 检查是否支持指定的版本转换
  bool supportsConversion(String sourceVersion, String targetVersion) {
    // 检查直接转换
    final directAdapter = getAdapter(sourceVersion, targetVersion);
    if (directAdapter != null) {
      return true;
    }

    // 检查是否有升级路径
    final upgradePath = getUpgradePath(sourceVersion, targetVersion);
    return upgradePath.isNotEmpty;
  }

  /// 验证升级结果
  Future<bool> validateUpgradeResult(
    List<ImportExportDataAdapter> adapters,
    String finalDataPath,
  ) async {
    try {
      AppLogger.info('开始验证升级结果',
          data: {'dataPath': finalDataPath}, tag: 'ImportExportAdapterManager');

      // 使用最后一个适配器进行验证
      if (adapters.isNotEmpty) {
        final lastAdapter = adapters.last;
        final isValid = await lastAdapter.validate(finalDataPath);

        AppLogger.info('升级结果验证完成',
            data: {'isValid': isValid, 'validator': lastAdapter.adapterName},
            tag: 'ImportExportAdapterManager');

        return isValid;
      }

      return false;
    } catch (e, stackTrace) {
      AppLogger.error('升级结果验证失败',
          error: e, stackTrace: stackTrace, tag: 'ImportExportAdapterManager');
      return false;
    }
  }

  /// 获取所有可用的适配器信息
  Map<String, String> getAvailableAdapters() {
    return _adapters
        .map((key, adapter) => MapEntry(key, adapter.getDescription()));
  }

  /// 计算总记录数
  int _calculateTotalRecords(List<ImportExportAdapterResult> results) {
    return results
        .where((r) => r.statistics != null)
        .map((r) => r.statistics!.convertedRecords)
        .fold(0, (sum, count) => sum + count);
  }

  /// 计算原始大小
  int _calculateOriginalSize(List<ImportExportAdapterResult> results) {
    if (results.isEmpty) return 0;
    return results.first.statistics?.originalSizeBytes ?? 0;
  }

  /// 计算最终大小
  int _calculateFinalSize(List<ImportExportAdapterResult> results) {
    if (results.isEmpty) return 0;
    return results.last.statistics?.convertedSizeBytes ?? 0;
  }

  /// 计算各适配器耗时
  Map<String, int> _calculateAdapterDurations(
    List<ImportExportAdapterResult> results,
    List<ImportExportDataAdapter> adapters,
  ) {
    final durations = <String, int>{};

    for (int i = 0; i < results.length && i < adapters.length; i++) {
      final adapter = adapters[i];
      final result = results[i];
      durations[adapter.adapterName] = result.statistics?.durationMs ?? 0;
    }

    return durations;
  }

  /// 清理临时文件
  Future<void> cleanupTemporaryFiles(
      List<ImportExportAdapterResult> results) async {
    try {
      for (final result in results) {
        if (result.outputPath != null) {
          final file = File(result.outputPath!);
          if (await file.exists()) {
            await file.delete();
            AppLogger.debug('删除临时文件',
                data: {'file': result.outputPath},
                tag: 'ImportExportAdapterManager');
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('清理临时文件失败',
          error: e, stackTrace: stackTrace, tag: 'ImportExportAdapterManager');
    }
  }
}
