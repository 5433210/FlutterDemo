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

    final painter = GuidelineRenderer.createGuidelinePainter(
      guidelines: guidelines,
      color: Colors.orange,
      strokeWidth: 1.0,
      showLabels: true,
      viewportBounds: viewportBounds,
    );

    EditPageLogger.editPageDebug(
      '渲染参考线层',
      data: {
        'guidelinesCount': guidelines.length,
        'scale': scale,
        'canvasSize': '${canvasSize.width.toStringAsFixed(0)}x${canvasSize.height.toStringAsFixed(0)}',
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
    final validGuidelines = guidelines.where((g) => 
      g.position.isFinite && 
      !g.position.isNaN
    ).toList();

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