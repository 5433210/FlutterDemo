import 'package:equatable/equatable.dart';

/// 元素的位置和尺寸信息
class ElementGeometry extends Equatable {
  /// X坐标
  final double x;

  /// Y坐标
  final double y;

  /// 宽度
  final double width;

  /// 高度
  final double height;

  /// 旋转角度
  final double rotation;

  const ElementGeometry({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0.0,
  });

  factory ElementGeometry.fromJson(Map<String, dynamic> json) {
    return ElementGeometry(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [x, y, width, height, rotation];

  ElementGeometry copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
  }) {
    return ElementGeometry(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
    };
  }
}
