import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/logging/logger.dart';
import '../services/app_initialization_service.dart';
import 'data_path_provider.dart';
import 'import_export_providers.dart';
import 'unified_path_provider.dart' as unified;

/// 应用初始化Provider
/// 管理应用启动时的初始化状态
final appInitializationProvider =
    FutureProvider<AppInitializationResult>((ref) async {
  AppLogger.info('开始应用初始化流程', tag: 'AppInit');
  // 创建一个简化的初始化方法，直接使用FutureProviderRef
  final result = await _initializeAppWithRef(ref);
  AppLogger.info('应用初始化流程完成', tag: 'AppInit', data: {
    'isSuccess': result.isSuccess,
    'errorMessage': result.errorMessage,
  });
  return result;
});

/// 简化的初始化方法，适配Provider环境
Future<AppInitializationResult> _initializeAppWithRef(Ref ref) async {
  try {
    AppLogger.info('开始加载统一路径配置', tag: 'AppInit');
    // 确保统一路径配置加载
    try {
      // 重要：使用read而不是watch来获取provider
      // 这样可以避免在异步操作中使用watch导致的依赖变化问题
      // final unifiedConfigProvider =
      //     ref.read(unified.unifiedPathConfigProvider.notifier);

      // 先检查当前状态
      final currentState = ref.read(unified.unifiedPathConfigProvider);
      AppLogger.debug('统一路径配置Provider当前状态: ${currentState.toString()}',
          tag: 'AppInit');

      // 如果已经加载完成，直接使用
      if (currentState is AsyncData) {
        final config = currentState.value;
        AppLogger.info('统一路径配置已加载', tag: 'AppInit', data: {
          'dataPath': config?.dataPath.useDefaultPath == true
              ? '默认路径'
              : config?.dataPath.customPath ?? '未知',
          'backupPath': config?.backupPath.path.isEmpty == true
              ? '未设置'
              : config?.backupPath.path,
        });
      } else {
        // 否则等待加载完成
        AppLogger.info('等待统一路径配置加载完成', tag: 'AppInit');

        // 使用直接读取而非等待Future，避免在provider重建期间使用ref.listen
        try {
          final currentState = ref.read(unified.unifiedPathConfigProvider);
          if (currentState is AsyncData) {
            final config = currentState.value;
            
            if (config != null) {
              AppLogger.info('统一路径配置加载成功', tag: 'AppInit', data: {
                'dataPath': config.dataPath.useDefaultPath == true
                    ? '默认路径'
                    : config.dataPath.customPath ?? '未知',
                'backupPath': config.backupPath.path.isEmpty == true
                    ? '未设置'
                    : config.backupPath.path,
              });
            } else {
              AppLogger.warning('统一路径配置为null', tag: 'AppInit');
            }
          } else if (currentState is AsyncLoading) {
            // 等待一个简短的时间后重试
            await Future.delayed(const Duration(milliseconds: 100));
            final retryState = ref.read(unified.unifiedPathConfigProvider);
            if (retryState is AsyncData) {
              AppLogger.info('统一路径配置重试后加载成功', tag: 'AppInit');
            } else {
              throw Exception('统一配置加载超时');
            }
          } else if (currentState is AsyncError) {
            throw currentState.error!;
          }
        } catch (e, stack) {
          AppLogger.error('统一路径配置加载失败',
              error: e,
              stackTrace: stack,
              tag: 'AppInit');
          rethrow;
        }
      }
    } catch (e, stack) {
      AppLogger.warning('统一配置加载失败，尝试回退到旧配置',
          error: e, stackTrace: stack, tag: 'AppInit');

      // 如果统一配置失败，回退到旧配置
      // 确保数据路径配置加载
      AppLogger.info('开始加载旧数据路径配置', tag: 'AppInit');

      try {
        // 重要：使用read而不是watch来获取provider
        final dataPathAsync = ref.read(dataPathConfigProvider);

        if (dataPathAsync is AsyncData) {
          final config = dataPathAsync.value;
          if (config != null) {
            AppLogger.info('旧数据路径配置已加载', tag: 'AppInit', data: {
              'useDefaultPath': config.useDefaultPath,
              'customPath': config.customPath,
            });
          } else {
            AppLogger.warning('旧数据路径配置为null', tag: 'AppInit');
          }
        } else {
          // 等待配置加载完成，使用直接读取避免ref.listen问题
          try {
            await Future.delayed(const Duration(milliseconds: 100));
            final retryDataPathAsync = ref.read(dataPathConfigProvider);
            if (retryDataPathAsync is AsyncData) {
              final config = retryDataPathAsync.value;
              if (config != null) {
                AppLogger.info('旧数据路径配置重试后加载成功', tag: 'AppInit', data: {
                  'useDefaultPath': config.useDefaultPath,
                  'customPath': config.customPath,
                });
              } else {
                AppLogger.warning('旧数据路径配置重试后仍为null', tag: 'AppInit');
              }
            } else {
              throw Exception('旧数据路径配置加载超时');
            }
          } catch (e, stack) {
            AppLogger.error('旧数据路径配置重试失败',
                error: e, stackTrace: stack, tag: 'AppInit');
            rethrow;
          }
        }
      } catch (innerError, innerStack) {
        AppLogger.error('旧数据路径配置加载失败',
            error: innerError, stackTrace: innerStack, tag: 'AppInit');
        rethrow;
      }
    }

    // 确保实际数据路径加载
    AppLogger.info('开始加载实际数据路径', tag: 'AppInit');

    // 使用统一路径配置的actualDataPathProvider
    final actualPathFuture = ref.read(unified.actualDataPathProvider.future);
    final actualPath = await actualPathFuture;

    AppLogger.info('实际数据路径加载成功', tag: 'AppInit', data: {
      'actualPath': actualPath,
    });

    // 备份恢复已在main.dart中完成，此处不再重复执行

    // 确保ServiceLocator初始化（这会注册所有必要的服务，包括EnhancedBackupService）
    AppLogger.info('开始初始化服务定位器', tag: 'AppInit');

    // 使用read而不是watch，然后手动等待Future完成
    final serviceLocatorFuture = ref.read(serviceLocatorProvider.future);
    await serviceLocatorFuture;

    AppLogger.info('服务定位器初始化成功', tag: 'AppInit');

    return AppInitializationResult.success();
  } catch (e, stack) {
    AppLogger.error('应用初始化失败', error: e, stackTrace: stack, tag: 'AppInit');
    return AppInitializationResult.failure('应用初始化失败: $e');
  }
}

/// 应用初始化状态Provider
/// 提供应用初始化状态的详细信息
final appInitializationStatusProvider =
    FutureProvider<AppInitializationStatus>((ref) async {
  AppLogger.info('获取应用初始化状态', tag: 'AppInit');
  final status = await AppInitializationService.getInitializationStatus();
  AppLogger.info('应用初始化状态获取成功', tag: 'AppInit', data: {
    'status': status.toString(),
  });
  return status;
});

/// 应用是否已初始化Provider
/// 简单的布尔值Provider，用于快速检查应用是否已初始化
final appIsInitializedProvider = Provider<bool>((ref) {
  final initAsync = ref.watch(appInitializationProvider);
  final isInitialized = initAsync.when(
    data: (result) => result.isSuccess,
    loading: () => false,
    error: (_, __) => false,
  );
  AppLogger.info('应用初始化状态检查', tag: 'AppInit', data: {
    'isInitialized': isInitialized,
    'state': initAsync.toString(),
  });
  return isInitialized;
});
