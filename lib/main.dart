import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

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
import 'version_config.dart';

// 全局初始化状态管理
class _GlobalInitializationState {
  static bool _pathConfigInitialized = false;
  static bool _loggingInitialized = false;
  static bool _preferencesInitialized = false;
  static bool _versionConfigInitialized = false;
  static bool _windowInitialized = false;

  // 初始化结果缓存
  static SharedPreferences? _cachedPreferences;
  static String? _cachedDataPath;

  static void reset() {
    _pathConfigInitialized = false;
    _loggingInitialized = false;
    _preferencesInitialized = false;
    _versionConfigInitialized = false;
    _windowInitialized = false;
    _cachedPreferences = null;
    _cachedDataPath = null;
  }

  static bool get isInitialized =>
      _pathConfigInitialized &&
      _loggingInitialized &&
      _preferencesInitialized &&
      _versionConfigInitialized;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 重置初始化状态（用于热重载）
  if (kDebugMode) {
    _GlobalInitializationState.reset();
  }

  // 🚀 优化：最小化启动日志配置
  _configureMinimalLogging();

  // 🚀 优化：简化SQLite初始化
  _initializeSQLite();

  // 🚀 优化：后台初始化窗口管理
  _initializeWindowAsync();

  try {
    // 🚀 优化：分阶段并行初始化，避免重复操作
    await _performOptimizedInitialization();

    // 🚀 优化：立即启动应用，使用优化版本
    final container = _createOptimizedProviderContainer();

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: _buildOptimizedApp(),
      ),
    );
  } catch (e, stack) {
    _handleStartupError(e, stack);
  }
}

/// 最小化日志配置
void _configureMinimalLogging() {
  LoggingConfig.verboseStorageLogging = false;
  LoggingConfig.verboseThumbnailLogging = false;
  LoggingConfig.verboseDatabaseLogging = false;

  if (kDebugMode) {
    EditPageLoggingConfig.configureForDevelopment();
  } else {
    EditPageLoggingConfig.configureForProduction();
  }
}

/// 初始化SQLite
void _initializeSQLite() {
  if (_GlobalInitializationState._windowInitialized) return;

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

/// 异步初始化窗口管理
void _initializeWindowAsync() {
  if (_GlobalInitializationState._windowInitialized) return;
  _GlobalInitializationState._windowInitialized = true;

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    Future(() async {
      try {
        await windowManager.ensureInitialized();

        const windowOptions = WindowOptions(
          size: Size(1400, 800),
          minimumSize: Size(800, 600),
          center: true,
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.hidden,
          windowButtonVisibility: false,
          title: '字字珠玑',
        );
        await windowManager.setIcon('assets/images/logo.ico');
        await windowManager.waitUntilReadyToShow(windowOptions, () async {
          // await windowManager.setAsFrameless();
          await windowManager.setHasShadow(false);
          await windowManager.show();
          await windowManager.focus();

          // 延迟设置非关键属性
          Future.delayed(const Duration(milliseconds: 200), () async {
            try {
              // 确保窗口背景色与主题一致
              // await windowManager.setBackgroundColor(Colors.white);
              if (Platform.isWindows) {}
            } catch (e) {
              AppLogger.warning('延迟窗口设置失败', error: e, tag: 'App');
            }
          });
        });
      } catch (e) {
        debugPrint('窗口管理器初始化失败: $e');
      }
    });
  }
}

/// 执行优化的初始化流程
Future<void> _performOptimizedInitialization() async {
  // 第一阶段：关键路径初始化（顺序执行）
  await _initializeCriticalPath();

  // 第二阶段：并行初始化非关键组件
  await _initializeNonCriticalComponents();

  // 第三阶段：后台初始化可延迟组件
  _initializeDeferredComponents();
}

/// 初始化关键路径组件
Future<void> _initializeCriticalPath() async {
  // 1. 初始化路径配置（必须最先初始化，为日志系统提供路径）
  if (!_GlobalInitializationState._pathConfigInitialized) {
    await _initializePathConfig();
    _GlobalInitializationState._pathConfigInitialized = true;
  }

  // 2. 初始化日志系统（使用路径配置的数据路径）
  if (!_GlobalInitializationState._loggingInitialized) {
    await _initializeLogging();
    _GlobalInitializationState._loggingInitialized = true;
  }

  // 3. 检查备份恢复（必须在应用启动前）
  await _checkBackupRestore();
}

/// 初始化非关键组件
Future<void> _initializeNonCriticalComponents() async {
  final futures = <Future<void>>[];

  // 并行初始化SharedPreferences和版本配置
  if (!_GlobalInitializationState._preferencesInitialized) {
    futures.add(_initializePreferences());
  }

  if (!_GlobalInitializationState._versionConfigInitialized) {
    futures.add(_initializeVersionConfig());
  }

  await Future.wait(futures, eagerError: false);
}

/// 初始化可延迟组件
void _initializeDeferredComponents() {
  // 后台启动性能监控
  if (kDebugMode) {
    Future.delayed(const Duration(milliseconds: 500), () {
      PerformanceMonitor().startMonitoring();
    });
  }

  // 延迟初始化键盘工具
  Future.delayed(const Duration(milliseconds: 300), () {
    try {
      KeyboardUtils.initialize();
    } catch (e) {
      AppLogger.warning('键盘工具初始化失败', error: e, tag: 'App');
    }
  });
}

/// 初始化日志系统
Future<void> _initializeLogging() async {
  try {
    String? logFilePath;

    if (Platform.isAndroid || Platform.isIOS) {
      logFilePath = null; // 移动端禁用文件日志
    } else {
      // 使用已缓存的数据路径（由_initializePathConfig提供）
      String dataPath = _GlobalInitializationState._cachedDataPath ??
          path.join(Directory.systemTemp.path, 'charasgem');
      logFilePath = path.join(dataPath, 'logs', 'app.log');
    }

    await AppLogger.init(
      enableFile: logFilePath != null,
      enableConsole: kDebugMode,
      minLevel: kDebugMode ? LogLevel.debug : LogLevel.info,
      filePath: logFilePath,
      maxFileSizeBytes: 10 * 1024 * 1024,
      maxFiles: 5,
    );

    if (logFilePath != null) {
      AppLogger.info('日志系统初始化完成', tag: 'PathTrace', data: {
        'dataPath': _GlobalInitializationState._cachedDataPath,
        'logFilePath': logFilePath,
        'maxSize': '10MB',
        'maxFiles': 5,
        'source': 'optimized_logging'
      });
    }
  } catch (e) {
    debugPrint('日志系统初始化失败: $e');
  }
}

/// 初始化路径配置（去重版本）
Future<void> _initializePathConfig() async {
  debugPrint('开始初始化路径配置');

  try {
    final config = await UnifiedPathConfigService.readConfig();
    final actualDataPath = await config.dataPath.getActualDataPath();

    // 缓存数据路径，供日志系统和其他初始化使用
    _GlobalInitializationState._cachedDataPath = actualDataPath;

    debugPrint('路径配置初始化完成: $actualDataPath');

    // 路径配置完成后，AppLogger应该已经可用了
    if (AppLogger.hasHandlers) {
      AppLogger.info('统一路径配置初始化完成', tag: 'PathTrace', data: {
        'dataPath.useDefaultPath': config.dataPath.useDefaultPath,
        'dataPath.customPath': config.dataPath.customPath,
        'dataPath.actualPath': actualDataPath,
        'backupPath': config.backupPath.path,
        'source': 'optimized_main_initialize'
      });
    }
  } catch (e) {
    debugPrint('路径配置初始化失败: $e');
    if (AppLogger.hasHandlers) {
      AppLogger.error('统一路径配置初始化失败', error: e, tag: 'PathTrace');
    }
    rethrow;
  }
}

/// 检查备份恢复
Future<void> _checkBackupRestore() async {
  try {
    final dataPath = _GlobalInitializationState._cachedDataPath;
    if (dataPath != null) {
      AppLogger.info('开始检查备份恢复', tag: 'PathTrace');
      await EnhancedBackupService.checkAndCompleteRestoreAfterRestart(dataPath);
      AppLogger.info('备份恢复检查完成', tag: 'PathTrace');
    } else {
      AppLogger.warning('数据路径未缓存，跳过备份恢复检查', tag: 'PathTrace');
    }
  } catch (e, stack) {
    AppLogger.error('备份恢复检查失败', error: e, stackTrace: stack, tag: 'PathTrace');
    // 不影响应用启动
  }
}

/// 初始化SharedPreferences
Future<void> _initializePreferences() async {
  if (_GlobalInitializationState._cachedPreferences != null) return;

  try {
    _GlobalInitializationState._cachedPreferences =
        await SharedPreferences.getInstance();
    _GlobalInitializationState._preferencesInitialized = true;
    AppLogger.info('SharedPreferences初始化完成', tag: 'App');
  } catch (e) {
    AppLogger.error('SharedPreferences初始化失败', error: e, tag: 'App');
    rethrow;
  }
}

/// 初始化版本配置
Future<void> _initializeVersionConfig() async {
  try {
    await VersionConfig.initialize();
    _GlobalInitializationState._versionConfigInitialized = true;
    AppLogger.info('版本配置初始化完成', tag: 'App');
  } catch (e) {
    AppLogger.error('版本配置初始化失败', error: e, tag: 'App');
    // 版本配置失败不影响应用启动
  }
}

/// 创建优化的ProviderContainer
ProviderContainer _createOptimizedProviderContainer() {
  final prefs = _GlobalInitializationState._cachedPreferences!;

  return ProviderContainer(
    observers: [SilentObserver()], // 避免过多的Riverpod日志
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
}

/// 构建优化的应用
Widget _buildOptimizedApp() {
  return FutureBuilder(
    future: _delayedInitializeKeyboard(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.data == true) {
        return KeyboardMonitor.wrapApp(const MyApp());
      }
      return const MyApp(); // 不等待键盘监控
    },
  );
}

/// 延迟初始化键盘工具
Future<bool> _delayedInitializeKeyboard() async {
  await Future.delayed(const Duration(milliseconds: 200));
  return true; // 键盘工具在后台已初始化
}

/// 处理启动错误
void _handleStartupError(Object e, StackTrace stack) {
  if (AppLogger.hasHandlers) {
    AppLogger.fatal('应用启动失败', error: e, stackTrace: stack, tag: 'App');
  } else {
    debugPrint('Critical error: App startup failed: $e');
    debugPrint('$stack');
  }

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

/// 静默Observer，减少Riverpod日志噪音
class SilentObserver extends ProviderObserver {
  // 过滤频繁更新的provider
  static final _noisyProviders = {
    'cursor',
    'position',
    'render',
    'path',
    'scroll',
    'animation'
  };

  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    final name = provider.name?.toLowerCase() ?? '';

    // 跳过噪音provider的日志
    if (_noisyProviders.any((noise) => name.contains(noise))) {
      return;
    }

    // 只记录重要的provider变化
    if (kDebugMode && previousValue != newValue) {
      debugPrint('[Provider] ${provider.name}: changed');
    }
  }

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    // 静默添加
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    // 静默销毁
  }
}
