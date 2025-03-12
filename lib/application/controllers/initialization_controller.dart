import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/logging/logger.dart';
import '../providers/settings_providers.dart';

/// 初始化控制器 Provider
final initializationControllerProvider = Provider((ref) {
  return InitializationController(ref);
});

/// 初始化控制器
/// 用于管理应用启动时的各项初始化工作
class InitializationController {
  final Ref _ref;

  InitializationController(this._ref);

  /// 执行初始化检查
  Future<void> runInitialChecks() async {
    try {
      await _checkMigrations();
    } catch (e, stack) {
      AppLogger.error(
        '初始化检查失败',
        error: e,
        stackTrace: stack,
        tag: 'Init',
      );
      rethrow;
    }
  }

  /// 检查迁移状态
  Future<void> _checkMigrations() async {
    AppLogger.info('开始检查数据库迁移状态', tag: 'Init');

    try {
      // 获取迁移命令实例
      final migrationCommandsAsync = _ref.read(migrationCommandsProvider);

      await migrationCommandsAsync.when(
        data: (migrationCommands) async {
          // 检查V4迁移状态
          await migrationCommands.checkV4MigrationStatus();
        },
        loading: () {
          AppLogger.debug('等待迁移命令初始化', tag: 'Init');
        },
        error: (error, stack) {
          AppLogger.error(
            '迁移命令初始化失败',
            error: error,
            stackTrace: stack,
            tag: 'Init',
          );
          throw error;
        },
      );

      AppLogger.info('数据库迁移状态检查完成', tag: 'Init');
    } catch (e, stack) {
      AppLogger.error(
        '检查数据库迁移状态失败',
        error: e,
        stackTrace: stack,
        tag: 'Init',
      );
      rethrow;
    }
  }
}
