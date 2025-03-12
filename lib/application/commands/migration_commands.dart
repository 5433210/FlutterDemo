import 'dart:convert';

import '../../domain/repositories/settings_repository.dart';
import '../../infrastructure/logging/logger.dart';

/// 迁移命令
class MigrationCommands {
  final SettingsRepository _settingsRepository;

  MigrationCommands(this._settingsRepository);

  /// 检查V4迁移状态
  Future<void> checkV4MigrationStatus() async {
    try {
      // 获取迁移统计
      final stats = await _settingsRepository.getValue('migration_v4_stats');
      if (stats != null) {
        final data = json.decode(stats);
        AppLogger.info('迁移V4统计信息', tag: 'Migration', data: {
          '总图片数': data['total_images'],
          '更新数量': data['updated_images'],
          '有原始路径': data['with_original_path'],
          '无原始路径': data['without_original_path'],
          '执行时间': data['timestamp'],
        });
      }

      // 获取迁移完成状态
      final completion =
          await _settingsRepository.getValue('migration_v4_completion');
      if (completion != null) {
        final data = json.decode(completion);
        AppLogger.info('迁移V4完成状态', tag: 'Migration', data: {
          '迁移图片数': data['migrated_images'],
          '完成时间': data['timestamp'],
        });
      }

      if (stats == null && completion == null) {
        AppLogger.warning('未找到V4迁移记录', tag: 'Migration');
      }
    } catch (e, stack) {
      AppLogger.error('检查迁移状态失败',
          tag: 'Migration', error: e, stackTrace: stack);
    }
  }
}
