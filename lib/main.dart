import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'infrastructure/logging/log_level.dart';
import 'infrastructure/logging/logger.dart';
import 'infrastructure/providers/shared_preferences_provider.dart';
import 'presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化窗口管理器
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  // 设置窗口
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 初始化日志系统，启用控制台输出和调试级别
  await AppLogger.init(enableConsole: true, minLevel: LogLevel.debug);
  try {
    // 初始化 SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // 创建ProviderContainer用于初始化阶段
    final container = ProviderContainer(
      observers: [ProviderLogger()],
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // // 等待数据库初始化完成
    // AppLogger.info('等待数据库初始化', tag: 'App');
    // await container.read(databaseProvider.future);
    // AppLogger.info('数据库初始化完成', tag: 'App');

    // // 执行初始化检查
    // AppLogger.info('开始应用初始化检查', tag: 'App');
    // await container.read(initializationControllerProvider).runInitialChecks();
    // AppLogger.info('应用初始化检查完成', tag: 'App');

    // 启动应用
    runApp(
      ProviderScope(
        parent: container,
        observers: [ProviderLogger()],
        child: const MyApp(),
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

/// Riverpod 日志记录器
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
