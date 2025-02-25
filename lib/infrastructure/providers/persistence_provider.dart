import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/models/work_filter.dart';
import 'dart:convert';

final persistenceProvider = Provider<PersistenceService>((ref) {
  return PersistenceService();
});

class PersistenceService {
  static const String viewModeKey = 'view_mode';
  static const String filterKey = 'work_filter';
  static const String sortKey = 'work_sort';
  static const String sidebarKey = 'sidebar_state';

  late SharedPreferences _sharedPreferences;

  Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  SharedPreferences get sharedPreferences => _sharedPreferences;

  Future<void> saveViewMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(viewModeKey, mode);
  }

  Future<void> saveFilter(WorkFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(filterKey, jsonEncode(filter.toJson()));
  }

  Future<WorkFilter?> loadFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(filterKey);
    if (data == null) return null;
    return WorkFilter.fromJson(jsonDecode(data));
  }

  Future<void> saveSidebarState(bool isOpen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(sidebarKey, isOpen);
  }

  Future<bool> loadSidebarState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(sidebarKey) ?? true;
  }

  // ...其他持久化方法
}
