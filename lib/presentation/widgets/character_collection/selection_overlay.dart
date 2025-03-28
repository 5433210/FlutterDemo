import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../utils/coordinate_transformer.dart';
import '../../providers/character/tool_mode_provider.dart';

/// 调整大小的模式
enum ResizeMode {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// 选框覆盖层
class SelectionOverlay extends StatefulWidget {
  final List<CharacterRegion> regions;
  final Set<String> selectedIds;
  final Tool toolMode;
  final TransformationController transformationController;
  final Size imageSize;
  final Size viewportSize;
  final void Function(Rect rect) onRegionCreated;
  final void Function(String id) onRegionSelected;
  final void Function(String id, Rect rect) onRegionUpdated;

  const SelectionOverlay({
    Key? key,
    required this.regions,
    required this.selectedIds,
    required this.toolMode,
    required this.transformationController,
    required this.imageSize,
    required this.viewportSize,
    required this.onRegionCreated,
    required this.onRegionSelected,
    required this.onRegionUpdated,
  }) : super(key: key);

  @override
  State<SelectionOverlay> createState() => _SelectionOverlayState();
}

/// 选框可视化组件
class _RegionBox extends StatelessWidget {
  final bool isSelected;
  final bool isDrawing;
  final bool isResizing;
  final void Function(ResizeMode)? onResizeStart;
  final ValueChanged<Offset>? onResize;
  final VoidCallback? onResizeEnd;
  final VoidCallback? onTap;

  const _RegionBox({
    Key? key,
    this.isSelected = false,
    this.isDrawing = false,
    this.isResizing = false,
    this.onResizeStart,
    this.onResize,
    this.onResizeEnd,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _getBorderColor(),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            if (!isDrawing) ...[
              _buildResizeHandle(ResizeMode.topLeft, Alignment.topLeft),
              _buildResizeHandle(ResizeMode.topRight, Alignment.topRight),
              _buildResizeHandle(ResizeMode.bottomLeft, Alignment.bottomLeft),
              _buildResizeHandle(ResizeMode.bottomRight, Alignment.bottomRight),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResizeHandle(ResizeMode mode, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanStart: (_) => onResizeStart?.call(mode),
        onPanUpdate: (details) => onResize?.call(details.delta),
        onPanEnd: (_) => onResizeEnd?.call(),
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _getBorderColor(),
              width: 2,
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Color _getBorderColor() {
    if (isDrawing) return Colors.blue;
    if (isSelected) return Colors.blue;
    if (isResizing) return Colors.orange;
    return Colors.green;
  }
}

class _SelectionOverlayState extends State<SelectionOverlay> {
  // 最小选框尺寸（图像坐标系）
  static const double minRegionSize = 20.0;
  // 选框相关状态
  Offset? _startPoint;
  Offset? _currentPoint;
  String? _draggingId;
  bool _isResizing = false;

  ResizeMode? _resizeMode;

  // 坐标转换器
  late CoordinateTransformer _transformer;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.precise, // 使用十字光标更清晰地表示选择模式
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 现有选框
          ...widget.regions.map((region) => _buildRegion(region)),

          // 当前正在绘制的选框
          if (_startPoint != null && _currentPoint != null)
            _buildNewRegion(_startPoint!, _currentPoint!),

          // 使用原生监听器代替GestureDetector
          Positioned.fill(
            child: Listener(
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              behavior: HitTestBehavior.translucent,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(SelectionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transformationController != widget.transformationController ||
        oldWidget.imageSize != widget.imageSize ||
        oldWidget.viewportSize != widget.viewportSize) {
      _updateTransformer();
    }
  }

  @override
  void initState() {
    super.initState();
    _updateTransformer();
  }

  Widget _buildNewRegion(Offset start, Offset end) {
    try {
      // 直接转换为图像坐标
      final imageStart = _transformer.viewportToImageCoordinate(start);
      final imageEnd = _transformer.viewportToImageCoordinate(end);

      // 创建并规范化图像坐标系中的矩形
      final imageRect = _normalizeRect(Rect.fromPoints(imageStart, imageEnd));

      // 转换到视口坐标系显示
      final displayRect = _transformer.imageRectToViewportRect(imageRect);

      AppLogger.debug('预览选框', data: {
        'imageRect': _formatRect(imageRect),
        'displayRect': _formatRect(displayRect)
      });

      return Positioned.fromRect(
        rect: displayRect,
        child: const _RegionBox(isDrawing: true),
      );
    } catch (e) {
      AppLogger.error('构建选框预览失败', error: e);
      return const SizedBox.shrink();
    }
  }

  Widget _buildRegion(CharacterRegion region) {
    try {
      // 使用新的坐标转换方法
      final viewportRect = _transformer.imageRectToViewportRect(region.rect);
      final isSelected = widget.selectedIds.contains(region.id);

      return Positioned.fromRect(
        rect: viewportRect,
        child: _RegionBox(
          isSelected: isSelected,
          isResizing: _isResizing && _draggingId == region.id,
          onResizeStart: (mode) => _startResizing(region.id, mode),
          onResize: (delta) => _handleResize(region.id, delta),
          onResizeEnd: _endResizing,
          onTap: () => _handleRegionTap(region.id),
        ),
      );
    } catch (e) {
      AppLogger.error('构建选框失败', error: e, data: {'regionId': region.id});
      return const SizedBox.shrink();
    }
  }

  /// 计算调整大小后的矩形
  Rect _calculateNewRect(Rect oldRect, Offset delta) {
    switch (_resizeMode) {
      case ResizeMode.topLeft:
        return _normalizeRect(Rect.fromPoints(
          oldRect.bottomRight,
          Offset(oldRect.left + delta.dx, oldRect.top + delta.dy),
        ));
      case ResizeMode.topRight:
        return _normalizeRect(Rect.fromPoints(
          oldRect.bottomLeft,
          Offset(oldRect.right + delta.dx, oldRect.top + delta.dy),
        ));
      case ResizeMode.bottomLeft:
        return _normalizeRect(Rect.fromPoints(
          oldRect.topRight,
          Offset(oldRect.left + delta.dx, oldRect.bottom + delta.dy),
        ));
      case ResizeMode.bottomRight:
        return _normalizeRect(Rect.fromPoints(
          oldRect.topLeft,
          Offset(oldRect.right + delta.dx, oldRect.bottom + delta.dy),
        ));
      default:
        return oldRect;
    }
  }

  void _endResizing() {
    setState(() {
      _draggingId = null;
      _isResizing = false;
      _resizeMode = null;
    });
  }

  // 辅助方法，用于格式化矩形
  String _formatRect(Rect rect) {
    return '${rect.left.toInt()},${rect.top.toInt()},${rect.width.toInt()},${rect.height.toInt()}';
  }

  void _handlePanCancel() {}

  // 移除不再使用的方法
  void _handlePanDown(DragDownDetails details) {}

  void _handlePanEnd(DragEndDetails details) {}

  void _handlePanStart(DragStartDetails details) {}
  void _handlePanUpdate(DragUpdateDetails details) {}

  // 使用原生指针事件代替手势检测器
  void _handlePointerDown(PointerDownEvent event) {
    if (widget.toolMode != Tool.select) return;

    AppLogger.debug('指针按下', data: {
      'position':
          '${event.localPosition.dx.toInt()},${event.localPosition.dy.toInt()}'
    });

    setState(() {
      _startPoint = event.localPosition;
      _currentPoint = event.localPosition;
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (widget.toolMode != Tool.select || _startPoint == null) return;

    // 只有当移动足够距离时才更新
    final distance = (event.localPosition - _startPoint!).distance;
    if (distance < 2) return; // 忽略很小的移动

    setState(() {
      _currentPoint = event.localPosition;
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_startPoint == null ||
        _currentPoint == null ||
        widget.toolMode != Tool.select) {
      _resetSelectionState();
      return;
    }

    try {
      // 计算拖动的距离，如果太短可能是点击而非拖动
      final dragDistance = (_currentPoint! - _startPoint!).distance;

      if (dragDistance < 5) {
        // 距离太短，可能是意外点击，不处理
        _resetSelectionState();
        return;
      }

      // 记录框选的视口坐标
      AppLogger.debug('框选视口坐标', data: {
        'start': '${_startPoint!.dx.toInt()},${_startPoint!.dy.toInt()}',
        'end': '${_currentPoint!.dx.toInt()},${_currentPoint!.dy.toInt()}'
      });

      // 转换为视图坐标 (添加这部分)
      final viewStartPoint =
          _transformer.viewportToViewCoordinate(_startPoint!);
      final viewEndPoint =
          _transformer.viewportToViewCoordinate(_currentPoint!);

      // 记录视图坐标 (新增)
      AppLogger.debug('框选视图坐标', data: {
        'start': '${viewStartPoint.dx.toInt()},${viewStartPoint.dy.toInt()}',
        'end': '${viewEndPoint.dx.toInt()},${viewEndPoint.dy.toInt()}',
        'coordinateSystem': '视图坐标系(图像左上角为原点)',
        'scale': _transformer.currentScale,
        'displayRect': _formatRect(_transformer.displayRect)
      });

      // 记录完整的坐标转换过程(用于调试)
      _transformer.logCoordinateConversion(_startPoint!);
      _transformer.logCoordinateConversion(_currentPoint!);

      // 转换起点和终点到图像坐标系
      final startPoint = _transformer.viewportToImageCoordinate(_startPoint!);
      final endPoint = _transformer.viewportToImageCoordinate(_currentPoint!);

      // 创建并规范化图像坐标系中的矩形
      final rect = _normalizeRect(Rect.fromPoints(startPoint, endPoint));

      // 详细记录转换过程
      AppLogger.debug('框选坐标转换结果', data: {
        'viewportStart':
            '${_startPoint!.dx.toInt()},${_startPoint!.dy.toInt()}',
        'viewportEnd':
            '${_currentPoint!.dx.toInt()},${_currentPoint!.dy.toInt()}',
        'viewStart':
            '${viewStartPoint.dx.toInt()},${viewStartPoint.dy.toInt()}',
        'viewEnd': '${viewEndPoint.dx.toInt()},${viewEndPoint.dy.toInt()}',
        'imageStart': '${startPoint.dx.toInt()},${startPoint.dy.toInt()}',
        'imageEnd': '${endPoint.dx.toInt()},${endPoint.dy.toInt()}',
        'finalImageRect':
            '${rect.left.toInt()},${rect.top.toInt()},${rect.width.toInt()},${rect.height.toInt()}',
      });

      // 检查选框是否足够大
      if (rect.width >= minRegionSize && rect.height >= minRegionSize) {
        widget.onRegionCreated(rect);
      } else {
        AppLogger.warning('选框太小，忽略', data: {
          'width': rect.width,
          'height': rect.height,
          'minSize': minRegionSize
        });
      }
    } catch (e) {
      AppLogger.error('选框坐标转换错误', error: e, data: {
        'viewportStart': _startPoint != null
            ? '${_startPoint!.dx.toInt()},${_startPoint!.dy.toInt()}'
            : 'null',
        'viewportEnd': _currentPoint != null
            ? '${_currentPoint!.dx.toInt()},${_currentPoint!.dy.toInt()}'
            : 'null',
        'scale': _transformer.currentScale,
        'imageSize': '${widget.imageSize.width}x${widget.imageSize.height}',
      });
    } finally {
      _resetSelectionState();
    }
  }

  void _handleRegionTap(String id) {
    widget.onRegionSelected(id);
  }

  // 处理调整大小时的坐标转换，关注缩放比例
  void _handleResize(String id, Offset screenDelta) {
    try {
      final region = widget.regions.firstWhere((r) => r.id == id);

      // 将屏幕增量转换为图像坐标系的增量
      final scale = _transformer.actualScale;
      final imageDelta = Offset(screenDelta.dx / scale, screenDelta.dy / scale);

      AppLogger.debug('调整大小', data: {
        'id': id,
        'screenDelta': '${screenDelta.dx.toInt()},${screenDelta.dy.toInt()}',
        'scale': scale.toStringAsFixed(3),
        'imageDelta':
            '${imageDelta.dx.toStringAsFixed(2)},${imageDelta.dy.toStringAsFixed(2)}'
      });

      // 计算新矩形并确保在图像范围内
      final newRect =
          _normalizeRect(_calculateNewRect(region.rect, imageDelta));

      // 检查最小尺寸要求
      if (newRect.width >= minRegionSize && newRect.height >= minRegionSize) {
        widget.onRegionUpdated(id, newRect);
      } else {
        AppLogger.debug('选框太小', data: {
          'width': newRect.width.toInt(),
          'height': newRect.height.toInt(),
          'minSize': minRegionSize
        });
      }
    } catch (e) {
      AppLogger.error('调整选框大小失败', error: e);
    }
  }

  /// 标准化矩形，确保宽高都是正数且在图像范围内
  Rect _normalizeRect(Rect rect) {
    final left = math.min(rect.left, rect.right);
    final top = math.min(rect.top, rect.bottom);
    final right = math.max(rect.left, rect.right);
    final bottom = math.max(rect.top, rect.bottom);

    return Rect.fromLTRB(
      math.max(0.0, math.min(left, widget.imageSize.width)),
      math.max(0.0, math.min(top, widget.imageSize.height)),
      math.max(0.0, math.min(right, widget.imageSize.width)),
      math.max(0.0, math.min(bottom, widget.imageSize.height)),
    );
  }

  // 安全地重置选择状态
  void _resetSelectionState() {
    setState(() {
      _startPoint = null;
      _currentPoint = null;
    });
  }

  void _startResizing(String id, ResizeMode mode) {
    setState(() {
      _draggingId = id;
      _isResizing = true;
      _resizeMode = mode;
    });
  }

  void _updateTransformer() {
    _transformer = CoordinateTransformer(
      transformationController: widget.transformationController,
      imageSize: widget.imageSize,
      viewportSize: widget.viewportSize,
    );

    // 记录转换器状态，帮助调试
    if (widget.toolMode == Tool.select) {
      AppLogger.debug('更新坐标转换器', data: {
        'imageSize': '${widget.imageSize.width}x${widget.imageSize.height}',
        'viewportSize':
            '${widget.viewportSize.width}x${widget.viewportSize.height}',
        'scale': _transformer.currentScale,
      });
    }
  }
}
