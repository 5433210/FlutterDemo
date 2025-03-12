import '../../../infrastructure/logging/logger.dart';
import '../../../infrastructure/persistence/database_interface.dart';

/// 初始化服务
class InitializationService {
  final DatabaseInterface _database;
  InitializationState _state;

  InitializationService({
    required DatabaseInterface database,
  })  : _database = database,
        _state = const InitializationState();

  InitializationState get state => _state;

  /// 关闭应用
  Future<void> dispose() async {
    try {
      await _database.close();
      AppLogger.info('应用已关闭', tag: 'InitializationService');
    } catch (e, stack) {
      AppLogger.error(
        '关闭应用失败',
        error: e,
        stackTrace: stack,
        tag: 'InitializationService',
      );
    }
  }

  /// 初始化应用
  Future<void> initialize() async {
    try {
      AppLogger.info('正在初始化应用...', tag: 'InitializationService');

      // 初始化数据库
      await _database.initialize();

      _state = _state.copyWith(
        isInitialized: true,
        database: _database,
      );

      AppLogger.info('应用初始化完成', tag: 'InitializationService');
    } catch (e, stack) {
      AppLogger.error(
        '初始化失败',
        error: e,
        stackTrace: stack,
        tag: 'InitializationService',
      );

      _state = _state.copyWith(
        error: '初始化失败: $e',
      );

      rethrow;
    }
  }
}

/// 初始化状态
class InitializationState {
  final bool isInitialized;
  final DatabaseInterface? database;
  final String? error;

  const InitializationState({
    this.isInitialized = false,
    this.database,
    this.error,
  });

  InitializationState copyWith({
    bool? isInitialized,
    DatabaseInterface? database,
    String? error,
  }) {
    return InitializationState(
      isInitialized: isInitialized ?? this.isInitialized,
      database: database ?? this.database,
      error: error ?? this.error,
    );
  }
}
