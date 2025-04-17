import 'package:flutter/material.dart';

import '../../../domain/models/practice/practice_element.dart';
import '../../../domain/models/practice/practice_page.dart';
import '../../widgets/practice/practice_tool_panel.dart';
import '../../widgets/practice/right_property_panel.dart';
import '../../widgets/window/title_bar.dart';

// 网格绘制器
class GridPainter extends CustomPainter {
  final double gridSize;

  GridPainter({required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    // 绘制水平网格线
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 绘制垂直网格线
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is GridPainter && oldDelegate.gridSize != gridSize;
  }
}

class PracticeEditPage extends StatefulWidget {
  final String? practiceId; // 可选ID，如果为null则表示新建

  const PracticeEditPage({
    super.key,
    this.practiceId,
  });

  @override
  State<PracticeEditPage> createState() => _PracticeEditPageState();
}

class PracticeLayerPanel extends StatelessWidget {
  final List<Map<String, dynamic>> layers;
  final Function(int) onLayerSelected;
  final Function(int, bool) onLayerVisibilityChanged;
  final Function(int, bool) onLayerLockChanged;
  final Function(int) onLayerDeleted;
  final Function(int, int) onLayerReordered;
  final Function(int, String) onLayerRenamed;
  final VoidCallback onAddLayer;
  final VoidCallback onDeleteAllLayers;
  final VoidCallback onShowAllLayers;

  const PracticeLayerPanel({
    super.key,
    required this.layers,
    required this.onLayerSelected,
    required this.onLayerVisibilityChanged,
    required this.onLayerLockChanged,
    required this.onLayerDeleted,
    required this.onLayerReordered,
    required this.onLayerRenamed,
    required this.onAddLayer,
    required this.onDeleteAllLayers,
    required this.onShowAllLayers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 图层列表
        Expanded(
          child: ReorderableListView.builder(
            itemCount: layers.length,
            itemBuilder: (context, index) {
              final layer = layers[index];
              return ListTile(
                key: ValueKey(layer['id']),
                title: Text(layer['name']),
                leading: Checkbox(
                  value: layer['visible'],
                  onChanged: (value) =>
                      onLayerVisibilityChanged(index, value ?? true),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon:
                          Icon(layer['locked'] ? Icons.lock : Icons.lock_open),
                      onPressed: () =>
                          onLayerLockChanged(index, !layer['locked']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => onLayerDeleted(index),
                    ),
                  ],
                ),
                onTap: () => onLayerSelected(index),
              );
            },
            onReorder: onLayerReordered,
          ),
        ),

        // 操作按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: onAddLayer,
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: onDeleteAllLayers,
            ),
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: onShowAllLayers,
            ),
          ],
        ),
      ],
    );
  }
}

class PracticePropertyPanel extends StatelessWidget {
  final Map<String, dynamic>? selectedElement;
  final Function(Map<String, dynamic>) onPropertyChanged;
  final bool isGroupSelection;

  const PracticePropertyPanel({
    super.key,
    this.selectedElement,
    required this.onPropertyChanged,
    this.isGroupSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedElement == null) {
      return const Center(child: Text('未选择元素'));
    }

    if (isGroupSelection) {
      return const Center(child: Text('多选模式'));
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Text('属性面板', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildTextField('名称', selectedElement!['name'] ?? '', (value) {
          onPropertyChanged({...selectedElement!, 'name': value});
        }),
        const SizedBox(height: 16),
        _buildTextField('宽度', selectedElement!['width'].toString(), (value) {
          onPropertyChanged(
              {...selectedElement!, 'width': double.tryParse(value) ?? 0.0});
        }),
        const SizedBox(height: 16),
        _buildTextField('高度', selectedElement!['height'].toString(), (value) {
          onPropertyChanged(
              {...selectedElement!, 'height': double.tryParse(value) ?? 0.0});
        }),
        const SizedBox(height: 16),
        _buildTextField('X 坐标', selectedElement!['x'].toString(), (value) {
          onPropertyChanged(
              {...selectedElement!, 'x': double.tryParse(value) ?? 0.0});
        }),
        const SizedBox(height: 16),
        _buildTextField('Y 坐标', selectedElement!['y'].toString(), (value) {
          onPropertyChanged(
              {...selectedElement!, 'y': double.tryParse(value) ?? 0.0});
        }),
        const SizedBox(height: 16),
        _buildTextField('旋转角度', selectedElement!['rotation'].toString(),
            (value) {
          onPropertyChanged(
              {...selectedElement!, 'rotation': double.tryParse(value) ?? 0.0});
        }),
      ],
    );
  }

  Widget _buildTextField(
      String label, String initialValue, ValueChanged<String> onChanged) {
    return TextField(
      decoration: InputDecoration(labelText: label),
      controller: TextEditingController(text: initialValue),
      onChanged: onChanged,
    );
  }
}

class _PracticeEditPageState extends State<PracticeEditPage> {
  bool _hasUnsavedChanges = false;
  List<Map<String, dynamic>> _layers = [];
  Map<String, dynamic>? _selectedElement;
  bool _isPageThumbnailsVisible = true;
  List<Map<String, dynamic>> _pages = [];
  int _currentPageIndex = 0;
  double _currentZoom = 1.0;

  // 工具状态
  bool _gridVisible = false;

  bool _snapEnabled = true;
  // 选中元素状态
  List<String> _selectedElementIds = [];

  final bool _isGrouping = false;
  // 编辑历史
  final List<Map<String, dynamic>> _undoStack = [];

  final List<Map<String, dynamic>> _redoStack = [];
  // Current page getter
  Map<String, dynamic>? get _currentPage {
    return _currentPageIndex < _pages.length ? _pages[_currentPageIndex] : null;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Column(
          children: [
            const TitleBar(),
            _buildAppBar(),
            Expanded(
              child: Row(
                children: [
                  // 左侧工具面板和图层列表
                  SizedBox(
                    width: 250,
                    child: Column(
                      children: [
                        Expanded(
                          child: PracticeToolPanel(
                            onAddTextElement: _handleAddTextElement,
                            onAddImageElement: _handleAddImageElement,
                            onAddCollectionElement: _handleAddCollectionElement,
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: PracticeLayerPanel(
                            layers: _layers,
                            onLayerSelected: _handleLayerSelected,
                            onLayerVisibilityChanged:
                                _handleLayerVisibilityChanged,
                            onLayerLockChanged: _handleLayerLockChanged,
                            onLayerDeleted: _handleLayerDeleted,
                            onLayerReordered: _handleLayerReordered,
                            onLayerRenamed: _handleLayerRenamed,
                            onAddLayer: _handleAddLayer,
                            onDeleteAllLayers: _handleDeleteAllLayers,
                            onShowAllLayers: _handleShowAllLayers,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),

                  // 中央编辑区
                  Expanded(
                    child: Column(
                      children: [
                        _buildEditToolbar(),
                        Expanded(
                          child: _buildEditArea(),
                        ),
                        if (_isPageThumbnailsVisible)
                          _buildPageThumbnailStrip(),
                      ],
                    ),
                  ),

                  const VerticalDivider(width: 1),

                  // 右侧属性面板
                  SizedBox(
                    width: 500,
                    child: RightPropertyPanel(
                      page: _currentPage != null
                          ? _mapToPracticePage(_currentPage!)
                          : PracticePage.defaultPage(),
                      onPageChanged: _handlePageChanged,
                      selectedElement: _selectedElement != null
                          ? _mapToPracticeElement(_selectedElement!)
                          : null,
                      onElementChanged: _handleElementChanged,
                      isGroupSelection: _selectedElementIds.length > 1,
                      onUngroup:
                          _selectedElementIds.isEmpty ? null : _handleUngroup,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // 实际添加图片元素的方法
  void _addImageElement(String imageUrl) {
    setState(() {
      if (_pages.isEmpty || _currentPageIndex >= _pages.length) {
        return;
      }

      final newElementId = 'image_${DateTime.now().millisecondsSinceEpoch}';
      final defaultLayerId =
          _layers.isNotEmpty ? _layers.first['id'] : 'default';

      final newElement = {
        'id': newElementId,
        'type': 'image',
        'x': 100.0,
        'y': 100.0,
        'width': 200.0,
        'height': 200.0,
        'rotation': 0.0,
        'layerId': defaultLayerId,
        'imageUrl': imageUrl,
        'opacity': 1.0,
      };

      final elements =
          _pages[_currentPageIndex]['elements'] as List<dynamic>? ?? [];
      elements.add(newElement);

      // 选中新添加的元素
      _selectedElementIds = [newElementId];
      _selectedElement = newElement;
      _hasUnsavedChanges = true;
    });
  }

  // 构建添加页面按钮
  Widget _buildAddPageButton() {
    return GestureDetector(
      onTap: _handleAddPage,
      child: Container(
        width: 60,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Icon(Icons.add, size: 24),
        ),
      ),
    );
  }

  // 构建顶部操作栏
  Widget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async {
          if (await _onWillPop()) {
            Navigator.pop(context);
          }
        },
      ),
      title: Text(
        widget.practiceId == null ? '新建字帖' : '编辑字帖',
        style: const TextStyle(fontSize: 20),
      ),
      actions: [
        // 文件操作组
        IconButton(
          icon: const Icon(Icons.save),
          tooltip: '保存',
          onPressed: _handleSave,
        ),
        IconButton(
          icon: const Icon(Icons.save_as),
          tooltip: '保存到指定位置',
          onPressed: _handleSaveAs,
        ),
        IconButton(
          icon: const Icon(Icons.print),
          tooltip: '打印',
          onPressed: _handlePrint,
        ),
        IconButton(
          icon: const Icon(Icons.file_download),
          tooltip: '导出',
          onPressed: _handleExport,
        ),

        const VerticalDivider(),

        // 视图组
        IconButton(
          icon: Icon(_isPageThumbnailsVisible
              ? Icons.view_carousel_outlined
              : Icons.view_carousel),
          tooltip: '显示/隐藏页面缩略图',
          onPressed: _togglePageThumbnails,
        ),

        const VerticalDivider(),

        // 操作组
        IconButton(
          icon: const Icon(Icons.undo),
          tooltip: '撤销',
          onPressed: _undoStack.isEmpty ? null : _handleUndo,
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          tooltip: '重做',
          onPressed: _redoStack.isEmpty ? null : _handleRedo,
        ),
      ],
    );
  }

  // 构建集字元素
  Widget _buildCollectionElement(Map<String, dynamic> element) {
    final characters = element['characters'] as String? ?? '';
    final direction = element['direction'] as String? ?? 'horizontal';
    final spacing = (element['spacing'] as num?)?.toDouble() ?? 10.0;

    return Container(
      padding: const EdgeInsets.all(4),
      child: Wrap(
        direction: direction == 'vertical' ? Axis.vertical : Axis.horizontal,
        spacing: spacing,
        runSpacing: spacing,
        children: characters.split('').map((char) {
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                char,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 构建单个控制点
  Widget _buildControlPoint(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue, width: 2),
        shape: BoxShape.rectangle,
      ),
    );
  }

  // 构建中央编辑区
  Widget _buildEditArea() {
    return Stack(
      children: [
        // 编辑区背景
        Container(
          color: Colors.grey[200],
          child: Center(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.1,
              maxScale: 5.0,
              onInteractionUpdate: (details) {
                // 更新当前缩放比例
                setState(() {
                  _currentZoom = details.scale;
                });
              },
              onInteractionEnd: (details) {
                // Scale is not available in ScaleEndDetails
                // We already update it in onInteractionUpdate
              },
              child: _buildPageContent(),
            ),
          ),
        ),

        // 缩放指示器
        Positioned(
          right: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${(_currentZoom * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // 构建顶部编辑工具栏
  Widget _buildEditToolbar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // 编辑操作组
          IconButton(
            icon: const Icon(Icons.pan_tool),
            tooltip: '页面平移',
            onPressed: () => _handleToolSelected('pan'),
          ),
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: '复制',
            onPressed: _selectedElementIds.isEmpty ? null : _handleCopy,
          ),
          IconButton(
            icon: const Icon(Icons.content_paste),
            tooltip: '粘贴',
            onPressed: _handlePaste,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '删除',
            onPressed: _selectedElementIds.isEmpty ? null : _handleDelete,
          ),

          const VerticalDivider(),

          // 组合操作
          IconButton(
            icon: const Icon(Icons.group_work),
            tooltip: '组合',
            onPressed: _selectedElementIds.length < 2 ? null : _handleGroup,
          ),
          IconButton(
            icon: const Icon(Icons.group_work_outlined),
            tooltip: '取消组合',
            onPressed: !_isGroupSelection() ? null : _handleUngroup,
          ),

          const VerticalDivider(),

          // 辅助功能组
          Row(
            children: [
              const Text('网格: ', style: TextStyle(fontSize: 14)),
              IconButton(
                icon: Icon(_gridVisible ? Icons.grid_on : Icons.grid_off),
                tooltip: '显示网格',
                onPressed: _toggleGrid,
              ),
              const SizedBox(width: 8),
              DropdownButton<double>(
                value: 20.0, // 假设网格默认大小是20
                items: const [
                  DropdownMenuItem(value: 10.0, child: Text('10px')),
                  DropdownMenuItem(value: 20.0, child: Text('20px')),
                  DropdownMenuItem(value: 50.0, child: Text('50px')),
                ],
                onChanged: _gridVisible ? _setGridSize : null,
              ),
            ],
          ),

          const SizedBox(width: 16),

          // 吸附开关
          Row(
            children: [
              const Text('吸附: ', style: TextStyle(fontSize: 14)),
              Switch(
                value: _snapEnabled,
                onChanged: _toggleSnap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建网格线
  Widget _buildGridOverlay() {
    return CustomPaint(
      painter: GridPainter(gridSize: 20.0),
      child: const SizedBox(
        width: 595,
        height: 842,
      ),
    );
  }

  // 构建组合内的子元素
  Widget _buildGroupChildElement(Map<String, dynamic> element) {
    final type = element['type'] as String? ?? '';
    final x = (element['relativeX'] as num?)?.toDouble() ?? 0.0;
    final y = (element['relativeY'] as num?)?.toDouble() ?? 0.0;
    final width = (element['width'] as num?)?.toDouble() ?? 50.0;
    final height = (element['height'] as num?)?.toDouble() ?? 50.0;
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;

    Widget content;

    switch (type) {
      case 'text':
        content = _buildTextElement(element);
        break;
      case 'image':
        content = _buildImageElement(element);
        break;
      case 'collection':
        content = _buildCollectionElement(element);
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
      child: Transform.rotate(
        angle: rotation * 3.1415926 / 180,
        child: SizedBox(
          width: width,
          height: height,
          child: content,
        ),
      ),
    );
  }

  // 构建组合元素
  Widget _buildGroupElement(Map<String, dynamic> element) {
    final children = element['children'] as List<dynamic>? ?? [];

    return Stack(
      children: [
        for (var child in children)
          _buildGroupChildElement(child as Map<String, dynamic>),
      ],
    );
  }

  // 构建图片元素
  Widget _buildImageElement(Map<String, dynamic> element) {
    final imageUrl = element['imageUrl'] as String? ?? '';
    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;

    return Opacity(
      opacity: opacity,
      child: imageUrl.isNotEmpty
          ? Image.network(imageUrl, fit: BoxFit.contain)
          : Container(
              color: Colors.grey.withOpacity(0.2),
              child: const Center(child: Icon(Icons.image)),
            ),
    );
  }

  // 构建页面内容
  Widget _buildPageContent() {
    if (_pages.isEmpty) {
      return const Center(
        child: Text('没有页面，请添加页面'),
      );
    }

    return Stack(
      children: [
        // A4纸页面
        Container(
          width: 595, // A4纸宽度 (72dpi)
          height: 842, // A4纸高度 (72dpi)
          color: Colors.white,
          child: _buildPageElements(),
        ),

        // 网格线 (如果启用)
        if (_gridVisible) _buildGridOverlay(),
      ],
    );
  }

  // 构建页面元素
  Widget _buildPageElement(Map<String, dynamic> element) {
    final type = element['type'] as String? ?? '';
    final id = element['id'] as String? ?? '';
    final x = (element['x'] as num?)?.toDouble() ?? 0.0;
    final y = (element['y'] as num?)?.toDouble() ?? 0.0;
    final width = (element['width'] as num?)?.toDouble() ?? 100.0;
    final height = (element['height'] as num?)?.toDouble() ?? 100.0;
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
    final isSelected = _selectedElementIds.contains(id);

    // 封装元素内容
    Widget content;

    switch (type) {
      case 'text':
        content = _buildTextElement(element);
        break;
      case 'image':
        content = _buildImageElement(element);
        break;
      case 'collection':
        content = _buildCollectionElement(element);
        break;
      case 'group':
        content = _buildGroupElement(element);
        break;
      default:
        content = Container(
          color: Colors.grey.withOpacity(0.2),
          child: const Center(child: Text('未知元素')),
        );
    }

    // 应用变换并添加选择控制
    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () => _handleElementTap(id),
        child: Transform.rotate(
          angle: rotation * 3.1415926 / 180,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Stack(
              children: [
                // 元素内容
                content,

                // 如果元素被选中，添加变换控制点
                if (isSelected) _buildTransformControls(width, height),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建页面元素
  Widget _buildPageElements() {
    final currentPage =
        _currentPageIndex < _pages.length ? _pages[_currentPageIndex] : null;
    if (currentPage == null) {
      return Container();
    }

    // 修复类型转换问题
    final elements = currentPage['elements'] as List<dynamic>? ?? [];
    final typedElements =
        elements.map((e) => e as Map<String, dynamic>).toList();

    return Stack(
      children: [
        // 绘制背景
        Container(
          width: 595,
          height: 842,
          color: _getPageBackgroundColor(currentPage),
        ),

        // 绘制各个元素
        for (var element in typedElements) _buildPageElement(element),
      ],
    );
  }

  // 构建页面缩略图
  Widget _buildPageThumbnail(int index) {
    final isSelected = index == _currentPageIndex;

    return GestureDetector(
      onTap: () => _selectPage(index),
      child: Container(
        width: 60,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 4)]
              : null,
        ),
        child: Stack(
          children: [
            // 页面预览
            Center(
              child: Text('第 ${index + 1} 页'),
            ),

            // 页码指示
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建底部页面缩略图栏
  Widget _buildPageThumbnailStrip() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          // 页面操作按钮
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: '添加页面',
                  onPressed: _handleAddPage,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: '删除页面',
                  onPressed: _currentPageIndex < _pages.length
                      ? _handleDeletePage
                      : null,
                ),
                const Spacer(),
                Text(
                  '第 ${_currentPageIndex + 1} 页 / 共 ${_pages.length} 页',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // 页面缩略图列表
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _pages.length + 1, // +1 用于添加按钮
              itemBuilder: (context, index) {
                if (index == _pages.length) {
                  // 最后一个是添加页面按钮
                  return _buildAddPageButton();
                } else {
                  return _buildPageThumbnail(index);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // 构建文本元素
  Widget _buildTextElement(Map<String, dynamic> element) {
    final text = element['text'] as String? ?? '';
    final fontSize = (element['fontSize'] as num?)?.toDouble() ?? 14.0;
    final fontColor = element['fontColor'] as String? ?? '#000000';
    final textAlign = _getTextAlign(element['textAlign'] as String? ?? 'left');

    return Container(
      padding: const EdgeInsets.all(4),
      color: Colors.transparent,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color:
              Color(int.parse(fontColor.substring(1), radix: 16) + 0xFF000000),
        ),
        textAlign: textAlign,
      ),
    );
  }

  // 构建变换控制点
  Widget _buildTransformControls(double width, double height) {
    const controlSize = 10.0;

    return Stack(
      children: [
        // 四个角控制点 (缩放)
        // 左上
        Positioned(
          left: -controlSize / 2,
          top: -controlSize / 2,
          child: _buildControlPoint(controlSize),
        ),
        // 右上
        Positioned(
          right: -controlSize / 2,
          top: -controlSize / 2,
          child: _buildControlPoint(controlSize),
        ),
        // 左下
        Positioned(
          left: -controlSize / 2,
          bottom: -controlSize / 2,
          child: _buildControlPoint(controlSize),
        ),
        // 右下
        Positioned(
          right: -controlSize / 2,
          bottom: -controlSize / 2,
          child: _buildControlPoint(controlSize),
        ),

        // 四个边中点控制点 (水平/垂直缩放)
        // 上中
        Positioned(
          left: (width - controlSize) / 2,
          top: -controlSize / 2,
          child: _buildControlPoint(controlSize),
        ),
        // 右中
        Positioned(
          right: -controlSize / 2,
          top: (height - controlSize) / 2,
          child: _buildControlPoint(controlSize),
        ),
        // 下中
        Positioned(
          left: (width - controlSize) / 2,
          bottom: -controlSize / 2,
          child: _buildControlPoint(controlSize),
        ),
        // 左中
        Positioned(
          left: -controlSize / 2,
          top: (height - controlSize) / 2,
          child: _buildControlPoint(controlSize),
        ),

        // 旋转控制点
        Positioned(
          left: (width - controlSize) / 2,
          top: -30,
          child: Container(
            width: controlSize,
            height: controlSize,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue, width: 2),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // 旋转控制线
        Positioned(
          left: width / 2,
          top: -30 + controlSize / 2,
          child: Container(
            width: 1,
            height: 30 - controlSize / 2,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  // 根据ID查找元素
  Map<String, dynamic>? _findElementById(String id) {
    if (_pages.isEmpty || _currentPageIndex >= _pages.length) {
      return null;
    }

    final elements =
        _pages[_currentPageIndex]['elements'] as List<dynamic>? ?? [];
    for (var element in elements) {
      final elementMap = element as Map<String, dynamic>;
      if (elementMap['id'] == id) {
        return elementMap;
      }

      // 检查组合内部
      if (elementMap['type'] == 'group') {
        final children = elementMap['children'] as List<dynamic>? ?? [];
        for (var child in children) {
          final childMap = child as Map<String, dynamic>;
          if (childMap['id'] == id) {
            return childMap;
          }
        }
      }
    }

    return null;
  }

  // 获取页面背景颜色
  Color _getPageBackgroundColor(Map<String, dynamic> page) {
    final backgroundColor = page['backgroundColor'] as String? ?? '#FFFFFF';
    return Color(
        int.parse(backgroundColor.substring(1), radix: 16) + 0xFF000000);
  }

  // 获取文本对齐方式
  TextAlign _getTextAlign(String align) {
    switch (align) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  // 添加集字元素
  void _handleAddCollectionElement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加集字'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: '请输入字符',
                hintText: '例如：永字八法',
              ),
              maxLength: 20,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              const characters = '永字八法'; // 应该从TextField获取
              Navigator.pop(context);
              setState(() {
                if (_pages.isEmpty || _currentPageIndex >= _pages.length) {
                  return;
                }

                final newElementId =
                    'collection_${DateTime.now().millisecondsSinceEpoch}';
                final defaultLayerId =
                    _layers.isNotEmpty ? _layers.first['id'] : 'default';

                final newElement = {
                  'id': newElementId,
                  'type': 'collection',
                  'x': 100.0,
                  'y': 100.0,
                  'width': 300.0,
                  'height': 300.0,
                  'rotation': 0.0,
                  'layerId': defaultLayerId,
                  'characters': characters,
                  'direction': 'horizontal',
                  'spacing': 10.0,
                };

                final elements =
                    _pages[_currentPageIndex]['elements'] as List<dynamic>? ??
                        [];
                elements.add(newElement);

                // 选中新添加的元素
                _selectedElementIds = [newElementId];
                _selectedElement = newElement;
                _hasUnsavedChanges = true;
              });
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 添加图片元素
  void _handleAddImageElement() {
    // 首先显示图片选择对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加图片'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('请选择图片来源：'),
            SizedBox(height: 16),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addImageElement(''); // 空URL表示使用占位图
            },
            child: const Text('使用占位图'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 这里应该打开文件选择器
              _addImageElement('https://placeholder.com/150');
            },
            child: const Text('从本地选择'),
          ),
        ],
      ),
    );
  }

  // 处理添加图层
  void _handleAddLayer() {
    setState(() {
      // 取消选择其他图层
      for (var layer in _layers) {
        layer['selected'] = false;
      }

      // 添加新图层
      final newLayerId = 'layer_${DateTime.now().millisecondsSinceEpoch}';
      _layers.add({
        'id': newLayerId,
        'name': '新图层',
        'visible': true,
        'locked': false,
        'selected': true,
      });

      _hasUnsavedChanges = true;
    });
  }

  // 处理添加页面
  void _handleAddPage() {
    setState(() {
      final newPageId = 'page_${DateTime.now().millisecondsSinceEpoch}';
      _pages.add({
        'id': newPageId,
        'backgroundColor': '#FFFFFF',
        'elements': [],
      });

      // 切换到新页面
      _currentPageIndex = _pages.length - 1;
      _hasUnsavedChanges = true;
    });
  }

  // 添加文本元素
  void _handleAddTextElement() {
    setState(() {
      if (_pages.isEmpty || _currentPageIndex >= _pages.length) {
        return;
      }

      final newElementId = 'text_${DateTime.now().millisecondsSinceEpoch}';
      final defaultLayerId =
          _layers.isNotEmpty ? _layers.first['id'] : 'default';

      final newElement = {
        'id': newElementId,
        'type': 'text',
        'x': 100.0,
        'y': 100.0,
        'width': 200.0,
        'height': 50.0,
        'rotation': 0.0,
        'layerId': defaultLayerId,
        'text': '双击编辑文本',
        'fontSize': 16.0,
        'fontColor': '#000000',
        'textAlign': 'left',
      };

      final elements =
          _pages[_currentPageIndex]['elements'] as List<dynamic>? ?? [];
      elements.add(newElement);

      // 选中新添加的元素
      _selectedElementIds = [newElementId];
      _selectedElement = newElement;
      _hasUnsavedChanges = true;
    });
  }

  // 处理复制
  void _handleCopy() {
    if (_selectedElementIds.isEmpty) return;

    // 实现复制逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制所选元素')),
    );
  }

  // 处理删除
  void _handleDelete() {
    if (_selectedElementIds.isEmpty) return;

    setState(() {
      // 实现删除逻辑
      if (_pages.isNotEmpty && _currentPageIndex < _pages.length) {
        final elements = _pages[_currentPageIndex]['elements']
                as List<Map<String, dynamic>>? ??
            [];
        _pages[_currentPageIndex]['elements'] = elements
            .where((element) => !_selectedElementIds.contains(element['id']))
            .toList();

        _selectedElementIds.clear();
        _selectedElement = null;
        _hasUnsavedChanges = true;
      }
    });
  }

  // 处理删除所有图层
  void _handleDeleteAllLayers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除所有图层吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _layers.clear();
                _hasUnsavedChanges = true;
              });
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 处理删除页面
  void _handleDeletePage() {
    if (_pages.isEmpty || _currentPageIndex >= _pages.length) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除第 ${_currentPageIndex + 1} 页吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _pages.removeAt(_currentPageIndex);
                // 调整当前页索引
                if (_pages.isEmpty) {
                  _currentPageIndex = 0;
                } else if (_currentPageIndex >= _pages.length) {
                  _currentPageIndex = _pages.length - 1;
                }
                _hasUnsavedChanges = true;
              });
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 处理元素属性变更
  void _handleElementChanged(PracticeElement updatedElement) {
    setState(() {
      final elementId = updatedElement.id;
      final updatedMap = updatedElement.toMap();

      // 更新元素属性
      _updateElementProperties(elementId, updatedMap);

      // 更新选中的元素
      _selectedElement = updatedElement.toMap();
      _hasUnsavedChanges = true;
    });
  }

  // 处理元素选择
  void _handleElementTap(String id) {
    setState(() {
      if (_selectedElementIds.contains(id)) {
        // 如果已经选中，则取消选中
        _selectedElementIds.remove(id);
      } else {
        // 否则选中这个元素
        // 如果按住了Ctrl键，则是多选
        const isMultiSelect = false; // 这里需要检查Ctrl键，暂时写死为false
        if (!isMultiSelect) {
          _selectedElementIds.clear();
        }
        _selectedElementIds.add(id);
      }

      // 更新属性面板的数据
      _updateSelectedElementProperties();
    });
  }

  // 处理导出
  void _handleExport() {
    // 实现导出逻辑
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出文档'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择导出格式：'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('PDF'),
                  selected: true,
                  onSelected: (_) {},
                ),
                ChoiceChip(
                  label: const Text('图片'),
                  selected: false,
                  onSelected: (_) {},
                ),
                ChoiceChip(
                  label: const Text('Word'),
                  selected: false,
                  onSelected: (_) {},
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('文档已导出为PDF')),
              );
            },
            child: const Text('导出'),
          ),
        ],
      ),
    );
  }

  // 处理组合
  void _handleGroup() {
    if (_selectedElementIds.length < 2) return;

    setState(() {
      // 实现组合逻辑
      if (_pages.isNotEmpty && _currentPageIndex < _pages.length) {
        final elements = _pages[_currentPageIndex]['elements']
                as List<Map<String, dynamic>>? ??
            [];

        // 找出所有要组合的元素
        final selectedElements = elements
            .where((element) => _selectedElementIds.contains(element['id']))
            .toList();

        if (selectedElements.isEmpty) return;

        // 创建一个新的组合
        final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
        final group = {
          'id': groupId,
          'type': 'group',
          'x': selectedElements
              .map((e) => (e['x'] as num?)?.toDouble() ?? 0.0)
              .reduce((a, b) => a < b ? a : b),
          'y': selectedElements
              .map((e) => (e['y'] as num?)?.toDouble() ?? 0.0)
              .reduce((a, b) => a < b ? a : b),
          'width': selectedElements
                  .map((e) =>
                      ((e['x'] as num?)?.toDouble() ?? 0.0) +
                      ((e['width'] as num?)?.toDouble() ?? 0.0))
                  .reduce((a, b) => a > b ? a : b) -
              selectedElements
                  .map((e) => (e['x'] as num?)?.toDouble() ?? 0.0)
                  .reduce((a, b) => a < b ? a : b),
          'height': selectedElements
                  .map((e) =>
                      ((e['y'] as num?)?.toDouble() ?? 0.0) +
                      ((e['height'] as num?)?.toDouble() ?? 0.0))
                  .reduce((a, b) => a > b ? a : b) -
              selectedElements
                  .map((e) => (e['y'] as num?)?.toDouble() ?? 0.0)
                  .reduce((a, b) => a < b ? a : b),
          'rotation': 0.0,
          'children': selectedElements.map((element) {
            // 转换为相对坐标
            final baseX = selectedElements
                .map((e) => (e['x'] as num?)?.toDouble() ?? 0.0)
                .reduce((a, b) => a < b ? a : b);
            final baseY = selectedElements
                .map((e) => (e['y'] as num?)?.toDouble() ?? 0.0)
                .reduce((a, b) => a < b ? a : b);

            return {
              ...element,
              'relativeX': (element['x'] as num?)?.toDouble() ?? 0.0 - baseX,
              'relativeY': (element['y'] as num?)?.toDouble() ?? 0.0 - baseY,
            };
          }).toList(),
        };

        // 移除原始元素，添加组合
        _pages[_currentPageIndex]['elements'] = elements
            .where((element) => !_selectedElementIds.contains(element['id']))
            .toList();

        (_pages[_currentPageIndex]['elements'] as List<dynamic>).add(group);

        // 更新选择状态
        _selectedElementIds = [groupId];
        _updateSelectedElementProperties();
        _hasUnsavedChanges = true;
      }
    });
  }

  // 处理图层删除
  void _handleLayerDeleted(int index) {
    setState(() {
      _layers.removeAt(index);
      _hasUnsavedChanges = true;
    });
  }

  // 处理图层锁定状态变更
  void _handleLayerLockChanged(int index, bool locked) {
    setState(() {
      _layers[index]['locked'] = locked;
      _hasUnsavedChanges = true;
    });
  }

  // 处理图层重命名
  void _handleLayerRenamed(int index, String newName) {
    setState(() {
      _layers[index]['name'] = newName;
      _hasUnsavedChanges = true;
    });
  }

  // 处理图层重新排序
  void _handleLayerReordered(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _layers.removeAt(oldIndex);
      _layers.insert(newIndex, item);
      _hasUnsavedChanges = true;
    });
  }

  // 处理图层选择
  void _handleLayerSelected(int index) {
    setState(() {
      for (var i = 0; i < _layers.length; i++) {
        _layers[i]['selected'] = i == index;
      }
    });
  }

  // 处理图层可见性变更
  void _handleLayerVisibilityChanged(int index, bool visible) {
    setState(() {
      _layers[index]['visible'] = visible;
      _hasUnsavedChanges = true;
    });
  }

  // 处理页面属性变更
  void _handlePageChanged(PracticePage updatedPage) {
    setState(() {
      if (_pages.isNotEmpty && _currentPageIndex < _pages.length) {
        // 提取页面属性并更新
        final updatedMap = {
          'id': updatedPage.id,
          'name': updatedPage.name,
          'index': updatedPage.index,
          'width': updatedPage.width,
          'height': updatedPage.height,
          'backgroundType': updatedPage.backgroundType,
          'backgroundImage': updatedPage.backgroundImage,
          'backgroundColor': updatedPage.backgroundColor,
          'backgroundTexture': updatedPage.backgroundTexture,
          'backgroundOpacity': updatedPage.backgroundOpacity,
        };

        _pages[_currentPageIndex] = {
          ..._pages[_currentPageIndex],
          ...updatedMap,
        };

        _hasUnsavedChanges = true;
      }
    });
  }

  // 处理粘贴
  void _handlePaste() {
    // 实现粘贴逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已粘贴元素')),
    );
  }

  // 处理打印
  void _handlePrint() {
    // 实现打印逻辑
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('打印预览'),
        content: Container(
          width: 400,
          height: 500,
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/print_preview.png', width: 300),
                const SizedBox(height: 16),
                const Text('打印预览'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('文档已发送到打印机')),
              );
            },
            child: const Text('打印'),
          ),
        ],
      ),
    );
  }

  // 处理属性变更
  void _handlePropertyChanged(Map<String, dynamic> updatedElement) {
    setState(() {
      _selectedElement = updatedElement;
      _hasUnsavedChanges = true;

      // 更新元素属性
      if (_selectedElementIds.length == 1) {
        final id = _selectedElementIds.first;
        _updateElementProperties(id, updatedElement);
      }
    });
  }

  // 处理重做
  void _handleRedo() {
    if (_redoStack.isEmpty) return;

    setState(() {
      // 实现重做逻辑
      final nextOperation = _redoStack.removeLast();
      _undoStack.add(nextOperation);
    });
  }

  // 处理保存
  Future<void> _handleSave() async {
    // 实现保存逻辑
    setState(() => _hasUnsavedChanges = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('字帖已保存')),
    );
  }

  // 处理指定位置保存
  void _handleSaveAs() {
    // 实现另存为逻辑
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存到'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: '文件名',
                hintText: '输入文件名',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: '保存路径',
                hintText: '选择保存路径',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _hasUnsavedChanges = false);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('字帖已保存到指定位置')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 处理显示所有图层
  void _handleShowAllLayers() {
    setState(() {
      for (var layer in _layers) {
        layer['visible'] = true;
      }
      _hasUnsavedChanges = true;
    });
  }

  // 处理工具选择
  void _handleToolSelected(String tool) {
    setState(() {
      // 实现工具选择逻辑
      _hasUnsavedChanges = true;
    });
  }

  // 处理撤销
  void _handleUndo() {
    if (_undoStack.isEmpty) return;

    setState(() {
      // 实现撤销逻辑
      final lastOperation = _undoStack.removeLast();
      _redoStack.add(lastOperation);
    });
  }

  // 处理取消组合
  void _handleUngroup() {
    if (_selectedElementIds.length != 1) return;

    final groupId = _selectedElementIds.first;
    final group = _findElementById(groupId);

    if (group == null || group['type'] != 'group') return;

    setState(() {
      // 实现取消组合逻辑
      if (_pages.isNotEmpty && _currentPageIndex < _pages.length) {
        final elements = _pages[_currentPageIndex]['elements']
                as List<Map<String, dynamic>>? ??
            [];

        // 找出要取消组合的组
        final groupIndex = elements.indexWhere((e) => e['id'] == groupId);
        if (groupIndex < 0) return;

        final group = elements[groupIndex];
        final children = group['children'] as List<dynamic>? ?? [];

        // 计算基准位置
        final baseX = (group['x'] as num?)?.toDouble() ?? 0.0;
        final baseY = (group['y'] as num?)?.toDouble() ?? 0.0;

        // 将子元素恢复为绝对坐标并添加到页面元素
        final ungroupedElements = children.map((child) {
          final element = child as Map<String, dynamic>;
          final relativeX = (element['relativeX'] as num?)?.toDouble() ?? 0.0;
          final relativeY = (element['relativeY'] as num?)?.toDouble() ?? 0.0;

          return {
            ...element,
            'x': baseX + relativeX,
            'y': baseY + relativeY,
          };
        }).toList();

        // 移除组，添加子元素
        elements.removeAt(groupIndex);
        elements.addAll(ungroupedElements.cast<Map<String, dynamic>>());

        // 更新选择状态
        _selectedElementIds =
            ungroupedElements.map((e) => (e)['id'] as String).toList();
        _updateSelectedElementProperties();
        _hasUnsavedChanges = true;
      }
    });
  }

  // 初始化数据
  void _initData() {
    // 初始化图层
    _layers = [
      {
        'id': '1',
        'name': '背景层',
        'visible': true,
        'locked': false,
        'selected': false,
      },
      {
        'id': '2',
        'name': '内容层',
        'visible': true,
        'locked': false,
        'selected': true,
      },
    ];

    // 初始化页面
    _pages = [
      {
        'id': '1',
        'backgroundColor': '#FFFFFF',
        'elements': [],
      }
    ];
  }

  // 检查是否为组合选择
  bool _isGroupSelection() {
    if (_selectedElementIds.length != 1) return false;

    final element = _findElementById(_selectedElementIds.first);
    return element != null && element['type'] == 'group';
  }

  // 将Map转换为PracticeElement
  PracticeElement? _mapToPracticeElement(Map<String, dynamic> map) {
    final type = map['type'] as String? ?? '';
    try {
      return PracticeElement.fromMap(map);
    } catch (e) {
      debugPrint('Error converting element: $e');
      return null;
    }
  }

  // 将Map转换为PracticePage
  PracticePage _mapToPracticePage(Map<String, dynamic> map) {
    try {
      // 创建临时的基本PracticePage对象
      return PracticePage(
        id: map['id'] as String? ?? 'default',
        name: map['name'] as String? ?? '',
        index: (map['index'] as int?) ?? 0,
        width: (map['width'] as num?)?.toDouble() ?? 210.0,
        height: (map['height'] as num?)?.toDouble() ?? 297.0,
        backgroundType: map['backgroundType'] as String? ?? 'color',
        backgroundImage: map['backgroundImage'] as String?,
        backgroundColor: map['backgroundColor'] as String? ?? '#FFFFFF',
        backgroundTexture: map['backgroundTexture'] as String?,
        backgroundOpacity:
            (map['backgroundOpacity'] as num?)?.toDouble() ?? 1.0,
      );
    } catch (e) {
      debugPrint('Error converting page: $e');
      return PracticePage.defaultPage();
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('有未保存的更改，确定要退出吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // 选择页面
  void _selectPage(int index) {
    if (index < 0 || index >= _pages.length) return;

    setState(() {
      _currentPageIndex = index;

      // 清除选择
      _selectedElementIds.clear();
      _selectedElement = null;
    });
  }

  // 设置网格大小
  void _setGridSize(double? size) {
    if (size == null) return;

    setState(() {
      // 设置网格大小
    });
  }

  // 切换网格显示
  void _toggleGrid() {
    setState(() {
      _gridVisible = !_gridVisible;
    });
  }

  // 切换页面缩略图可见性
  void _togglePageThumbnails() {
    setState(() {
      _isPageThumbnailsVisible = !_isPageThumbnailsVisible;
    });
  }

  // 切换吸附功能
  void _toggleSnap(bool? enabled) {
    if (enabled == null) return;

    setState(() {
      _snapEnabled = enabled;
    });
  }

  // 更新元素属性
  void _updateElementProperties(String id, Map<String, dynamic> properties) {
    if (_pages.isEmpty || _currentPageIndex >= _pages.length) {
      return;
    }

    final elements =
        _pages[_currentPageIndex]['elements'] as List<Map<String, dynamic>>? ??
            [];
    for (var i = 0; i < elements.length; i++) {
      if (elements[i]['id'] == id) {
        // 更新属性
        elements[i] = {...elements[i], ...properties};
        break;
      }

      // 检查组合内部
      if (elements[i]['type'] == 'group') {
        final children = elements[i]['children'] as List<dynamic>? ?? [];
        for (var j = 0; j < children.length; j++) {
          if ((children[j] as Map<String, dynamic>)['id'] == id) {
            children[j] = {
              ...children[j] as Map<String, dynamic>,
              ...properties
            };
            break;
          }
        }
      }
    }
  }

  // 更新选中元素的属性
  void _updateSelectedElementProperties() {
    if (_selectedElementIds.isEmpty) {
      _selectedElement = null;
      return;
    }

    if (_selectedElementIds.length == 1) {
      // 单选
      final id = _selectedElementIds.first;
      final element = _findElementById(id);
      if (element != null) {
        final practiceElement = _mapToPracticeElement(element);
        _selectedElement = practiceElement?.toMap() ?? element;
      }
    } else {
      // 多选状态处理
      _selectedElement = null;
    }
  }
}
