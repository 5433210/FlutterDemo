import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../../../l10n/app_localizations.dart';
import '../../../widgets/image/cached_image.dart';
import '../../../widgets/practice/collection_element_renderer.dart';
import '../../../widgets/practice/element_renderers.dart';
import '../../../widgets/practice/practice_edit_controller.dart';
import '../helpers/element_utils.dart';
import 'canvas_control_points.dart';
import 'canvas_gesture_handler.dart';

/// Material 3 canvas widget for practice editing
class M3PracticeEditCanvas extends ConsumerStatefulWidget {
  final PracticeEditController controller;
  final bool isPreviewMode;
  final TransformationController transformationController;

  const M3PracticeEditCanvas({
    super.key,
    required this.controller,
    required this.isPreviewMode,
    required this.transformationController,
  });

  @override
  ConsumerState<M3PracticeEditCanvas> createState() =>
      _M3PracticeEditCanvasState();
}

/// Grid painter
class _GridPainter extends CustomPainter {
  final double gridSize;
  final Color gridColor;

  _GridPainter({
    required this.gridSize,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize ||
        oldDelegate.gridColor != gridColor;
  }
}

class _M3PracticeEditCanvasState extends ConsumerState<M3PracticeEditCanvas> {
  // Drag state variables
  bool _isDragging = false;
  Offset _dragStart = Offset.zero;
  Offset _elementStartPosition = Offset.zero;
  final Map<String, Offset> _elementStartPositions = {};

  // Canvas gesture handler
  late CanvasGestureHandler _gestureHandler;

  // Dedicated GlobalKey for RepaintBoundary (for screenshot functionality)
  // Use the widget's key if provided, otherwise create a new one
  late final GlobalKey _repaintBoundaryKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.controller.state.pages.isEmpty) {
      return Center(
        child: Text(
          'No pages available',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final currentPage = widget.controller.state.currentPage;
    if (currentPage == null) {
      return Center(
        child: Text(
          'Current page does not exist',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final elements = widget.controller.state.currentPageElements;
    return _buildCanvas(currentPage, elements, colorScheme);
  }

  @override
  void dispose() {
    widget.transformationController.removeListener(_handleTransformationChange);
    super.dispose();
  }
  @override
  void initState() {
    super.initState();

    // Initialize RepaintBoundary key - always create a new key for screenshot functionality
    // Don't reuse widget.key as it may cause conflicts with other widgets
    _repaintBoundaryKey = GlobalKey();

    // Initialize zoom listener
    widget.transformationController.addListener(_handleTransformationChange);

    // Initialize gesture handler
    _gestureHandler = CanvasGestureHandler(
      controller: widget.controller,
      onDragStart: (isDragging, dragStart, elementPosition, elementPositions) {
        setState(() {
          _isDragging = isDragging;
          _dragStart = dragStart;
          _elementStartPosition = elementPosition;
          _elementStartPositions.clear();
          _elementStartPositions.addAll(elementPositions);
        });
      },
      onDragUpdate: () {
        setState(() {});
      },
      onDragEnd: () {
        setState(() {
          _isDragging = false;
        });

        // 处理元素平移后的网格吸附
        _applyGridSnapToSelectedElements();
      },
      getScaleFactor: () {
        // Extract the scale from the transformation matrix
        final Matrix4 matrix = widget.transformationController.value;
        // The scale is the same for x and y in this case (uniform scaling)
        return matrix.getMaxScaleOnAxis();
      },
    ); // Register this canvas with the controller for reset view functionality
    widget.controller.setEditCanvas(this);

    // Set the RepaintBoundary key in the controller for screenshot functionality
    widget.controller.setCanvasKey(_repaintBoundaryKey);
  }

  /// Public method to reset canvas position
  void resetCanvasPosition() {
    _resetCanvasPosition();
  }

  /// 为所有选中的元素应用网格吸附  /// 为选中的元素应用网格吸附（只在拖拽结束时调用）
  void _applyGridSnapToSelectedElements() {
    // 只有在启用了网格吸附的情况下才进行网格吸附
    if (!widget.controller.state.snapEnabled) {
      return;
    }

    final gridSize = widget.controller.state.gridSize;

    // 处理所有选中元素
    for (final elementId in widget.controller.state.selectedElementIds) {
      final element = widget.controller.state.currentPageElements.firstWhere(
        (e) => e['id'] == elementId,
        orElse: () => <String, dynamic>{},
      );

      if (element.isEmpty) continue;

      // 跳过锁定的元素
      final isLocked = element['locked'] as bool? ?? false;
      if (isLocked) continue;

      // 跳过锁定图层上的元素
      final layerId = element['layerId'] as String?;
      if (layerId != null && widget.controller.state.isLayerLocked(layerId)) {
        continue;
      }

      // 获取当前位置和尺寸
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();

      // 计算吸附后的位置（向最近的网格线吸附）
      final snappedX = (x / gridSize).round() * gridSize;
      final snappedY = (y / gridSize).round() * gridSize;

      // 如果位置有变化，更新元素属性
      if (snappedX != x || snappedY != y) {
        debugPrint(
            '网格吸附: 元素 $elementId 位置从 ($x, $y) 吸附到 ($snappedX, $snappedY)');

        widget.controller.updateElementProperties(elementId, {
          'x': snappedX,
          'y': snappedY,
        });
      }
    }
  }

  /// Build the main canvas
  Widget _buildCanvas(
    Map<String, dynamic> currentPage,
    List<dynamic> elements,
    ColorScheme colorScheme,
  ) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        // Handle dropping new elements onto the canvas
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.offset);

        // Calculate page dimensions (applying DPI conversion)
        final pageSize = ElementUtils.calculatePixelSize(currentPage);

        // Ensure coordinates are within page boundaries
        double x = localPosition.dx.clamp(0.0, pageSize.width);
        double y = localPosition.dy.clamp(0.0, pageSize.height);

        // Adjust for current zoom level
        final scale = widget.transformationController.value.getMaxScaleOnAxis();
        final translation =
            widget.transformationController.value.getTranslation();
        x = (x - translation.x) / scale;
        y = (y - translation.y) / scale;

        // Add element based on type
        switch (details.data) {
          case 'text':
            widget.controller.addTextElementAt(x, y);
            break;
          case 'image':
            widget.controller.addEmptyImageElementAt(x, y);
            break;
          case 'collection':
            widget.controller.addEmptyCollectionElementAt(x, y);
            break;
        }
      },
      builder: (context, candidateData, rejectedData) {
        // Get current zoom level
        final scale = widget.transformationController.value.getMaxScaleOnAxis();
        final zoomPercentage = (scale * 100).toInt();

        return Stack(
          children: [
            Container(
              color: colorScheme.inverseSurface.withOpacity(
                  0.1), // Canvas outer background - improved contrast in light theme

              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(double.infinity),
                // 当处于select模式时禁用平移，允许我们的选择框功能工作
                panEnabled: widget.controller.state.currentTool != 'select',
                scaleEnabled: true,
                minScale: 0.1,
                maxScale: 15.0,
                scaleFactor:
                    600.0, // Increased scale factor to make zooming more gradual
                transformationController: widget.transformationController,
                onInteractionStart: (ScaleStartDetails details) {},
                onInteractionUpdate: (ScaleUpdateDetails details) {},
                onInteractionEnd: (ScaleEndDetails details) {
                  // Update final zoom value
                  final scale =
                      widget.transformationController.value.getMaxScaleOnAxis();
                  widget.controller.zoomTo(scale);
                  setState(
                      () {}); // Update to reflect the new zoom level in the status bar
                },
                constrained: false, // Allow content to be unconstrained
                child: GestureDetector(
                  behavior: HitTestBehavior
                      .translucent, // Ensure gesture events are properly passed
                  onTapUp: (details) => _gestureHandler.handleTapUp(
                      details, elements.cast<Map<String, dynamic>>()),
                  // 处理右键点击事件，用于退出select模式
                  onSecondaryTapDown: (details) =>
                      _gestureHandler.handleSecondaryTapDown(details),
                  onSecondaryTapUp: (details) =>
                      _gestureHandler.handleSecondaryTapUp(
                          details, elements.cast<Map<String, dynamic>>()),
                  onPanStart: (details) => _gestureHandler.handlePanStart(
                      details, elements.cast<Map<String, dynamic>>()),
                  onPanUpdate: (details) {
                    // 先处理选择框更新，这优先级最高
                    if (widget.controller.state.currentTool == 'select' &&
                        _gestureHandler.isSelectionBoxActive) {
                      _gestureHandler.handlePanUpdate(details);
                      setState(() {}); // 确保选择框重绘
                      return;
                    }

                    // Handle element dragging in select mode or any other mode
                    // _isDragging will be true even in select mode if we started dragging on a selected element
                    if (_isDragging) {
                      _gestureHandler.handlePanUpdate(details);
                      setState(() {}); // Force redraw for element movement
                      return;
                    }

                    // If not dragging elements and not in select mode, handle panning directly
                    if (!_isDragging &&
                        widget.controller.state.currentTool != 'select') {
                      // Create new transformation matrix
                      final Matrix4 newMatrix = Matrix4.identity();

                      // Set same scale factor as current
                      final scale = widget.transformationController.value
                          .getMaxScaleOnAxis();
                      newMatrix.setEntry(0, 0, scale);
                      newMatrix.setEntry(1, 1, scale);
                      newMatrix.setEntry(2, 2, scale);

                      // Get current translation
                      final Vector3 translation = widget
                          .transformationController.value
                          .getTranslation(); // Apply delta with scale adjustment to ensure consistent movement at all zoom levels
                      // For canvas panning: when zoomed in, cursor movement should translate to larger canvas movement
                      // Use the same approach as in canvas_gesture_handler.dart

                      newMatrix.setTranslation(Vector3(
                        translation.x + details.delta.dx * scale,
                        translation.y + details.delta.dy * scale,
                        0.0,
                      ));

                      widget.transformationController.value =
                          newMatrix; // Force refresh
                      setState(() {});

                      // Add debug logging
                      debugPrint(
                          '【直接平移】在缩放级别=$scale下应用dx=${details.delta.dx}, dy=${details.delta.dy}，'
                          '倒数缩放因子=$scale, 调整后dx=${details.delta.dx * scale}, dy=${details.delta.dy * scale}');
                    }

                    // Always call handlePanUpdate for any cases not handled above
                    _gestureHandler.handlePanUpdate(details);
                  },
                  onPanEnd: (details) => _gestureHandler.handlePanEnd(details),
                  child: _buildPageContent(currentPage,
                      elements.cast<Map<String, dynamic>>(), colorScheme),
                ),
              ),
            ),

            // Status bar showing zoom level (only visible in edit mode)

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                color: colorScheme.surface.withOpacity(0.85),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: [
                    // Debug indicator showing current tool
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '当前工具: ${widget.controller.state.currentTool}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Selection mode indicator
                    if (widget.controller.state.currentTool == 'select' &&
                        !widget.isPreviewMode)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.select_all,
                              size: 16,
                              color: colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '选择模式', // Direct text since the localization key might not exist
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Reset position button
                    Tooltip(
                      message:
                          AppLocalizations.of(context).canvasResetViewTooltip,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _resetCanvasPosition,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 120),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.center_focus_strong,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .canvasResetView,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Zoom indicator
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 80),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.zoom_in,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '$zoomPercentage%',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build control points for selected element
  Widget _buildControlPoints(
    String elementId,
    double x,
    double y,
    double width,
    double height,
    double rotation,
  ) {
    // 添加日志，跟踪控制点构建
    debugPrint(
        '⚙️ 构建控制点 - 元素ID: $elementId, 类型: ${widget.controller.state.selectedElement?['type'] ?? '未知'}, 坐标: ($x, $y), 尺寸: ${width}x$height, 旋转: $rotation');
    // Use absolute positioning for control points to ensure they're always visible
    return AbsorbPointer(
      absorbing: false, // Ensure control points can receive events
      child: GestureDetector(
        // onTapDown: (details) {},
        // onTap: () {
        //   // Clear selection when tapping on empty area
        //   // widget.controller.clearSelection();
        // },
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Transparent overlay to ensure control points receive events
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                ),
              ), // Actual control points
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                bottom: 0,
                child: RepaintBoundary(
                  key: ValueKey('control_points_repaint_boundary_$elementId'),
                  child: Builder(builder: (context) {
                    // 获取当前缩放值
                    final scale = widget.transformationController.value
                        .getMaxScaleOnAxis();
                    return CanvasControlPoints(
                      key: ValueKey(
                          'control_points_${elementId}_${scale.toStringAsFixed(2)}'),
                      elementId: elementId,
                      x: x,
                      y: y,
                      width: width,
                      height: height,
                      rotation: rotation,
                      initialScale:
                          scale, // Pass the current scale to ensure proper control point sizing
                      onControlPointUpdate: _handleControlPointUpdate,
                      onControlPointDragEnd: _handleControlPointDragEnd,
                    );
                  }),
                ),
              ),

              // Add a transparent overlay to ensure control points can immediately respond to events
              Positioned.fill(
                child: IgnorePointer(
                  ignoring:
                      true, // Ignore pointer events, let control points receive events
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build page content
  Widget _buildPageContent(
    Map<String, dynamic> page,
    List<Map<String, dynamic>> elements,
    ColorScheme colorScheme,
  ) {
    // Get page dimensions (applying DPI conversion)
    final pageSize = ElementUtils.calculatePixelSize(page);

    // Get page background color
    Color backgroundColor = Colors.white;
    try {
      final background = page['background'] as Map<String, dynamic>?;
      if (background != null && background['type'] == 'color') {
        final colorStr = background['value'] as String? ?? '#FFFFFF';
        backgroundColor = ElementUtils.parseColor(colorStr);
        debugPrint('Background color parsed: $colorStr -> $backgroundColor');
      }
    } catch (e) {
      debugPrint('Error parsing background color: $e');
    }

    // Get selected element for control points
    String? selectedElementId;
    double x = 0, y = 0, width = 0, height = 0, rotation = 0;

    debugPrint(
        '🔍 构建页面内容 - 选中元素数: ${widget.controller.state.selectedElementIds.length}');

    if (widget.controller.state.selectedElementIds.length == 1) {
      selectedElementId = widget.controller.state.selectedElementIds.first;
      final selectedElement = elements.firstWhere(
        (e) => e['id'] == selectedElementId,
        orElse: () => <String, dynamic>{},
      );

      debugPrint(
          '🔍 选中元素信息 - ID: $selectedElementId, 类型: ${selectedElement['type'] ?? '未知'}, 找到元素: ${selectedElement.isNotEmpty}');

      if (selectedElement.isNotEmpty) {
        // Get element properties for control points
        x = (selectedElement['x'] as num?)?.toDouble() ?? 0.0;
        y = (selectedElement['y'] as num?)?.toDouble() ?? 0.0;
        width = (selectedElement['width'] as num?)?.toDouble() ?? 0.0;
        height = (selectedElement['height'] as num?)?.toDouble() ?? 0.0;
        rotation = (selectedElement['rotation'] as num?)?.toDouble() ?? 0.0;
      }
    }

    return Stack(
      fit: StackFit.loose, // Use loose fit for outer stack
      clipBehavior:
          Clip.hardEdge, // Use hardEdge to prevent mouse tracking issues
      children: [
        // Page background
        Container(
          width: pageSize.width,
          height: pageSize.height,
          color: backgroundColor,
          child: RepaintBoundary(
            key: _repaintBoundaryKey, // Use dedicated key for RepaintBoundary
            child: AbsorbPointer(
              absorbing: false, // Ensure control points can receive events
              child: Stack(
                fit: StackFit.expand, // Ensure stack fills its parent
                clipBehavior: Clip
                    .hardEdge, // Use hardEdge to prevent mouse tracking issues
                children: [
                  // Background layer - ensure background color is correctly applied
                  Container(
                    width: pageSize.width,
                    height: pageSize.height,
                    color: backgroundColor,
                  ),

                  // Grid (if visible and not in preview mode)
                  if (widget.controller.state.gridVisible &&
                      !widget.isPreviewMode)
                    CustomPaint(
                      size: Size(pageSize.width, pageSize.height),
                      painter: _GridPainter(
                        gridSize: widget.controller.state.gridSize,
                        gridColor: colorScheme.outlineVariant
                            .withAlpha(77), // 0.3 opacity (77/255)
                      ),
                    ),

                  // Render elements
                  ...elements.map((element) {
                    // Skip hidden elements
                    final isHidden = element['hidden'] == true;
                    if (isHidden) {
                      debugPrint(
                          '跳过隐藏元素: id=${element['id']}, hidden=$isHidden');
                      return const SizedBox.shrink();
                    }

                    // Get element properties
                    final id = element['id'] as String;
                    final elementX = (element['x'] as num).toDouble();
                    final elementY = (element['y'] as num).toDouble();
                    final elementWidth = (element['width'] as num).toDouble();
                    final elementHeight = (element['height'] as num).toDouble();
                    final elementRotation =
                        (element['rotation'] as num?)?.toDouble() ?? 0.0;
                    final isLocked = element['locked'] == true;

                    // Check if element is on a locked layer
                    final layerId = element['layerId'] as String?;
                    bool isLayerLocked = false;
                    bool isLayerHidden = false;
                    if (layerId != null) {
                      final layer =
                          widget.controller.state.getLayerById(layerId);
                      if (layer != null) {
                        isLayerLocked = layer['isLocked'] == true;
                        isLayerHidden = layer['isVisible'] == false;
                      }
                    }

                    // Skip hidden layer elements
                    if (isLayerHidden) {
                      debugPrint(
                          '跳过隐藏图层上的元素: id=${element['id']}, layerId=$layerId');
                      return const SizedBox.shrink();
                    }

                    // Check if this element is selected
                    final isSelected =
                        widget.controller.state.selectedElementIds.contains(id);

                    // Render element
                    return Positioned(
                      left: elementX,
                      top: elementY,
                      child: Transform.rotate(
                        angle: elementRotation *
                            math.pi /
                            180, // Convert to radians
                        child: Container(
                          width: elementWidth,
                          height: elementHeight,
                          decoration: !widget.isPreviewMode && isSelected
                              ? BoxDecoration(
                                  border: Border.all(
                                    color: isLocked || isLayerLocked
                                        ? colorScheme.tertiary
                                        : colorScheme.primary,
                                    width: 0.5, // 将边框宽度从2.0减小到0.5像素
                                    style: BorderStyle.solid,
                                  ),
                                  // 使用完全透明的遮盖层，不再使用半透明背景色
                                  color: Colors.transparent,
                                )
                              : null,
                          child: Stack(
                            children: [
                              // Element content
                              _renderElement(
                                  element), // 为选中元素添加角落指示器，增强选中状态的可见性
                              if (!widget.isPreviewMode && isSelected)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _SelectionCornerPainter(
                                      color: isLocked
                                          ? colorScheme.tertiary
                                          : colorScheme.primary,
                                    ),
                                  ),
                                ),

                              // Lock icon (if element or its layer is locked)
                              if ((isLocked || isLayerLocked) &&
                                  !widget.isPreviewMode)
                                Positioned(
                                  right: 2,
                                  top: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withAlpha(204), // 0.8 opacity
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isLayerLocked
                                            ? Colors.grey.shade400
                                            : colorScheme.tertiary,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isLayerLocked
                                              ? Icons.layers
                                              : Icons.lock,
                                          size: 18,
                                          color: isLayerLocked
                                              ? Colors.grey.shade700
                                              : colorScheme.tertiary,
                                        ),
                                        if (isLayerLocked)
                                          Icon(
                                            Icons.lock,
                                            size: 14,
                                            color: Colors.grey.shade700,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  // Selection box - draw when in select mode and dragging
                  if (!widget.isPreviewMode &&
                      widget.controller.state.currentTool == 'select' &&
                      _gestureHandler.isSelectionBoxActive &&
                      _gestureHandler.selectionBoxStart != null &&
                      _gestureHandler.selectionBoxEnd != null)
                    CustomPaint(
                      painter: _SelectionBoxPainter(
                        startPoint: _gestureHandler.selectionBoxStart!,
                        endPoint: _gestureHandler.selectionBoxEnd!,
                        color: colorScheme.primary,
                      ),
                      size: Size(pageSize.width, pageSize.height),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Control points for selected element (if single selection)
        if (selectedElementId != null && !widget.isPreviewMode)
          Positioned.fill(
            child: _buildControlPoints(
                selectedElementId, x, y, width, height, rotation),
          ),
      ],
    );
  }

  BoxFit _getFitMode(String fitMode) {
    switch (fitMode) {
      case 'fill':
        return BoxFit.fill;
      case 'cover':
        return BoxFit.cover;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      case 'scaleDown':
        return BoxFit.scaleDown;
      case 'contain':
      default:
        return BoxFit.contain;
    }
  }

  /// 处理控制点拖拽结束事件

  /// 处理控制点拖拽结束事件
  void _handleControlPointDragEnd(int controlPointIndex) {
    debugPrint('控制点 $controlPointIndex 拖拽结束');

    if (widget.controller.state.selectedElementIds.isEmpty) {
      return;
    }

    final elementId = widget.controller.state.selectedElementIds.first;

    // 获取当前元素属性
    final element = widget.controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) {
      return;
    }

    // 如果是旋转控制点（索引8），不做处理
    if (controlPointIndex == 8) {
      debugPrint('旋转控制点拖拽结束');
      return;
    }

    // 只有在启用了网格吸附的情况下才进行网格吸附
    if (widget.controller.state.snapEnabled) {
      // 获取元素的当前位置和尺寸
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();
      final gridSize = widget.controller.state.gridSize;

      // 计算吸附后的位置和尺寸（向最近的网格线吸附）
      final snappedX = (x / gridSize).round() * gridSize;
      final snappedY = (y / gridSize).round() * gridSize;
      final snappedWidth = (width / gridSize).round() * gridSize;
      final snappedHeight = (height / gridSize).round() * gridSize;

      // 确保尺寸不小于最小值
      final finalWidth = math.max(snappedWidth, 10.0);
      final finalHeight = math.max(snappedHeight, 10.0);

      // 更新元素属性
      final updates = {
        'x': snappedX,
        'y': snappedY,
        'width': finalWidth,
        'height': finalHeight,
      };

      debugPrint('网格吸附: 元素 $elementId 位置从 ($x, $y) 吸附到 ($snappedX, $snappedY)');
      debugPrint(
          '网格吸附: 元素 $elementId 尺寸从 ($width, $height) 吸附到 ($finalWidth, $finalHeight)');

      widget.controller.updateElementProperties(elementId, updates);
    }
  }

  /// Handle control point updates
  void _handleControlPointUpdate(int controlPointIndex, Offset delta) {
    // 获取当前缩放比例
    final scale = widget.transformationController.value.getMaxScaleOnAxis();

    // 调整增量，考虑当前缩放比例
    // 注意：在高缩放比例下，小的物理移动会导致很小的逻辑移动，
    // 而在低缩放比例下，相同的物理移动会导致较大的逻辑移动
    final adjustedDelta = Offset(delta.dx / scale, delta.dy / scale);
    delta = adjustedDelta;

    if (widget.controller.state.selectedElementIds.isEmpty) {
      return;
    }

    final elementId = widget.controller.state.selectedElementIds.first;

    // Get current element properties
    final element = widget.controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );
    if (element.isEmpty) {
      return;
    } // Recreate the SnapManager with current settings
    // _snapManager.updateSettings(
    //   gridSize: widget.controller.state.gridSize,
    //   enabled: widget.controller.state.snapEnabled,
    //   snapThreshold: 10.0,
    // );

    // Check if element's layer is locked
    final layerId = element['layerId'] as String?;
    if (layerId != null && widget.controller.state.isLayerLocked(layerId)) {
      return; // Skip if layer is locked
    }

    // Check if element itself is locked
    final isLocked = element['locked'] as bool? ?? false;
    if (isLocked) {
      debugPrint('跳过控制点更新：元素已锁定 id=$elementId');
      return; // Skip if element is locked
    }

    try {
      // Process control point update immediately
      if (controlPointIndex == 8) {
        // Rotation control point
        _handleRotation(elementId, delta);
      } else {
        // Resize control point
        _handleResize(elementId, controlPointIndex, delta);
      }
    } catch (e) {
      debugPrint('Control point update failed: $e');
    }
  }

  /// Handle element resize
  void _handleResize(String elementId, int controlPointIndex, Offset delta) {
    final element = widget.controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) {
      return;
    }

    // Get current element properties
    double x = (element['x'] as num).toDouble();
    double y = (element['y'] as num).toDouble();
    double width = (element['width'] as num).toDouble();
    double height = (element['height'] as num).toDouble();
    double rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;

    debugPrint(
        '调整元素大小: 控制点=$controlPointIndex, delta=$delta, 当前属性: x=$x, y=$y, width=$width, height=$height, rotation=$rotation');

    // 如果元素有旋转，我们需要考虑旋转后的坐标系中的调整
    // 但为了简化，我们先在原始坐标系中进行调整

    // 根据控制点索引计算新的位置和大小
    switch (controlPointIndex) {
      case 0: // 左上角
        x += delta.dx;
        y += delta.dy;
        width -= delta.dx;
        height -= delta.dy;
        break;
      case 1: // 上中
        y += delta.dy;
        height -= delta.dy;
        break;
      case 2: // 右上角
        y += delta.dy;
        width += delta.dx;
        height -= delta.dy;
        break;
      case 3: // 右中
        width += delta.dx;
        break;
      case 4: // 右下角
        width += delta.dx;
        height += delta.dy;
        break;
      case 5: // 下中
        height += delta.dy;
        break;
      case 6: // 左下角
        x += delta.dx;
        width -= delta.dx;
        height += delta.dy;
        break;
      case 7: // 左中
        x += delta.dx;
        width -= delta.dx;
        break;
    } // 确保最小尺寸
    width = width.clamp(10.0, double.infinity);
    height =
        height.clamp(10.0, double.infinity); // 注释掉拖拽过程中的平滑吸附，改为只在拖拽结束时应用网格吸附
    // 应用平滑吸附 - 使用SnapManager
    // if (widget.controller.state.snapEnabled) {
    //   // 确保使用最新的网格设置更新SnapManager
    //   _snapManager.updateSettings(
    //     gridSize: widget.controller.state.gridSize,
    //     enabled: widget.controller.state.snapEnabled,
    //     snapThreshold: 10.0,
    //   );

    //   // 创建一个临时的元素位置供SnapManager使用
    //   final tempElement = {
    //     'id': elementId,
    //     'x': x,
    //     'y': y,
    //     'width': width,
    //     'height': height,
    //   }; // 应用平滑吸附到网格 - 在拖拽过程中使用 snapFactor=0.3 实现平滑效果
    //   final snappedPosition = _snapManager.snapPosition(
    //     Offset(x, y),
    //     [tempElement],
    //     elementId,
    //     isDragging: true,
    //     snapFactor: 0.3,
    //   );

    //   // 确保位置有变化 - 避免卡住不动
    //   if ((snappedPosition.dx - x).abs() > 0.001 ||
    //       (snappedPosition.dy - y).abs() > 0.001) {
    //     // 更新位置，但保持原来计算的宽高
    //     x = snappedPosition.dx;
    //     y = snappedPosition.dy;

    //     debugPrint('吸附后的位置: x=$x, y=$y');
    //   } else {
    //     debugPrint('跳过吸附: 位置变化太小');
    //   }
    // }

    // 更新元素属性
    final updates = {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };

    debugPrint('更新元素属性: $updates');
    widget.controller.updateElementProperties(elementId, updates);
  }

  /// Handle element rotation
  void _handleRotation(String elementId, Offset delta) {
    final element = widget.controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) {
      return;
    }

    // Get current rotation
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;

    // We'll use a simpler rotation approach that doesn't require center point calculation

    // Improved rotation calculation
    // Use a sensitivity factor to make rotation more controllable
    const rotationSensitivity = 0.5;

    // Calculate rotation based on delta movement
    // Horizontal movement (dx) has more effect on rotation than vertical movement (dy)
    final rotationDelta = (delta.dx * rotationSensitivity);

    // Apply the rotation delta
    final newRotation = rotation + rotationDelta;

    debugPrint(
        'Rotating element $elementId: delta=$delta, rotationDelta=$rotationDelta, newRotation=$newRotation'); // Update rotation
    widget.controller
        .updateElementProperties(elementId, {'rotation': newRotation});
  }

  /// Handle transformation changes
  void _handleTransformationChange() {
    // Update controller with new scale
    final scale = widget.transformationController.value.getMaxScaleOnAxis();
    widget.controller.zoomTo(scale);

    // Force a rebuild to update the zoom percentage in the status bar
    setState(() {});
  }

  /// Parse color from string
  Color _parseColor(String colorString) {
    // Use the same implementation as ElementUtils.parseColor for consistency
    return ElementUtils.parseColor(colorString);
  }

  /// Render collection element
  Widget _renderCollectionElement(Map<String, dynamic> element) {
    debugPrint(
        '🔍 渲染集字元素 - ID: ${element['id']}, 选中状态: ${widget.controller.state.selectedElementIds.contains(element['id'])}');
    final content = element['content'] as Map<String, dynamic>? ?? {};
    final characters = content['characters'] as String? ?? '';
    final backgroundColor = content['backgroundColor'] as String? ?? '#FFFFFF';

    // Get collection properties with defaults
    final writingMode = content['writingMode'] as String? ?? 'horizontal-l';
    final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 40.0;
    final letterSpacing = (content['letterSpacing'] as num?)?.toDouble() ?? 0.0;
    final lineSpacing = (content['lineSpacing'] as num?)?.toDouble() ?? 0.0;
    final textAlign = content['textAlign'] as String? ?? 'left';
    final verticalAlign = content['verticalAlign'] as String? ?? 'top';
    final fontColor = content['fontColor'] as String? ?? '#000000';
    final padding = (content['padding'] as num?)?.toDouble() ?? 0.0;
    final enableSoftLineBreak = content['enableSoftLineBreak'] as bool? ??
        false; // Get texture-related properties
    final hasBackgroundTexture = content.containsKey('backgroundTexture') &&
        content['backgroundTexture'] != null &&
        content['backgroundTexture'] is Map<String, dynamic> &&
        (content['backgroundTexture'] as Map<String, dynamic>).isNotEmpty;
    final backgroundTexture = hasBackgroundTexture
        ? content['backgroundTexture'] as Map<String, dynamic>
        : null;
    final textureApplicationRange =
        content['textureApplicationRange'] as String? ?? 'character';
    final textureFillMode = content['textureFillMode'] as String? ?? 'repeat';
    final textureOpacity =
        (content['textureOpacity'] as num?)?.toDouble() ?? 1.0;

    // Enhanced texture debugging
    print('🧩 TEXTURE: 渲染集字元素开始：元素ID=${element['id']}');
    print('🧩 TEXTURE: 纹理数据详情:');
    print('🧩 TEXTURE:   - 是否启用纹理: $hasBackgroundTexture');
    print('🧩 TEXTURE:   - 纹理数据: $backgroundTexture');
    print('🧩 TEXTURE:   - 应用范围: $textureApplicationRange');
    print('🧩 TEXTURE:   - 填充模式: $textureFillMode');
    print('🧩 TEXTURE:   - 不透明度: $textureOpacity');

    if (backgroundTexture != null) {
      print('🧩 TEXTURE:   - 纹理路径: ${backgroundTexture['path']}');
      if (backgroundTexture.containsKey('path')) {
        // Check if the texture path exists
        final texturePath = backgroundTexture['path'];
        if (texturePath != null) {
          try {
            final file = File(texturePath.toString());
            print('🧩 TEXTURE:   - 纹理文件检查: ${file.path}');
            print('🧩 TEXTURE:   - 文件是否存在: ${file.existsSync()}');
          } catch (e) {
            print('🧩 TEXTURE:   - 纹理文件检查失败: $e');
          }
        }
      }
    }

    // Get character images
    final characterImages = content;

    // Parse color
    final bgColor = _parseColor(backgroundColor);

    if (characters.isEmpty) {
      print('🧩 TEXTURE: 渲染集字元素：字符为空，显示占位符');
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: bgColor,
        child: const Center(
          child: Text(
            'Empty Collection',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    print('🧩 TEXTURE: 创建集字渲染器，字符数: ${characters.length}');
    print('🧩 TEXTURE: 传递的内边距: $padding');

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: bgColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          print('🧩 TEXTURE: 布局构建器获得约束: $constraints');
          return CollectionElementRenderer.buildCollectionLayout(
            characters: characters,
            writingMode: writingMode,
            fontSize: fontSize,
            letterSpacing: letterSpacing,
            lineSpacing: lineSpacing,
            textAlign: textAlign,
            verticalAlign: verticalAlign,
            characterImages: characterImages,
            constraints: constraints,
            padding: padding,
            fontColor: fontColor,
            backgroundColor: backgroundColor,
            enableSoftLineBreak: enableSoftLineBreak,
            // Pass texture-related properties
            hasCharacterTexture: hasBackgroundTexture,
            characterTextureData: backgroundTexture,
            textureFillMode: textureFillMode,
            textureOpacity: textureOpacity,
            textureApplicationRange:
                textureApplicationRange, // Pass the application mode explicitly
            ref: ref,
          );
        },
      ),
    );
  }

  /// Render element based on its type
  Widget _renderElement(Map<String, dynamic> element) {
    final type = element['type'] as String;

    // Simple placeholder rendering for each element type
    switch (type) {
      case 'text':
        return _renderTextElement(element);
      case 'image':
        return _renderImageElement(element);
      case 'collection':
        return _renderCollectionElement(element);
      case 'group':
        return _renderGroupElement(element);
      default:
        return Container(
          color: Colors.grey.withAlpha(51), // 0.2 opacity (51/255)
          child: Center(child: Text('Unknown element type: $type')),
        );
    }
  }

  /// Render group element
  Widget _renderGroupElement(Map<String, dynamic> element) {
    final content = element['content'] as Map<String, dynamic>? ?? {};

    // 检查是否使用 'children' 键（新版本）或 'elements' 键（旧版本）
    List<dynamic> children = [];
    if (content.containsKey('children')) {
      children = content['children'] as List<dynamic>? ?? [];
    } else if (content.containsKey('elements')) {
      children = content['elements'] as List<dynamic>? ?? [];
    }

    if (children.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.withAlpha(26), // 0.1 opacity (26/255)
        child: const Center(
          child: Text('空组合'),
        ),
      );
    }

    // 使用Stack来渲染所有子元素
    return Stack(
      clipBehavior: Clip.none,
      children: children.map<Widget>((child) {
        final String type = child['type'] as String;
        final double x = (child['x'] as num).toDouble();
        final double y = (child['y'] as num).toDouble();
        final double width = (child['width'] as num).toDouble();
        final double height = (child['height'] as num).toDouble();
        final double rotation = (child['rotation'] as num? ?? 0.0).toDouble();
        final double opacity = (child['opacity'] as num? ?? 1.0).toDouble();
        final bool isHidden = child['hidden'] as bool? ?? false;

        // 如果元素被隐藏，则不渲染（预览模式）或半透明显示（编辑模式）
        if (isHidden && widget.isPreviewMode) {
          return const SizedBox.shrink();
        }

        // 根据子元素类型渲染不同的内容
        Widget childWidget;
        switch (type) {
          case 'text':
            childWidget = _renderTextElement(child);
            break;
          case 'image':
            childWidget = _renderImageElement(child);
            break;
          case 'collection':
            childWidget = _renderCollectionElement(child);
            break;
          case 'group':
            // 递归处理嵌套组合
            childWidget = _renderGroupElement(child);
            break;
          default:
            childWidget = Container(
              color: Colors.grey.withAlpha(51), // 0.2 的不透明度
              child: Center(child: Text('未知元素类型: $type')),
            );
        }

        // 使用Positioned和Transform确保子元素在正确的位置和角度
        return Positioned(
          left: x,
          top: y,
          width: width,
          height: height,
          child: Transform.rotate(
            angle: rotation * (3.14159265359 / 180),
            alignment: Alignment.center,
            child: Opacity(
              opacity: isHidden && !widget.isPreviewMode ? 0.5 : opacity,
              child: SizedBox(
                width: width,
                height: height,
                child: childWidget,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Render image element
  Widget _renderImageElement(Map<String, dynamic> element) {
    debugPrint(
        '🔍 渲染图片元素 - ID: ${element['id']}, 选中状态: ${widget.controller.state.selectedElementIds.contains(element['id'])}');
    final content = element['content'] as Map<String, dynamic>? ?? {};
    final imageUrl = content['imageUrl'] as String? ?? '';
    final transformedImageUrl = content['transformedImageUrl'] as String?;
    final backgroundColor = content['backgroundColor'] as String? ?? '#FFFFFF';
    final fitMode = content['fitMode'] as String? ?? 'contain';

    // Get BoxFit from fitMode
    final BoxFit fit = _getFitMode(fitMode);

    // Parse color
    final bgColor = _parseColor(backgroundColor);

    // Process transformedImageData (could be Uint8List, List<int>, or List<dynamic>)
    Uint8List? transformedImageData;
    final dynamic rawTransformedData = content['transformedImageData'];

    if (rawTransformedData != null) {
      debugPrint(
          'Found transformedImageData of type: ${rawTransformedData.runtimeType}');

      if (rawTransformedData is Uint8List) {
        transformedImageData = rawTransformedData;
        debugPrint('Using transformedImageData as Uint8List directly');
      } else if (rawTransformedData is List<int>) {
        transformedImageData = Uint8List.fromList(rawTransformedData);
        debugPrint('Converted List<int> to Uint8List');
      } else if (rawTransformedData is List) {
        // Handle case where JSON deserialization creates a List<dynamic>
        try {
          transformedImageData = Uint8List.fromList(
              (rawTransformedData).map((dynamic item) => item as int).toList());
          debugPrint('Converted List<dynamic> to Uint8List');
        } catch (e) {
          debugPrint('Error converting List<dynamic> to Uint8List: $e');
        }
      }
    }

    // 使用Stack包装，确保事件可以穿透到控制点层
    Widget imageContent;

    // If we have transformed image data, use it
    if (transformedImageData != null) {
      debugPrint(
          'Using transformedImageData for rendering (${transformedImageData.length} bytes)');
      imageContent = Stack(
        children: [
          Positioned.fill(
            child: Container(color: bgColor),
          ),
          Positioned.fill(
            child: IgnorePointer(
              // 确保图片不拦截控制点事件
              child: Image.memory(
                transformedImageData,
                fit: fit,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading transformed image data: $error');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image,
                            size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 8),
                        Text('Error: $error',
                            style: TextStyle(color: Colors.red.shade300)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    } else {
      // If we have a transformed image URL, use it
      final effectiveImageUrl = transformedImageUrl ?? imageUrl;

      // If no image URL is available, show placeholder
      if (effectiveImageUrl.isEmpty) {
        imageContent = Stack(
          children: [
            Positioned.fill(
              child: Container(color: bgColor),
            ),
            const Positioned.fill(
              child: Center(
                child: Icon(Icons.image, size: 48, color: Colors.grey),
              ),
            ),
          ],
        );
      } else if (effectiveImageUrl.startsWith('file://')) {
        // Check if it's a local file path
        final filePath = effectiveImageUrl.substring(7);
        imageContent = Stack(
          children: [
            Positioned.fill(
              child: Container(color: bgColor),
            ),
            Positioned.fill(
              child: IgnorePointer(
                // 确保图片不拦截控制点事件
                child: CachedImage(
                  path: filePath,
                  fit: fit,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error loading file image: $error');
                    return Center(
                      child: Icon(Icons.broken_image,
                          size: 48, color: Colors.red.shade300),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      } else {
        imageContent = Stack(
          children: [
            Positioned.fill(
              child: Container(color: bgColor),
            ),
            Positioned.fill(
              child: IgnorePointer(
                // 确保图片不拦截控制点事件
                child: Image.network(
                  effectiveImageUrl,
                  fit: fit,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error loading network image: $error');
                    return Center(
                      child: Icon(Icons.broken_image,
                          size: 48, color: Colors.red.shade300),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      // 使用Material包装以确保正确的点击行为
      child: Material(
        type: MaterialType.transparency,
        child: imageContent,
      ),
    );
  }

  /// Render text element
  Widget _renderTextElement(Map<String, dynamic> element) {
    debugPrint(
        '🔍 渲染文本元素 - ID: ${element['id']}, 选中状态: ${widget.controller.state.selectedElementIds.contains(element['id'])}');
    // 添加IgnorePointer包装，确保文本元素不拦截控制点事件
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // 这里添加一个透明层来接收基本事件，但不会拦截控制点事件
          Positioned.fill(
            child: Container(color: Colors.transparent),
          ),
          // 包装原始文本元素，使其忽略指针事件，以便控制点可以接收事件
          Positioned.fill(
            child: IgnorePointer(
              // 允许文本内容显示，但不拦截控制点事件
              ignoring: widget.controller.state.selectedElementIds
                  .contains(element['id']),
              child: ElementRenderers.buildTextElement(
                element,
                isPreviewMode: widget.isPreviewMode,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Reset canvas position to the initial state
  void _resetCanvasPosition() {
    // Create an identity matrix (1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)
    final Matrix4 identityMatrix = Matrix4.identity();

    // Animate to the identity matrix (default position and scale)
    widget.transformationController.value = identityMatrix;

    // Notify the controller that zoom has changed
    final scale = widget.transformationController.value.getMaxScaleOnAxis();
    widget.controller.zoomTo(scale);

    // Update UI
    setState(() {});
  }
}

/// Custom painter for selection box
class _SelectionBoxPainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final Color color;

  _SelectionBoxPainter({
    required this.startPoint,
    required this.endPoint,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 创建选择框的矩形
    final rect = Rect.fromPoints(startPoint, endPoint);

    // 绘制半透明填充
    final fillPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // 绘制边框
    final strokePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(rect, strokePaint);

    // 绘制角落标记，增强视觉反馈
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // 边角尺寸
    const cornerSize = 6.0;

    // 左上角
    canvas.drawLine(
        rect.topLeft, rect.topLeft.translate(cornerSize, 0), cornerPaint);
    canvas.drawLine(
        rect.topLeft, rect.topLeft.translate(0, cornerSize), cornerPaint);

    // 右上角
    canvas.drawLine(
        rect.topRight, rect.topRight.translate(-cornerSize, 0), cornerPaint);
    canvas.drawLine(
        rect.topRight, rect.topRight.translate(0, cornerSize), cornerPaint);

    // 左下角
    canvas.drawLine(
        rect.bottomLeft, rect.bottomLeft.translate(cornerSize, 0), cornerPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(0, -cornerSize),
        cornerPaint);

    // 右下角
    canvas.drawLine(rect.bottomRight,
        rect.bottomRight.translate(-cornerSize, 0), cornerPaint);
    canvas.drawLine(rect.bottomRight,
        rect.bottomRight.translate(0, -cornerSize), cornerPaint);
  }

  @override
  bool shouldRepaint(_SelectionBoxPainter oldDelegate) {
    return startPoint != oldDelegate.startPoint ||
        endPoint != oldDelegate.endPoint ||
        color != oldDelegate.color;
  }
}

/// Custom painter for selection corner indicators with high contrast dual colors
class _SelectionCornerPainter extends CustomPainter {
  final Color color;
  late final Color contrastColor;

  _SelectionCornerPainter({required this.color}) {
    // Create a contrasting color - white for dark colors, black for light colors
    // Determine if the primary color is light or dark
    final brightness = ThemeData.estimateBrightnessForColor(color);
    contrastColor = brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Create two paints for the dual-color effect
    final primaryPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0;

    final contrastPaint = Paint()
      ..color = contrastColor
      ..strokeWidth = 1.0;

    // Draw corner indicators with a dual-color effect
    const cornerLength = 10.0; // Slightly longer for better visibility

    // Draw corners with dual-color effect (outer stroke first, then inner stroke)
    _drawCornerWithDualColors(canvas, const Offset(0, 0), 'top-left', size,
        primaryPaint, contrastPaint, cornerLength);
    _drawCornerWithDualColors(canvas, Offset(size.width, 0), 'top-right', size,
        primaryPaint, contrastPaint, cornerLength);
    _drawCornerWithDualColors(canvas, Offset(0, size.height), 'bottom-left',
        size, primaryPaint, contrastPaint, cornerLength);
    _drawCornerWithDualColors(canvas, Offset(size.width, size.height),
        'bottom-right', size, primaryPaint, contrastPaint, cornerLength);
  }

  @override
  bool shouldRepaint(_SelectionCornerPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.contrastColor != contrastColor;
  }

  /// Helper method to draw a corner with dual colors
  void _drawCornerWithDualColors(
      Canvas canvas,
      Offset point,
      String cornerPosition,
      Size size,
      Paint primaryPaint,
      Paint contrastPaint,
      double cornerLength) {
    // Calculate the two lines for this corner
    Offset horizontalEnd, verticalEnd;

    switch (cornerPosition) {
      case 'top-left':
        horizontalEnd = Offset(point.dx + cornerLength, point.dy);
        verticalEnd = Offset(point.dx, point.dy + cornerLength);
        break;
      case 'top-right':
        horizontalEnd = Offset(point.dx - cornerLength, point.dy);
        verticalEnd = Offset(point.dx, point.dy + cornerLength);
        break;
      case 'bottom-left':
        horizontalEnd = Offset(point.dx + cornerLength, point.dy);
        verticalEnd = Offset(point.dx, point.dy - cornerLength);
        break;
      case 'bottom-right':
        horizontalEnd = Offset(point.dx - cornerLength, point.dy);
        verticalEnd = Offset(point.dx, point.dy - cornerLength);
        break;
      default:
        return;
    }

    // Draw the outer (contrast) stroke
    canvas.drawLine(point, horizontalEnd, primaryPaint);
    canvas.drawLine(point, verticalEnd, primaryPaint);

    // Draw the inner (primary) stroke with slight offset for a dual-color effect
    const offsetAmount = 1.0;
    final offsetX =
        cornerPosition.contains('right') ? -offsetAmount : offsetAmount;
    final offsetY =
        cornerPosition.contains('bottom') ? -offsetAmount : offsetAmount;

    canvas.drawLine(point.translate(offsetX, offsetY),
        horizontalEnd.translate(0, offsetY), contrastPaint);

    canvas.drawLine(point.translate(offsetX, offsetY),
        verticalEnd.translate(offsetX, 0), contrastPaint);
  }
}
