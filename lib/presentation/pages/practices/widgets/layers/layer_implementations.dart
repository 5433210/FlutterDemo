import 'package:flutter/material.dart';

import 'base_layer.dart';
import 'layer_types.dart';

/// Interaction layer for UI controls, selection boxes, etc.
class InteractionLayer extends BaseCanvasLayer {
  final Size pageSize;
  final Widget Function()? selectionBuilder;
  final Widget Function()? controlsBuilder;
  final VoidCallback? onInteraction;

  const InteractionLayer({
    super.key,
    required super.config,
    required super.layerId,
    required this.pageSize,
    this.selectionBuilder,
    this.controlsBuilder,
    this.onInteraction,
  });

  @override
  BaseCanvasLayerState<InteractionLayer> createState() =>
      _InteractionLayerState();
}

/// Enhanced content layer that integrates with the layer management system
class ManagedContentLayer extends BaseCanvasLayer {
  final List<Map<String, dynamic>> elements;
  final List<Map<String, dynamic>> layers;
  final Set<String> selectedElementIds;
  final Size pageSize;
  final bool isPreviewMode;
  final Widget Function(List<Map<String, dynamic>>) contentBuilder;

  const ManagedContentLayer({
    super.key,
    required super.config,
    required super.layerId,
    required this.elements,
    required this.layers,
    required this.selectedElementIds,
    required this.pageSize,
    required this.isPreviewMode,
    required this.contentBuilder,
  });

  @override
  BaseCanvasLayerState<ManagedContentLayer> createState() =>
      _ManagedContentLayerState();
}

/// Static background layer for canvas rendering (grid, page borders, etc.)
class StaticBackgroundLayer extends BaseCanvasLayer {
  final Size pageSize;
  final Color backgroundColor;
  final bool showGrid;
  final double gridSpacing;
  final Color gridColor;
  final bool showPageBorder;
  final Color pageBorderColor;
  final double pageBorderWidth;

  const StaticBackgroundLayer({
    super.key,
    required super.config,
    required super.layerId,
    required this.pageSize,
    this.backgroundColor = Colors.white,
    this.showGrid = true,
    this.gridSpacing = 20.0,
    this.gridColor = const Color(0xFFE0E0E0),
    this.showPageBorder = true,
    this.pageBorderColor = const Color(0xFFBDBDBD),
    this.pageBorderWidth = 1.0,
  });

  @override
  BaseCanvasLayerState<StaticBackgroundLayer> createState() =>
      _StaticBackgroundLayerState();
}

/// UI overlay layer for toolbars, menus, etc.
class UIOverlayLayer extends BaseCanvasLayer {
  final Widget? topOverlay;
  final Widget? bottomOverlay;
  final Widget? leftOverlay;
  final Widget? rightOverlay;
  final Widget? centerOverlay;

  const UIOverlayLayer({
    super.key,
    required super.config,
    required super.layerId,
    this.topOverlay,
    this.bottomOverlay,
    this.leftOverlay,
    this.rightOverlay,
    this.centerOverlay,
  });

  @override
  BaseCanvasLayerState<UIOverlayLayer> createState() => _UIOverlayLayerState();
}

/// Custom painter for static background elements
class _BackgroundPainter extends CustomPainter {
  final bool showGrid;
  final double gridSpacing;
  final Color gridColor;
  final bool showPageBorder;
  final Color pageBorderColor;
  final double pageBorderWidth;
  final Size pageSize;

  const _BackgroundPainter({
    required this.showGrid,
    required this.gridSpacing,
    required this.gridColor,
    required this.showPageBorder,
    required this.pageBorderColor,
    required this.pageBorderWidth,
    required this.pageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid if enabled
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    // Draw page border if enabled
    if (showPageBorder) {
      _drawPageBorder(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return showGrid != oldDelegate.showGrid ||
        gridSpacing != oldDelegate.gridSpacing ||
        gridColor != oldDelegate.gridColor ||
        showPageBorder != oldDelegate.showPageBorder ||
        pageBorderColor != oldDelegate.pageBorderColor ||
        pageBorderWidth != oldDelegate.pageBorderWidth ||
        pageSize != oldDelegate.pageSize;
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawPageBorder(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = pageBorderColor
      ..strokeWidth = pageBorderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }
}

class _InteractionLayerState extends BaseCanvasLayerState<InteractionLayer>
    with InteractiveMixin<InteractionLayer> {
  @override
  Widget buildLayerContent(BuildContext context) {
    final children = <Widget>[];

    // Add selection overlay
    if (widget.selectionBuilder != null) {
      children.add(widget.selectionBuilder!());
    }

    // Add control overlay
    if (widget.controlsBuilder != null) {
      children.add(widget.controlsBuilder!());
    }

    Widget content = SizedBox(
      width: widget.pageSize.width,
      height: widget.pageSize.height,
      child: Stack(children: children),
    );

    // Wrap with interactive handling
    return buildInteractiveWrapper(content);
  }

  @override
  void onConfigChanged(LayerConfig oldConfig, LayerConfig newConfig) {
    super.onConfigChanged(oldConfig, newConfig);

    // Interaction layer needs frequent updates
    markNeedsRepaint();
  }

  @override
  void onPointerEvent(PointerEvent event) {
    super.onPointerEvent(event);
    widget.onInteraction?.call();
  }
}

class _ManagedContentLayerState
    extends BaseCanvasLayerState<ManagedContentLayer> {
  @override
  Widget buildLayerContent(BuildContext context) {
    return SizedBox(
      width: widget.pageSize.width,
      height: widget.pageSize.height,
      child: widget.contentBuilder(widget.elements),
    );
  }

  @override
  void onConfigChanged(LayerConfig oldConfig, LayerConfig newConfig) {
    super.onConfigChanged(oldConfig, newConfig);

    // Content layer needs repaint when visibility or opacity changes
    markNeedsRepaint();
  }
}

class _StaticBackgroundLayerState
    extends BaseCanvasLayerState<StaticBackgroundLayer> {
  @override
  Widget buildLayerContent(BuildContext context) {
    return Container(
      width: widget.pageSize.width,
      height: widget.pageSize.height,
      color: widget.backgroundColor,
      child: CustomPaint(
        painter: _BackgroundPainter(
          showGrid: widget.showGrid,
          gridSpacing: widget.gridSpacing,
          gridColor: widget.gridColor,
          showPageBorder: widget.showPageBorder,
          pageBorderColor: widget.pageBorderColor,
          pageBorderWidth: widget.pageBorderWidth,
          pageSize: widget.pageSize,
        ),
        size: widget.pageSize,
      ),
    );
  }

  @override
  void onConfigChanged(LayerConfig oldConfig, LayerConfig newConfig) {
    super.onConfigChanged(oldConfig, newConfig);

    // Background layer rarely needs updates, so only repaint if
    // configuration actually affects rendering
    if (oldConfig.opacity != newConfig.opacity ||
        oldConfig.visibility != newConfig.visibility) {
      markNeedsRepaint();
    }
  }
}

class _UIOverlayLayerState extends BaseCanvasLayerState<UIOverlayLayer> {
  @override
  Widget buildLayerContent(BuildContext context) {
    return Stack(
      children: [
        // Top overlay
        if (widget.topOverlay != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: widget.topOverlay!,
          ),

        // Bottom overlay
        if (widget.bottomOverlay != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: widget.bottomOverlay!,
          ),

        // Left overlay
        if (widget.leftOverlay != null)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: widget.leftOverlay!,
          ),

        // Right overlay
        if (widget.rightOverlay != null)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: widget.rightOverlay!,
          ),

        // Center overlay
        if (widget.centerOverlay != null) Center(child: widget.centerOverlay!),
      ],
    );
  }
}
