import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../practice_edit_controller.dart';
import 'm3_practice_property_panel_base.dart';

/// Material 3 多选属性面板
class M3MultiSelectionPropertyPanel extends M3PracticePropertyPanel {
  final List<String> selectedIds;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;

  const M3MultiSelectionPropertyPanel({
    super.key,
    required PracticeEditController controller,
    required this.selectedIds,
    required this.onElementPropertiesChanged,
  }) : super(controller: controller);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 获取所有选中的元素
    final elements = selectedIds
        .map((id) => controller.state.currentPageElements.firstWhere(
            (e) => e['id'] == id,
            orElse: () => <String, dynamic>{}))
        .where((e) => e.isNotEmpty)
        .toList();

    if (elements.isEmpty) {
      return Center(
        child: Text(
          l10n.noElementsSelected,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // 计算共同属性
    final commonOpacity = _getCommonOpacity(elements);
    final commonLocked = _getCommonLocked(elements);
    final commonHidden = _getCommonHidden(elements);
    final commonLayerId = _getCommonLayerId(elements);

    // 获取图层信息
    final layer = commonLayerId != null
        ? controller.state.layers.firstWhere(
            (l) => l['id'] == commonLayerId,
            orElse: () => <String, dynamic>{},
          )
        : null;

    return ListView(
      children: [
        // 多选标题
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.select_all,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${l10n.selected}: ${selectedIds.length} ${l10n.elements}',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        // 多选操作卡片 - 基本属性
        Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.commonProperties,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                // 锁定和可见性控制
                Row(
                  children: [
                    // 锁定控制
                    Expanded(
                      child: SwitchListTile(
                        title: Text(
                          l10n.locked,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        value: commonLocked ?? false,
                        activeColor: colorScheme.primary,
                        onChanged: commonLocked != null
                            ? (value) {
                                _updateAllElements('locked', value);
                              }
                            : null,
                        secondary: Icon(
                          commonLocked == true ? Icons.lock : Icons.lock_open,
                          color: commonLocked == true
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        dense: true,
                      ),
                    ),

                    // 可见性控制
                    Expanded(
                      child: SwitchListTile(
                        title: Text(
                          l10n.visible,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        value: !(commonHidden ?? false),
                        activeColor: colorScheme.primary,
                        onChanged: commonHidden != null
                            ? (value) {
                                _updateAllElements('hidden', !value);
                              }
                            : null,
                        secondary: Icon(
                          commonHidden == true
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: commonHidden == true
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.primary,
                        ),
                        dense: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 透明度控制
                if (commonOpacity != null) ...[
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
                          value: commonOpacity,
                          min: 0.0,
                          max: 1.0,
                          divisions: 100,
                          label: '${(commonOpacity * 100).round()}%',
                          activeColor: colorScheme.primary,
                          inactiveColor: colorScheme.surfaceContainerHighest,
                          onChanged: (value) {
                            _updateAllElements('opacity', value);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${(commonOpacity * 100).round()}%',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // 图层信息
                if (layer != null) ...[
                  Text(
                    l10n.layer,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Icon(
                      Icons.layers,
                      color: colorScheme.primary,
                    ),
                    title: Text(
                      layer['name'] as String? ?? l10n.unnamedLayer,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          (layer['isVisible'] as bool? ?? true)
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 16,
                          color: (layer['isVisible'] as bool? ?? true)
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          (layer['isLocked'] as bool? ?? false)
                              ? Icons.lock
                              : Icons.lock_open,
                          size: 16,
                          color: (layer['isLocked'] as bool? ?? false)
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    dense: true,
                  ),
                ],

                const SizedBox(height: 16),

                // 批量操作按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // 删除所有选中的元素
                        for (final id in selectedIds) {
                          controller.deleteElement(id);
                        }
                      },
                      icon: Icon(
                        Icons.delete,
                        color: colorScheme.error,
                        size: 18,
                      ),
                      label: Text(
                        l10n.deleteAll,
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.error,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // 组合所有选中的元素
                        controller.groupSelectedElements();
                      },
                      icon: Icon(
                        Icons.group_work,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                      label: Text(
                        l10n.group,
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 对齐操作卡片
        Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.layerOperations, // Using layerOperations as a substitute for alignment operations
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                // 水平对齐
                Text(
                  '${l10n.textPropertyPanelHorizontal} ${l10n.textPropertyPanelTextAlign}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: selectedIds.length > 1
                            ? () => _alignElements('left')
                            : null,
                        icon: const Icon(Icons.align_horizontal_left, size: 18),
                        label: Text(
                            '${l10n.textPropertyPanelHorizontal} ${l10n.bringLayerToFront}'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: selectedIds.length > 1
                            ? () => _alignElements('center')
                            : null,
                        icon:
                            const Icon(Icons.align_horizontal_center, size: 18),
                        label: Text(l10n.textPropertyPanelHorizontal),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: selectedIds.length > 1
                            ? () => _alignElements('right')
                            : null,
                        icon:
                            const Icon(Icons.align_horizontal_right, size: 18),
                        label: Text(
                            '${l10n.textPropertyPanelHorizontal} ${l10n.sendToBack}'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 垂直对齐
                Text(
                  '${l10n.textPropertyPanelVertical} ${l10n.textPropertyPanelTextAlign}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: selectedIds.length > 1
                            ? () => _alignElements('top')
                            : null,
                        icon: const Icon(Icons.align_vertical_top, size: 18),
                        label: Text(
                            '${l10n.textPropertyPanelVertical} ${l10n.bringLayerToFront}'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: selectedIds.length > 1
                            ? () => _alignElements('middle')
                            : null,
                        icon: const Icon(Icons.align_vertical_center, size: 18),
                        label: Text(l10n.textPropertyPanelVertical),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: selectedIds.length > 1
                            ? () => _alignElements('bottom')
                            : null,
                        icon: const Icon(Icons.align_vertical_bottom, size: 18),
                        label: Text(
                            '${l10n.textPropertyPanelVertical} ${l10n.sendToBack}'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                if (selectedIds.length <= 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      l10n.practiceEditElementSelectionInfo('2+'),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 分布操作卡片
        Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.position,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                // 元素分布
                Text(
                  l10n.elements,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: selectedIds.length > 2
                      ? () => _distributeElements('horizontal')
                      : null,
                  icon: const Icon(Icons.horizontal_distribute, size: 18),
                  label: Text(l10n.textPropertyPanelHorizontal),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: selectedIds.length > 2
                      ? () => _distributeElements('vertical')
                      : null,
                  icon: const Icon(Icons.vertical_distribute, size: 18),
                  label: Text(l10n.textPropertyPanelVertical),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                if (selectedIds.length <= 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      l10n.practiceEditElementSelectionInfo('3+'),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 图层操作卡片
        Card(
          margin: const EdgeInsets.all(8.0),
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

                // 移动到图层
                Text(
                  '${l10n.moveUp} ${l10n.selected} ${l10n.elements} ${l10n.layer}:',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: null,
                      hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(l10n.selectCollection)),
                      items: _buildLayerItems(context),
                      onChanged: (value) {
                        if (value != null) {
                          _moveToLayer(value);
                        }
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 对齐元素
  void _alignElements(String alignment) {
    // 实现对齐逻辑
    if (selectedIds.length <= 1) return; // 至少需要两个元素

    // 获取选中元素
    final elements = <Map<String, dynamic>>[];
    for (final id in selectedIds) {
      final element = controller.state.currentPageElements.firstWhere(
        (e) => e['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (element.isNotEmpty) {
        elements.add(Map<String, dynamic>.from(element));
      }
    }

    if (elements.length <= 1) return;

    // 计算对齐值
    double alignValue = 0;

    switch (alignment) {
      case 'left':
        // 左对齐，使用最小的 x 值
        alignValue = elements
            .map((e) => (e['x'] as num).toDouble())
            .reduce((a, b) => a < b ? a : b);

        // 更新每个元素的位置
        for (final element in elements) {
          final id = element['id'] as String;
          controller.updateElementProperty(id, 'x', alignValue);
        }
        break;

      case 'center':
        // 水平居中，使用平均中心点
        final centerX = elements
                .map((e) =>
                    (e['x'] as num).toDouble() +
                    (e['width'] as num).toDouble() / 2)
                .reduce((a, b) => a + b) /
            elements.length;

        // 更新每个元素的位置
        for (final element in elements) {
          final id = element['id'] as String;
          final newX = centerX - (element['width'] as num).toDouble() / 2;
          controller.updateElementProperty(id, 'x', newX);
        }
        break;

      case 'right':
        // 右对齐，使用最大的右边界
        alignValue = elements
            .map((e) =>
                (e['x'] as num).toDouble() + (e['width'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b);

        // 更新每个元素的位置
        for (final element in elements) {
          final id = element['id'] as String;
          final newX = alignValue - (element['width'] as num).toDouble();
          controller.updateElementProperty(id, 'x', newX);
        }
        break;

      case 'top':
        // 顶对齐，使用最小的 y 值
        alignValue = elements
            .map((e) => (e['y'] as num).toDouble())
            .reduce((a, b) => a < b ? a : b);

        // 更新每个元素的位置
        for (final element in elements) {
          final id = element['id'] as String;
          controller.updateElementProperty(id, 'y', alignValue);
        }
        break;

      case 'middle':
        // 垂直居中，使用平均中心点
        final centerY = elements
                .map((e) =>
                    (e['y'] as num).toDouble() +
                    (e['height'] as num).toDouble() / 2)
                .reduce((a, b) => a + b) /
            elements.length;

        // 更新每个元素的位置
        for (final element in elements) {
          final id = element['id'] as String;
          final newY = centerY - (element['height'] as num).toDouble() / 2;
          controller.updateElementProperty(id, 'y', newY);
        }
        break;

      case 'bottom':
        // 底对齐，使用最大的底边界
        alignValue = elements
            .map((e) =>
                (e['y'] as num).toDouble() + (e['height'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b);

        // 更新每个元素的位置
        for (final element in elements) {
          final id = element['id'] as String;
          final newY = alignValue - (element['height'] as num).toDouble();
          controller.updateElementProperty(id, 'y', newY);
        }
        break;
    }
  }

  // 构建图层选项
  List<DropdownMenuItem<String>> _buildLayerItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final layers = controller.state.layers;
    return layers.map((layer) {
      final layerId = layer['id'] as String;
      final layerName = layer['name'] as String? ?? l10n.unnamedLayer;
      return DropdownMenuItem<String>(
        value: layerId,
        child: Text(layerName),
      );
    }).toList();
  }

  // 分布元素
  void _distributeElements(String direction) {
    // 实现分布逻辑
    if (selectedIds.length <= 2) return; // 至少需要三个元素

    // 获取选中元素
    final elements = <Map<String, dynamic>>[];
    final elementIds = <String>[];

    for (final id in selectedIds) {
      final element = controller.state.currentPageElements.firstWhere(
        (e) => e['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (element.isNotEmpty) {
        elements.add(Map<String, dynamic>.from(element));
        elementIds.add(id);
      }
    }

    if (elements.length <= 2) return;

    if (direction == 'horizontal') {
      // 水平分布
      // 按 x 坐标排序
      final sortedElements = List<Map<String, dynamic>>.from(elements);
      final sortedIds = List<String>.from(elementIds);

      // 创建元素和ID的配对，以便排序后仍能找到对应的ID
      final pairs = List.generate(elements.length,
          (i) => {'element': elements[i], 'id': elementIds[i]});

      // 按 x 坐标排序
      pairs.sort((a, b) => ((a['element'] as Map<String, dynamic>)['x'] as num)
          .toDouble()
          .compareTo(
              ((b['element'] as Map<String, dynamic>)['x'] as num).toDouble()));

      // 提取排序后的元素和ID
      for (int i = 0; i < pairs.length; i++) {
        sortedElements[i] = pairs[i]['element'] as Map<String, dynamic>;
        sortedIds[i] = pairs[i]['id'] as String;
      }

      // 计算总宽度和间距
      final firstX = (sortedElements.first['x'] as num).toDouble();
      final lastX = (sortedElements.last['x'] as num).toDouble();
      final lastWidth = (sortedElements.last['width'] as num).toDouble();
      final totalWidth = (lastX + lastWidth) - firstX;
      final totalElementWidth = sortedElements.fold<double>(
          0, (sum, e) => sum + (e['width'] as num).toDouble());
      final spacing =
          (totalWidth - totalElementWidth) / (sortedElements.length - 1);

      // 重新分布元素
      double currentX = firstX;
      for (int i = 0; i < sortedElements.length; i++) {
        final element = sortedElements[i];
        final id = sortedIds[i];

        // 第一个和最后一个元素保持原位置，中间的元素重新分布
        if (i > 0 && i < sortedElements.length - 1) {
          controller.updateElementProperty(id, 'x', currentX);
        }

        currentX += (element['width'] as num).toDouble() + spacing;
      }
    } else if (direction == 'vertical') {
      // 垂直分布
      // 按 y 坐标排序
      final sortedElements = List<Map<String, dynamic>>.from(elements);
      final sortedIds = List<String>.from(elementIds);

      // 创建元素和ID的配对，以便排序后仍能找到对应的ID
      final pairs = List.generate(elements.length,
          (i) => {'element': elements[i], 'id': elementIds[i]});

      // 按 y 坐标排序
      pairs.sort((a, b) => ((a['element'] as Map<String, dynamic>)['y'] as num)
          .toDouble()
          .compareTo(
              ((b['element'] as Map<String, dynamic>)['y'] as num).toDouble()));

      // 提取排序后的元素和ID
      for (int i = 0; i < pairs.length; i++) {
        sortedElements[i] = pairs[i]['element'] as Map<String, dynamic>;
        sortedIds[i] = pairs[i]['id'] as String;
      }

      // 计算总高度和间距
      final firstY = (sortedElements.first['y'] as num).toDouble();
      final lastY = (sortedElements.last['y'] as num).toDouble();
      final lastHeight = (sortedElements.last['height'] as num).toDouble();
      final totalHeight = (lastY + lastHeight) - firstY;
      final totalElementHeight = sortedElements.fold<double>(
          0, (sum, e) => sum + (e['height'] as num).toDouble());
      final spacing =
          (totalHeight - totalElementHeight) / (sortedElements.length - 1);

      // 重新分布元素
      double currentY = firstY;
      for (int i = 0; i < sortedElements.length; i++) {
        final element = sortedElements[i];
        final id = sortedIds[i];

        // 第一个和最后一个元素保持原位置，中间的元素重新分布
        if (i > 0 && i < sortedElements.length - 1) {
          controller.updateElementProperty(id, 'y', currentY);
        }

        currentY += (element['height'] as num).toDouble() + spacing;
      }
    }
  }

  // 获取所有元素的共同隐藏状态
  bool? _getCommonHidden(List<Map<String, dynamic>> elements) {
    if (elements.isEmpty) return null;

    final firstHidden = elements.first['hidden'] as bool? ?? false;

    for (final element in elements) {
      final hidden = element['hidden'] as bool? ?? false;
      if (hidden != firstHidden) {
        return null; // 不一致
      }
    }

    return firstHidden;
  }

  // 获取所有元素的共同图层ID
  String? _getCommonLayerId(List<Map<String, dynamic>> elements) {
    if (elements.isEmpty) return null;

    final firstLayerId = elements.first['layerId'] as String?;
    if (firstLayerId == null) return null;

    for (final element in elements) {
      final layerId = element['layerId'] as String?;
      if (layerId != firstLayerId) {
        return null; // 不一致
      }
    }

    return firstLayerId;
  }

  // 获取所有元素的共同锁定状态
  bool? _getCommonLocked(List<Map<String, dynamic>> elements) {
    if (elements.isEmpty) return null;

    final firstLocked = elements.first['locked'] as bool? ?? false;

    for (final element in elements) {
      final locked = element['locked'] as bool? ?? false;
      if (locked != firstLocked) {
        return null; // 不一致
      }
    }

    return firstLocked;
  }

  // 获取所有元素的共同不透明度
  double? _getCommonOpacity(List<Map<String, dynamic>> elements) {
    if (elements.isEmpty) return null;

    final firstOpacity = (elements.first['opacity'] as num?)?.toDouble() ?? 1.0;

    for (final element in elements) {
      final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;
      if ((opacity - firstOpacity).abs() > 0.01) {
        return null; // 不一致
      }
    }

    return firstOpacity;
  }

  // 移动到图层
  void _moveToLayer(String layerId) {
    // 实现移动到图层逻辑
    if (selectedIds.isEmpty) return;

    // 获取目标图层信息，确保图层存在
    final targetLayer = controller.state.layers.firstWhere(
      (layer) => layer['id'] == layerId,
      orElse: () => <String, dynamic>{},
    );

    if (targetLayer.isEmpty) return;

    // 使用控制器更新每个元素的图层ID
    for (final id in selectedIds) {
      controller.updateElementProperty(id, 'layerId', layerId);
    }
  }

  // 更新所有选中元素的属性
  void _updateAllElements(String key, dynamic value) {
    // 使用传入的回调函数更新所有选中元素的属性
    // 回调函数会在调用方处理每个元素的更新
    onElementPropertiesChanged({key: value});
  }
}
