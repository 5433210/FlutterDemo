import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Interactive crop selection overlay with 8 control points
class InteractiveCropOverlay extends StatefulWidget {
  final Size imageSize;
  final Size renderSize;
  final double cropX;       // Left edge of crop area in pixels
  final double cropY;       // Top edge of crop area in pixels  
  final double cropWidth;   // Width of crop area in pixels
  final double cropHeight;  // Height of crop area in pixels
  final double contentRotation; // Rotation angle in degrees
  final Function(double, double, double, double) onCropChanged; // (x, y, width, height)
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
  bool _isDragging = false;  // 添加拖动状态标识

  @override
  void initState() {
    super.initState();
    _updateCurrentCropValues();
  }

  @override
  void didUpdateWidget(InteractiveCropOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有在不处于拖动状态时才更新本地状态
    if (!_isDragging &&
        (oldWidget.cropX != widget.cropX ||
        oldWidget.cropY != widget.cropY ||
        oldWidget.cropWidth != widget.cropWidth ||
        oldWidget.cropHeight != widget.cropHeight)) {
      _updateCurrentCropValues();
    }
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
    _activeDragHandle = _getHandleAtPosition(details.localPosition, containerSize);
    _lastPanPosition = details.localPosition;
    _isDragging = true;  // 设置拖动状态
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeDragHandle == null || _lastPanPosition == null) return;

    final containerSize = context.size!;
    final delta = details.localPosition - _lastPanPosition!;
    _lastPanPosition = details.localPosition;

    _updateCropFromDrag(_activeDragHandle!, delta, containerSize);
    
    // 实时更新父组件状态
    widget.onCropChanged(
      _currentCropX,
      _currentCropY,
      _currentCropWidth,
      _currentCropHeight,
    );
  }

  void _onPanEnd(DragEndDetails details) {
    _activeDragHandle = null;
    _lastPanPosition = null;
    _isDragging = false;  // 清除拖动状态
    
    // 最终确认更新父组件状态
    widget.onCropChanged(
      _currentCropX,
      _currentCropY,
      _currentCropWidth,
      _currentCropHeight,
    );
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

      final rotationRadians = -widget.contentRotation * math.pi / 180; // Inverse rotation
      
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
    const handleSize = 12.0;
    
    final handles = _getHandlePositions(cropRect);
    
    for (final entry in handles.entries) {
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
    // Calculate scale for image in container
    final scaleX = containerSize.width / widget.imageSize.width;
    final scaleY = containerSize.height / widget.imageSize.height;
    final scale = math.min(scaleX, scaleY);

    final scaledImageWidth = widget.imageSize.width * scale;
    final scaledImageHeight = widget.imageSize.height * scale;

    final offsetX = (containerSize.width - scaledImageWidth) / 2;
    final offsetY = (containerSize.height - scaledImageHeight) / 2;

    final imageRect = Rect.fromLTWH(offsetX, offsetY, scaledImageWidth, scaledImageHeight);

    // Convert crop coordinates from image pixels to display coordinates
    // Scale factor: display pixels per image pixel
    final imageToDisplayScale = scale;

    final cropLeft = imageRect.left + (_currentCropX * imageToDisplayScale);
    final cropTop = imageRect.top + (_currentCropY * imageToDisplayScale);
    final cropWidth = _currentCropWidth * imageToDisplayScale;
    final cropHeight = _currentCropHeight * imageToDisplayScale;

    final cropRect = Rect.fromLTWH(cropLeft, cropTop, cropWidth, cropHeight);

    // Apply rotation transform if needed
    if (widget.contentRotation != 0.0) {
      final rotationRadians = widget.contentRotation * math.pi / 180;
      final imageCenter = imageRect.center;
      
      // Calculate the rotated crop rectangle corners
      final cropCenter = cropRect.center;
      
      // Translate to origin (image center)
      final translatedCropCenter = Offset(
        cropCenter.dx - imageCenter.dx,
        cropCenter.dy - imageCenter.dy,
      );
      
      // Apply rotation
      final cos = math.cos(rotationRadians);
      final sin = math.sin(rotationRadians);
      final rotatedCropCenter = Offset(
        translatedCropCenter.dx * cos - translatedCropCenter.dy * sin,
        translatedCropCenter.dx * sin + translatedCropCenter.dy * cos,
      );
      
      // Translate back
      final finalCropCenter = Offset(
        rotatedCropCenter.dx + imageCenter.dx,
        rotatedCropCenter.dy + imageCenter.dy,
      );
      
      return Rect.fromCenter(
        center: finalCropCenter,
        width: cropRect.width,
        height: cropRect.height,
      );
    }

    return cropRect;
  }

  void _updateCropFromDrag(_DragHandle handle, Offset delta, Size containerSize) {
    // Calculate the scale factor for converting display coordinates to image coordinates
    final scaleX = containerSize.width / widget.imageSize.width;
    final scaleY = containerSize.height / widget.imageSize.height;
    final scale = math.min(scaleX, scaleY);
    
    // Transform delta to account for rotation
    Offset transformedDelta = delta;
    if (widget.contentRotation != 0.0) {
      final rotationRadians = -widget.contentRotation * math.pi / 180; // Inverse rotation
      final cos = math.cos(rotationRadians);
      final sin = math.sin(rotationRadians);
      transformedDelta = Offset(
        delta.dx * cos - delta.dy * sin,
        delta.dx * sin + delta.dy * cos,
      );
    }
    
    // Convert screen delta to image coordinate delta
    final deltaX = transformedDelta.dx / scale;  
    final deltaY = transformedDelta.dy / scale;

    // Define minimum crop area (e.g., 10x10 pixels)
    const minCropSize = 10.0;

    setState(() {
      // Calculate new crop values based on handle type
      double newCropX = _currentCropX;
      double newCropY = _currentCropY;
      double newCropWidth = _currentCropWidth;
      double newCropHeight = _currentCropHeight;

      switch (handle) {
        case _DragHandle.topLeft:
          // Moving top-left corner: adjust x, y, width, height
          newCropX = _currentCropX + deltaX;
          newCropY = _currentCropY + deltaY;
          newCropWidth = _currentCropWidth - deltaX;
          newCropHeight = _currentCropHeight - deltaY;
          break;
        case _DragHandle.topCenter:
          // Moving top edge: adjust y and height
          newCropY = _currentCropY + deltaY;
          newCropHeight = _currentCropHeight - deltaY;
          break;
        case _DragHandle.topRight:
          // Moving top-right corner: adjust y, width, height
          newCropY = _currentCropY + deltaY;
          newCropWidth = _currentCropWidth + deltaX;
          newCropHeight = _currentCropHeight - deltaY;
          break;
        case _DragHandle.centerLeft:
          // Moving left edge: adjust x and width
          newCropX = _currentCropX + deltaX;
          newCropWidth = _currentCropWidth - deltaX;
          break;
        case _DragHandle.centerRight:
          // Moving right edge: adjust width
          newCropWidth = _currentCropWidth + deltaX;
          break;
        case _DragHandle.bottomLeft:
          // Moving bottom-left corner: adjust x, width, height
          newCropX = _currentCropX + deltaX;
          newCropWidth = _currentCropWidth - deltaX;
          newCropHeight = _currentCropHeight + deltaY;
          break;
        case _DragHandle.bottomCenter:
          // Moving bottom edge: adjust height
          newCropHeight = _currentCropHeight + deltaY;
          break;
        case _DragHandle.bottomRight:
          // Moving bottom-right corner: adjust width and height
          newCropWidth = _currentCropWidth + deltaX;
          newCropHeight = _currentCropHeight + deltaY;
          break;
        case _DragHandle.move:
          // Move entire crop area: adjust x and y, keep width and height
          newCropX = _currentCropX + deltaX;
          newCropY = _currentCropY + deltaY;
          break;
      }

      // Apply constraints to ensure valid crop area
      final validatedCrop = _validateCropArea(
        newCropX,
        newCropY, 
        newCropWidth,
        newCropHeight,
        minCropSize,
      );

      _currentCropX = validatedCrop['x']!;
      _currentCropY = validatedCrop['y']!;
      _currentCropWidth = validatedCrop['width']!;
      _currentCropHeight = validatedCrop['height']!;
    });
  }

  /// Validates and adjusts crop values to ensure a valid crop area
  Map<String, double> _validateCropArea(
    double x,
    double y,
    double width,
    double height,
    double minSize,
  ) {
    // Ensure crop area stays within image bounds
    x = x.clamp(0.0, widget.imageSize.width);
    y = y.clamp(0.0, widget.imageSize.height);
    
    // Ensure minimum dimensions
    width = width.clamp(minSize, widget.imageSize.width);
    height = height.clamp(minSize, widget.imageSize.height);
    
    // Adjust position if crop area extends beyond image bounds
    if (x + width > widget.imageSize.width) {
      x = widget.imageSize.width - width;
    }
    if (y + height > widget.imageSize.height) {
      y = widget.imageSize.height - height;
    }
    
    // Final validation to ensure values are within bounds
    x = x.clamp(0.0, widget.imageSize.width - minSize);
    y = y.clamp(0.0, widget.imageSize.height - minSize);
    
    // Ensure final width and height don't exceed image bounds
    width = width.clamp(minSize, widget.imageSize.width - x);
    height = height.clamp(minSize, widget.imageSize.height - y);

    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
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
  final double cropX;       // Left edge of crop area in pixels
  final double cropY;       // Top edge of crop area in pixels
  final double cropWidth;   // Width of crop area in pixels
  final double cropHeight;  // Height of crop area in pixels
  final double contentRotation; // Rotation angle in degrees
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
    required this.containerSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate scale for image in container
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final scale = math.min(scaleX, scaleY);

    final scaledImageWidth = imageSize.width * scale;
    final scaledImageHeight = imageSize.height * scale;

    final offsetX = (size.width - scaledImageWidth) / 2;
    final offsetY = (size.height - scaledImageHeight) / 2;

    final imageRect = Rect.fromLTWH(offsetX, offsetY, scaledImageWidth, scaledImageHeight);

    // Save canvas state before applying rotation
    canvas.save();

    // Apply image rotation around image center
    if (contentRotation != 0.0) {
      final rotationRadians = contentRotation * math.pi / 180;
      final imageCenter = imageRect.center;
      canvas.translate(imageCenter.dx, imageCenter.dy);
      canvas.rotate(rotationRadians);
      canvas.translate(-imageCenter.dx, -imageCenter.dy);
    }

    // Convert crop coordinates from image pixels to display coordinates
    // Use the same scale factor as the image scaling
    final imageToDisplayScale = scale;

    final cropRectLeft = imageRect.left + (cropX * imageToDisplayScale);
    final cropRectTop = imageRect.top + (cropY * imageToDisplayScale);
    final cropRectWidth = cropWidth * imageToDisplayScale;
    final cropRectHeight = cropHeight * imageToDisplayScale;

    final cropRect = Rect.fromLTWH(cropRectLeft, cropRectTop, cropRectWidth, cropRectHeight);

    if (cropRect.width > 0 && cropRect.height > 0) {
      // Draw mask over non-cropped areas
      final maskPaint = Paint()
        ..color = Colors.black.withAlpha(100)
        ..style = PaintingStyle.fill;

      final maskPath = Path()..addRect(imageRect);
      maskPath.addRect(cropRect);
      maskPath.fillType = PathFillType.evenOdd;

      canvas.drawPath(maskPath, maskPaint);

      // Draw crop area border
      final borderPaint = Paint()
        ..color = colorScheme.primary
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawRect(cropRect, borderPaint);

      // Draw grid lines
      final gridPaint = Paint()
        ..color = colorScheme.primary.withAlpha(150)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      // Horizontal grid lines
      final gridHeight = cropRect.height / 3;
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + gridHeight),
        Offset(cropRect.right, cropRect.top + gridHeight),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + gridHeight * 2),
        Offset(cropRect.right, cropRect.top + gridHeight * 2),
        gridPaint,
      );

      // Vertical grid lines
      final gridWidth = cropRect.width / 3;
      canvas.drawLine(
        Offset(cropRect.left + gridWidth, cropRect.top),
        Offset(cropRect.left + gridWidth, cropRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left + gridWidth * 2, cropRect.top),
        Offset(cropRect.left + gridWidth * 2, cropRect.bottom),
        gridPaint,
      );

      // Draw 8 control handles
      const handleSize = 12.0;
      final handlePaint = Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.fill;

      final handleBorderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final handles = [
        // Corner handles
        cropRect.topLeft,
        cropRect.topRight,
        cropRect.bottomLeft,
        cropRect.bottomRight,
        // Edge handles
        Offset(cropRect.center.dx, cropRect.top),
        Offset(cropRect.center.dx, cropRect.bottom),
        Offset(cropRect.left, cropRect.center.dy),
        Offset(cropRect.right, cropRect.center.dy),
      ];

      for (final handleCenter in handles) {
        final handleRect = Rect.fromCenter(
          center: handleCenter,
          width: handleSize,
          height: handleSize,
        );
        
        // Draw handle background
        canvas.drawRRect(
          RRect.fromRectAndRadius(handleRect, const Radius.circular(2)),
          handleBorderPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(handleRect, const Radius.circular(2)),
          handlePaint,
        );
      }

      // Draw crop area dimensions (if crop area is reasonably large)
      if (cropRect.width > 60 && cropRect.height > 40) {
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
          cropRect.center.dx - textPainter.width / 2,
          cropRect.center.dy - textPainter.height / 2,
        );
        
        textPainter.paint(canvas, textPosition);
      }
    }

    // Restore canvas state
    canvas.restore();
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
        containerSize != oldDelegate.containerSize;
  }
}