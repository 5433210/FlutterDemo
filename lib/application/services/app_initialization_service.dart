import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../infrastructure/logging/logger.dart';
import '../providers/data_path_provider.dart';
import '../providers/unified_path_provider.dart' as unified;
import 'data_path_config_service.dart';

/// 应用启动初始化服务
///
/// 负责应用启动时的各种初始化工作，特别是数据路径相关的设置
class AppInitializationService {
  /// 初始化应用
  ///
  /// 这个方法应该在应用启动时调用，确保所有必要的初始化工作完成
  static Future<AppInitializationResult> initializeApp(WidgetRef ref) async {
    AppLogger.info('开始应用初始化', tag: 'AppInit');

    try {
      // 1. 初始化数据路径配置
      final dataPathResult = await _initializeDataPath(ref);
      if (!dataPathResult.isSuccess) {
        return AppInitializationResult.failure(
          '数据路径初始化失败: ${dataPathResult.errorMessage}',
        );
      }

      // 2. 验证数据完整性
      final dataIntegrityResult = await _verifyDataIntegrity(ref);
      if (!dataIntegrityResult.isSuccess) {
        AppLogger.warning('数据完整性检查失败: ${dataIntegrityResult.errorMessage}',
            tag: 'AppInit');
        // 数据完整性问题不应该阻止应用启动，只记录警告
      }

      // 3. 初始化存储服务
      try {
        await ref.read(unified.actualDataPathProvider.future);
        AppLogger.debug('存储服务预加载完成', tag: 'AppInit');
      } catch (e) {
        AppLogger.warning('存储服务预加载失败', error: e, tag: 'AppInit');
        // 存储服务会在需要时延迟加载，这里的失败不应该阻止应用启动
      }

      AppLogger.info('应用初始化完成', tag: 'AppInit');
      return AppInitializationResult.success();
    } catch (e, stack) {
      AppLogger.error('应用初始化失败', error: e, stackTrace: stack, tag: 'AppInit');
      return AppInitializationResult.failure('应用初始化过程中发生错误: $e');
    }
  }

  /// 初始化数据路径配置
  static Future<_InitResult> _initializeDataPath(WidgetRef ref) async {
    try {
      AppLogger.debug('开始初始化数据路径配置', tag: 'AppInit');

      // 读取数据路径配置
      final config = await DataPathConfigService.readConfig();

      // 获取实际数据路径
      final actualPath = await config.getActualDataPath();

      // 确保数据路径存在
      await _ensureDataPathExists(actualPath);

      // 检查和更新版本信息
      await _ensureDataVersionInfo(actualPath);

      AppLogger.info('数据路径配置初始化完成: $actualPath', tag: 'AppInit');
      return _InitResult.success();
    } catch (e) {
      AppLogger.error('数据路径配置初始化失败', error: e, tag: 'AppInit');
      return _InitResult.failure('数据路径配置初始化失败: $e');
    }
  }

  /// 验证数据完整性
  static Future<_InitResult> _verifyDataIntegrity(WidgetRef ref) async {
    try {
      AppLogger.debug('开始验证数据完整性', tag: 'AppInit');

      final configAsync = ref.read(dataPathConfigProvider);
      final config = configAsync.when(
        data: (config) => config,
        loading: () => throw Exception('配置加载中'),
        error: (error, _) => throw error,
      );

      final actualPath = await config.getActualDataPath();

      // 检查版本兼容性
      final compatibilityResult =
          await DataPathConfigService.checkDataCompatibility(actualPath);

      switch (compatibilityResult.status) {
        case DataCompatibilityStatus.compatible:
        case DataCompatibilityStatus.newDataPath:
          // 兼容或新路径，一切正常
          break;
        case DataCompatibilityStatus.upgradable:
          // 可升级，记录信息但不阻止启动
          AppLogger.info('检测到可升级的数据版本，将在后台升级',
              tag: 'AppInit',
              data: {'dataVersion': compatibilityResult.dataVersion});
          break;
        case DataCompatibilityStatus.incompatible:
        case DataCompatibilityStatus.needsAppUpgrade:
          // 不兼容的数据，这可能是个问题
          return _InitResult.failure(
              '数据版本不兼容: ${compatibilityResult.status} - ${compatibilityResult.dataVersion}');
        case DataCompatibilityStatus.unknownState:
          // 未知状态，记录警告
          AppLogger.warning('数据状态未知: ${compatibilityResult.message}',
              tag: 'AppInit');
          break;
      }

      AppLogger.debug('数据完整性验证完成', tag: 'AppInit');
      return _InitResult.success();
    } catch (e) {
      AppLogger.warning('数据完整性验证失败', error: e, tag: 'AppInit');
      return _InitResult.failure('数据完整性验证失败: $e');
    }
  }

  /// 确保数据路径存在
  static Future<void> _ensureDataPathExists(String dataPath) async {
    try {
      final dataDir = Directory(dataPath);
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
        AppLogger.debug('创建数据路径: $dataPath', tag: 'AppInit');
      }

      // 创建必要的子目录
      final subdirectories = ['storage', 'cache', 'logs'];
      for (final subdir in subdirectories) {
        final dir = Directory(path.join(dataPath, subdir));
        if (!await dir.exists()) {
          await dir.create(recursive: true);
          AppLogger.debug('创建子目录: ${dir.path}', tag: 'AppInit');
        }
      }
    } catch (e) {
      throw Exception('无法创建数据路径: $e');
    }
  }

  /// 确保数据版本信息存在
  static Future<void> _ensureDataVersionInfo(String dataPath) async {
    try {
      // 检查版本文件是否存在
      final compatibilityResult =
          await DataPathConfigService.checkDataCompatibility(dataPath);

      if (compatibilityResult.status == DataCompatibilityStatus.newDataPath) {
        // 新数据路径，创建版本文件
        await DataPathConfigService.writeDataVersion(dataPath);
        AppLogger.debug('为新数据路径创建版本信息', tag: 'AppInit');
      } else if (compatibilityResult.status ==
          DataCompatibilityStatus.upgradable) {
        // 可升级的数据，更新版本文件
        await DataPathConfigService.writeDataVersion(dataPath);
        AppLogger.info('升级数据版本信息', tag: 'AppInit');
      }
    } catch (e) {
      AppLogger.warning('处理数据版本信息失败', error: e, tag: 'AppInit');
      // 版本信息问题不应该阻止应用启动
    }
  }

  /// 获取应用初始化状态摘要
  static Future<AppInitializationStatus> getInitializationStatus() async {
    try {
      // 读取当前配置
      final config = await DataPathConfigService.readConfig();
      final actualPath = await config.getActualDataPath();

      // 检查数据路径状态
      final pathExists = await Directory(actualPath).exists();
      final compatibilityResult =
          await DataPathConfigService.checkDataCompatibility(actualPath);

      return AppInitializationStatus(
        isInitialized: true,
        dataPath: actualPath,
        isCustomPath: !config.useDefaultPath,
        dataPathExists: pathExists,
        dataCompatibilityStatus: compatibilityResult.status,
        lastInitialized: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('获取初始化状态失败', error: e, tag: 'AppInit');
      return AppInitializationStatus(
        isInitialized: false,
        dataPath: '',
        isCustomPath: false,
        dataPathExists: false,
        dataCompatibilityStatus: DataCompatibilityStatus.unknownState,
        lastInitialized: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }
}

/// 应用初始化结果
class AppInitializationResult {
  final bool isSuccess;
  final String? errorMessage;

  const AppInitializationResult._(this.isSuccess, this.errorMessage);

  factory AppInitializationResult.success() =>
      const AppInitializationResult._(true, null);

  factory AppInitializationResult.failure(String errorMessage) =>
      AppInitializationResult._(false, errorMessage);
}

/// 应用初始化状态
class AppInitializationStatus {
  final bool isInitialized;
  final String dataPath;
  final bool isCustomPath;
  final bool dataPathExists;
  final DataCompatibilityStatus dataCompatibilityStatus;
  final DateTime lastInitialized;
  final String? errorMessage;

  const AppInitializationStatus({
    required this.isInitialized,
    required this.dataPath,
    required this.isCustomPath,
    required this.dataPathExists,
    required this.dataCompatibilityStatus,
    required this.lastInitialized,
    this.errorMessage,
  });
}

/// 内部初始化结果
class _InitResult {
  final bool isSuccess;
  final String? errorMessage;

  const _InitResult._(this.isSuccess, this.errorMessage);

  factory _InitResult.success() => const _InitResult._(true, null);
  factory _InitResult.failure(String errorMessage) =>
      _InitResult._(false, errorMessage);
}
