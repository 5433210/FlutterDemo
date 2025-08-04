import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

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

    print('🔍 === InteractiveCropOverlay didUpdateWidget ===');
    print('  - imageSize: ${widget.imageSize.width.toStringAsFixed(1)}×${widget.imageSize.height.toStringAsFixed(1)}');
    print('  - renderSize: ${widget.renderSize.width.toStringAsFixed(1)}×${widget.renderSize.height.toStringAsFixed(1)}');
    print('  - contentRotation: ${widget.contentRotation}°');
    print('  - cropX: ${widget.cropX.toStringAsFixed(1)}, cropY: ${widget.cropY.toStringAsFixed(1)}');
    print('  - cropWidth: ${widget.cropWidth.toStringAsFixed(1)}, cropHeight: ${widget.cropHeight.toStringAsFixed(1)}');

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
        'transformsChanged':
            oldWidget.contentRotation != widget.contentRotation ||
                oldWidget.flipHorizontal != widget.flipHorizontal ||
                oldWidget.flipVertical != widget.flipVertical,
      },
    );

    // 检查是否需要重新初始化坐标协调器
    if (oldWidget.contentRotation != widget.contentRotation ||
        oldWidget.flipHorizontal != widget.flipHorizontal ||
        oldWidget.flipVertical != widget.flipVertical ||
        oldWidget.imageSize != widget.imageSize) {
      print('🔄 旋转/翻转/尺寸发生变化，重新初始化坐标协调器');
      print(
          '  - 旋转角度: ${oldWidget.contentRotation}° → ${widget.contentRotation}°');
      print(
          '  - 翻转状态: H=${oldWidget.flipHorizontal}→${widget.flipHorizontal}, V=${oldWidget.flipVertical}→${widget.flipVertical}');

      _initializeCoordinator();

      // 🔧 新增：当旋转角度变化时，自动调整裁剪框到新的动态边界
      if (oldWidget.contentRotation != widget.contentRotation) {
        _adjustCropToNewRotation(
            oldWidget.contentRotation, widget.contentRotation);
      }
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

  /// 🔧 新增方法：当旋转角度变化时，自动调整裁剪框到新的动态边界
  void _adjustCropToNewRotation(double oldRotation, double newRotation) {
    try {
      print('🎯 开始调整裁剪框以适应新的旋转角度');
      print('  - 旧旋转: ${oldRotation.toStringAsFixed(1)}°');
      print('  - 新旋转: ${newRotation.toStringAsFixed(1)}°');

      // 🔧 安全检查：验证输入参数
      if (!oldRotation.isFinite || !newRotation.isFinite) {
        print('  - ⚠️ 警告：旋转角度无效，跳过调整');
        return;
      }

      // 获取新的动态边界
      final newDynamicBounds = _coordinator.dynamicBounds;
      final validCropBounds = _coordinator.getValidDynamicCropBounds();

      // 🔧 安全检查：验证边界数据
      if (!newDynamicBounds.width.isFinite || 
          !newDynamicBounds.height.isFinite ||
          newDynamicBounds.width <= 0 || 
          newDynamicBounds.height <= 0) {
        print('  - ⚠️ 警告：动态边界无效，跳过调整');
        return;
      }

      print(
          '  - 新动态边界尺寸: ${newDynamicBounds.width.toStringAsFixed(1)} × ${newDynamicBounds.height.toStringAsFixed(1)}');
      print('  - 有效裁剪边界: ${validCropBounds.toString()}');

      // 🔧 安全检查：验证当前裁剪值
      if (!_currentCropX.isFinite || !_currentCropY.isFinite ||
          !_currentCropWidth.isFinite || !_currentCropHeight.isFinite ||
          _currentCropWidth <= 0 || _currentCropHeight <= 0) {
        print('  - ⚠️ 警告：当前裁剪值无效，跳过调整');
        return;
      }

      // 🔧 重要修复：如果当前裁剪框覆盖了整个原始图像，重新设置为合适的大小
      final originalImageSize = widget.imageSize;
      final isFullImageCrop = (_currentCropX == 0 && _currentCropY == 0 && 
                              _currentCropWidth >= originalImageSize.width - 1 && 
                              _currentCropHeight >= originalImageSize.height - 1);

      if (isFullImageCrop) {
        print('  - 🔧 检测到全图裁剪，重设为整个动态边界区域');
        
        // 🔧 关键修复：使用动态边界的完整区域作为默认裁剪框
        // 这样裁剪框会覆盖整个旋转后的图像包围区域
        const newCropX = 0.0;
        const newCropY = 0.0;
        final newCropWidth = newDynamicBounds.width;
        final newCropHeight = newDynamicBounds.height;

        print('  - 设置为完整动态边界: (${newCropX.toStringAsFixed(1)}, ${newCropY.toStringAsFixed(1)}, ${newCropWidth.toStringAsFixed(1)}, ${newCropHeight.toStringAsFixed(1)})');
        print('  - 动态边界尺寸: ${newDynamicBounds.width.toStringAsFixed(1)}×${newDynamicBounds.height.toStringAsFixed(1)}');

        // 将动态边界坐标转换回原始坐标系
        final adjustedOriginalParams = _coordinator.dynamicToOriginalCropParams(
          cropX: newCropX,
          cropY: newCropY,
          cropWidth: newCropWidth,
          cropHeight: newCropHeight,
        );

        final adjCropX = adjustedOriginalParams['cropX'];
        final adjCropY = adjustedOriginalParams['cropY']; 
        final adjCropWidth = adjustedOriginalParams['cropWidth'];
        final adjCropHeight = adjustedOriginalParams['cropHeight'];

        if (adjCropX != null && adjCropY != null && 
            adjCropWidth != null && adjCropHeight != null &&
            adjCropWidth > 0 && adjCropHeight > 0 &&
            adjCropX.isFinite && adjCropY.isFinite &&
            adjCropWidth.isFinite && adjCropHeight.isFinite) {

          print('  - 转换回原始坐标: (${adjCropX.toStringAsFixed(1)}, ${adjCropY.toStringAsFixed(1)}, ${adjCropWidth.toStringAsFixed(1)}, ${adjCropHeight.toStringAsFixed(1)})');

          // 🔧 在setState前进行最后的验证
          if (!mounted) {
            print('  - ⚠️ 警告：组件已卸载，跳过状态更新');
            return;
          }

          // 更新裁剪框
          setState(() {
            _currentCropX = adjCropX;
            _currentCropY = adjCropY;
            _currentCropWidth = adjCropWidth;
            _currentCropHeight = adjCropHeight;
          });

          // 🔧 异步通知父组件，避免在构建过程中触发
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onCropChanged(
                _currentCropX,
                _currentCropY,
                _currentCropWidth,
                _currentCropHeight,
                isDragging: false,
              );
            }
          });

          print('  - ✅ 全图裁剪框重设完成');
          return;
        } else {
          print('  - ⚠️ 警告：坐标转换失败，跳过重设');
        }
      }

      // 原有的边界检查和调整逻辑...
      // 获取当前裁剪区域在新的动态坐标系中的位置
      final currentDynamicCropParams = _coordinator.originalToDynamicCropParams(
        cropX: _currentCropX,
        cropY: _currentCropY,
        cropWidth: _currentCropWidth,
        cropHeight: _currentCropHeight,
      );

      // 🔧 验证转换结果
      final dynCropX = currentDynamicCropParams['cropX'];
      final dynCropY = currentDynamicCropParams['cropY'];
      final dynCropWidth = currentDynamicCropParams['cropWidth'];
      final dynCropHeight = currentDynamicCropParams['cropHeight'];

      if (dynCropX == null || dynCropY == null || 
          dynCropWidth == null || dynCropHeight == null ||
          !dynCropX.isFinite || !dynCropY.isFinite ||
          !dynCropWidth.isFinite || !dynCropHeight.isFinite ||
          dynCropWidth <= 0 || dynCropHeight <= 0) {
        print('  - ⚠️ 警告：动态坐标转换结果无效，跳过调整');
        return;
      }

      final currentDynamicRect = Rect.fromLTWH(
        dynCropX,
        dynCropY,
        dynCropWidth,
        dynCropHeight,
      );

      print('  - 当前裁剪区域（动态坐标）: ${currentDynamicRect.toString()}');

      // 检查当前裁剪区域是否超出新的有效边界
      // 🔧 优化边界检查逻辑，避免边界情况导致的异常
      final isOutOfBounds = currentDynamicRect.left < validCropBounds.left ||
          currentDynamicRect.top < validCropBounds.top ||
          currentDynamicRect.right > validCropBounds.right ||
          currentDynamicRect.bottom > validCropBounds.bottom ||
          currentDynamicRect.width > validCropBounds.width ||
          currentDynamicRect.height > validCropBounds.height ||
          currentDynamicRect.width <= 0 ||
          currentDynamicRect.height <= 0;

      if (isOutOfBounds) {
        print('  - 🔧 裁剪框超出新边界，需要调整');

        // 🔧 安全检查：确保有效边界有效
        if (validCropBounds.width <= 0 || validCropBounds.height <= 0 ||
            !validCropBounds.width.isFinite || !validCropBounds.height.isFinite) {
          print('  - ⚠️ 警告：有效边界无效，跳过调整');
          return;
        }

        // 自动调整裁剪框：保持相对比例，但限制在有效边界内
        final scaleX = validCropBounds.width / newDynamicBounds.width;
        final scaleY = validCropBounds.height / newDynamicBounds.height;
        final uniformScale = math.min(scaleX, scaleY) * 0.8; // 留一些边距

        // 🔧 确保缩放值有效
        if (uniformScale <= 0 || !uniformScale.isFinite) {
          print('  - ⚠️ 警告：计算出的缩放值无效 ($uniformScale)，跳过调整');
          return;
        }

        final newCropWidth = newDynamicBounds.width * uniformScale;
        final newCropHeight = newDynamicBounds.height * uniformScale;
        final newCropX = (validCropBounds.width - newCropWidth) / 2;
        final newCropY = (validCropBounds.height - newCropHeight) / 2;

        // 🔧 验证计算结果
        if (newCropWidth <= 0 ||
            newCropHeight <= 0 ||
            !newCropWidth.isFinite ||
            !newCropHeight.isFinite ||
            !newCropX.isFinite ||
            !newCropY.isFinite) {
          print('  - ⚠️ 警告：计算出的裁剪框尺寸无效，跳过调整');
          print('    newCropWidth: $newCropWidth, newCropHeight: $newCropHeight');
          print('    newCropX: $newCropX, newCropY: $newCropY');
          return;
        }

        print(
            '  - 调整后裁剪框（动态坐标）: (${newCropX.toStringAsFixed(1)}, ${newCropY.toStringAsFixed(1)}, ${newCropWidth.toStringAsFixed(1)}, ${newCropHeight.toStringAsFixed(1)})');

        // 转换回原始坐标系
        final adjustedOriginalParams = _coordinator.dynamicToOriginalCropParams(
          cropX: newCropX,
          cropY: newCropY,
          cropWidth: newCropWidth,
          cropHeight: newCropHeight,
        );

        // 🔧 验证转换后的原始坐标
        final adjCropX = adjustedOriginalParams['cropX'];
        final adjCropY = adjustedOriginalParams['cropY'];
        final adjCropWidth = adjustedOriginalParams['cropWidth'];
        final adjCropHeight = adjustedOriginalParams['cropHeight'];

        if (adjCropX == null || adjCropY == null || 
            adjCropWidth == null || adjCropHeight == null ||
            adjCropWidth <= 0 ||
            adjCropHeight <= 0 ||
            !adjCropX.isFinite ||
            !adjCropY.isFinite ||
            !adjCropWidth.isFinite ||
            !adjCropHeight.isFinite) {
          print('  - ⚠️ 警告：转换后的原始坐标无效，跳过调整');
          print('    adjCropX: $adjCropX, adjCropY: $adjCropY');
          print('    adjCropWidth: $adjCropWidth, adjCropHeight: $adjCropHeight');
          return;
        }

        print(
            '  - 调整后裁剪框（原始坐标）: (${adjCropX.toStringAsFixed(1)}, ${adjCropY.toStringAsFixed(1)}, ${adjCropWidth.toStringAsFixed(1)}, ${adjCropHeight.toStringAsFixed(1)})');

        // 🔧 在setState前进行最后的验证
        if (!mounted) {
          print('  - ⚠️ 警告：组件已卸载，跳过状态更新');
          return;
        }

        // 更新裁剪框并通知父组件
        setState(() {
          _currentCropX = adjCropX;
          _currentCropY = adjCropY;
          _currentCropWidth = adjCropWidth;
          _currentCropHeight = adjCropHeight;
        });

        // 🔧 异步通知父组件，避免在构建过程中触发
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onCropChanged(
              _currentCropX,
              _currentCropY,
              _currentCropWidth,
              _currentCropHeight,
              isDragging: false,
            );
          }
        });

        print('  - ✅ 裁剪框调整完成');
      } else {
        print('  - ✅ 裁剪框在有效边界内，无需调整');
      }
    } catch (e, stackTrace) {
      print('  - ❌ 裁剪框调整过程中发生异常: $e');
      print('  - 堆栈跟踪: $stackTrace');
      
      EditPageLogger.propertyPanelError(
        '裁剪框自动调整异常',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        error: e,
        stackTrace: stackTrace,
        data: {
          'operation': 'crop_adjustment_on_rotation',
          'oldRotation': oldRotation,
          'newRotation': newRotation,
          'currentCrop': {
            'x': _currentCropX,
            'y': _currentCropY,
            'width': _currentCropWidth,
            'height': _currentCropHeight,
          },
        },
      );
    }
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
    // 🔧 修复：使用与裁剪框显示相同的动态边界坐标系统
    // 不再需要手动处理旋转，因为裁剪框计算已经在动态边界中处理了所有变换

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
        if (handleRect.contains(position)) {
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
      if (handleRect.contains(position)) {
        return entry.key;
      }
    }

    // Check if inside crop area for moving
    if (cropRect.contains(position)) {
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
    try {
      // 🔧 安全检查：验证容器尺寸
      if (containerSize.width <= 0 || containerSize.height <= 0 ||
          !containerSize.width.isFinite || !containerSize.height.isFinite) {
        return Rect.zero;
      }

      // 🔧 安全检查：验证当前裁剪值
      if (!_currentCropX.isFinite || !_currentCropY.isFinite ||
          !_currentCropWidth.isFinite || !_currentCropHeight.isFinite ||
          _currentCropWidth <= 0 || _currentCropHeight <= 0) {
        return Rect.zero;
      }

      // 🔧 修复：根据用户建议使用"先旋转，再缩放"的简单方法
      print('🔧 === _calculateCropRect 路由 ===');
      print('  - contentRotation: ${widget.contentRotation}°');
      
      // 🎯 改用动态边界坐标系统 - 更符合"先旋转，再缩放"的逻辑  
      print('  - 🎯 使用动态边界坐标系统（符合先旋转再缩放的逻辑）');
      final result = _calculateCropRectWithDynamicBounds(containerSize);
      
      print('  - 🎯 動態邊界算法結果: ${result.toString()}');
      print('🔧 === _calculateCropRect 路由結束 ===\n');
      
      return result;
    } catch (e) {
      print('❌ _calculateCropRect 异常: $e');
      return Rect.zero;
    }
  }

  /// 使用动态边界坐标系计算裁剪矩形
  Rect _calculateCropRectWithDynamicBounds(Size containerSize) {
    print('🔍 === _calculateCropRectWithDynamicBounds 开始 ===');
    print('  - containerSize: ${containerSize.width.toStringAsFixed(1)}×${containerSize.height.toStringAsFixed(1)}');
    print('  - 输入原始裁剪值: (${_currentCropX.toStringAsFixed(1)}, ${_currentCropY.toStringAsFixed(1)}, ${_currentCropWidth.toStringAsFixed(1)}, ${_currentCropHeight.toStringAsFixed(1)})');
    print('  - widget.imageSize: ${widget.imageSize.width.toStringAsFixed(1)}×${widget.imageSize.height.toStringAsFixed(1)}');
    print('  - widget.renderSize: ${widget.renderSize.width.toStringAsFixed(1)}×${widget.renderSize.height.toStringAsFixed(1)}');
    print('  - contentRotation: ${widget.contentRotation}°');
    
    // 🔧 使用动态边界坐标系统
    // 将原始图像坐标系的裁剪区域转换为动态边界坐标系
    final dynamicCropParams = _coordinator.originalToDynamicCropParams(
      cropX: _currentCropX,
      cropY: _currentCropY,
      cropWidth: _currentCropWidth,
      cropHeight: _currentCropHeight,
    );

    // 🔧 验证转换结果
    final dynCropX = dynamicCropParams['cropX'];
    final dynCropY = dynamicCropParams['cropY'];
    final dynCropWidth = dynamicCropParams['cropWidth'];
    final dynCropHeight = dynamicCropParams['cropHeight'];

    print('  - 转换后动态裁剪: (${dynCropX?.toStringAsFixed(1)}, ${dynCropY?.toStringAsFixed(1)}, ${dynCropWidth?.toStringAsFixed(1)}, ${dynCropHeight?.toStringAsFixed(1)})');

    if (dynCropX == null || dynCropY == null || 
        dynCropWidth == null || dynCropHeight == null ||
        !dynCropX.isFinite || !dynCropY.isFinite ||
        !dynCropWidth.isFinite || !dynCropHeight.isFinite ||
        dynCropWidth <= 0 || dynCropHeight <= 0) {
      print('  - ❌ 动态裁剪参数无效，返回 Rect.zero');
      return Rect.zero;
    }

    final dynamicCropRect = Rect.fromLTWH(
      dynCropX,
      dynCropY,
      dynCropWidth,
      dynCropHeight,
    );

    // 验证并调整动态边界中的裁剪区域
    final clampedDynamicRect =
        _coordinator.clampDynamicCropRect(dynamicCropRect);
    
    print('  - clampedDynamicRect: ${clampedDynamicRect.toString()}');

    // 将动态边界坐标转换为显示坐标
    final dynamicBounds = _coordinator.dynamicBounds;
    print('  - dynamicBounds: ${dynamicBounds.width.toStringAsFixed(1)}×${dynamicBounds.height.toStringAsFixed(1)}');

    // 🔧 验证动态边界
    if (!dynamicBounds.width.isFinite || !dynamicBounds.height.isFinite ||
        dynamicBounds.width <= 0 || dynamicBounds.height <= 0) {
      print('  - ❌ 动态边界无效，返回 Rect.zero');
      return Rect.zero;
    }

    // Calculate scale for dynamic bounds in container - 使用contain模式
    final scaleX = containerSize.width / dynamicBounds.width;
    final scaleY = containerSize.height / dynamicBounds.height;
    final scale = math.min(scaleX, scaleY);
    print('  - 缩放计算: scaleX=${scaleX.toStringAsFixed(3)}, scaleY=${scaleY.toStringAsFixed(3)}, final scale=${scale.toStringAsFixed(3)}');

    // 🔧 验证缩放值
    if (!scale.isFinite || scale <= 0) {
      print('  - ❌ 缩放值无效，返回 Rect.zero');
      return Rect.zero;
    }

    final scaledDynamicWidth = dynamicBounds.width * scale;
    final scaledDynamicHeight = dynamicBounds.height * scale;

    final offsetX = (containerSize.width - scaledDynamicWidth) / 2;
    final offsetY = (containerSize.height - scaledDynamicHeight) / 2;
    print('  - 偏移量: offsetX=${offsetX.toStringAsFixed(1)}, offsetY=${offsetY.toStringAsFixed(1)}');

    // 🔧 验证偏移量
    if (!offsetX.isFinite || !offsetY.isFinite) {
      print('  - ❌ 偏移量无效，返回 Rect.zero');
      return Rect.zero;
    }

    // Convert dynamic crop coordinates to display coordinates
    final left = offsetX + (clampedDynamicRect.left * scale);
    final top = offsetY + (clampedDynamicRect.top * scale);
    final width = clampedDynamicRect.width * scale;
    final height = clampedDynamicRect.height * scale;

    print('  - 最终显示坐标计算:');
    print('    - left = ${offsetX.toStringAsFixed(1)} + (${clampedDynamicRect.left.toStringAsFixed(1)} * ${scale.toStringAsFixed(3)}) = ${left.toStringAsFixed(1)}');
    print('    - top = ${offsetY.toStringAsFixed(1)} + (${clampedDynamicRect.top.toStringAsFixed(1)} * ${scale.toStringAsFixed(3)}) = ${top.toStringAsFixed(1)}');
    print('    - width = ${clampedDynamicRect.width.toStringAsFixed(1)} * ${scale.toStringAsFixed(3)} = ${width.toStringAsFixed(1)}');
    print('    - height = ${clampedDynamicRect.height.toStringAsFixed(1)} * ${scale.toStringAsFixed(3)} = ${height.toStringAsFixed(1)}');

    // 🔧 最终验证
    if (!left.isFinite || !top.isFinite || !width.isFinite || !height.isFinite ||
        width <= 0 || height <= 0) {
      print('  - ❌ 最终显示坐标无效，返回 Rect.zero');
      return Rect.zero;
    }

    final result = Rect.fromLTWH(left, top, width, height);
    print('  - ✅ 最终结果: ${result.toString()}');
    print('🔍 === _calculateCropRectWithDynamicBounds 结束 ===\n');

    return result;
  }

  /// 为未旋转图像计算裁剪矩形（使用动态边界坐标系）
  Rect _calculateCropRectForNormalImage(Size containerSize) {
    // 🔧 使用动态边界坐标系统
    // 将原始图像坐标系的裁剪区域转换为动态边界坐标系
    final dynamicCropParams = _coordinator.originalToDynamicCropParams(
      cropX: _currentCropX,
      cropY: _currentCropY,
      cropWidth: _currentCropWidth,
      cropHeight: _currentCropHeight,
    );

    // 🔧 验证转换结果
    final dynCropX = dynamicCropParams['cropX'];
    final dynCropY = dynamicCropParams['cropY'];
    final dynCropWidth = dynamicCropParams['cropWidth'];
    final dynCropHeight = dynamicCropParams['cropHeight'];

    if (dynCropX == null || dynCropY == null || 
        dynCropWidth == null || dynCropHeight == null ||
        !dynCropX.isFinite || !dynCropY.isFinite ||
        !dynCropWidth.isFinite || !dynCropHeight.isFinite ||
        dynCropWidth <= 0 || dynCropHeight <= 0) {
      return Rect.zero;
    }

    final dynamicCropRect = Rect.fromLTWH(
      dynCropX,
      dynCropY,
      dynCropWidth,
      dynCropHeight,
    );

    // 验证并调整动态边界中的裁剪区域
    final clampedDynamicRect =
        _coordinator.clampDynamicCropRect(dynamicCropRect);

    // 将动态边界坐标转换为显示坐标
    final dynamicBounds = _coordinator.dynamicBounds;

    // 🔧 验证动态边界
    if (!dynamicBounds.width.isFinite || !dynamicBounds.height.isFinite ||
        dynamicBounds.width <= 0 || dynamicBounds.height <= 0) {
      return Rect.zero;
    }

    // Calculate scale for dynamic bounds in container - 使用contain模式
    final scaleX = containerSize.width / dynamicBounds.width;
    final scaleY = containerSize.height / dynamicBounds.height;
    final scale = math.min(scaleX, scaleY);

    // 🔧 验证缩放值
    if (!scale.isFinite || scale <= 0) {
      return Rect.zero;
    }

    final scaledDynamicWidth = dynamicBounds.width * scale;
    final scaledDynamicHeight = dynamicBounds.height * scale;

    final offsetX = (containerSize.width - scaledDynamicWidth) / 2;
    final offsetY = (containerSize.height - scaledDynamicHeight) / 2;

    // 🔧 验证偏移量
    if (!offsetX.isFinite || !offsetY.isFinite) {
      return Rect.zero;
    }

    // Convert dynamic crop coordinates to display coordinates
    final left = offsetX + (clampedDynamicRect.left * scale);
    final top = offsetY + (clampedDynamicRect.top * scale);
    final width = clampedDynamicRect.width * scale;
    final height = clampedDynamicRect.height * scale;

    // 🔧 最终验证
    if (!left.isFinite || !top.isFinite || !width.isFinite || !height.isFinite ||
        width <= 0 || height <= 0) {
      return Rect.zero;
    }

    return Rect.fromLTWH(left, top, width, height);
  }

  /// 统一的Transform坐标变换算法
  /// 基于步驟2數學模型實現，確保與視覺Transform完全一致
  Rect _calculateUnifiedTransformCropRect(Size containerSize) {
    print('🔧 === 统一Transform坐标算法 开始 ===');
    print('  - containerSize: ${containerSize.width.toStringAsFixed(1)}×${containerSize.height.toStringAsFixed(1)}');
    print('  - imageSize: ${widget.imageSize.width.toStringAsFixed(1)}×${widget.imageSize.height.toStringAsFixed(1)}');
    print('  - renderSize: ${widget.renderSize.width.toStringAsFixed(1)}×${widget.renderSize.height.toStringAsFixed(1)}');
    print('  - contentRotation: ${widget.contentRotation}°');
    print('  - 当前裁剪参数: (${_currentCropX.toStringAsFixed(1)}, ${_currentCropY.toStringAsFixed(1)}, ${_currentCropWidth.toStringAsFixed(1)}, ${_currentCropHeight.toStringAsFixed(1)})');
    
    // 步驟1：計算未旋轉時的基礎參數
    final renderSize = widget.renderSize;
    final imagePosition = Offset(
      (containerSize.width - renderSize.width) / 2,
      (containerSize.height - renderSize.height) / 2,
    );
    
    print('  - 📍 步驟1 - 圖像居中位置: (${imagePosition.dx.toStringAsFixed(3)}, ${imagePosition.dy.toStringAsFixed(3)})');
    
    // 步驟2：將原始裁剪坐標映射到容器坐標（未旋轉）
    final cropRatioX = _currentCropX / widget.imageSize.width;
    final cropRatioY = _currentCropY / widget.imageSize.height;
    final cropRatioWidth = _currentCropWidth / widget.imageSize.width;
    final cropRatioHeight = _currentCropHeight / widget.imageSize.height;
    
    print('  - 🧮 步驟2 - 裁剪比例: x=${cropRatioX.toStringAsFixed(4)}, y=${cropRatioY.toStringAsFixed(4)}, w=${cropRatioWidth.toStringAsFixed(4)}, h=${cropRatioHeight.toStringAsFixed(4)}');
    
    final unrotatedCropRect = Rect.fromLTWH(
      imagePosition.dx + (cropRatioX * renderSize.width),
      imagePosition.dy + (cropRatioY * renderSize.height),
      cropRatioWidth * renderSize.width,
      cropRatioHeight * renderSize.height,
    );
    
    print('  - 📦 步驟2 - 未旋轉裁剪框: ${unrotatedCropRect.toString()}');
    
    // 步驟3：應用Transform變換
    if (widget.contentRotation == 0) {
      print('  - ✅ 無旋轉，直接返回未旋轉結果');
      print('🔧 === 统一Transform坐标算法 结束 ===\n');
      return unrotatedCropRect;
    }
    
    print('  - 🔄 步驟3 - 應用${widget.contentRotation}°旋轉變換...');
    
    // 构建Transform矩阵
    final centerX = containerSize.width / 2;
    final centerY = containerSize.height / 2;
    final rotationRadians = widget.contentRotation * (math.pi / 180.0);
    
    print('  - 🔄 變換中心: (${centerX.toStringAsFixed(1)}, ${centerY.toStringAsFixed(1)})');
    print('  - 🔄 旋轉弧度: ${rotationRadians.toStringAsFixed(4)}');
    
    // 创建Transform矩阵（与image_property_panel_widgets.dart中完全一致）
    final transformMatrix = Matrix4.identity()
      ..translate(centerX, centerY)
      ..rotateZ(rotationRadians)
      ..scale(
        widget.flipHorizontal ? -1.0 : 1.0,
        widget.flipVertical ? -1.0 : 1.0,
      )
      ..translate(-centerX, -centerY);
    
    // 計算裁剪框四個角點的變換
    final corners = [
      Offset(unrotatedCropRect.left, unrotatedCropRect.top),      // 左上
      Offset(unrotatedCropRect.right, unrotatedCropRect.top),     // 右上
      Offset(unrotatedCropRect.right, unrotatedCropRect.bottom),  // 右下
      Offset(unrotatedCropRect.left, unrotatedCropRect.bottom),   // 左下
    ];
    
    // 應用Transform變換到每個角點
    final transformedCorners = corners.map((corner) => _transformPoint(corner, transformMatrix)).toList();
    
    print('  - 🔄 角點變換結果:');
    for (int i = 0; i < corners.length; i++) {
      final original = corners[i];
      final transformed = transformedCorners[i];
      final cornerNames = ['左上', '右上', '右下', '左下'];
      print('    - ${cornerNames[i]}: (${original.dx.toStringAsFixed(1)}, ${original.dy.toStringAsFixed(1)}) → (${transformed.dx.toStringAsFixed(1)}, ${transformed.dy.toStringAsFixed(1)})');
    }
    
    // 計算變換後的邊界框
    double minX = transformedCorners.map((p) => p.dx).reduce(math.min);
    double maxX = transformedCorners.map((p) => p.dx).reduce(math.max);
    double minY = transformedCorners.map((p) => p.dy).reduce(math.min);
    double maxY = transformedCorners.map((p) => p.dy).reduce(math.max);
    
    final transformedCropRect = Rect.fromLTRB(minX, minY, maxX, maxY);
    
    print('  - 📦 步驟3 - 變換後邊界框: minX=${minX.toStringAsFixed(1)}, minY=${minY.toStringAsFixed(1)}, maxX=${maxX.toStringAsFixed(1)}, maxY=${maxY.toStringAsFixed(1)}');
    print('  - ✅ 最終統一結果: ${transformedCropRect.toString()}');
    
    // 步驟4：邊界檢查和像素對齊
    final clampedRect = Rect.fromLTWH(
      math.max(0, math.min(transformedCropRect.left, containerSize.width)).roundToDouble(),
      math.max(0, math.min(transformedCropRect.top, containerSize.height)).roundToDouble(),
      math.max(1, math.min(transformedCropRect.width, containerSize.width - transformedCropRect.left)).roundToDouble(),
      math.max(1, math.min(transformedCropRect.height, containerSize.height - transformedCropRect.top)).roundToDouble(),
    );
    
    if (clampedRect != transformedCropRect) {
      print('  - 🔧 邊界調整: ${transformedCropRect.toString()} → ${clampedRect.toString()}');
    }
    
    print('🔧 === 统一Transform坐标算法 结束 ===\n');
    return clampedRect;
  }
  
  /// 統一的反向Transform坐標變換算法（用於拖拽處理）
  void _updateCropFromUnifiedTransformDrag(_DragHandle handle, Offset delta, Size containerSize) {
    print('🔧 === 统一反向Transform拖拽处理 开始 ===');
    print('  - handle: ${handle.toString()}');
    print('  - delta: (${delta.dx.toStringAsFixed(1)}, ${delta.dy.toStringAsFixed(1)})');
    print('  - contentRotation: ${widget.contentRotation}°');
    
    try {
      // 步驟1：獲取當前裁剪框位置（在容器坐標系中）
      final currentCropRect = _calculateUnifiedTransformCropRect(containerSize);
      print('  - 📦 當前裁剪框: ${currentCropRect.toString()}');
      
      // 步驟2：計算拖拽後的新裁剪框位置
      final newCropRect = _calculateNewCropRectFromDrag(currentCropRect, handle, delta, containerSize);
      print('  - 📦 拖拽後裁剪框: ${newCropRect.toString()}');
      
      // 步驟3：反向變換 - 從容器坐標轉換回原始圖像坐標
      final (newCropX, newCropY, newCropWidth, newCropHeight) = _reverseCropToOriginalCoordinates(
        newCropRect, containerSize
      );
      
      print('  - 🔄 反向變換結果: (${newCropX.toStringAsFixed(1)}, ${newCropY.toStringAsFixed(1)}, ${newCropWidth.toStringAsFixed(1)}, ${newCropHeight.toStringAsFixed(1)})');
      
      // 步驟4：應用邊界限制
      final clampedCropX = math.max(0, math.min(newCropX, widget.imageSize.width)).toDouble();
      final clampedCropY = math.max(0, math.min(newCropY, widget.imageSize.height)).toDouble();
      final clampedCropWidth = math.max(1, math.min(newCropWidth, widget.imageSize.width - clampedCropX)).toDouble();
      final clampedCropHeight = math.max(1, math.min(newCropHeight, widget.imageSize.height - clampedCropY)).toDouble();
      
      print('  - 🔧 邊界限制後: (${clampedCropX.toStringAsFixed(1)}, ${clampedCropY.toStringAsFixed(1)}, ${clampedCropWidth.toStringAsFixed(1)}, ${clampedCropHeight.toStringAsFixed(1)})');
      
      // 步驟5：更新裁剪參數
      setState(() {
        _currentCropX = clampedCropX;
        _currentCropY = clampedCropY;
        _currentCropWidth = clampedCropWidth;
        _currentCropHeight = clampedCropHeight;
        
        print('  - ✅ 參數已更新');
      });
      
      print('🔧 === 统一反向Transform拖拽处理 结束 ===\n');
    } catch (e) {
      print('❌ 統一拖拽處理異常: $e');
    }
  }
  
  /// 根據拖拽操作計算新的裁剪框
  Rect _calculateNewCropRectFromDrag(Rect currentRect, _DragHandle handle, Offset delta, Size containerSize) {
    switch (handle) {
      case _DragHandle.topLeft:
        return Rect.fromLTRB(
          math.max(0, currentRect.left + delta.dx),
          math.max(0, currentRect.top + delta.dy),
          currentRect.right,
          currentRect.bottom,
        );
      case _DragHandle.topCenter:
        return Rect.fromLTRB(
          currentRect.left,
          math.max(0, currentRect.top + delta.dy),
          currentRect.right,
          currentRect.bottom,
        );
      case _DragHandle.topRight:
        return Rect.fromLTRB(
          currentRect.left,
          math.max(0, currentRect.top + delta.dy),
          math.min(containerSize.width, currentRect.right + delta.dx),
          currentRect.bottom,
        );
      case _DragHandle.centerLeft:
        return Rect.fromLTRB(
          math.max(0, currentRect.left + delta.dx),
          currentRect.top,
          currentRect.right,
          currentRect.bottom,
        );
      case _DragHandle.centerRight:
        return Rect.fromLTRB(
          currentRect.left,
          currentRect.top,
          math.min(containerSize.width, currentRect.right + delta.dx),
          currentRect.bottom,
        );
      case _DragHandle.bottomLeft:
        return Rect.fromLTRB(
          math.max(0, currentRect.left + delta.dx),
          currentRect.top,
          currentRect.right,
          math.min(containerSize.height, currentRect.bottom + delta.dy),
        );
      case _DragHandle.bottomCenter:
        return Rect.fromLTRB(
          currentRect.left,
          currentRect.top,
          currentRect.right,
          math.min(containerSize.height, currentRect.bottom + delta.dy),
        );
      case _DragHandle.bottomRight:
        return Rect.fromLTRB(
          currentRect.left,
          currentRect.top,
          math.min(containerSize.width, currentRect.right + delta.dx),
          math.min(containerSize.height, currentRect.bottom + delta.dy),
        );
      case _DragHandle.move:
        final newLeft = math.max(0, math.min(containerSize.width - currentRect.width, currentRect.left + delta.dx)).toDouble();
        final newTop = math.max(0, math.min(containerSize.height - currentRect.height, currentRect.top + delta.dy)).toDouble();
        return Rect.fromLTWH(newLeft, newTop, currentRect.width, currentRect.height);
    }
  }
  
  /// 反向變換：從容器坐標轉換回原始圖像坐標
  (double, double, double, double) _reverseCropToOriginalCoordinates(Rect containerCropRect, Size containerSize) {
    print('  - 🔄 反向變換開始...');
    
    // 如果沒有旋轉，直接反向映射
    if (widget.contentRotation == 0) {
      print('  - 🔄 無旋轉，直接反向映射');
      return _reverseUnrotatedCropToOriginal(containerCropRect, containerSize);
    }
    
    // 有旋轉的情況，需要先進行反向Transform變換
    print('  - 🔄 有旋轉，進行反向Transform變換...');
    
    // 創建反向Transform矩陣
    final centerX = containerSize.width / 2;
    final centerY = containerSize.height / 2;
    final rotationRadians = -widget.contentRotation * (math.pi / 180.0); // 反向旋轉
    
    final inverseTransformMatrix = Matrix4.identity()
      ..translate(centerX, centerY)
      ..scale(
        widget.flipHorizontal ? -1.0 : 1.0,
        widget.flipVertical ? -1.0 : 1.0,
      )
      ..rotateZ(rotationRadians)
      ..translate(-centerX, -centerY);
    
    // 對裁剪框四個角點進行反向變換
    final corners = [
      Offset(containerCropRect.left, containerCropRect.top),
      Offset(containerCropRect.right, containerCropRect.top),
      Offset(containerCropRect.right, containerCropRect.bottom),
      Offset(containerCropRect.left, containerCropRect.bottom),
    ];
    
    final reverseTransformedCorners = corners.map((corner) => _transformPoint(corner, inverseTransformMatrix)).toList();
    
    print('  - 🔄 反向變換角點:');
    for (int i = 0; i < corners.length; i++) {
      final original = corners[i];
      final transformed = reverseTransformedCorners[i];
      print('    - (${original.dx.toStringAsFixed(1)}, ${original.dy.toStringAsFixed(1)}) → (${transformed.dx.toStringAsFixed(1)}, ${transformed.dy.toStringAsFixed(1)})');
    }
    
    // 計算反向變換後的邊界框
    double minX = reverseTransformedCorners.map((p) => p.dx).reduce(math.min);
    double maxX = reverseTransformedCorners.map((p) => p.dx).reduce(math.max);
    double minY = reverseTransformedCorners.map((p) => p.dy).reduce(math.min);
    double maxY = reverseTransformedCorners.map((p) => p.dy).reduce(math.max);
    
    final reverseTransformedRect = Rect.fromLTRB(minX, minY, maxX, maxY);
    print('  - 🔄 反向變換邊界框: ${reverseTransformedRect.toString()}');
    
    // 將反向變換後的容器坐標映射到原始圖像坐標
    return _reverseUnrotatedCropToOriginal(reverseTransformedRect, containerSize);
  }
  
  /// 將未旋轉的容器裁剪坐標映射回原始圖像坐標
  (double, double, double, double) _reverseUnrotatedCropToOriginal(Rect containerCropRect, Size containerSize) {
    final renderSize = widget.renderSize;
    final imagePosition = Offset(
      (containerSize.width - renderSize.width) / 2,
      (containerSize.height - renderSize.height) / 2,
    );
    
    // 將容器坐標轉換為相對於圖像的坐標
    final relativeLeft = containerCropRect.left - imagePosition.dx;
    final relativeTop = containerCropRect.top - imagePosition.dy;
    final relativeWidth = containerCropRect.width;
    final relativeHeight = containerCropRect.height;
    
    // 將renderSize坐標轉換為原始圖像坐標
    final scaleX = widget.imageSize.width / renderSize.width;
    final scaleY = widget.imageSize.height / renderSize.height;
    
    final originalCropX = relativeLeft * scaleX;
    final originalCropY = relativeTop * scaleY;
    final originalCropWidth = relativeWidth * scaleX;
    final originalCropHeight = relativeHeight * scaleY;
    
    print('  - 🔄 反向映射: 容器(${containerCropRect.left.toStringAsFixed(1)}, ${containerCropRect.top.toStringAsFixed(1)}, ${containerCropRect.width.toStringAsFixed(1)}, ${containerCropRect.height.toStringAsFixed(1)}) → 原始(${originalCropX.toStringAsFixed(1)}, ${originalCropY.toStringAsFixed(1)}, ${originalCropWidth.toStringAsFixed(1)}, ${originalCropHeight.toStringAsFixed(1)})');
    
    return (originalCropX, originalCropY, originalCropWidth, originalCropHeight);
  }
  
  /// Transform點變換輔助方法
  Offset _transformPoint(Offset point, Matrix4 matrix) {
    final vector = Vector4(point.dx, point.dy, 0, 1);
    final transformed = matrix * vector;
    return Offset(transformed.x, transformed.y);
  }

  void _updateCropFromDrag(
      _DragHandle handle, Offset delta, Size containerSize) {
    try {
      // 🔧 安全检查：验证输入参数
      if (!delta.dx.isFinite || !delta.dy.isFinite ||
          containerSize.width <= 0 || containerSize.height <= 0 ||
          !containerSize.width.isFinite || !containerSize.height.isFinite) {
        return;
      }

      // 🔧 修复：根据用户建议使用"先旋转，再缩放"的简单方法
      print('🔧 === _updateCropFromDrag 路由 ===');
      print('  - handle: ${handle.toString()}');
      print('  - delta: (${delta.dx.toStringAsFixed(1)}, ${delta.dy.toStringAsFixed(1)})');
      print('  - contentRotation: ${widget.contentRotation}°');
      
      // 🎯 改用动态边界坐标系统 - 更符合"先旋转，再缩放"的逻辑
      print('  - 🎯 使用动态边界坐标系统（符合先旋转再缩放的逻辑）');
      _updateCropFromDragWithDynamicBounds(handle, delta, containerSize);
      
      print('🔧 === _updateCropFromDrag 路由結束 ===\n');
    } catch (e) {
      print('❌ _updateCropFromDrag 异常: $e');
      
      EditPageLogger.propertyPanelError(
        '裁剪框拖拽更新异常',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        error: e,
        data: {
          'operation': 'crop_drag_update',
          'handle': handle.toString(),
          'delta': '${delta.dx}, ${delta.dy}',
          'containerSize': '${containerSize.width}x${containerSize.height}',
        },
      );
    }
  }

  /// 使用动态边界坐标系处理拖拽
  void _updateCropFromDragWithDynamicBounds(
      _DragHandle handle, Offset delta, Size containerSize) {
    // 🔧 使用动态边界坐标系统计算拖拽变换
    final dynamicBounds = _coordinator.dynamicBounds;

    // 🔧 验证动态边界
    if (!dynamicBounds.width.isFinite || !dynamicBounds.height.isFinite ||
        dynamicBounds.width <= 0 || dynamicBounds.height <= 0) {
      return;
    }

    // Calculate scale for dynamic bounds in container
    final scaleX = containerSize.width / dynamicBounds.width;
    final scaleY = containerSize.height / dynamicBounds.height;
    final scale = math.min(scaleX, scaleY);

    // 🔧 验证缩放值
    if (!scale.isFinite || scale <= 0) {
      return;
    }

    // Convert screen delta to dynamic boundary coordinate delta
    final deltaX = delta.dx / scale;
    final deltaY = delta.dy / scale;

    // 🔧 验证增量值
    if (!deltaX.isFinite || !deltaY.isFinite) {
      return;
    }

    setState(() {
      // 🔧 验证当前裁剪值
      if (!_currentCropX.isFinite || !_currentCropY.isFinite ||
          !_currentCropWidth.isFinite || !_currentCropHeight.isFinite ||
          _currentCropWidth <= 0 || _currentCropHeight <= 0) {
        return;
      }

      // 获取当前在动态边界坐标系中的裁剪参数
      final currentDynamicCropParams = _coordinator.originalToDynamicCropParams(
        cropX: _currentCropX,
        cropY: _currentCropY,
        cropWidth: _currentCropWidth,
        cropHeight: _currentCropHeight,
      );

      // 🔧 验证转换结果
      final currentDynCropX = currentDynamicCropParams['cropX'];
      final currentDynCropY = currentDynamicCropParams['cropY'];
      final currentDynCropWidth = currentDynamicCropParams['cropWidth'];
      final currentDynCropHeight = currentDynamicCropParams['cropHeight'];

      if (currentDynCropX == null || currentDynCropY == null || 
          currentDynCropWidth == null || currentDynCropHeight == null ||
          !currentDynCropX.isFinite || !currentDynCropY.isFinite ||
          !currentDynCropWidth.isFinite || !currentDynCropHeight.isFinite ||
          currentDynCropWidth <= 0 || currentDynCropHeight <= 0) {
        return;
      }

      // Calculate new crop values in dynamic boundary coordinates
      double newDynamicCropX = currentDynCropX;
      double newDynamicCropY = currentDynCropY;
      double newDynamicCropWidth = currentDynCropWidth;
      double newDynamicCropHeight = currentDynCropHeight;

      switch (handle) {
        case _DragHandle.topLeft:
          newDynamicCropX = currentDynCropX + deltaX;
          newDynamicCropY = currentDynCropY + deltaY;
          newDynamicCropWidth = currentDynCropWidth - deltaX;
          newDynamicCropHeight = currentDynCropHeight - deltaY;
          break;
        case _DragHandle.topCenter:
          newDynamicCropY = currentDynCropY + deltaY;
          newDynamicCropHeight = currentDynCropHeight - deltaY;
          break;
        case _DragHandle.topRight:
          newDynamicCropY = currentDynCropY + deltaY;
          newDynamicCropWidth = currentDynCropWidth + deltaX;
          newDynamicCropHeight = currentDynCropHeight - deltaY;
          break;
        case _DragHandle.centerLeft:
          newDynamicCropX = currentDynCropX + deltaX;
          newDynamicCropWidth = currentDynCropWidth - deltaX;
          break;
        case _DragHandle.centerRight:
          newDynamicCropWidth = currentDynCropWidth + deltaX;
          break;
        case _DragHandle.bottomLeft:
          newDynamicCropX = currentDynCropX + deltaX;
          newDynamicCropWidth = currentDynCropWidth - deltaX;
          newDynamicCropHeight = currentDynCropHeight + deltaY;
          break;
        case _DragHandle.bottomCenter:
          newDynamicCropHeight = currentDynCropHeight + deltaY;
          break;
        case _DragHandle.bottomRight:
          newDynamicCropWidth = currentDynCropWidth + deltaX;
          newDynamicCropHeight = currentDynCropHeight + deltaY;
          break;
        case _DragHandle.move:
          newDynamicCropX = currentDynCropX + deltaX;
          newDynamicCropY = currentDynCropY + deltaY;
          break;
      }

      // 🔧 验证计算结果
      if (!newDynamicCropX.isFinite || !newDynamicCropY.isFinite ||
          !newDynamicCropWidth.isFinite || !newDynamicCropHeight.isFinite ||
          newDynamicCropWidth <= 0 || newDynamicCropHeight <= 0) {
        return;
      }

      // Validate dynamic boundary crop area
      final dynamicRect = Rect.fromLTWH(newDynamicCropX, newDynamicCropY,
          newDynamicCropWidth, newDynamicCropHeight);
      final clampedDynamicRect = _coordinator.clampDynamicCropRect(dynamicRect);

      // Convert back to original image coordinates
      final originalCropParams = _coordinator.dynamicToOriginalCropParams(
        cropX: clampedDynamicRect.left,
        cropY: clampedDynamicRect.top,
        cropWidth: clampedDynamicRect.width,
        cropHeight: clampedDynamicRect.height,
      );

      // 🔧 验证最终结果
      final finalCropX = originalCropParams['cropX'];
      final finalCropY = originalCropParams['cropY'];
      final finalCropWidth = originalCropParams['cropWidth'];
      final finalCropHeight = originalCropParams['cropHeight'];

      if (finalCropX == null || finalCropY == null || 
          finalCropWidth == null || finalCropHeight == null ||
          !finalCropX.isFinite || !finalCropY.isFinite ||
          !finalCropWidth.isFinite || !finalCropHeight.isFinite ||
          finalCropWidth <= 0 || finalCropHeight <= 0) {
        return;
      }

      _currentCropX = finalCropX;
      _currentCropY = finalCropY;
      _currentCropWidth = finalCropWidth;
      _currentCropHeight = finalCropHeight;

      print('🔧 动态边界拖拽更新: (${_currentCropX.toStringAsFixed(1)}, ${_currentCropY.toStringAsFixed(1)}, ${_currentCropWidth.toStringAsFixed(1)}, ${_currentCropHeight.toStringAsFixed(1)})');
    });
  }

  /// 为未旋转图像处理拖拽（使用动态边界坐标系）
  void _updateCropFromDragForNormalImage(
      _DragHandle handle, Offset delta, Size containerSize) {
    // 🔧 使用动态边界坐标系统计算拖拽变换
    final dynamicBounds = _coordinator.dynamicBounds;

    // 🔧 验证动态边界
    if (!dynamicBounds.width.isFinite || !dynamicBounds.height.isFinite ||
        dynamicBounds.width <= 0 || dynamicBounds.height <= 0) {
      return;
    }

    // Calculate scale for dynamic bounds in container
    final scaleX = containerSize.width / dynamicBounds.width;
    final scaleY = containerSize.height / dynamicBounds.height;
    final scale = math.min(scaleX, scaleY);

    // 🔧 验证缩放值
    if (!scale.isFinite || scale <= 0) {
      return;
    }

    // Convert screen delta to dynamic boundary coordinate delta
    final deltaX = delta.dx / scale;
    final deltaY = delta.dy / scale;

    // 🔧 验证增量值
    if (!deltaX.isFinite || !deltaY.isFinite) {
      return;
    }

    setState(() {
      // 🔧 验证当前裁剪值
      if (!_currentCropX.isFinite || !_currentCropY.isFinite ||
          !_currentCropWidth.isFinite || !_currentCropHeight.isFinite ||
          _currentCropWidth <= 0 || _currentCropHeight <= 0) {
        return;
      }

      // 获取当前在动态边界坐标系中的裁剪参数
      final currentDynamicCropParams = _coordinator.originalToDynamicCropParams(
        cropX: _currentCropX,
        cropY: _currentCropY,
        cropWidth: _currentCropWidth,
        cropHeight: _currentCropHeight,
      );

      // 🔧 验证转换结果
      final currentDynCropX = currentDynamicCropParams['cropX'];
      final currentDynCropY = currentDynamicCropParams['cropY'];
      final currentDynCropWidth = currentDynamicCropParams['cropWidth'];
      final currentDynCropHeight = currentDynamicCropParams['cropHeight'];

      if (currentDynCropX == null || currentDynCropY == null || 
          currentDynCropWidth == null || currentDynCropHeight == null ||
          !currentDynCropX.isFinite || !currentDynCropY.isFinite ||
          !currentDynCropWidth.isFinite || !currentDynCropHeight.isFinite ||
          currentDynCropWidth <= 0 || currentDynCropHeight <= 0) {
        return;
      }

      // Calculate new crop values in dynamic boundary coordinates
      double newDynamicCropX = currentDynCropX;
      double newDynamicCropY = currentDynCropY;
      double newDynamicCropWidth = currentDynCropWidth;
      double newDynamicCropHeight = currentDynCropHeight;

      switch (handle) {
        case _DragHandle.topLeft:
          newDynamicCropX = currentDynCropX + deltaX;
          newDynamicCropY = currentDynCropY + deltaY;
          newDynamicCropWidth = currentDynCropWidth - deltaX;
          newDynamicCropHeight = currentDynCropHeight - deltaY;
          break;
        case _DragHandle.topCenter:
          newDynamicCropY = currentDynCropY + deltaY;
          newDynamicCropHeight = currentDynCropHeight - deltaY;
          break;
        case _DragHandle.topRight:
          newDynamicCropY = currentDynCropY + deltaY;
          newDynamicCropWidth = currentDynCropWidth + deltaX;
          newDynamicCropHeight = currentDynCropHeight - deltaY;
          break;
        case _DragHandle.centerLeft:
          newDynamicCropX = currentDynCropX + deltaX;
          newDynamicCropWidth = currentDynCropWidth - deltaX;
          break;
        case _DragHandle.centerRight:
          newDynamicCropWidth = currentDynCropWidth + deltaX;
          break;
        case _DragHandle.bottomLeft:
          newDynamicCropX = currentDynCropX + deltaX;
          newDynamicCropWidth = currentDynCropWidth - deltaX;
          newDynamicCropHeight = currentDynCropHeight + deltaY;
          break;
        case _DragHandle.bottomCenter:
          newDynamicCropHeight = currentDynCropHeight + deltaY;
          break;
        case _DragHandle.bottomRight:
          newDynamicCropWidth = currentDynCropWidth + deltaX;
          newDynamicCropHeight = currentDynCropHeight + deltaY;
          break;
        case _DragHandle.move:
          newDynamicCropX = currentDynCropX + deltaX;
          newDynamicCropY = currentDynCropY + deltaY;
          break;
      }

      // 🔧 验证计算结果
      if (!newDynamicCropX.isFinite || !newDynamicCropY.isFinite ||
          !newDynamicCropWidth.isFinite || !newDynamicCropHeight.isFinite ||
          newDynamicCropWidth <= 0 || newDynamicCropHeight <= 0) {
        return;
      }

      // Validate dynamic boundary crop area
      final dynamicRect = Rect.fromLTWH(newDynamicCropX, newDynamicCropY,
          newDynamicCropWidth, newDynamicCropHeight);
      final clampedDynamicRect = _coordinator.clampDynamicCropRect(dynamicRect);

      // Convert back to original image coordinates
      final originalCropParams = _coordinator.dynamicToOriginalCropParams(
        cropX: clampedDynamicRect.left,
        cropY: clampedDynamicRect.top,
        cropWidth: clampedDynamicRect.width,
        cropHeight: clampedDynamicRect.height,
      );

      // 🔧 验证最终结果
      final finalCropX = originalCropParams['cropX'];
      final finalCropY = originalCropParams['cropY'];
      final finalCropWidth = originalCropParams['cropWidth'];
      final finalCropHeight = originalCropParams['cropHeight'];

      if (finalCropX == null || finalCropY == null || 
          finalCropWidth == null || finalCropHeight == null ||
          !finalCropX.isFinite || !finalCropY.isFinite ||
          !finalCropWidth.isFinite || !finalCropHeight.isFinite ||
          finalCropWidth <= 0 || finalCropHeight <= 0) {
        return;
      }

      _currentCropX = finalCropX;
      _currentCropY = finalCropY;
      _currentCropWidth = finalCropWidth;
      _currentCropHeight = finalCropHeight;
    });
  }

  /// 为Transform变换图像处理拖拽（与视觉变换保持一致）
  void _updateCropFromDragForTransformedImage(
      _DragHandle handle, Offset delta, Size containerSize) {
    // 基于renderSize计算缩放比例
    final renderSize = widget.renderSize;
    final scaleX = renderSize.width / widget.imageSize.width;
    final scaleY = renderSize.height / widget.imageSize.height;
    final scale = math.min(scaleX, scaleY);
    
    if (!scale.isFinite || scale <= 0) {
      return;
    }
    
    // 将屏幕坐标的增量转换为原始图像坐标的增量
    final deltaX = delta.dx / scale;
    final deltaY = delta.dy / scale;
    
    if (!deltaX.isFinite || !deltaY.isFinite) {
      return;
    }
    
    setState(() {
      // 验证当前裁剪值
      if (!_currentCropX.isFinite || !_currentCropY.isFinite ||
          !_currentCropWidth.isFinite || !_currentCropHeight.isFinite ||
          _currentCropWidth <= 0 || _currentCropHeight <= 0) {
        return;
      }
      
      // 在原始图像坐标系中计算新的裁剪值
      double newCropX = _currentCropX;
      double newCropY = _currentCropY;
      double newCropWidth = _currentCropWidth;
      double newCropHeight = _currentCropHeight;
      
      switch (handle) {
        case _DragHandle.topLeft:
          newCropX = _currentCropX + deltaX;
          newCropY = _currentCropY + deltaY;
          newCropWidth = _currentCropWidth - deltaX;
          newCropHeight = _currentCropHeight - deltaY;
          break;
        case _DragHandle.topCenter:
          newCropY = _currentCropY + deltaY;
          newCropHeight = _currentCropHeight - deltaY;
          break;
        case _DragHandle.topRight:
          newCropY = _currentCropY + deltaY;
          newCropWidth = _currentCropWidth + deltaX;
          newCropHeight = _currentCropHeight - deltaY;
          break;
        case _DragHandle.centerLeft:
          newCropX = _currentCropX + deltaX;
          newCropWidth = _currentCropWidth - deltaX;
          break;
        case _DragHandle.centerRight:
          newCropWidth = _currentCropWidth + deltaX;
          break;
        case _DragHandle.bottomLeft:
          newCropX = _currentCropX + deltaX;
          newCropWidth = _currentCropWidth - deltaX;
          newCropHeight = _currentCropHeight + deltaY;
          break;
        case _DragHandle.bottomCenter:
          newCropHeight = _currentCropHeight + deltaY;
          break;
        case _DragHandle.bottomRight:
          newCropWidth = _currentCropWidth + deltaX;
          newCropHeight = _currentCropHeight + deltaY;
          break;
        case _DragHandle.move:
          newCropX = _currentCropX + deltaX;
          newCropY = _currentCropY + deltaY;
          break;
      }
      
      // 验证计算结果并限制在图像边界内
      if (!newCropX.isFinite || !newCropY.isFinite ||
          !newCropWidth.isFinite || !newCropHeight.isFinite) {
        return;
      }
      
      const minCropSize = 10.0;
      newCropX = math.max(0, newCropX);
      newCropY = math.max(0, newCropY);
      newCropWidth = math.max(minCropSize, math.min(newCropWidth, widget.imageSize.width - newCropX));
      newCropHeight = math.max(minCropSize, math.min(newCropHeight, widget.imageSize.height - newCropY));
      
      // 确保裁剪区域不超出图像边界
      if (newCropX + newCropWidth > widget.imageSize.width) {
        newCropX = widget.imageSize.width - newCropWidth;
      }
      if (newCropY + newCropHeight > widget.imageSize.height) {
        newCropY = widget.imageSize.height - newCropHeight;
      }
      
      // 最终验证
      if (newCropX >= 0 && newCropY >= 0 && 
          newCropWidth >= minCropSize && newCropHeight >= minCropSize &&
          newCropX + newCropWidth <= widget.imageSize.width &&
          newCropY + newCropHeight <= widget.imageSize.height) {
        
        _currentCropX = newCropX;
        _currentCropY = newCropY;
        _currentCropWidth = newCropWidth;
        _currentCropHeight = newCropHeight;
        
        print('🔧 Transform图像拖拽更新: (${_currentCropX.toStringAsFixed(1)}, ${_currentCropY.toStringAsFixed(1)}, ${_currentCropWidth.toStringAsFixed(1)}, ${_currentCropHeight.toStringAsFixed(1)})');
      }
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

    print('🎨 === InteractiveCropPainter.paint 开始 ===');
    print('  - canvas size: ${size.width.toStringAsFixed(1)}×${size.height.toStringAsFixed(1)}');
    print('  - imageSize: ${imageSize.width.toStringAsFixed(1)}×${imageSize.height.toStringAsFixed(1)}');
    print('  - renderSize: ${renderSize.width.toStringAsFixed(1)}×${renderSize.height.toStringAsFixed(1)}');
    print('  - contentRotation: $contentRotation°');
    print('  - 裁剪参数: (${cropX.toStringAsFixed(1)}, ${cropY.toStringAsFixed(1)}, ${cropWidth.toStringAsFixed(1)}, ${cropHeight.toStringAsFixed(1)})');

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 🔧 使用动态边界坐标系统
    print('  - 🔄 创建ImageTransformCoordinator...');
    final coordinator = ImageTransformCoordinator(
      originalImageSize: imageSize,
      rotation: contentRotation * (math.pi / 180.0), // 转换为弧度
      flipHorizontal: flipHorizontal,
      flipVertical: flipVertical,
    );

    print('  - 🔄 将原始坐标转换为动态边界坐标...');
    // 将原始图像坐标系的裁剪区域转换为动态边界坐标系
    final dynamicCropParams = coordinator.originalToDynamicCropParams(
      cropX: cropX,
      cropY: cropY,
      cropWidth: cropWidth,
      cropHeight: cropHeight,
    );

    print('  - 🔄 动态边界裁剪参数: x=${dynamicCropParams['cropX']!.toStringAsFixed(1)}, y=${dynamicCropParams['cropY']!.toStringAsFixed(1)}, w=${dynamicCropParams['cropWidth']!.toStringAsFixed(1)}, h=${dynamicCropParams['cropHeight']!.toStringAsFixed(1)}');

    final dynamicCropRect = Rect.fromLTWH(
      dynamicCropParams['cropX']!,
      dynamicCropParams['cropY']!,
      dynamicCropParams['cropWidth']!,
      dynamicCropParams['cropHeight']!,
    );

    // 验证并调整动态边界中的裁剪区域
    final clampedDynamicRect = coordinator.clampDynamicCropRect(dynamicCropRect);
    print('  - 🔄 限制后的动态裁剪区域: ${clampedDynamicRect.toString()}');

    // 获取动态边界大小
    final dynamicBounds = coordinator.dynamicBounds;
    print('  - 📐 动态边界尺寸: ${dynamicBounds.width.toStringAsFixed(1)}×${dynamicBounds.height.toStringAsFixed(1)}');

    // Calculate scale for dynamic bounds in container
    final scaleX = size.width / dynamicBounds.width;
    final scaleY = size.height / dynamicBounds.height;
    final scale = math.min(scaleX, scaleY);
    
    print('  - 📐 缩放计算: scaleX=${scaleX.toStringAsFixed(4)} (${size.width}/${dynamicBounds.width})');
    print('  - 📐 缩放计算: scaleY=${scaleY.toStringAsFixed(4)} (${size.height}/${dynamicBounds.height})');
    print('  - 📐 最终缩放: ${scale.toStringAsFixed(4)} (取较小值)');

    final scaledDynamicWidth = dynamicBounds.width * scale;
    final scaledDynamicHeight = dynamicBounds.height * scale;

    final offsetX = (size.width - scaledDynamicWidth) / 2;
    final offsetY = (size.height - scaledDynamicHeight) / 2;
    
    print('  - 📍 缩放后动态边界: ${scaledDynamicWidth.toStringAsFixed(1)}×${scaledDynamicHeight.toStringAsFixed(1)}');
    print('  - 📍 动态边界偏移: offset=(${offsetX.toStringAsFixed(1)}, ${offsetY.toStringAsFixed(1)})');

    // Dynamic bounds display rectangle
    final dynamicBoundsRect = Rect.fromLTWH(
        offsetX, offsetY, scaledDynamicWidth, scaledDynamicHeight);
    print('  - 📍 动态边界显示区域: ${dynamicBoundsRect.toString()}');

    // Convert dynamic crop coordinates to display coordinates
    final displayCropRect = Rect.fromLTWH(
      offsetX + (clampedDynamicRect.left * scale),
      offsetY + (clampedDynamicRect.top * scale),
      clampedDynamicRect.width * scale,
      clampedDynamicRect.height * scale,
    );
    
    print('  - 🧮 显示坐标计算: left = ${offsetX.toStringAsFixed(1)} + (${clampedDynamicRect.left.toStringAsFixed(1)} × ${scale.toStringAsFixed(4)}) = ${(offsetX + clampedDynamicRect.left * scale).toStringAsFixed(1)}');
    print('  - 🧮 显示坐标计算: top = ${offsetY.toStringAsFixed(1)} + (${clampedDynamicRect.top.toStringAsFixed(1)} × ${scale.toStringAsFixed(4)}) = ${(offsetY + clampedDynamicRect.top * scale).toStringAsFixed(1)}');
    print('  - 🧮 显示坐标计算: width = ${clampedDynamicRect.width.toStringAsFixed(1)} × ${scale.toStringAsFixed(4)} = ${(clampedDynamicRect.width * scale).toStringAsFixed(1)}');
    print('  - 🧮 显示坐标计算: height = ${clampedDynamicRect.height.toStringAsFixed(1)} × ${scale.toStringAsFixed(4)} = ${(clampedDynamicRect.height * scale).toStringAsFixed(1)}');
    print('  - ✅ 最终显示裁剪框（动态边界系统）: ${displayCropRect.toString()}');
    
    print('  - ⚠️ 注意：此结果基于动态边界坐标系统，与Transform变换可能不匹配！');

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
      
      print('  - 🎨 绘制裁剪框边框和遮罩完成');
      print('🎨 === InteractiveCropPainter.paint 结束 ===\n');

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

/// Zoom-aware crop overlay that scales with InteractiveViewer
class ZoomedCropOverlay extends StatefulWidget {
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
  final double zoomScale; // Current zoom scale from InteractiveViewer
  final Offset panOffset; // Current pan offset from InteractiveViewer

  const ZoomedCropOverlay({
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
    required this.zoomScale,
    required this.panOffset,
  });

  @override
  State<ZoomedCropOverlay> createState() => _ZoomedCropOverlayState();
}

class _ZoomedCropOverlayState extends State<ZoomedCropOverlay> {
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
  void didUpdateWidget(ZoomedCropOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    print('🔍 === ZoomedCropOverlay didUpdateWidget ===');
    print('  - zoomScale: ${widget.zoomScale.toStringAsFixed(2)}');
    print('  - panOffset: ${widget.panOffset.dx.toStringAsFixed(1)}, ${widget.panOffset.dy.toStringAsFixed(1)}');

    // 检查是否需要重新初始化坐标协调器
    if (oldWidget.contentRotation != widget.contentRotation ||
        oldWidget.flipHorizontal != widget.flipHorizontal ||
        oldWidget.flipVertical != widget.flipVertical ||
        oldWidget.imageSize != widget.imageSize) {
      _initializeCoordinator();
    }

    // 更新本地状态
    if (oldWidget.cropX != widget.cropX ||
        oldWidget.cropY != widget.cropY ||
        oldWidget.cropWidth != widget.cropWidth ||
        oldWidget.cropHeight != widget.cropHeight) {
      _updateCurrentCropValues();
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
              painter: ZoomedCropPainter(
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
                zoomScale: widget.zoomScale,
                panOffset: widget.panOffset,
              ),
              size: constraints.biggest,
            ),
          ),
        );
      },
    );
  }

  MouseCursor _getCursorForPosition(Size containerSize) {
    return SystemMouseCursors.precise;
  }

  void _onPanStart(DragStartDetails details) {
    final containerSize = context.size!;
    _activeDragHandle = _getHandleAtPosition(details.localPosition, containerSize);
    _lastPanPosition = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeDragHandle == null || _lastPanPosition == null) return;

    final containerSize = context.size!;
    final delta = details.localPosition - _lastPanPosition!;
    _lastPanPosition = details.localPosition;

    // 调整delta以考虑zoom scale
    final adjustedDelta = Offset(delta.dx / widget.zoomScale, delta.dy / widget.zoomScale);

    _updateCropFromDrag(_activeDragHandle!, adjustedDelta, containerSize);

    widget.onCropChanged(
      _currentCropX,
      _currentCropY,
      _currentCropWidth,
      _currentCropHeight,
      isDragging: true,
    );
  }

  void _onPanEnd(DragEndDetails details) {
    _activeDragHandle = null;
    _lastPanPosition = null;

    widget.onCropChanged(
      _currentCropX,
      _currentCropY,
      _currentCropWidth,
      _currentCropHeight,
      isDragging: false,
    );
  }

  _DragHandle? _getHandleAtPosition(Offset position, Size containerSize) {
    final cropRect = _calculateCropRect(containerSize);
    final handleSize = 16.0 / widget.zoomScale; // 句柄大小随缩放调整

    final handles = _getHandlePositions(cropRect);

    // 优先检测角落句柄
    final cornerHandles = [
      _DragHandle.topLeft,
      _DragHandle.topRight,
      _DragHandle.bottomLeft,
      _DragHandle.bottomRight,
    ];

    for (final handleType in cornerHandles) {
      final handleCenter = handles[handleType];
      if (handleCenter != null) {
        final handleRect = Rect.fromCenter(
          center: handleCenter,
          width: handleSize,
          height: handleSize,
        );
        if (handleRect.contains(position)) {
          return handleType;
        }
      }
    }

    // 然后检测边缘句柄
    for (final entry in handles.entries) {
      if (cornerHandles.contains(entry.key)) continue;

      final handleRect = Rect.fromCenter(
        center: entry.value,
        width: handleSize,
        height: handleSize,
      );
      if (handleRect.contains(position)) {
        return entry.key;
      }
    }

    // Check if inside crop area for moving
    if (cropRect.contains(position)) {
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
    try {
      // 安全检查
      if (containerSize.width <= 0 || containerSize.height <= 0 ||
          !containerSize.width.isFinite || !containerSize.height.isFinite) {
        return Rect.zero;
      }

      if (!_currentCropX.isFinite || !_currentCropY.isFinite ||
          !_currentCropWidth.isFinite || !_currentCropHeight.isFinite ||
          _currentCropWidth <= 0 || _currentCropHeight <= 0) {
        return Rect.zero;
      }

      print('🔧 === ZoomedCropOverlay _calculateCropRect ===');
      print('  - contentRotation: ${widget.contentRotation}°');
      print('  - zoomScale: ${widget.zoomScale.toStringAsFixed(2)}');
      print('  - panOffset: ${widget.panOffset.dx.toStringAsFixed(1)}, ${widget.panOffset.dy.toStringAsFixed(1)}');
      
      // 使用动态边界坐标系统计算基础裁剪框
      final result = _calculateCropRectWithDynamicBounds(containerSize);
      
      print('  - 基础裁剪框: ${result.toString()}');
      
      // 应用缩放和平移变换
      final scaledResult = Rect.fromLTWH(
        (result.left * widget.zoomScale) + widget.panOffset.dx,
        (result.top * widget.zoomScale) + widget.panOffset.dy,
        result.width * widget.zoomScale,
        result.height * widget.zoomScale,
      );
      
      print('  - 缩放平移后: ${scaledResult.toString()}');
      print('🔧 === ZoomedCropOverlay _calculateCropRect 结束 ===\n');
      
      return scaledResult;
    } catch (e) {
      print('❌ ZoomedCropOverlay _calculateCropRect 异常: $e');
      return Rect.zero;
    }
  }

  /// 使用动态边界坐标系计算裁剪矩形
  Rect _calculateCropRectWithDynamicBounds(Size containerSize) {
    // 将原始图像坐标系的裁剪区域转换为动态边界坐标系
    final dynamicCropParams = _coordinator.originalToDynamicCropParams(
      cropX: _currentCropX,
      cropY: _currentCropY,
      cropWidth: _currentCropWidth,
      cropHeight: _currentCropHeight,
    );

    final dynCropX = dynamicCropParams['cropX'];
    final dynCropY = dynamicCropParams['cropY'];
    final dynCropWidth = dynamicCropParams['cropWidth'];
    final dynCropHeight = dynamicCropParams['cropHeight'];

    if (dynCropX == null || dynCropY == null || 
        dynCropWidth == null || dynCropHeight == null ||
        !dynCropX.isFinite || !dynCropY.isFinite ||
        !dynCropWidth.isFinite || !dynCropHeight.isFinite ||
        dynCropWidth <= 0 || dynCropHeight <= 0) {
      return Rect.zero;
    }

    final dynamicCropRect = Rect.fromLTWH(
      dynCropX,
      dynCropY,
      dynCropWidth,
      dynCropHeight,
    );

    // 验证并调整动态边界中的裁剪区域
    final clampedDynamicRect = _coordinator.clampDynamicCropRect(dynamicCropRect);

    // 将动态边界坐标转换为显示坐标
    final dynamicBounds = _coordinator.dynamicBounds;

    if (!dynamicBounds.width.isFinite || !dynamicBounds.height.isFinite ||
        dynamicBounds.width <= 0 || dynamicBounds.height <= 0) {
      return Rect.zero;
    }

    // Calculate scale for dynamic bounds in container - 使用contain模式
    final scaleX = containerSize.width / dynamicBounds.width;
    final scaleY = containerSize.height / dynamicBounds.height;
    final scale = math.min(scaleX, scaleY);

    if (!scale.isFinite || scale <= 0) {
      return Rect.zero;
    }

    final scaledDynamicWidth = dynamicBounds.width * scale;
    final scaledDynamicHeight = dynamicBounds.height * scale;

    final offsetX = (containerSize.width - scaledDynamicWidth) / 2;
    final offsetY = (containerSize.height - scaledDynamicHeight) / 2;

    if (!offsetX.isFinite || !offsetY.isFinite) {
      return Rect.zero;
    }

    // Convert dynamic crop coordinates to display coordinates
    final left = offsetX + (clampedDynamicRect.left * scale);
    final top = offsetY + (clampedDynamicRect.top * scale);
    final width = clampedDynamicRect.width * scale;
    final height = clampedDynamicRect.height * scale;

    if (!left.isFinite || !top.isFinite || !width.isFinite || !height.isFinite ||
        width <= 0 || height <= 0) {
      return Rect.zero;
    }

    return Rect.fromLTWH(left, top, width, height);
  }

  void _updateCropFromDrag(_DragHandle handle, Offset delta, Size containerSize) {
    try {
      if (!delta.dx.isFinite || !delta.dy.isFinite) {
        return;
      }

      // 使用动态边界坐标系处理拖拽
      _updateCropFromDragWithDynamicBounds(handle, delta, containerSize);
    } catch (e) {
      print('❌ ZoomedCropOverlay _updateCropFromDrag 异常: $e');
    }
  }

  /// 使用动态边界坐标系处理拖拽
  void _updateCropFromDragWithDynamicBounds(_DragHandle handle, Offset delta, Size containerSize) {
    final dynamicBounds = _coordinator.dynamicBounds;

    if (!dynamicBounds.width.isFinite || !dynamicBounds.height.isFinite ||
        dynamicBounds.width <= 0 || dynamicBounds.height <= 0) {
      return;
    }

    // Calculate scale for dynamic bounds in container
    final scaleX = containerSize.width / dynamicBounds.width;
    final scaleY = containerSize.height / dynamicBounds.height;
    final scale = math.min(scaleX, scaleY);

    if (!scale.isFinite || scale <= 0) {
      return;
    }

    // Convert screen delta to dynamic boundary coordinate delta
    final deltaX = delta.dx / scale;
    final deltaY = delta.dy / scale;

    if (!deltaX.isFinite || !deltaY.isFinite) {
      return;
    }

    setState(() {
      // 获取当前在动态边界坐标系中的裁剪参数
      final currentDynamicCropParams = _coordinator.originalToDynamicCropParams(
        cropX: _currentCropX,
        cropY: _currentCropY,
        cropWidth: _currentCropWidth,
        cropHeight: _currentCropHeight,
      );

      final currentDynCropX = currentDynamicCropParams['cropX'];
      final currentDynCropY = currentDynamicCropParams['cropY'];
      final currentDynCropWidth = currentDynamicCropParams['cropWidth'];
      final currentDynCropHeight = currentDynamicCropParams['cropHeight'];

      if (currentDynCropX == null || currentDynCropY == null || 
          currentDynCropWidth == null || currentDynCropHeight == null ||
          !currentDynCropX.isFinite || !currentDynCropY.isFinite ||
          !currentDynCropWidth.isFinite || !currentDynCropHeight.isFinite ||
          currentDynCropWidth <= 0 || currentDynCropHeight <= 0) {
        return;
      }

      // Calculate new crop values in dynamic boundary coordinates
      double newDynamicCropX = currentDynCropX;
      double newDynamicCropY = currentDynCropY;
      double newDynamicCropWidth = currentDynCropWidth;
      double newDynamicCropHeight = currentDynCropHeight;

      switch (handle) {
        case _DragHandle.topLeft:
          newDynamicCropX = currentDynCropX + deltaX;
          newDynamicCropY = currentDynCropY + deltaY;
          newDynamicCropWidth = currentDynCropWidth - deltaX;
          newDynamicCropHeight = currentDynCropHeight - deltaY;
          break;
        case _DragHandle.topCenter:
          newDynamicCropY = currentDynCropY + deltaY;
          newDynamicCropHeight = currentDynCropHeight - deltaY;
          break;
        case _DragHandle.topRight:
          newDynamicCropY = currentDynCropY + deltaY;
          newDynamicCropWidth = currentDynCropWidth + deltaX;
          newDynamicCropHeight = currentDynCropHeight - deltaY;
          break;
        case _DragHandle.centerLeft:
          newDynamicCropX = currentDynCropX + deltaX;
          newDynamicCropWidth = currentDynCropWidth - deltaX;
          break;
        case _DragHandle.centerRight:
          newDynamicCropWidth = currentDynCropWidth + deltaX;
          break;
        case _DragHandle.bottomLeft:
          newDynamicCropX = currentDynCropX + deltaX;
          newDynamicCropWidth = currentDynCropWidth - deltaX;
          newDynamicCropHeight = currentDynCropHeight + deltaY;
          break;
        case _DragHandle.bottomCenter:
          newDynamicCropHeight = currentDynCropHeight + deltaY;
          break;
        case _DragHandle.bottomRight:
          newDynamicCropWidth = currentDynCropWidth + deltaX;
          newDynamicCropHeight = currentDynCropHeight + deltaY;
          break;
        case _DragHandle.move:
          newDynamicCropX = currentDynCropX + deltaX;
          newDynamicCropY = currentDynCropY + deltaY;
          break;
      }

      if (!newDynamicCropX.isFinite || !newDynamicCropY.isFinite ||
          !newDynamicCropWidth.isFinite || !newDynamicCropHeight.isFinite ||
          newDynamicCropWidth <= 0 || newDynamicCropHeight <= 0) {
        return;
      }

      // Validate dynamic boundary crop area
      final dynamicRect = Rect.fromLTWH(newDynamicCropX, newDynamicCropY,
          newDynamicCropWidth, newDynamicCropHeight);
      final clampedDynamicRect = _coordinator.clampDynamicCropRect(dynamicRect);

      // Convert back to original image coordinates
      final originalCropParams = _coordinator.dynamicToOriginalCropParams(
        cropX: clampedDynamicRect.left,
        cropY: clampedDynamicRect.top,
        cropWidth: clampedDynamicRect.width,
        cropHeight: clampedDynamicRect.height,
      );

      final finalCropX = originalCropParams['cropX'];
      final finalCropY = originalCropParams['cropY'];
      final finalCropWidth = originalCropParams['cropWidth'];
      final finalCropHeight = originalCropParams['cropHeight'];

      if (finalCropX == null || finalCropY == null || 
          finalCropWidth == null || finalCropHeight == null ||
          !finalCropX.isFinite || !finalCropY.isFinite ||
          !finalCropWidth.isFinite || !finalCropHeight.isFinite ||
          finalCropWidth <= 0 || finalCropHeight <= 0) {
        return;
      }

      _currentCropX = finalCropX;
      _currentCropY = finalCropY;
      _currentCropWidth = finalCropWidth;
      _currentCropHeight = finalCropHeight;
    });
  }
}

/// Custom painter for the zoom-aware crop overlay
class ZoomedCropPainter extends CustomPainter {
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
  final double zoomScale; // Current zoom scale
  final Offset panOffset; // Current pan offset

  const ZoomedCropPainter({
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
    required this.zoomScale,
    required this.panOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    print('🎨 === ZoomedCropPainter.paint 开始 ===');
    print('  - canvas size: ${size.width.toStringAsFixed(1)}×${size.height.toStringAsFixed(1)}');
    print('  - zoomScale: ${zoomScale.toStringAsFixed(2)}');
    print('  - panOffset: ${panOffset.dx.toStringAsFixed(1)}, ${panOffset.dy.toStringAsFixed(1)}');

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 使用动态边界坐标系统
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
    final dynamicBoundsRect = Rect.fromLTWH(
        offsetX, offsetY, scaledDynamicWidth, scaledDynamicHeight);

    // Convert dynamic crop coordinates to display coordinates (before zoom/pan)
    final baseCropRect = Rect.fromLTWH(
      offsetX + (clampedDynamicRect.left * scale),
      offsetY + (clampedDynamicRect.top * scale),
      clampedDynamicRect.width * scale,
      clampedDynamicRect.height * scale,
    );

    // Apply zoom and pan transformation
    final displayCropRect = Rect.fromLTWH(
      (baseCropRect.left * zoomScale) + panOffset.dx,
      (baseCropRect.top * zoomScale) + panOffset.dy,
      baseCropRect.width * zoomScale,
      baseCropRect.height * zoomScale,
    );

    print('  - ✅ 最终显示裁剪框（缩放平移后）: ${displayCropRect.toString()}');

    if (displayCropRect.width > 0 && displayCropRect.height > 0) {
      // Apply zoom and pan to bounds rect as well
      final displayBoundsRect = Rect.fromLTWH(
        (dynamicBoundsRect.left * zoomScale) + panOffset.dx,
        (dynamicBoundsRect.top * zoomScale) + panOffset.dy,
        dynamicBoundsRect.width * zoomScale,
        dynamicBoundsRect.height * zoomScale,
      );

      // Clip to visible area for mask
      final visibleArea = Rect.fromLTWH(0, 0, size.width, size.height);
      final clippedBoundsRect = displayBoundsRect.intersect(visibleArea);
      
      if (clippedBoundsRect.width > 0 && clippedBoundsRect.height > 0) {
        // Draw mask over non-cropped areas
        final maskPaint = Paint()
          ..color = Colors.black.withAlpha(100)
          ..style = PaintingStyle.fill;

        final maskPath = Path()..addRect(clippedBoundsRect);
        maskPath.addRect(displayCropRect);
        maskPath.fillType = PathFillType.evenOdd;

        canvas.drawPath(maskPath, maskPaint);
      }

      // Draw crop area border
      final borderPaint = Paint()
        ..color = colorScheme.primary
        ..strokeWidth = 2.0 / zoomScale // 边框线宽随缩放调整
        ..style = PaintingStyle.stroke;

      canvas.drawRect(displayCropRect, borderPaint);

      // Draw grid lines
      final gridPaint = Paint()
        ..color = colorScheme.primary.withAlpha(150)
        ..strokeWidth = 1.0 / zoomScale // 网格线宽随缩放调整
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

      // Draw 8 control handles with zoom-adjusted size
      final handleSize = 16.0 / zoomScale; // 句柄大小随缩放调整

      final handleBorderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0 / zoomScale // 句柄边框随缩放调整
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

        final currentHandleSize = isCornerHandle ? handleSize : handleSize * 0.8;

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
              fontSize: 12 / zoomScale, // 文字大小随缩放调整
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

    print('🎨 === ZoomedCropPainter.paint 结束 ===\n');
  }

  @override
  bool shouldRepaint(ZoomedCropPainter oldDelegate) {
    return imageSize != oldDelegate.imageSize ||
        renderSize != oldDelegate.renderSize ||
        cropX != oldDelegate.cropX ||
        cropY != oldDelegate.cropY ||
        cropWidth != oldDelegate.cropWidth ||
        cropHeight != oldDelegate.cropHeight ||
        contentRotation != oldDelegate.contentRotation ||
        flipHorizontal != oldDelegate.flipHorizontal ||
        flipVertical != oldDelegate.flipVertical ||
        containerSize != oldDelegate.containerSize ||
        zoomScale != oldDelegate.zoomScale ||
        panOffset != oldDelegate.panOffset;
  }
}
