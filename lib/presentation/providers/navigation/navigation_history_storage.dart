import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/navigation/navigation_history_item.dart';

/// 负责导航历史的持久化存储
class NavigationHistoryStorage {
  static const String _historyKey = 'navigation_history';
  static const String _sectionRoutesKey = 'section_routes';
  static const String _currentSectionKey = 'current_section';

  final SharedPreferences _prefs;

  NavigationHistoryStorage(this._prefs);

  /// 清除所有保存的导航状态
  Future<void> clearNavigationState() async {
    await _prefs.remove(_currentSectionKey);
    await _prefs.remove(_historyKey);
    await _prefs.remove(_sectionRoutesKey);
  }

  /// 读取保存的导航状态
  ({
    int currentSectionIndex,
    List<NavigationHistoryItem> history,
    Map<int, String?> sectionRoutes
  }) loadNavigationState() {
    // 读取当前功能区索引
    final currentSectionIndex = _prefs.getInt(_currentSectionKey) ?? 0;

    // 读取并反序列化历史记录
    final historyJson = _prefs.getString(_historyKey);
    final history = <NavigationHistoryItem>[];
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      history.addAll(
        decoded.map((item) => NavigationHistoryItem.fromJson(item)),
      );
    }

    // 读取并反序列化功能区路由
    final sectionRoutesJson = _prefs.getString(_sectionRoutesKey);
    final sectionRoutes = <int, String?>{};
    if (sectionRoutesJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(sectionRoutesJson);
      decoded.forEach((key, value) {
        sectionRoutes[int.parse(key)] = value as String?;
      });
    }

    return (
      currentSectionIndex: currentSectionIndex,
      history: history,
      sectionRoutes: sectionRoutes
    );
  }

  /// 保存导航历史
  Future<void> saveNavigationState({
    required int currentSectionIndex,
    required List<NavigationHistoryItem> history,
    required Map<int, String?> sectionRoutes,
  }) async {
    // 保存当前功能区索引
    await _prefs.setInt(_currentSectionKey, currentSectionIndex);

    // 序列化并保存历史记录
    final historyJson = history.map((item) => item.toJson()).toList();
    await _prefs.setString(_historyKey, jsonEncode(historyJson));

    // 序列化并保存功能区路由
    final sectionRoutesJson = sectionRoutes.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    await _prefs.setString(_sectionRoutesKey, jsonEncode(sectionRoutesJson));
  }
}
