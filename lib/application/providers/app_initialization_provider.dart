import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/logging/logger.dart';
import '../services/app_initialization_service.dart';
import '../services/enhanced_backup_service.dart';
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
    bool unifiedConfigLoaded = false;
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
        unifiedConfigLoaded = true;
        final config = currentState.value;
        AppLogger.info('统一路径配置已加载', tag: 'AppInit', data: {
          'dataPath': config?.dataPath.useDefaultPath == true
              ? '默认路径'
              : config?.dataPath.customPath ?? '未知',
          'backupPath': config?.backupPath.path.isEmpty == true
              ? '未设置'
              : config?.backupPath.path ?? '未知',
        });
      } else {
        // 否则等待加载完成
        AppLogger.info('等待统一路径配置加载完成', tag: 'AppInit');

        // 使用超时保护
        bool timeoutOccurred = false;
        final timeout = Future.delayed(const Duration(seconds: 5), () {
          if (!unifiedConfigLoaded) {
            timeoutOccurred = true;
            AppLogger.warning('统一配置加载超时', tag: 'AppInit');
            throw Exception('统一配置加载超时');
          }
        });

        // 手动监听配置加载完成
        final completer = Completer<void>();
        final subscription = ref.listen<AsyncValue<dynamic>>(
          unified.unifiedPathConfigProvider,
          (_, next) {
            if (next is AsyncData && !completer.isCompleted) {
              unifiedConfigLoaded = true;
              final config = next.value;
              if (config != null) {
                AppLogger.info('统一路径配置加载成功', tag: 'AppInit', data: {
                  'dataPath': config.dataPath?.useDefaultPath == true
                      ? '默认路径'
                      : config.dataPath?.customPath ?? '未知',
                  'backupPath': config.backupPath?.path?.isEmpty == true
                      ? '未设置'
                      : config.backupPath?.path ?? '未知',
                });
              } else {
                AppLogger.warning('统一路径配置为null', tag: 'AppInit');
              }
              completer.complete();
            } else if (next is AsyncError && !completer.isCompleted) {
              AppLogger.error('统一路径配置加载失败',
                  error: next.error,
                  stackTrace: next.stackTrace,
                  tag: 'AppInit');
              completer.completeError(next.error, next.stackTrace);
            }
          },
          fireImmediately: true,
        );

        // 等待配置加载完成或超时
        try {
          await Future.any([completer.future, timeout]);
          subscription.close();
          if (timeoutOccurred) {
            throw Exception('统一配置加载超时');
          }
        } catch (e, stack) {
          subscription.close();
          AppLogger.warning('统一配置加载出错',
              error: e, stackTrace: stack, tag: 'AppInit');
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
          // 等待配置加载完成
          bool configLoaded = false;

          // 使用超时保护
          final timeout = Future.delayed(const Duration(seconds: 3), () {
            if (!configLoaded) {
              AppLogger.warning('旧配置加载超时', tag: 'AppInit');
              throw Exception('配置加载超时');
            }
          });

          // 手动监听配置加载完成
          final completer = Completer<void>();
          final subscription = ref.listen<AsyncValue<dynamic>>(
            dataPathConfigProvider,
            (_, next) {
              if (next is AsyncData && !completer.isCompleted) {
                configLoaded = true;
                final config = next.value;
                if (config != null) {
                  AppLogger.info('旧数据路径配置加载成功', tag: 'AppInit', data: {
                    'useDefaultPath': config.useDefaultPath,
                    'customPath': config.customPath,
                  });
                } else {
                  AppLogger.warning('旧数据路径配置为null', tag: 'AppInit');
                }
                completer.complete();
              } else if (next is AsyncError && !completer.isCompleted) {
                AppLogger.error('旧数据路径配置加载失败',
                    error: next.error,
                    stackTrace: next.stackTrace,
                    tag: 'AppInit');
                completer.completeError(next.error, next.stackTrace);
              }
            },
            fireImmediately: true,
          );

          // 等待配置加载完成或超时
          try {
            await Future.any([completer.future, timeout]);
          } finally {
            subscription.close();
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
