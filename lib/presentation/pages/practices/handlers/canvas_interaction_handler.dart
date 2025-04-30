import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../../widgets/practice/practice_edit_controller.dart';

/// Handles touch interactions with elements on the canvas
class CanvasInteractionHandler {
  final PracticeEditController controller;
  final bool isPreviewMode;
  final Function(bool) setIsDragging;
  final Function(Offset) setDragStart;
  final Function(Offset) setElementStartPosition;
  final Function(Map<String, Offset>) setElementStartPositions;

  CanvasInteractionHandler({
    required this.controller,
    required this.isPreviewMode,
    required this.setIsDragging,
    required this.setDragStart,
    required this.setElementStartPosition,
    required this.setElementStartPositions,
  });

  /// Handle pan end on canvas
  void handlePanEnd(
    DragEndDetails details,
    bool isDragging,
    Function(Matrix4) updateTransformMatrix,
    Matrix4 currentMatrix,
    VoidCallback applyInertia,
  ) {
    // In preview mode, only handle canvas panning end
    if (isPreviewMode) {
      // Apply inertia effect when panning ends
      final velocity = details.velocity;
      final speed = velocity.pixelsPerSecond.distance;

      if (speed > 100) {
        applyInertia();
      }

      debugPrint('Preview mode panning end: speed=$speed');
      return;
    }

    // Non-preview mode handling
    if (isDragging) {
      setIsDragging(false);

      // Apply snapping at end of drag
      for (final elementId in controller.state.selectedElementIds) {
        final element = controller.state.currentPageElements
            .firstWhere((e) => e['id'] == elementId);

        // Get current position
        final x = (element['x'] as num).toDouble();
        final y = (element['y'] as num).toDouble();

        // Apply snapping
        controller.updateElementProperties(elementId, {
          'x': x,
          'y': y,
        });

        debugPrint('Element $elementId end position: ($x, $y)');
      }
    } else {
      // Apply inertia effect when panning ends
      final velocity = details.velocity;
      final speed = velocity.pixelsPerSecond.distance;

      if (speed > 100) {
        applyInertia();
      }

      debugPrint('Panning end: speed=$speed');
    }
  }

  /// Handle pan start on canvas
  void handlePanStart(
    DragStartDetails details,
    List<Map<String, dynamic>> elements,
    Offset canvasTranslation,
  ) {
    // Check if clicked on an element
    bool hitElement = false;

    // In preview mode, no need to check element clicks
    if (!isPreviewMode) {
      for (int i = elements.length - 1; i >= 0; i--) {
        final element = elements[i];
        final x = (element['x'] as num).toDouble();
        final y = (element['y'] as num).toDouble();
        final width = (element['width'] as num).toDouble();
        final height = (element['height'] as num).toDouble();

        if (details.localPosition.dx >= x &&
            details.localPosition.dx <= x + width &&
            details.localPosition.dy >= y &&
            details.localPosition.dy <= y + height) {
          hitElement = true;
          break;
        }
      }
    }

    // In preview mode, or when clicking in blank area, record initial click position for manual panning
    if (isPreviewMode ||
        (controller.state.selectedElementIds.isEmpty || !hitElement)) {
      setDragStart(details.localPosition);
      // Record current transform matrix state
      setElementStartPosition(canvasTranslation);
      debugPrint('Start panning canvas: ${details.localPosition}');
      return;
    }

    // If there are selected elements and clicked on an element, start dragging (only in non-preview mode)
    if (controller.state.selectedElementIds.isNotEmpty && hitElement) {
      setIsDragging(true);
      setDragStart(details.localPosition);

      // Record start positions of all selected elements
      final Map<String, Offset> startPositions = {};
      for (final elementId in controller.state.selectedElementIds) {
        final element = controller.state.currentPageElements
            .firstWhere((e) => e['id'] == elementId);
        if (element['isLocked'] == true) continue;

        // Save initial position of each element
        startPositions[elementId] = Offset(
          (element['x'] as num).toDouble(),
          (element['y'] as num).toDouble(),
        );
      }
      setElementStartPositions(startPositions);
      debugPrint('Start dragging element: ${details.localPosition}');
    }
  }

  /// Handle pan update on canvas
  void handlePanUpdate(
    DragUpdateDetails details,
    Offset dragStart,
    Offset elementStartPosition,
    Map<String, Offset> elementStartPositions,
    bool isDragging,
    Function(Matrix4) updateTransformMatrix,
  ) {
    // In preview mode, only handle canvas panning
    if (isPreviewMode) {
      // Pan the canvas
      final dx = details.localPosition.dx - dragStart.dx;
      final dy = details.localPosition.dy - dragStart.dy;

      // Create new transformation matrix
      final Matrix4 newMatrix = Matrix4.identity();
      // Set same scale factor as current
      final scale = controller.canvasScale;
      newMatrix.setEntry(0, 0, scale);
      newMatrix.setEntry(1, 1, scale);
      newMatrix.setEntry(2, 2, scale);

      // Set new translation values
      newMatrix.setTranslation(Vector3(
        elementStartPosition.dx + dx,
        elementStartPosition.dy + dy,
        0.0,
      ));

      // Apply new transformation
      updateTransformMatrix(newMatrix);

      debugPrint('Preview mode panning canvas: dx=$dx, dy=$dy');
      return;
    }

    // Non-preview mode handling
    if (isDragging && controller.state.selectedElementIds.isNotEmpty) {
      // Drag elements
      final dx = details.localPosition.dx - dragStart.dx;
      final dy = details.localPosition.dy - dragStart.dy;

      // Update positions of all selected elements
      for (final elementId in controller.state.selectedElementIds) {
        // Get element
        final element = controller.state.currentPageElements
            .firstWhere((e) => e['id'] == elementId);

        // Check element lock state - skip moving if locked
        if (element['locked'] == true) {
          debugPrint('Element $elementId is locked, cannot move');
          continue;
        }

        // Check layer lock state
        final layerId = element['layerId'] as String?;
        if (layerId != null) {
          final layer = controller.state.getLayerById(layerId);
          if (layer != null) {
            if (layer['isLocked'] == true) {
              debugPrint('Element $elementId in locked layer, cannot move');
              continue;
            }
            if (layer['isVisible'] == false) continue;
          }
        }

        // Get element's initial position
        final startPosition = elementStartPositions[elementId];
        if (startPosition == null) continue;

        // Calculate new position
        double newX = startPosition.dx + dx;
        double newY = startPosition.dy + dy;

        // Snap to grid (if enabled)
        if (controller.state.snapEnabled) {
          newX = (newX / controller.state.gridSize).round() *
              controller.state.gridSize;
          newY = (newY / controller.state.gridSize).round() *
              controller.state.gridSize;
        }

        // Update element position - don't apply snapping during dragging
        controller.updateElementPropertiesDuringDrag(elementId, {
          'x': newX,
          'y': newY,
        });
      }
      debugPrint('Drag update: dx=$dx, dy=$dy');
    } else if (!isDragging) {
      // Pan the canvas
      final dx = details.localPosition.dx - dragStart.dx;
      final dy = details.localPosition.dy - dragStart.dy;

      // Create new transformation matrix
      final Matrix4 newMatrix = Matrix4.identity();
      // Set same scale factor as current
      final scale = controller.canvasScale;
      newMatrix.setEntry(0, 0, scale);
      newMatrix.setEntry(1, 1, scale);
      newMatrix.setEntry(2, 2, scale);

      // Set new translation values
      newMatrix.setTranslation(Vector3(
        elementStartPosition.dx + dx,
        elementStartPosition.dy + dy,
        0.0,
      ));

      // Apply new transformation
      updateTransformMatrix(newMatrix);

      debugPrint('Panning canvas: dx=$dx, dy=$dy');
    }
  }

  /// Handle right click on canvas
  void handleSecondaryTapUp(
      TapUpDetails details, List<Map<String, dynamic>> elements) {
    // Check if clicked on a selected element
    bool hitSelectedElement = false;

    // Check from back to front (elements added later are on top)
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

      // If clicked inside the element and the element is already selected
      if (isInside && controller.state.selectedElementIds.contains(id)) {
        hitSelectedElement = true;
        debugPrint('\n=== Right click on selected element $id ===');
        debugPrint('Deselect element');

        // Cancel selection
        controller.clearSelection();
        setIsDragging(false);

        break;
      }
    }

    // If not clicked on a selected element, do nothing
    if (!hitSelectedElement) {
      debugPrint('\n=== Right click on non-selected element or blank area ===');
    }
  }

  /// Handle tap on the canvas
  void handleTapUp(TapUpDetails details, List<Map<String, dynamic>> elements) {
    // If clicking in a blank area, cancel selection
    bool hitElement = false;

    // Check from back to front (elements added later are on top)
    for (int i = elements.length - 1; i >= 0; i--) {
      final element = elements[i];
      final id = element['id'] as String;
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();
      final isLocked = element['locked'] == true;
      final isHidden = element['hidden'] == true;

      // If the element is hidden and in preview mode, skip this element
      if (isHidden && isPreviewMode) continue;

      // Calculate border width for border click detection
      final isSelected = controller.state.selectedElementIds.contains(id);
      final borderWidth = !isPreviewMode && isSelected ? 2.0 : 1.0;

      // Check if clicked inside the element
      final bool isInside = details.localPosition.dx >= x &&
          details.localPosition.dx <= x + width &&
          details.localPosition.dy >= y &&
          details.localPosition.dy <= y + height;

      // Check if clicked on the border
      // Only expand click area in small range near the border
      final bool isOnBorder = !isInside &&
          (
              // Left border
              (details.localPosition.dx >= x - borderWidth &&
                      details.localPosition.dx <= x &&
                      details.localPosition.dy >= y &&
                      details.localPosition.dy <= y + height) ||
                  // Right border
                  (details.localPosition.dx >= x + width &&
                      details.localPosition.dx <= x + width + borderWidth &&
                      details.localPosition.dy >= y &&
                      details.localPosition.dy <= y + height) ||
                  // Top border
                  (details.localPosition.dy >= y - borderWidth &&
                      details.localPosition.dy <= y &&
                      details.localPosition.dx >= x &&
                      details.localPosition.dx <= x + width) ||
                  // Bottom border
                  (details.localPosition.dy >= y + height &&
                      details.localPosition.dy <= y + height + borderWidth &&
                      details.localPosition.dx >= x &&
                      details.localPosition.dx <= x + width));

      // Print debug info
      if (isOnBorder) {
        debugPrint(
            'Click on border of element $id at ${details.localPosition}');
      }

      // If clicked inside the element or on the border
      if (isInside || isOnBorder) {
        hitElement = true;

        // If the element is locked, only allow selection, not editing
        if (isLocked) {
          // Locked elements can only be selected, not edited
          // Clear layer selection to ensure property panel can switch to element properties
          controller.state.selectedLayerId = null;

          controller.selectElement(id,
              isMultiSelect: controller.state.isCtrlOrShiftPressed);

          break;
        } else {
          // Implement state transitions according to the state diagram
          final isCurrentlySelected =
              controller.state.selectedElementIds.contains(id);
          final isMultipleSelected =
              controller.state.selectedElementIds.length > 1;

          // Print current state info
          debugPrint('\n=== Click on element $id previous state ===');
          debugPrint(
              'Currently selected elements: ${controller.state.selectedElementIds.length}');
          debugPrint(
              'Currently selected element IDs: ${controller.state.selectedElementIds}');
          debugPrint('Current element is selected: $isCurrentlySelected');
          debugPrint('Currently in multi-selection state: $isMultipleSelected');
          debugPrint(
              'Ctrl or Shift key pressed: ${controller.state.isCtrlOrShiftPressed}');

          if (controller.state.isCtrlOrShiftPressed) {
            // Ctrl+click: Multi-selection state
            debugPrint('→ Enter multi-selection state (Ctrl or Shift pressed)');
            // Clear layer selection to ensure property panel can switch to element properties
            controller.state.selectedLayerId = null;

            controller.selectElement(id, isMultiSelect: true);
          } else if (isCurrentlySelected && isMultipleSelected) {
            // Already selected and currently in multi-selection: Cancel other selections, enter edit state
            debugPrint(
                '→ From multi-selection to edit state (cancel other selections)');
            controller.state.selectedElementIds = [id];
            controller.state.selectedElement = element;

            // Critical change: Enable dragging regardless
            setIsDragging(true);
            setDragStart(details.localPosition);
            setElementStartPosition(Offset(x, y));
            debugPrint('→ Set dragging state, prepare to move element');
          } else if (!isCurrentlySelected) {
            // Not selected: Select and enter edit state
            debugPrint('→ From normal state to edit state (select element)');
            // Clear layer selection to ensure property panel can switch to element properties
            controller.state.selectedLayerId = null;

            controller.selectElement(id, isMultiSelect: false);

            // Critical change: Also enable dragging
            setIsDragging(true);
            setDragStart(details.localPosition);
            setElementStartPosition(Offset(x, y));
            debugPrint('→ Set dragging state, prepare to move element');
          } else {
            // If already in edit state, maintain state and enable dragging
            debugPrint('→ Maintain edit state (already selected)');

            // Critical change: Even if element is already selected, set dragging state to allow element movement
            setIsDragging(true);
            setDragStart(details.localPosition);
            setElementStartPosition(Offset(x, y));

            debugPrint('→ Set dragging state, prepare to move element');
            debugPrint('  Drag start point: ${details.localPosition}');
            debugPrint('  Element start position: $x, $y');
          }

          // Print state info after change
          Future.microtask(() {
            debugPrint('=== Click on element $id after state ===');
            debugPrint(
                'Currently selected elements: ${controller.state.selectedElementIds.length}');
            debugPrint(
                'Currently selected element IDs: ${controller.state.selectedElementIds}');
            debugPrint('Element start: ${element['x']}, ${element['y']}');
            debugPrint(
                'Element size: ${element['width']}x${element['height']}');
            debugPrint('\n');
          });
        }

        break;
      }
    }

    if (!hitElement) {
      // Print state info when clicking in blank area
      debugPrint('\n=== Click in blank area ===');
      debugPrint(
          'Currently selected elements: ${controller.state.selectedElementIds.length}');
      debugPrint(
          'Currently selected element IDs: ${controller.state.selectedElementIds}');
      debugPrint(
          'Ctrl or Shift key pressed: ${controller.state.isCtrlOrShiftPressed}');

      if (!controller.state.isCtrlOrShiftPressed) {
        // Click in blank area and no Ctrl or Shift pressed, cancel selection
        debugPrint('→ Cancel all selections, enter normal state');
        controller.clearSelection();
        setIsDragging(false);
        debugPrint('→ Reset dragging state');

        // Print state info after change
        Future.microtask(() {
          debugPrint('=== After clicking blank area ===');
          debugPrint(
              'Currently selected elements: ${controller.state.selectedElementIds.length}');
          debugPrint(
              'Currently selected element IDs: ${controller.state.selectedElementIds}');
          debugPrint('\n');
        });
      } else {
        debugPrint(
            '→ Maintain current selection state (Ctrl or Shift pressed)');
      }
    }
  }
}
