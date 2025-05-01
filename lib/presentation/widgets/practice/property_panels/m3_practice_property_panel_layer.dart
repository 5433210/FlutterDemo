import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../practice_edit_controller.dart';
import 'm3_practice_property_panel_base.dart';

/// Material 3 图层属性面板
class M3LayerPropertyPanel extends M3PracticePropertyPanel {
  final Map<String, dynamic> layer;
  final Function(Map<String, dynamic>) onLayerPropertiesChanged;

  const M3LayerPropertyPanel({
    super.key,
    required PracticeEditController controller,
    required this.layer,
    required this.onLayerPropertiesChanged,
  }) : super(controller: controller);

  @override
  Widget build(BuildContext context) {
    return _M3LayerPropertyPanelContent(
      controller: controller,
      layer: layer,
      onLayerPropertiesChanged: onLayerPropertiesChanged,
    );
  }
}

class _M3LayerPropertyPanelContent extends StatefulWidget {
  final PracticeEditController controller;
  final Map<String, dynamic> layer;
  final Function(Map<String, dynamic>) onLayerPropertiesChanged;

  const _M3LayerPropertyPanelContent({
    required this.controller,
    required this.layer,
    required this.onLayerPropertiesChanged,
  });

  @override
  State<_M3LayerPropertyPanelContent> createState() =>
      _M3LayerPropertyPanelContentState();
}

class _M3LayerPropertyPanelContentState
    extends State<_M3LayerPropertyPanelContent> {
  // 图层名称编辑控制器
  late TextEditingController _nameController;
  late FocusNode _nameFocusNode;
  bool _isEditingName = false;

  // 元素名称编辑控制器
  final TextEditingController _elementNameController = TextEditingController();
  final FocusNode _elementNameFocusNode = FocusNode();
  String? _editingElementId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final name = widget.layer['name'] as String? ?? l10n.layer1;
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
            Icon(
              Icons.layers,
              size: 24,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.practiceEditLayerProperties,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const Divider(height: 24),

        // 图层名称
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.basicInfo,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _isEditingName
                          ? TextField(
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              decoration: InputDecoration(
                                labelText: l10n.name,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (_) => _applyNameChange(),
                            )
                          : ListTile(
                              title: Text(
                                l10n.name,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              subtitle: Text(
                                name,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: l10n.rename,
                                onPressed: _startEditingName,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(
                    l10n.position,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  subtitle: Text(
                    '$layerPosition / $totalLayers',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                ListTile(
                  title: Text(
                    l10n.elements,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  subtitle: Text(
                    '$elementCount ${l10n.elements}',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 状态与显示
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.stateAndDisplay,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                // 可见性控制
                SwitchListTile(
                  title: Text(
                    l10n.visible,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  value: isVisible,
                  activeColor: colorScheme.primary,
                  onChanged: (value) {
                    widget.onLayerPropertiesChanged({'isVisible': value});
                  },
                  secondary: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                    color: isVisible
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),

                // 锁定控制
                SwitchListTile(
                  title: Text(
                    l10n.locked,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  value: isLocked,
                  activeColor: colorScheme.primary,
                  onChanged: (value) {
                    widget.onLayerPropertiesChanged({'isLocked': value});
                  },
                  secondary: Icon(
                    isLocked ? Icons.lock : Icons.lock_open,
                    color: isLocked
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),

                // 不透明度控制
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.opacity,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: opacity,
                              min: 0.0,
                              max: 1.0,
                              divisions: 100,
                              label: '${(opacity * 100).round()}%',
                              activeColor: colorScheme.primary,
                              inactiveColor:
                                  colorScheme.surfaceContainerHighest,
                              onChanged: (value) {
                                widget.onLayerPropertiesChanged(
                                    {'opacity': value});
                              },
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${(opacity * 100).round()}%',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 图层操作
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.layerOperations,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                // 图层排序操作
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      context: context,
                      icon: Icons.vertical_align_top,
                      label: l10n.bringToFront,
                      tooltip: l10n.bringLayerToFront,
                      onPressed: isTopLayer ? null : () => _moveLayer('top'),
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    _buildActionButton(
                      context: context,
                      icon: Icons.arrow_upward,
                      label: l10n.moveUp,
                      tooltip: l10n.moveLayerUp,
                      onPressed: isTopLayer ? null : () => _moveLayer('up'),
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    _buildActionButton(
                      context: context,
                      icon: Icons.arrow_downward,
                      label: l10n.moveDown,
                      tooltip: l10n.moveLayerDown,
                      onPressed:
                          isBottomLayer ? null : () => _moveLayer('down'),
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    _buildActionButton(
                      context: context,
                      icon: Icons.vertical_align_bottom,
                      label: l10n.sendToBack,
                      tooltip: l10n.sendLayerToBack,
                      onPressed:
                          isBottomLayer ? null : () => _moveLayer('bottom'),
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 删除图层按钮
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDeleteLayer(context),
                    icon: Icon(
                      Icons.delete,
                      color: colorScheme.error,
                      size: 18,
                    ),
                    label: Text(
                      l10n.practiceEditDeleteLayer,
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer,
                      foregroundColor: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 图层元素列表
        if (elementCount > 0) ...[
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.layerElements,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 头部操作区
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${l10n.total}: $elementCount ${l10n.elements}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: l10n.showHideAllElements,
                            onPressed: () =>
                                _toggleAllElementsVisibility(elementsInLayer),
                            iconSize: 20,
                          ),
                          IconButton(
                            icon: const Icon(Icons.lock_outline),
                            tooltip: l10n.lockUnlockAllElements,
                            onPressed: () =>
                                _toggleAllElementsLock(elementsInLayer),
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),

                  // 元素列表
                  _buildLayerElementsList(elementsInLayer, context),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void didUpdateWidget(_M3LayerPropertyPanelContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当选中的图层发生变化时，更新名称控制器
    if (oldWidget.layer['id'] != widget.layer['id']) {
      final name = widget.layer['name'] as String? ?? 'Layer 1';
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
    // 初始化控制器
    final name = widget.layer['name'] as String? ?? 'Layer 1';
    _nameController = TextEditingController(text: name);
    _nameFocusNode = FocusNode();
    _nameFocusNode.addListener(_onFocusChange);
  }

  // 应用元素名称更改
  void _applyElementNameChange() {
    if (_editingElementId != null) {
      final newName = _elementNameController.text.trim();
      if (newName.isNotEmpty) {
        // 更新元素名称
        widget.controller
            .updateElementProperties(_editingElementId!, {'name': newName});
      }
      setState(() {
        _editingElementId = null;
      });
    }
  }

  // 应用图层名称更改
  void _applyNameChange() {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      widget.onLayerPropertiesChanged({'name': newName});
    } else {
      // 如果名称为空，恢复原来的名称
      _nameController.text = widget.layer['name'] as String? ?? 'Layer 1';
    }
    setState(() {
      _isEditingName = false;
    });
  }

  // 构建操作按钮
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback? onPressed,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final isDisabled = onPressed == null;

    return Tooltip(
      message: tooltip,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          foregroundColor: isDisabled
              ? colorScheme.onSurfaceVariant.withOpacity(0.5)
              : colorScheme.primary,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isDisabled
                  ? colorScheme.onSurfaceVariant.withOpacity(0.5)
                  : colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: isDisabled
                    ? colorScheme.onSurfaceVariant.withOpacity(0.5)
                    : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建图层元素列表
  Widget _buildLayerElementsList(
      List<Map<String, dynamic>> elements, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (elements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            l10n.noElementsInLayer,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: elements.length,
      itemBuilder: (context, index) {
        final element = elements[index];
        final id = element['id'] as String;
        final elementName = element['name'] as String? ?? l10n.unnamedElement;
        final type = element['type'] as String;
        final isHidden = element['hidden'] as bool? ?? false;
        final isLocked = element['locked'] as bool? ?? false;
        final isSelected =
            widget.controller.state.selectedElementIds.contains(id);
        final isEditing = _editingElementId == id;

        // 获取元素类型图标
        IconData iconData;
        switch (type) {
          case 'text':
            iconData = Icons.text_fields;
            break;
          case 'image':
            iconData = Icons.image;
            break;
          case 'collection':
            iconData = Icons.font_download;
            break;
          case 'group':
            iconData = Icons.group_work;
            break;
          default:
            iconData = Icons.crop_square;
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withOpacity(0.3)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Icon(
              iconData,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            title: isEditing
                ? TextField(
                    controller: _elementNameController,
                    focusNode: _elementNameFocusNode,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onSubmitted: (_) => _applyElementNameChange(),
                  )
                : Text(
                    elementName,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 编辑名称按钮
                if (!isEditing)
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    tooltip: l10n.rename,
                    onPressed: () => _startEditingElementName(id, elementName),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                // 可见性按钮
                IconButton(
                  icon: Icon(
                    isHidden ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: isHidden
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.primary,
                  ),
                  tooltip: isHidden ? l10n.showElement : l10n.hideElement,
                  onPressed: () => _toggleElementVisibility(id, isHidden),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                // 锁定按钮
                IconButton(
                  icon: Icon(
                    isLocked ? Icons.lock : Icons.lock_open,
                    size: 18,
                    color: isLocked
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  tooltip: isLocked ? l10n.unlockElement : l10n.lockElement,
                  onPressed: () => _toggleElementLock(id, isLocked),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            onTap: () {
              // 选择元素
              widget.controller.selectElements([id]);
            },
          ),
        );
      },
    );
  }

  // 确认删除图层
  void _confirmDeleteLayer(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.practiceEditDeleteLayerConfirm),
        content: Text(l10n.practiceEditDeleteLayerMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.cancel,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              final layerId = widget.layer['id'] as String;
              widget.controller.deleteLayer(layerId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.error,
            ),
            child: Text(
              l10n.delete,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 移动图层
  void _moveLayer(String direction) {
    final layerId = widget.layer['id'] as String;
    final layerIndex =
        widget.controller.state.layers.indexWhere((l) => l['id'] == layerId);
    final totalLayers = widget.controller.state.layers.length;

    int newIndex;
    switch (direction) {
      case 'top':
        newIndex = totalLayers - 1;
        break;
      case 'up':
        newIndex = layerIndex + 1;
        break;
      case 'down':
        newIndex = layerIndex - 1;
        break;
      case 'bottom':
        newIndex = 0;
        break;
      default:
        return;
    }

    // 确保索引在有效范围内
    newIndex = newIndex.clamp(0, totalLayers - 1);

    // 如果索引没有变化，不执行操作
    if (newIndex == layerIndex) return;

    // 执行图层重排序
    widget.controller.reorderLayer(layerIndex, newIndex);
  }

  // 焦点变化处理
  void _onFocusChange() {
    if (!_nameFocusNode.hasFocus) {
      _applyNameChange();
    }
  }

  // 开始编辑元素名称
  void _startEditingElementName(String id, String name) {
    _elementNameController.text = name;
    setState(() {
      _editingElementId = id;
    });
    // 确保在下一帧聚焦
    Future.microtask(() => _elementNameFocusNode.requestFocus());
  }

  // 开始编辑图层名称
  void _startEditingName() {
    setState(() {
      _isEditingName = true;
    });
    // 确保在下一帧聚焦
    Future.microtask(() => _nameFocusNode.requestFocus());
  }

  // 切换所有元素的锁定状态
  void _toggleAllElementsLock(List<Map<String, dynamic>> elements) {
    // 检查是否所有元素都已锁定
    final allLocked = elements.every((e) => e['locked'] as bool? ?? false);

    // 如果所有元素都已锁定，则解锁所有元素；否则锁定所有元素
    for (final element in elements) {
      final id = element['id'] as String;
      widget.controller.updateElementProperties(id, {'locked': !allLocked});
    }
  }

  // 切换所有元素的可见性
  void _toggleAllElementsVisibility(List<Map<String, dynamic>> elements) {
    // 检查是否所有元素都已隐藏
    final allHidden = elements.every((e) => e['hidden'] as bool? ?? false);

    // 如果所有元素都已隐藏，则显示所有元素；否则隐藏所有元素
    for (final element in elements) {
      final id = element['id'] as String;
      widget.controller.updateElementProperties(id, {'hidden': !allHidden});
    }
  }

  // 切换元素锁定状态
  void _toggleElementLock(String id, bool isLocked) {
    widget.controller.updateElementProperties(id, {'locked': !isLocked});
  }

  // 切换元素可见性
  void _toggleElementVisibility(String id, bool isHidden) {
    widget.controller.updateElementProperties(id, {'hidden': !isHidden});
  }
}
