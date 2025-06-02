// filepath: lib/canvas/rendering/rendering_engine.dart

import 'package:flutter/material.dart';

import '../compatibility/canvas_state_adapter.dart';
import '../core/canvas_state_manager.dart';
import '../core/interfaces/element_data.dart';
import 'element_renderer_factory.dart';

/// 渲染上下文
///
/// 包含渲染元素所需的上下文信息，例如选择状态、主题色等
class RenderingContext {
  /// 选择高亮颜色
  final Color selectionColor;

  /// 当前选中的元素ID集合
  final Set<String> selectedElements;

  /// 构造函数
  const RenderingContext({
    required this.selectionColor,
    required this.selectedElements,
  });

  /// 检查元素是否被选中
  bool isSelected(String elementId) {
    return selectedElements.contains(elementId);
  }
}

/// 渲染引擎 - 负责高效渲染画布元素
class RenderingEngine {
  final dynamic stateManager;
  final ElementRendererFactory _rendererFactory = ElementRendererFactory();

  RenderingEngine({required this.stateManager}) {
    assert(
        stateManager is CanvasStateManager ||
            stateManager is CanvasStateManagerAdapter,
        'stateManager must be either CanvasStateManager or CanvasStateManagerAdapter');
  }

  /// 渲染所有元素到指定的画布
  void renderElements(Canvas canvas, Size size) {
    // 获取需要渲染的元素
    final allElements = stateManager.elementState.sortedElements;

    // 筛选可见元素（考虑图层可见性）
    final visibleElements = allElements.where((element) {
      // 元素本身必须可见
      if (!element.visible) return false;

      // 元素所在图层必须可见
      final layerId = element.layerId;
      if (stateManager is CanvasStateManager) {
        final layer = stateManager.layerState.getLayerById(layerId);
        return layer != null && layer.visible;
      } else if (stateManager is CanvasStateManagerAdapter) {
        // 适配器可能有不同的处理方式
        return stateManager.isElementVisible(element.id);
      }
      return true;
    }).toList();

    // 清空画布
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 渲染每个可见元素
    for (final element in visibleElements) {
      if (element.isHidden) continue;

      _renderElement(canvas, size, element);
    } // 渲染选择框
    _renderSelectionBoxes(canvas, size);
  }

  void _applyElementTransform(Canvas canvas, ElementData element) {
    // 移动到元素位置
    canvas.translate(element.bounds.left, element.bounds.top);

    // 应用旋转
    if (element.rotation != 0) {
      final center =
          Offset(element.bounds.width / 2, element.bounds.height / 2);
      canvas.translate(center.dx, center.dy);
      canvas.rotate(element.rotation);
      canvas.translate(-center.dx, -center.dy);
    }

    // 应用透明度
    if (element.opacity < 1.0) {
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, element.bounds.width, element.bounds.height),
        Paint()..color = Color.fromRGBO(255, 255, 255, element.opacity),
      );
    }
  }

  void _renderControlPoints(Canvas canvas, Rect bounds) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    const pointSize = 6.0;
    const halfPoint = pointSize / 2;

    // 8个控制点位置
    final points = [
      // 四角
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
      // 四边中点
      Offset(bounds.center.dx, bounds.top),
      Offset(bounds.center.dx, bounds.bottom),
      Offset(bounds.left, bounds.center.dy),
      Offset(bounds.right, bounds.center.dy),
    ];

    for (final point in points) {
      canvas.drawRect(
        Rect.fromLTWH(
          point.dx - halfPoint,
          point.dy - halfPoint,
          pointSize,
          pointSize,
        ),
        paint,
      );
    }
  }

  void _renderElement(Canvas canvas, Size size, ElementData element) {
    canvas.save();

    try {
      // 应用元素变换
      _applyElementTransform(canvas, element);

      // 创建元素渲染器
      final renderer = _rendererFactory.createRenderer(element);

      // 计算元素渲染大小
      final elementSize = Size(element.bounds.width, element.bounds.height);

      // 渲染元素
      renderer.paint(canvas, elementSize);
    } finally {
      canvas.restore();
    }
  }

  void _renderSelectionBox(Canvas canvas, ElementData element) {
    final bounds = element.bounds;

    // 选择框样式
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 绘制选择框
    canvas.drawRect(bounds, paint);

    // 绘制控制点
    _renderControlPoints(canvas, bounds);
  }

  void _renderSelectionBoxes(Canvas canvas, Size size) {
    final selectedElementIds = stateManager.selectedElements;

    for (final elementId in selectedElementIds) {
      // Find the element data by its ID from the elements map
      final element = stateManager.elements[elementId];
      if (element != null) {
        _renderSelectionBox(canvas, element);
      }
    }
  }
}
