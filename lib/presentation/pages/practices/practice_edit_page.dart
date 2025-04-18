import 'package:flutter/material.dart';

import '../../widgets/practice/control_handlers.dart';
import '../../widgets/practice/edit_toolbar.dart';
import '../../widgets/practice/element_operations.dart';
import '../../widgets/practice/element_renderers.dart';
import '../../widgets/practice/file_operations.dart';
import '../../widgets/practice/grid_painter.dart';
import '../../widgets/practice/page_operations.dart';
import '../../widgets/practice/page_thumbnail_strip.dart';
import '../../widgets/practice/practice_edit_controller.dart';
import '../../widgets/practice/practice_layer_panel.dart';
import '../../widgets/practice/practice_property_panel.dart';

/// 字帖编辑页面
class PracticeEditPage extends StatefulWidget {
  final String? practiceId;

  const PracticeEditPage({super.key, this.practiceId});

  @override
  State<PracticeEditPage> createState() => _PracticeEditPageState();
}

class _PracticeEditPageState extends State<PracticeEditPage> {
  // 控制器
  late final PracticeEditController _controller;

  // 当前工具
  String _currentTool = 'select';

  // 网格大小
  double _gridSize = 20.0;

  // 剪贴板
  Map<String, dynamic>? _clipboardElement;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('字帖编辑'),
        actions: [
          // 文件操作按钮
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '保存',
            onPressed: () => _savePractice(context),
          ),
          IconButton(
            icon: const Icon(Icons.save_as),
            tooltip: '另存为',
            onPressed: () => _saveAs(context),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: '打印',
            onPressed: () => _printPractice(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: '导出',
            onPressed: () => _exportPractice(context),
          ),

          const SizedBox(width: 16),

          // 撤销/重做按钮
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: '撤销',
            onPressed:
                _controller.undoRedoManager.canUndo ? _controller.undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: '重做',
            onPressed:
                _controller.undoRedoManager.canRedo ? _controller.redo : null,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            children: [
              // 工具栏
              EditToolbar(
                gridVisible: _controller.state.gridVisible,
                snapEnabled: _controller.state.snapEnabled,
                hasSelection: _controller.state.selectedElementIds.isNotEmpty,
                isGroupSelection: _controller.state.selectedElement != null &&
                    _controller.state.selectedElement!['type'] == 'group',
                hasMultiSelection:
                    _controller.state.selectedElementIds.length > 1,
                onToolSelected: (tool) => setState(() => _currentTool = tool),
                onCopy: _copySelectedElement,
                onPaste: _pasteElement,
                onDelete: _controller.deleteSelectedElements,
                onGroup: _controller.groupSelectedElements,
                onUngroup: _controller.ungroupSelectedElement,
                onToggleGrid: _controller.toggleGrid,
                onSetGridSize: (size) => setState(() => _gridSize = size),
                onToggleSnap: _controller.toggleSnap,
              ),

              // 主体内容
              Expanded(
                child: Row(
                  children: [
                    // 左侧面板 - 图层
                    SizedBox(
                      width: 250,
                      child: PracticeLayerPanel(
                        layers: _controller.state.layers,
                        onLayerSelected: _controller.selectLayer,
                        onLayerVisibilityChanged:
                            _controller.setLayerVisibility,
                        onLayerLockChanged: _controller.setLayerLocked,
                        onLayerDeleted: _controller.deleteLayer,
                        onLayerReordered: _controller.reorderLayers,
                        onLayerRenamed: _controller.renameLayer,
                        onAddLayer: _controller.addLayer,
                        onDeleteAllLayers: _controller.deleteAllLayers,
                        onShowAllLayers: _controller.showAllLayers,
                      ),
                    ),

                    // 中间编辑区域
                    Expanded(
                      child: Stack(
                        children: [
                          // 编辑画布
                          _buildEditCanvas(),

                          // 添加元素按钮
                          Positioned(
                            right: 16,
                            top: 16,
                            child: Column(
                              children: [
                                FloatingActionButton(
                                  heroTag: 'add_text',
                                  mini: true,
                                  onPressed: _controller.addTextElement,
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
                                  onPressed: () =>
                                      _showCollectionDialog(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 右侧面板 - 属性
                    SizedBox(
                      width: 250,
                      child: PracticePropertyPanel(
                        selectedElement: _controller.state.selectedElement,
                        onPropertyChanged: (properties) {
                          if (_controller.state.selectedElementIds.length ==
                              1) {
                            _controller.updateElementProperties(
                              _controller.state.selectedElementIds.first,
                              properties,
                            );
                          }
                        },
                        isGroupSelection:
                            _controller.state.selectedElementIds.length > 1,
                      ),
                    ),
                  ],
                ),
              ),

              // 底部页面缩略图条
              if (_controller.state.isPageThumbnailsVisible)
                PageThumbnailStrip(
                  pages: _controller.state.pages,
                  currentPageIndex: _controller.state.currentPageIndex,
                  onPageSelected: _controller.selectPage,
                  onAddPage: _controller.addPage,
                  onDeletePage: _controller.deletePage,
                ),
            ],
          );
        },
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
                  width: 595, // A4 宽度 (72dpi)
                  height: 842, // A4 高度 (72dpi)
                  color: PageOperations.getPageBackgroundColor(currentPage),
                  child: Stack(
                    children: [
                      // 网格
                      if (_controller.state.gridVisible)
                        CustomPaint(
                          size: const Size(595, 842),
                          painter: GridPainter(gridSize: _gridSize),
                        ),

                      // 元素
                      for (final element in elements) _buildElement(element),
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
    final type = element['type'] as String;
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num).toDouble();

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
          color: Colors.grey.withOpacity(0.2),
          child: const Center(child: Text('未知元素')),
        );
    }

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () => _controller.selectElement(
          id,
          isMultiSelect: false,
        ),
        child: Transform.rotate(
          angle: rotation * 3.1415926 / 180,
          child: Container(
            width: width,
            height: height,
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                  )
                : null,
            child: Stack(
              children: [
                // 元素内容
                content,

                // 如果选中，显示控制点
                if (isSelected)
                  ControlHandlers.buildTransformControls(width, height),
              ],
            ),
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

  /// 导出字帖
  Future<void> _exportPractice(BuildContext context) async {
    await FileOperations.exportPractice(
      context,
      _controller.state.pages,
    );
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

  /// 打印字帖
  Future<void> _printPractice(BuildContext context) async {
    await FileOperations.printPractice(
      context,
      _controller.state.pages,
    );
  }

  /// 另存为
  Future<void> _saveAs(BuildContext context) async {
    await FileOperations.saveAs(
      context,
      _controller.state.pages,
      _controller.state.layers,
    );
  }

  /// 保存字帖
  Future<void> _savePractice(BuildContext context) async {
    await FileOperations.savePractice(
      context,
      _controller.state.pages,
      _controller.state.layers,
      widget.practiceId,
    );
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
