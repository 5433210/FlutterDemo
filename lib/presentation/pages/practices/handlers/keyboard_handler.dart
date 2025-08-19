import 'package:flutter/services.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../infrastructure/logging/practice_edit_logger.dart';
import '../../../../utils/config/edit_page_logging_config.dart';
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
/// - Ctrl+Shift+H: Toggle toolbar visibility
/// - Ctrl+O: Page thumbnails toggle
/// - Ctrl+G: Grid toggle
/// - Ctrl+R: Snap toggle
/// - Ctrl+[: Toggle left panel
/// - Ctrl+]: Toggle right panel
/// - Ctrl+0: Reset view position (return to original zoom and position)
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
///
/// Page Navigation:
/// - Ctrl+Left Arrow: Previous page (when no elements selected)
/// - Ctrl+Right Arrow: Next page (when no elements selected)
class KeyboardHandler {
  final PracticeEditController controller;

  // Keyboard state
  bool _isCtrlPressed = false;
  bool _isShiftPressed = false;
  bool _isAltPressed = false;
  String _lastKeyPressed = ''; // Track combination key state

  // Performance tracking for keyboard operations
  final Map<String, DateTime> _lastActionTime = {};
  static const int _actionDedupeMs = 100; // Prevent duplicate action logs

  // Tool selection callback
  final Function(String)? onSelectTool;

  // Callback functions
  final Function() onTogglePreviewMode;

  final Function() onToggleThumbnails;
  final Function() onToggleToolbar;
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
  final Function() resetViewPosition; // Added callback for reset view position
  final Function()
      goToPreviousPage; // Added callback for previous page navigation
  final Function() goToNextPage; // Added callback for next page navigation
  KeyboardHandler({
    required this.controller,
    required this.onTogglePreviewMode,
    required this.onToggleThumbnails,
    required this.onToggleToolbar,
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
    required this.resetViewPosition, // Added parameter for reset view position
    required this.goToPreviousPage, // Added parameter for previous page navigation
    required this.goToNextPage, // Added parameter for next page navigation
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
          _logUserAction(
              '工具退出', 'Escape键退出工具模式: ${controller.state.currentTool}');
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
            _logUserAction('工具选择', '选择文本工具', {'shortcut': 'Alt+T'});
            _selectTool('text');
            return true;

          // Alt+I: Image tool
          case LogicalKeyboardKey.keyI:
            _logUserAction('工具选择', '选择图片工具', {'shortcut': 'Alt+I'});
            _selectTool('image');
            return true;

          // Alt+C: Collection tool
          case LogicalKeyboardKey.keyC:
            _logUserAction('工具选择', '选择集字工具', {'shortcut': 'Alt+C'});
            _selectTool('collection');
            return true;

          // Alt+S: Select tool
          case LogicalKeyboardKey.keyS:
            _logUserAction('工具选择', '选择选择工具', {'shortcut': 'Alt+S'});
            _selectTool('select');
            return true;

          // Alt+Q: Copy format
          case LogicalKeyboardKey.keyQ:
            _logUserAction('格式操作', '复制格式', {'shortcut': 'Alt+Q'});
            copyElementFormatting();
            return true;

          // Alt+W: Apply format
          case LogicalKeyboardKey.keyW:
            _logUserAction('格式操作', '应用格式', {'shortcut': 'Alt+W'});
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

          // Ctrl+0: Reset view position
          case LogicalKeyboardKey.digit0:
          case LogicalKeyboardKey.numpad0:
            _logUserAction('视图操作', '重置视图位置', {'shortcut': 'Ctrl+0'});
            resetViewPosition();
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
                _logUserAction('元素操作', '复制选中元素', {
                  'shortcut': 'Ctrl+Shift+C',
                  'elementCount': controller.state.selectedElementIds.length
                });
                copySelectedElement();
              }
              // 不记录无效操作的日志，减少噪音
              return true;
            }
            return false;

          // Ctrl+Shift+V: Paste copy
          case LogicalKeyboardKey.keyV:
            if (_isShiftPressed) {
              _logUserAction('元素操作', '粘贴元素', {'shortcut': 'Ctrl+Shift+V'});
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
            if (!_isShiftPressed) {
              toggleSelectedElementsVisibility();
            } else {
              // Ctrl+Shift+H: Toggle toolbar visibility
              onToggleToolbar();
            }
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

      // Handle arrow keys
      if (controller.state.selectedElementIds.isNotEmpty) {
        // Move selected items when elements are selected
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
      } else if (_isCtrlPressed) {
        // Handle page navigation when no elements are selected and Ctrl is pressed
        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowLeft:
            _logUserAction('页面导航', '切换到上一页', {'shortcut': 'Ctrl+Left'});
            goToPreviousPage();
            return true;

          case LogicalKeyboardKey.arrowRight:
            _logUserAction('页面导航', '切换到下一页', {'shortcut': 'Ctrl+Right'});
            goToNextPage();
            return true;
        }
      }
    }

    // If not handled, return false to pass event
    return false;
  }

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
      if (controller.state.currentTool != toolName) {
        controller.setCurrentTool(toolName);
      }
    }
  }

  /// 智能用户操作日志记录
  /// 避免高频重复日志，只记录有意义的用户操作
  void _logUserAction(String category, String action,
      [Map<String, dynamic>? data]) {
    final actionKey = '$category:$action';
    final now = DateTime.now();

    // 检查是否为重复操作（防抖动）
    final lastTime = _lastActionTime[actionKey];
    if (lastTime != null &&
        now.difference(lastTime).inMilliseconds < _actionDedupeMs) {
      return; // 跳过重复操作日志
    }

    _lastActionTime[actionKey] = now;

    // 使用性能监控包装重要的键盘操作
    final timer = PerformanceTimer(
      '键盘操作: $action',
      customThreshold: EditPageLoggingConfig.complexOperationThreshold,
    );

    // 使用专用的用户操作日志方法
    EditPageLogger.userAction('$category: $action', data: {
      'category': category,
      'action': action,
      'source': 'keyboard_shortcut',
      if (data != null) ...data,
    });

    timer.finish();
  }
}
