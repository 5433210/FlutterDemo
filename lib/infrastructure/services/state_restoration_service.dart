import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../presentation/models/work_filter.dart';
import '../../presentation/viewmodels/states/work_browse_state.dart';
import '../../presentation/viewmodels/work_browse_view_model.dart';

class StateRestorationService {
  static const String keyPrefix = 'app_state_';
  static const String workBrowseKey = '${keyPrefix}work_browse';
  final SharedPreferences _prefs;

  StateRestorationService(this._prefs);
  

  // 保存工作浏览状态
  Future<void> saveWorkBrowseState(WorkBrowseState state) async {
    try {
      final stateMap = {
        'viewMode': state.viewMode.index,
        'isSidebarOpen': state.isSidebarOpen,
        'filter': state.filter.toJson(),
        'searchQuery': state.searchQuery,
        'pageSize': state.pageSize,
      };
      await _prefs.setString(workBrowseKey, jsonEncode(stateMap));
    } catch (e) {
      debugPrint('Error saving work browse state: $e');
    }
  }

  // 恢复工作浏览状态
  
  Future<WorkBrowseState?> restoreWorkBrowseState(WorkBrowseViewModel viewModel) async {
    try {
      final json = _prefs.getString(workBrowseKey);
      if (json == null) return null;

      final stateMap = jsonDecode(json) as Map<String, dynamic>;
      return WorkBrowseState(
        viewMode: ViewMode.values[stateMap['viewMode'] as int],
        isSidebarOpen: stateMap['isSidebarOpen'] as bool,
        filter: WorkFilter.fromJson(stateMap['filter'] as Map<String, dynamic>),
        searchQuery: (stateMap['searchQuery'] as String?) ?? '',
        pageSize: stateMap['pageSize'] as int? ?? 20,
      );
    } catch (e) {
      debugPrint('Error restoring work browse state: $e');
      return null;
    }
  }

  // 清除所有状态
  Future<void> clearAllStates() async {
    final keys = _prefs.getKeys().where((key) => key.startsWith(keyPrefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
