import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'infrastructure/logging/log_level.dart';
import 'infrastructure/logging/logger.dart';
import 'infrastructure/providers/shared_preferences_provider.dart';
import 'presentation/app.dart';
import 'utils/config/logging_config.dart';
import 'utils/keyboard/keyboard_monitor.dart';
import 'utils/keyboard/keyboard_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging config - default to minimal logging
  LoggingConfig.verboseStorageLogging = false;
  LoggingConfig.verboseThumbnailLogging = false;
  LoggingConfig.verboseDatabaseLogging = false;
  LoggingConfig.enableDebugPrints = false; // Turn off noisy prints

  // 初始化键盘工具
  KeyboardUtils.initialize();

  // 初始化窗口管理器
  await windowManager.ensureInitialized();

  // 设置初始窗口标题，后续会在应用中根据语言更新
  const appTitle = '字字珠玑'; // 默认使用中文标题

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: appTitle,
  );

  // 设置窗口
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    // 设置窗口图标，确保与任务栏图标一致
    // 注意：路径是相对于可执行文件的，不是相对于Flutter项目
    await windowManager.setIcon('resources/app_icon.ico');
    await windowManager.show();
    await windowManager.focus();
  });

  // 初始化日志系统，启用控制台输出和调试级别
  await AppLogger.init(enableConsole: true, minLevel: LogLevel.debug);
  try {
    // 初始化 SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // 创建ProviderContainer用于初始化阶段 - Use SilentObserver here too
    final container = ProviderContainer(
      observers: [
        SilentObserver()
      ], // Replace ProviderLogger with SilentObserver
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // 启动应用
    runApp(
      ProviderScope(
        parent: container,
        observers: [SilentObserver()],
        child: KeyboardMonitor.wrapApp(const MyApp()),
      ),
    );
  } catch (e, stack) {
    // 确保在初始化过程中的错误也能被记录
    if (AppLogger.hasHandlers) {
      AppLogger.fatal('应用启动失败', error: e, stackTrace: stack, tag: 'App');
    } else {
      // 如果日志系统未初始化，使用调试打印
      debugPrint('严重错误：应用启动失败: $e');
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
                  '应用启动失败: $e',
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
