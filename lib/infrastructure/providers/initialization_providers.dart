import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import '../../application/config/app_config.dart';
import '../../application/services/initialization/app_initialization_service.dart';
import '../logging/app_error_handler.dart';
import '../logging/log_level.dart';
import '../logging/logger.dart';
import '../persistence/database_state.dart';

const _initializationTimeout = Duration(seconds: 30);

/// 应用初始化状态提供者
final appInitializationProvider = FutureProvider<bool>((ref) async {
  // 等待系统初始化完成
  await ref.watch(systemInitializationProvider.future);

  // 设置初始化超时
  return await _withTimeout(() async {
    final dbState = ref.watch(databaseStateProvider);

    if (dbState.error != null) {
      throw dbState.error!;
    }

    if (!dbState.isInitialized) {
      // 等待数据库初始化完成
      await _waitForInitialization(ref);
    }

    return true;
  });
});

/// 数据库状态提供者
final databaseStateProvider =
    StateNotifierProvider<DatabaseStateNotifier, DatabaseState>((ref) {
  return DatabaseStateNotifier(ref.watch(initializationServiceProvider));
});

/// 初始化服务提供者
final initializationServiceProvider = Provider<AppInitializationService>((ref) {
  return const AppInitializationService();
});

/// 系统初始化提供者
final systemInitializationProvider = FutureProvider<void>((ref) async {
  try {
    // 初始化数据库工厂
    if (Platform.isWindows || Platform.isLinux) {
      // 在Windows和Linux上使用FFI
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

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

    // 初始化日志系统
    final appDocDir = await getApplicationDocumentsDirectory();
    final logDir = Directory('${appDocDir.path}/logs');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    await AppLogger.init(
      minLevel: kDebugMode ? LogLevel.debug : LogLevel.warning,
      enableConsole: true,
      enableFile: true,
      filePath: '${logDir.path}/app.log',
      maxFileSizeBytes: 5 * 1024 * 1024, // 5 MB
      maxFiles: 10,
    );

    // 设置全局错误处理
    AppErrorHandler.initialize();

    AppLogger.info('Application starting', tag: 'App');
  } catch (e, stack) {
    AppLogger.fatal(
      'Failed to start application',
      error: e,
      stackTrace: stack,
      tag: 'App',
    );
    rethrow;
  }
});

/// 等待数据库初始化完成
Future<void> _waitForInitialization(Ref ref) async {
  final completer = Completer<void>();

  // 监听数据库状态
  ref.listen(databaseStateProvider, (previous, next) {
    if (next.isInitialized && !completer.isCompleted) {
      completer.complete();
    } else if (next.error != null && !completer.isCompleted) {
      completer.completeError(next.error!);
    }
  });

  return completer.future;
}

/// 添加超时保护的异步操作包装器
Future<T> _withTimeout<T>(Future<T> Function() operation) async {
  try {
    return await operation().timeout(_initializationTimeout);
  } on TimeoutException {
    AppLogger.error(
      '初始化超时',
      tag: 'Initialization',
      error: TimeoutException('初始化操作超过 ${_initializationTimeout.inSeconds} 秒'),
    );
    rethrow;
  }
}

/// 数据库状态管理器
class DatabaseStateNotifier extends StateNotifier<DatabaseState> {
  final AppInitializationService _initService;
  Timer? _timeoutTimer;

  DatabaseStateNotifier(this._initService) : super(const DatabaseState()) {
    _initialize();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> retry() async {
    state = const DatabaseState();
    await _initialize();
  }

  Future<void> _initialize() async {
    try {
      // 设置超时定时器
      _timeoutTimer = Timer(_initializationTimeout, () {
        if (!state.isInitialized) {
          state = DatabaseState(
            error: TimeoutException('数据库初始化超时'),
            isInitialized: false,
          );
        }
      });

      final db = await _initService.initializeDatabase(AppConfig.dataPath);
      state = DatabaseState(
        database: db,
        isInitialized: true,
      );
    } catch (e) {
      state = DatabaseState(
        error: e,
        isInitialized: false,
      );
    } finally {
      _timeoutTimer?.cancel();
    }
  }
}
