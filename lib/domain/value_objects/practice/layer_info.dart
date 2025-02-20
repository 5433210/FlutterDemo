import 'element_info.dart';

class LayerInfo {
  final int index;
  final String name;
  final String type;  // background/content
  final bool visible;
  final bool locked;
  final double opacity;
  final List<ElementInfo> elements;

  LayerInfo({
    required this.index,
    required this.name,
    required this.type,
    this.visible = true,
    this.locked = false,
    this.opacity = 1.0,
    this.elements = const [],
  }) {
    if (opacity < 0 || opacity > 1) {
      throw ArgumentError('Opacity must be between 0 and 1');
    }
    if (!['background', 'content'].contains(type)) {
      throw ArgumentError('Type must be either background or content');
    }
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'name': name,
    'type': type,
    'visible': visible,
    'locked': locked,
    'opacity': opacity,
    'elements': elements.map((e) => e.toJson()).toList(),
  };

  factory LayerInfo.fromJson(Map<String, dynamic> json) => LayerInfo(
    index: json['index'] as int,
    name: json['name'] as String,
    type: json['type'] as String,
    visible: json['visible'] as bool? ?? true,
    locked: json['locked'] as bool? ?? false,
    opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    elements: (json['elements'] as List?)
        ?.map((e) => ElementInfo.fromJson(e as Map<String, dynamic>))
        .toList() ?? const [],
  );
}
