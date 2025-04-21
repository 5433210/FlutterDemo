import 'package:flutter/material.dart';

import '../practice_edit_controller.dart';
import 'practice_property_panel_base.dart';

/// 图层属性面板
class LayerPropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic> layer;
  final Function(Map<String, dynamic>) onLayerPropertiesChanged;

  const LayerPropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.layer,
    required this.onLayerPropertiesChanged,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    return _LayerPropertyPanelContent(
      controller: controller,
      layer: layer,
      onLayerPropertiesChanged: onLayerPropertiesChanged,
    );
  }
}

/// 图层属性面板内容 - 使用StatefulWidget以管理输入状态
class _LayerPropertyPanelContent extends StatefulWidget {
  final PracticeEditController controller;
  final Map<String, dynamic> layer;
  final Function(Map<String, dynamic>) onLayerPropertiesChanged;

  const _LayerPropertyPanelContent({
    Key? key,
    required this.controller,
    required this.layer,
    required this.onLayerPropertiesChanged,
  }) : super(key: key);

  @override
  State<_LayerPropertyPanelContent> createState() =>
      _LayerPropertyPanelContentState();
}

class _LayerPropertyPanelContentState
    extends State<_LayerPropertyPanelContent> {
  late TextEditingController _nameController;
  late TextEditingController _elementNameController;
  String? _editingElementId;
  bool _isEditingName = false;
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _elementNameFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final name = widget.layer['name'] as String? ?? '图层1';
    final isVisible = widget.layer['isVisible'] as bool? ?? true;
    final isLocked = widget.layer['isLocked'] as bool? ?? false;
    final opacity = (widget.layer['opacity'] as num?)?.toDouble() ?? 1.0;

    // 获取图层中的元素数量
    final layerId = widget.layer['id'] as String;
    final allElements = widget.controller.state.currentPageElements;
    final elementsInLayer =
        allElements.where((e) => e['layerId'] == layerId).toList();
    final elementCount = elementsInLayer.length;

    // 获取图层索引（用于确定位置）
    final layerIndex =
        widget.controller.state.layers.indexWhere((l) => l['id'] == layerId);
    final isTopLayer = layerIndex == widget.controller.state.layers.length - 1;
    final isBottomLayer = layerIndex == 0;
    final layerPosition = layerIndex + 1; // 从1开始计数，更自然
    final totalLayers = widget.controller.state.layers.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 面板标题
        Row(
          children: [
            const Icon(Icons.layers, size: 24),
            const SizedBox(width: 8),
            Text(
              '图层属性',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const Divider(height: 24),

        // 基本信息区
        _buildInfoCard(
          context,
          title: '基本信息',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图层名称
              Row(
                children: [
                  const Text('名称:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isEditingName
                        ? TextField(
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 8),
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _applyNameChange(),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                tooltip: '编辑名称',
                                onPressed: () {
                                  setState(() {
                                    _isEditingName = true;
                                    _nameController.text = name;
                                  });
                                  // 确保下一帧聚焦
                                  Future.microtask(
                                      () => _nameFocusNode.requestFocus());
                                },
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 图层位置
              Row(
                children: [
                  const Text('位置:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text('第 $layerPosition 层 (共 $totalLayers 层)'),
                ],
              ),

              // 元素数量
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('元素:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text('$elementCount 个元素'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 状态与显示
        _buildInfoCard(
          context,
          title: '状态与显示',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图层状态控制区
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 可见性控制
                  _buildControlButton(
                    icon: isVisible ? Icons.visibility : Icons.visibility_off,
                    label: isVisible ? '可见' : '隐藏',
                    isActive: isVisible,
                    tooltip: isVisible ? '隐藏图层' : '显示图层',
                    onPressed: () {
                      widget
                          .onLayerPropertiesChanged({'isVisible': !isVisible});
                    },
                  ),

                  // 锁定控制
                  _buildControlButton(
                    icon: isLocked ? Icons.lock : Icons.lock_open,
                    label: isLocked ? '已锁定' : '未锁定',
                    isActive: !isLocked, // 反向激活 - 未锁定是活跃状态
                    tooltip: isLocked ? '解锁图层' : '锁定图层',
                    onPressed: () {
                      widget.onLayerPropertiesChanged({'isLocked': !isLocked});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 透明度
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('不透明度:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${(opacity * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.opacity_outlined, size: 16),
                      Expanded(
                        child: Slider(
                          value: opacity,
                          min: 0.0,
                          max: 1.0,
                          divisions: 100,
                          label: '${(opacity * 100).toStringAsFixed(0)}%',
                          onChanged: (value) {
                            widget.onLayerPropertiesChanged({'opacity': value});
                          },
                        ),
                      ),
                      const Icon(Icons.opacity, size: 16),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 图层操作
        _buildInfoCard(
          context,
          title: '图层操作',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图层排序操作
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.vertical_align_top,
                    label: '置顶',
                    tooltip: '将图层移到最上层',
                    onPressed: isTopLayer ? null : () => _moveLayer('top'),
                  ),
                  _buildActionButton(
                    icon: Icons.arrow_upward,
                    label: '上移',
                    tooltip: '将图层上移一层',
                    onPressed: isTopLayer ? null : () => _moveLayer('up'),
                  ),
                  _buildActionButton(
                    icon: Icons.arrow_downward,
                    label: '下移',
                    tooltip: '将图层下移一层',
                    onPressed: isBottomLayer ? null : () => _moveLayer('down'),
                  ),
                  _buildActionButton(
                    icon: Icons.vertical_align_bottom,
                    label: '置底',
                    tooltip: '将图层移到最下层',
                    onPressed:
                        isBottomLayer ? null : () => _moveLayer('bottom'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 图层管理操作
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.copy,
                    label: '复制',
                    tooltip: '创建图层副本',
                    onPressed: _duplicateLayer,
                  ),
                  _buildActionButton(
                    icon: Icons.select_all,
                    label: '选择元素',
                    tooltip: '选择图层中的所有元素',
                    onPressed: elementCount > 0 ? _selectAllElements : null,
                  ),
                  _buildActionButton(
                    icon: Icons.delete,
                    label: '删除',
                    tooltip: '删除此图层',
                    isDanger: true,
                    onPressed: () => _showDeleteLayerDialog(context),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 图层元素列表
        if (elementCount > 0) ...[
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            title: '图层元素',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部操作区
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('共 $elementCount 个元素'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, size: 18),
                          tooltip: '显示/隐藏所有元素',
                          onPressed: () =>
                              _toggleAllElementsVisibility(elementsInLayer),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.lock_outline, size: 18),
                          tooltip: '锁定/解锁所有元素',
                          onPressed: () =>
                              _toggleAllElementsLock(elementsInLayer),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                // 元素列表
                _buildLayerElementsList(elementsInLayer),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void didUpdateWidget(_LayerPropertyPanelContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当选中的图层发生变化时，更新名称控制器
    if (oldWidget.layer['id'] != widget.layer['id']) {
      final name = widget.layer['name'] as String? ?? '图层1';
      _nameController.text = name;
      _isEditingName = false;
    }
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_onFocusChange);
    _nameController.dispose();
    _nameFocusNode.dispose();
    _elementNameController.dispose();
    _elementNameFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final name = widget.layer['name'] as String? ?? '图层1';
    _nameController = TextEditingController(text: name);
    _elementNameController = TextEditingController();
    _nameFocusNode.addListener(_onFocusChange);
  }

  void _applyElementNameChange() {
    final newName = _elementNameController.text.trim();
    if (newName.isNotEmpty && _editingElementId != null) {
      widget.controller
          .updateElementProperty(_editingElementId!, 'name', newName);
      setState(() {
        _editingElementId = null;
      });
    }
  }

  void _applyNameChange() {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      widget.onLayerPropertiesChanged({'name': newName});
      setState(() {
        _isEditingName = false;
      });
    }
  }

  // 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String tooltip,
    bool isDanger = false,
    VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isDanger
                  ? Colors.red.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDanger
                    ? Colors.red.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isDanger ? Colors.red : Colors.black87,
                  size: 18,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isDanger ? Colors.red : Colors.black87,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建控制按钮
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.blue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? Colors.blue.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.blue : Colors.grey,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.blue : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建信息卡片
  Widget _buildInfoCard(BuildContext context,
      {required String title, required Widget child}) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  // 构建图层元素列表
  Widget _buildLayerElementsList(List<Map<String, dynamic>> elements) {
    // 用于存储当前正在编辑的元素ID
    final editingElementId = _editingElementId;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: elements.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final element = elements[index];
        final type = element['type'] as String? ?? 'unknown';
        final id = element['id'] as String;
        final isSelected =
            widget.controller.state.selectedElementIds.contains(id);
        final isLocked = element['locked'] == true;
        final isHidden = element['hidden'] == true;

        // 获取元素名称，如果没有则使用类型+序号
        String typeName;
        switch (type) {
          case 'text':
            typeName = '文本';
            break;
          case 'image':
            typeName = '图片';
            break;
          case 'collection':
            typeName = '集字';
            break;
          case 'group':
            typeName = '组';
            break;
          default:
            typeName = '未知';
        }

        final String defaultName = '$typeName ${index + 1}';
        final String elementName = element['name'] as String? ?? defaultName;
        final bool isEditing = editingElementId == id;

        // 根据元素类型显示不同的图标
        IconData iconData;
        switch (type) {
          case 'text':
            iconData = Icons.text_fields;
            break;
          case 'image':
            iconData = Icons.image;
            break;
          case 'collection':
            iconData = Icons.collections;
            break;
          case 'group':
            iconData = Icons.group_work;
            break;
          default:
            iconData = Icons.question_mark;
        }

        return Container(
          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
          child: ListTile(
            leading: Icon(iconData),
            title: isEditing
                ? TextField(
                    controller: _elementNameController,
                    focusNode: _elementNameFocusNode,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _applyElementNameChange(),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          elementName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        tooltip: '重命名',
                        onPressed: () =>
                            _startEditingElementName(id, elementName),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      ),
                    ],
                  ),
            subtitle: Text(type,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            selected: isSelected,
            dense: true,
            onTap: () => _selectElement(id),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 可见性切换
                IconButton(
                  icon: Icon(
                    isHidden ? Icons.visibility_off : Icons.visibility,
                    color: isHidden ? Colors.grey : Colors.blue,
                    size: 18,
                  ),
                  tooltip: isHidden ? '显示元素' : '隐藏元素',
                  onPressed: () => _toggleElementVisibility(id, !isHidden),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),

                // 锁定切换
                IconButton(
                  icon: Icon(
                    isLocked ? Icons.lock : Icons.lock_open,
                    color: isLocked ? Colors.orange : Colors.grey,
                    size: 18,
                  ),
                  tooltip: isLocked ? '解锁元素' : '锁定元素',
                  onPressed: () => _toggleElementLock(id, !isLocked),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),

                // 删除元素
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                    size: 18,
                  ),
                  tooltip: '删除元素',
                  onPressed: () => _deleteElement(id),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 删除元素
  void _deleteElement(String elementId) {
    widget.controller.deleteElement(elementId);
  }

  // 复制图层
  void _duplicateLayer() {
    final layerId = widget.layer['id'] as String;
    widget.controller.duplicateLayer(layerId);
  }

  // 移动图层
  void _moveLayer(String direction) {
    final layerId = widget.layer['id'] as String;
    final layers = widget.controller.state.layers;
    final index = layers.indexWhere((l) => l['id'] == layerId);

    if (index < 0) return;

    switch (direction) {
      case 'up':
        if (index < layers.length - 1) {
          widget.controller.reorderLayer(index, index + 1);
        }
        break;
      case 'down':
        if (index > 0) {
          widget.controller.reorderLayer(index, index - 1);
        }
        break;
      case 'top':
        if (index < layers.length - 1) {
          widget.controller.reorderLayer(index, layers.length - 1);
        }
        break;
      case 'bottom':
        if (index > 0) {
          widget.controller.reorderLayer(index, 0);
        }
        break;
    }
  }

  void _onFocusChange() {
    if (!_nameFocusNode.hasFocus && _isEditingName) {
      _applyNameChange();
    }
  }

  // 选择图层中的所有元素
  void _selectAllElements() {
    final layerId = widget.layer['id'] as String;
    final allElements = widget.controller.state.currentPageElements;
    final elementIds = allElements
        .where((element) => element['layerId'] == layerId)
        .map((element) => element['id'] as String)
        .toList();

    if (elementIds.isNotEmpty) {
      widget.controller.selectElements(elementIds);
    }
  }

  // 选择单个元素
  void _selectElement(String elementId) {
    widget.controller.selectElement(elementId);
  }

  // 显示删除图层确认对话框
  void _showDeleteLayerDialog(BuildContext context) {
    final layerId = widget.layer['id'] as String;
    final layerName = widget.layer['name'] as String? ?? '图层';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除图层'),
        content: Text('确定要删除图层 "$layerName" 吗？图层中的所有元素都将被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              widget.controller.deleteLayer(layerId);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _startEditingElementName(String elementId, String currentName) {
    setState(() {
      _editingElementId = elementId;
      _elementNameController.text = currentName;
    });
    Future.microtask(() => _elementNameFocusNode.requestFocus());
  }

  // 切换所有元素的锁定状态
  void _toggleAllElementsLock(List<Map<String, dynamic>> elements) {
    // 检查当前是否所有元素都是锁定的
    final allLocked = elements.every((element) => element['locked'] == true);

    // 对所有元素执行相反的操作
    for (final element in elements) {
      final elementId = element['id'] as String;
      widget.controller.updateElementProperty(elementId, 'locked', !allLocked);
    }
  }

  // 切换所有元素的可见性
  void _toggleAllElementsVisibility(List<Map<String, dynamic>> elements) {
    // 检查当前是否所有元素都是可见的
    final allVisible = elements.every((element) => element['hidden'] != true);

    // 对所有元素执行相反的操作
    for (final element in elements) {
      final elementId = element['id'] as String;
      widget.controller.updateElementProperty(elementId, 'hidden', allVisible);
    }
  }

  // 切换元素锁定状态
  void _toggleElementLock(String elementId, bool lock) {
    widget.controller.updateElementProperty(elementId, 'locked', lock);
  }

  // 切换元素可见性
  void _toggleElementVisibility(String elementId, bool hidden) {
    widget.controller.updateElementProperty(elementId, 'hidden', hidden);
  }
}
