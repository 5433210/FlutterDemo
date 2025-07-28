import '../../domain/interfaces/data_version_adapter.dart';
import '../../domain/models/data_version_definition.dart';
import '../../infrastructure/logging/logger.dart';
import 'data_versions/adapter_v1_to_v2.dart';
import 'data_versions/adapter_v2_to_v3.dart';

/// 数据版本适配器管理器
/// 负责管理所有数据版本适配器，提供适配器查找和执行功能
class DataVersionAdapterManager {
  static final Map<String, DataVersionAdapter> _adapters = {
    'v1->v2': DataAdapterV1ToV2(),
    'v2->v3': DataAdapterV2ToV3(),
    // 可以继续添加更多适配器
    // 'v3->v4': DataAdapter_v3_to_v4(),
  };

  /// 获取适配器
  static DataVersionAdapter? getAdapter(String fromVersion, String toVersion) {
    final key = '$fromVersion->$toVersion';
    return _adapters[key];
  }

  /// 获取升级路径的所有适配器
  static List<DataVersionAdapter> getUpgradeAdapters(
      String fromVersion, String toVersion) {
    final upgradePath =
        DataVersionDefinition.getUpgradePath(fromVersion, toVersion);

    // 如果升级路径为空，说明不需要升级或者是降级，抛出异常
    if (upgradePath.isEmpty || upgradePath.length < 2) {
      throw Exception('不支持从 $fromVersion 到 $toVersion 的升级路径');
    }

    final adapters = <DataVersionAdapter>[];

    for (int i = 0; i < upgradePath.length - 1; i++) {
      final from = upgradePath[i];
      final to = upgradePath[i + 1];
      final adapter = getAdapter(from, to);

      if (adapter != null) {
        adapters.add(adapter);
      } else {
        AppLogger.warning('未找到适配器', tag: 'DataVersionAdapterManager', data: {
          'fromVersion': from,
          'toVersion': to,
        });
        throw Exception('未找到从 $from 到 $to 的适配器');
      }
    }

    return adapters;
  }

  /// 执行单步适配
  static Future<AdapterExecutionResult> executeSingleAdapter(
    DataVersionAdapter adapter,
    String dataPath,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.info('开始执行适配器', tag: 'DataVersionAdapterManager', data: {
        'adapter': '${adapter.sourceDataVersion}->${adapter.targetDataVersion}',
        'dataPath': dataPath,
      });

      // 1. 预处理阶段
      final preProcessResult = await adapter.preProcess(dataPath);
      if (!preProcessResult.success) {
        return AdapterExecutionResult.failure(
          adapter: adapter,
          stage: AdapterExecutionStage.preProcess,
          errorMessage: preProcessResult.errorMessage ?? '预处理失败',
          executionTimeMs: stopwatch.elapsedMilliseconds,
        );
      }

      // 2. 数据库迁移集成
      await adapter.integrateDatabaseMigration(dataPath);

      // 3. 后处理阶段
      final postProcessResult = await adapter.postProcess(dataPath);
      if (!postProcessResult.success) {
        return AdapterExecutionResult.failure(
          adapter: adapter,
          stage: AdapterExecutionStage.postProcess,
          errorMessage: postProcessResult.errorMessage ?? '后处理失败',
          executionTimeMs: stopwatch.elapsedMilliseconds,
        );
      }

      // 4. 验证适配结果
      final isValid = await adapter.validateAdaptation(dataPath);
      if (!isValid) {
        return AdapterExecutionResult.failure(
          adapter: adapter,
          stage: AdapterExecutionStage.validation,
          errorMessage: '适配结果验证失败',
          executionTimeMs: stopwatch.elapsedMilliseconds,
        );
      }

      stopwatch.stop();

      AppLogger.info('适配器执行成功', tag: 'DataVersionAdapterManager', data: {
        'adapter': '${adapter.sourceDataVersion}->${adapter.targetDataVersion}',
        'executionTimeMs': stopwatch.elapsedMilliseconds,
      });

      return AdapterExecutionResult.success(
        adapter: adapter,
        preProcessResult: preProcessResult,
        postProcessResult: postProcessResult,
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();

      AppLogger.error('适配器执行失败',
          error: e,
          stackTrace: stackTrace,
          tag: 'DataVersionAdapterManager',
          data: {
            'adapter':
                '${adapter.sourceDataVersion}->${adapter.targetDataVersion}',
          });

      return AdapterExecutionResult.failure(
        adapter: adapter,
        stage: AdapterExecutionStage.unknown,
        errorMessage: e.toString(),
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// 执行升级链
  static Future<UpgradeChainResult> executeUpgradeChain(
    String fromVersion,
    String toVersion,
    String dataPath,
  ) async {
    final stopwatch = Stopwatch()..start();
    final results = <AdapterExecutionResult>[];

    try {
      AppLogger.info('开始执行升级链', tag: 'DataVersionAdapterManager', data: {
        'fromVersion': fromVersion,
        'toVersion': toVersion,
        'dataPath': dataPath,
      });

      final adapters = getUpgradeAdapters(fromVersion, toVersion);

      for (final adapter in adapters) {
        final result = await executeSingleAdapter(adapter, dataPath);
        results.add(result);

        if (!result.success) {
          // 升级链中断
          stopwatch.stop();
          return UpgradeChainResult(
            success: false,
            fromVersion: fromVersion,
            toVersion: toVersion,
            results: results,
            totalExecutionTimeMs: stopwatch.elapsedMilliseconds,
            errorMessage:
                '升级链在 ${adapter.sourceDataVersion}->${adapter.targetDataVersion} 阶段失败: ${result.errorMessage}',
          );
        }
      }

      stopwatch.stop();

      AppLogger.info('升级链执行成功', tag: 'DataVersionAdapterManager', data: {
        'fromVersion': fromVersion,
        'toVersion': toVersion,
        'adaptersCount': adapters.length,
        'totalExecutionTimeMs': stopwatch.elapsedMilliseconds,
      });

      return UpgradeChainResult(
        success: true,
        fromVersion: fromVersion,
        toVersion: toVersion,
        results: results,
        totalExecutionTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();

      AppLogger.error('升级链执行失败',
          error: e, stackTrace: stackTrace, tag: 'DataVersionAdapterManager');

      return UpgradeChainResult(
        success: false,
        fromVersion: fromVersion,
        toVersion: toVersion,
        results: results,
        totalExecutionTimeMs: stopwatch.elapsedMilliseconds,
        errorMessage: e.toString(),
      );
    }
  }

  /// 获取所有可用的适配器
  static List<DataVersionAdapter> getAllAdapters() {
    return _adapters.values.toList();
  }

  /// 检查是否支持指定的升级路径
  static bool isUpgradePathSupported(String fromVersion, String toVersion) {
    try {
      getUpgradeAdapters(fromVersion, toVersion);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取升级路径描述
  static String getUpgradePathDescription(
      String fromVersion, String toVersion) {
    try {
      final adapters = getUpgradeAdapters(fromVersion, toVersion);
      final descriptions =
          adapters.map((adapter) => adapter.description).toList();
      return descriptions.join(' → ');
    } catch (e) {
      return '不支持的升级路径';
    }
  }

  /// 估算升级时间
  static int estimateUpgradeTime(String fromVersion, String toVersion) {
    try {
      final adapters = getUpgradeAdapters(fromVersion, toVersion);
      return adapters.fold(
          0, (total, adapter) => total + adapter.estimatedProcessingTime);
    } catch (e) {
      return 0;
    }
  }
}

/// 适配器执行阶段
enum AdapterExecutionStage {
  preProcess,
  databaseMigration,
  postProcess,
  validation,
  unknown,
}

/// 适配器执行结果
class AdapterExecutionResult {
  final bool success;
  final DataVersionAdapter adapter;
  final AdapterExecutionStage? stage;
  final PreProcessResult? preProcessResult;
  final PostProcessResult? postProcessResult;
  final String? errorMessage;
  final int executionTimeMs;

  const AdapterExecutionResult({
    required this.success,
    required this.adapter,
    this.stage,
    this.preProcessResult,
    this.postProcessResult,
    this.errorMessage,
    required this.executionTimeMs,
  });

  factory AdapterExecutionResult.success({
    required DataVersionAdapter adapter,
    required PreProcessResult preProcessResult,
    required PostProcessResult postProcessResult,
    required int executionTimeMs,
  }) {
    return AdapterExecutionResult(
      success: true,
      adapter: adapter,
      preProcessResult: preProcessResult,
      postProcessResult: postProcessResult,
      executionTimeMs: executionTimeMs,
    );
  }

  factory AdapterExecutionResult.failure({
    required DataVersionAdapter adapter,
    required AdapterExecutionStage stage,
    required String errorMessage,
    required int executionTimeMs,
  }) {
    return AdapterExecutionResult(
      success: false,
      adapter: adapter,
      stage: stage,
      errorMessage: errorMessage,
      executionTimeMs: executionTimeMs,
    );
  }
}

/// 升级链结果
class UpgradeChainResult {
  final bool success;
  final String fromVersion;
  final String toVersion;
  final List<AdapterExecutionResult> results;
  final int totalExecutionTimeMs;
  final String? errorMessage;

  const UpgradeChainResult({
    required this.success,
    required this.fromVersion,
    required this.toVersion,
    required this.results,
    required this.totalExecutionTimeMs,
    this.errorMessage,
  });

  /// 获取成功的适配器数量
  int get successfulAdapters => results.where((r) => r.success).length;

  /// 获取失败的适配器数量
  int get failedAdapters => results.where((r) => !r.success).length;

  /// 获取总处理文件数
  int get totalProcessedFiles => results
      .where((r) => r.preProcessResult != null)
      .map((r) => r.preProcessResult!.processedFiles)
      .fold(0, (sum, count) => sum + count);

  /// 获取总处理记录数
  int get totalProcessedRecords => results
      .where((r) => r.postProcessResult != null)
      .map((r) => r.postProcessResult!.processedRecords)
      .fold(0, (sum, count) => sum + count);
}
