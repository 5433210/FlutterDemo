import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'edit_toolbar.dart';
import 'element_context_menu.dart';
import 'element_renderers.dart';
import 'grid_painter.dart';
import 'page_operations.dart';
import 'practice_edit_controller.dart';
import 'practice_element_widget.dart';
import 'selection_manager.dart';

/// 中央编辑区域
class CentralEditArea extends StatefulWidget {
  final PracticeEditController controller;
  final String currentTool;
  final bool isPreviewMode;
  final double gridSize;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onAddTextElement;
  final Function(String) onAddCollectionElement;
  final Function(String) onAddImageElement;
  final Function(Map<String, dynamic>, Offset) onElementTap;
  final Function(String, Offset) onElementDragUpdate;
  final Function(String, Offset, Size) onElementResizeUpdate;
  final Function(String, double) onElementRotateUpdate;

  const CentralEditArea({
    Key? key,
    required this.controller,
    required this.currentTool,
    required this.isPreviewMode,
    required this.gridSize,
    required this.onCopy,
    required this.onPaste,
    required this.onAddTextElement,
    required this.onAddCollectionElement,
    required this.onAddImageElement,
    required this.onElementTap,
    required this.onElementDragUpdate,
    required this.onElementResizeUpdate,
    required this.onElementRotateUpdate,
  }) : super(key: key);

  @override
  State<CentralEditArea> createState() => _CentralEditAreaState();
}

class _CentralEditAreaState extends State<CentralEditArea> {
  // 选择管理器
  final SelectionManager _selectionManager = SelectionManager();

  // 是否按下Ctrl键
  bool _isCtrlPressed = false;

  // 是否按下Shift键
  bool _isShiftPressed = false;

  // 拖拽状态
  bool _isDragging = false;
  final Map<String, Offset> _elementStartPositions = {};

  // 变换控制器
  final TransformationController _transformationController =
      TransformationController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 编辑工具栏
        EditToolbar(
          controller: widget.controller,
          gridVisible: widget.controller.state.gridVisible,
          snapEnabled: widget.controller.state.snapEnabled,
          onCopy: widget.onCopy,
          onPaste: widget.onPaste,
          onDelete: widget.controller.deleteSelectedElements,
          onToggleGrid: widget.controller.toggleGrid,
          onToggleSnap: widget.controller.toggleSnap,
          onMoveUp: _moveSelectedElementsUp,
          onMoveDown: _moveSelectedElementsDown,
          onBringToFront: _bringSelectedElementsToFront,
          onSendToBack: _sendSelectedElementsToBack,
          onGroupElements: _groupSelectedElements,
          onUngroupElements: widget.controller.ungroupSelectedElement,
        ),

        // 编辑画布
        Expanded(
          child: Stack(
            children: [
              // 编辑画布
              _buildEditCanvas(),

              // 添加元素按钮
              if (!widget.isPreviewMode)
                Positioned(
                  right: 16,
                  top: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'add_text',
                        mini: true,
                        onPressed: widget.onAddTextElement,
                        child: const Icon(Icons.text_fields),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'add_image',
                        mini: true,
                        child: const Icon(Icons.image),
                        onPressed: () => _showImageUrlDialog(context),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'add_collection',
                        mini: true,
                        child: const Icon(Icons.grid_view),
                        onPressed: () => _showCollectionDialog(context),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // 移除键盘监听
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // 添加键盘监听
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  /// 将选中元素置于顶层
  void _bringSelectedElementsToFront() {
    if (widget.controller.state.selectedElementIds.isEmpty) return;

    final elements = widget.controller.state.currentPageElements;
    final selectedIds = widget.controller.state.selectedElementIds;

    // 找出所有选中的元素
    final selectedElements =
        elements.where((e) => selectedIds.contains(e['id'])).toList();

    // 从原列表中移除选中的元素
    elements.removeWhere((e) => selectedIds.contains(e['id']));

    // 将选中的元素添加到列表末尾（顶层）
    elements.addAll(selectedElements);

    // 更新页面元素
    final currentPageIndex = widget.controller.state.currentPageIndex;
    widget.controller.state.pages[currentPageIndex]['elements'] = elements;
    widget.controller
        .notifyListeners(); // Update the UI after changing elements order
  }

  /// 构建编辑画布
  Widget _buildEditCanvas() {
    final currentPage = widget.controller.state.currentPage;
    if (currentPage == null) {
      return const Center(
        child: Text('没有页面，请添加一个新页面'),
      );
    }

    final elements = widget.controller.state.currentPageElements;

    return GestureDetector(
      onTapDown: (details) => _handleTapDown(details, elements),
      onPanStart: (details) => _handlePanStart(details, elements),
      onPanUpdate: (details) => _handlePanUpdate(details),
      onPanEnd: (details) => _handlePanEnd(details),
      child: Container(
        color: Colors.grey.shade200,
        child: Center(
          child: InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.1,
            maxScale: 5.0,
            child: Stack(
              children: [
                // 页面背景
                Container(
                  width: 595, // A4 宽度 (72dpi)
                  height: 842, // A4 高度 (72dpi)
                  color: PageOperations.getPageBackgroundColor(currentPage),
                  child: Stack(
                    children: [
                      // 网格
                      if (widget.controller.state.gridVisible &&
                          !widget.isPreviewMode)
                        CustomPaint(
                          size: const Size(595, 842),
                          painter: GridPainter(gridSize: widget.gridSize),
                        ),

                      // 元素
                      for (final element in elements) _buildElement(element),

                      // 选择框
                      if (_selectionManager.isSelecting &&
                          !widget.isPreviewMode)
                        CustomPaint(
                          size: const Size(595, 842),
                          painter: _SelectionPainter(_selectionManager),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建元素
  Widget _buildElement(Map<String, dynamic> element) {
    final id = element['id'] as String;
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num).toDouble();
    final isLocked = element['isLocked'] == true;
    final isSelected = widget.controller.state.selectedElementIds.contains(id);
    final isEditing =
        isSelected && widget.controller.state.selectedElementIds.length == 1;

    // 元素状态
    final state = widget.isPreviewMode
        ? ElementState.normal
        : isEditing
            ? ElementState.editing
            : isSelected
                ? ElementState.selected
                : ElementState.normal;

    // 根据元素类型构建不同的渲染器
    Widget content;
    switch (element['type']) {
      case 'text':
        content = ElementRenderers.buildTextElement(element);
        break;
      case 'image':
        content = ElementRenderers.buildImageElement(element);
        break;
      case 'collection':
        content = ElementRenderers.buildCollectionElement(element);
        break;
      case 'group':
        content = ElementRenderers.buildGroupElement(element);
        break;
      default:
        content = Container(
          color: Colors.grey.withAlpha(51), // 0.2 * 255 = 51
          child: const Center(child: Text('未知元素')),
        );
    }

    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: rotation * (3.1415926535 / 180), // 转换为弧度
        child: GestureDetector(
          onTap: () => widget.onElementTap(element, Offset(x, y)),
          onPanUpdate: (details) {
            if (!widget.isPreviewMode && isSelected && !isLocked) {
              // 使用带吸附的方法更新元素位置
              widget.controller
                  .updateElementPositionWithSnap(id, details.delta);
            }
          },
          onSecondaryTapDown: (details) {
            if (widget.isPreviewMode) return;

            // 显示上下文菜单
            _showElementContextMenu(context, element, details.globalPosition);
          },
          child: Stack(
            children: [
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  border: !widget.isPreviewMode
                      ? Border.all(
                          color: isLocked
                              ? Colors.orange
                              : state == ElementState.normal
                                  ? Colors.grey
                                  : Colors.blue,
                          width: state == ElementState.normal ? 1.0 : 2.0,
                        )
                      : null,
                ),
                child: content,
              ),

              // 锁定图标
              if (isLocked && !widget.isPreviewMode)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51), // 0.2 * 255 = 51
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.orange,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 组合选中元素
  void _groupSelectedElements() {
    if (widget.controller.state.selectedElementIds.length <= 1) return;

    widget.controller.groupSelectedElements();
  }

  /// 处理键盘事件
  bool _handleKeyEvent(KeyEvent event) {
    setState(() {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
            event.logicalKey == LogicalKeyboardKey.controlRight) {
          _isCtrlPressed = true;
        } else if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
            event.logicalKey == LogicalKeyboardKey.shiftRight) {
          _isShiftPressed = true;
        } else if (event.logicalKey == LogicalKeyboardKey.delete) {
          // 删除选中元素
          widget.controller.deleteSelectedElements();
        }
      } else if (event is KeyUpEvent) {
        if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
            event.logicalKey == LogicalKeyboardKey.controlRight) {
          _isCtrlPressed = false;
        } else if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
            event.logicalKey == LogicalKeyboardKey.shiftRight) {
          _isShiftPressed = false;
        }
      }
    });

    // 返回false表示不拦截事件，允许其他处理程序处理
    return false;
  }

  /// 处理拖拽结束
  void _handlePanEnd(DragEndDetails details) {
    if (widget.isPreviewMode) return;

    if (_selectionManager.isSelecting) {
      // 结束框选
      final selectionRect = _selectionManager.endSelection();
      if (selectionRect != null) {
        _selectElementsInRect(selectionRect);
      }
    } else if (_isDragging) {
      // 结束拖拽
      _isDragging = false;
      _elementStartPositions.clear();
    }
  }

  /// 处理拖拽开始
  void _handlePanStart(
      DragStartDetails details, List<Map<String, dynamic>> elements) {
    if (widget.isPreviewMode) return;

    if (widget.currentTool == 'select') {
      final hitElement = _hitTestElement(details.localPosition, elements);

      if (hitElement == null) {
        // 开始框选
        _selectionManager.startSelection(details.localPosition);
      } else {
        // 开始拖拽元素
        _isDragging = true;

        // 记录所有选中元素的起始位置
        _elementStartPositions.clear();
        for (final id in widget.controller.state.selectedElementIds) {
          final element = elements.firstWhere((e) => e['id'] == id);
          _elementStartPositions[id] = Offset(
            (element['x'] as num).toDouble(),
            (element['y'] as num).toDouble(),
          );
        }
      }
    }
  }

  /// 处理拖拽更新
  void _handlePanUpdate(DragUpdateDetails details) {
    if (widget.isPreviewMode) return;

    if (_selectionManager.isSelecting) {
      // 更新框选
      setState(() {
        _selectionManager.updateSelection(details.localPosition);
      });
    } else if (_isDragging) {
      // 拖拽选中元素
      final delta = details.delta;
      for (final id in widget.controller.state.selectedElementIds) {
        widget.controller.updateElementPositionWithSnap(id, delta);
      }
    }
  }

  /// 处理点击事件
  void _handleTapDown(
      TapDownDetails details, List<Map<String, dynamic>> elements) {
    if (widget.isPreviewMode) return;

    if (widget.currentTool == 'select') {
      // 选择工具模式
      final hitElement = _hitTestElement(details.localPosition, elements);
      if (hitElement != null) {
        widget.onElementTap(hitElement, details.localPosition);
      } else {
        // 点击空白区域，开始框选或取消选择
        if (_isCtrlPressed || _isShiftPressed) {
          // 按住Ctrl或Shift开始框选
          _selectionManager.startSelection(details.localPosition);
        } else {
          // 普通点击空白区域，取消选择
          widget.controller.clearSelection();
        }
      }
    }
  }

  /// 命中测试
  Map<String, dynamic>? _hitTestElement(
      Offset position, List<Map<String, dynamic>> elements) {
    // 从上到下（Z序）遍历元素进行命中测试
    for (int i = elements.length - 1; i >= 0; i--) {
      final element = elements[i];
      if (_isPointInElement(position, element)) {
        return element;
      }
    }
    return null;
  }

  /// 检查点是否在元素内
  bool _isPointInElement(Offset position, Map<String, dynamic> element) {
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();

    final rect = Rect.fromLTWH(x, y, width, height);
    return rect.contains(position);
  }

  /// 将选中元素下移一层
  void _moveSelectedElementsDown() {
    if (widget.controller.state.selectedElementIds.isEmpty) return;

    final elements = widget.controller.state.currentPageElements;
    final selectedIds = widget.controller.state.selectedElementIds;

    // 按照元素在列表中的顺序排序选中的元素ID
    final sortedSelectedIds = selectedIds.toList()
      ..sort((a, b) {
        final indexA = elements.indexWhere((e) => e['id'] == a);
        final indexB = elements.indexWhere((e) => e['id'] == b);
        return indexA.compareTo(indexB);
      });

    // 从前向后处理，避免索引变化
    for (final id in sortedSelectedIds) {
      final index = elements.indexWhere((e) => e['id'] == id);

      if (index > 0) {
        // 交换元素位置
        final temp = elements[index];
        elements[index] = elements[index - 1];
        elements[index - 1] = temp;
      }
    }

    // 更新页面元素
    final currentPageIndex = widget.controller.state.currentPageIndex;
    widget.controller.state.pages[currentPageIndex]['elements'] = elements;
    widget.controller.updateElementsOrder();
  }

  /// 将选中元素上移一层
  void _moveSelectedElementsUp() {
    if (widget.controller.state.selectedElementIds.isEmpty) return;

    final elements = widget.controller.state.currentPageElements;
    final selectedIds = widget.controller.state.selectedElementIds;

    // 按照元素在列表中的顺序排序选中的元素ID
    final sortedSelectedIds = selectedIds.toList()
      ..sort((a, b) {
        final indexA = elements.indexWhere((e) => e['id'] == a);
        final indexB = elements.indexWhere((e) => e['id'] == b);
        return indexA.compareTo(indexB);
      });

    // 从后向前处理，避免索引变化
    for (int i = sortedSelectedIds.length - 1; i >= 0; i--) {
      final id = sortedSelectedIds[i];
      final index = elements.indexWhere((e) => e['id'] == id);

      if (index < elements.length - 1) {
        // 交换元素位置
        final temp = elements[index];
        elements[index] = elements[index + 1];
        elements[index + 1] = temp;
      }
    }

    // 更新页面元素
    final currentPageIndex = widget.controller.state.currentPageIndex;
    widget.controller.state.pages[currentPageIndex]['elements'] = elements;
    widget.controller.updateElementsOrder();
  }

  /// 选择矩形区域内的元素
  void _selectElementsInRect(Rect selectionRect) {
    final elements = widget.controller.state.currentPageElements;
    final selectedIds = <String>[];

    for (final element in elements) {
      if (_selectionManager.isElementInSelection(element, selectionRect)) {
        selectedIds.add(element['id'] as String);
      }
    }

    if (selectedIds.isNotEmpty) {
      if (_isCtrlPressed || _isShiftPressed) {
        // 按住Ctrl或Shift时，添加到当前选中元素
        final currentSelectedIds =
            widget.controller.state.selectedElementIds.toList();
        for (final id in selectedIds) {
          if (!currentSelectedIds.contains(id)) {
            currentSelectedIds.add(id);
          }
        }
        widget.controller.selectElements(currentSelectedIds);
      } else {
        // 普通选择，替换当前选中元素
        widget.controller.selectElements(selectedIds);
      }
    }
  }

  /// 将选中元素置于底层
  void _sendSelectedElementsToBack() {
    if (widget.controller.state.selectedElementIds.isEmpty) return;

    final elements = widget.controller.state.currentPageElements;
    final selectedIds = widget.controller.state.selectedElementIds;

    // 找出所有选中的元素
    final selectedElements =
        elements.where((e) => selectedIds.contains(e['id'])).toList();

    // 从原列表中移除选中的元素
    elements.removeWhere((e) => selectedIds.contains(e['id']));

    // 将选中的元素添加到列表开头（底层）
    elements.insertAll(0, selectedElements);

    // 更新页面元素
    final currentPageIndex = widget.controller.state.currentPageIndex;
    widget.controller.state.pages[currentPageIndex]['elements'] = elements;
    widget.controller.updateElementsOrder();
  }

  /// 显示集字对话框
  void _showCollectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController();

        return AlertDialog(
          title: const Text('添加集字内容'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: '请输入汉字',
              hintText: '例如：永字八法',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = textController.text.trim();
                if (text.isNotEmpty) {
                  Navigator.of(context).pop();
                  widget.onAddCollectionElement(text);
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  /// 显示元素上下文菜单
  void _showElementContextMenu(
      BuildContext context, Map<String, dynamic> element, Offset position) {
    final id = element['id'] as String;

    // 如果元素未选中，先选中它
    if (!widget.controller.state.selectedElementIds.contains(id)) {
      widget.controller.selectElement(id);
    }

    // 使用元素上下文菜单组件
    showDialog(
      context: context,
      builder: (context) => ElementContextMenu(
        element: element,
        controller: widget.controller,
        onMoveUp: _moveSelectedElementsUp,
        onMoveDown: _moveSelectedElementsDown,
        onBringToFront: _bringSelectedElementsToFront,
        onSendToBack: _sendSelectedElementsToBack,
        onGroup: _groupSelectedElements,
      ),
    );
  }

  /// 显示图片URL对话框
  void _showImageUrlDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController();

        return AlertDialog(
          title: const Text('添加图片'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: '请输入图片URL',
              hintText: 'https://example.com/image.jpg',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final url = textController.text.trim();
                if (url.isNotEmpty) {
                  Navigator.of(context).pop();
                  widget.onAddImageElement(url);
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }
}

/// 选择框绘制器
class _SelectionPainter extends CustomPainter {
  final SelectionManager selectionManager;

  _SelectionPainter(this.selectionManager);

  @override
  void paint(Canvas canvas, Size size) {
    selectionManager.paintSelectionRect(canvas);
  }

  @override
  bool shouldRepaint(_SelectionPainter oldDelegate) => true;
}
