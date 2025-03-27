import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/character/character_region.dart';
import '../../providers/character/tool_mode_provider.dart';

class SelectionOverlay extends StatefulWidget {
  final List<CharacterRegion> regions;
  final Set<String> selectedIds;
  final Tool toolMode;
  final TransformationController transformationController;
  final Function(Rect) onRegionCreated;
  final Function(String) onRegionSelected;
  final Function(String, Rect) onRegionUpdated;

  const SelectionOverlay({
    Key? key,
    required this.regions,
    required this.selectedIds,
    required this.toolMode,
    required this.transformationController,
    required this.onRegionCreated,
    required this.onRegionSelected,
    required this.onRegionUpdated,
  }) : super(key: key);

  @override
  State<SelectionOverlay> createState() => _SelectionOverlayState();
}

// 自定义绘制类
class SelectionPainter extends CustomPainter {
  final List<CharacterRegion> regions;
  final Set<String> selectedIds;
  final Rect? selectionRect;
  final TransformationController transformationController;
  final String? adjustingRegionId;
  final int? activeHandleIndex;

  SelectionPainter({
    required this.regions,
    required this.selectedIds,
    this.selectionRect,
    required this.transformationController,
    this.adjustingRegionId,
    this.activeHandleIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制已保存的区域
    for (final region in regions) {
      final isSelected = selectedIds.contains(region.id);
      final isAdjusting = region.id == adjustingRegionId;

      // 设置样式
      final Paint paint = Paint()
        ..color = isSelected || isAdjusting ? Colors.blue : Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected || isAdjusting ? 2.0 : 1.5;

      // 保存画布状态
      canvas.save();

      // 应用旋转
      if (region.rotation != 0) {
        canvas.translate(region.rect.center.dx, region.rect.center.dy);
        canvas.rotate(region.rotation * math.pi / 180);
        canvas.translate(-region.rect.center.dx, -region.rect.center.dy);
      }

      // 绘制区域矩形
      canvas.drawRect(region.rect, paint);

      // 绘制角落手柄（仅当选中或调整时）
      if (isSelected || isAdjusting) {
        _drawHandles(canvas, region.rect);
      }

      // 标注文字（如果有）
      if (region.character.isNotEmpty) {
        final textStyle = TextStyle(
          color: isSelected ? Colors.blue : Colors.green,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        );

        final textSpan = TextSpan(
          text: region.character,
          style: textStyle,
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        // 在区域上方绘制字符
        textPainter.paint(
          canvas,
          Offset(
            region.rect.center.dx - textPainter.width / 2,
            region.rect.top - textPainter.height - 4,
          ),
        );
      }

      // 恢复画布状态
      canvas.restore();
    }

    // 绘制当前选择矩形（如果有）
    if (selectionRect != null) {
      final Paint paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRect(selectionRect!, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SelectionPainter oldDelegate) {
    return regions != oldDelegate.regions ||
        selectedIds != oldDelegate.selectedIds ||
        selectionRect != oldDelegate.selectionRect ||
        adjustingRegionId != oldDelegate.adjustingRegionId ||
        activeHandleIndex != oldDelegate.activeHandleIndex ||
        transformationController.value !=
            oldDelegate.transformationController.value;
  }

  // 绘制调整手柄
  void _drawHandles(Canvas canvas, Rect rect) {
    final handles = [
      Offset(rect.left, rect.top), // 左上
      Offset(rect.left + rect.width / 2, rect.top), // 上中
      Offset(rect.right, rect.top), // 右上
      Offset(rect.right, rect.top + rect.height / 2), // 右中
      Offset(rect.right, rect.bottom), // 右下
      Offset(rect.left + rect.width / 2, rect.bottom), // 下中
      Offset(rect.left, rect.bottom), // 左下
      Offset(rect.left, rect.top + rect.height / 2), // 左中
    ];

    for (int i = 0; i < handles.length; i++) {
      final isActive = i == activeHandleIndex;

      final fillPaint = Paint()
        ..color = isActive ? Colors.blue : Colors.white
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // 绘制手柄
      canvas.drawCircle(handles[i], 5, fillPaint);
      canvas.drawCircle(handles[i], 5, strokePaint);
    }
  }
}

class _SelectionOverlayState extends State<SelectionOverlay> {
  // 拖动状态
  Offset? _startPoint;
  Offset? _currentPoint;

  // 调整状态
  String? _adjustingRegionId;
  int? _activeHandleIndex;
  Rect? _initialRect;

  // 移动状态
  String? _movingRegionId;
  Offset? _initialPointerPosition;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: CustomPaint(
        painter: SelectionPainter(
          regions: widget.regions,
          selectedIds: widget.selectedIds,
          selectionRect: _getSelectionRect(),
          transformationController: widget.transformationController,
          adjustingRegionId: _adjustingRegionId,
          activeHandleIndex: _activeHandleIndex,
        ),
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  // 查找点击位置上的调整手柄索引
  int? _findHandleAtPosition(Offset position, CharacterRegion region) {
    final handles = _getHandlePositions(region.rect);
    const handleSize = 16.0; // 手柄点击范围

    for (int i = 0; i < handles.length; i++) {
      final handle = handles[i];
      final handleRect = Rect.fromCenter(
        center: handle,
        width: handleSize,
        height: handleSize,
      );

      if (handleRect.contains(position)) {
        return i;
      }
    }

    return null;
  }

  // 查找指定位置的区域
  CharacterRegion? _findRegionAtPosition(Offset position) {
    // 按照添加顺序倒序检查，以便优先选择最近添加的区域
    for (int i = widget.regions.length - 1; i >= 0; i--) {
      final region = widget.regions[i];

      // 创建包含旋转的转换矩阵
      final transform = Matrix4.identity()
        ..translate(region.rect.center.dx, region.rect.center.dy)
        ..rotateZ(region.rotation * math.pi / 180)
        ..translate(-region.rect.center.dx, -region.rect.center.dy);

      // 创建一个变换路径来测试点击
      final path = Path();
      path.addRect(region.rect);
      path.transform(transform.storage);

      if (path.contains(position)) {
        return region;
      }
    }

    return null;
  }

  // 获取区域的调整手柄位置
  List<Offset> _getHandlePositions(Rect rect) {
    return [
      Offset(rect.left, rect.top), // 左上
      Offset(rect.left + rect.width / 2, rect.top), // 上中
      Offset(rect.right, rect.top), // 右上
      Offset(rect.right, rect.top + rect.height / 2), // 右中
      Offset(rect.right, rect.bottom), // 右下
      Offset(rect.left + rect.width / 2, rect.bottom), // 下中
      Offset(rect.left, rect.bottom), // 左下
      Offset(rect.left, rect.top + rect.height / 2), // 左中
    ];
  }

  // 获取当前选择矩形（在绘制新选框时使用）
  Rect? _getSelectionRect() {
    if (_startPoint == null || _currentPoint == null) {
      return null;
    }

    final left = math.min(_startPoint!.dx, _currentPoint!.dx);
    final top = math.min(_startPoint!.dy, _currentPoint!.dy);
    final right = math.max(_startPoint!.dx, _currentPoint!.dx);
    final bottom = math.max(_startPoint!.dy, _currentPoint!.dy);

    return Rect.fromLTRB(left, top, right, bottom);
  }

  // 处理拖动结束
  void _handlePanEnd(DragEndDetails details) {
    if (_adjustingRegionId != null || _movingRegionId != null) {
      // 已完成调整或移动
      setState(() {
        _adjustingRegionId = null;
        _activeHandleIndex = null;
        _movingRegionId = null;
        _initialRect = null;
        _initialPointerPosition = null;
      });
    } else if (_startPoint != null &&
        _currentPoint != null &&
        widget.toolMode == Tool.selection) {
      // 完成选择操作，创建新区域
      final selectionRect = _getSelectionRect();

      // 确保选框大小合适（防止点击误操作）
      if (selectionRect != null &&
          selectionRect.width > 20 &&
          selectionRect.height > 20) {
        widget.onRegionCreated(selectionRect);
      }

      setState(() {
        _startPoint = null;
        _currentPoint = null;
      });
    }
  }

  // 处理拖动开始
  void _handlePanStart(DragStartDetails details) {
    final position = details.localPosition;

    switch (widget.toolMode) {
      case Tool.selection:
        // 在选择模式下，开始新的选框
        setState(() {
          _startPoint = position;
          _currentPoint = position;
          _adjustingRegionId = null;
          _movingRegionId = null;
        });
        break;

      case Tool.multiSelect:
        // 在多选模式下，检查是否点击了已有区域
        final selectedRegion = _findRegionAtPosition(position);
        if (selectedRegion != null) {
          // 选中区域
          widget.onRegionSelected(selectedRegion.id);

          // 检查是否点击了调整手柄
          final handleIndex = _findHandleAtPosition(position, selectedRegion);
          if (handleIndex != null) {
            // 开始调整区域
            setState(() {
              _adjustingRegionId = selectedRegion.id;
              _activeHandleIndex = handleIndex;
              _initialRect = selectedRegion.rect;
              _initialPointerPosition = position;
              _movingRegionId = null;
              _startPoint = null;
              _currentPoint = null;
            });
          } else if (selectedRegion.rect.contains(position)) {
            // 开始移动区域
            setState(() {
              _movingRegionId = selectedRegion.id;
              _initialRect = selectedRegion.rect;
              _initialPointerPosition = position;
              _adjustingRegionId = null;
              _startPoint = null;
              _currentPoint = null;
            });
          }
        }
        break;

      default:
        // 其他模式不处理拖动
        break;
    }
  }

  // 处理拖动更新
  void _handlePanUpdate(DragUpdateDetails details) {
    final position = details.localPosition;

    if (_adjustingRegionId != null &&
        _initialRect != null &&
        _initialPointerPosition != null &&
        _activeHandleIndex != null) {
      // 正在调整区域
      final delta = position - _initialPointerPosition!;
      final newRect = _resizeRect(_initialRect!, _activeHandleIndex!, delta);

      setState(() {
        // 更新区域大小
        widget.onRegionUpdated(_adjustingRegionId!, newRect);
      });
    } else if (_movingRegionId != null &&
        _initialRect != null &&
        _initialPointerPosition != null) {
      // 正在移动区域
      final delta = position - _initialPointerPosition!;
      final newRect = _initialRect!.translate(delta.dx, delta.dy);

      setState(() {
        // 更新区域位置
        widget.onRegionUpdated(_movingRegionId!, newRect);
      });
    } else if (_startPoint != null) {
      // 正在绘制新的选框
      setState(() {
        _currentPoint = position;
      });
    }
  }

  // 调整矩形大小
  Rect _resizeRect(Rect rect, int handleIndex, Offset delta) {
    double left = rect.left;
    double top = rect.top;
    double right = rect.right;
    double bottom = rect.bottom;

    switch (handleIndex) {
      case 0: // 左上
        left += delta.dx;
        top += delta.dy;
        break;
      case 1: // 上中
        top += delta.dy;
        break;
      case 2: // 右上
        right += delta.dx;
        top += delta.dy;
        break;
      case 3: // 右中
        right += delta.dx;
        break;
      case 4: // 右下
        right += delta.dx;
        bottom += delta.dy;
        break;
      case 5: // 下中
        bottom += delta.dy;
        break;
      case 6: // 左下
        left += delta.dx;
        bottom += delta.dy;
        break;
      case 7: // 左中
        left += delta.dx;
        break;
    }

    // 确保矩形不会翻转（宽高始终为正）
    if (left > right) {
      final temp = left;
      left = right;
      right = temp;

      // 更新手柄索引（左右对调）
      if (handleIndex == 0)
        _activeHandleIndex = 2;
      else if (handleIndex == 2)
        _activeHandleIndex = 0;
      else if (handleIndex == 6)
        _activeHandleIndex = 4;
      else if (handleIndex == 4)
        _activeHandleIndex = 6;
      else if (handleIndex == 3)
        _activeHandleIndex = 7;
      else if (handleIndex == 7) _activeHandleIndex = 3;
    }

    if (top > bottom) {
      final temp = top;
      top = bottom;
      bottom = temp;

      // 更新手柄索引（上下对调）
      if (handleIndex == 0)
        _activeHandleIndex = 6;
      else if (handleIndex == 1)
        _activeHandleIndex = 5;
      else if (handleIndex == 2)
        _activeHandleIndex = 4;
      else if (handleIndex == 6)
        _activeHandleIndex = 0;
      else if (handleIndex == 5)
        _activeHandleIndex = 1;
      else if (handleIndex == 4) _activeHandleIndex = 2;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }
}
