/// Canvas多选属性面板 - Phase 2.2
///
/// 职责：
/// 1. 多选元素批量编辑
/// 2. 共同属性检测和显示
/// 3. 批量操作支持
/// 4. 性能优化的多选处理
library;

import 'package:flutter/material.dart';

import '../../../core/canvas_state_manager.dart';
import '../../../core/interfaces/element_data.dart';
import '../property_panel.dart';
import '../property_panel_controller.dart';
import 'property_widgets.dart';

/// 多选属性面板
class MultiSelectionPropertyPanel extends StatefulWidget {
  final CanvasStateManager stateManager;
  final PropertyPanelController controller;
  final List<String> selectedElementIds;
  final PropertyPanelStyle style;
  final Function(String, Map<String, dynamic>) onPropertyChanged;

  const MultiSelectionPropertyPanel({
    super.key,
    required this.stateManager,
    required this.controller,
    required this.selectedElementIds,
    this.style = PropertyPanelStyle.modern,
    required this.onPropertyChanged,
  });

  @override
  State<MultiSelectionPropertyPanel> createState() =>
      _MultiSelectionPropertyPanelState();
}

class _MultiSelectionPropertyPanelState
    extends State<MultiSelectionPropertyPanel> {
  late List<ElementData> _selectedElements;
  late Map<String, dynamic> _commonProperties;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    if (widget.selectedElementIds.isEmpty) {
      return _buildEmptySelection();
    }

    if (_selectedElements.isEmpty) {
      return _buildInvalidSelection();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSelectionInfo(),
        const SizedBox(height: 16),
        _buildBatchEditIndicator(),
        const SizedBox(height: 16),
        _buildCommonProperties(),
        const SizedBox(height: 16),
        _buildBatchOperations(),
        const SizedBox(height: 16),
        _buildElementList(),
      ],
    );
  }

  @override
  void didUpdateWidget(MultiSelectionPropertyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedElementIds != widget.selectedElementIds) {
      _updateSelectedElements();
      _calculateCommonProperties();
    }
  }

  @override
  void initState() {
    super.initState();
    _updateSelectedElements();
    _calculateCommonProperties();
  }

  /// 对齐元素
  void _alignElements(String alignment) {
    // TODO: 实现元素对齐逻辑
  }

  /// 构建对齐操作
  Widget _buildAlignmentOperations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '对齐',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _alignElements('left'),
                icon: const Icon(Icons.align_horizontal_left),
                label: const Text('左对齐'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _alignElements('center'),
                icon: const Icon(Icons.align_horizontal_center),
                label: const Text('居中'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _alignElements('right'),
                icon: const Icon(Icons.align_horizontal_right),
                label: const Text('右对齐'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建批量编辑指示器
  Widget _buildBatchEditIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '批量编辑模式 - ${_selectedElements.length} 个元素',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            OutlinedButton(
              onPressed: () {
                final newState =
                    widget.stateManager.selectionState.clearSelection();
                widget.stateManager.updateSelectionState(newState);
              },
              child: const Text('清除选择'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建批量操作
  Widget _buildBatchOperations() {
    return PropertySection(
      title: '批量操作',
      style: widget.style,
      children: [
        _buildAlignmentOperations(),
        const SizedBox(height: 16),
        _buildDistributionOperations(),
        const SizedBox(height: 16),
        _buildGroupingOperations(),
      ],
    );
  }

  /// 构建共同属性
  Widget _buildCommonProperties() {
    if (_commonProperties.isEmpty) {
      return PropertyCard(
        title: '共同属性',
        style: widget.style,
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.difference,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                '所选元素没有共同属性',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return PropertySection(
      title: '共同属性',
      style: widget.style,
      children: [
        if (_commonProperties.containsKey('opacity'))
          PropertySlider(
            label: '透明度',
            value: (_commonProperties['opacity'] as num?)?.toDouble() ?? 1.0,
            min: 0.0,
            max: 1.0,
            onChanged: (value) => _updateBatchProperty('opacity', value),
            divisions: 100,
            suffix: '%',
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PropertySwitch(
                label: '可见性',
                value: _commonProperties['isVisible'] ?? true,
                onChanged: (value) => _updateBatchProperty('isVisible', value),
                enabled: _commonProperties.containsKey('isVisible'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PropertySwitch(
                label: '锁定',
                value: _commonProperties['isLocked'] ?? false,
                onChanged: (value) => _updateBatchProperty('isLocked', value),
                enabled: _commonProperties.containsKey('isLocked'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建分布操作
  Widget _buildDistributionOperations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '分布',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedElements.length >= 3
                    ? () => _distributeElements('horizontal')
                    : null,
                icon: const Icon(Icons.space_bar),
                label: const Text('水平分布'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedElements.length >= 3
                    ? () => _distributeElements('vertical')
                    : null,
                icon: const Icon(Icons.format_line_spacing),
                label: const Text('垂直分布'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建元素项
  Widget _buildElementItem(ElementData element) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getElementIcon(element),
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  element.properties['name']?.toString() ?? '未命名元素',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${element.bounds.width.round()}×${element.bounds.height.round()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            iconSize: 16,
            onPressed: () => _removeElementFromSelection(element.id),
            tooltip: '从选择中移除',
          ),
        ],
      ),
    );
  }

  /// 构建元素列表
  Widget _buildElementList() {
    return PropertySection(
      title: '选中元素',
      style: widget.style,
      children: [
        ..._selectedElements.map((element) => _buildElementItem(element)),
      ],
    );
  }

  /// 构建空选择状态
  Widget _buildEmptySelection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.select_all,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '未选择任何元素',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '选择多个元素以进行批量编辑',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// 构建成组操作
  Widget _buildGroupingOperations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '成组',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _groupElements(),
                icon: const Icon(Icons.group_work),
                label: const Text('创建组'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _deleteElements(),
                icon: const Icon(Icons.delete),
                label: const Text('删除'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建无效选择状态
  Widget _buildInvalidSelection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '选择的元素无效',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '请重新选择有效的元素',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// 构建选择信息
  Widget _buildSelectionInfo() {
    return PropertyCard(
      title: '多选信息',
      style: widget.style,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.select_all,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '已选择 ${_selectedElements.length} 个元素',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '类型: ${_getElementTypes().entries.map((e) => '${e.key}(${e.value})').join(', ')}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// 计算共同属性
  void _calculateCommonProperties() {
    _commonProperties =
        widget.controller.getCommonProperties(widget.selectedElementIds);
  }

  /// 删除元素
  void _deleteElements() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedElements.length} 个元素吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 实现批量删除逻辑
              // ElementState doesn't have a batch removal method,
              // so we would need to implement this differently
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('删除功能尚未实现')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 分布元素
  void _distributeElements(String direction) {
    // TODO: 实现元素分布逻辑
  }

  /// 获取元素图标
  IconData _getElementIcon(ElementData element) {
    switch (element.type) {
      case 'text':
        return Icons.text_fields;
      case 'image':
        return Icons.image;
      case 'collection':
        return Icons.grid_view;
      default:
        return Icons.crop_square;
    }
  }

  /// 获取元素类型统计
  Map<String, int> _getElementTypes() {
    final types = <String, int>{};
    for (final element in _selectedElements) {
      final type = element.type;
      types[type] = (types[type] ?? 0) + 1;
    }
    return types;
  }

  /// 成组元素
  void _groupElements() {
    // TODO: 实现元素成组逻辑
  }

  /// 从选择中移除元素
  void _removeElementFromSelection(String elementId) {
    final newState =
        widget.stateManager.selectionState.removeFromSelection(elementId);
    widget.stateManager.updateSelectionState(newState);
  }

  /// 更新批量属性
  void _updateBatchProperty(String key, dynamic value) {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // 批量更新所有选中元素的属性
    for (final elementId in widget.selectedElementIds) {
      widget.onPropertyChanged(elementId, {key: value});
    }

    // 更新共同属性
    _commonProperties[key] = value;

    setState(() {
      _isProcessing = false;
    });
  }

  /// 更新选中元素
  void _updateSelectedElements() {
    _selectedElements = widget.selectedElementIds
        .map((id) => widget.stateManager.elementState.getElementById(id))
        .where((element) => element != null)
        .cast<ElementData>()
        .toList();
  }
}
