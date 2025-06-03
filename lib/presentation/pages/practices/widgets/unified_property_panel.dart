/// 统一属性面板组件
/// 使用适配器模式支持不同类型元素的属性编辑
library;

import 'package:flutter/material.dart';

import '../adapters/property_panel_adapter.dart';
import '../adapters/text_property_adapter.dart';

/// 统一属性面板组件
class UnifiedPropertyPanel extends StatefulWidget {
  final List<dynamic> selectedElements;
  final Function(String elementId, String property, dynamic value)
      onPropertyChanged;
  final PropertyPanelConfig? config;

  const UnifiedPropertyPanel({
    super.key,
    required this.selectedElements,
    required this.onPropertyChanged,
    this.config,
  });

  @override
  State<UnifiedPropertyPanel> createState() => _UnifiedPropertyPanelState();
}

class _UnifiedPropertyPanelState extends State<UnifiedPropertyPanel> {
  final Map<String, PropertyPanelAdapter> _adapters = {};
  late PropertyPanelConfig _config;

  @override
  Widget build(BuildContext context) {
    if (widget.selectedElements.isEmpty) {
      return _buildEmptyState();
    }

    if (widget.selectedElements.length == 1) {
      return _buildSingleElementEditor();
    } else {
      return _buildMultiElementEditor();
    }
  }

  @override
  void initState() {
    super.initState();
    _config = widget.config ?? const PropertyPanelConfig();
    _initializeAdapters();
  }

  Widget _buildBatchEditHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.select_all,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '批量编辑 (${widget.selectedElements.length} 个元素)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '修改的属性将应用到所有选中的元素',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementHeader(dynamic element) {
    final elementType = _getElementType(element);
    final elementId = _getElementId(element);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getElementIcon(elementType),
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getElementDisplayName(elementType),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  elementId,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showElementMenu(element),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '选择一个或多个元素以编辑属性',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击画布中的元素来开始编辑',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMixedTypeEditor() {
    final typeGroups = <String, List<dynamic>>{};
    for (final element in widget.selectedElements) {
      final type = _getElementType(element);
      typeGroups.putIfAbsent(type, () => []).add(element);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '混合选择 (${widget.selectedElements.length} 个元素)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '选中了不同类型的元素，只能编辑通用属性',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 16),
                ...typeGroups.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          _getElementIcon(entry.key),
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                            '${_getElementDisplayName(entry.key)}: ${entry.value.length} 个'),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showBatchEditDialog(),
                  child: const Text('开始批量编辑'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiElementEditor() {
    final elementTypes =
        widget.selectedElements.map(_getElementType).toSet().toList();

    if (elementTypes.length == 1) {
      // 所有元素都是同一类型，可以批量编辑
      final elementType = elementTypes.first;
      final adapter = _adapters[elementType];

      if (adapter == null) {
        return _buildUnsupportedBatchEditor(elementType);
      }

      return Column(
        children: [
          _buildBatchEditHeader(),
          Expanded(
            child: adapter.buildPropertyEditor(
              context: context,
              selectedElements: widget.selectedElements,
              onPropertyChanged: _handleBatchPropertyChange,
              config: _config.copyWith(enableBatchEdit: true),
            ),
          ),
        ],
      );
    } else {
      // 混合类型元素，显示通用属性
      return _buildMixedTypeEditor();
    }
  }

  Widget _buildSingleElementEditor() {
    final element = widget.selectedElements.first;
    final elementType = _getElementType(element);
    final adapter = _adapters[elementType];

    if (adapter == null) {
      return _buildUnsupportedElementEditor(elementType);
    }

    return Column(
      children: [
        _buildElementHeader(element),
        Expanded(
          child: adapter.buildPropertyEditor(
            context: context,
            selectedElements: widget.selectedElements,
            onPropertyChanged: widget.onPropertyChanged,
            config: _config,
          ),
        ),
      ],
    );
  }

  Widget _buildUnsupportedBatchEditor(String elementType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '不支持批量编辑此类型的元素',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '类型: $elementType',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedElementEditor(String elementType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '不支持的元素类型',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '类型: $elementType',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  String _getElementDisplayName(String elementType) {
    switch (elementType) {
      case 'text':
        return '文本';
      case 'collection':
        return '集字';
      case 'image':
        return '图片';
      case 'shape':
        return '形状';
      case 'group':
        return '组合';
      default:
        return '未知元素';
    }
  }

  IconData _getElementIcon(String elementType) {
    switch (elementType) {
      case 'text':
      case 'collection':
        return Icons.text_fields;
      case 'image':
        return Icons.image;
      case 'shape':
        return Icons.crop_square;
      case 'group':
        return Icons.group_work;
      default:
        return Icons.help_outline;
    }
  }

  String _getElementId(dynamic element) {
    if (element is Map<String, dynamic>) {
      return element['id']?.toString() ?? 'unknown';
    }
    return 'unknown';
  }

  String _getElementType(dynamic element) {
    if (element is Map<String, dynamic>) {
      return element['type']?.toString() ?? 'unknown';
    }
    return 'unknown';
  }

  void _handleBatchPropertyChange(
      String elementId, String property, dynamic value) {
    // 批量编辑时，将属性应用到所有选中的元素
    for (final element in widget.selectedElements) {
      final id = _getElementId(element);
      widget.onPropertyChanged(id, property, value);
    }
  }

  void _initializeAdapters() {
    // 注册各种类型的适配器
    final textAdapter = TextPropertyPanelAdapter();
    for (final type in textAdapter.supportedElementTypes) {
      _adapters[type] = textAdapter;
    }

    // 未来可以添加更多适配器
    // final imageAdapter = ImagePropertyPanelAdapter();
    // final shapeAdapter = ShapePropertyPanelAdapter();
  }

  void _showBatchEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量编辑选项'),
        content: const Text('选择要批量编辑的属性类型'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 开始批量编辑
            },
            child: const Text('开始'),
          ),
        ],
      ),
    );
  }

  void _showElementMenu(dynamic element) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('复制元素'),
            onTap: () {
              Navigator.pop(context);
              // 触发复制操作
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('删除元素'),
            onTap: () {
              Navigator.pop(context);
              // 触发删除操作
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('锁定/解锁'),
            onTap: () {
              Navigator.pop(context);
              // 触发锁定切换
            },
          ),
        ],
      ),
    );
  }
}

extension PropertyPanelConfigExtension on PropertyPanelConfig {
  PropertyPanelConfig copyWith({
    bool? enableBatchEdit,
    bool? showAdvancedProperties,
    bool? enableUndoRedo,
    Map<String, dynamic>? customSettings,
  }) {
    return PropertyPanelConfig(
      enableBatchEdit: enableBatchEdit ?? this.enableBatchEdit,
      showAdvancedProperties:
          showAdvancedProperties ?? this.showAdvancedProperties,
      enableUndoRedo: enableUndoRedo ?? this.enableUndoRedo,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}
