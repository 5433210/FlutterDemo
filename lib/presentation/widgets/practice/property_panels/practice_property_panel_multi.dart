import 'package:flutter/material.dart';

import '../practice_edit_controller.dart';
import 'practice_property_panel_base.dart';

/// 多选属性面板
class MultiSelectionPropertyPanel extends PracticePropertyPanel {
  final List<String> selectedIds;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;

  const MultiSelectionPropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.selectedIds,
    required this.onElementPropertiesChanged,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '多选元素属性',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // 选中元素信息
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('已选中 ${selectedIds.length} 个元素'),
        ),

        // 对齐操作
        materialExpansionTile(
          title: const Text('对齐操作'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('水平对齐',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: selectedIds.length > 1
                              ? () => _alignElements('left')
                              : null,
                          icon:
                              const Icon(Icons.align_horizontal_left, size: 16),
                          label: const Text('左对齐'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: selectedIds.length > 1
                              ? () => _alignElements('center')
                              : null,
                          icon: const Icon(Icons.align_horizontal_center,
                              size: 16),
                          label: const Text('居中'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: selectedIds.length > 1
                              ? () => _alignElements('right')
                              : null,
                          icon: const Icon(Icons.align_horizontal_right,
                              size: 16),
                          label: const Text('右对齐'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  const Text('垂直对齐',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: selectedIds.length > 1
                              ? () => _alignElements('top')
                              : null,
                          icon: const Icon(Icons.align_vertical_top, size: 16),
                          label: const Text('顶对齐'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: selectedIds.length > 1
                              ? () => _alignElements('middle')
                              : null,
                          icon:
                              const Icon(Icons.align_vertical_center, size: 16),
                          label: const Text('居中'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: selectedIds.length > 1
                              ? () => _alignElements('bottom')
                              : null,
                          icon:
                              const Icon(Icons.align_vertical_bottom, size: 16),
                          label: const Text('底对齐'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // 分布操作
        materialExpansionTile(
          title: const Text('分布操作'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('元素分布',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: selectedIds.length > 2
                              ? () => _distributeElements('horizontal')
                              : null,
                          icon:
                              const Icon(Icons.horizontal_distribute, size: 16),
                          label: const Text('水平均匀分布'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: selectedIds.length > 2
                              ? () => _distributeElements('vertical')
                              : null,
                          icon: const Icon(Icons.vertical_distribute, size: 16),
                          label: const Text('垂直均匀分布'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (selectedIds.length <= 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '注意：分布操作需要至少3个元素',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.error,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        // 组合操作
        materialExpansionTile(
          title: const Text('组合操作'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('组合操作',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              selectedIds.length > 1 ? _groupElements : null,
                          icon: const Icon(Icons.group_work, size: 16),
                          label: const Text('组合为一个元素'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (selectedIds.length <= 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '注意：组合操作需要至少2个元素',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.error,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        // 图层操作
        materialExpansionTile(
          title: const Text('图层操作'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('图层操作',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('移动选中元素到图层:'),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: null,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('选择目标图层'),
                        ),
                        items: _buildLayerItems(),
                        onChanged: (value) {
                          if (value != null) {
                            _moveToLayer(value);
                          }
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
  List<DropdownMenuItem<String>> _buildLayerItems() {
    final layers = controller.state.layers;
    return layers.map((layer) {
      final layerId = layer['id'] as String;
      final layerName = layer['name'] as String? ?? '图层1';
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

  // 组合元素
  void _groupElements() {
    // 直接调用控制器的组合方法
    controller.groupSelectedElements();
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
}
