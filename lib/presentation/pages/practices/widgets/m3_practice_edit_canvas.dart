import 'dart:io';
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
  final GlobalKey canvasKey;
  final TransformationController transformationController;

  const M3PracticeEditCanvas({
    super.key,
    required this.controller,
    required this.isPreviewMode,
    required this.canvasKey,
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
      },
    );
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
                panEnabled: widget.isPreviewMode ||
                    !_isDragging, // Enable pan in preview mode or when not dragging elements
                scaleEnabled: true,
                minScale: 0.1,
                maxScale: 15.0,
                scaleFactor:
                    200.0, // Increase scale factor to reduce zoom speed
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
                  onSecondaryTapUp: (details) =>
                      _gestureHandler.handleSecondaryTapUp(
                          details, elements.cast<Map<String, dynamic>>()),
                  onPanStart: (details) => _gestureHandler.handlePanStart(
                      details, elements.cast<Map<String, dynamic>>()),
                  onPanUpdate: (details) {
                    // If not dragging elements and not in preview mode, handle panning directly
                    if (!_isDragging && !widget.isPreviewMode) {
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
                          .getTranslation();

                      // Set new translation
                      newMatrix.setTranslation(Vector3(
                        translation.x + details.delta.dx,
                        translation.y + details.delta.dy,
                        0.0,
                      ));

                      widget.transformationController.value = newMatrix;

                      // Force refresh
                      setState(() {});
                    }

                    // Call original handlePanUpdate
                    _gestureHandler.handlePanUpdate(details);
                  },
                  onPanEnd: (details) => _gestureHandler.handlePanEnd(details),
                  child: _buildPageContent(currentPage,
                      elements.cast<Map<String, dynamic>>(), colorScheme),
                ),
              ),
            ),

            // Status bar showing zoom level (only visible in edit mode)
            if (!widget.isPreviewMode)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  color: colorScheme.surface.withOpacity(0.85),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.center_focus_strong,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context)
                                        .canvasResetView,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Zoom indicator
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.zoom_in,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$zoomPercentage%',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
    // Use absolute positioning for control points to ensure they're always visible
    return AbsorbPointer(
      absorbing: false, // Ensure control points can receive events
      child: GestureDetector(
        // onTapDown: (details) {},
        // onTap: () {
        //   // Clear selection when tapping on empty area
        //   // widget.controller.clearSelection();
        // },
        child: Stack(
          children: [
            // Transparent overlay to ensure control points receive events
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
              ),
            ),

            // Actual control points
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: RepaintBoundary(
                child: CanvasControlPoints(
                  key: ValueKey('control_points_$elementId'),
                  elementId: elementId,
                  x: x,
                  y: y,
                  width: width,
                  height: height,
                  rotation: rotation,
                  onControlPointUpdate: _handleControlPointUpdate,
                ),
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

    if (widget.controller.state.selectedElementIds.length == 1) {
      selectedElementId = widget.controller.state.selectedElementIds.first;
      final selectedElement = elements.firstWhere(
        (e) => e['id'] == selectedElementId,
        orElse: () => <String, dynamic>{},
      );

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
            key: widget.canvasKey,
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
                    final elementOpacity =
                        (element['opacity'] as num?)?.toDouble() ?? 1.0;
                    final isLocked = element['locked'] as bool? ?? false;
                    debugPrint('元素锁定状态: id=${element['id']}, locked=$isLocked');
                    final isSelected =
                        widget.controller.state.selectedElementIds.contains(id);

                    // Get layer visibility and lock status
                    final layerId = element['layerId'] as String?;
                    final isLayerVisible = layerId == null ||
                        widget.controller.state.isLayerVisible(layerId);
                    final isLayerLocked = layerId != null &&
                        widget.controller.state.isLayerLocked(layerId);

                    // 添加调试信息
                    if (isLayerLocked) {
                      debugPrint(
                          '图层锁定: 元素id=${element['id']}, 图层id=$layerId, 图层锁定=$isLayerLocked');
                    }

                    // Skip elements on hidden layers
                    if (!isLayerVisible) return const SizedBox.shrink();

                    // Log element properties for debugging
                    if (element['type'] == 'image') {
                      debugPrint(
                          'Rendering image element: id=$id, opacity=$elementOpacity, hidden=${element['hidden']}');
                    }

                    // Render element
                    return Positioned(
                      left: elementX,
                      top: elementY,
                      child: Transform.rotate(
                        angle: elementRotation *
                            (3.14159265359 / 180), // Convert degrees to radians
                        child: Opacity(
                          opacity: elementOpacity, // Apply element opacity
                          child: Container(
                            width: elementWidth,
                            height: elementHeight,
                            decoration: !widget.isPreviewMode && isSelected
                                ? BoxDecoration(
                                    border: Border.all(
                                      color: isLocked
                                          ? colorScheme.tertiary
                                          : colorScheme.primary,
                                      width: 2.0, // 增加边框宽度，从 1.0 改为 2.0
                                      style: BorderStyle.solid,
                                    ),
                                    // 添加半透明背景色，提高可视性
                                    color: (isLocked
                                            ? colorScheme.tertiary
                                            : colorScheme.primary)
                                        .withOpacity(0.08),
                                  )
                                : null,
                            child: Stack(
                              children: [
                                // Element content
                                _renderElement(element),

                                // 为选中元素添加角落指示器，增强选中状态的可见性
                                if (!widget.isPreviewMode && isSelected)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _SelectionCornerPainter(
                                        color: isLocked
                                            ? colorScheme.tertiary
                                            : colorScheme.surfaceBright,
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
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),

        // Control points for selected element (only in edit mode and when one element is selected)
        if (!widget.isPreviewMode && selectedElementId != null)
          Positioned.fill(
            child: _buildControlPoints(
                selectedElementId, x, y, width, height, rotation),
          ),
      ],
    );
  }

  /// Get BoxFit from fitMode string
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

  // /// Get BoxFit from fitMode string
  // BoxFit _getFitMode(String fitMode) {
  //   switch (fitMode) {
  //     case 'contain':
  //       return BoxFit.contain;
  //     case 'cover':
  //       return BoxFit.cover;
  //     case 'fill':
  //       return BoxFit.fill;
  //     case 'none':
  //       return BoxFit.none;
  //     default:
  //       return BoxFit.contain;
  //   }
  // }

  /// Handle control point updates
  void _handleControlPointUpdate(int controlPointIndex, Offset delta) {
    // Add more debug info to understand control point behavior
    final scale = widget.transformationController.value.getMaxScaleOnAxis();

    // Adjust offset based on current scale
    final adjustedDelta = Offset(delta.dx / scale, delta.dy / scale);

    // Use adjusted offset
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
    }

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
    }

    // 确保最小尺寸
    width = width.clamp(10.0, double.infinity);
    height = height.clamp(10.0, double.infinity);

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
        'Rotating element $elementId: delta=$delta, rotationDelta=$rotationDelta, newRotation=$newRotation');

    // Update rotation
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

    // If we have transformed image data, use it
    if (transformedImageData != null) {
      debugPrint(
          'Using transformedImageData for rendering (${transformedImageData.length} bytes)');
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: bgColor,
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
      );
    }

    // If we have a transformed image URL, use it
    final effectiveImageUrl = transformedImageUrl ?? imageUrl;

    // If no image URL is available, show placeholder
    if (effectiveImageUrl.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: bgColor,
        child: const Center(
          child: Icon(Icons.image, size: 48, color: Colors.grey),
        ),
      );
    }

    // Check if it's a local file path
    if (effectiveImageUrl.startsWith('file://')) {
      final filePath = effectiveImageUrl.substring(7);
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: bgColor,
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
      );
    } else {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: bgColor,
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
      );
    }
  }

  /// Render text element
  Widget _renderTextElement(Map<String, dynamic> element) {
    // Use the ElementRenderers.buildTextElement method to ensure all text formatting properties are applied
    return ElementRenderers.buildTextElement(element,
        isPreviewMode: widget.isPreviewMode);
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

/// Custom painter for selection corner indicators
class _SelectionCornerPainter extends CustomPainter {
  final Color color;

  _SelectionCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const double cornerLength = 10.0;

    // Draw corners
    // Top-left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Top-right
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-left
    canvas.drawLine(
        Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
