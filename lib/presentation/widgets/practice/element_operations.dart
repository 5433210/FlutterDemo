import 'dart:math';

import 'package:flutter/material.dart';

/// 元素操作工具类
class ElementOperations {
  /// 计算元素的边界框
  static Map<String, double> calculateBoundingBox(
      Map<String, dynamic> element) {
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();

    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'right': x + width,
      'bottom': y + height,
    };
  }

  /// 根据控制点和移动方向计算新的几何属性
  static Map<String, dynamic> calculateResizedGeometry(
      Map<String, dynamic> element, int controlPointIndex, Offset delta) {
    final corners = getRotatedCorners(element);
    final center = Rect.fromPoints(corners[0], corners[2]).center;
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
    final rotationInRadians = rotation * pi / 180;

    // 根据不同的控制点计算新的尺寸和位置
    switch (controlPointIndex) {
      case 0: // 左上角
        return _resizeFromCorner(
            element, corners, 0, 2, delta, rotationInRadians);
      case 2: // 右上角
        return _resizeFromCorner(
            element, corners, 1, 3, delta, rotationInRadians);
      case 4: // 右下角
        return _resizeFromCorner(
            element, corners, 2, 0, delta, rotationInRadians);
      case 6: // 左下角
        return _resizeFromCorner(
            element, corners, 3, 1, delta, rotationInRadians);
      case 1: // 上中
        return _resizeFromEdge(
            element, corners, 0, 1, 2, 3, delta, rotationInRadians);
      case 3: // 右中
        return _resizeFromEdge(
            element, corners, 1, 2, 0, 3, delta, rotationInRadians);
      case 5: // 下中
        return _resizeFromEdge(
            element, corners, 2, 3, 0, 1, delta, rotationInRadians);
      case 7: // 左中
        return _resizeFromEdge(
            element, corners, 0, 3, 1, 2, delta, rotationInRadians);
      default:
        return element;
    }
  }

  /// 计算元素旋转角度
  static double calculateRotation(
      Map<String, dynamic> element, Offset startPoint, Offset currentPoint) {
    final rect = getElementRect(element);
    final center = rect.center;

    // 计算起始向量和当前向量
    final startVector =
        Offset(startPoint.dx - center.dx, startPoint.dy - center.dy);
    final currentVector =
        Offset(currentPoint.dx - center.dx, currentPoint.dy - center.dy);

    // 计算两个向量的夹角
    final startAngle = atan2(startVector.dy, startVector.dx);
    final currentAngle = atan2(currentVector.dy, currentVector.dx);

    // 计算角度差（弧度）
    var angleDiff = currentAngle - startAngle;

    // 转换为角度
    var degrees = angleDiff * 180 / pi;

    // 当前元素的旋转角度
    final currentRotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;

    // 计算新的旋转角度
    var newRotation = currentRotation + degrees;

    // 规范化角度到0-360范围
    while (newRotation < 0) {
      newRotation += 360;
    }
    while (newRotation >= 360) {
      newRotation -= 360;
    }

    return newRotation;
  }

  /// 复制元素
  static Map<String, dynamic> copyElement(Map<String, dynamic> element,
      {Offset? offset}) {
    final copy = Map<String, dynamic>.from(element);

    // 创建新ID
    copy['id'] = '${element['type']}_${DateTime.now().millisecondsSinceEpoch}';

    // 如果提供了位置偏移，则应用偏移
    if (offset != null) {
      copy['x'] = (element['x'] as num).toDouble() + offset.dx;
      copy['y'] = (element['y'] as num).toDouble() + offset.dy;
    }

    // 如果是组合元素，递归复制子元素
    if (element['type'] == 'group') {
      final children = element['children'] as List<dynamic>;
      final copiedChildren = children.map((child) {
        return copyElement(child as Map<String, dynamic>);
      }).toList();
      copy['children'] = copiedChildren;
    }

    return copy;
  }

  /// 创建集字元素
  static Map<String, dynamic> createCollectionElement(
      String characters, Offset position) {
    final id = 'collection_${DateTime.now().millisecondsSinceEpoch}';

    return {
      'id': id,
      'type': 'collection',
      'x': position.dx,
      'y': position.dy,
      'width': 400.0,
      'height': 200.0,
      'rotation': 0.0,
      'opacity': 1.0,
      'layerId': 'default',
      'isLocked': false,
      'isHidden': false,
      'name': '集字元素',
      'characters': characters,
      'fontSize': 36.0,
      'fontColor': '#000000',
      'backgroundColor': '#FFFFFF',
      'direction': 'horizontal',
      'flowDirection': 'vertical',
      'horizontalSpacing': 10.0,
      'verticalSpacing': 10.0,
      'padding': 10.0,
      'alignment': 'left',
      'charStyle': 'default',
    };
  }

  /// 创建组合元素
  static Map<String, dynamic> createGroupElement(
      List<Map<String, dynamic>> children) {
    final id = 'group_${DateTime.now().millisecondsSinceEpoch}';

    // 计算包含所有子元素的外接矩形
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final child in children) {
      final x = (child['x'] as num).toDouble();
      final y = (child['y'] as num).toDouble();
      final width = (child['width'] as num).toDouble();
      final height = (child['height'] as num).toDouble();
      final rotation = (child['rotation'] as num?)?.toDouble() ?? 0.0;

      // 旋转校正暂时不处理，简单计算包围盒
      minX = min(minX, x);
      minY = min(minY, y);
      maxX = max(maxX, x + width);
      maxY = max(maxY, y + height);
    }

    final x = minX;
    final y = minY;
    final width = maxX - minX;
    final height = maxY - minY;

    // 调整子元素相对坐标（相对于组合元素左上角）
    final adjustedChildren = children.map((child) {
      final childX = (child['x'] as num).toDouble();
      final childY = (child['y'] as num).toDouble();

      return {
        ...child,
        'x': childX - x,
        'y': childY - y,
      };
    }).toList();

    return {
      'id': id,
      'type': 'group',
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': 0.0,
      'opacity': 1.0,
      'layerId': children.first['layerId'],
      'isLocked': false,
      'isHidden': false,
      'name': '组合元素',
      'children': adjustedChildren,
    };
  }

  /// 创建图片元素
  static Map<String, dynamic> createImageElement(
      String imageUrl, Offset position) {
    final id = 'image_${DateTime.now().millisecondsSinceEpoch}';

    return {
      'id': id,
      'type': 'image',
      'x': position.dx,
      'y': position.dy,
      'width': 200.0,
      'height': 200.0,
      'rotation': 0.0,
      'opacity': 1.0,
      'layerId': 'default',
      'isLocked': false,
      'isHidden': false,
      'name': '图片元素',
      'imageUrl': imageUrl,
      'originalWidth': 200.0,
      'originalHeight': 200.0,
      'cropRect': null,
      'flipHorizontal': false,
      'flipVertical': false,
      'fit': 'contain',
      'filter': 'none',
    };
  }

  /// 创建文本元素
  static Map<String, dynamic> createTextElement(String text, Offset position) {
    final id = 'text_${DateTime.now().millisecondsSinceEpoch}';

    return {
      'id': id,
      'type': 'text',
      'x': position.dx,
      'y': position.dy,
      'width': 200.0,
      'height': 100.0,
      'rotation': 0.0,
      'opacity': 1.0,
      'layerId': 'default',
      'isLocked': false,
      'isHidden': false,
      'name': '文本元素',
      'text': text,
      'fontSize': 16.0,
      'fontFamily': 'Arial',
      'fontColor': '#000000',
      'backgroundColor': 'transparent',
      'alignment': 'left',
      'lineHeight': 1.2,
      'letterSpacing': 0.0,
      'fontWeight': 'normal',
      'fontStyle': 'normal',
      'textDecoration': 'none',
    };
  }

  /// 查找元素
  static Map<String, dynamic>? findElementById(
      List<Map<String, dynamic>> elements, String id) {
    for (final element in elements) {
      if (element['id'] == id) {
        return element;
      }

      // 检查组合元素
      if (element['type'] == 'group') {
        final children = element['children'] as List<dynamic>?;
        if (children != null) {
          for (final child in children) {
            final childMap = child as Map<String, dynamic>;
            if (childMap['id'] == id) {
              return childMap;
            }
          }
        }
      }
    }
    return null;
  }

  /// 计算元素变换的控制点位置
  static List<Offset> getControlPoints(Map<String, dynamic> element) {
    final corners = getRotatedCorners(element);

    // 返回8个控制点的位置（四个角点和四个中点）
    return [
      corners[0], // 左上
      Offset((corners[0].dx + corners[1].dx) / 2,
          (corners[0].dy + corners[1].dy) / 2), // 上中
      corners[1], // 右上
      Offset((corners[1].dx + corners[2].dx) / 2,
          (corners[1].dy + corners[2].dy) / 2), // 右中
      corners[2], // 右下
      Offset((corners[2].dx + corners[3].dx) / 2,
          (corners[2].dy + corners[3].dy) / 2), // 下中
      corners[3], // 左下
      Offset((corners[3].dx + corners[0].dx) / 2,
          (corners[3].dy + corners[0].dy) / 2), // 左中
    ];
  }

  /// 获取元素的外接矩形
  static Rect getElementRect(Map<String, dynamic> element) {
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();

    return Rect.fromLTWH(x, y, width, height);
  }

  /// 计算元素的旋转后边界
  static List<Offset> getRotatedCorners(Map<String, dynamic> element) {
    final rect = getElementRect(element);
    final center = rect.center;
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
    final rotationInRadians = rotation * pi / 180;

    // 计算矩形的四个角点
    final topLeft = rect.topLeft;
    final topRight = rect.topRight;
    final bottomLeft = rect.bottomLeft;
    final bottomRight = rect.bottomRight;

    // 应用旋转变换
    final rotatedTopLeft = _rotatePoint(topLeft, center, rotationInRadians);
    final rotatedTopRight = _rotatePoint(topRight, center, rotationInRadians);
    final rotatedBottomLeft =
        _rotatePoint(bottomLeft, center, rotationInRadians);
    final rotatedBottomRight =
        _rotatePoint(bottomRight, center, rotationInRadians);

    return [
      rotatedTopLeft,
      rotatedTopRight,
      rotatedBottomRight,
      rotatedBottomLeft,
    ];
  }

  /// 计算旋转控制点位置
  static Offset getRotationControlPoint(Map<String, dynamic> element) {
    final corners = getRotatedCorners(element);
    final topMiddle = Offset(
      (corners[0].dx + corners[1].dx) / 2,
      (corners[0].dy + corners[1].dy) / 2,
    );

    // 旋转控制点位于上边中点上方30像素处
    final center = Rect.fromPoints(corners[0], corners[2]).center;
    final direction =
        Offset(topMiddle.dx - center.dx, topMiddle.dy - center.dy);
    final normalized = direction / direction.distance;

    return Offset(
      topMiddle.dx + normalized.dx * 30,
      topMiddle.dy + normalized.dy * 30,
    );
  }

  /// 检查点是否在元素内
  static bool isPointInElement(Offset point, Map<String, dynamic> element,
      {bool considerRotation = true}) {
    final rect = getElementRect(element);
    final center = rect.center;
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;

    if (!considerRotation || rotation.abs() < 0.001) {
      // 如果不考虑旋转或旋转角度接近0，直接使用矩形检测
      return rect.contains(point);
    }

    // 将点变换到元素坐标系中
    final rotationInRadians = rotation * pi / 180;
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;

    // 反向旋转变换
    final rotatedDx =
        dx * cos(-rotationInRadians) - dy * sin(-rotationInRadians);
    final rotatedDy =
        dx * sin(-rotationInRadians) + dy * cos(-rotationInRadians);

    // 检查变换后的点是否在矩形内
    return Rect.fromCenter(
      center: Offset.zero,
      width: rect.width,
      height: rect.height,
    ).contains(Offset(rotatedDx, rotatedDy));
  }

  /// 解组元素
  static List<Map<String, dynamic>> ungroupElement(
      Map<String, dynamic> groupElement) {
    if (groupElement['type'] != 'group') {
      throw ArgumentError('不是组合元素');
    }

    final content = groupElement['content'] as Map<String, dynamic>;
    final children = content['children'] as List<dynamic>;
    final x = (groupElement['x'] as num).toDouble();
    final y = (groupElement['y'] as num).toDouble();

    // 计算子元素的绝对位置
    return children.map<Map<String, dynamic>>((child) {
      final result = Map<String, dynamic>.from(child as Map<String, dynamic>);
      result['x'] = (child['x'] as num).toDouble() + x;
      result['y'] = (child['y'] as num).toDouble() + y;
      result['layerId'] = groupElement['layerId'];

      // 生成新的ID，避免ID冲突
      result['id'] =
          '${child['type']}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

      return result;
    }).toList();
  }

  /// 更新元素属性
  static Map<String, dynamic> updateElementProperties(
      Map<String, dynamic> element, Map<String, dynamic> properties) {
    return {
      ...element,
      ...properties,
    };
  }

  /// 从角点调整大小
  static Map<String, dynamic> _resizeFromCorner(
      Map<String, dynamic> element,
      List<Offset> corners,
      int movingCornerIndex,
      int oppositeCornerIndex,
      Offset delta,
      double rotationInRadians) {
    // 反向旋转变换delta
    final rotatedDelta = Offset(
      delta.dx * cos(-rotationInRadians) - delta.dy * sin(-rotationInRadians),
      delta.dx * sin(-rotationInRadians) + delta.dy * cos(-rotationInRadians),
    );

    // 移动的角点
    final movingCorner = corners[movingCornerIndex];
    // 对角点（不动）
    final oppositeCorner = corners[oppositeCornerIndex];

    // 计算新的角点位置
    final newMovingCorner = Offset(
      movingCorner.dx + delta.dx,
      movingCorner.dy + delta.dy,
    );

    // 计算新的矩形（未旋转前）
    final oldRect = Rect.fromPoints(
      _rotatePoint(corners[0], corners[2], -rotationInRadians),
      _rotatePoint(corners[2], corners[0], -rotationInRadians),
    );

    // 计算新的未旋转矩形
    Rect newRect;
    switch (movingCornerIndex) {
      case 0: // 左上角
        newRect = Rect.fromLTRB(
          oldRect.left + rotatedDelta.dx,
          oldRect.top + rotatedDelta.dy,
          oldRect.right,
          oldRect.bottom,
        );
        break;
      case 1: // 右上角
        newRect = Rect.fromLTRB(
          oldRect.left,
          oldRect.top + rotatedDelta.dy,
          oldRect.right + rotatedDelta.dx,
          oldRect.bottom,
        );
        break;
      case 2: // 右下角
        newRect = Rect.fromLTRB(
          oldRect.left,
          oldRect.top,
          oldRect.right + rotatedDelta.dx,
          oldRect.bottom + rotatedDelta.dy,
        );
        break;
      case 3: // 左下角
        newRect = Rect.fromLTRB(
          oldRect.left + rotatedDelta.dx,
          oldRect.top,
          oldRect.right,
          oldRect.bottom + rotatedDelta.dy,
        );
        break;
      default:
        newRect = oldRect;
    }

    // 避免负宽高
    if (newRect.width <= 10 || newRect.height <= 10) {
      return element;
    }

    // 计算新的中心点
    final newCenter = newRect.center;

    // 计算旋转后的中心点
    final rotatedCenter =
        _rotatePoint(newCenter, oldRect.center, rotationInRadians);

    return {
      ...element,
      'x': rotatedCenter.dx - newRect.width / 2,
      'y': rotatedCenter.dy - newRect.height / 2,
      'width': newRect.width,
      'height': newRect.height,
    };
  }

  /// 从边中点调整大小
  static Map<String, dynamic> _resizeFromEdge(
      Map<String, dynamic> element,
      List<Offset> corners,
      int edge1Index,
      int edge2Index,
      int opposite1Index,
      int opposite2Index,
      Offset delta,
      double rotationInRadians) {
    // 反向旋转变换delta
    final rotatedDelta = Offset(
      delta.dx * cos(-rotationInRadians) - delta.dy * sin(-rotationInRadians),
      delta.dx * sin(-rotationInRadians) + delta.dy * cos(-rotationInRadians),
    );

    // 计算新的未旋转矩形
    final oldRect = Rect.fromPoints(
      _rotatePoint(corners[0], corners[2], -rotationInRadians),
      _rotatePoint(corners[2], corners[0], -rotationInRadians),
    );

    Rect newRect;

    // 根据不同边调整矩形
    if (edge1Index == 0 && edge2Index == 1) {
      // 上边
      newRect = Rect.fromLTRB(
        oldRect.left,
        oldRect.top + rotatedDelta.dy,
        oldRect.right,
        oldRect.bottom,
      );
    } else if (edge1Index == 1 && edge2Index == 2) {
      // 右边
      newRect = Rect.fromLTRB(
        oldRect.left,
        oldRect.top,
        oldRect.right + rotatedDelta.dx,
        oldRect.bottom,
      );
    } else if (edge1Index == 2 && edge2Index == 3) {
      // 下边
      newRect = Rect.fromLTRB(
        oldRect.left,
        oldRect.top,
        oldRect.right,
        oldRect.bottom + rotatedDelta.dy,
      );
    } else {
      // 左边
      newRect = Rect.fromLTRB(
        oldRect.left + rotatedDelta.dx,
        oldRect.top,
        oldRect.right,
        oldRect.bottom,
      );
    }

    // 避免负宽高
    if (newRect.width <= 10 || newRect.height <= 10) {
      return element;
    }

    // 计算新的中心点
    final newCenter = newRect.center;

    // 计算旋转后的中心点
    final rotatedCenter =
        _rotatePoint(newCenter, oldRect.center, rotationInRadians);

    return {
      ...element,
      'x': rotatedCenter.dx - newRect.width / 2,
      'y': rotatedCenter.dy - newRect.height / 2,
      'width': newRect.width,
      'height': newRect.height,
    };
  }

  /// 旋转一个点
  static Offset _rotatePoint(Offset point, Offset center, double angle) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;

    final rotatedDx = dx * cos(angle) - dy * sin(angle);
    final rotatedDy = dx * sin(angle) + dy * cos(angle);

    return Offset(center.dx + rotatedDx, center.dy + rotatedDy);
  }
}
