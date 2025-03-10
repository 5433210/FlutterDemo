import '../models/work/work_image.dart';

/// 图片元数据
class ImageMetadata {
  final int width;
  final int height;
  final String format;
  final int size;

  const ImageMetadata({
    required this.width,
    required this.height,
    required this.format,
    required this.size,
  });
}

/// 批量创建图片的输入参数
class WorkImageBatchInput {
  final String workId;
  final List<WorkImageInput> images;
  final bool generateMissing;

  const WorkImageBatchInput({
    required this.workId,
    required this.images,
    this.generateMissing = true,
  });
}

/// 更新图片索引的输入参数
class WorkImageIndexUpdate {
  final String imageId;
  final int newIndex;

  const WorkImageIndexUpdate({
    required this.imageId,
    required this.newIndex,
  });
}

/// 创建图片的输入参数
class WorkImageInput {
  final String originalPath;
  final ImageMetadata metadata;
  final String? importedPath;
  final String? thumbnailPath;
  final int? targetIndex;

  const WorkImageInput({
    required this.originalPath,
    required this.metadata,
    this.importedPath,
    this.thumbnailPath,
    this.targetIndex,
  });
}

/// WorkImage仓储接口
abstract class WorkImageRepository {
  /// 批量创建
  Future<List<WorkImage>> batchCreate(
      String workId, List<WorkImageInput> inputs);

  /// 批量删除
  Future<void> batchDelete(String workId, List<String> imageIds);

  /// 创建图片记录
  Future<WorkImage> create(String workId, WorkImageInput input);

  /// 删除图片
  Future<void> delete(String workId, String imageId);

  /// 根据ID获取图片
  Future<WorkImage?> findById(String imageId);

  /// 获取作品的所有图片
  Future<List<WorkImage>> findByWorkId(String workId);

  /// 获取作品的第一张图片
  Future<WorkImage?> findFirstByWorkId(String workId);

  /// 获取下一个可用的索引号
  Future<int> getNextIndex(String workId);

  /// 事务支持
  Future<T> transaction<T>(Future<T> Function() action);

  /// 更新图片索引
  Future<void> updateIndex(String workId, String imageId, int newIndex);
}
