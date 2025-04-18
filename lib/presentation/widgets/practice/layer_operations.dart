import 'package:flutter/material.dart';

/// 图层操作类
/// 包含图层操作相关的方法
class LayerOperations {
  /// 创建新图层
  static Map<String, dynamic> createLayer({
    String? name,
    bool visible = true,
    bool locked = false,
    bool selected = false,
  }) {
    final layerId = 'layer_${DateTime.now().millisecondsSinceEpoch}';
    
    return {
      'id': layerId,
      'name': name ?? '新图层',
      'visible': visible,
      'locked': locked,
      'selected': selected,
    };
  }

  /// 初始化默认图层
  static List<Map<String, dynamic>> createDefaultLayers() {
    return [
      {
        'id': 'layer_bg',
        'name': '背景层',
        'visible': true,
        'locked': false,
        'selected': false,
      },
      {
        'id': 'layer_content',
        'name': '内容层',
        'visible': true,
        'locked': false,
        'selected': true,
      },
    ];
  }

  /// 选择图层
  static void selectLayer(List<Map<String, dynamic>> layers, int index) {
    for (var i = 0; i < layers.length; i++) {
      layers[i]['selected'] = i == index;
    }
  }

  /// 更改图层可见性
  static void setLayerVisibility(
    List<Map<String, dynamic>> layers,
    int index,
    bool visible,
  ) {
    if (index >= 0 && index < layers.length) {
      layers[index]['visible'] = visible;
    }
  }

  /// 更改图层锁定状态
  static void setLayerLocked(
    List<Map<String, dynamic>> layers,
    int index,
    bool locked,
  ) {
    if (index >= 0 && index < layers.length) {
      layers[index]['locked'] = locked;
    }
  }

  /// 重命名图层
  static void renameLayer(
    List<Map<String, dynamic>> layers,
    int index,
    String newName,
  ) {
    if (index >= 0 && index < layers.length) {
      layers[index]['name'] = newName;
    }
  }

  /// 删除图层
  static void deleteLayer(List<Map<String, dynamic>> layers, int index) {
    if (index >= 0 && index < layers.length) {
      layers.removeAt(index);
    }
  }

  /// 重新排序图层
  static void reorderLayers(
    List<Map<String, dynamic>> layers,
    int oldIndex,
    int newIndex,
  ) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = layers.removeAt(oldIndex);
    layers.insert(newIndex, item);
  }

  /// 显示所有图层
  static void showAllLayers(List<Map<String, dynamic>> layers) {
    for (var layer in layers) {
      layer['visible'] = true;
    }
  }

  /// 获取选中的图层
  static Map<String, dynamic>? getSelectedLayer(
    List<Map<String, dynamic>> layers,
  ) {
    for (var layer in layers) {
      if (layer['selected'] == true) {
        return layer;
      }
    }
    return null;
  }

  /// 获取默认图层ID（用于添加新元素）
  static String getDefaultLayerId(List<Map<String, dynamic>> layers) {
    // 首先尝试获取选中的图层
    final selectedLayer = getSelectedLayer(layers);
    if (selectedLayer != null) {
      return selectedLayer['id'] as String;
    }
    
    // 如果没有选中的图层，返回第一个图层的ID
    if (layers.isNotEmpty) {
      return layers.first['id'] as String;
    }
    
    // 如果没有图层，返回默认ID
    return 'default';
  }
}
