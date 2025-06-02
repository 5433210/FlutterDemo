// filepath: lib/canvas/rendering/element_renderer_factory.dart

import 'package:flutter/material.dart';

import '../core/canvas_state_manager.dart';
import '../core/interfaces/element_data.dart';
import 'element_renderer/collection_renderer.dart';
import 'element_renderer/image_element_renderer.dart';
import 'element_renderer/path_element_renderer.dart';
import 'element_renderer/shape_element_renderer.dart';
import 'element_renderer/text_element_renderer.dart';
import 'rendering_engine.dart';

/// 元素渲染器工厂
/// 根据元素类型创建对应的渲染器
class ElementRendererFactory {
  static final ElementRendererFactory _instance =
      ElementRendererFactory._internal();
  // 专用渲染器实例
  final Map<String, dynamic> _renderers = {};
  // 状态管理器
  CanvasStateManager? _stateManager;

  factory ElementRendererFactory() => _instance;

  ElementRendererFactory._internal();

  /// 创建元素渲染器
  CustomPainter createRenderer(ElementData elementData,
      {Map<String, dynamic>? options}) {
    // 检查状态管理器是否已初始化
    if (_stateManager == null) {
      return _PlaceholderRenderer(elementData, '渲染器工厂未初始化');
    }

    // 根据元素类型创建对应渲染器
    switch (elementData.type) {
      case 'collection':
        return CollectionRenderer(
          elementData: elementData,
          options: options,
        );
      case 'image':
        return _createImageRenderer(elementData, options);
      case 'text':
        return _createTextRenderer(elementData, options);
      case 'shape':
        return _createShapeRenderer(elementData, options);
      case 'path':
        return _createPathRenderer(elementData, options);
      default:
        return _createDefaultRenderer(elementData, options);
    }
  }

  /// 释放所有渲染器资源
  void dispose() {
    _disposeRenderers();
    _stateManager = null;
  }

  /// 初始化渲染器工厂
  void initialize(CanvasStateManager stateManager) {
    _stateManager = stateManager;

    // 清理任何现有渲染器
    _disposeRenderers();

    // 创建专用渲染器
    _renderers['text'] = TextElementRenderer(stateManager);
    _renderers['image'] = ImageElementRenderer(stateManager);
    _renderers['shape'] = ShapeElementRenderer(stateManager);
    _renderers['path'] = PathElementRenderer(stateManager);
  }

  /// 创建默认渲染器
  CustomPainter _createDefaultRenderer(
      ElementData elementData, Map<String, dynamic>? options) {
    return _PlaceholderRenderer(elementData, '未知元素类型: ${elementData.type}');
  }

  /// 创建图像渲染器
  CustomPainter _createImageRenderer(
      ElementData elementData, Map<String, dynamic>? options) {
    final imageRenderer = _renderers['image'] as ImageElementRenderer?;
    if (imageRenderer == null) {
      return _PlaceholderRenderer(elementData, '图像渲染器未初始化');
    }

    return _SpecializedRendererAdapter(
      elementData: elementData,
      renderer: imageRenderer,
      context: RenderingContext(
        selectionColor: options?['selectionColor'] as Color? ?? Colors.blue,
        selectedElements: options?['selectedElements'] as Set<String>? ?? {},
      ),
    );
  }

  /// 创建路径渲染器
  CustomPainter _createPathRenderer(
      ElementData elementData, Map<String, dynamic>? options) {
    final pathRenderer = _renderers['path'] as PathElementRenderer?;
    if (pathRenderer == null) {
      return _PlaceholderRenderer(elementData, '路径渲染器未初始化');
    }

    return _SpecializedRendererAdapter(
      elementData: elementData,
      renderer: pathRenderer,
      context: RenderingContext(
        selectionColor: options?['selectionColor'] as Color? ?? Colors.blue,
        selectedElements: options?['selectedElements'] as Set<String>? ?? {},
      ),
    );
  }

  /// 创建形状渲染器
  CustomPainter _createShapeRenderer(
      ElementData elementData, Map<String, dynamic>? options) {
    final shapeRenderer = _renderers['shape'] as ShapeElementRenderer?;
    if (shapeRenderer == null) {
      return _PlaceholderRenderer(elementData, '形状渲染器未初始化');
    }

    return _SpecializedRendererAdapter(
      elementData: elementData,
      renderer: shapeRenderer,
      context: RenderingContext(
        selectionColor: options?['selectionColor'] as Color? ?? Colors.blue,
        selectedElements: options?['selectedElements'] as Set<String>? ?? {},
      ),
    );
  }

  /// 创建文本渲染器
  CustomPainter _createTextRenderer(
      ElementData elementData, Map<String, dynamic>? options) {
    final textRenderer = _renderers['text'] as TextElementRenderer?;
    if (textRenderer == null) {
      return _PlaceholderRenderer(elementData, '文本渲染器未初始化');
    }

    return _SpecializedRendererAdapter(
      elementData: elementData,
      renderer: textRenderer,
      context: RenderingContext(
        selectionColor: options?['selectionColor'] as Color? ?? Colors.blue,
        selectedElements: options?['selectedElements'] as Set<String>? ?? {},
      ),
    );
  }

  /// 释放渲染器资源
  void _disposeRenderers() {
    // 释放文本渲染器资源
    final textRenderer = _renderers['text'] as TextElementRenderer?;
    if (textRenderer != null) {
      textRenderer.dispose();
    }

    // 释放图像渲染器资源
    final imageRenderer = _renderers['image'] as ImageElementRenderer?;
    if (imageRenderer != null) {
      imageRenderer.dispose();
    }

    // 释放形状渲染器资源
    final shapeRenderer = _renderers['shape'] as ShapeElementRenderer?;
    if (shapeRenderer != null) {
      shapeRenderer.dispose();
    }

    // 释放路径渲染器资源
    final pathRenderer = _renderers['path'] as PathElementRenderer?;
    if (pathRenderer != null) {
      pathRenderer.dispose();
    }

    _renderers.clear();
  }
}

/// 占位渲染器 - 用于未实现的元素类型
class _PlaceholderRenderer extends CustomPainter {
  final ElementData elementData;
  final String message;

  const _PlaceholderRenderer(this.elementData, this.message);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制边框
    final borderPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      borderPaint,
    );

    // 绘制背景
    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      bgPaint,
    );

    // 绘制文本
    final textPainter = TextPainter(
      text: TextSpan(
        text: message,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(maxWidth: size.width - 20);
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// 专用渲染器适配器 - 将专用渲染器转换为CustomPainter
class _SpecializedRendererAdapter extends CustomPainter {
  final ElementData elementData;
  final dynamic renderer;
  final RenderingContext context;

  const _SpecializedRendererAdapter({
    required this.elementData,
    required this.renderer,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 创建元素边界矩形
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 更新元素边界
    final updatedElement = elementData.copyWith(bounds: rect);

    // 调用专用渲染器的渲染方法
    if (renderer is TextElementRenderer) {
      renderer.renderElement(canvas, updatedElement, context);
    } else if (renderer is ImageElementRenderer) {
      renderer.renderElement(canvas, updatedElement, context);
    } else if (renderer is ShapeElementRenderer) {
      renderer.renderElement(canvas, updatedElement, context);
    } else if (renderer is PathElementRenderer) {
      renderer.renderElement(canvas, updatedElement, context);
    }
  }

  @override
  bool shouldRepaint(covariant _SpecializedRendererAdapter oldDelegate) {
    // 元素ID必须相同
    if (elementData.id != oldDelegate.elementData.id) return true;

    // 检查选择状态是否变化
    final oldSelected = oldDelegate.context.isSelected(elementData.id);
    final newSelected = context.isSelected(elementData.id);
    if (oldSelected != newSelected) return true;

    // 调用专用渲染器的shouldRepaint方法
    if (renderer is TextElementRenderer) {
      return renderer.shouldRepaint(oldDelegate.elementData, elementData);
    } else if (renderer is ImageElementRenderer) {
      return renderer.shouldRepaint(oldDelegate.elementData, elementData);
    } else if (renderer is ShapeElementRenderer) {
      return renderer.shouldRepaint(oldDelegate.elementData, elementData);
    } else if (renderer is PathElementRenderer) {
      return renderer.shouldRepaint(oldDelegate.elementData, elementData);
    }

    return true; // 默认情况下总是重绘
  }
}
