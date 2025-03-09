import 'package:freezed_annotation/freezed_annotation.dart';

part 'element_geometry.freezed.dart';
part 'element_geometry.g.dart';

/// 元素几何属性
@freezed
class ElementGeometry with _$ElementGeometry {
  const factory ElementGeometry({
    /// X坐标
    @Default(0.0) double x,

    /// Y坐标
    @Default(0.0) double y,

    /// 宽度
    @Default(100.0) double width,

    /// 高度
    @Default(100.0) double height,

    /// 旋转角度(弧度)
    @Default(0.0) double rotation,

    /// 缩放
    @Default(1.0) double scale,
  }) = _ElementGeometry;

  /// 从JSON创建实例
  factory ElementGeometry.fromJson(Map<String, dynamic> json) =>
      _$ElementGeometryFromJson(json);

  const ElementGeometry._();

  /// 获取下边界
  double get bottom => y + height;

  /// 获取中心点X坐标
  double get centerX => x + width / 2;

  /// 获取中心点Y坐标
  double get centerY => y + height / 2;

  /// 获取右边界
  double get right => x + width;

  /// 判断点是否在边界内
  bool containsPoint(double px, double py) {
    return px >= x && px <= right && py >= y && py <= bottom;
  }

  /// 移动元素
  ElementGeometry move(double dx, double dy) {
    return copyWith(
      x: x + dx,
      y: y + dy,
    );
  }

  /// 调整大小
  ElementGeometry resize(double width, double height) {
    return copyWith(
      width: width,
      height: height,
    );
  }

  /// 旋转
  ElementGeometry rotate(double angle) {
    return copyWith(
      rotation: rotation + angle,
    );
  }

  /// 设置缩放
  ElementGeometry setScale(double scale) {
    return copyWith(
      scale: scale,
    );
  }
}
