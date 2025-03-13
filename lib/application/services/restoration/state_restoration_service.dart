import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/work/work_entity.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../presentation/providers/work_detail_provider.dart';
import '../../../presentation/viewmodels/states/work_browse_state.dart';

/// 负责保存和恢复应用状态
class StateRestorationService {
  // 键前缀常量
  static const _workEditStatePrefix = 'work_edit_state_';
  static const _workEditTimestampPrefix = 'work_edit_timestamp_';

  // 浏览页相关键
  static const String _workBrowseStateKey = 'work_browse_state';
  static const String _workBrowseTimestampKey = 'work_browse_timestamp';

  // 状态有效期（毫秒），默认24小时
  static const _stateValidityPeriod = 24 * 60 * 60 * 1000;

  final SharedPreferences _prefs;

  StateRestorationService(this._prefs) {
    _checkFirstRun();
  }

  /// 检查编辑会话状态
  Future<String> checkEditSessions() async {
    try {
      final keys = _prefs.getKeys();
      final editStateKeys =
          keys.where((key) => key.startsWith('work_edit_state_'));
      return '${editStateKeys.length}个活动编辑会话';
    } catch (e) {
      AppLogger.error('检查编辑会话失败', tag: 'StateRestorationService', error: e);
      return '未知';
    }
  }

  /// 清除产品浏览页状态
  Future<void> clearWorkBrowseState() async {
    try {
      await _prefs.remove(_workBrowseStateKey);
      await _prefs.remove(_workBrowseTimestampKey);

      AppLogger.debug('已清除浏览页状态', tag: 'StateRestorationService');
    } catch (e, stack) {
      AppLogger.error(
        '清除浏览页状态失败',
        tag: 'StateRestorationService',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// 清除特定作品的编辑状态
  Future<void> clearWorkEditState(String workId) async {
    try {
      final stateKey = '$_workEditStatePrefix$workId';
      final timestampKey = '$_workEditTimestampPrefix$workId';

      await _prefs.remove(stateKey);
      await _prefs.remove(timestampKey);

      AppLogger.debug('已清除编辑状态',
          tag: 'StateRestorationService', data: {'workId': workId});
    } catch (e, stack) {
      AppLogger.error(
        '清除编辑状态失败',
        tag: 'StateRestorationService',
        error: e,
        stackTrace: stack,
        data: {'workId': workId},
      );
    }
  }

  /// 获取SharedPreferences中的条目数
  Future<String> getPreferencesEntryCount() async {
    try {
      final keys = _prefs.getKeys();
      return keys.length.toString();
    } catch (e) {
      AppLogger.error(
        '获取Preferences条目数失败',
        tag: 'StateRestorationService',
        error: e,
      );
    }
    return '未知';
  }

  /// 获取SharedPreferences文件的大小
  Future<String> getPreferencesFileSize() async {
    try {
      final path = await getPreferencesPath();
      final file = File(path);
      if (await file.exists()) {
        final size = await file.length();
        return '${(size / 1024).toStringAsFixed(2)} KB';
      }
    } catch (e) {
      AppLogger.error(
        '获取Preferences文件大小失败',
        tag: 'StateRestorationService',
        error: e,
      );
    }
    return '未知';
  }

  /// 获取SharedPreferences文件的路径
  Future<String> getPreferencesPath() async {
    final appDataDir = Platform.isWindows
        ? Platform.environment['LOCALAPPDATA']
        : Platform.environment['HOME'];

    if (appDataDir == null) {
      return '未知';
    }

    return '$appDataDir/SharedPreferences.json';
  }

  /// 获取状态存储位置
  Future<String> getStorageLocation() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      return appDir.path;
    } catch (e) {
      AppLogger.error('获取存储位置失败', tag: 'StateRestorationService', error: e);
      return '未知';
    }
  }

  /// 检查是否有未完成的编辑会话
  Future<bool> hasUnfinishedEditSession(String workId) async {
    try {
      final stateKey = '$_workEditStatePrefix$workId';
      final timestampKey = '$_workEditTimestampPrefix$workId';

      // 检查状态是否存在
      final hasState = _prefs.containsKey(stateKey);
      if (!hasState) return false;

      // 检查状态是否过期
      final timestamp = _prefs.getInt(timestampKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (currentTime - timestamp > _stateValidityPeriod) {
        // 状态已过期，自动清理
        await clearWorkEditState(workId);
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.error(
        '检查未完成编辑会话失败',
        tag: 'StateRestorationService',
        error: e,
        data: {'workId': workId},
      );
      return false;
    }
  }

  /// 检查是否有保存的浏览页状态
  Future<bool> hasWorkBrowseState() async {
    try {
      // 检查状态是否存在
      final hasState = _prefs.containsKey(_workBrowseStateKey);
      if (!hasState) return false;

      // 检查状态是否过期
      final timestamp = _prefs.getInt(_workBrowseTimestampKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (currentTime - timestamp > _stateValidityPeriod) {
        // 状态已过期，自动清理
        await clearWorkBrowseState();
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.error(
        '检查浏览页状态失败',
        tag: 'StateRestorationService',
        error: e,
      );
      return false;
    }
  }

  /// 恢复产品浏览页状态
  Future<WorkBrowseState?> restoreWorkBrowseState() async {
    try {
      // 获取保存的状态
      AppLogger.debug(
        '尝试恢复WorkBrowseState',
        tag: 'StateRestorationService',
      );

      final stateJson = _prefs.getString(_workBrowseStateKey);
      if (stateJson == null) {
        AppLogger.debug(
          '没有找到已保存的状态，返回null',
          tag: 'StateRestorationService',
        );
        return null;
      }

      // 解析状态
      AppLogger.debug(
        '开始解析状态JSON',
        tag: 'StateRestorationService',
        data: {'stateJson': stateJson},
      );

      try {
        final stateMap = jsonDecode(stateJson) as Map<String, dynamic>;

        // 创建状态对象
        final restoredState = WorkBrowseState.fromJson(stateMap);

        AppLogger.debug(
          '状态恢复成功',
          tag: 'StateRestorationService',
          data: {
            'filter': {
              'style': restoredState.filter.style?.name,
              'tool': restoredState.filter.tool?.name,
            }
          },
        );

        return restoredState;
      } catch (parseError) {
        AppLogger.error(
          'JSON解析失败',
          tag: 'StateRestorationService',
          error: parseError,
          data: {'stateJson': stateJson},
        );
        // 如果JSON解析失败，清除存储的状态并返回null
        await clearWorkBrowseState();
        return null;
      }
    } catch (e, stack) {
      AppLogger.error(
        '恢复浏览页状态失败',
        tag: 'StateRestorationService',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// 恢复作品的编辑状态
  Future<WorkDetailState?> restoreWorkEditState(String workId) async {
    try {
      final stateKey = '$_workEditStatePrefix$workId';

      // 获取保存的状态
      final stateJson = _prefs.getString(stateKey);
      if (stateJson == null) return null;

      // 解析状态
      final stateMap = jsonDecode(stateJson) as Map<String, dynamic>;

      // 恢复 WorkEntity 对象
      WorkEntity? editingWork;
      if (stateMap.containsKey('editingWork')) {
        try {
          final workMap = stateMap['editingWork'] as Map<String, dynamic>;
          editingWork = WorkEntity.fromJson(workMap);
        } catch (e) {
          AppLogger.error(
            '恢复作品实体失败',
            tag: 'StateRestorationService',
            error: e,
            data: {'workId': workId},
          );
        }
      }

      // 恢复基本状态属性
      final isEditing = stateMap['isEditing'] as bool? ?? false;
      final hasChanges = stateMap['hasChanges'] as bool? ?? false;
      final historyIndex = stateMap['historyIndex'] as int? ?? -1;

      // 返回恢复的状态（注意: 命令历史无法从 JSON 恢复，因为它包含服务依赖）
      return WorkDetailState(
        isEditing: isEditing,
        editingWork: editingWork,
        hasChanges: hasChanges,
        historyIndex: historyIndex,
      );
    } catch (e, stack) {
      AppLogger.error(
        '恢复编辑状态失败',
        tag: 'StateRestorationService',
        error: e,
        stackTrace: stack,
        data: {'workId': workId},
      );
      return null;
    }
  }

  /// 保存产品浏览页状态
  Future<void> saveWorkBrowseState(WorkBrowseState state) async {
    try {
      // 转换状态为 JSON
      final stateMap = state.toJson();
      AppLogger.debug(
        '准备保存状态',
        tag: 'StateRestorationService',
        data: {
          'filter': {
            'style': state.filter.style?.name,
            'tool': state.filter.tool?.name,
          }
        },
      );

      final stateJson = jsonEncode(stateMap);

      // 保存状态和时间戳
      await _prefs.setString(_workBrowseStateKey, stateJson);
      await _prefs.setInt(
          _workBrowseTimestampKey, DateTime.now().millisecondsSinceEpoch);

      AppLogger.debug(
        '状态保存成功',
        tag: 'StateRestorationService',
      );
    } catch (e, stack) {
      AppLogger.error(
        '保存浏览页状态失败',
        tag: 'StateRestorationService',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// 保存作品的编辑状态
  Future<void> saveWorkEditState(String workId, WorkDetailState state) async {
    try {
      if (state.editingWork == null) return;

      final stateKey = '$_workEditStatePrefix$workId';
      final timestampKey = '$_workEditTimestampPrefix$workId';

      // 准备要保存的数据
      final stateMap = {
        'isEditing': state.isEditing,
        'hasChanges': state.hasChanges,
        'historyIndex': state.historyIndex,
      };

      // 保存 WorkEntity
      try {
        stateMap['editingWork'] = state.editingWork!.toJson();
      } catch (e) {
        AppLogger.error(
          '序列化作品实体失败',
          tag: 'StateRestorationService',
          error: e,
          data: {'workId': workId},
        );
      }

      // 保存状态和时间戳
      final stateJson = jsonEncode(stateMap);
      await _prefs.setString(stateKey, stateJson);
      await _prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

      AppLogger.debug('已保存编辑状态',
          tag: 'StateRestorationService', data: {'workId': workId});
    } catch (e, stack) {
      AppLogger.error(
        '保存编辑状态失败',
        tag: 'StateRestorationService',
        error: e,
        stackTrace: stack,
        data: {'workId': workId},
      );
    }
  }

  /// 检查是否首次运行，如果是则清除所有状态
  void _checkFirstRun() {
    final firstRun = _prefs.getBool('first_run') ?? true;
    if (firstRun) {
      _prefs.remove(_workBrowseStateKey);
      _prefs.remove(_workBrowseTimestampKey);
      _prefs.setBool('first_run', false);
      AppLogger.info(
        '首次运行，已清除所有已保存状态',
        tag: 'StateRestorationService',
      );
    }
  }
}
