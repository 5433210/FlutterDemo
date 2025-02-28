import 'package:equatable/equatable.dart';

/// 元素的样式属性
class ElementStyle extends Equatable {
  /// 不透明度 (0-1)
  final double opacity;

  /// 是否可见
  final bool visible;

  const ElementStyle({
    this.opacity = 1.0,
    this.visible = true,
  });

  factory ElementStyle.fromJson(Map<String, dynamic> json) {
    return ElementStyle(
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      visible: json['visible'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [opacity, visible];

  ElementStyle copyWith({
    double? opacity,
    bool? visible,
  }) {
    return ElementStyle(
      opacity: opacity ?? this.opacity,
      visible: visible ?? this.visible,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opacity': opacity,
      'visible': visible,
    };
  }
}
