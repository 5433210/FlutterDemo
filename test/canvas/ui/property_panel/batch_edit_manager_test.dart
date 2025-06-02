import 'package:charasgem/canvas/core/canvas_state_manager.dart';
import 'package:charasgem/canvas/core/interfaces/element_data.dart';
import 'package:charasgem/canvas/state/element_state.dart';
import 'package:charasgem/canvas/ui/property_panel/batch_edit_manager.dart';
import 'package:charasgem/canvas/ui/property_panel/property_panel_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BatchEditManager Tests', () {
    late CanvasStateManager stateManager;
    late PropertyPanelController propertyController;
    late BatchEditManager batchManager;

    // 测试辅助方法：创建三个水平排列的矩形元素
    void setupTestElements() {
      const element1 = ElementData(
        id: 'rect1',
        type: 'shape',
        bounds: Rect.fromLTWH(0, 0, 100, 50),
        properties: {'name': 'Rectangle 1'},
        layerId: 'default',
      );

      const element2 = ElementData(
        id: 'rect2',
        type: 'shape',
        bounds: Rect.fromLTWH(150, 0, 100, 50),
        properties: {'name': 'Rectangle 2'},
        layerId: 'default',
      );

      const element3 = ElementData(
        id: 'rect3',
        type: 'shape',
        bounds: Rect.fromLTWH(300, 0, 100, 50),
        properties: {'name': 'Rectangle 3'},
        layerId: 'default',
      );

      final newElementState = const ElementState()
          .addElement(element1)
          .addElement(element2)
          .addElement(element3);

      stateManager.updateElementState(newElementState);
    }

    setUp(() {
      stateManager = CanvasStateManager();
      propertyController = PropertyPanelController(stateManager: stateManager);
      batchManager = BatchEditManager(
        controller: propertyController,
        stateManager: stateManager,
      );
    });

    test('初始状态检查', () {
      expect(batchManager.history.isEmpty, isTrue);
      expect(batchManager.isBatchOperationActive, isFalse);
    });

    test('批量设置属性', () {
      setupTestElements();

      final elementIds = ['rect1', 'rect2', 'rect3'];
      batchManager.setBatchProperty(elementIds, 'opacity', 0.5);

      // 验证所有元素的透明度是否已更新
      for (final id in elementIds) {
        final element = stateManager.elementState.getElementById(id);
        expect(element?.opacity, equals(0.5));
      }

      // 验证历史记录
      expect(batchManager.history.length, equals(1));
      expect(batchManager.history.first.operationType,
          equals(BatchOperationType.setProperty));
      expect(batchManager.history.first.targetIds, equals(elementIds));
    });

    test('元素对齐 - 左对齐', () {
      setupTestElements();

      final elementIds = ['rect1', 'rect2', 'rect3'];
      batchManager.alignElements(elementIds, 'left');

      // 验证所有元素是否左对齐
      for (final id in elementIds) {
        final element = stateManager.elementState.getElementById(id);
        expect(element?.bounds.left, equals(0)); // 应该与第一个元素左对齐
      }
    });

    test('元素对齐 - 水平居中', () {
      setupTestElements();

      final elementIds = ['rect1', 'rect2', 'rect3'];

      // 记录初始位置的中心点
      final initialElements = elementIds
          .map((id) => stateManager.elementState.getElementById(id))
          .where((e) => e != null)
          .cast<ElementData>()
          .toList();

      final initialCenters =
          initialElements.map((e) => e.bounds.center.dx).toList();
      final avgCenter =
          initialCenters.reduce((a, b) => a + b) / initialCenters.length;

      // 执行水平居中对齐
      batchManager.alignElements(elementIds, 'center');

      // 验证所有元素是否水平居中对齐
      for (final id in elementIds) {
        final element = stateManager.elementState.getElementById(id);
        expect(element?.bounds.center.dx, closeTo(avgCenter, 0.001));
      }
    });

    test('元素分布 - 水平分布', () {
      setupTestElements();

      final elementIds = ['rect1', 'rect2', 'rect3'];

      // 获取初始的首尾元素位置
      final firstElement = stateManager.elementState.getElementById('rect1')!;
      final lastElement = stateManager.elementState.getElementById('rect3')!;

      final initialLeft = firstElement.bounds.left;
      final initialRight = lastElement.bounds.right;

      // 执行水平分布
      batchManager.distributeElements(elementIds, 'horizontal');

      // 验证首尾元素位置不变
      final updatedFirstElement =
          stateManager.elementState.getElementById('rect1')!;
      final updatedLastElement =
          stateManager.elementState.getElementById('rect3')!;

      expect(updatedFirstElement.bounds.left, equals(initialLeft));
      expect(updatedLastElement.bounds.right, equals(initialRight));

      // 验证中间元素位置是否均匀分布
      final middleElement = stateManager.elementState.getElementById('rect2')!;

      // 计算理想的中间位置
      final totalWidth = initialRight - initialLeft;
      const elementsWidth = 300; // 3个元素，每个宽100
      final spacing = (totalWidth - elementsWidth) / 2;
      final idealMiddleLeft = initialLeft + 100 + spacing;

      expect(middleElement.bounds.left, closeTo(idealMiddleLeft, 0.001));
    });
  });
}
