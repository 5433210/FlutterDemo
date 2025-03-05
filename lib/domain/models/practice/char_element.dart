import 'package:equatable/equatable.dart';

/// 字符元素
class CharElement extends Equatable {
  /// 字符ID
  final String charId;

  /// 相对位置
  final CharPosition position;

  /// 变换信息
  final CharTransform transform;

  /// 样式信息
  final CharStyle style;

  const CharElement({
    required this.charId,
    required this.position,
    required this.transform,
    required this.style,
  });

  /// 从JSON数据创建字符元素
  factory CharElement.fromJson(Map<String, dynamic> json) {
    return CharElement(
      charId: json['charId'] as String,
      position: CharPosition.fromJson(json['position'] as Map<String, dynamic>),
      transform:
          CharTransform.fromJson(json['transform'] as Map<String, dynamic>),
      style: CharStyle.fromJson(json['style'] as Map<String, dynamic>),
    );
  }

  /// 从默认值创建字符元素
  factory CharElement.standard({
    required String charId,
    double offsetX = 0,
    double offsetY = 0,
  }) {
    return CharElement(
      charId: charId,
      position: CharPosition(offsetX: offsetX, offsetY: offsetY),
      transform: const CharTransform(),
      style: const CharStyle(),
    );
  }

  @override
  List<Object?> get props => [charId, position, transform, style];

  /// 创建一个带有更新属性的新实例
  CharElement copyWith({
    String? charId,
    CharPosition? position,
    CharTransform? transform,
    CharStyle? style,
  }) {
    return CharElement(
      charId: charId ?? this.charId,
      position: position ?? this.position,
      transform: transform ?? this.transform,
      style: style ?? this.style,
    );
  }

  /// 移动字符
  CharElement move(double dx, double dy) {
    return copyWith(
      position: position.copyWith(
        offsetX: position.offsetX + dx,
        offsetY: position.offsetY + dy,
      ),
    );
  }

  /// 旋转字符
  CharElement rotate(double angle) {
    return copyWith(
      transform: transform.copyWith(
        rotation: transform.rotation + angle,
      ),
    );
  }

  /// 缩放字符
  CharElement scale(double sx, double sy) {
    return copyWith(
      transform: transform.copyWith(
        scaleX: transform.scaleX * sx,
        scaleY: transform.scaleY * sy,
      ),
    );
  }

  /// 设置颜色
  CharElement setColor(String color) {
    return copyWith(
      style: style.copyWith(color: color),
    );
  }

  /// 设置不透明度
  CharElement setOpacity(double opacity) {
    return copyWith(
      style: style.copyWith(opacity: opacity),
    );
  }

  /// 将字符元素转换为JSON数据
  Map<String, dynamic> toJson() {
    return {
      'charId': charId,
      'position': position.toJson(),
      'transform': transform.toJson(),
      'style': style.toJson(),
    };
  }
}

/// 字符位置
class CharPosition extends Equatable {
  /// X轴偏移量
  final double offsetX;

  /// Y轴偏移量
  final double offsetY;

  const CharPosition({
    required this.offsetX,
    required this.offsetY,
  });

  /// 从JSON数据创建位置
  factory CharPosition.fromJson(Map<String, dynamic> json) {
    return CharPosition(
      offsetX: (json['offsetX'] as num).toDouble(),
      offsetY: (json['offsetY'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [offsetX, offsetY];

  /// 创建一个带有更新属性的新实例
  CharPosition copyWith({
    double? offsetX,
    double? offsetY,
  }) {
    return CharPosition(
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
    );
  }

  /// 将位置转换为JSON数据
  Map<String, dynamic> toJson() {
    return {
      'offsetX': offsetX,
      'offsetY': offsetY,
    };
  }
}

/// 字符样式
class CharStyle extends Equatable {
  /// 颜色
  final String? color;

  /// 不透明度
  final double opacity;

  const CharStyle({
    this.color = '#000000',
    this.opacity = 1.0,
  });

  /// 从JSON数据创建样式
  factory CharStyle.fromJson(Map<String, dynamic> json) {
    return CharStyle(
      color: json['color'] as String?,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [color, opacity];

  /// 创建一个带有更新属性的新实例
  CharStyle copyWith({
    String? color,
    double? opacity,
  }) {
    return CharStyle(
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
    );
  }

  /// 将样式转换为JSON数据
  Map<String, dynamic> toJson() {
    return {
      'color': color,
      'opacity': opacity,
    };
  }
}

/// 字符变换
class CharTransform extends Equatable {
  /// X轴缩放
  final double scaleX;

  /// Y轴缩放
  final double scaleY;

  /// 旋转角度
  final double rotation;

  const CharTransform({
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    this.rotation = 0.0,
  });

  /// 从JSON数据创建变换
  factory CharTransform.fromJson(Map<String, dynamic> json) {
    return CharTransform(
      scaleX: (json['scaleX'] as num?)?.toDouble() ?? 1.0,
      scaleY: (json['scaleY'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [scaleX, scaleY, rotation];

  /// 创建一个带有更新属性的新实例
  CharTransform copyWith({
    double? scaleX,
    double? scaleY,
    double? rotation,
  }) {
    return CharTransform(
      scaleX: scaleX ?? this.scaleX,
      scaleY: scaleY ?? this.scaleY,
      rotation: rotation ?? this.rotation,
    );
  }

  /// 将变换转换为JSON数据
  Map<String, dynamic> toJson() {
    return {
      'scaleX': scaleX,
      'scaleY': scaleY,
      'rotation': rotation,
    };
  }
}
