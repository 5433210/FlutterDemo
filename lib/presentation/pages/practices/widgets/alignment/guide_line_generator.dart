import 'package:flutter/material.dart';

import 'alignment_types.dart';

/// 参考线生成器
///
/// 负责为每个元素计算出所有可能的对齐参考线。
/// 算法的核心思想是：每个矩形元素都有6条潜在的参考线：
/// 3条水平线（上边、中心、下边）和3条垂直线（左边、中心、右边）
class GuideLineGenerator {
  /// 为元素生成所有参考线
  ///
  /// 参数:
  /// - [element]: 元素数据，包含id, x, y, width, height等信息
  ///
  /// 返回:
  /// - 包含6条参考线的列表（3条水平 + 3条垂直）
  ///
  /// 算法逻辑：
  /// 1. 水平参考线计算：
  ///    - 上边线 = 元素的y坐标
  ///    - 水平中心线 = 元素的y坐标 + 元素高度的一半
  ///    - 下边线 = 元素的y坐标 + 元素高度
  /// 2. 垂直参考线计算：
  ///    - 左边线 = 元素的x坐标
  ///    - 垂直中心线 = 元素的x坐标 + 元素宽度的一半
  ///    - 右边线 = 元素的x坐标 + 元素宽度
  static List<GuideLine> generateGuideLines(Map<String, dynamic> element) {
    final id = element['id'] as String;
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();

    final bounds = Rect.fromLTWH(x, y, width, height);

    return [
      // 横向参考线（水平线）
      GuideLine(
        elementId: id,
        type: GuideLineType.top,
        orientation: GuideLineOrientation.horizontal,
        position: y,
        elementBounds: bounds,
      ),
      GuideLine(
        elementId: id,
        type: GuideLineType.horizontalCenter,
        orientation: GuideLineOrientation.horizontal,
        position: y + height / 2,
        elementBounds: bounds,
      ),
      GuideLine(
        elementId: id,
        type: GuideLineType.bottom,
        orientation: GuideLineOrientation.horizontal,
        position: y + height,
        elementBounds: bounds,
      ),

      // 纵向参考线（垂直线）
      GuideLine(
        elementId: id,
        type: GuideLineType.left,
        orientation: GuideLineOrientation.vertical,
        position: x,
        elementBounds: bounds,
      ),
      GuideLine(
        elementId: id,
        type: GuideLineType.verticalCenter,
        orientation: GuideLineOrientation.vertical,
        position: x + width / 2,
        elementBounds: bounds,
      ),
      GuideLine(
        elementId: id,
        type: GuideLineType.right,
        orientation: GuideLineOrientation.vertical,
        position: x + width,
        elementBounds: bounds,
      ),
    ];
  }

  /// 为多个元素批量生成参考线
  ///
  /// 参数:
  /// - [elements]: 元素列表
  ///
  /// 返回:
  /// - 所有元素的参考线列表（按元素ID分组）
  static Map<String, List<GuideLine>> generateGuidelinesForElements(
    List<Map<String, dynamic>> elements,
  ) {
    final Map<String, List<GuideLine>> result = {};

    for (final element in elements) {
      final elementId = element['id'] as String;
      result[elementId] = generateGuideLines(element);
    }

    return result;
  }

  /// 获取指定元素在指定方向上的参考线
  ///
  /// 参数:
  /// - [element]: 元素数据
  /// - [orientation]: 参考线方向
  ///
  /// 返回:
  /// - 指定方向的参考线列表
  static List<GuideLine> getGuideLinesByOrientation(
    Map<String, dynamic> element,
    GuideLineOrientation orientation,
  ) {
    final allLines = generateGuideLines(element);
    return allLines.where((line) => line.orientation == orientation).toList();
  }

  /// 获取指定类型的参考线
  ///
  /// 参数:
  /// - [element]: 元素数据
  /// - [types]: 参考线类型列表
  ///
  /// 返回:
  /// - 指定类型的参考线列表
  static List<GuideLine> getGuideLinesByTypes(
    Map<String, dynamic> element,
    List<GuideLineType> types,
  ) {
    final allLines = generateGuideLines(element);
    return allLines.where((line) => types.contains(line.type)).toList();
  }
}
