import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../widgets/practice/drag_state_manager.dart';
import '../../../widgets/practice/practice_edit_controller.dart';
import '../helpers/element_utils.dart';

/// Handles gestures on the canvas like tapping, panning and zooming
///
/// Supports the following gestures:
/// - Tapping: Select elements
/// - Panning: Move selected elements or pan the canvas
/// - Selection Box: Create selection box in select mode on empty canvas areas
/// - Element Dragging: Drag selected elements (even when in select mode)
class CanvasGestureHandler {
  final PracticeEditController controller;
  final DragStateManager dragStateManager;
  final Function(bool, Offset, Offset, Map<String, Offset>) onDragStart;
  final VoidCallback onDragUpdate;
  final VoidCallback onDragEnd;
  final double Function() getScaleFactor;
  // Drag tracking - use DragStateManager instead of local state
  Offset _dragStart = Offset.zero;
  Offset _elementStartPosition = Offset.zero;
  final Map<String, Offset> _elementStartPositions = {};

  // Selection box variables
  bool _isSelectionBoxActive = false;
  Offset? _selectionBoxStart;
  Offset? _selectionBoxEnd;
  // 记录平移开始时的选中元素，确保平移不会改变选中状态
  List<String> _panStartSelectedElementIds = [];

  // 追踪是否在画布空白处进行拖拽操作
  bool _isPanningEmptyArea = false;

  // 追踪画布平移的结束位置，用于区分点击和拖拽
  Offset? _panEndPosition;
  
  // 🔧 防止重复创建撤销操作的记录（与SmartCanvasGestureHandler保持一致）
  final Set<String> _recentTranslationOperations = {};
  CanvasGestureHandler({
    required this.controller,
    required this.dragStateManager,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.getScaleFactor,
  });

  /// Get if selection box is active
  bool get isSelectionBoxActive => _isSelectionBoxActive;

  /// Get selection box end position
  Offset? get selectionBoxEnd => _selectionBoxEnd;

  /// Get selection box start position
  Offset? get selectionBoxStart => _selectionBoxStart;

  /// Cancel selection box
  void cancelSelectionBox() {
    _isSelectionBoxActive = false;
    _selectionBoxStart = null;
    _selectionBoxEnd = null;
    onDragUpdate();
  }

  /// Get the selection box rectangle
  Rect? getSelectionBoxRect() {
    if (_selectionBoxStart != null && _selectionBoxEnd != null) {
      return Rect.fromPoints(_selectionBoxStart!, _selectionBoxEnd!);
    }
    return null;
  }

  /// Get the selection box state
  SelectionBoxState getSelectionBoxState() {
    return SelectionBoxState(
      isActive: _isSelectionBoxActive,
      startPoint: _selectionBoxStart,
      endPoint: _selectionBoxEnd,
    );
  }

  /// Handle pan cancel
  void handlePanCancel() {
    EditPageLogger.canvasDebug('平移操作被取消');

    // 重置所有跟踪变量
    _isPanningEmptyArea = false;
    _panStartSelectedElementIds = [];
    _panEndPosition = null;
    _selectionBoxEnd = null;
    _isSelectionBoxActive = false;

    // 通知父组件更新
    onDragEnd();
  }

  /// Handle pan end on canvas
  void handlePanEnd(DragEndDetails details) {
    // Check if we're in select mode and using selection box
    if (controller.state.currentTool == 'select' && _isSelectionBoxActive) {
      _finalizeSelectionBox();
      return;
    }

    // Note: No need to check controller.state.currentTool == 'select' here
    // If _isDragging is true, that means we started dragging elements
    // (even in select mode) and should continue processing the drag end    // 添加日志跟踪
    EditPageLogger.canvasDebug('拖拽结束', 
      data: {
        'velocity': details.velocity.pixelsPerSecond.toString(),
        'isDragging': dragStateManager.isDragging
      });

    // If in preview mode, don't handle element dragging
    if (controller.state.isPreviewMode) return;
    if (dragStateManager.isDragging) {
      // End the current drag operation through DragStateManager
      dragStateManager.endDrag();

      // Lists to hold element IDs, old positions, and new positions for batch update
      final List<String> elementIds = [];
      final List<Map<String, dynamic>> oldPositions = [];
      final List<Map<String, dynamic>> newPositions = [];

      // Collect data for all dragged elements
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

        // Get original position from the start positions map
        final startPosition = _elementStartPositions[elementId];
        if (startPosition == null) continue;

        // Only include elements that actually moved
        if (startPosition.dx != x || startPosition.dy != y) {
          elementIds.add(elementId);
          oldPositions.add({
            'x': startPosition.dx,
            'y': startPosition.dy,
          });
          newPositions.add({
            'x': x,
            'y': y,
          });
        }
      }

      // Create a batch translation operation if any elements moved
      if (elementIds.isNotEmpty) {
        // 🔧 检查是否需要创建撤销操作（防止重复创建）
        final operationKey = '${elementIds.join('_')}_${DateTime.now().millisecondsSinceEpoch ~/ 200}';
        if (!_recentTranslationOperations.contains(operationKey)) {
          _recentTranslationOperations.add(operationKey);
          Timer(const Duration(milliseconds: 500), () {
            _recentTranslationOperations.remove(operationKey);
          });
          
          EditPageLogger.canvasDebug('创建批量平移操作', data: {
            'elementCount': elementIds.length,
            'operationKey': operationKey,
            'source': 'CanvasGestureHandler',
          });
          
          controller.createElementTranslationOperation(
            elementIds: elementIds,
            oldPositions: oldPositions,
            newPositions: newPositions,
          );
        } else {
          EditPageLogger.canvasDebug('跳过重复平移撤销操作', data: {
            'operationKey': operationKey,
            'source': 'CanvasGestureHandler',
          });
        }
      }

      onDragEnd();
    } else {
      // 添加日志跟踪 - 平移结束
      EditPageLogger.canvasDebug('平移画布结束'); // 计算拖拽距离，判断是否为点击还是拖拽
      // 使用专门的平移结束位置，如果没有则说明没有发生平移更新，使用起始位置
      final endPoint = _panEndPosition ?? _dragStart;
      final dragDistance = (_dragStart - endPoint).distance;
      final isClick = dragDistance < 1.0; // 🔧 降低点击检测阈值

      // 添加详细的调试日志
      EditPageLogger.canvasDebug('平移画布详细信息', 
        data: {
          'startPosition': '$_dragStart',
          'endPosition': '$endPoint',
          'panEndPosition': '$_panEndPosition',
          'dragDistance': dragDistance,
          'isClick': isClick,
          'isPanningEmptyArea': _isPanningEmptyArea,
          'isCtrlOrShiftPressed': controller.state.isCtrlOrShiftPressed,
          'panStartSelectedElements': _panStartSelectedElementIds.length
        });

      // 如果是在空白区域的点击（而非拖拽），且不按Ctrl/Shift键，则清除选择
      if (_isPanningEmptyArea &&
          isClick &&
          !controller.state.isCtrlOrShiftPressed) {
        EditPageLogger.canvasDebug('检测到空白区域点击，清除选择');
        controller.clearSelection();
      }
      // 如果是拖拽结束且平移开始时有选中的元素，保持选中状态
      else if (_panStartSelectedElementIds.isNotEmpty) {
        debugPrint(
            '【平移】handlePanEnd: 拖拽结束，保持原有选中状态: $_panStartSelectedElementIds');
      }

      // 重置平移标记
      _isPanningEmptyArea = false;
      // 清空记录
      _panStartSelectedElementIds = [];
      // 清空平移结束位置
      _panEndPosition = null;

      onDragEnd();
    }
  }

  /// Handle pan start on canvas
  void handlePanStart(
      DragStartDetails details, List<Map<String, dynamic>> elements) {
    // Debug information
    debugPrint(
        'handlePanStart - currentTool: ${controller.state.currentTool}, isPreviewMode: ${controller.state.isPreviewMode}');

    // Check if we're in select mode
    if (controller.state.currentTool == 'select' &&
        !controller.state.isPreviewMode) {
      // Check if we're clicking on any selected element first before creating a selection box
      bool hitSelectedElement = false;

      // From top-most element (visually on top, which is last in the array)
      for (int i = elements.length - 1; i >= 0; i--) {
        final element = elements[i];
        final id = element['id'] as String;
        final x = (element['x'] as num).toDouble();
        final y = (element['y'] as num).toDouble();
        final width = (element['width'] as num).toDouble();
        final height = (element['height'] as num).toDouble();

        // Check if element is hidden
        final isHidden = element['hidden'] == true;
        if (isHidden) continue;

        // Check if layer is hidden
        final layerId = element['layerId'] as String?;
        bool isLayerHidden = false;
        if (layerId != null) {
          final layer = controller.state.getLayerById(layerId);
          if (layer != null) {
            isLayerHidden = layer['isVisible'] == false;
          }
        }
        if (isLayerHidden) continue;

        // Check if click is inside the element
        final bool isInside = details.localPosition.dx >= x &&
            details.localPosition.dx <= x + width &&
            details.localPosition.dy >= y &&
            details.localPosition.dy <= y + height;

        // If clicking on a selected element
        if (isInside && controller.state.selectedElementIds.contains(id)) {
          hitSelectedElement = true;

          // Check if element or layer is locked
          final isLocked = element['locked'] == true;
          bool isLayerLocked = false;
          if (layerId != null) {
            final layer = controller.state.getLayerById(layerId);
            if (layer != null) {
              isLayerLocked = layer['isLocked'] == true;
            }
          }

          // If element and layer are not locked, set up for dragging
          if (!isLocked && !isLayerLocked) {
            // Set up dragging for selected elements instead of creating selection box
            _dragStart = details.localPosition;
            _elementStartPositions.clear();

            // Record starting positions of all selected elements
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

            // Start drag through DragStateManager
            dragStateManager.startDrag(
              elementIds: controller.state.selectedElementIds.toSet(),
              startPosition: details.localPosition,
              elementStartPositions: _elementStartPositions,
            );

            // Notify drag started
            onDragStart(dragStateManager.isDragging, _dragStart, Offset(x, y),
                _elementStartPositions);
            debugPrint(
                '【拖拽】Starting drag on selected element in select mode - elementId: $id');
            return; // Exit early since we're now dragging elements
          }
          break; // Found a selected but locked element, don't need to check more
        }
      }

      // If didn't hit any selected element, start selection box
      if (!hitSelectedElement) {
        debugPrint('Starting selection box at ${details.localPosition}');
        // Start drawing selection box
        _isSelectionBoxActive = true;
        _selectionBoxStart = details.localPosition;
        _selectionBoxEnd = details.localPosition;
        onDragUpdate();
        return;
      }
    }

    // 记录拖拽起始位置，无论是否在预览模式
    _dragStart = details.localPosition;

    // 检查是否点击在任何元素上（无论是否选中）
    bool hitAnyElement = false; // 如果在预览模式下，我们只需要记录起始位置用于平移
    if (controller.state.isPreviewMode) {
      // Don't start element dragging in preview mode

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
          } // 如果元素和图层都未锁定，则开始拖拽
          if (!isLocked && !isLayerLocked) {
            _dragStart = details.localPosition;
            _elementStartPositions.clear();

            // 记录所有选中元素的起始位置和完整属性
            final Map<String, Map<String, dynamic>> elementStartProperties = {};
            for (final selectedId in controller.state.selectedElementIds) {
              final selectedElement = ElementUtils.findElementById(
                  elements.cast<Map<String, dynamic>>(), selectedId);
              if (selectedElement != null) {
                _elementStartPositions[selectedId] = Offset(
                  (selectedElement['x'] as num).toDouble(),
                  (selectedElement['y'] as num).toDouble(),
                );
                // 保存完整的元素属性
                elementStartProperties[selectedId] = Map<String, dynamic>.from(selectedElement);
              }
            }

            // Start drag through DragStateManager
            dragStateManager.startDrag(
              elementIds: controller.state.selectedElementIds.toSet(),
              startPosition: details.localPosition,
              elementStartPositions: _elementStartPositions,
              elementStartProperties: elementStartProperties, // 🔧 传递完整属性
            );

            onDragStart(dragStateManager.isDragging, _dragStart, Offset(x, y),
                _elementStartPositions);
            return; // 找到了可拖拽的选中元素，直接返回
          }
        }
      }
    } // 如果没有点击在任何可拖拽的选中元素上，则准备平移画布
    // Don't start element dragging, prepare for canvas panning

    // 直接使用起始位置
    _elementStartPosition = Offset.zero;

    // 保存当前选中状态，确保平移不会改变选中状态
    _panStartSelectedElementIds =
        List.from(controller.state.selectedElementIds);

    // 标记正在开始在空白区域平移
    _isPanningEmptyArea = !hitAnyElement;

    // 添加日志跟踪
    debugPrint(
        '【平移】handlePanStart: 准备平移画布，起始位置=$_dragStart, 预览模式=${controller.state.isPreviewMode}, 是否拖拽元素=${dragStateManager.isDragging}');
    debugPrint(
        '【平移】handlePanStart: 记录平移开始时的选中元素: $_panStartSelectedElementIds');

    onDragStart(false, _dragStart, _elementStartPosition, {});

    // 在平移开始时不清除选择，而是记录下来，之后再决定是否需要清除
    // 如果是真正的点击而不是拖拽，在handlePanEnd中处理
  }

  /// Handle pan update on canvas
  void handlePanUpdate(DragUpdateDetails details) {
    // Update selection box if active
    if (_isSelectionBoxActive) {
      _selectionBoxEnd = details.localPosition;
      onDragUpdate();
      return;
    }

    // Note: We don't need to check controller.state.currentTool == 'select' here
    // because if we're dragging elements (_isDragging = true), that means
    // we've already set up dragging in handlePanStart, even in select mode

    // 获取当前位置
    final currentPosition = details.localPosition;

    // 获取当前缩放因子，用于调整拖拽的距离
    final scaleFactor = getScaleFactor();
    // 缩放因子的倒数，用于调整拖拽偏移量
    final inverseScale =
        scaleFactor > 0 ? 1.0 / scaleFactor : 1.0; // 在预览模式下，只处理画布平移
    if (controller.state.isPreviewMode) {
      // 计算拖拽偏移量并应用缩放因子的倒数
      final rawDx = currentPosition.dx - _dragStart.dx;
      final rawDy = currentPosition.dy - _dragStart.dy;

      // 应用缩放因子的倒数来修正坐标变换，确保平移匹配鼠标实际移动距离
      final dx = rawDx * inverseScale;
      final dy = rawDy * inverseScale;

      // 记录拖拽信息，让父组件处理平移
      _elementStartPosition = Offset(dx, dy);

      // 更新当前画布平移的终点位置，用于计算拖拽距离
      _panEndPosition = currentPosition;

      // 添加日志跟踪
      debugPrint(
          '【预览平移】handlePanUpdate: 平移画布，原始偏移=($rawDx, $rawDy), 调整后偏移=($dx, $dy), 缩放因子=$scaleFactor, 反向缩放=$inverseScale');

      onDragUpdate();
      return;
    } // 如果正在拖拽选中的元素
    if (dragStateManager.isDragging &&
        controller.state.selectedElementIds.isNotEmpty) {
      // 计算拖拽偏移量并应用缩放因子的倒数来修正坐标变换
      // 确保水平和垂直方向使用相同的缩放计算方式
      final dx = (currentPosition.dx - _dragStart.dx);
      final dy = (currentPosition.dy - _dragStart.dy);
      debugPrint(
          '【拖拽】拖拽选中元素: 当前工具=${controller.state.currentTool}, 原始偏移=(${currentPosition.dx - _dragStart.dx}, ${currentPosition.dy - _dragStart.dy}), '
          '缩放因子=$scaleFactor, 反向缩放=$inverseScale, 调整后偏移=($dx, $dy)');

      // Update drag offset through DragStateManager instead of direct element updates
      dragStateManager.updateDragOffset(Offset(dx, dy));

      onDragUpdate();
    } // 如果不是在拖拽元素，则平移画布
    else {
      // 计算拖拽偏移量并应用缩放因子的倒数
      // 对于画布平移，需要应用缩放因子以确保在不同缩放级别下平移距离与鼠标移动一致
      final rawDx = currentPosition.dx - _dragStart.dx;
      final rawDy = currentPosition.dy - _dragStart.dy;

      // 应用缩放因子的倒数来修正坐标变换，确保平移匹配鼠标实际移动距离
      final dx = rawDx * inverseScale;
      final dy = rawDy * inverseScale;

      // 检查偏移量是否有效
      if (dx.isNaN || dy.isNaN) {
        debugPrint('【平移】handlePanUpdate: 警告 - 偏移量包含NaN值！');
        return;
      } // 记录拖拽信息，让父组件处理平移
      _elementStartPosition = Offset(dx, dy);

      // 更新当前画布平移的终点位置，用于计算拖拽距离
      _panEndPosition = currentPosition;

      // 添加日志跟踪
      debugPrint(
          '【平移】handlePanUpdate: 平移画布，当前位置=$currentPosition, 起始位置=$_dragStart, '
          '原始偏移=($rawDx, $rawDy), 调整后偏移=($dx, $dy), 缩放因子=$scaleFactor, 反向缩放=$inverseScale');

      // 确保调用回调
      onDragUpdate();

      // 检查回调后的状态
      debugPrint('【平移】handlePanUpdate: 回调后，偏移量=$_elementStartPosition');
    }
  }

  /// Handle right-click (secondary button) tap down event
  /// 移除右键退出Select工具状态的功能
  void handleSecondaryTapDown(TapDownDetails details) {
    // 移除右键退出select模式的功能
    // 保留取消选择框的功能
    if (_isSelectionBoxActive) {
      cancelSelectionBox();
      onDragUpdate();
    }
  }

  /// Handle right click on canvas
  void handleSecondaryTapUp(
      TapUpDetails details, List<Map<String, dynamic>> elements) {
    // 移除右键退出select模式的功能
    // 保留取消选择框的功能
    if (_isSelectionBoxActive) {
      _isSelectionBoxActive = false;
      _selectionBoxStart = null;
      _selectionBoxEnd = null;
      onDragUpdate();
    }

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
      // 移除右键退出select模式的功能，保持当前选择状态
      // Don't start element dragging
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

          // 如果点击的是已选中的元素且不是多选模式，则取消选中
          if (isCurrentlySelected && !isMultiSelect) {
            debugPrint('【选择】handleTapUp: 点击已选中元素，取消选中: $id');
            controller.clearSelection();
            break;
          }

          // 选择元素
          controller.selectElement(id,
              isMultiSelect: isMultiSelect); // 如果不是多选模式，或者元素之前没有被选中，准备拖拽
          if (!isMultiSelect || !isCurrentlySelected) {
            // Start drag through DragStateManager
            _dragStart = details.localPosition;
            _elementStartPosition = Offset(x, y);
            _elementStartPositions.clear();

            // 记录所有选中元素的起始位置和完整属性
            final Map<String, Map<String, dynamic>> elementStartProperties = {};
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
                // 保存完整的元素属性
                elementStartProperties[selectedId] = Map<String, dynamic>.from(selectedElement);
              }
            }

            dragStateManager.startDrag(
              elementIds: controller.state.selectedElementIds.toSet(),
              startPosition: details.localPosition,
              elementStartPositions: _elementStartPositions,
              elementStartProperties: elementStartProperties, // 🔧 传递完整属性
            );

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

  /// Finalize selection box
  void _finalizeSelectionBox() {
    // Do nothing if no selection box
    if (_selectionBoxStart == null || _selectionBoxEnd == null) {
      _isSelectionBoxActive = false;
      onDragUpdate();
      return;
    }

    // Create a rect from the selection box points
    final selectionRect =
        Rect.fromPoints(_selectionBoxStart!, _selectionBoxEnd!);

    // If selection box is too small, treat as a click and cancel selection
    if (selectionRect.width < 5 && selectionRect.height < 5) {
      _isSelectionBoxActive = false;
      _selectionBoxStart = null;
      _selectionBoxEnd = null;
      onDragUpdate();
      return;
    }

    // Select all elements inside the selection box
    final isMultiSelect = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isShiftPressed;

    if (!isMultiSelect) {
      controller.clearSelection();
    }

    // Check each element to see if it's inside the selection box
    for (final element in controller.state.currentPageElements) {
      // Skip hidden elements
      final isHidden = element['hidden'] == true;
      if (isHidden) continue;

      // Skip hidden layers
      final layerId = element['layerId'] as String?;
      bool isLayerHidden = false;
      if (layerId != null) {
        final layer = controller.state.getLayerById(layerId);
        if (layer != null) {
          isLayerHidden = layer['isVisible'] == false;
        }
      }
      if (isLayerHidden) continue;

      // Get element bounds
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();
      final elementRect = Rect.fromLTWH(x, y, width, height);

      // Check if element intersects with selection box
      if (selectionRect.overlaps(elementRect)) {
        final id = element['id'] as String;
        controller.selectElement(id, isMultiSelect: true);
      }
    }

    // Reset selection box
    _isSelectionBoxActive = false;
    _selectionBoxStart = null;
    _selectionBoxEnd = null;
    onDragUpdate();
  }

  /// Show context menu for an element
  void _showElementContextMenu(Offset position, String elementId) {
    // This method would show a context menu at the given position
    // Implementation would depend on your context menu system
  }
}

/// Represents the state of the selection box
class SelectionBoxState {
  final bool isActive;
  final Offset? startPoint;
  final Offset? endPoint;

  SelectionBoxState({
    this.isActive = false,
    this.startPoint,
    this.endPoint,
  });
}
