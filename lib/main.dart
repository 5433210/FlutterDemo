import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'application/providers/app_initialization_provider.dart';
import 'application/services/unified_path_config_service.dart';
import 'infrastructure/logging/log_level.dart';
import 'infrastructure/logging/logger.dart';
import 'infrastructure/monitoring/performance_monitor.dart';
import 'infrastructure/providers/shared_preferences_provider.dart';
import 'presentation/app.dart';
import 'utils/config/edit_page_logging_config.dart';
import 'utils/config/logging_config.dart';
import 'utils/keyboard/keyboard_monitor.dart';
import 'utils/keyboard/keyboard_utils.dart';

// 添加标志位，防止重复初始化
bool _unifiedPathConfigInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化SQLite FFI (对于桌面平台)
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    // Windows和macOS使用默认初始化
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize logging config - default to minimal logging
  LoggingConfig.verboseStorageLogging = false;
  LoggingConfig.verboseThumbnailLogging = false;
  LoggingConfig.verboseDatabaseLogging = false;

  // 初始化字帖编辑页日志配置
  if (kDebugMode) {
    EditPageLoggingConfig.configureForDevelopment();
    AppLogger.info('已启用字帖编辑页开发环境日志配置', tag: 'App');
  } else {
    EditPageLoggingConfig.configureForProduction();
    AppLogger.info('已启用字帖编辑页生产环境日志配置', tag: 'App');
  }

  // 初始化键盘工具
  KeyboardUtils.initialize();

  // Only initialize window manager on desktop platforms
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    // 初始化窗口管理器
    await windowManager.ensureInitialized();

    // 设置初始窗口标题，后续会在应用中根据语言更新
    const appTitle = '字字珠玑'; // 默认使用中文标题

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1400, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.white,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: appTitle,
    ); // 设置窗口
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      // 设置窗口图标，确保与任务栏图标一致
      await windowManager.setIcon('assets/images/app_trans_bg4.ico');
      // 确保窗口背景不透明
      await windowManager.setBackgroundColor(Colors.white);
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // 初始化日志系统，启用控制台输出和调试级别
  await AppLogger.init(
      enableFile: true,
      enableConsole: true,
      minLevel: LogLevel.debug,
      filePath: 'app.log');

  // 🚀 启动性能监控器
  PerformanceMonitor().startMonitoring();
  AppLogger.info('性能监控器已启动', tag: 'App');

  try {
    // 初始化 SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // 初始化统一路径配置（确保只初始化一次）
    if (!_unifiedPathConfigInitialized) {
      _unifiedPathConfigInitialized = true;
      try {
        AppLogger.info('开始初始化统一路径配置', tag: 'App');
        final unifiedConfig = await UnifiedPathConfigService.readConfig();
        AppLogger.info('统一路径配置初始化成功', tag: 'App', data: {
          'dataPath': unifiedConfig.dataPath.useDefaultPath
              ? '默认路径'
              : unifiedConfig.dataPath.customPath,
          'backupPath': unifiedConfig.backupPath.path.isEmpty
              ? '未设置'
              : unifiedConfig.backupPath.path,
          'dataHistoryCount': unifiedConfig.dataPath.historyPaths.length,
          'backupHistoryCount': unifiedConfig.backupPath.historyPaths.length,
        });
      } catch (e) {
        AppLogger.warning('统一路径配置初始化失败，将使用旧配置', error: e, tag: 'App');
      }
    }

    // 创建ProviderContainer用于初始化阶段 - Use SilentObserver here too
    final container = ProviderContainer(
      observers: [
        SilentObserver()
      ], // Replace ProviderLogger with SilentObserver
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // 预加载数据路径配置
    try {
      AppLogger.info('开始预加载数据路径配置', tag: 'App');
      final initResult = await container.read(appInitializationProvider.future);
      if (initResult.isSuccess) {
        AppLogger.info('数据路径配置预加载成功', tag: 'App');
      } else {
        AppLogger.warning('数据路径配置预加载失败: ${initResult.errorMessage}',
            tag: 'App');
      }

      // 备份恢复检查现在在应用初始化过程中处理
    } catch (e) {
      AppLogger.error('数据路径配置预加载出错', error: e, tag: 'App');
      // 备份恢复检查现在在应用初始化过程中处理，即使预加载失败也会尝试
    }

    // 启动应用
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: KeyboardMonitor.wrapApp(const MyApp()),
      ),
    );
  } catch (e, stack) {
    // 确保在初始化过程中的错误也能被记录
    if (AppLogger.hasHandlers) {
      AppLogger.fatal('应用启动失败', error: e, stackTrace: stack, tag: 'App');
    } else {
      // 如果日志系统未初始化，使用调试打印
      debugPrint('Critical error: App startup failed: $e');
      debugPrint('$stack');
    }

    // 显示基本的错误界面
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'App startup failed: $e',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom provider observer that filters log messages
class FilteredProviderObserver extends ProviderObserver {
  // List of providers to ignore in logs
  static final _ignoredProviders = ['cursor', 'position', 'render', 'path'];

  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    // Skip logging for certain providers that update frequently
    final name = provider.name ?? '';
    if (_ignoredProviders.any((term) => name.contains(term))) {
      return; // Skip logging entirely
    }

    // For other providers, only log significant updates
    if (previousValue != newValue) {
      debugPrint('[Provider] ${provider.name}: updated');
    }
  }
}

/// Riverpod 日志记录器 - This class won't be used anymore
class ProviderLogger extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase<dynamic> provider,
    Object? value,
    ProviderContainer container,
  ) {
    AppLogger.debug(
      'Provider $provider was initialized with $value',
      tag: 'Riverpod',
    );
  }

  @override
  void didDisposeProvider(
    ProviderBase<dynamic> provider,
    ProviderContainer container,
  ) {
    AppLogger.debug('Provider $provider was disposed', tag: 'Riverpod');
  }

  @override
  void didUpdateProvider(
    ProviderBase<dynamic> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (previousValue != newValue) {
      AppLogger.debug(
        'Provider $provider updated from $previousValue to $newValue',
        tag: 'Riverpod',
      );
    }
  }
}

/// Silent observer that disables Riverpod's default logging
class SilentObserver extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    // Do nothing - silence logging
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    // Do nothing - silence logging
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    // Do nothing - silence logging
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    // Optional: You might want to still log critical errors
    // print('Provider $provider failed with: $error');
  }
}
