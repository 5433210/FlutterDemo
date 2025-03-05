import 'package:equatable/equatable.dart';

import 'practice_element.dart';

/// 字帖图层
class PracticeLayer extends Equatable {
  /// 图层序号
  final int index;

  /// 图层名称
  final String name;

  /// 图层类型：'background'或'content'
  final String type;

  /// 图层是否可见
  final bool visible;

  /// 图层是否锁定
  final bool locked;

  /// 图层不透明度，范围0-1
  final double opacity;

  /// 图层中的元素列表
  final List<PracticeElement> elements;

  const PracticeLayer({
    required this.index,
    required this.name,
    required this.type,
    this.visible = true,
    this.locked = false,
    this.opacity = 1.0,
    this.elements = const [],
  });

  /// 创建背景图层
  factory PracticeLayer.background({
    int index = 0,
    String name = '背景',
    List<PracticeElement> elements = const [],
  }) {
    return PracticeLayer(
      index: index,
      name: name,
      type: 'background',
      elements: elements,
    );
  }

  /// 创建内容图层
  factory PracticeLayer.content({
    int index = 1,
    String name = '内容',
    List<PracticeElement> elements = const [],
  }) {
    return PracticeLayer(
      index: index,
      name: name,
      type: 'content',
      elements: elements,
    );
  }

  /// 从JSON数据创建图层
  factory PracticeLayer.fromJson(Map<String, dynamic> json) {
    return PracticeLayer(
      index: json['index'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      elements: json['elements'] != null
          ? List<PracticeElement>.from(
              (json['elements'] as List).map(
                (x) => PracticeElement.fromJson(x as Map<String, dynamic>),
              ),
            )
          : [],
    );
  }

  @override
  List<Object?> get props => [
        index,
        name,
        type,
        visible,
        locked,
        opacity,
        elements,
      ];

  /// 添加元素
  PracticeLayer addElement(PracticeElement element) {
    return copyWith(elements: [...elements, element]);
  }

  /// 创建一个带有更新属性的新实例
  PracticeLayer copyWith({
    int? index,
    String? name,
    String? type,
    bool? visible,
    bool? locked,
    double? opacity,
    List<PracticeElement>? elements,
  }) {
    return PracticeLayer(
      index: index ?? this.index,
      name: name ?? this.name,
      type: type ?? this.type,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      opacity: opacity ?? this.opacity,
      elements: elements ?? this.elements,
    );
  }

  /// 移除元素
  PracticeLayer removeElement(String elementId) {
    return copyWith(
      elements: elements.where((e) => e.id != elementId).toList(),
    );
  }

  /// 切换锁定状态
  PracticeLayer toggleLock() {
    return copyWith(locked: !locked);
  }

  /// 切换可见性
  PracticeLayer toggleVisibility() {
    return copyWith(visible: !visible);
  }

  /// 将图层转换为JSON数据
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'name': name,
      'type': type,
      'visible': visible,
      'locked': locked,
      'opacity': opacity,
      'elements': elements.map((element) => element.toJson()).toList(),
    };
  }

  /// 更新元素
  PracticeLayer updateElement(PracticeElement element) {
    return copyWith(
      elements: elements.map((e) => e.id == element.id ? element : e).toList(),
    );
  }
}
