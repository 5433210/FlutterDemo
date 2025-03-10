import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'infrastructure/logging/logger.dart';
import 'infrastructure/providers/shared_preferences_provider.dart';
import 'presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 初始化 SharedPreferences (关键步骤)
    final prefs = await SharedPreferences.getInstance();

    // 启动应用，提供 SharedPreferences 实例
    runApp(
      ProviderScope(
        observers: [ProviderLogger()],
        overrides: [
          // 覆盖 sharedPreferencesProvider
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stack) {
    // 确保在初始化过程中的错误也能被记录
    if (AppLogger.hasHandlers) {
      AppLogger.fatal(
        '应用启动失败',
        error: e,
        stackTrace: stack,
        tag: 'App',
      );
    } else {
      // 如果日志系统未初始化，使用调试打印
      debugPrint('严重错误：应用启动失败: $e');
      debugPrint('$stack');
    }

    // 显示基本的错误界面
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('应用启动失败: $e'),
        ),
      ),
    ));
  }
}

/// Riverpod 日志记录器（仅在调试模式下使用）
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
    AppLogger.debug(
      'Provider $provider was disposed',
      tag: 'Riverpod',
    );
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
