import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../infrastructure/image/dynamic_image_bounds.dart';
import '../../../../../infrastructure/image/image_transform_coordinator.dart';
import '../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../../utils/config/edit_page_logging_config.dart';

/// Interactive crop selection overlay with 8 control points
class InteractiveCropOverlay extends StatefulWidget {
  final Size imageSize;
  final Size renderSize;
  final double cropX; // Left edge of crop area in pixels
  final double cropY; // Top edge of crop area in pixels
  final double cropWidth; // Width of crop area in pixels
  final double cropHeight; // Height of crop area in pixels
  final double contentRotation; // Rotation angle in degrees
  final bool flipHorizontal; // Horizontal flip state
  final bool flipVertical; // Vertical flip state
  final Function(double, double, double, double, {bool isDragging})
      onCropChanged; // (x, y, width, height, isDragging)
  final bool enabled;

  const InteractiveCropOverlay({
    super.key,
    required this.imageSize,
    required this.renderSize,
    required this.cropX,
    required this.cropY,
    required this.cropWidth,
    required this.cropHeight,
    required this.contentRotation,
    this.flipHorizontal = false,
    this.flipVertical = false,
    required this.onCropChanged,
    this.enabled = true,
  });

  @override
  State<InteractiveCropOverlay> createState() => _InteractiveCropOverlayState();
}

class _InteractiveCropOverlayState extends State<InteractiveCropOverlay> {
  late double _currentCropX;
  late double _currentCropY;
  late double _currentCropWidth;
  late double _currentCropHeight;

  _DragHandle? _activeDragHandle;
  Offset? _lastPanPosition;
  
  // 动态边界坐标协调器
  late ImageTransformCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    _initializeCoordinator();
    _updateCurrentCropValues();
  }

  @override
  void didUpdateWidget(InteractiveCropOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    EditPageLogger.propertyPanelDebug(
      'InteractiveCropOverlay didUpdateWidget',
      tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
      data: {
        'oldValues': {
          'cropX': oldWidget.cropX.toStringAsFixed(1),
          'cropY': oldWidget.cropY.toStringAsFixed(1),
          'cropWidth': oldWidget.cropWidth.toStringAsFixed(1),
          'cropHeight': oldWidget.cropHeight.toStringAsFixed(1),
        },
        'newValues': {
          'cropX': widget.cropX.toStringAsFixed(1),
          'cropY': widget.cropY.toStringAsFixed(1),
          'cropWidth': widget.cropWidth.toStringAsFixed(1),
          'cropHeight': widget.cropHeight.toStringAsFixed(1),
        },
        'hasChanged': oldWidget.cropX != widget.cropX ||
            oldWidget.cropY != widget.cropY ||
            oldWidget.cropWidth != widget.cropWidth ||
            oldWidget.cropHeight != widget.cropHeight,
        'transformsChanged': oldWidget.contentRotation != widget.contentRotation ||
            oldWidget.flipHorizontal != widget.flipHorizontal ||
            oldWidget.flipVertical != widget.flipVertical,
      },
    );

    // 检查是否需要重新初始化坐标协调器
    if (oldWidget.contentRotation != widget.contentRotation ||
        oldWidget.flipHorizontal != widget.flipHorizontal ||
        oldWidget.flipVertical != widget.flipVertical ||
        oldWidget.imageSize != widget.imageSize) {
      _initializeCoordinator();
    }

    // 始终更新本地状态以确保同步
    if (oldWidget.cropX != widget.cropX ||
        oldWidget.cropY != widget.cropY ||
        oldWidget.cropWidth != widget.cropWidth ||
        oldWidget.cropHeight != widget.cropHeight) {
      print('=== 检测到外部状态变化，更新本地状态 ===');
      print(
          '变化: cropX ${oldWidget.cropX.toStringAsFixed(1)} -> ${widget.cropX.toStringAsFixed(1)}');
      print(
          '变化: cropY ${oldWidget.cropY.toStringAsFixed(1)} -> ${widget.cropY.toStringAsFixed(1)}');
      print(
          '变化: cropWidth ${oldWidget.cropWidth.toStringAsFixed(1)} -> ${widget.cropWidth.toStringAsFixed(1)}');
      print(
          '变化: cropHeight ${oldWidget.cropHeight.toStringAsFixed(1)} -> ${widget.cropHeight.toStringAsFixed(1)}');

      _updateCurrentCropValues();

      print('更新后本地状态:');
      print('_currentCropX: ${_currentCropX.toStringAsFixed(1)}');
      print('_currentCropY: ${_currentCropY.toStringAsFixed(1)}');
      print('_currentCropWidth: ${_currentCropWidth.toStringAsFixed(1)}');
      print('_currentCropHeight: ${_currentCropHeight.toStringAsFixed(1)}');
    }
  }

  void _initializeCoordinator() {
    _coordinator = ImageTransformCoordinator(
      originalImageSize: widget.imageSize,
      rotation: widget.contentRotation * (math.pi / 180.0), // 转换为弧度
      flipHorizontal: widget.flipHorizontal,
      flipVertical: widget.flipVertical,
    );
  }

  void _updateCurrentCropValues() {
    _currentCropX = widget.cropX;
    _currentCropY = widget.cropY;
    _currentCropWidth = widget.cropWidth;
    _currentCropHeight = widget.cropHeight;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          cursor: _getCursorForPosition(constraints.biggest),
          child: GestureDetector(
            onPanStart: widget.enabled ? _onPanStart : null,
            onPanUpdate: widget.enabled ? _onPanUpdate : null,
            onPanEnd: widget.enabled ? _onPanEnd : null,
            child: CustomPaint(
              painter: InteractiveCropPainter(
                context: context,
                imageSize: widget.imageSize,
                renderSize: widget.renderSize,
                cropX: _currentCropX,
                cropY: _currentCropY,
                cropWidth: _currentCropWidth,
                cropHeight: _currentCropHeight,
                contentRotation: widget.contentRotation,
                flipHorizontal: widget.flipHorizontal,
                flipVertical: widget.flipVertical,
                containerSize: constraints.biggest,
              ),
              size: constraints.biggest,
            ),
          ),
        );
      },
    );
  }

  MouseCursor _getCursorForPosition(Size containerSize) {
    // This would need to be enhanced with actual mouse position tracking
    // For now, return default cursor
    return SystemMouseCursors.precise;
  }

  void _onPanStart(DragStartDetails details) {
    final containerSize = context.size!;
    _activeDragHandle =
        _getHandleAtPosition(details.localPosition, containerSize);
    _lastPanPosition = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeDragHandle == null || _lastPanPosition == null) return;

    final containerSize = context.size!;
    final delta = details.localPosition - _lastPanPosition!;
    _lastPanPosition = details.localPosition;

    // 记录拖拽前的值
    final oldCropX = _currentCropX;
    final oldCropY = _currentCropY;
    final oldCropWidth = _currentCropWidth;
    final oldCropHeight = _currentCropHeight;

    _updateCropFromDrag(_activeDragHandle!, delta, containerSize);

    // 记录拖拽后的值变化
    EditPageLogger.propertyPanelDebug(
      '裁剪拖拽更新',
      tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
      data: {
        'handle': _activeDragHandle.toString(),
        'delta':
            '${delta.dx.toStringAsFixed(2)}, ${delta.dy.toStringAsFixed(2)}',
        'before': {
          'x': oldCropX.toStringAsFixed(1),
          'y': oldCropY.toStringAsFixed(1),
          'width': oldCropWidth.toStringAsFixed(1),
          'height': oldCropHeight.toStringAsFixed(1),
        },
        'after': {
          'x': _currentCropX.toStringAsFixed(1),
          'y': _currentCropY.toStringAsFixed(1),
          'width': _currentCropWidth.toStringAsFixed(1),
          'height': _currentCropHeight.toStringAsFixed(1),
        },
        'containerSize':
            '${containerSize.width.toStringAsFixed(1)}x${containerSize.height.toStringAsFixed(1)}',
      },
    );

    // 实时更新父组件状态 - 标记为拖动中
    EditPageLogger.propertyPanelDebug(
      '调用 onCropChanged (拖拽中)',
      tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
      data: {
        'x': _currentCropX.toStringAsFixed(1),
        'y': _currentCropY.toStringAsFixed(1),
        'width': _currentCropWidth.toStringAsFixed(1),
        'height': _currentCropHeight.toStringAsFixed(1),
        'isDragging': true,
      },
    );

    widget.onCropChanged(
      _currentCropX,
      _currentCropY,
      _currentCropWidth,
      _currentCropHeight,
      isDragging: true,
    );
  }

  void _onPanEnd(DragEndDetails details) {
    EditPageLogger.propertyPanelDebug(
      '拖拽结束',
      tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
      data: {
        'handle': _activeDragHandle.toString(),
        'finalValues': {
          'x': _currentCropX.toStringAsFixed(1),
          'y': _currentCropY.toStringAsFixed(1),
          'width': _currentCropWidth.toStringAsFixed(1),
          'height': _currentCropHeight.toStringAsFixed(1),
        },
      },
    );

    _activeDragHandle = null;
    _lastPanPosition = null;

    // 最终确认更新父组件状态 - 标记为拖动结束
    EditPageLogger.propertyPanelDebug(
      '调用 onCropChanged (拖拽结束)',
      tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
      data: {
        'x': _currentCropX.toStringAsFixed(1),
        'y': _currentCropY.toStringAsFixed(1),
        'width': _currentCropWidth.toStringAsFixed(1),
        'height': _currentCropHeight.toStringAsFixed(1),
        'isDragging': false,
      },
    );

    widget.onCropChanged(
      _currentCropX,
      _currentCropY,
      _currentCropWidth,
      _currentCropHeight,
      isDragging: false,
    );

    // 确保下一帧后同步状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // 强制重建以同步状态
        });
      }
    });
  }

  _DragHandle? _getHandleAtPosition(Offset position, Size containerSize) {
    // Apply inverse rotation to position if image is rotated
    Offset adjustedPosition = position;
    if (widget.contentRotation != 0.0) {
      final scaleX = containerSize.width / widget.imageSize.width;
      final scaleY = containerSize.height / widget.imageSize.height;
      final scale = math.min(scaleX, scaleY);

      final scaledImageWidth = widget.imageSize.width * scale;
      final scaledImageHeight = widget.imageSize.height * scale;
      final offsetX = (containerSize.width - scaledImageWidth) / 2;
      final offsetY = (containerSize.height - scaledImageHeight) / 2;
      final imageCenter = Offset(
        offsetX + scaledImageWidth / 2,
        offsetY + scaledImageHeight / 2,
      );

      final rotationRadians =
          -widget.contentRotation * math.pi / 180; // Inverse rotation

      // Translate to origin (image center)
      final translatedPosition = Offset(
        position.dx - imageCenter.dx,
        position.dy - imageCenter.dy,
      );

      // Apply inverse rotation
      final cos = math.cos(rotationRadians);
      final sin = math.sin(rotationRadians);
      final rotatedPosition = Offset(
        translatedPosition.dx * cos - translatedPosition.dy * sin,
        translatedPosition.dx * sin + translatedPosition.dy * cos,
      );

      // Translate back
      adjustedPosition = Offset(
        rotatedPosition.dx + imageCenter.dx,
        rotatedPosition.dy + imageCenter.dy,
      );
    }

    final cropRect = _calculateCropRect(containerSize);
    const handleSize = 16.0; // 增加句柄大小以便更容易点击

    final handles = _getHandlePositions(cropRect);

    // 首先检测句柄，角落句柄优先级更高
    final cornerHandles = [
      _DragHandle.topLeft,
      _DragHandle.topRight,
      _DragHandle.bottomLeft,
      _DragHandle.bottomRight,
    ];

    // 优先检测角落句柄
    for (final handleType in cornerHandles) {
      final handleCenter = handles[handleType];
      if (handleCenter != null) {
        final handleRect = Rect.fromCenter(
          center: handleCenter,
          width: handleSize,
          height: handleSize,
        );
        if (handleRect.contains(adjustedPosition)) {
          return handleType;
        }
      }
    }

    // 然后检测边缘句柄
    for (final entry in handles.entries) {
      if (cornerHandles.contains(entry.key)) continue; // 跳过已检测的角落句柄

      final handleRect = Rect.fromCenter(
        center: entry.value,
        width: handleSize,
        height: handleSize,
      );
      if (handleRect.contains(adjustedPosition)) {
        return entry.key;
      }
    }

    // Check if inside crop area for moving
    if (cropRect.contains(adjustedPosition)) {
      return _DragHandle.move;
    }

    return null;
  }

  Map<_DragHandle, Offset> _getHandlePositions(Rect cropRect) {
    return {
      _DragHandle.topLeft: cropRect.topLeft,
      _DragHandle.topCenter: Offset(cropRect.center.dx, cropRect.top),
      _DragHandle.topRight: cropRect.topRight,
      _DragHandle.centerLeft: Offset(cropRect.left, cropRect.center.dy),
      _DragHandle.centerRight: Offset(cropRect.right, cropRect.center.dy),
      _DragHandle.bottomLeft: cropRect.bottomLeft,
      _DragHandle.bottomCenter: Offset(cropRect.center.dx, cropRect.bottom),
      _DragHandle.bottomRight: cropRect.bottomRight,
    };
  }

  Rect _calculateCropRect(Size containerSize) {
    // 🔧 使用动态边界坐标系统
    // 将原始图像坐标系的裁剪区域转换为动态边界坐标系
    final dynamicCropParams = _coordinator.originalToDynamicCropParams(
      cropX: _currentCropX,
      cropY: _currentCropY,
      cropWidth: _currentCropWidth,
      cropHeight: _currentCropHeight,
    );
    
    final dynamicCropRect = Rect.fromLTWH(
      dynamicCropParams['cropX']!,
      dynamicCropParams['cropY']!,
      dynamicCropParams['cropWidth']!,
      dynamicCropParams['cropHeight']!,
    );
    
    // 验证并调整动态边界中的裁剪区域
    final clampedDynamicRect = _coordinator.clampDynamicCropRect(dynamicCropRect);
    
    // 将动态边界坐标转换为显示坐标
    final dynamicBounds = _coordinator.dynamicBounds;
    
    // Calculate scale for dynamic bounds in container - 使用contain模式
    final scaleX = containerSize.width / dynamicBounds.width;
    final scaleY = containerSize.height / dynamicBounds.height;
    final scale = math.min(scaleX, scaleY);

    final scaledDynamicWidth = dynamicBounds.width * scale;
    final scaledDynamicHeight = dynamicBounds.height * scale;

    final offsetX = (containerSize.width - scaledDynamicWidth) / 2;
    final offsetY = (containerSize.height - scaledDynamicHeight) / 2;

    // Convert dynamic crop coordinates to display coordinates
    final displayCropRect = Rect.fromLTWH(
      offsetX + (clampedDynamicRect.left * scale),
      offsetY + (clampedDynamicRect.top * scale),
      clampedDynamicRect.width * scale,
      clampedDynamicRect.height * scale,
    );

    return displayCropRect;
  }

  void _updateCropFromDrag(
      _DragHandle handle, Offset delta, Size containerSize) {
    // 🔧 使用动态边界坐标系统计算拖拽变换
    final dynamicBounds = _coordinator.dynamicBounds;
    
    // Calculate scale for dynamic bounds in container
    final scaleX = containerSize.width / dynamicBounds.width;
    final scaleY = containerSize.height / dynamicBounds.height;
    final scale = math.min(scaleX, scaleY);

    // Convert screen delta to dynamic boundary coordinate delta
    final deltaX = delta.dx / scale;
    final deltaY = delta.dy / scale;

    // Define minimum crop area (e.g., 10x10 pixels in dynamic coordinates)
    const minCropSize = 10.0;

    setState(() {
      // 获取当前在动态边界坐标系中的裁剪参数
      final currentDynamicCropParams = _coordinator.originalToDynamicCropParams(
        cropX: _currentCropX,
        cropY: _currentCropY,
        cropWidth: _currentCropWidth,
        cropHeight: _currentCropHeight,
      );
      
      // Calculate new crop values in dynamic boundary coordinates
      double newDynamicCropX = currentDynamicCropParams['cropX']!;
      double newDynamicCropY = currentDynamicCropParams['cropY']!;
      double newDynamicCropWidth = currentDynamicCropParams['cropWidth']!;
      double newDynamicCropHeight = currentDynamicCropParams['cropHeight']!;

      switch (handle) {
        case _DragHandle.topLeft:
          // Moving top-left corner: adjust x, y, width, height
          newDynamicCropX = currentDynamicCropParams['cropX']! + deltaX;
          newDynamicCropY = currentDynamicCropParams['cropY']! + deltaY;
          newDynamicCropWidth = currentDynamicCropParams['cropWidth']! - deltaX;
          newDynamicCropHeight = currentDynamicCropParams['cropHeight']! - deltaY;
          break;
        case _DragHandle.topCenter:
          // Moving top edge: adjust y and height
          newDynamicCropY = currentDynamicCropParams['cropY']! + deltaY;
          newDynamicCropHeight = currentDynamicCropParams['cropHeight']! - deltaY;
          break;
        case _DragHandle.topRight:
          // Moving top-right corner: adjust y, width, height
          newDynamicCropY = currentDynamicCropParams['cropY']! + deltaY;
          newDynamicCropWidth = currentDynamicCropParams['cropWidth']! + deltaX;
          newDynamicCropHeight = currentDynamicCropParams['cropHeight']! - deltaY;
          break;
        case _DragHandle.centerLeft:
          // Moving left edge: adjust x and width
          newDynamicCropX = currentDynamicCropParams['cropX']! + deltaX;
          newDynamicCropWidth = currentDynamicCropParams['cropWidth']! - deltaX;
          break;
        case _DragHandle.centerRight:
          // Moving right edge: adjust width
          newDynamicCropWidth = currentDynamicCropParams['cropWidth']! + deltaX;
          break;
        case _DragHandle.bottomLeft:
          // Moving bottom-left corner: adjust x, width, height
          newDynamicCropX = currentDynamicCropParams['cropX']! + deltaX;
          newDynamicCropWidth = currentDynamicCropParams['cropWidth']! - deltaX;
          newDynamicCropHeight = currentDynamicCropParams['cropHeight']! + deltaY;
          break;
        case _DragHandle.bottomCenter:
          // Moving bottom edge: adjust height
          newDynamicCropHeight = currentDynamicCropParams['cropHeight']! + deltaY;
          break;
        case _DragHandle.bottomRight:
          // Moving bottom-right corner: adjust width and height
          newDynamicCropWidth = currentDynamicCropParams['cropWidth']! + deltaX;
          newDynamicCropHeight = currentDynamicCropParams['cropHeight']! + deltaY;
          break;
        case _DragHandle.move:
          // Move entire crop area: adjust x and y, keep width and height
          newDynamicCropX = currentDynamicCropParams['cropX']! + deltaX;
          newDynamicCropY = currentDynamicCropParams['cropY']! + deltaY;
          break;
      }

      // Validate dynamic boundary crop area
      final dynamicRect = Rect.fromLTWH(
        newDynamicCropX, 
        newDynamicCropY, 
        newDynamicCropWidth, 
        newDynamicCropHeight
      );
      final clampedDynamicRect = _coordinator.clampDynamicCropRect(dynamicRect);
      
      // Convert back to original image coordinates
      final originalCropParams = _coordinator.dynamicToOriginalCropParams(
        cropX: clampedDynamicRect.left,
        cropY: clampedDynamicRect.top,
        cropWidth: clampedDynamicRect.width,
        cropHeight: clampedDynamicRect.height,
      );

      _currentCropX = originalCropParams['cropX']!;
      _currentCropY = originalCropParams['cropY']!;
      _currentCropWidth = originalCropParams['cropWidth']!;
      _currentCropHeight = originalCropParams['cropHeight']!;
    });
}
}

enum _DragHandle {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
  move,
}

/// Custom painter for the interactive crop overlay
class InteractiveCropPainter extends CustomPainter {
  final BuildContext context;
  final Size imageSize;
  final Size renderSize;
  final double cropX; // Left edge of crop area in pixels
  final double cropY; // Top edge of crop area in pixels
  final double cropWidth; // Width of crop area in pixels
  final double cropHeight; // Height of crop area in pixels
  final double contentRotation; // Rotation angle in degrees
  final bool flipHorizontal; // Horizontal flip state
  final bool flipVertical; // Vertical flip state
  final Size containerSize;

  const InteractiveCropPainter({
    required this.context,
    required this.imageSize,
    required this.renderSize,
    required this.cropX,
    required this.cropY,
    required this.cropWidth,
    required this.cropHeight,
    required this.contentRotation,
    this.flipHorizontal = false,
    this.flipVertical = false,
    required this.containerSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 🔧 使用动态边界坐标系统
    final coordinator = ImageTransformCoordinator(
      originalImageSize: imageSize,
      rotation: contentRotation * (math.pi / 180.0), // 转换为弧度
      flipHorizontal: flipHorizontal,
      flipVertical: flipVertical,
    );

    // 将原始图像坐标系的裁剪区域转换为动态边界坐标系
    final dynamicCropParams = coordinator.originalToDynamicCropParams(
      cropX: cropX,
      cropY: cropY,
      cropWidth: cropWidth,
      cropHeight: cropHeight,
    );
    
    final dynamicCropRect = Rect.fromLTWH(
      dynamicCropParams['cropX']!,
      dynamicCropParams['cropY']!,
      dynamicCropParams['cropWidth']!,
      dynamicCropParams['cropHeight']!,
    );
    
    // 验证并调整动态边界中的裁剪区域
    final clampedDynamicRect = coordinator.clampDynamicCropRect(dynamicCropRect);
    
    // 获取动态边界大小
    final dynamicBounds = coordinator.dynamicBounds;
    
    // Calculate scale for dynamic bounds in container
    final scaleX = size.width / dynamicBounds.width;
    final scaleY = size.height / dynamicBounds.height;
    final scale = math.min(scaleX, scaleY);

    final scaledDynamicWidth = dynamicBounds.width * scale;
    final scaledDynamicHeight = dynamicBounds.height * scale;

    final offsetX = (size.width - scaledDynamicWidth) / 2;
    final offsetY = (size.height - scaledDynamicHeight) / 2;

    // Dynamic bounds display rectangle
    final dynamicBoundsRect = Rect.fromLTWH(offsetX, offsetY, scaledDynamicWidth, scaledDynamicHeight);

    // Convert dynamic crop coordinates to display coordinates
    final displayCropRect = Rect.fromLTWH(
      offsetX + (clampedDynamicRect.left * scale),
      offsetY + (clampedDynamicRect.top * scale),
      clampedDynamicRect.width * scale,
      clampedDynamicRect.height * scale,
    );

    if (displayCropRect.width > 0 && displayCropRect.height > 0) {
      // Draw mask over non-cropped areas
      final maskPaint = Paint()
        ..color = Colors.black.withAlpha(100)
        ..style = PaintingStyle.fill;

      final maskPath = Path()..addRect(dynamicBoundsRect);
      maskPath.addRect(displayCropRect);
      maskPath.fillType = PathFillType.evenOdd;

      canvas.drawPath(maskPath, maskPaint);

      // Draw crop area border
      final borderPaint = Paint()
        ..color = colorScheme.primary
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawRect(displayCropRect, borderPaint);

      // Draw grid lines
      final gridPaint = Paint()
        ..color = colorScheme.primary.withAlpha(150)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      // Horizontal grid lines
      final gridHeight = displayCropRect.height / 3;
      canvas.drawLine(
        Offset(displayCropRect.left, displayCropRect.top + gridHeight),
        Offset(displayCropRect.right, displayCropRect.top + gridHeight),
        gridPaint,
      );
      canvas.drawLine(
        Offset(displayCropRect.left, displayCropRect.top + gridHeight * 2),
        Offset(displayCropRect.right, displayCropRect.top + gridHeight * 2),
        gridPaint,
      );

      // Vertical grid lines
      final gridWidth = displayCropRect.width / 3;
      canvas.drawLine(
        Offset(displayCropRect.left + gridWidth, displayCropRect.top),
        Offset(displayCropRect.left + gridWidth, displayCropRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(displayCropRect.left + gridWidth * 2, displayCropRect.top),
        Offset(displayCropRect.left + gridWidth * 2, displayCropRect.bottom),
        gridPaint,
      );

      // Draw 8 control handles
      const handleSize = 16.0; // 与检测大小保持一致

      final handleBorderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final handles = [
        // Corner handles (larger and more prominent)
        displayCropRect.topLeft,
        displayCropRect.topRight,
        displayCropRect.bottomLeft,
        displayCropRect.bottomRight,
        // Edge handles
        Offset(displayCropRect.center.dx, displayCropRect.top),
        Offset(displayCropRect.center.dx, displayCropRect.bottom),
        Offset(displayCropRect.left, displayCropRect.center.dy),
        Offset(displayCropRect.right, displayCropRect.center.dy),
      ];

      for (int i = 0; i < handles.length; i++) {
        final handleCenter = handles[i];
        final isCornerHandle = i < 4; // 前4个是角落句柄

        final currentHandleSize =
            isCornerHandle ? handleSize : handleSize * 0.8;

        final handleRect = Rect.fromCenter(
          center: handleCenter,
          width: currentHandleSize,
          height: currentHandleSize,
        );

        // Draw handle background (white border)
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            handleRect,
            Radius.circular(isCornerHandle ? 3 : 2),
          ),
          handleBorderPaint,
        );

        // Draw handle fill with different colors for corners
        final fillPaint = Paint()
          ..color = isCornerHandle ? colorScheme.primary : colorScheme.secondary
          ..style = PaintingStyle.fill;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            handleRect,
            Radius.circular(isCornerHandle ? 3 : 2),
          ),
          fillPaint,
        );
      }

      // Draw crop area dimensions (if crop area is reasonably large)
      if (displayCropRect.width > 60 && displayCropRect.height > 40) {
        final dimensionText = '${cropWidth.round()}x${cropHeight.round()}';

        final textPainter = TextPainter(
          text: TextSpan(
            text: dimensionText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withAlpha(150),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        // Position text in the center of crop area
        final textPosition = Offset(
          displayCropRect.center.dx - textPainter.width / 2,
          displayCropRect.center.dy - textPainter.height / 2,
        );

        textPainter.paint(canvas, textPosition);
      }
    }
  }

  @override
  bool shouldRepaint(InteractiveCropPainter oldDelegate) {
    return imageSize != oldDelegate.imageSize ||
        renderSize != oldDelegate.renderSize ||
        cropX != oldDelegate.cropX ||
        cropY != oldDelegate.cropY ||
        cropWidth != oldDelegate.cropWidth ||
        cropHeight != oldDelegate.cropHeight ||
        contentRotation != oldDelegate.contentRotation ||
        flipHorizontal != oldDelegate.flipHorizontal ||
        flipVertical != oldDelegate.flipVertical ||
        containerSize != oldDelegate.containerSize;
  }
}
