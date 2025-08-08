import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/pagination/pagination_settings.dart';
import '../../domain/repositories/pagination_settings_repository.dart';
import '../../infrastructure/logging/logger.dart';

/// 基于SharedPreferences的分页设置仓库实现
class PaginationSettingsRepositoryImpl implements PaginationSettingsRepository {
  static const String _keyPrefix = 'pagination_settings_';
  static const String _keyAll = 'all_pagination_settings';

  /// SharedPreferences实例
  final SharedPreferences _prefs;

  PaginationSettingsRepositoryImpl({
    required SharedPreferences prefs,
  }) : _prefs = prefs;

  @override
  Future<void> clearAllPaginationSettings() async {
    try {
      await _prefs.remove(_keyAll);
      
      // 清除所有以前缀开头的key
      final keys = _prefs.getKeys();
      final paginationKeys = keys.where((key) => key.startsWith(_keyPrefix));
      
      for (final key in paginationKeys) {
        await _prefs.remove(key);
      }

      AppLogger.debug('已清空所有分页设置');
    } catch (e) {
      AppLogger.error('清空分页设置失败', error: e);
      rethrow;
    }
  }

  @override
  Future<void> deletePaginationSettings(String pageId) async {
    try {
      await _prefs.remove('$_keyPrefix$pageId');
      AppLogger.debug('已删除页面分页设置', data: {'pageId': pageId});
    } catch (e) {
      AppLogger.error('删除页面分页设置失败', error: e, data: {'pageId': pageId});
      rethrow;
    }
  }

  @override
  Future<AllPaginationSettings> getAllPaginationSettings() async {
    try {
      final jsonString = _prefs.getString(_keyAll);
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return AllPaginationSettings.fromJson(json);
      }
      return const AllPaginationSettings();
    } catch (e) {
      AppLogger.error('获取所有分页设置失败', error: e);
      return const AllPaginationSettings();
    }
  }

  @override
  Future<PaginationSettings?> getPaginationSettings(String pageId) async {
    try {
      final jsonString = _prefs.getString('$_keyPrefix$pageId');
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return PaginationSettings.fromJson(json);
      }
      return null;
    } catch (e) {
      AppLogger.error('获取分页设置失败', error: e, data: {'pageId': pageId});
      return null;
    }
  }

  @override
  Future<int> getPageSize(String pageId, {int defaultSize = 20}) async {
    try {
      final settings = await getPaginationSettings(pageId);
      return settings?.pageSize ?? defaultSize;
    } catch (e) {
      AppLogger.error('获取页面大小失败', error: e, data: {'pageId': pageId});
      return defaultSize;
    }
  }

  @override
  Future<void> saveAllPaginationSettings(AllPaginationSettings settings) async {
    try {
      final jsonString = jsonEncode(settings.toJson());
      await _prefs.setString(_keyAll, jsonString);
      AppLogger.debug('已保存所有分页设置', data: {'settingsCount': settings.settings.length});
    } catch (e) {
      AppLogger.error('保存所有分页设置失败', error: e);
      rethrow;
    }
  }

  @override
  Future<void> savePaginationSettings(PaginationSettings settings) async {
    try {
      final jsonString = jsonEncode(settings.toJson());
      await _prefs.setString('$_keyPrefix${settings.pageId}', jsonString);
      AppLogger.debug('已保存页面分页设置', data: {
        'pageId': settings.pageId,
        'pageSize': settings.pageSize,
      });
    } catch (e) {
      AppLogger.error('保存页面分页设置失败', error: e, data: {
        'pageId': settings.pageId,
      });
      rethrow;
    }
  }

  @override
  Future<void> savePageSize(String pageId, int pageSize) async {
    try {
      // 先尝试获取现有设置
      var settings = await getPaginationSettings(pageId);
      
      // 如果不存在则创建新的设置
      if (settings == null) {
        settings = PaginationSettings(
          pageId: pageId,
          pageSize: pageSize,
          lastUpdated: DateTime.now(),
        );
      } else {
        // 更新现有设置
        settings = settings.copyWith(
          pageSize: pageSize,
          lastUpdated: DateTime.now(),
        );
      }

      // 保存设置
      await savePaginationSettings(settings);

      AppLogger.debug('已保存页面大小设置', data: {
        'pageId': pageId,
        'pageSize': pageSize,
      });
    } catch (e) {
      AppLogger.error('保存页面大小设置失败', error: e, data: {
        'pageId': pageId,
        'pageSize': pageSize,
      });
      rethrow;
    }
  }
}