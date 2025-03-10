import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as p;

part 'work_image.freezed.dart';
part 'work_image.g.dart';

/// 作品图片
@freezed
class WorkImage with _$WorkImage {
  factory WorkImage({
    /// ID
    required String id,

    /// 关联的作品ID
    required String workId,

    /// 导入时的原始路径
    required String originalPath,

    /// 图片路径
    required String path,

    /// 缩略图路径
    required String thumbnailPath,

    /// 在作品中的序号
    required int index,

    /// 图片宽度
    required int width,

    /// 图片高度
    required int height,

    /// 文件格式
    required String format,

    /// 文件大小(字节)
    required int size,

    /// 创建时间
    required DateTime createTime,

    /// 更新时间
    required DateTime updateTime,
  }) = _WorkImage;

  /// 创建新图片
  @Deprecated('使用 WorkImage(...) 构造函数替代')
  factory WorkImage.create({
    required String id,
    required String workId,
    required String originalPath,
    required String path,
    required String thumbnailPath,
    required int index,
    required int width,
    required int height,
    required String format,
    required int size,
  }) =>
      WorkImage(
        id: id,
        workId: workId,
        originalPath: originalPath,
        path: path,
        thumbnailPath: thumbnailPath,
        index: index,
        width: width,
        height: height,
        format: format,
        size: size,
        createTime: DateTime.now(),
        updateTime: DateTime.now(),
      );

  factory WorkImage.fromJson(Map<String, dynamic> json) =>
      _$WorkImageFromJson(json);

  const WorkImage._();

  /// 目录路径
  String get directory => p.dirname(path);

  /// 扩展名
  String get extension {
    final ext = p.extension(path);
    return ext.isEmpty ? '' : ext.substring(1);
  }

  /// 文件名(含扩展名)
  String get filename => p.basename(path);

  /// 文件名(不含扩展名)
  String get name => p.basenameWithoutExtension(path);
}
