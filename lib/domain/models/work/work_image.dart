import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as p;

part 'work_image.freezed.dart';
part 'work_image.g.dart';

/// 作品图片
@freezed
class WorkImage with _$WorkImage {
  const factory WorkImage({
    /// 图片路径
    required String path,
    required String thumbnailPath,

    /// 在作品中的序号
    required int index,
  }) = _WorkImage;

  /// 创建新图片
  factory WorkImage.create({
    required String path,
    required int index,
    required String thumbnailPath,
  }) {
    return WorkImage(
      path: path,
      index: index,
      thumbnailPath: thumbnailPath,
    );
  }

  factory WorkImage.fromJson(Map<String, dynamic> json) =>
      _$WorkImageFromJson(json);

  const WorkImage._();

  /// 目录路径
  String get directory => p.dirname(path);

  /// 扩展名
  String get extension {
    final ext = p.extension(path);
    return ext.isEmpty ? '' : ext.substring(1); // 移除点号
  }

  /// 文件名(含扩展名)
  String get filename => p.basename(path);

  /// 文件名(不含扩展名)
  String get name => p.basenameWithoutExtension(path);
}
