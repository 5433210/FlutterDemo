import '../../domain/models/pagination/pagination_settings.dart';
import '../../domain/repositories/pagination_settings_repository.dart';
import '../../infrastructure/logging/logger.dart';

/// 分页设置服务
class PaginationSettingsService {
  final PaginationSettingsRepository _repository;

  PaginationSettingsService({
    required PaginationSettingsRepository repository,
  }) : _repository = repository;

  /// 获取指定页面的页面大小
  /// 
  /// [pageId] 页面标识符
  /// [defaultSize] 默认页面大小
  /// 返回该页面的页面大小设置
  Future<int> getPageSize(String pageId, {int defaultSize = 20}) async {
    try {
      return await _repository.getPageSize(pageId, defaultSize: defaultSize);
    } catch (e) {
      AppLogger.error('获取页面大小失败，使用默认值', error: e, data: {
        'pageId': pageId,
        'defaultSize': defaultSize,
      });
      return defaultSize;
    }
  }

  /// 设置指定页面的页面大小
  /// 
  /// [pageId] 页面标识符
  /// [pageSize] 页面大小
  Future<void> setPageSize(String pageId, int pageSize) async {
    try {
      if (pageSize <= 0) {
        throw ArgumentError('页面大小必须大于0');
      }

      await _repository.savePageSize(pageId, pageSize);

      AppLogger.info('页面大小设置已更新', data: {
        'pageId': pageId,
        'pageSize': pageSize,
      });
    } catch (e) {
      AppLogger.error('设置页面大小失败', error: e, data: {
        'pageId': pageId,
        'pageSize': pageSize,
      });
      rethrow;
    }
  }

  /// 获取指定页面的完整分页设置
  /// 
  /// [pageId] 页面标识符
  /// 返回该页面的分页设置，如果不存在则返回null
  Future<PaginationSettings?> getPaginationSettings(String pageId) async {
    try {
      return await _repository.getPaginationSettings(pageId);
    } catch (e) {
      AppLogger.error('获取分页设置失败', error: e, data: {'pageId': pageId});
      return null;
    }
  }

  /// 获取所有分页设置
  Future<AllPaginationSettings> getAllPaginationSettings() async {
    try {
      return await _repository.getAllPaginationSettings();
    } catch (e) {
      AppLogger.error('获取所有分页设置失败', error: e);
      return const AllPaginationSettings();
    }
  }

  /// 重置指定页面的分页设置
  /// 
  /// [pageId] 页面标识符
  Future<void> resetPageSettings(String pageId) async {
    try {
      await _repository.deletePaginationSettings(pageId);
      AppLogger.info('页面分页设置已重置', data: {'pageId': pageId});
    } catch (e) {
      AppLogger.error('重置页面分页设置失败', error: e, data: {'pageId': pageId});
      rethrow;
    }
  }

  /// 重置所有分页设置
  Future<void> resetAllSettings() async {
    try {
      await _repository.clearAllPaginationSettings();
      AppLogger.info('所有分页设置已重置');
    } catch (e) {
      AppLogger.error('重置所有分页设置失败', error: e);
      rethrow;
    }
  }

  /// 导出分页设置（用于备份）
  Future<Map<String, dynamic>> exportSettings() async {
    try {
      final allSettings = await getAllPaginationSettings();
      return allSettings.toJson();
    } catch (e) {
      AppLogger.error('导出分页设置失败', error: e);
      return {};
    }
  }

  /// 导入分页设置（用于恢复）
  Future<void> importSettings(Map<String, dynamic> settingsData) async {
    try {
      final allSettings = AllPaginationSettings.fromJson(settingsData);
      await _repository.saveAllPaginationSettings(allSettings);
      
      AppLogger.info('分页设置已导入', data: {
        'settingsCount': allSettings.settings.length,
      });
    } catch (e) {
      AppLogger.error('导入分页设置失败', error: e);
      rethrow;
    }
  }
}