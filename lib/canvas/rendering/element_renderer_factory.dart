// filepath: lib/canvas/rendering/element_renderer_factory.dart

import 'package:flutter/material.dart';

import '../core/interfaces/element_data.dart';
import 'element_renderer/collection_renderer.dart';

/// 元素渲染器工厂
/// 根据元素类型创建对应的渲染器
class ElementRendererFactory {
  static const ElementRendererFactory _instance =
      ElementRendererFactory._internal();
  factory ElementRendererFactory() => _instance;
  const ElementRendererFactory._internal();

  /// 创建元素渲染器
  CustomPainter createRenderer(ElementData elementData,
      {Map<String, dynamic>? options}) {
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
      default:
        return _createDefaultRenderer(elementData, options);
    }
  }

  /// 创建默认渲染器
  CustomPainter _createDefaultRenderer(
      ElementData elementData, Map<String, dynamic>? options) {
    return _PlaceholderRenderer(elementData, '未知元素类型: ${elementData.type}');
  }

  /// 创建图像渲染器（占位实现）
  CustomPainter _createImageRenderer(
      ElementData elementData, Map<String, dynamic>? options) {
    return _PlaceholderRenderer(elementData, '图像元素');
  }

  /// 创建文本渲染器（占位实现）
  CustomPainter _createTextRenderer(
      ElementData elementData, Map<String, dynamic>? options) {
    return _PlaceholderRenderer(elementData, '文本元素');
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
    );    // 绘制背景
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
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
