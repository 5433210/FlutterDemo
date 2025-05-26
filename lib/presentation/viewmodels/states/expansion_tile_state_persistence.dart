import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../infrastructure/logging/logger.dart';
import 'expansion_tile_state.dart';

/// 扩展方法，提供 ExpansionTile 状态持久化功能
extension ExpansionTileStatePersistence on ExpansionTileState {
  static const String _keyExpansionTileState = 'expansion_tile_state';

  /// 保存状态到 SharedPreferences
  Future<void> persist() async {
    try {
      AppLogger.debug('Persisting ExpansionTileState', tag: 'ExpansionTile');

      final prefs = await SharedPreferences.getInstance();
      final jsonData = toJson();
      final jsonString = jsonEncode(jsonData);
      await prefs.setString(_keyExpansionTileState, jsonString);

      AppLogger.debug('ExpansionTileState persisted successfully',
          tag: 'ExpansionTile', data: {'tileCount': tileStates.length});
    } catch (e, stack) {
      AppLogger.error('Failed to persist ExpansionTileState',
          tag: 'ExpansionTile', error: e, stackTrace: stack);
    }
  }

  /// 将状态转换为 JSON
  Map<String, dynamic> toJson() {
    final result = {
      'tileStates': tileStates,
    };

    AppLogger.debug('ExpansionTileState serialized successfully',
        tag: 'ExpansionTile');
    return result;
  }

  /// 清除保存的状态
  static Future<void> clear() async {
    try {
      AppLogger.debug('Clearing ExpansionTileState', tag: 'ExpansionTile');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyExpansionTileState);

      AppLogger.debug('ExpansionTileState cleared successfully',
          tag: 'ExpansionTile');
    } catch (e, stack) {
      AppLogger.error('Failed to clear ExpansionTileState',
          tag: 'ExpansionTile', error: e, stackTrace: stack);
    }
  }

  /// 从 JSON 恢复状态
  static ExpansionTileState fromJson(Map<String, dynamic> json) {
    try {
      AppLogger.debug('Deserializing ExpansionTileState',
          tag: 'ExpansionTile', data: {'json': json});

      // 恢复 tileStates
      final tileStatesData = json['tileStates'] as Map<String, dynamic>?;
      final tileStates = tileStatesData != null
          ? Map<String, bool>.from(tileStatesData.map((key, value) =>
              MapEntry(key, value is bool ? value : value == true)))
          : <String, bool>{};

      final state = ExpansionTileState(tileStates: tileStates);

      AppLogger.debug('ExpansionTileState deserialized successfully',
          tag: 'ExpansionTile', data: {'tileCount': state.tileStates.length});

      return state;
    } catch (e, stack) {
      AppLogger.error(
        'Error deserializing ExpansionTileState',
        tag: 'ExpansionTile',
        error: e,
        stackTrace: stack,
      );

      // 出错时返回默认状态
      return ExpansionTileState.initial();
    }
  }

  /// 从 SharedPreferences 恢复保存的状态
  static Future<ExpansionTileState> restore() async {
    try {
      AppLogger.debug('Restoring ExpansionTileState', tag: 'ExpansionTile');

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyExpansionTileState);

      if (jsonString == null) {
        AppLogger.debug('No saved ExpansionTileState found, using defaults',
            tag: 'ExpansionTile');
        return ExpansionTileState.initial();
      }

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final state = fromJson(jsonData);

      AppLogger.debug('ExpansionTileState restored successfully',
          tag: 'ExpansionTile');

      return state;
    } catch (e, stack) {
      AppLogger.error('Failed to restore ExpansionTileState',
          tag: 'ExpansionTile', error: e, stackTrace: stack);
      return ExpansionTileState.initial();
    }
  }
}
