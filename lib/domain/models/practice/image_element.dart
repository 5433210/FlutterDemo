import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_element.freezed.dart';
part 'image_element.g.dart';

/// 图片元素
@freezed
class ImageElement with _$ImageElement {
  const factory ImageElement({
    /// 图片ID
    required String imageId,

    /// 图片URL
    required String url,

    /// 图片原始宽度
    required int width,

    /// 图片原始高度
    required int height,

    /// 图片MIME类型
    @Default('image/jpeg') String mimeType,

    /// 不透明度
    @Default(1.0) double opacity,

    /// 自定义属性
    @Default({}) Map<String, dynamic> customProps,
  }) = _ImageElement;

  /// 从JSON创建实例
  factory ImageElement.fromJson(Map<String, dynamic> json) =>
      _$ImageElementFromJson(json);

  const ImageElement._();

  /// 获取宽高比
  double get aspectRatio => width / height;

  /// 获取自定义属性
  T? getCustomProp<T>(String key) => customProps[key] as T?;

  /// 移除自定义属性
  ImageElement removeCustomProp(String key) {
    final newProps = Map<String, dynamic>.from(customProps);
    newProps.remove(key);
    return copyWith(customProps: newProps);
  }

  /// 设置自定义属性
  ImageElement setCustomProp(String key, dynamic value) {
    final newProps = Map<String, dynamic>.from(customProps);
    newProps[key] = value;
    return copyWith(customProps: newProps);
  }

  /// 设置不透明度
  ImageElement withOpacity(double value) =>
      copyWith(opacity: value.clamp(0.0, 1.0));
}
