import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'application/providers/app_initialization_provider.dart';
import 'application/services/enhanced_backup_service.dart';
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

  // 🚀 优化：延迟非关键初始化，加速应用启动
  // 初始化SQLite FFI (对于桌面平台)
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    // Windows和macOS使用默认初始化
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 🚀 优化：最小化启动时的日志配置
  LoggingConfig.verboseStorageLogging = false;
  LoggingConfig.verboseThumbnailLogging = false;
  LoggingConfig.verboseDatabaseLogging = false;

  // 🚀 优化：简化启动时的日志配置，推迟到需要时配置详细日志
  if (kDebugMode) {
    EditPageLoggingConfig.configureForDevelopment();
  } else {
    EditPageLoggingConfig.configureForProduction();
  }

  // 🚀 优化：延迟键盘工具初始化到实际需要时
  // KeyboardUtils.initialize();

  // 🚀 优化：简化窗口管理器初始化
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    // 🚀 优化：使用更简单的窗口配置，减少启动时间
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1400, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.white,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: '字字珠玑',
    );

    // 🚀 优化：简化窗口显示流程
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      // 延迟设置图标和背景色到窗口显示后
      _delayedWindowSetup();
    });
  }

  // 🚀 优化：简化日志初始化，减少启动开销
  String? logFilePath;
  if (Platform.isAndroid || Platform.isIOS) {
    // 移动端：禁用文件日志，避免权限问题
    logFilePath = null;
  } else {
    // 桌面端：使用相对路径
    logFilePath = 'app.log';
  }

  await AppLogger.init(
      enableFile: logFilePath != null,
      enableConsole: kDebugMode, // 只在调试模式启用控制台
      minLevel: kDebugMode ? LogLevel.debug : LogLevel.info,
      filePath: logFilePath);

  // 🚀 优化：只在调试模式启动性能监控器
  if (kDebugMode) {
    PerformanceMonitor().startMonitoring();
  }

  try {
    // 🚀 优化：并行初始化SharedPreferences和路径配置
    final futures = await Future.wait([
      SharedPreferences.getInstance(),
      _initializePathConfig(),
    ]);

    final prefs = futures[0] as SharedPreferences;

    // 🚀 优化：使用优化的ProviderContainer配置
    final container = ProviderContainer(
      observers: [SilentObserver()], // 避免Riverpod日志开销
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // 🚀 优化：简化预加载流程，减少启动阻塞
    _preloadAppDataAsync(container);

    // 🚀 优化：立即启动应用，避免阻塞主线程
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: _buildAppWithDelayedKeyboardMonitor(),
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

// 🚀 优化：延迟窗口设置，减少启动阻塞
void _delayedWindowSetup() {
  Future.delayed(const Duration(milliseconds: 100), () async {
    try {
      await windowManager.setIcon('assets/images/logo.ico');

      await windowManager.setBackgroundColor(Colors.white);
    } catch (e) {
      AppLogger.warning('延迟窗口设置失败', error: e, tag: 'App');
    }
  });
}

// 🚀 优化：异步路径配置初始化
Future<void> _initializePathConfig() async {
  if (!_unifiedPathConfigInitialized) {
    _unifiedPathConfigInitialized = true;
    try {
      await UnifiedPathConfigService.readConfig();
      AppLogger.info('统一路径配置初始化成功', tag: 'App');

      // 立即检查备份恢复，在任何Provider被触发之前
      try {
        await _checkAndCompleteBackupRestore();
      } catch (restoreError, restoreStack) {
        // 备份恢复失败记录详细错误，但不影响应用启动
        AppLogger.error('主程序备份恢复失败',
            error: restoreError, stackTrace: restoreStack, tag: 'App');
      }

      AppLogger.info('数据路径配置预加载完成', tag: 'App');
    } catch (e) {
      AppLogger.warning('统一路径配置初始化失败', error: e, tag: 'App');
    }
  }
}

/// 检查并完成备份恢复
Future<void> _checkAndCompleteBackupRestore() async {
  try {
    // 获取当前数据路径
    final config = await UnifiedPathConfigService.readConfig();
    final actualDataPath = await config.dataPath.getActualDataPath();

    // 调用备份恢复检查
    await EnhancedBackupService.checkAndCompleteRestoreAfterRestart(
        actualDataPath);
  } catch (e, stack) {
    AppLogger.error('主程序中备份恢复检查失败', error: e, stackTrace: stack, tag: 'App');
    // 备份恢复失败不应该阻止应用启动
  }
}

// 🚀 优化：异步预加载数据，不阻塞UI启动
void _preloadAppDataAsync(ProviderContainer container) {
  Future(() async {
    try {
      final initResult = await container.read(appInitializationProvider.future);
      if (initResult.isSuccess) {
        AppLogger.info('数据路径配置预加载完成', tag: 'App');
      }
    } catch (e) {
      AppLogger.error('数据预加载失败', error: e, tag: 'App');
    }
  });
}

// 🚀 优化：延迟键盘监控初始化
Widget _buildAppWithDelayedKeyboardMonitor() {
  return FutureBuilder(
    future: _delayedInitializeKeyboard(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.data == true) {
        return KeyboardMonitor.wrapApp(const MyApp());
      }
      return const MyApp(); // 直接显示应用，不等待键盘监控
    },
  );
}

// 🚀 优化：异步初始化键盘工具
Future<bool> _delayedInitializeKeyboard() async {
  await Future.delayed(const Duration(milliseconds: 200));
  try {
    KeyboardUtils.initialize();
    return true;
  } catch (e) {
    AppLogger.warning('键盘工具初始化失败', error: e, tag: 'App');
    return false;
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
