// filepath: lib/canvas/core/interfaces/layer_data.dart

/// 图层数据接口
/// 
/// 定义画布中图层的数据结构
class LayerData {
  /// 图层唯一标识符
  final String id;
  
  /// 图层名称
  final String name;
  
  /// 图层是否可见
  final bool visible;
  
  /// 图层是否锁定
  final bool locked;
  
  /// 图层透明度 (0.0 - 1.0)
  final double opacity;
  
  /// 图层叠加模式
  final String blendMode;
  
  /// 图层自定义属性
  final Map<String, dynamic> properties;

  const LayerData({
    required this.id,
    required this.name,
    this.visible = true,
    this.locked = false,
    this.opacity = 1.0,
    this.blendMode = 'normal',
    this.properties = const {},
  });
  
  /// 创建更新后的副本
  LayerData copyWith({
    String? name,
    bool? visible,
    bool? locked,
    double? opacity,
    String? blendMode,
    Map<String, dynamic>? properties,
  }) {
    return LayerData(
      id: this.id,
      name: name ?? this.name,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      properties: properties ?? this.properties,
    );
  }
}
