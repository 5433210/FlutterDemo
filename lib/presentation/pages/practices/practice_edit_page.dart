import 'package:demo/presentation/widgets/page_layout.dart';
import 'package:demo/presentation/widgets/practice/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerState, ConsumerStatefulWidget;

import '../../widgets/practice/control_handlers.dart';
import '../../widgets/practice/edit_toolbar.dart';
import '../../widgets/practice/element_operations.dart';
import '../../widgets/practice/element_renderers.dart';
import '../../widgets/practice/grid_painter.dart';
import '../../widgets/practice/page_operations.dart';
import '../../widgets/practice/page_thumbnail_strip.dart';
import '../../widgets/practice/practice_edit_controller.dart';
import '../../widgets/practice/practice_layer_panel.dart';
import '../../widgets/practice/practice_property_panel.dart';

/// 字帖编辑页面
class PracticeEditPage extends ConsumerStatefulWidget {
  final String? practiceId;

  const PracticeEditPage({super.key, this.practiceId});

  @override
  ConsumerState<PracticeEditPage> createState() => _PracticeEditPageState();
}

class _PracticeEditPageState extends ConsumerState<PracticeEditPage> {
  // 控制器
  late final PracticeEditController _controller;

  // 当前工具
  String _currentTool = 'select';

  // 网格大小
  final double _gridSize = 20.0;

  // 剪贴板
  Map<String, dynamic>? _clipboardElement;

  // 预览模式
  final bool _isPreviewMode = false;

  // 拖拽状态
  bool _isDragging = false;
  Offset _dragStart = Offset.zero;
  Offset _elementStartPosition = Offset.zero;

  // 控制页面缩略图显示
  final bool _showThumbnails = true;
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: PageLayout(
        toolbar: TopNavigationBar(
          controller: _controller,
          isPreviewMode: _isPreviewMode,
          onTogglePreviewMode: () {
            setState(() {
              // Toggle preview mode functionality
            });
          },
          showThumbnails: _showThumbnails,
          onThumbnailToggle: (bool value) {
            setState(() {
              // Toggle thumbnails functionality
            });
          },
        ),
        body: _buildBody(context),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = PracticeEditController();

    // 如果有ID，加载现有字帖
    if (widget.practiceId != null) {
      _loadPractice(widget.practiceId!);
    }
  }

  /// 将元素置于顶层
  void _bringElementToFront() {
    if (_controller.state.selectedElementIds.isEmpty) return;

    final id = _controller.state.selectedElementIds.first;
    final elements = _controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index >= 0 && index < elements.length - 1) {
      // 移除元素
      final element = elements.removeAt(index);
      // 添加到末尾（最顶层）
      elements.add(element);

      // 更新当前页面的元素
      _controller.state.pages[_controller.state.currentPageIndex]['elements'] =
          elements;
      _controller.state.hasUnsavedChanges = true;

      setState(() {});
    }
  }

  Widget _buildBody(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          children: [
            // 左侧面板
            if (!_isPreviewMode) _buildLeftPanel(),

            // 中央编辑区
            Expanded(
              child: Column(
                children: [
                  // 工具栏
                  if (!_isPreviewMode) _buildEditToolbar(),

                  // 编辑画布
                  Expanded(child: _buildEditCanvas()),

                  // 页面缩略图栏
                  if (_showThumbnails && !_isPreviewMode)
                    SizedBox(
                      height: 120,
                      child: PageThumbnailStrip(
                        pages: _controller.state.pages,
                        currentPageIndex: _controller.state.currentPageIndex,
                        onPageSelected: (index) =>
                            _controller.setCurrentPage(index),
                        onAddPage: _controller.addNewPage,
                        onDeletePage: _controller.deletePage,
                        onReorderPages: (oldIndex, newIndex) {
                          _controller.reorderPages(oldIndex, newIndex);
                        },
                      ),
                    ),
                ],
              ),
            ),

            // 右侧属性面板
            if (!_isPreviewMode) _buildRightPanel(),
          ],
        );
      },
    );
  }

  /// 构建内容控件区
  Widget _buildContentToolPanel() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              '内容控件',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              _buildDraggableToolButton(
                icon: Icons.title,
                label: '文本',
                toolName: 'text',
                elementType: 'text',
              ),
              _buildDraggableToolButton(
                icon: Icons.image,
                label: '图片',
                toolName: 'image',
                elementType: 'image',
              ),
              _buildDraggableToolButton(
                icon: Icons.format_shapes,
                label: '集字',
                toolName: 'collection',
                elementType: 'collection',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建可拖拽的工具按钮
  Widget _buildDraggableToolButton({
    required IconData icon,
    required String label,
    required String toolName,
    required String elementType,
  }) {
    final isSelected = _currentTool == toolName;

    return Draggable<String>(
      // 拖拽的数据是元素类型
      data: elementType,
      // 拖拽时显示的控件
      feedback: Material(
        elevation: 4.0,
        child: Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(204), // 0.8 opacity
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24.0),
              const SizedBox(height: 4.0),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
      ),
      // 拖拽时原位置显示的控件
      childWhenDragging: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.5,
          child: _buildToolButton(
            icon: icon,
            label: label,
            toolName: toolName,
            onPressed: () {}, // 拖拽时禁用点击
          ),
        ),
      ),
      // 原始控件
      child: _buildToolButton(
        icon: icon,
        label: label,
        toolName: toolName,
        onPressed: () {
          setState(() {
            _currentTool = toolName;
          });
          // 点击时默认添加对应类型的元素
          switch (elementType) {
            case 'text':
              _controller.addTextElement();
              break;
            case 'image':
              // 直接添加空图片元素，不显示对话框
              _controller.addEmptyImageElementAt(100.0, 100.0);
              break;
            case 'collection':
              // 直接添加空集字元素，不显示对话框
              _controller.addEmptyCollectionElementAt(100.0, 100.0);
              break;
          }
        },
      ),
    );
  }

  /// 构建编辑画布
  Widget _buildEditCanvas() {
    if (_controller.state.pages.isEmpty) {
      return const Center(child: Text('没有页面，请添加页面'));
    }

    final currentPage = _controller.state.currentPage;
    if (currentPage == null) {
      return const Center(child: Text('当前页面不存在'));
    }

    final elements = _controller.state.currentPageElements;

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        // 获取放置位置 - 相对于编辑画布的坐标
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.offset);

        // 获取InteractiveViewer的变换矩阵
        // 注意：在实际应用中，你可能需要保存和访问InteractiveViewer的TransformationController
        // 这里简化处理，使用一个估计的位置

        // 计算A4页面中心位置
        const pageWidth = 595.0; // A4 宽度 (72dpi)
        const pageHeight = 842.0; // A4 高度 (72dpi)

        // 使用相对位置，如果坐标在可见范围内，则使用实际位置
        // 否则默认放在页面中心
        double x = localPosition.dx;
        double y = localPosition.dy;

        // 确保坐标在页面范围内
        x = x.clamp(0.0, pageWidth);
        y = y.clamp(0.0, pageHeight);

        // 根据类型添加不同的元素
        switch (details.data) {
          case 'text':
            _controller.addTextElementAt(x, y);
            break;
          case 'image':
            // 直接添加空图片元素，不显示对话框
            _controller.addEmptyImageElementAt(x, y);
            break;
          case 'collection':
            // 直接添加空集字元素，不显示对话框
            _controller.addEmptyCollectionElementAt(x, y);
            break;
        }
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTapDown: (details) => _handleTapDown(details, elements),
          child: Container(
            color: Colors.grey.shade200,
            child: Center(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(100),
                minScale: 0.1,
                maxScale: 5.0,
                child: Stack(
                  children: [
                    // 页面背景
                    Container(
                      width:
                          (currentPage['width'] as num?)?.toDouble() ?? 595.0,
                      height:
                          (currentPage['height'] as num?)?.toDouble() ?? 842.0,
                      color: PageOperations.getPageBackgroundColor(currentPage),
                      child: Stack(
                        children: [
                          // 网格
                          if (_controller.state.gridVisible)
                            CustomPaint(
                              size: Size(
                                (currentPage['width'] as num?)?.toDouble() ??
                                    595.0,
                                (currentPage['height'] as num?)?.toDouble() ??
                                    842.0,
                              ),
                              painter: GridPainter(gridSize: _gridSize),
                            ),

                          // 元素
                          for (final element in elements)
                            _buildElement(element),

                          // 拖拽指示
                          if (candidateData.isNotEmpty)
                            Container(
                              width: 595,
                              height: 842,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
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
      },
    );
  }

  /// 构建顶部编辑工具栏
  Widget _buildEditToolbar() {
    return EditToolbar(
      controller: _controller,
      gridVisible: _controller.state.gridVisible,
      snapEnabled: _controller.state.snapEnabled,
      onToggleGrid: () {
        _controller.state.gridVisible = !_controller.state.gridVisible;
        setState(() {});
      },
      onToggleSnap: () {
        _controller.state.snapEnabled = !_controller.state.snapEnabled;
        setState(() {});
      },
      onCopy: _copySelectedElement,
      onPaste: _pasteElement,
      onGroupElements: () {
        if (_controller.state.selectedElementIds.length > 1) {
          _controller.groupSelectedElements();
        }
      },
      onUngroupElements: () {
        if (_controller.state.selectedElementIds.length == 1) {
          final id = _controller.state.selectedElementIds.first;
          final element = ElementOperations.findElementById(
              _controller.state.currentPageElements, id);
          if (element != null && element['type'] == 'group') {
            _controller.ungroupElements(id);
          }
        }
      },
      onBringToFront: _bringElementToFront,
      onSendToBack: _sendElementToBack,
      onMoveUp: _moveElementUp,
      onMoveDown: _moveElementDown,
      onDelete: () {
        if (_controller.state.selectedElementIds.isNotEmpty) {
          for (final id in _controller.state.selectedElementIds) {
            _controller.deleteElement(id);
          }
        }
      },
    );
  }

  /// 构建元素
  Widget _buildElement(Map<String, dynamic> element) {
    final id = element['id'] as String;
    final type = element['type'] as String;
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num).toDouble();
    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;

    // 检查元素是否被选中
    final isSelected = _controller.state.selectedElementIds.contains(id);

    Widget content;

    // 根据元素类型构建内容
    switch (type) {
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
          color: Colors.grey.withAlpha(51), // 0.2 opacity
          child: const Center(child: Text('未知元素')),
        );
    }

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: _isPreviewMode
            ? null // 预览模式下禁用选择
            : () => _controller.selectElement(id, isMultiSelect: false),
        onPanStart: !_isPreviewMode && isSelected
            ? (details) {
                setState(() {
                  _isDragging = true;
                  _dragStart = details.localPosition;
                  _elementStartPosition = Offset(x, y);
                });
              }
            : null,
        onPanUpdate: !_isPreviewMode && isSelected && _isDragging
            ? (details) {
                final dx = details.localPosition.dx - _dragStart.dx;
                final dy = details.localPosition.dy - _dragStart.dy;
                final newX = _elementStartPosition.dx + dx;
                final newY = _elementStartPosition.dy + dy;

                _controller.updateElementProperties(id, {
                  'x': newX,
                  'y': newY,
                });
              }
            : null,
        onPanEnd: !_isPreviewMode && isSelected && _isDragging
            ? (details) {
                setState(() {
                  _isDragging = false;
                });
              }
            : null,
        child: Transform.rotate(
          angle: rotation * 3.1415926 / 180,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: width,
              height: height,
              decoration: !_isPreviewMode && isSelected
                  ? BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                    )
                  : null,
              child: Stack(
                children: [
                  // 元素内容
                  content,

                  // 如果选中且不在预览模式，显示控制点
                  if (!_isPreviewMode && isSelected)
                    ControlHandlers.buildTransformControls(width, height),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建左侧面板
  Widget _buildLeftPanel() {
    return SizedBox(
      width: 250,
      child: Column(
        children: [
          // 内容控件区
          _buildContentToolPanel(),

          const Divider(),

          // 图层管理区
          Expanded(
            child: PracticeLayerPanel(
              controller: _controller,
              onLayerSelect: (layerId) {
                // 处理图层选择
                _controller.selectLayer(layerId);
              },
              onLayerVisibilityToggle: (layerId, isVisible) {
                // 处理图层可见性切换
                _controller.toggleLayerVisibility(layerId, isVisible);
              },
              onLayerLockToggle: (layerId, isLocked) {
                // 处理图层锁定切换
                _controller.toggleLayerLock(layerId, isLocked);
              },
              onAddLayer: _controller.addNewLayer,
              onDeleteLayer: _controller.deleteLayer,
              onReorderLayer: _controller.reorderLayer,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建右侧属性面板
  Widget _buildRightPanel() {
    Widget panel;

    // 检查是否选中了图层
    if (_controller.state.selectedLayerId != null) {
      // 选中图层时显示图层属性
      final layerId = _controller.state.selectedLayerId!;
      final layer = _controller.state.getLayerById(layerId);
      if (layer != null) {
        panel = PracticePropertyPanel.forLayer(
          controller: _controller,
          layer: layer,
          onLayerPropertiesChanged: (properties) {
            // 更新图层属性
            _controller.updateLayerProperties(layerId, properties);
          },
        );
        return SizedBox(
          width: 300,
          child: panel,
        );
      }
    }

    // 根据选中元素类型显示不同的属性面板
    if (_controller.state.selectedElementIds.isEmpty) {
      // 未选中元素时显示页面属性
      panel = PracticePropertyPanel.forPage(
        controller: _controller,
        page: _controller.state.currentPage,
        onPagePropertiesChanged: (properties) {
          if (_controller.state.currentPageIndex >= 0) {
            _controller.updatePageProperties(properties);
          }
        },
      );
    } else if (_controller.state.selectedElementIds.length == 1) {
      // 单选元素时根据类型显示属性
      final id = _controller.state.selectedElementIds.first;
      final element = ElementOperations.findElementById(
          _controller.state.currentPageElements, id);

      if (element != null) {
        switch (element['type']) {
          case 'text':
            panel = PracticePropertyPanel.forText(
              controller: _controller,
              element: element,
              onElementPropertiesChanged: (properties) {
                _controller.updateElementProperties(id, properties);
              },
            );
            break;
          case 'image':
            panel = PracticePropertyPanel.forImage(
              controller: _controller,
              element: element,
              onElementPropertiesChanged: (properties) {
                _controller.updateElementProperties(id, properties);
              },
              onSelectImage: () async {
                // 实现选择图片的逻辑
                await _showImageUrlDialog(context);
              },
            );
            break;
          case 'collection':
            panel = PracticePropertyPanel.forCollection(
              controller: _controller,
              element: element,
              onElementPropertiesChanged: (properties) {
                _controller.updateElementProperties(id, properties);
              },
              onUpdateChars: (chars) {
                // Get the current content map
                final content = Map<String, dynamic>.from(
                    element['content'] as Map<String, dynamic>);
                // Update the characters property
                content['characters'] = chars;
                // Update the element with the modified content map
                final updatedProps = {'content': content};
                _controller.updateElementProperties(id, updatedProps);
              },
            );
            break;
          case 'group':
            panel = PracticePropertyPanel.forGroup(
              controller: _controller,
              element: element,
              onElementPropertiesChanged: (properties) {
                _controller.updateElementProperties(id, properties);
              },
            );
            break;
          default:
            panel = const Center(child: Text('不支持的元素类型'));
        }
      } else {
        panel = const Center(child: Text('找不到选中的元素'));
      }
    } else {
      // 多选元素时显示组合属性
      panel = PracticePropertyPanel.forMultiSelection(
        controller: _controller,
        selectedIds: _controller.state.selectedElementIds,
        onElementPropertiesChanged: (properties) {
          // 将属性应用到所有选中的元素
          for (final id in _controller.state.selectedElementIds) {
            _controller.updateElementProperties(id, properties);
          }
        },
      );
    }

    return SizedBox(
      width: 300,
      child: panel,
    );
  }

  /// 构建工具按钮
  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required String toolName,
    required VoidCallback onPressed,
  }) {
    final isSelected = _currentTool == toolName;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _currentTool = toolName;
          });
          onPressed();
        },
        borderRadius: BorderRadius.circular(4.0),
        child: Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withAlpha(26) : null, // 0.1 opacity
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.blue : null,
                size: 24.0,
              ),
              const SizedBox(height: 4.0),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blue : null,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 复制选中的元素
  void _copySelectedElement() {
    if (_controller.state.selectedElementIds.isEmpty) return;

    if (_controller.state.selectedElementIds.length == 1) {
      // 单选复制
      final id = _controller.state.selectedElementIds.first;
      final elements = _controller.state.currentPageElements;
      final element = ElementOperations.findElementById(elements, id);

      if (element != null) {
        _clipboardElement = Map<String, dynamic>.from(element);
      }
    } else {
      // 多选复制暂不支持
    }
  }

  /// 处理点击事件
  void _handleTapDown(
      TapDownDetails details, List<Map<String, dynamic>> elements) {
    // 如果点击在空白处，取消选择
    bool hitElement = false;

    // 从后往前检查（后添加的元素在上层）
    for (int i = elements.length - 1; i >= 0; i--) {
      final element = elements[i];
      final id = element['id'] as String;
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();

      // 简单的矩形碰撞检测
      if (details.localPosition.dx >= x &&
          details.localPosition.dx <= x + width &&
          details.localPosition.dy >= y &&
          details.localPosition.dy <= y + height) {
        hitElement = true;
        _controller.selectElement(id);
        break;
      }
    }

    if (!hitElement) {
      // 点击空白处，取消选择
      _controller.state.selectedElementIds.clear();
      _controller.state.selectedElement = null;
      setState(() {});
    }
  }

  // 加载字帖
  Future<void> _loadPractice(String id) async {
    // 这里应该实现实际的加载逻辑
    // 例如，从数据库或文件系统加载数据
  }

  /// 将元素下移一层
  void _moveElementDown() {
    if (_controller.state.selectedElementIds.isEmpty) return;

    final id = _controller.state.selectedElementIds.first;
    final elements = _controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index > 0) {
      // 交换元素位置
      final temp = elements[index];
      elements[index] = elements[index - 1];
      elements[index - 1] = temp;

      // 更新当前页面的元素
      _controller.state.pages[_controller.state.currentPageIndex]['elements'] =
          elements;
      _controller.state.hasUnsavedChanges = true;

      setState(() {});
    }
  }

  /// 将元素上移一层
  void _moveElementUp() {
    if (_controller.state.selectedElementIds.isEmpty) return;

    final id = _controller.state.selectedElementIds.first;
    final elements = _controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index < elements.length - 1) {
      // 交换元素位置
      final temp = elements[index];
      elements[index] = elements[index + 1];
      elements[index + 1] = temp;

      // 更新当前页面的元素
      _controller.state.pages[_controller.state.currentPageIndex]['elements'] =
          elements;
      _controller.state.hasUnsavedChanges = true;

      setState(() {});
    }
  }

  /// 粘贴元素
  void _pasteElement() {
    if (_clipboardElement == null) return;

    // 创建新元素ID
    final newId =
        '${_clipboardElement!['type']}_${DateTime.now().millisecondsSinceEpoch}';

    // 复制元素并修改位置（稍微偏移一点）
    final newElement = {
      ..._clipboardElement!,
      'id': newId,
      'x': (_clipboardElement!['x'] as num).toDouble() + 20,
      'y': (_clipboardElement!['y'] as num).toDouble() + 20,
    };

    // 添加到当前页面
    final elements = _controller.state.currentPageElements;
    elements.add(newElement);

    // 更新当前页面的元素
    _controller.state.pages[_controller.state.currentPageIndex]['elements'] =
        elements;

    // 选中新粘贴的元素
    _controller.state.selectedElementIds = [newId];
    _controller.state.selectedElement = newElement;
    _controller.state.hasUnsavedChanges = true;

    setState(() {});
  }

  /// 将元素置于底层
  void _sendElementToBack() {
    if (_controller.state.selectedElementIds.isEmpty) return;

    final id = _controller.state.selectedElementIds.first;
    final elements = _controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index > 0) {
      // 移除元素
      final element = elements.removeAt(index);
      // 添加到开头（最底层）
      elements.insert(0, element);

      // 更新当前页面的元素
      _controller.state.pages[_controller.state.currentPageIndex]['elements'] =
          elements;
      _controller.state.hasUnsavedChanges = true;

      setState(() {});
    }
  }

  /// 显示集字输入对话框
  Future<void> _showCollectionDialog(BuildContext context) async {
    String characters = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加集字'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: '字符',
            hintText: '输入要集字的字符',
          ),
          onChanged: (value) => characters = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result == true && characters.isNotEmpty) {
      _controller.addCollectionElement(characters);
    }
  }

  /// 显示图片URL输入对话框
  Future<void> _showImageUrlDialog(BuildContext context) async {
    String imageUrl = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加图片'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: '图片URL',
            hintText: '输入图片URL',
          ),
          onChanged: (value) => imageUrl = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result == true && imageUrl.isNotEmpty) {
      _controller.addImageElement(imageUrl);
    }
  }
}
