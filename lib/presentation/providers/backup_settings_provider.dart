import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/backup/backup_service.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/providers/database_providers.dart';
import '../../infrastructure/providers/shared_preferences_provider.dart';
import '../../infrastructure/providers/storage_providers.dart';
import '../../utils/app_restart_service.dart';

/// 备份列表提供者
final backupListProvider = FutureProvider<List<BackupInfo>>((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  return await backupService.getBackups();
});

/// 备份服务提供者
final backupServiceProvider = Provider<BackupService>((ref) {
  final storage = ref.watch(initializedStorageProvider);
  final database = ref.watch(initializedDatabaseProvider);

  final service = BackupService(
    storage: storage,
    database: database,
  );

  // 初始化备份服务
  service.initialize();

  return service;
});

/// 备份设置提供者
final backupSettingsProvider =
    StateNotifierProvider<BackupSettingsNotifier, BackupSettings>((ref) {
  return BackupSettingsNotifier(ref);
});

/// 备份设置状态
class BackupSettings {
  /// 保留的备份数量
  final int keepBackupCount;

  /// 上次备份时间
  final DateTime? lastBackupTime;

  const BackupSettings({
    this.keepBackupCount = 5,
    this.lastBackupTime,
  });

  /// 创建新的备份设置实例
  BackupSettings copyWith({
    int? keepBackupCount,
    DateTime? lastBackupTime,
  }) {
    return BackupSettings(
      keepBackupCount: keepBackupCount ?? this.keepBackupCount,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
    );
  }
}

/// 备份设置状态管理器
class BackupSettingsNotifier extends StateNotifier<BackupSettings> {
  final Ref ref;

  BackupSettingsNotifier(this.ref) : super(const BackupSettings()) {
    _loadSettings();
  }

  /// 创建备份
  Future<String?> createBackup({String? description}) async {
    try {
      AppLogger.info('开始创建备份', tag: 'BackupSettingsNotifier', data: {
        'description': description,
        'keepBackupCount': state.keepBackupCount,
      });

      final backupService = ref.read(backupServiceProvider);
      final backupPath =
          await backupService.createBackup(description: description);

      AppLogger.info('备份文件创建完成', tag: 'BackupSettingsNotifier', data: {
        'backupPath': backupPath,
      });

      // 更新上次备份时间
      try {
        await updateLastBackupTime(DateTime.now());
        AppLogger.info('上次备份时间更新完成', tag: 'BackupSettingsNotifier');
      } catch (e) {
        AppLogger.warning('更新备份时间失败', tag: 'BackupSettingsNotifier', data: {
          'error': e.toString(),
        });
        // 继续执行，不影响备份结果
      }

      // 清理旧备份
      try {
        AppLogger.info('开始清理旧备份', tag: 'BackupSettingsNotifier', data: {
          'keepCount': state.keepBackupCount,
        });
        
        final deletedCount = await backupService.cleanupOldBackups(state.keepBackupCount);
        AppLogger.info('清理旧备份完成', tag: 'BackupSettingsNotifier', data: {
          'deletedCount': deletedCount,
        });
      } catch (e) {
        AppLogger.warning('清理旧备份失败，但不影响备份成功', tag: 'BackupSettingsNotifier', data: {
          'error': e.toString(),
        });
        // 清理失败不影响备份成功
      }
      
      // 刷新备份列表
      try {
        ref.invalidate(backupListProvider);
        AppLogger.info('备份列表已刷新', tag: 'BackupSettingsNotifier');
      } catch (e) {
        AppLogger.warning('刷新备份列表失败', tag: 'BackupSettingsNotifier', data: {
          'error': e.toString(),
        });
      }

      AppLogger.info('备份操作全部完成', tag: 'BackupSettingsNotifier', data: {
        'backupPath': backupPath,
      });

      return backupPath;
    } catch (e, stackTrace) {
      AppLogger.error('创建备份失败', tag: 'BackupSettingsNotifier', 
          error: e, stackTrace: stackTrace, data: {
        'description': description,
      });
      return null;
    }
  }

  /// 删除备份
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final backupService = ref.read(backupServiceProvider);
      final success = await backupService.deleteBackup(backupPath);

      // 刷新备份列表
      ref.invalidate(backupListProvider);

      return success;
    } catch (e) {
      return false;
    }
  }

  /// 导出备份到外部位置
  Future<bool> exportBackup(String backupPath, String exportPath) async {
    try {
      final backupService = ref.read(backupServiceProvider);
      final success = await backupService.exportBackup(backupPath, exportPath);
      return success;
    } catch (e) {
      return false;
    }
  }

  /// 从外部位置导入备份
  Future<bool> importBackup(String importPath) async {
    try {
      final backupService = ref.read(backupServiceProvider);
      final success = await backupService.importBackup(importPath);

      // 刷新备份列表
      ref.invalidate(backupListProvider);

      return success;
    } catch (e) {
      return false;
    }
  }

  /// 从备份恢复
  ///
  /// [backupPath] 备份文件路径
  /// [context] 上下文，用于自动重启应用
  /// [autoRestart] 参数保留但不再使用，应用将始终自动重启
  Future<bool> restoreFromBackup(
    String backupPath, {
    BuildContext? context,
    bool autoRestart = true, // 保留参数但默认为true
  }) async {
    try {
      final backupService = ref.read(backupServiceProvider);
      bool needsRestart = false;

      // 保存当前上下文，避免异步操作后上下文失效
      final currentContext = context;

      try {
        final success = await backupService.restoreFromBackup(
          backupPath,
          onRestoreComplete: (needsRestartValue, message) {
            needsRestart = needsRestartValue;
            AppLogger.info('恢复完成回调',
                tag: 'BackupSettingsNotifier',
                data: {'needsRestart': needsRestart, 'message': message});
          },
        );

        // 刷新备份列表
        ref.invalidate(backupListProvider);

        // 如果恢复成功且需要重启，则直接重启应用（不再检查autoRestart参数）
        if (success &&
            needsRestart &&
            currentContext != null &&
            currentContext.mounted) {
          AppLogger.info('恢复成功，准备自动重启应用', tag: 'BackupSettingsNotifier');

          // 使用更长的延迟，确保数据库操作完成
          await Future.delayed(const Duration(seconds: 1));

          if (currentContext.mounted) {
            AppLogger.info('执行应用重启', tag: 'BackupSettingsNotifier');
            AppRestartService.restartApp(currentContext);
          }
        }

        return success;
      } catch (e) {
        if (e is NeedsRestartException ||
            e.toString().contains('NeedsRestartException')) {
          AppLogger.info('捕获到需要重启的异常',
              tag: 'BackupSettingsNotifier', data: {'error': e.toString()});

          // 不再检查autoRestart参数，始终自动重启
          if (currentContext != null && currentContext.mounted) {
            AppLogger.info('准备自动重启应用', tag: 'BackupSettingsNotifier');

            // 使用更长的延迟，确保数据库操作完成
            await Future.delayed(const Duration(seconds: 1));

            if (currentContext.mounted) {
              AppLogger.info('执行应用重启', tag: 'BackupSettingsNotifier');
              AppRestartService.restartApp(currentContext);
            }
          }

          return true;
        } else {
          rethrow;
        }
      }
    } catch (e) {
      AppLogger.error('恢复备份失败', tag: 'BackupSettingsNotifier', error: e);
      return false;
    }
  }



  /// 设置保留的备份数量
  Future<void> setKeepBackupCount(int count) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt('keep_backup_count', count);
    state = state.copyWith(keepBackupCount: count);

    // 如果减少了保留数量，清理多余的备份
    final backupService = ref.read(backupServiceProvider);
    await backupService.cleanupOldBackups(count);
  }

  /// 更新上次备份时间
  Future<void> updateLastBackupTime(DateTime time) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('last_backup_time', time.toIso8601String());
    state = state.copyWith(lastBackupTime: time);
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    final prefs = ref.read(sharedPreferencesProvider);

    final keepBackupCount = prefs.getInt('keep_backup_count') ?? 5;

    DateTime? lastBackupTime;
    final lastBackupTimeStr = prefs.getString('last_backup_time');
    if (lastBackupTimeStr != null) {
      try {
        lastBackupTime = DateTime.parse(lastBackupTimeStr);
      } catch (e) {
        // 忽略解析错误
      }
    }

    state = BackupSettings(
      keepBackupCount: keepBackupCount,
      lastBackupTime: lastBackupTime,
    );
  }
}
