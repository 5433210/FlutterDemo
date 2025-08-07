import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'guideline_renderer.dart';
import 'guideline_types.dart';

/// 参考线渲染层
class GuidelineLayer extends StatelessWidget {
  final List<Guideline> guidelines;
  final Size canvasSize;
  final double scale;
  final Rect? viewportBounds;

  const GuidelineLayer({
    super.key,
    required this.guidelines,
    required this.canvasSize,
    this.scale = 1.0,
    this.viewportBounds,
  });
  @override
  Widget build(BuildContext context) {
    if (guidelines.isEmpty) {
      return const SizedBox.shrink();
    }

    // 检查是否存在动态参考线
    final hasDynamicGuidelines =
        guidelines.any((g) => g.id.startsWith('dynamic_'));

    // 动态参考线强制使用灰色，实线显示
    final painter = GuidelineRenderer.createGuidelinePainter(
      guidelines: guidelines,
      color: hasDynamicGuidelines
          ? const Color(0xFFA0A0A0)
          : Colors.orange, // 动态参考线使用灰色
      strokeWidth: hasDynamicGuidelines ? 1.5 : 1.0,
      showLabels: false, // 动态参考线不显示标签
      dashLine: !hasDynamicGuidelines, // 动态参考线使用实线，静态参考线使用虚线
      viewportBounds: viewportBounds,
    );

    EditPageLogger.editPageDebug(
      '渲染参考线层',
      data: {
        'guidelinesCount': guidelines.length,
        'hasDynamicGuidelines': hasDynamicGuidelines,
        'dynamicGuidelinesCount':
            guidelines.where((g) => g.id.startsWith('dynamic_')).length,
        'guidelinesIds': guidelines.map((g) => g.id).toList(),
        'guidelinesPositions':
            guidelines.map((g) => g.position.toStringAsFixed(1)).toList(),
        'guidelinesColors':
            guidelines.map((g) => g.color.toARGB32().toRadixString(16)).toList(),
        'scale': scale,
        'canvasSize':
            '${canvasSize.width.toStringAsFixed(0)}x${canvasSize.height.toStringAsFixed(0)}',
        'viewportBounds': viewportBounds != null
            ? '${viewportBounds!.left.toStringAsFixed(0)},${viewportBounds!.top.toStringAsFixed(0)},${viewportBounds!.width.toStringAsFixed(0)},${viewportBounds!.height.toStringAsFixed(0)}'
            : 'null',
        'operation': 'guideline_layer_render',
      },
    );

    return IgnorePointer(
      child: SizedBox(
        width: canvasSize.width,
        height: canvasSize.height,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: painter,
            size: canvasSize,
          ),
        ),
      ),
    );
  }
}

/// 创建参考线层的工厂方法
class GuidelineLayerFactory {
  /// 创建参考线渲染层
  static Widget create({
    required List<Guideline> guidelines,
    required Size canvasSize,
    double scale = 1.0,
    Rect? viewportBounds,
  }) {
    // 过滤无效的参考线
    final validGuidelines = guidelines
        .where((g) => g.position.isFinite && !g.position.isNaN)
        .toList();

    if (validGuidelines.isEmpty) {
      return const SizedBox.shrink();
    }

    return GuidelineLayer(
      guidelines: validGuidelines,
      canvasSize: canvasSize,
      scale: scale,
      viewportBounds: viewportBounds,
    );
  }
}
