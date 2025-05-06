import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../logging/logger.dart';

/// 数据库恢复处理器 V2
///
/// 在应用启动时检查是否有待恢复的数据库文件，如果有则进行恢复
/// 使用一种不同的方法来处理数据库恢复，避免文件锁定问题
class DatabaseRestoreHandlerV2 {
  /// 检查并处理待恢复的数据库
  static Future<bool> checkAndRestoreDatabase(String databaseDir) async {
    try {
      final restoreMarkerPath = path.join(databaseDir, 'restore_pending.json');
      final pendingDbPath = path.join(databaseDir, 'app.db.new');
      final dbPath = path.join(databaseDir, 'app.db');
      final readyMarkerPath = path.join(databaseDir, 'db_ready_to_restore');
      final tempDbPath = path.join(databaseDir, 'app.db.temp');

      AppLogger.debug('检查数据库恢复标记文件', tag: 'DatabaseRestoreV2', data: {
        'restoreMarkerPath': restoreMarkerPath,
        'pendingDbPath': pendingDbPath,
        'dbPath': dbPath,
        'readyMarkerPath': readyMarkerPath,
        'tempDbPath': tempDbPath,
        'databaseDir': databaseDir
      });

      // 检查是否存在ready标记文件
      final readyMarkerFile = File(readyMarkerPath);
      final readyMarkerExists = await readyMarkerFile.exists();

      if (readyMarkerExists) {
        AppLogger.info('发现数据库恢复就绪标记文件，准备恢复数据库',
            tag: 'DatabaseRestoreV2',
            data: {'readyMarkerPath': readyMarkerPath});

        // 检查是否存在待恢复的数据库文件
        final pendingFile = File(pendingDbPath);
        final pendingExists = await pendingFile.exists();

        if (!pendingExists) {
          AppLogger.warning('未找到待恢复的数据库文件，删除恢复就绪标记文件',
              tag: 'DatabaseRestoreV2', data: {'pendingDbPath': pendingDbPath});
          await _retryFileOperation(
              () => readyMarkerFile.delete(), '删除恢复就绪标记文件');
          return false;
        }

        // 检查数据库文件是否存在
        final dbFile = File(dbPath);
        final dbExists = await dbFile.exists();

        // 获取待恢复文件大小
        final pendingSize = await pendingFile.length();
        AppLogger.info('待恢复数据库文件大小',
            tag: 'DatabaseRestoreV2', data: {'pendingSize': pendingSize});

        // 如果数据库文件存在，尝试重命名它
        if (dbExists) {
          final oldDbPath = '$dbPath.old';
          final success = await _retryFileOperation(
            () => dbFile.rename(oldDbPath),
            '重命名现有数据库文件',
            maxRetries: 3,
            delayMs: 500,
          );

          if (success) {
            AppLogger.info('成功重命名现有数据库文件',
                tag: 'DatabaseRestoreV2',
                data: {'oldPath': dbPath, 'newPath': oldDbPath});
          } else {
            AppLogger.warning('无法重命名现有数据库文件，将尝试直接替换',
                tag: 'DatabaseRestoreV2', data: {'dbPath': dbPath});
          }
        }

        // 将待恢复的数据库文件复制为正式数据库文件
        try {
          // 确保目标目录存在
          await Directory(path.dirname(dbPath)).create(recursive: true);

          // 使用增强的文件复制方法
          final copySuccess = await _copyFileWithFallback(pendingFile, dbPath);

          if (!copySuccess) {
            AppLogger.error('复制数据库文件失败，尝试使用临时文件方法',
                tag: 'DatabaseRestoreV2',
                data: {'pendingDbPath': pendingDbPath, 'dbPath': dbPath});

            // 尝试使用临时文件方法
            final tempSuccess =
                await _copyFileWithFallback(pendingFile, tempDbPath);
            if (tempSuccess) {
              final tempFile = File(tempDbPath);
              final renameSuccess = await _retryFileOperation(
                () => tempFile.rename(dbPath),
                '重命名临时数据库文件',
                maxRetries: 3,
                delayMs: 500,
              );

              if (!renameSuccess) {
                AppLogger.error('重命名临时数据库文件失败',
                    tag: 'DatabaseRestoreV2',
                    data: {'tempDbPath': tempDbPath, 'dbPath': dbPath});
                return false;
              }
            } else {
              AppLogger.error('使用临时文件方法复制数据库文件失败',
                  tag: 'DatabaseRestoreV2',
                  data: {
                    'pendingDbPath': pendingDbPath,
                    'tempDbPath': tempDbPath
                  });
              return false;
            }
          }

          // 验证复制后的文件
          final newDbFile = File(dbPath);
          final newDbExists = await newDbFile.exists();
          final newDbSize = newDbExists ? await newDbFile.length() : 0;

          AppLogger.info('成功复制数据库文件', tag: 'DatabaseRestoreV2', data: {
            'pendingDbPath': pendingDbPath,
            'dbPath': dbPath,
            'pendingSize': pendingSize,
            'newDbExists': newDbExists,
            'newDbSize': newDbSize
          });

          // 删除待恢复的数据库文件
          await _retryFileOperation(() => pendingFile.delete(), '删除待恢复的数据库文件');
          AppLogger.info('成功删除待恢复的数据库文件',
              tag: 'DatabaseRestoreV2', data: {'pendingDbPath': pendingDbPath});

          // 删除恢复就绪标记文件
          await _retryFileOperation(
              () => readyMarkerFile.delete(), '删除恢复就绪标记文件');
          AppLogger.info('成功删除恢复就绪标记文件',
              tag: 'DatabaseRestoreV2',
              data: {'readyMarkerPath': readyMarkerPath});

          return true;
        } catch (e) {
          AppLogger.error('复制数据库文件失败',
              tag: 'DatabaseRestoreV2',
              error: e,
              data: {'pendingDbPath': pendingDbPath, 'dbPath': dbPath});
          return false;
        }
      }

      // 检查是否存在恢复标记文件
      final markerFile = File(restoreMarkerPath);
      final markerExists = await markerFile.exists();

      if (!markerExists) {
        return false; // 没有待恢复的数据库
      }

      AppLogger.info('发现数据库恢复标记文件，准备创建恢复就绪标记',
          tag: 'DatabaseRestoreV2', data: {'markerPath': restoreMarkerPath});

      // 检查是否存在待恢复的数据库文件
      final pendingFile = File(pendingDbPath);
      final pendingExists = await pendingFile.exists();

      if (!pendingExists) {
        AppLogger.warning('未找到待恢复的数据库文件，删除恢复标记文件',
            tag: 'DatabaseRestoreV2', data: {'pendingDbPath': pendingDbPath});
        await _retryFileOperation(() => markerFile.delete(), '删除恢复标记文件');
        return false;
      }

      // 读取恢复标记文件
      final restoreInfoJson = await markerFile.readAsString();
      final restoreInfo = jsonDecode(restoreInfoJson) as Map<String, dynamic>;

      AppLogger.info('准备创建恢复就绪标记',
          tag: 'DatabaseRestoreV2', data: {'restoreInfo': restoreInfo});

      // 创建恢复就绪标记文件
      final writeSuccess = await _retryFileOperation(
        () => readyMarkerFile.writeAsString('ready'),
        '创建恢复就绪标记文件',
        maxRetries: 3,
        delayMs: 300,
      );

      if (!writeSuccess) {
        AppLogger.error('创建恢复就绪标记文件失败',
            tag: 'DatabaseRestoreV2',
            data: {'readyMarkerPath': readyMarkerPath});
        return false;
      }

      AppLogger.info('成功创建恢复就绪标记文件',
          tag: 'DatabaseRestoreV2', data: {'readyMarkerPath': readyMarkerPath});

      // 删除恢复标记文件
      await _retryFileOperation(() => markerFile.delete(), '删除恢复标记文件');
      AppLogger.info('成功删除恢复标记文件',
          tag: 'DatabaseRestoreV2', data: {'markerPath': restoreMarkerPath});

      return true;
    } catch (e, stack) {
      AppLogger.error('恢复数据库失败',
          error: e, stackTrace: stack, tag: 'DatabaseRestoreV2');
      return false;
    }
  }

  /// 使用替代方法复制文件，处理文件锁定问题
  static Future<bool> _copyFileWithFallback(
      File source, String destination) async {
    try {
      // 尝试直接复制
      await source.copy(destination);
      return true;
    } catch (e) {
      AppLogger.warning(
        '直接复制文件失败，尝试使用流复制方法',
        tag: 'DatabaseRestoreV2',
        data: {'error': e, 'source': source.path, 'destination': destination},
      );

      try {
        // 使用流复制方法
        final sourceStream = source.openRead();
        final destinationFile = File(destination);

        // 如果目标文件存在，先尝试删除
        if (await destinationFile.exists()) {
          try {
            await destinationFile.delete();
          } catch (e) {
            AppLogger.warning(
              '无法删除现有目标文件，将尝试覆盖',
              tag: 'DatabaseRestoreV2',
              data: {'error': e, 'destination': destination},
            );
          }
        }

        final sink = destinationFile.openWrite();
        await sourceStream.pipe(sink);
        await sink.flush();
        await sink.close();

        return true;
      } catch (e) {
        AppLogger.error(
          '使用流复制方法失败',
          tag: 'DatabaseRestoreV2',
          error: e,
          data: {'source': source.path, 'destination': destination},
        );
        return false;
      }
    }
  }

  /// 尝试执行文件操作，如果失败则重试
  static Future<bool> _retryFileOperation(
    Future<void> Function() operation,
    String operationName, {
    int maxRetries = 5,
    int delayMs = 200,
  }) async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        await operation();
        return true; // 操作成功
      } catch (e) {
        retryCount++;
        AppLogger.warning(
          '$operationName 失败，尝试重试 ($retryCount/$maxRetries)',
          tag: 'DatabaseRestoreV2',
          data: {
            'error': e,
            'retryCount': retryCount,
            'maxRetries': maxRetries
          },
        );

        if (retryCount >= maxRetries) {
          AppLogger.error(
            '$operationName 失败，已达到最大重试次数',
            tag: 'DatabaseRestoreV2',
            error: e,
          );
          return false;
        }

        // 延迟后重试，每次重试增加延迟时间
        await Future.delayed(Duration(milliseconds: delayMs * retryCount));
      }
    }
    return false;
  }
}
