import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/backup_models.dart';
import '../../infrastructure/logging/logger.dart';

/// 旧数据路径管理器
class LegacyDataPathManager {
  static const String _legacyDataPathsKey = 'legacy_data_paths';

  /// 获取所有旧数据路径
  static Future<List<LegacyDataPath>> getLegacyPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyPathsJson = prefs.getStringList(_legacyDataPathsKey) ?? [];

      final legacyPaths = <LegacyDataPath>[];
      for (final pathJson in legacyPathsJson) {
        try {
          final pathData = jsonDecode(pathJson) as Map<String, dynamic>;
          legacyPaths.add(LegacyDataPath.fromJson(pathData));
        } catch (e) {
          AppLogger.warning('解析旧数据路径失败',
              error: e, tag: 'LegacyDataPathManager');
        }
      }

      return legacyPaths;
    } catch (e, stack) {
      AppLogger.error('获取旧数据路径失败',
          error: e, stackTrace: stack, tag: 'LegacyDataPathManager');
      return [];
    }
  }

  /// 保存旧数据路径列表
  static Future<void> _saveLegacyPaths(List<LegacyDataPath> legacyPaths) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyPathsJson =
          legacyPaths.map((path) => jsonEncode(path.toJson())).toList();

      await prefs.setStringList(_legacyDataPathsKey, legacyPathsJson);

      AppLogger.info('保存旧数据路径列表成功', tag: 'LegacyDataPathManager', data: {
        'count': legacyPaths.length,
      });
    } catch (e, stack) {
      AppLogger.error('保存旧数据路径列表失败',
          error: e, stackTrace: stack, tag: 'LegacyDataPathManager');
      rethrow;
    }
  }

  /// 记录旧数据路径
  static Future<void> recordLegacyPath(String oldPath) async {
    try {
      final legacyPaths = await getLegacyPaths();

      // 检查是否已经存在相同路径
      final existingPath = legacyPaths.firstWhere(
        (path) => path.path == oldPath,
        orElse: () => LegacyDataPath(
          id: '',
          path: '',
          switchedTime: DateTime.now(),
          sizeEstimate: 0,
          status: '',
          description: '',
        ),
      );

      if (existingPath.id.isNotEmpty) {
        AppLogger.info('旧数据路径已存在，跳过记录', tag: 'LegacyDataPathManager', data: {
          'path': oldPath,
        });
        return;
      }

      // 估算旧路径的数据大小
      final sizeEstimate = await _calculateDirectorySize(oldPath);

      // 生成唯一ID
      final id = 'legacy_${DateTime.now().millisecondsSinceEpoch}';

      final legacyPath = LegacyDataPath(
        id: id,
        path: oldPath,
        switchedTime: DateTime.now(),
        sizeEstimate: sizeEstimate,
        status: 'pending_cleanup',
        description: '需要清理的旧数据路径',
      );

      legacyPaths.add(legacyPath);
      await _saveLegacyPaths(legacyPaths);

      AppLogger.info('记录旧数据路径成功', tag: 'LegacyDataPathManager', data: {
        'path': oldPath,
        'sizeEstimate': sizeEstimate,
        'id': id,
      });
    } catch (e, stack) {
      AppLogger.error('记录旧数据路径失败',
          error: e, stackTrace: stack, tag: 'LegacyDataPathManager');
      rethrow;
    }
  }

  /// 获取所有待清理的旧路径
  static Future<List<LegacyDataPath>> getPendingCleanupPaths() async {
    try {
      final legacyPaths = await getLegacyPaths();
      return legacyPaths
          .where((path) => path.status == 'pending_cleanup')
          .toList();
    } catch (e, stack) {
      AppLogger.error('获取待清理的旧路径失败',
          error: e, stackTrace: stack, tag: 'LegacyDataPathManager');
      return [];
    }
  }

  /// 清理旧数据路径
  static Future<void> cleanupLegacyPath(String pathId) async {
    try {
      final legacyPaths = await getLegacyPaths();
      final targetPathIndex = legacyPaths.indexWhere((p) => p.id == pathId);

      if (targetPathIndex == -1) {
        AppLogger.warning('要清理的旧数据路径不存在', tag: 'LegacyDataPathManager', data: {
          'pathId': pathId,
        });
        return;
      }

      final targetPath = legacyPaths[targetPathIndex];

      AppLogger.info('开始清理旧数据路径', tag: 'LegacyDataPathManager', data: {
        'pathId': pathId,
        'path': targetPath.path,
      });

      // 删除旧路径的数据
      final directory = Directory(targetPath.path);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        AppLogger.info('删除旧数据路径目录成功', tag: 'LegacyDataPathManager', data: {
          'path': targetPath.path,
        });
      } else {
        AppLogger.info('旧数据路径目录不存在，跳过删除', tag: 'LegacyDataPathManager', data: {
          'path': targetPath.path,
        });
      }

      // 更新状态
      targetPath.status = 'cleaned';
      targetPath.cleanedTime = DateTime.now();

      legacyPaths[targetPathIndex] = targetPath;
      await _saveLegacyPaths(legacyPaths);

      AppLogger.info('清理旧数据路径完成', tag: 'LegacyDataPathManager', data: {
        'pathId': pathId,
        'path': targetPath.path,
      });
    } catch (e, stack) {
      AppLogger.error('清理旧数据路径失败',
          error: e, stackTrace: stack, tag: 'LegacyDataPathManager');
      rethrow;
    }
  }

  /// 忽略旧数据路径
  static Future<void> ignoreLegacyPath(String pathId) async {
    try {
      final legacyPaths = await getLegacyPaths();
      final targetPathIndex = legacyPaths.indexWhere((p) => p.id == pathId);

      if (targetPathIndex == -1) {
        AppLogger.warning('要忽略的旧数据路径不存在', tag: 'LegacyDataPathManager', data: {
          'pathId': pathId,
        });
        return;
      }

      final targetPath = legacyPaths[targetPathIndex];

      // 更新状态
      targetPath.status = 'ignored';

      legacyPaths[targetPathIndex] = targetPath;
      await _saveLegacyPaths(legacyPaths);

      AppLogger.info('忽略旧数据路径成功', tag: 'LegacyDataPathManager', data: {
        'pathId': pathId,
        'path': targetPath.path,
      });
    } catch (e, stack) {
      AppLogger.error('忽略旧数据路径失败',
          error: e, stackTrace: stack, tag: 'LegacyDataPathManager');
      rethrow;
    }
  }

  /// 删除旧数据路径记录
  static Future<void> removeLegacyPath(String pathId) async {
    try {
      final legacyPaths = await getLegacyPaths();
      legacyPaths.removeWhere((path) => path.id == pathId);
      await _saveLegacyPaths(legacyPaths);

      AppLogger.info('删除旧数据路径记录成功', tag: 'LegacyDataPathManager', data: {
        'pathId': pathId,
      });
    } catch (e, stack) {
      AppLogger.error('删除旧数据路径记录失败',
          error: e, stackTrace: stack, tag: 'LegacyDataPathManager');
      rethrow;
    }
  }

  /// 计算目录大小
  static Future<int> _calculateDirectorySize(String path) async {
    try {
      final directory = Directory(path);
      if (!await directory.exists()) return 0;

      int totalSize = 0;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          try {
            final size = await entity.length();
            totalSize += size;
          } catch (e) {
            // 忽略无法访问的文件
            AppLogger.debug('无法访问文件', tag: 'LegacyDataPathManager', data: {
              'filePath': entity.path,
              'error': e.toString(),
            });
          }
        }
      }
      return totalSize;
    } catch (e) {
      AppLogger.warning('计算目录大小失败', error: e, tag: 'LegacyDataPathManager');
      return 0;
    }
  }

  /// 检查旧路径是否仍然存在
  static Future<bool> checkLegacyPathExists(String path) async {
    try {
      final directory = Directory(path);
      return await directory.exists();
    } catch (e) {
      AppLogger.warning('检查旧路径是否存在失败', error: e, tag: 'LegacyDataPathManager');
      return false;
    }
  }

  /// 获取旧路径的实际大小
  static Future<int> getLegacyPathActualSize(String path) async {
    try {
      return await _calculateDirectorySize(path);
    } catch (e) {
      AppLogger.warning('获取旧路径实际大小失败', error: e, tag: 'LegacyDataPathManager');
      return 0;
    }
  }

  /// 清理所有已处理的旧路径记录
  static Future<int> cleanupProcessedRecords() async {
    try {
      final legacyPaths = await getLegacyPaths();
      final processedPaths = legacyPaths
          .where(
            (path) => path.status == 'cleaned' || path.status == 'ignored',
          )
          .toList();

      if (processedPaths.isEmpty) {
        return 0;
      }

      // 移除已处理的记录
      final remainingPaths = legacyPaths
          .where(
            (path) => path.status != 'cleaned' && path.status != 'ignored',
          )
          .toList();

      await _saveLegacyPaths(remainingPaths);

      AppLogger.info('清理已处理的旧路径记录完成', tag: 'LegacyDataPathManager', data: {
        'removedCount': processedPaths.length,
        'remainingCount': remainingPaths.length,
      });

      return processedPaths.length;
    } catch (e, stack) {
      AppLogger.error('清理已处理的旧路径记录失败',
          error: e, stackTrace: stack, tag: 'LegacyDataPathManager');
      return 0;
    }
  }
}
