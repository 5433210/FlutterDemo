import '../models/work/work_image.dart';

/// WorkImage仓储接口
abstract class WorkImageRepository {
  /// 创建图片记录
  Future<WorkImage> create(String workId, WorkImage image);

  /// 批量创建
  Future<List<WorkImage>> createMany(String workId, List<WorkImage> images);

  /// 删除图片
  Future<void> delete(String workId, String imageId);

  /// 批量删除
  Future<void> deleteMany(String workId, List<String> imageIds);

  /// 获取图片
  Future<WorkImage?> get(String imageId);

  /// 获取作品的所有图片
  Future<List<WorkImage>> getAllByWorkId(String workId);

  /// 获取作品的第一张图片
  Future<WorkImage?> getFirstByWorkId(String workId);

  /// 获取下一个可用的索引号
  Future<int> getNextIndex(String workId);

  /// 批量更新
  Future<List<WorkImage>> saveMany(List<WorkImage> images);

  /// 更新图片索引
  Future<void> updateIndex(String workId, String imageId, int newIndex);
}
