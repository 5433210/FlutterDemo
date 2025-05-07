import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../logging/logger.dart';

/// 数据库恢复处理器
///
/// 在应用启动时检查是否有待恢复的数据库文件，如果有则进行恢复
class DatabaseRestoreHandler {
  /// 检查并处理待恢复的数据库
  static Future<bool> checkAndRestoreDatabase(String databaseDir) async {
    try {
      final restoreMarkerPath = p.join(databaseDir, 'restore_pending.json');
      final pendingDbPath = p.join(databaseDir, 'app.db.new');
      final dbPath = p.join(databaseDir, 'app.db');

      AppLogger.debug('检查数据库恢复标记文件', tag: 'DatabaseRestore', data: {
        'restoreMarkerPath': restoreMarkerPath,
        'pendingDbPath': pendingDbPath,
        'dbPath': dbPath,
        'databaseDir': databaseDir
      });

      // 检查是否存在恢复标记文件
      final markerFile = File(restoreMarkerPath);
      final markerExists = await markerFile.exists();

      AppLogger.debug('恢复标记文件状态',
          tag: 'DatabaseRestore',
          data: {'exists': markerExists, 'path': restoreMarkerPath});

      if (!markerExists) {
        return false; // 没有待恢复的数据库
      }

      AppLogger.info('发现数据库恢复标记文件，准备恢复数据库',
          tag: 'DatabaseRestore', data: {'markerPath': restoreMarkerPath});

      // 检查是否存在待恢复的数据库文件
      final pendingFile = File(pendingDbPath);
      final pendingExists = await pendingFile.exists();

      AppLogger.debug('待恢复数据库文件状态',
          tag: 'DatabaseRestore',
          data: {'exists': pendingExists, 'path': pendingDbPath});

      if (!pendingExists) {
        AppLogger.warning('未找到待恢复的数据库文件，删除恢复标记文件',
            tag: 'DatabaseRestore', data: {'pendingDbPath': pendingDbPath});
        await markerFile.delete();
        return false;
      }

      // 读取恢复标记文件
      final restoreInfoJson = await File(restoreMarkerPath).readAsString();
      final restoreInfo = jsonDecode(restoreInfoJson) as Map<String, dynamic>;

      AppLogger.info('开始恢复数据库',
          tag: 'DatabaseRestore', data: {'restoreInfo': restoreInfo});

      // 删除现有数据库文件
      final dbFile = File(dbPath);
      final dbExists = await dbFile.exists();

      AppLogger.debug('现有数据库文件状态',
          tag: 'DatabaseRestore', data: {'exists': dbExists, 'path': dbPath});

      if (dbExists) {
        try {
          await dbFile.delete();
          AppLogger.info('成功删除现有数据库文件',
              tag: 'DatabaseRestore', data: {'dbPath': dbPath});
        } catch (e) {
          AppLogger.warning('无法删除现有数据库文件，尝试重命名',
              tag: 'DatabaseRestore', data: {'dbPath': dbPath, 'error': e});

          // 如果无法删除，尝试重命名
          final oldDbPath = '$dbPath.old';
          await dbFile.rename(oldDbPath);
          AppLogger.info('成功重命名现有数据库文件',
              tag: 'DatabaseRestore',
              data: {'oldPath': dbPath, 'newPath': oldDbPath});
        }
      }

      // 将待恢复的数据库文件复制（而不是重命名）为正式数据库文件
      // 使用复制而不是重命名，以防止跨卷移动问题
      try {
        // 确保目标目录存在
        await Directory(p.dirname(dbPath)).create(recursive: true);

        // 获取待恢复文件大小
        final pendingSize = await pendingFile.length();

        // 复制文件
        await pendingFile.copy(dbPath);

        // 验证复制后的文件
        final newDbFile = File(dbPath);
        final newDbExists = await newDbFile.exists();
        final newDbSize = newDbExists ? await newDbFile.length() : 0;

        AppLogger.info('成功复制数据库文件', tag: 'DatabaseRestore', data: {
          'pendingDbPath': pendingDbPath,
          'dbPath': dbPath,
          'pendingSize': pendingSize,
          'newDbExists': newDbExists,
          'newDbSize': newDbSize
        });

        // 删除待恢复的数据库文件
        await pendingFile.delete();
        AppLogger.info('成功删除待恢复的数据库文件',
            tag: 'DatabaseRestore', data: {'pendingDbPath': pendingDbPath});
      } catch (e) {
        AppLogger.error('复制数据库文件失败',
            tag: 'DatabaseRestore',
            error: e,
            data: {'pendingDbPath': pendingDbPath, 'dbPath': dbPath});

        // 尝试使用重命名方式
        try {
          await pendingFile.rename(dbPath);
          AppLogger.info('使用重命名方式成功恢复数据库文件',
              tag: 'DatabaseRestore',
              data: {'pendingDbPath': pendingDbPath, 'dbPath': dbPath});
        } catch (renameError) {
          AppLogger.error('重命名数据库文件失败',
              tag: 'DatabaseRestore',
              error: renameError,
              data: {'pendingDbPath': pendingDbPath, 'dbPath': dbPath});

          // 如果重命名也失败，尝试使用存储服务的方法
          try {
            // 直接使用File API复制文件
            final sourceFile = File(pendingDbPath);
            await sourceFile.copy(dbPath);
            AppLogger.info('使用File API成功复制数据库文件',
                tag: 'DatabaseRestore',
                data: {'pendingDbPath': pendingDbPath, 'dbPath': dbPath});
          } catch (storageError) {
            AppLogger.error('使用File API复制数据库文件失败',
                tag: 'DatabaseRestore',
                error: storageError,
                data: {'pendingDbPath': pendingDbPath, 'dbPath': dbPath});
            throw Exception('无法恢复数据库文件: $e, $renameError, $storageError');
          }
        }
      }

      // 删除恢复标记文件
      await File(restoreMarkerPath).delete();
      AppLogger.info('成功删除恢复标记文件',
          tag: 'DatabaseRestore', data: {'markerPath': restoreMarkerPath});

      return true;
    } catch (e, stack) {
      AppLogger.error('恢复数据库失败',
          error: e, stackTrace: stack, tag: 'DatabaseRestore');
      return false;
    }
  }
}
