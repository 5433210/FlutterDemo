import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/practice/practice_edit_controller.dart';
import '../helpers/element_utils.dart';

/// Handles gestures on the canvas like tapping, panning and zooming
class CanvasGestureHandler {
  final PracticeEditController controller;
  final Function(bool, Offset, Offset, Map<String, Offset>) onDragStart;
  final VoidCallback onDragUpdate;
  final VoidCallback onDragEnd;

  // Drag tracking
  bool _isDragging = false;
  Offset _dragStart = Offset.zero;
  Offset _elementStartPosition = Offset.zero;
  final Map<String, Offset> _elementStartPositions = {};

  // 记录平移开始时的选中元素，确保平移不会改变选中状态
  List<String> _panStartSelectedElementIds = [];

  CanvasGestureHandler({
    required this.controller,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  /// Handle pan end on canvas
  void handlePanEnd(DragEndDetails details) {
    // 添加日志跟踪
    debugPrint(
        '【平移】handlePanEnd: 拖拽结束，速度=${details.velocity.pixelsPerSecond}, 是否正在拖拽元素=$_isDragging');

    // If in preview mode, don't handle element dragging
    if (controller.state.isPreviewMode) return;

    if (_isDragging) {
      _isDragging = false;

      // Finalize positions of all dragged elements
      for (final elementId in controller.state.selectedElementIds) {
        final element = controller.state.currentPageElements.firstWhere(
          (e) => e['id'] == elementId,
          orElse: () => <String, dynamic>{},
        );

        if (element.isEmpty) continue;

        // Skip locked elements or elements on locked layers
        if (element['locked'] == true) continue;

        final layerId = element['layerId'] as String?;
        if (layerId != null) {
          final layer = controller.state.getLayerById(layerId);
          if (layer != null && layer['isLocked'] == true) {
            continue;
          }
        }

        // Get current position
        final x = (element['x'] as num).toDouble();
        final y = (element['y'] as num).toDouble();

        // Finalize element position
        controller.updateElementProperties(elementId, {
          'x': x,
          'y': y,
        });
      }

      onDragEnd();
    } else {
      // 添加日志跟踪 - 平移结束
      debugPrint('【平移】handlePanEnd: 平移画布结束');

      // 如果平移开始时有选中的元素，恢复选中状态
      if (_panStartSelectedElementIds.isNotEmpty) {
        debugPrint(
            '【平移】handlePanEnd: 恢复平移前的选中状态: $_panStartSelectedElementIds');

        // 清除当前选中状态
        controller.clearSelection();

        // 恢复平移前的选中状态
        for (final elementId in _panStartSelectedElementIds) {
          controller.selectElement(elementId, isMultiSelect: true);
        }

        // 清空记录
        _panStartSelectedElementIds = [];
      }

      onDragEnd();
    }
  }

  /// Handle pan start on canvas
  void handlePanStart(
      DragStartDetails details, List<Map<String, dynamic>> elements) {
    // 记录拖拽起始位置，无论是否在预览模式
    _dragStart = details.localPosition;

    // 检查是否点击在任何元素上（无论是否选中）
    bool hitAnyElement = false;

    // 如果在预览模式下，我们只需要记录起始位置用于平移
    if (controller.state.isPreviewMode) {
      _isDragging = false;

      // 直接使用起始位置
      _elementStartPosition = Offset.zero;

      onDragStart(false, _dragStart, _elementStartPosition, {});
      return;
    }

    // 从顶层元素开始检查（视觉上的顶层，即数组的末尾）
    for (int i = elements.length - 1; i >= 0; i--) {
      final element = elements[i];
      final id = element['id'] as String;
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();

      // 检查元素是否隐藏
      final isHidden = element['hidden'] == true;
      if (isHidden) continue;

      // 检查图层是否隐藏
      final layerId = element['layerId'] as String?;
      bool isLayerHidden = false;
      if (layerId != null) {
        final layer = controller.state.getLayerById(layerId);
        if (layer != null) {
          isLayerHidden = layer['isVisible'] == false;
        }
      }
      if (isLayerHidden) continue;

      // 检查是否点击在元素内部
      final bool isInside = details.localPosition.dx >= x &&
          details.localPosition.dx <= x + width &&
          details.localPosition.dy >= y &&
          details.localPosition.dy <= y + height;

      if (isInside) {
        hitAnyElement = true;

        // 如果点击在选中的元素上
        if (controller.state.selectedElementIds.contains(id)) {
          // 检查元素和图层是否锁定
          final isLocked = element['locked'] == true;
          bool isLayerLocked = false;
          if (layerId != null) {
            final layer = controller.state.getLayerById(layerId);
            if (layer != null) {
              isLayerLocked = layer['isLocked'] == true;
            }
          }

          // 如果元素和图层都未锁定，则开始拖拽
          if (!isLocked && !isLayerLocked) {
            _isDragging = true;
            _elementStartPositions.clear();

            // 记录所有选中元素的起始位置
            for (final selectedId in controller.state.selectedElementIds) {
              final selectedElement = ElementUtils.findElementById(
                  elements.cast<Map<String, dynamic>>(), selectedId);
              if (selectedElement != null) {
                _elementStartPositions[selectedId] = Offset(
                  (selectedElement['x'] as num).toDouble(),
                  (selectedElement['y'] as num).toDouble(),
                );
              }
            }

            onDragStart(
                _isDragging, _dragStart, Offset(x, y), _elementStartPositions);
            return; // 找到了可拖拽的选中元素，直接返回
          }
        }
      }
    }

    // 如果没有点击在任何可拖拽的选中元素上，则准备平移画布
    _isDragging = false;

    // 直接使用起始位置
    _elementStartPosition = Offset.zero;

    // 保存当前选中状态，确保平移不会改变选中状态
    _panStartSelectedElementIds =
        List.from(controller.state.selectedElementIds);

    // 添加日志跟踪
    debugPrint(
        '【平移】handlePanStart: 准备平移画布，起始位置=$_dragStart, 预览模式=${controller.state.isPreviewMode}, 是否拖拽元素=$_isDragging');
    debugPrint(
        '【平移】handlePanStart: 记录平移开始时的选中元素: $_panStartSelectedElementIds');

    onDragStart(false, _dragStart, _elementStartPosition, {});

    // 如果点击在空白区域且不按住Ctrl/Shift键，则清除选择
    // 注意：我们仍然清除选择，但会在平移结束时恢复
    if (!hitAnyElement && !controller.state.isCtrlOrShiftPressed) {
      controller.clearSelection();
    }
  }

  /// Handle pan update on canvas
  void handlePanUpdate(DragUpdateDetails details) {
    // 获取当前位置
    final currentPosition = details.localPosition;

    // 在预览模式下，只处理画布平移
    if (controller.state.isPreviewMode) {
      // 计算拖拽偏移量
      final dx = currentPosition.dx - _dragStart.dx;
      final dy = currentPosition.dy - _dragStart.dy;

      // 记录拖拽信息，让父组件处理平移
      _elementStartPosition = Offset(dx, dy);

      onDragUpdate();
      return;
    }

    // 如果正在拖拽选中的元素
    if (_isDragging && controller.state.selectedElementIds.isNotEmpty) {
      final dx = currentPosition.dx - _dragStart.dx;
      final dy = currentPosition.dy - _dragStart.dy;

      // 更新所有选中元素的位置
      for (final elementId in controller.state.selectedElementIds) {
        // 跳过锁定图层上的元素
        final element = controller.state.currentPageElements.firstWhere(
          (e) => e['id'] == elementId,
          orElse: () => <String, dynamic>{},
        );

        if (element.isEmpty) continue;

        // 跳过锁定的元素
        if (element['locked'] == true) continue;

        // 跳过锁定或隐藏图层上的元素
        final layerId = element['layerId'] as String?;
        if (layerId != null) {
          final layer = controller.state.getLayerById(layerId);
          if (layer != null) {
            if (layer['isLocked'] == true || layer['isVisible'] == false) {
              continue;
            }
          }
        }

        // 获取元素的起始位置
        final startPosition = _elementStartPositions[elementId];
        if (startPosition == null) continue;

        // 计算新位置
        double newX = startPosition.dx + dx;
        double newY = startPosition.dy + dy;

        // 如果启用了网格吸附
        if (controller.state.snapEnabled) {
          final gridSize = controller.state.gridSize;
          newX = (newX / gridSize).round() * gridSize;
          newY = (newY / gridSize).round() * gridSize;
        }

        // 更新元素位置
        controller.updateElementPropertiesDuringDrag(elementId, {
          'x': newX,
          'y': newY,
        });
      }

      onDragUpdate();
    }
    // 如果不是在拖拽元素，则平移画布
    else {
      // 计算拖拽偏移量
      final dx = currentPosition.dx - _dragStart.dx;
      final dy = currentPosition.dy - _dragStart.dy;

      // 检查偏移量是否有效
      if (dx.isNaN || dy.isNaN) {
        debugPrint('【平移】handlePanUpdate: 警告 - 偏移量包含NaN值！');
        return;
      }

      // 记录拖拽信息，让父组件处理平移
      final oldPosition = _elementStartPosition;
      _elementStartPosition = Offset(dx, dy);

      // 添加日志跟踪
      debugPrint(
          '【平移】handlePanUpdate: 平移画布，当前位置=$currentPosition, 起始位置=$_dragStart, 偏移量=($dx, $dy), 旧偏移量=$oldPosition');

      // 确保调用回调
      onDragUpdate();

      // 检查回调后的状态
      debugPrint('【平移】handlePanUpdate: 回调后，偏移量=$_elementStartPosition');
    }
  }

  /// Handle right click on canvas
  void handleSecondaryTapUp(
      TapUpDetails details, List<Map<String, dynamic>> elements) {
    // If in preview mode, don't handle secondary tap
    if (controller.state.isPreviewMode) return;

    // Check if clicked on a selected element
    bool hitSelectedElement = false;

    for (int i = elements.length - 1; i >= 0; i--) {
      final element = elements[i];
      final id = element['id'] as String;
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();

      // Check if clicked inside the element
      final bool isInside = details.localPosition.dx >= x &&
          details.localPosition.dx <= x + width &&
          details.localPosition.dy >= y &&
          details.localPosition.dy <= y + height;

      if (isInside && controller.state.selectedElementIds.contains(id)) {
        hitSelectedElement = true;

        // Show context menu for the element
        _showElementContextMenu(details.globalPosition, id);
        break;
      }
    }

    if (!hitSelectedElement) {
      // Right click on blank area or non-selected element
      controller.clearSelection();
      _isDragging = false;
      onDragStart(false, Offset.zero, Offset.zero, {});
    }
  }

  /// Handle tap up event on canvas
  void handleTapUp(TapUpDetails details, List<Map<String, dynamic>> elements) {
    // If in preview mode, don't handle selection
    if (controller.state.isPreviewMode) return;

    // If clicking in a blank area, cancel selection
    bool hitElement = false;

    // 检查是否按下了Ctrl或Shift键
    final isMultiSelect = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isShiftPressed;

    debugPrint(
        '【选择】handleTapUp: 多选模式=$isMultiSelect, 控制键=${HardwareKeyboard.instance.isControlPressed}, 换档键=${HardwareKeyboard.instance.isShiftPressed}');

    // 从顶层元素开始检查（视觉上的顶层，即数组的末尾）
    for (int i = elements.length - 1; i >= 0; i--) {
      final element = elements[i];
      final id = element['id'] as String;
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();
      final isLocked = element['locked'] == true;
      final isHidden = element['hidden'] == true;

      // Check layer lock and visibility state
      final layerId = element['layerId'] as String?;
      bool isLayerLocked = false;
      bool isLayerHidden = false;

      if (layerId != null) {
        final layer = controller.state.getLayerById(layerId);
        if (layer != null) {
          isLayerLocked = layer['isLocked'] == true;
          isLayerHidden = layer['isVisible'] == false;
        }
      }

      // Skip hidden elements
      if (isHidden || isLayerHidden) continue;

      // Check if clicked inside the element
      final bool isInside = details.localPosition.dx >= x &&
          details.localPosition.dx <= x + width &&
          details.localPosition.dy >= y &&
          details.localPosition.dy <= y + height;

      if (isInside) {
        hitElement = true;

        // 检查元素是否已经被选中
        final isCurrentlySelected =
            controller.state.selectedElementIds.contains(id);

        // 如果元素或图层被锁定，只允许选择，不允许拖拽
        if (isLocked || isLayerLocked) {
          // Clear layer selection
          controller.state.selectedLayerId = null;
          controller.selectElement(id, isMultiSelect: isMultiSelect);
          break;
        } else {
          // 清除图层选择
          controller.state.selectedLayerId = null;

          // 选择元素
          controller.selectElement(id, isMultiSelect: isMultiSelect);

          // 如果不是多选模式，或者元素之前没有被选中，准备拖拽
          if (!isMultiSelect || !isCurrentlySelected) {
            // 准备拖拽
            _isDragging = true;
            _dragStart = details.localPosition;
            _elementStartPosition = Offset(x, y);
            _elementStartPositions.clear();

            // 记录所有选中元素的起始位置
            for (final selectedId in controller.state.selectedElementIds) {
              final selectedElement = elements.firstWhere(
                (e) => e['id'] == selectedId,
                orElse: () => <String, dynamic>{},
              );

              if (selectedElement.isNotEmpty) {
                _elementStartPositions[selectedId] = Offset(
                  (selectedElement['x'] as num).toDouble(),
                  (selectedElement['y'] as num).toDouble(),
                );
              }
            }

            // onDragStart(_isDragging, _dragStart, _elementStartPosition,
            //     _elementStartPositions);
          }
        }

        // 找到了点击的元素，不需要继续检查
        break;
      }
    }

    if (!hitElement) {
      // Click in blank area, cancel selection
      debugPrint('【选择】handleTapUp: 点击空白区域，清除选择');
      controller.clearSelection();
      // _isDragging = false;
      // onDragStart(false, Offset.zero, Offset.zero, {});
    }
  }

  /// Show context menu for an element
  void _showElementContextMenu(Offset position, String elementId) {
    // This method would show a context menu at the given position
    // Implementation would depend on your context menu system
  }
}
