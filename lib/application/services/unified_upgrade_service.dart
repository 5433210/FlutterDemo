import 'dart:convert';
import 'dart:io';

import '../../infrastructure/logging/logger.dart';
import '../adapters/data_version_adapter_manager.dart';
import 'data_version_mapping_service.dart';

/// 升级检查结果
class UpgradeCheckResult {
  final UpgradeCheckStatus status;
  final String? fromVersion;
  final String? toVersion;
  final UpgradeChainResult? upgradeResult;
  final String? errorMessage;

  const UpgradeCheckResult({
    required this.status,
    this.fromVersion,
    this.toVersion,
    this.upgradeResult,
    this.errorMessage,
  });

  factory UpgradeCheckResult.compatible(String fromVersion, String toVersion) {
    return UpgradeCheckResult(
      status: UpgradeCheckStatus.compatible,
      fromVersion: fromVersion,
      toVersion: toVersion,
    );
  }

  factory UpgradeCheckResult.newDataDirectory(String version) {
    return UpgradeCheckResult(
      status: UpgradeCheckStatus.newDataDirectory,
      fromVersion: version, // 新目录的初始版本
      toVersion: version,
    );
  }

  factory UpgradeCheckResult.upgraded(
      String fromVersion, String toVersion, UpgradeChainResult result) {
    return UpgradeCheckResult(
      status: UpgradeCheckStatus.upgraded,
      fromVersion: fromVersion,
      toVersion: toVersion,
      upgradeResult: result,
    );
  }

  factory UpgradeCheckResult.appUpgradeRequired(
      String fromVersion, String toVersion) {
    return UpgradeCheckResult(
      status: UpgradeCheckStatus.appUpgradeRequired,
      fromVersion: fromVersion,
      toVersion: toVersion,
    );
  }

  factory UpgradeCheckResult.incompatible(
      String fromVersion, String toVersion) {
    return UpgradeCheckResult(
      status: UpgradeCheckStatus.incompatible,
      fromVersion: fromVersion,
      toVersion: toVersion,
    );
  }

  factory UpgradeCheckResult.unsupportedUpgradePath(
      String fromVersion, String toVersion) {
    return UpgradeCheckResult(
      status: UpgradeCheckStatus.unsupportedUpgradePath,
      fromVersion: fromVersion,
      toVersion: toVersion,
    );
  }

  factory UpgradeCheckResult.upgradeFailed(
      String fromVersion, String toVersion, String errorMessage) {
    return UpgradeCheckResult(
      status: UpgradeCheckStatus.upgradeFailed,
      fromVersion: fromVersion,
      toVersion: toVersion,
      errorMessage: errorMessage,
    );
  }

  factory UpgradeCheckResult.error(String errorMessage) {
    return UpgradeCheckResult(
      status: UpgradeCheckStatus.error,
      errorMessage: errorMessage,
    );
  }

  bool get isSuccess =>
      status == UpgradeCheckStatus.compatible ||
      status == UpgradeCheckStatus.newDataDirectory ||
      status == UpgradeCheckStatus.upgraded;
}

/// 升级检查状态
enum UpgradeCheckStatus {
  compatible,
  newDataDirectory,
  upgraded,
  appUpgradeRequired,
  incompatible,
  unsupportedUpgradePath,
  upgradeFailed,
  error,
}

/// 恢复升级结果
class RestoreUpgradeResult {
  final RestoreUpgradeStatus status;
  final String? fromVersion;
  final String? toVersion;
  final UpgradeChainResult? upgradeResult;
  final String? errorMessage;

  const RestoreUpgradeResult({
    required this.status,
    this.fromVersion,
    this.toVersion,
    this.upgradeResult,
    this.errorMessage,
  });

  factory RestoreUpgradeResult.compatible(
      String fromVersion, String toVersion) {
    return RestoreUpgradeResult(
      status: RestoreUpgradeStatus.compatible,
      fromVersion: fromVersion,
      toVersion: toVersion,
    );
  }

  factory RestoreUpgradeResult.upgraded(
      String fromVersion, String toVersion, UpgradeChainResult result) {
    return RestoreUpgradeResult(
      status: RestoreUpgradeStatus.upgraded,
      fromVersion: fromVersion,
      toVersion: toVersion,
      upgradeResult: result,
    );
  }

  factory RestoreUpgradeResult.appUpgradeRequired(
      String fromVersion, String toVersion) {
    return RestoreUpgradeResult(
      status: RestoreUpgradeStatus.appUpgradeRequired,
      fromVersion: fromVersion,
      toVersion: toVersion,
    );
  }

  factory RestoreUpgradeResult.incompatible(
      String fromVersion, String toVersion) {
    return RestoreUpgradeResult(
      status: RestoreUpgradeStatus.incompatible,
      fromVersion: fromVersion,
      toVersion: toVersion,
    );
  }

  factory RestoreUpgradeResult.error(String errorMessage) {
    return RestoreUpgradeResult(
      status: RestoreUpgradeStatus.error,
      errorMessage: errorMessage,
    );
  }

  factory RestoreUpgradeResult.fromUpgradeResult(
      UpgradeCheckResult upgradeResult) {
    switch (upgradeResult.status) {
      case UpgradeCheckStatus.compatible:
        return RestoreUpgradeResult.compatible(
            upgradeResult.fromVersion!, upgradeResult.toVersion!);
      case UpgradeCheckStatus.upgraded:
        return RestoreUpgradeResult.upgraded(upgradeResult.fromVersion!,
            upgradeResult.toVersion!, upgradeResult.upgradeResult!);
      case UpgradeCheckStatus.appUpgradeRequired:
        return RestoreUpgradeResult.appUpgradeRequired(
            upgradeResult.fromVersion!, upgradeResult.toVersion!);
      case UpgradeCheckStatus.incompatible:
        return RestoreUpgradeResult.incompatible(
            upgradeResult.fromVersion!, upgradeResult.toVersion!);
      default:
        return RestoreUpgradeResult.error(upgradeResult.errorMessage ?? '未知错误');
    }
  }

  bool get isSuccess =>
      status == RestoreUpgradeStatus.compatible ||
      status == RestoreUpgradeStatus.upgraded;
}

/// 恢复升级状态
enum RestoreUpgradeStatus {
  compatible,
  upgraded,
  appUpgradeRequired,
  incompatible,
  error,
}

/// 升级状态
class UpgradeState {
  final String fromVersion;
  final String toVersion;
  final UpgradeStatus status;
  final DateTime startTime;
  final DateTime lastUpdated;

  const UpgradeState({
    required this.fromVersion,
    required this.toVersion,
    required this.status,
    required this.startTime,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'fromVersion': fromVersion,
      'toVersion': toVersion,
      'status': status.name,
      'startTime': startTime.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UpgradeState.fromMap(Map<String, dynamic> map) {
    return UpgradeState(
      fromVersion: map['fromVersion'],
      toVersion: map['toVersion'],
      status: UpgradeStatus.values.firstWhere((s) => s.name == map['status']),
      startTime: DateTime.parse(map['startTime']),
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}

/// 升级状态枚举
enum UpgradeStatus {
  inProgress,
  completed,
  failed,
}

/// 统一升级服务
/// 负责应用启动时的自动升级和跨版本升级处理
class UnifiedUpgradeService {
  static const String _upgradeStateFileName = 'upgrade_state.json';
  static const String _dataVersionFileName = 'data_version.json';

  /// 检查并执行应用启动时的自动升级
  static Future<UpgradeCheckResult> checkAndUpgradeOnStartup(
      String dataPath) async {
    try {
      AppLogger.info('开始检查应用启动升级', tag: 'UnifiedUpgradeService', data: {
        'dataPath': dataPath,
      });

      // 1. 获取当前应用的数据版本
      final currentAppDataVersion =
          await DataVersionMappingService.getCurrentDataVersion();

      // 2. 获取数据目录的版本信息
      final dataVersionInfo = await _getDataVersionInfo(dataPath);
      final dataDirectoryVersion = dataVersionInfo['dataVersion'] as String?;

      if (dataDirectoryVersion == null) {
        // 新数据目录，写入当前版本信息
        await _writeDataVersionInfo(dataPath, currentAppDataVersion);
        return UpgradeCheckResult.newDataDirectory(currentAppDataVersion);
      }

      // 3. 检查是否需要升级
      final compatibility = DataVersionMappingService.checkCompatibility(
          dataDirectoryVersion, currentAppDataVersion);

      switch (compatibility) {
        case DataVersionCompatibility.compatible:
          return UpgradeCheckResult.compatible(
              dataDirectoryVersion, currentAppDataVersion);

        case DataVersionCompatibility.upgradable:
          // 需要升级数据
          return await _executeDataUpgrade(
              dataPath, dataDirectoryVersion, currentAppDataVersion);

        case DataVersionCompatibility.appUpgradeRequired:
          return UpgradeCheckResult.appUpgradeRequired(
              dataDirectoryVersion, currentAppDataVersion);

        case DataVersionCompatibility.incompatible:
          return UpgradeCheckResult.incompatible(
              dataDirectoryVersion, currentAppDataVersion);
      }
    } catch (e, stackTrace) {
      AppLogger.error('应用启动升级检查失败',
          error: e, stackTrace: stackTrace, tag: 'UnifiedUpgradeService');

      return UpgradeCheckResult.error(e.toString());
    }
  }

  /// 执行备份恢复时的数据升级
  static Future<RestoreUpgradeResult> upgradeForRestore(
    String dataPath,
    String backupDataVersion,
  ) async {
    try {
      AppLogger.info('开始备份恢复升级', tag: 'UnifiedUpgradeService', data: {
        'dataPath': dataPath,
        'backupDataVersion': backupDataVersion,
      });

      final currentAppDataVersion =
          await DataVersionMappingService.getCurrentDataVersion();

      // 检查兼容性
      final compatibility = DataVersionMappingService.checkCompatibility(
          backupDataVersion, currentAppDataVersion);

      switch (compatibility) {
        case DataVersionCompatibility.compatible:
          // 直接兼容，无需升级
          await _writeDataVersionInfo(dataPath, currentAppDataVersion);
          return RestoreUpgradeResult.compatible(
              backupDataVersion, currentAppDataVersion);

        case DataVersionCompatibility.upgradable:
          // 需要升级数据
          final upgradeResult = await _executeDataUpgrade(
              dataPath, backupDataVersion, currentAppDataVersion);
          return RestoreUpgradeResult.fromUpgradeResult(upgradeResult);

        case DataVersionCompatibility.appUpgradeRequired:
          return RestoreUpgradeResult.appUpgradeRequired(
              backupDataVersion, currentAppDataVersion);

        case DataVersionCompatibility.incompatible:
          return RestoreUpgradeResult.incompatible(
              backupDataVersion, currentAppDataVersion);
      }
    } catch (e, stackTrace) {
      AppLogger.error('备份恢复升级失败',
          error: e, stackTrace: stackTrace, tag: 'UnifiedUpgradeService');

      return RestoreUpgradeResult.error(e.toString());
    }
  }

  /// 检查升级状态
  static Future<UpgradeState?> checkUpgradeState(String dataPath) async {
    try {
      final stateFile = File('$dataPath/$_upgradeStateFileName');
      if (!await stateFile.exists()) {
        return null;
      }

      final stateData = jsonDecode(await stateFile.readAsString());
      return UpgradeState.fromMap(stateData);
    } catch (e) {
      AppLogger.error('检查升级状态失败', error: e, tag: 'UnifiedUpgradeService');
      return null;
    }
  }

  /// 清理升级状态
  static Future<void> clearUpgradeState(String dataPath) async {
    try {
      final stateFile = File('$dataPath/$_upgradeStateFileName');
      if (await stateFile.exists()) {
        await stateFile.delete();
        AppLogger.info('清理升级状态完成', tag: 'UnifiedUpgradeService');
      }
    } catch (e) {
      AppLogger.error('清理升级状态失败', error: e, tag: 'UnifiedUpgradeService');
    }
  }

  /// 执行数据升级
  static Future<UpgradeCheckResult> _executeDataUpgrade(
    String dataPath,
    String fromVersion,
    String toVersion,
  ) async {
    try {
      AppLogger.info('开始执行数据升级', tag: 'UnifiedUpgradeService', data: {
        'fromVersion': fromVersion,
        'toVersion': toVersion,
        'dataPath': dataPath,
      });

      // 检查是否支持升级路径
      if (!DataVersionAdapterManager.isUpgradePathSupported(
          fromVersion, toVersion)) {
        return UpgradeCheckResult.unsupportedUpgradePath(
            fromVersion, toVersion);
      }

      // 保存升级状态
      await _saveUpgradeState(
          dataPath, fromVersion, toVersion, UpgradeStatus.inProgress);

      // 执行升级链
      final chainResult = await DataVersionAdapterManager.executeUpgradeChain(
          fromVersion, toVersion, dataPath);

      if (chainResult.success) {
        // 升级成功，更新数据版本信息
        await _writeDataVersionInfo(dataPath, toVersion);
        await _saveUpgradeState(
            dataPath, fromVersion, toVersion, UpgradeStatus.completed);

        AppLogger.info('数据升级成功', tag: 'UnifiedUpgradeService', data: {
          'fromVersion': fromVersion,
          'toVersion': toVersion,
          'totalExecutionTimeMs': chainResult.totalExecutionTimeMs,
          'processedFiles': chainResult.totalProcessedFiles,
          'processedRecords': chainResult.totalProcessedRecords,
        });

        return UpgradeCheckResult.upgraded(fromVersion, toVersion, chainResult);
      } else {
        // 升级失败
        await _saveUpgradeState(
            dataPath, fromVersion, toVersion, UpgradeStatus.failed);

        AppLogger.error('数据升级失败', tag: 'UnifiedUpgradeService', data: {
          'fromVersion': fromVersion,
          'toVersion': toVersion,
          'errorMessage': chainResult.errorMessage,
        });

        return UpgradeCheckResult.upgradeFailed(
            fromVersion, toVersion, chainResult.errorMessage ?? '升级失败');
      }
    } catch (e, stackTrace) {
      AppLogger.error('执行数据升级异常',
          error: e, stackTrace: stackTrace, tag: 'UnifiedUpgradeService');

      await _saveUpgradeState(
          dataPath, fromVersion, toVersion, UpgradeStatus.failed);
      return UpgradeCheckResult.error(e.toString());
    }
  }

  /// 获取数据版本信息
  static Future<Map<String, dynamic>> _getDataVersionInfo(
      String dataPath) async {
    try {
      final versionFile = File('$dataPath/$_dataVersionFileName');
      if (!await versionFile.exists()) {
        return {};
      }

      return jsonDecode(await versionFile.readAsString());
    } catch (e) {
      AppLogger.warning('读取数据版本信息失败', error: e, tag: 'UnifiedUpgradeService');
      return {};
    }
  }

  /// 写入数据版本信息
  static Future<void> _writeDataVersionInfo(
      String dataPath, String dataVersion) async {
    try {
      final versionFile = File('$dataPath/$_dataVersionFileName');
      final versionInfo = {
        'dataVersion': dataVersion,
        'lastUpdated': DateTime.now().toIso8601String(),
        'appVersion': await DataVersionMappingService.getCurrentDataVersion(),
      };

      await versionFile.writeAsString(jsonEncode(versionInfo));

      AppLogger.debug('写入数据版本信息', tag: 'UnifiedUpgradeService', data: {
        'dataVersion': dataVersion,
        'dataPath': dataPath,
      });
    } catch (e) {
      AppLogger.error('写入数据版本信息失败', error: e, tag: 'UnifiedUpgradeService');
      rethrow;
    }
  }

  /// 保存升级状态
  static Future<void> _saveUpgradeState(
    String dataPath,
    String fromVersion,
    String toVersion,
    UpgradeStatus status,
  ) async {
    try {
      final stateFile = File('$dataPath/$_upgradeStateFileName');
      final state = UpgradeState(
        fromVersion: fromVersion,
        toVersion: toVersion,
        status: status,
        startTime: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      await stateFile.writeAsString(jsonEncode(state.toMap()));
    } catch (e) {
      AppLogger.error('保存升级状态失败', error: e, tag: 'UnifiedUpgradeService');
    }
  }
}
