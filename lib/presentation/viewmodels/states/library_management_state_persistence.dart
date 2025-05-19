import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../infrastructure/logging/logger.dart';
import 'library_management_state.dart';

/// 扩展方法，提供图库管理状态持久化功能
extension LibraryManagementStatePersistence on LibraryManagementState {
  static const String _keyLibraryManagementState = 'library_management_state';

  /// 保存状态到SharedPreferences
  Future<void> persist() async {
    try {
      AppLogger.debug('Persisting LibraryManagementState', tag: 'State');

      final prefs = await SharedPreferences.getInstance();
      final jsonData = toJson();
      final jsonString = jsonEncode(jsonData);
      await prefs.setString(_keyLibraryManagementState, jsonString);

      AppLogger.debug('LibraryManagementState persisted successfully',
          tag: 'State');
    } catch (e, stack) {
      AppLogger.error('Failed to persist LibraryManagementState',
          tag: 'State', error: e, stackTrace: stack);
    }
  }

  /// 将状态转换为JSON
  Map<String, dynamic> toJson() {
    final result = {
      'viewMode': viewMode.index,
      'isBatchMode': isBatchMode,
      'selectedItems': selectedItems.toList(),
      'showFavoritesOnly': showFavoritesOnly,
      'showFilterPanel': showFilterPanel,
      'isImagePreviewOpen': isImagePreviewOpen,
      'selectedCategoryId': selectedCategoryId,
      // 保存其他重要的状态属性但排除大型集合数据
    };

    AppLogger.debug('LibraryManagementState serialized successfully',
        tag: 'State');
    return result;
  }

  /// 从JSON恢复状态
  static LibraryManagementState fromJson(Map<String, dynamic> json) {
    try {
      AppLogger.debug('Deserializing LibraryManagementState',
          tag: 'State', data: {'json': json});

      // 获取viewMode或使用默认值
      final viewModeIndex = json['viewMode'] as int?;
      final viewMode = viewModeIndex != null
          ? ViewMode.values[viewModeIndex]
          : ViewMode.grid;

      // 恢复selectedItems
      final selectedItemsList = json['selectedItems'] as List<dynamic>?;
      final selectedItems = selectedItemsList != null
          ? Set<String>.from(selectedItemsList.cast<String>())
          : <String>{};

      // 创建初始状态并应用保存的值
      final state = LibraryManagementState.initial().copyWith(
        viewMode: viewMode,
        isBatchMode: json['isBatchMode'] as bool? ?? false,
        selectedItems: selectedItems,
        showFavoritesOnly: json['showFavoritesOnly'] as bool? ?? false,
        showFilterPanel: json['showFilterPanel'] as bool? ?? true,
        isImagePreviewOpen: json['isImagePreviewOpen'] as bool? ?? false,
        selectedCategoryId: json['selectedCategoryId'] as String?,
        // 使用默认值，避免覆盖重要状态
        isLoading: false,
        isDetailOpen: false,
        items: const [],
        errorMessage: null,
      );

      AppLogger.debug('LibraryManagementState deserialized successfully',
          tag: 'State',
          data: {
            'viewMode': state.viewMode.toString(),
            'isBatchMode': state.isBatchMode,
          });

      return state;
    } catch (e, stack) {
      AppLogger.error(
        'Error deserializing LibraryManagementState',
        tag: 'State',
        error: e,
        stackTrace: stack,
      );

      // 出错时返回默认状态
      return LibraryManagementState.initial();
    }
  }

  /// 从SharedPreferences恢复保存的状态
  static Future<LibraryManagementState> restore() async {
    try {
      AppLogger.debug('Restoring LibraryManagementState', tag: 'State');

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyLibraryManagementState);

      if (jsonString == null) {
        AppLogger.debug('No saved LibraryManagementState found, using defaults',
            tag: 'State');
        return LibraryManagementState.initial();
      }

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final state = fromJson(jsonData);

      AppLogger.debug('LibraryManagementState restored successfully',
          tag: 'State');

      return state;
    } catch (e, stack) {
      AppLogger.error('Failed to restore LibraryManagementState',
          tag: 'State', error: e, stackTrace: stack);
      return LibraryManagementState.initial();
    }
  }
}
