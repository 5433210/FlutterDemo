import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../infrastructure/logging/logger.dart';
import '../../presentation/viewmodels/states/work_browse_state.dart';
import '../../presentation/viewmodels/work_browse_view_model.dart';

/// 负责保存和恢复应用的状态
class StateRestorationService {
  static const _workBrowseStateKey = 'work_browse_state';

  final SharedPreferences _prefs;

  StateRestorationService(this._prefs);

  /// 清除所有保存的状态
  Future<void> clearAllState() async {
    try {
      AppLogger.info('Clearing all saved states',
          tag: 'StateRestorationService');

      await _prefs.remove(_workBrowseStateKey);

      AppLogger.info('All saved states cleared',
          tag: 'StateRestorationService');
    } catch (e, stack) {
      AppLogger.error('Failed to clear saved states',
          tag: 'StateRestorationService', error: e, stackTrace: stack);
    }
  }

  /// 恢复作品浏览状态
  Future<WorkBrowseState?> restoreWorkBrowseState(
      WorkBrowseViewModel viewModel) async {
    try {
      AppLogger.debug('Restoring work browse state',
          tag: 'StateRestorationService');

      final stateJson = _prefs.getString(_workBrowseStateKey);
      if (stateJson == null) {
        AppLogger.debug('No saved state found', tag: 'StateRestorationService');
        return null;
      }

      final stateMap = jsonDecode(stateJson) as Map<String, dynamic>;
      final state = WorkBrowseState.fromJson(stateMap); // 使用静态方法 fromJson 创建状态

      AppLogger.debug('Work browse state restored',
          tag: 'StateRestorationService',
          data: {'viewMode': state.viewMode.toString()});

      return state;
    } catch (e, stack) {
      AppLogger.error('Failed to restore work browse state',
          tag: 'StateRestorationService', error: e, stackTrace: stack);
      return null;
    }
  }

  /// 保存作品浏览状态
  Future<void> saveWorkBrowseState(WorkBrowseState state) async {
    try {
      AppLogger.debug('Saving work browse state',
          tag: 'StateRestorationService');

      final stateJson = state.toJson();
      await _prefs.setString(_workBrowseStateKey, jsonEncode(stateJson));

      AppLogger.debug('Work browse state saved',
          tag: 'StateRestorationService');
    } catch (e, stack) {
      AppLogger.error('Failed to save work browse state',
          tag: 'StateRestorationService', error: e, stackTrace: stack);
    }
  }
}
