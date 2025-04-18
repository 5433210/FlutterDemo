import 'package:flutter/material.dart';

/// 元素操作类
/// 包含元素操作相关的方法（添加、删除、复制等）
class ElementOperations {
  /// 添加文本元素
  static Map<String, dynamic> createTextElement({
    required String layerId,
    double x = 100.0,
    double y = 100.0,
    double width = 200.0,
    double height = 50.0,
  }) {
    final newElementId = 'text_${DateTime.now().millisecondsSinceEpoch}';
    
    return {
      'id': newElementId,
      'type': 'text',
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': 0.0,
      'layerId': layerId,
      'text': '双击编辑文本',
      'fontSize': 16.0,
      'fontColor': '#000000',
      'textAlign': 'left',
    };
  }

  /// 添加图片元素
  static Map<String, dynamic> createImageElement({
    required String layerId,
    required String imageUrl,
    double x = 100.0,
    double y = 100.0,
    double width = 200.0,
    double height = 200.0,
  }) {
    final newElementId = 'image_${DateTime.now().millisecondsSinceEpoch}';
    
    return {
      'id': newElementId,
      'type': 'image',
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': 0.0,
      'layerId': layerId,
      'imageUrl': imageUrl,
      'opacity': 1.0,
    };
  }

  /// 添加集字元素
  static Map<String, dynamic> createCollectionElement({
    required String layerId,
    required String characters,
    double x = 100.0,
    double y = 100.0,
    double width = 300.0,
    double height = 300.0,
  }) {
    final newElementId = 'collection_${DateTime.now().millisecondsSinceEpoch}';
    
    return {
      'id': newElementId,
      'type': 'collection',
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': 0.0,
      'layerId': layerId,
      'characters': characters,
      'direction': 'horizontal',
      'spacing': 10.0,
    };
  }

  /// 创建组合元素
  static Map<String, dynamic> createGroupElement({
    required List<Map<String, dynamic>> elements,
  }) {
    if (elements.isEmpty) {
      throw ArgumentError('Cannot create a group with no elements');
    }

    final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    
    // 计算组合的边界
    final minX = elements
        .map((e) => (e['x'] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a < b ? a : b);
    final minY = elements
        .map((e) => (e['y'] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a < b ? a : b);
    final maxX = elements
        .map((e) => ((e['x'] as num?)?.toDouble() ?? 0.0) + ((e['width'] as num?)?.toDouble() ?? 0.0))
        .reduce((a, b) => a > b ? a : b);
    final maxY = elements
        .map((e) => ((e['y'] as num?)?.toDouble() ?? 0.0) + ((e['height'] as num?)?.toDouble() ?? 0.0))
        .reduce((a, b) => a > b ? a : b);
    
    // 创建组合元素
    return {
      'id': groupId,
      'type': 'group',
      'x': minX,
      'y': minY,
      'width': maxX - minX,
      'height': maxY - minY,
      'rotation': 0.0,
      'layerId': elements.first['layerId'],
      'children': elements.map((element) {
        // 转换为相对坐标
        return {
          ...element,
          'relativeX': (element['x'] as num?)?.toDouble() ?? 0.0 - minX,
          'relativeY': (element['y'] as num?)?.toDouble() ?? 0.0 - minY,
        };
      }).toList(),
    };
  }

  /// 根据ID查找元素
  static Map<String, dynamic>? findElementById(
    List<Map<String, dynamic>> elements,
    String id,
  ) {
    for (var element in elements) {
      if (element['id'] == id) {
        return element;
      }

      // 检查组合内部
      if (element['type'] == 'group') {
        final children = element['children'] as List<dynamic>? ?? [];
        for (var child in children) {
          final childMap = child as Map<String, dynamic>;
          if (childMap['id'] == id) {
            return childMap;
          }
        }
      }
    }

    return null;
  }

  /// 更新元素属性
  static void updateElementProperties(
    List<Map<String, dynamic>> elements,
    String id,
    Map<String, dynamic> properties,
  ) {
    for (var i = 0; i < elements.length; i++) {
      if (elements[i]['id'] == id) {
        // 更新属性
        elements[i] = {...elements[i], ...properties};
        break;
      }

      // 检查组合内部
      if (elements[i]['type'] == 'group') {
        final children = elements[i]['children'] as List<dynamic>? ?? [];
        for (var j = 0; j < children.length; j++) {
          if ((children[j] as Map<String, dynamic>)['id'] == id) {
            children[j] = {
              ...children[j] as Map<String, dynamic>,
              ...properties
            };
            break;
          }
        }
      }
    }
  }

  /// 删除元素
  static void deleteElements(
    List<Map<String, dynamic>> elements,
    List<String> elementIds,
  ) {
    // 移除匹配ID的元素
    elements.removeWhere((element) => elementIds.contains(element['id']));
    
    // 检查组合内的元素
    for (var element in elements) {
      if (element['type'] == 'group') {
        final children = element['children'] as List<dynamic>? ?? [];
        children.removeWhere((child) => 
          elementIds.contains((child as Map<String, dynamic>)['id']));
      }
    }
  }

  /// 取消组合
  static List<Map<String, dynamic>> ungroupElement(
    List<Map<String, dynamic>> elements,
    String groupId,
  ) {
    // 找出要取消组合的组
    final groupIndex = elements.indexWhere((e) => e['id'] == groupId);
    if (groupIndex < 0) return [];

    final group = elements[groupIndex];
    final children = group['children'] as List<dynamic>? ?? [];

    // 计算基准位置
    final baseX = (group['x'] as num?)?.toDouble() ?? 0.0;
    final baseY = (group['y'] as num?)?.toDouble() ?? 0.0;

    // 将子元素恢复为绝对坐标
    final ungroupedElements = children.map((child) {
      final element = child as Map<String, dynamic>;
      final relativeX = (element['relativeX'] as num?)?.toDouble() ?? 0.0;
      final relativeY = (element['relativeY'] as num?)?.toDouble() ?? 0.0;

      return {
        ...element,
        'x': baseX + relativeX,
        'y': baseY + relativeY,
      };
    }).toList().cast<Map<String, dynamic>>();

    // 移除组
    elements.removeAt(groupIndex);
    
    // 添加子元素
    elements.addAll(ungroupedElements);
    
    // 返回取消组合后的元素ID列表
    return ungroupedElements;
  }
}
