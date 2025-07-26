import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../domain/models/data_version_definition.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/persistence/sqlite/migrations.dart';

/// 数据库迁移集成
/// 负责将数据版本升级与现有的 migrations.dart 机制集成
class DatabaseMigrationIntegration {
  /// 与现有迁移机制集成
  static Future<void> integrateWithExistingMigrations(
    String fromDataVersion,
    String toDataVersion,
    String databasePath,
  ) async {
    try {
      AppLogger.info('开始数据库迁移集成', tag: 'DatabaseMigrationIntegration', data: {
        'fromDataVersion': fromDataVersion,
        'toDataVersion': toDataVersion,
        'databasePath': databasePath,
      });

      // 获取对应的数据库版本
      final fromDbVersion = DataVersionDefinition.getDatabaseVersion(fromDataVersion);
      final toDbVersion = DataVersionDefinition.getDatabaseVersion(toDataVersion);

      if (fromDbVersion >= toDbVersion) {
        AppLogger.info('数据库版本无需升级', tag: 'DatabaseMigrationIntegration', data: {
          'fromDbVersion': fromDbVersion,
          'toDbVersion': toDbVersion,
        });
        return;
      }

      // 检查数据库文件是否存在
      final dbFile = File(databasePath);
      if (!await dbFile.exists()) {
        AppLogger.warning('数据库文件不存在，跳过迁移', tag: 'DatabaseMigrationIntegration', data: {
          'databasePath': databasePath,
        });
        return;
      }

      // 执行数据库迁移
      await _executeDatabaseMigration(databasePath, fromDbVersion, toDbVersion);

      AppLogger.info('数据库迁移集成完成', tag: 'DatabaseMigrationIntegration', data: {
        'fromDbVersion': fromDbVersion,
        'toDbVersion': toDbVersion,
      });

    } catch (e, stackTrace) {
      AppLogger.error('数据库迁移集成失败', 
          error: e, 
          stackTrace: stackTrace,
          tag: 'DatabaseMigrationIntegration');
      rethrow;
    }
  }

  /// 执行数据库迁移
  static Future<void> _executeDatabaseMigration(
    String databasePath,
    int fromVersion,
    int toVersion,
  ) async {
    try {
      // 打开数据库并执行迁移
      final database = await openDatabase(
        databasePath,
        version: toVersion,
        onUpgrade: (db, oldVersion, newVersion) async {
          AppLogger.info('执行数据库升级', tag: 'DatabaseMigrationIntegration', data: {
            'oldVersion': oldVersion,
            'newVersion': newVersion,
          });

          // 执行从 oldVersion 到 newVersion 的所有迁移脚本
          for (var i = oldVersion; i < newVersion; i++) {
            if (i < migrations.length) {
              final sql = migrations[i];
              AppLogger.debug('执行迁移脚本 ${i + 1}', tag: 'DatabaseMigrationIntegration', data: {
                'migrationIndex': i + 1,
                'sql': sql.substring(0, 100) + '...', // 只记录前100个字符
              });
              
              try {
                await db.execute(sql);
              } catch (e) {
                AppLogger.error('迁移脚本执行失败', 
                    error: e,
                    tag: 'DatabaseMigrationIntegration',
                    data: {
                      'migrationIndex': i + 1,
                      'sql': sql,
                    });
                rethrow;
              }
            }
          }
        },
      );

      // 验证迁移结果
      final currentVersion = await database.getVersion();
      if (currentVersion != toVersion) {
        throw Exception('数据库版本验证失败: 期望 $toVersion, 实际 $currentVersion');
      }

      await database.close();

      AppLogger.info('数据库迁移执行完成', tag: 'DatabaseMigrationIntegration', data: {
        'finalVersion': currentVersion,
      });

    } catch (e, stackTrace) {
      AppLogger.error('数据库迁移执行失败', 
          error: e, 
          stackTrace: stackTrace,
          tag: 'DatabaseMigrationIntegration');
      rethrow;
    }
  }

  /// 验证数据库版本
  static Future<bool> validateDatabaseVersion(String databasePath, String expectedDataVersion) async {
    try {
      final expectedDbVersion = DataVersionDefinition.getDatabaseVersion(expectedDataVersion);
      
      final dbFile = File(databasePath);
      if (!await dbFile.exists()) {
        AppLogger.warning('数据库文件不存在', tag: 'DatabaseMigrationIntegration', data: {
          'databasePath': databasePath,
        });
        return false;
      }

      final database = await openDatabase(databasePath, readOnly: true);
      final currentVersion = await database.getVersion();
      await database.close();

      final isValid = currentVersion == expectedDbVersion;
      
      AppLogger.info('数据库版本验证', tag: 'DatabaseMigrationIntegration', data: {
        'expectedDataVersion': expectedDataVersion,
        'expectedDbVersion': expectedDbVersion,
        'currentDbVersion': currentVersion,
        'isValid': isValid,
      });

      return isValid;

    } catch (e, stackTrace) {
      AppLogger.error('数据库版本验证失败', 
          error: e, 
          stackTrace: stackTrace,
          tag: 'DatabaseMigrationIntegration');
      return false;
    }
  }

  /// 获取数据库当前版本
  static Future<int> getCurrentDatabaseVersion(String databasePath) async {
    try {
      final dbFile = File(databasePath);
      if (!await dbFile.exists()) {
        return 0;
      }

      final database = await openDatabase(databasePath, readOnly: true);
      final version = await database.getVersion();
      await database.close();

      return version;

    } catch (e, stackTrace) {
      AppLogger.error('获取数据库版本失败', 
          error: e, 
          stackTrace: stackTrace,
          tag: 'DatabaseMigrationIntegration');
      return 0;
    }
  }

  /// 备份数据库
  static Future<String> backupDatabase(String databasePath) async {
    try {
      final dbFile = File(databasePath);
      if (!await dbFile.exists()) {
        throw Exception('数据库文件不存在: $databasePath');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = '${databasePath}.backup_$timestamp';
      
      await dbFile.copy(backupPath);

      AppLogger.info('数据库备份完成', tag: 'DatabaseMigrationIntegration', data: {
        'originalPath': databasePath,
        'backupPath': backupPath,
      });

      return backupPath;

    } catch (e, stackTrace) {
      AppLogger.error('数据库备份失败', 
          error: e, 
          stackTrace: stackTrace,
          tag: 'DatabaseMigrationIntegration');
      rethrow;
    }
  }

  /// 恢复数据库
  static Future<void> restoreDatabase(String backupPath, String targetPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('备份文件不存在: $backupPath');
      }

      await backupFile.copy(targetPath);

      AppLogger.info('数据库恢复完成', tag: 'DatabaseMigrationIntegration', data: {
        'backupPath': backupPath,
        'targetPath': targetPath,
      });

    } catch (e, stackTrace) {
      AppLogger.error('数据库恢复失败', 
          error: e, 
          stackTrace: stackTrace,
          tag: 'DatabaseMigrationIntegration');
      rethrow;
    }
  }

  /// 清理数据库备份文件
  static Future<void> cleanupDatabaseBackups(String databasePath, {int keepCount = 3}) async {
    try {
      final dbFile = File(databasePath);
      final directory = dbFile.parent;
      final baseName = path.basenameWithoutExtension(databasePath);
      
      // 查找所有备份文件
      final backupFiles = <File>[];
      await for (final entity in directory.list()) {
        if (entity is File && entity.path.contains('$baseName.backup_')) {
          backupFiles.add(entity);
        }
      }

      // 按修改时间排序，保留最新的几个
      backupFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      if (backupFiles.length > keepCount) {
        final filesToDelete = backupFiles.skip(keepCount);
        for (final file in filesToDelete) {
          await file.delete();
          AppLogger.debug('删除旧备份文件', tag: 'DatabaseMigrationIntegration', data: {
            'filePath': file.path,
          });
        }
      }

      AppLogger.info('数据库备份清理完成', tag: 'DatabaseMigrationIntegration', data: {
        'totalBackups': backupFiles.length,
        'kept': keepCount,
        'deleted': backupFiles.length > keepCount ? backupFiles.length - keepCount : 0,
      });

    } catch (e, stackTrace) {
      AppLogger.error('数据库备份清理失败', 
          error: e, 
          stackTrace: stackTrace,
          tag: 'DatabaseMigrationIntegration');
    }
  }
}
