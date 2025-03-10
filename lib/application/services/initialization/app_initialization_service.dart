import '../../../infrastructure/logging/logger.dart';
import '../../../infrastructure/persistence/database_factory.dart';
import '../../../infrastructure/persistence/database_interface.dart';
import '../../../infrastructure/persistence/sqlite/migrations.dart';
import '../../config/app_config.dart';

/// 应用初始化服务
/// 负责管理应用启动时的初始化流程
class AppInitializationService {
  const AppInitializationService();

  /// 执行所有初始化操作
  Future<void> initialize() async {
    try {
      AppLogger.info('开始应用初始化', tag: 'AppInitializationService');

      // 初始化数据库（带重试）
      await retryOperation(
        () => initializeDatabase(AppConfig.dataPath),
        maxAttempts: 3,
        delayBetweenAttempts: const Duration(seconds: 2),
      );

      // TODO: 添加其他初始化操作

      AppLogger.info('应用初始化完成', tag: 'AppInitializationService');
    } catch (e, stack) {
      AppLogger.error('应用初始化失败',
          tag: 'AppInitializationService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 初始化数据库
  Future<DatabaseInterface> initializeDatabase(String dataPath) async {
    try {
      AppLogger.info('开始初始化数据库', tag: 'AppInitializationService', data: {
        'databasePath': dataPath,
      });

      final config = DatabaseConfig(
        name: 'app.db',
        directory: dataPath,
        migrations: migrations,
      );

      // 创建数据库实例
      final database = await DatabaseFactory.create(config);

      // 初始化数据库
      await database.initialize();

      AppLogger.info('数据库初始化完成',
          tag: 'AppInitializationService', data: {'databasePath': dataPath});

      return database;
    } catch (e, stack) {
      AppLogger.error('数据库初始化失败',
          tag: 'AppInitializationService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 重试初始化操作
  /// [operation] 要重试的初始化操作
  /// [maxAttempts] 最大重试次数
  /// [delayBetweenAttempts] 重试间隔
  Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration delayBetweenAttempts = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e, stack) {
        if (attempts >= maxAttempts) {
          AppLogger.error(
            '初始化操作重试失败',
            tag: 'AppInitializationService',
            error: e,
            stackTrace: stack,
            data: {
              'attempts': attempts,
              'maxAttempts': maxAttempts,
            },
          );
          rethrow;
        }

        AppLogger.warning(
          '初始化操作失败，准备重试',
          tag: 'AppInitializationService',
          error: e,
          data: {
            'attempt': attempts,
            'maxAttempts': maxAttempts,
            'delayBeforeRetry': delayBetweenAttempts.inSeconds,
          },
        );

        await Future.delayed(delayBetweenAttempts);
      }
    }
  }
}
