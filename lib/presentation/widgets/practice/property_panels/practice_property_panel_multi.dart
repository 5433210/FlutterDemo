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
                  const Text('水平对齐'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _alignElements('left'),
                        child: const Icon(Icons.align_horizontal_left),
                      ),
                      ElevatedButton(
                        onPressed: () => _alignElements('center'),
                        child: const Icon(Icons.align_horizontal_center),
                      ),
                      ElevatedButton(
                        onPressed: () => _alignElements('right'),
                        child: const Icon(Icons.align_horizontal_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  const Text('垂直对齐'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _alignElements('top'),
                        child: const Icon(Icons.align_vertical_top),
                      ),
                      ElevatedButton(
                        onPressed: () => _alignElements('middle'),
                        child: const Icon(Icons.align_vertical_center),
                      ),
                      ElevatedButton(
                        onPressed: () => _alignElements('bottom'),
                        child: const Icon(Icons.align_vertical_bottom),
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
                  const Text('水平分布'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _distributeElements('horizontal'),
                        child: const Icon(Icons.horizontal_distribute),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  const Text('垂直分布'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _distributeElements('vertical'),
                        child: const Icon(Icons.vertical_distribute),
                      ),
                    ],
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
                  ElevatedButton(
                    onPressed: _groupElements,
                    child: const Text('组合选中元素'),
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
                  const Text('移动到图层'),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: null,
                    hint: const Text('选择目标图层'),
                    items: _buildLayerItems(),
                    onChanged: (value) {
                      if (value != null) {
                        _moveToLayer(value);
                      }
                    },
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
      elements.add(element);
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
        for (final element in elements) {
          element['x'] = alignValue;
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
        for (final element in elements) {
          element['x'] = centerX - (element['width'] as num).toDouble() / 2;
        }
        break;
      case 'right':
        // 右对齐，使用最大的右边界
        alignValue = elements
            .map((e) =>
                (e['x'] as num).toDouble() + (e['width'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b);
        for (final element in elements) {
          element['x'] = alignValue - (element['width'] as num).toDouble();
        }
        break;
      case 'top':
        // 顶对齐，使用最小的 y 值
        alignValue = elements
            .map((e) => (e['y'] as num).toDouble())
            .reduce((a, b) => a < b ? a : b);
        for (final element in elements) {
          element['y'] = alignValue;
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
        for (final element in elements) {
          element['y'] = centerY - (element['height'] as num).toDouble() / 2;
        }
        break;
      case 'bottom':
        // 底对齐，使用最大的底边界
        alignValue = elements
            .map((e) =>
                (e['y'] as num).toDouble() + (e['height'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b);
        for (final element in elements) {
          element['y'] = alignValue - (element['height'] as num).toDouble();
        }
        break;
    }

    // 标记为未保存状态
    controller.state.hasUnsavedChanges = true;
    // 通知界面更新
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
    for (final id in selectedIds) {
      final element = controller.state.currentPageElements.firstWhere(
        (e) => e['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      elements.add(element);
    }

    if (elements.length <= 2) return;

    if (direction == 'horizontal') {
      // 水平分布
      // 按 x 坐标排序
      elements.sort((a, b) =>
          ((a['x'] as num).toDouble()).compareTo((b['x'] as num).toDouble()));

      // 计算总宽度和间距
      final firstX = (elements.first['x'] as num).toDouble();
      final lastX = (elements.last['x'] as num).toDouble();
      final lastWidth = (elements.last['width'] as num).toDouble();
      final totalWidth = (lastX + lastWidth) - firstX;
      final totalElementWidth = elements.fold<double>(
          0, (sum, e) => sum + (e['width'] as num).toDouble());
      final spacing = (totalWidth - totalElementWidth) / (elements.length - 1);

      // 重新分布元素
      double currentX = firstX;
      for (int i = 0; i < elements.length; i++) {
        final element = elements[i];
        element['x'] = currentX;
        currentX += (element['width'] as num).toDouble() + spacing;
      }
    } else if (direction == 'vertical') {
      // 垂直分布
      // 按 y 坐标排序
      elements.sort((a, b) =>
          ((a['y'] as num).toDouble()).compareTo((b['y'] as num).toDouble()));

      // 计算总高度和间距
      final firstY = (elements.first['y'] as num).toDouble();
      final lastY = (elements.last['y'] as num).toDouble();
      final lastHeight = (elements.last['height'] as num).toDouble();
      final totalHeight = (lastY + lastHeight) - firstY;
      final totalElementHeight = elements.fold<double>(
          0, (sum, e) => sum + (e['height'] as num).toDouble());
      final spacing =
          (totalHeight - totalElementHeight) / (elements.length - 1);

      // 重新分布元素
      double currentY = firstY;
      for (int i = 0; i < elements.length; i++) {
        final element = elements[i];
        element['y'] = currentY;
        currentY += (element['height'] as num).toDouble() + spacing;
      }
    }

    // 标记为未保存状态
    controller.state.hasUnsavedChanges = true;
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

    // 获取选中元素
    final elements = <Map<String, dynamic>>[];
    for (final id in selectedIds) {
      final element = controller.state.currentPageElements.firstWhere(
        (e) => e['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      elements.add(element);
    }

    if (elements.isEmpty) return;

    // 更新元素的图层ID
    for (final element in elements) {
      element['layerId'] = layerId;
    }

    // 标记为未保存状态
    controller.state.hasUnsavedChanges = true;
  }
}
