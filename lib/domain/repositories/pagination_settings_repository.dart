import '../models/pagination/pagination_settings.dart';

/// 分页设置仓库接口
abstract class PaginationSettingsRepository {
  /// 获取指定页面的分页设置
  Future<PaginationSettings?> getPaginationSettings(String pageId);

  /// 获取所有分页设置
  Future<AllPaginationSettings> getAllPaginationSettings();

  /// 保存指定页面的分页设置
  Future<void> savePaginationSettings(PaginationSettings settings);

  /// 保存所有分页设置
  Future<void> saveAllPaginationSettings(AllPaginationSettings settings);

  /// 删除指定页面的分页设置
  Future<void> deletePaginationSettings(String pageId);

  /// 清空所有分页设置
  Future<void> clearAllPaginationSettings();

  /// 获取指定页面的页面大小，如果不存在则返回默认值
  Future<int> getPageSize(String pageId, {int defaultSize = 20});

  /// 保存指定页面的页面大小
  Future<void> savePageSize(String pageId, int pageSize);
}