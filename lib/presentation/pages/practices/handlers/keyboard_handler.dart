import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../widgets/practice/practice_edit_controller.dart';

/// Handles keyboard events for the practice edit page
///
/// Keyboard shortcuts:
/// 
/// File Operations:
/// - Ctrl+S: Save
/// - Ctrl+Shift+S: Save As
/// - Ctrl+E: Export
/// - Ctrl+M, T: Edit title
///
/// View Controls:
/// - Ctrl+P: Preview mode toggle
/// - Ctrl+O: Page thumbnails toggle
/// - Ctrl+G: Grid toggle
/// - Ctrl+R: Snap toggle
/// - Ctrl+[: Toggle left panel
/// - Ctrl+]: Toggle right panel
///
/// Element Tools:
/// - Alt+T: Text tool
/// - Alt+I: Image tool
/// - Alt+C: Collection tool
/// - Alt+S: Select tool
/// - Escape: Exit current tool
///
/// Selection Operations:
/// - Ctrl+Shift+A: Select all elements on current page
/// - Ctrl+Shift+C: Copy selection
/// - Ctrl+Shift+V: Paste copy
/// - Ctrl+D: Delete selection
/// - Ctrl+H: Hide selected objects
/// - Ctrl+L: Lock selected objects
///
/// Element Arrangement:
/// - Ctrl+J: Group
/// - Ctrl+U: Ungroup
/// - Ctrl+T: Bring to front
/// - Ctrl+Shift+T: Move up
/// - Ctrl+B: Send to back
/// - Ctrl+Shift+B: Move down
///
/// Formatting:
/// - Ctrl+Shift+F: Copy element formatting (format brush)
/// - Ctrl+F: Apply format brush
/// - Alt+Q: Copy format
/// - Alt+W: Apply format
///
/// History Operations:
/// - Ctrl+Z: Undo
/// - Ctrl+Y: Redo
///
/// Element Creation:
/// - Ctrl+N, T: Add text element
/// - Ctrl+N, P: Add image element
/// - Ctrl+N, C: Add collection element
///
/// Movement:
/// - Arrow keys: Move selected items
/// - Ctrl+Arrow keys: Move selected items by larger distance
class KeyboardHandler {
  final PracticeEditController controller;

  // Keyboard state
  bool _isCtrlPressed = false;
  bool _isShiftPressed = false;
  bool _isAltPressed = false;
  String _lastKeyPressed = ''; // Track combination key state
  
  // Tool selection callback
  final Function(String)? onSelectTool;
  
  // Function to select a tool (to be called by shortcuts)
  void _selectTool(String toolName) {
    if (onSelectTool != null) {
      // Use the callback if provided
      onSelectTool!(toolName);
    } else if (controller.state.currentTool == toolName) {
      // If the tool is already selected, deselect it
      controller.exitSelectMode();
    } else {
      // Otherwise select the tool
      controller.state.currentTool = toolName;
      controller.notifyListeners();
    }
  }

  // Callback functions
  final Function() onTogglePreviewMode;
  final Function() onToggleThumbnails;
  final Function() editTitle;
  final Function() savePractice;
  final Function() saveAsNewPractice;
  final Function() selectAllElements;
  final Function() copySelectedElement;
  final Function() pasteElement;
  final Function() deleteSelectedElements;
  final Function() groupSelectedElements;
  final Function() ungroupElements;
  final Function() bringToFront;
  final Function() sendToBack;
  final Function() moveElementUp;
  final Function() moveElementDown;
  final Function() toggleGrid;
  final Function() toggleSnap;
  final Function() toggleSelectedElementsVisibility;
  final Function() toggleSelectedElementsLock;
  final Function() showExportDialog;
  final Function() toggleLeftPanel;
  final Function() toggleRightPanel;
  final Function() copyElementFormatting;
  final Function() applyFormatBrush;
  final Function(double dx, double dy) moveSelectedElements;

  KeyboardHandler({
    required this.controller,
    required this.onTogglePreviewMode,
    required this.onToggleThumbnails,
    required this.editTitle,
    required this.savePractice,
    required this.saveAsNewPractice,
    required this.selectAllElements,
    required this.copySelectedElement,
    required this.pasteElement,
    required this.deleteSelectedElements,
    required this.groupSelectedElements,
    required this.ungroupElements,
    required this.bringToFront,
    required this.sendToBack,
    required this.moveElementUp,
    required this.moveElementDown,
    required this.toggleGrid,
    required this.toggleSnap,
    required this.toggleSelectedElementsVisibility,
    required this.toggleSelectedElementsLock,
    required this.showExportDialog,
    required this.toggleLeftPanel,
    required this.toggleRightPanel,
    required this.moveSelectedElements,
    required this.copyElementFormatting,
    required this.applyFormatBrush,
    this.onSelectTool,
  });

  /// Handle keyboard events
  bool handleKeyEvent(KeyEvent event) {
    // Process keyboard event
    if (event is KeyDownEvent) {
      // Handle key state
      if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight) {
        _isCtrlPressed = true;
      } else if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight) {
        _isShiftPressed = true;
      } else if (event.logicalKey == LogicalKeyboardKey.altLeft ||
          event.logicalKey == LogicalKeyboardKey.altRight) {
        _isAltPressed = true;
      }

      // Handle key combinations
      if (_isCtrlPressed) {
        // Record last pressed key
        if (event.logicalKey == LogicalKeyboardKey.keyM) {
          _lastKeyPressed = 'M';
        } else if (event.logicalKey == LogicalKeyboardKey.keyN) {
          _lastKeyPressed = 'N';
        } else if (_lastKeyPressed == 'M' &&
            event.logicalKey == LogicalKeyboardKey.keyT) {
          // Ctrl+M, T combination: Edit title
          editTitle();
          _lastKeyPressed = '';
          return true;
        } else if (_lastKeyPressed == 'N' &&
            event.logicalKey == LogicalKeyboardKey.keyT) {
          // Ctrl+N, T combination: Add text element
          controller.addTextElement();
          _lastKeyPressed = '';
          return true;
        } else if (_lastKeyPressed == 'N' &&
            event.logicalKey == LogicalKeyboardKey.keyP) {
          // Ctrl+N, P combination: Add image element
          controller.addEmptyImageElementAt(100.0, 100.0);
          _lastKeyPressed = '';
          return true;
        } else if (_lastKeyPressed == 'N' &&
            event.logicalKey == LogicalKeyboardKey.keyC) {
          // Ctrl+N, C combination: Add collection element
          controller.addEmptyCollectionElementAt(100.0, 100.0);
          _lastKeyPressed = '';
          return true;
        }
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight) {
        _isCtrlPressed = false;
        _lastKeyPressed = ''; // Reset combination key state
      } else if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight) {
        _isShiftPressed = false;
      } else if (event.logicalKey == LogicalKeyboardKey.altLeft ||
          event.logicalKey == LogicalKeyboardKey.altRight) {
        _isAltPressed = false;
      }
    }

    // If key down event, handle shortcuts
    if (event is KeyDownEvent) {
      // Handle Escape key to exit current tool
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (controller.state.currentTool.isNotEmpty) {
          debugPrint('KeyboardHandler: Exiting tool mode via Escape key');
          controller.exitSelectMode();
          return true;
        }
      }
      
      // If in preview mode, only handle preview mode toggle shortcut
      if (controller.state.isPreviewMode) {
        if (_isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyP) {
          onTogglePreviewMode();
          return true;
        }
        return false;
      }
      
      // Handle Alt combinations for tool selection and formatting
      if (_isAltPressed) {
        switch (event.logicalKey) {
          // Alt+T: Text tool
          case LogicalKeyboardKey.keyT:
            debugPrint('KeyboardHandler: Selecting text tool via Alt+T');
            _selectTool('text');
            return true;
            
          // Alt+I: Image tool
          case LogicalKeyboardKey.keyI:
            debugPrint('KeyboardHandler: Selecting image tool via Alt+I');
            _selectTool('image');
            return true;
            
          // Alt+C: Collection tool
          case LogicalKeyboardKey.keyC:
            debugPrint('KeyboardHandler: Selecting collection tool via Alt+C');
            _selectTool('collection');
            return true;
            
          // Alt+S: Select tool
          case LogicalKeyboardKey.keyS:
            debugPrint('KeyboardHandler: Selecting select tool via Alt+S');
            _selectTool('select');
            return true;
            
          // Alt+Q: Copy format
          case LogicalKeyboardKey.keyQ:
            debugPrint('KeyboardHandler: Copy format via Alt+Q');
            copyElementFormatting();
            return true;
            
          // Alt+W: Apply format
          case LogicalKeyboardKey.keyW:
            debugPrint('KeyboardHandler: Apply format via Alt+W');
            applyFormatBrush();
            return true;
        }
      }

      // Handle Ctrl combinations
      if (_isCtrlPressed) {
        switch (event.logicalKey) {
          // Ctrl+S: Save or Ctrl+Shift+S: Save As
          case LogicalKeyboardKey.keyS:
            if (_isShiftPressed) {
              // Ctrl+Shift+S: Save As
              saveAsNewPractice();
            } else {
              // Ctrl+S: Save
              savePractice();
            }
            return true;

          // Ctrl+Shift+A: Select all elements on current page
          case LogicalKeyboardKey.keyA:
            if (_isShiftPressed) {
              selectAllElements();
              return true;
            }
            return false;

          // Ctrl+Shift+C: Copy selection
          case LogicalKeyboardKey.keyC:
            if (_isShiftPressed) {
              // 确保只有在有选中元素时才执行复制操作
              if (controller.state.selectedElementIds.isNotEmpty) {
                debugPrint('KeyboardHandler: 执行复制操作 (Ctrl+Shift+C)');
                copySelectedElement();
              } else {
                debugPrint('KeyboardHandler: 忽略复制操作，因为没有选中元素');
              }
              return true;
            }
            return false;

          // Ctrl+Shift+V: Paste copy
          case LogicalKeyboardKey.keyV:
            if (_isShiftPressed) {
              debugPrint('KeyboardHandler: 执行粘贴操作 (Ctrl+Shift+V)');
              pasteElement();
              return true;
            }
            return false;

          // Ctrl+F: Apply format brush (or Ctrl+Shift+F: Copy element formatting)
          case LogicalKeyboardKey.keyF:
            if (_isShiftPressed) {
              // Ctrl+Shift+F: Copy element formatting (format brush)
              copyElementFormatting();
            } else {
              // Ctrl+F: Apply format brush
              applyFormatBrush();
            }
            return true;

          // Ctrl+D: Delete selection
          case LogicalKeyboardKey.keyD:
            deleteSelectedElements();
            return true;

          // Ctrl+Z: Undo
          case LogicalKeyboardKey.keyZ:
            controller.undo();
            return true;

          // Ctrl+Y: Redo
          case LogicalKeyboardKey.keyY:
            controller.redo();
            return true;

          // Ctrl+J: Group
          case LogicalKeyboardKey.keyJ:
            groupSelectedElements();
            return true;

          // Ctrl+U: Ungroup
          case LogicalKeyboardKey.keyU:
            ungroupElements();
            return true;

          // Ctrl+G: Grid toggle
          case LogicalKeyboardKey.keyG:
            toggleGrid();
            return true;

          // Ctrl+R: Snap toggle
          case LogicalKeyboardKey.keyR:
            toggleSnap();
            return true;

          // Ctrl+T: Bring to front
          case LogicalKeyboardKey.keyT:
            if (!_isShiftPressed) {
              bringToFront();
            } else {
              // Ctrl+Shift+T: Move up
              moveElementUp();
            }
            return true;

          // Ctrl+B: Send to back
          case LogicalKeyboardKey.keyB:
            if (!_isShiftPressed) {
              sendToBack();
            } else {
              // Ctrl+Shift+B: Move down
              moveElementDown();
            }
            return true;

          // Ctrl+E: Export
          case LogicalKeyboardKey.keyE:
            // Implement export functionality
            showExportDialog();
            return true;

          // Ctrl+M+T: Edit title
          case LogicalKeyboardKey.keyM:
            if (event.logicalKey == LogicalKeyboardKey.keyT) {
              editTitle();
              return true;
            }
            return false;

          // Ctrl+N+T: Add text element
          case LogicalKeyboardKey.keyN:
            return false; // Return false to continue passing event

          // Ctrl+H: Hide selected objects
          case LogicalKeyboardKey.keyH:
            toggleSelectedElementsVisibility();
            return true;

          // Ctrl+L: Lock selected objects
          case LogicalKeyboardKey.keyL:
            toggleSelectedElementsLock();
            return true;

          // Ctrl+P: Preview mode toggle
          case LogicalKeyboardKey.keyP:
            onTogglePreviewMode();
            return true;

          // Ctrl+O: Page thumbnails toggle
          case LogicalKeyboardKey.keyO:
            onToggleThumbnails();
            return true;

          // Ctrl+[: Toggle left panel
          case LogicalKeyboardKey.bracketLeft:
            toggleLeftPanel();
            return true;

          // Ctrl+]: Toggle right panel
          case LogicalKeyboardKey.bracketRight:
            toggleRightPanel();
            return true;
        }
      }

      // Handle arrow keys: Move selected items
      if (controller.state.selectedElementIds.isNotEmpty) {
        final moveDistance = _isCtrlPressed
            ? 10.0
            : 1.0; // Move larger distance when Ctrl is pressed

        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowUp:
            moveSelectedElements(0, -moveDistance);
            return true;

          case LogicalKeyboardKey.arrowDown:
            moveSelectedElements(0, moveDistance);
            return true;

          case LogicalKeyboardKey.arrowLeft:
            moveSelectedElements(-moveDistance, 0);
            return true;

          case LogicalKeyboardKey.arrowRight:
            moveSelectedElements(moveDistance, 0);
            return true;
        }
      }
    }

    // If not handled, return false to pass event
    return false;
  }
}
