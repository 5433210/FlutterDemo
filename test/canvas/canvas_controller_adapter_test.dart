// filepath: test/canvas/canvas_controller_adapter_test.dart

import 'package:charasgem/canvas/compatibility/canvas_controller_adapter.dart';
import 'package:charasgem/canvas/compatibility/canvas_state_adapter.dart';
import 'package:charasgem/canvas/core/canvas_state_manager.dart';
import 'package:charasgem/canvas/core/interfaces/layer_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CanvasControllerAdapter', () {
    late CanvasControllerAdapter adapter;
    late CanvasStateManager coreStateManager;
    late CanvasStateManagerAdapter stateAdapter;

    setUp(() {
      // 创建核心状态管理器
      coreStateManager = CanvasStateManager();

      // 创建兼容适配器
      stateAdapter = CanvasStateManagerAdapter(coreStateManager);

      // 创建默认图层
      const defaultLayer = LayerData(
        id: 'default',
        name: 'Default Layer',
        visible: true,
        locked: false,
        opacity: 1.0,
        blendMode: 'normal',
      );
      coreStateManager.createLayer(defaultLayer);
      coreStateManager.selectLayer('default');

      // 创建控制器适配器并附加
      adapter = CanvasControllerAdapter();
      adapter.attach(stateAdapter);
    });

    test('should initialize with empty state', () {
      expect(adapter.elements, isEmpty);
      expect(adapter.selectedElementIds, isEmpty);
      expect(adapter.canUndo, false);
      expect(adapter.canRedo, false);
    });

    test('should add element correctly', () {
      final elementData = {
        'id': 'test_1',
        'type': 'collection',
        'x': 100.0,
        'y': 100.0,
        'width': 200.0,
        'height': 200.0,
      };

      adapter.addElement(elementData);

      expect(adapter.elements.length, 1);
      expect(adapter.elements.first['id'], 'test_1');
      expect(adapter.canUndo, true);
    });

    test('should delete selected elements', () {
      // 添加元素
      final elementData = {
        'id': 'test_1',
        'type': 'collection',
        'x': 100.0,
        'y': 100.0,
        'width': 200.0,
        'height': 200.0,
      };
      adapter.addElement(elementData);

      // 选择元素
      adapter.selectElement('test_1');
      expect(adapter.selectedElementIds, contains('test_1'));

      // 删除选中元素
      adapter.deleteSelectedElements();
      expect(adapter.elements, isEmpty);
      expect(adapter.selectedElementIds, isEmpty);
    });

    test('should support undo/redo operations', () {
      final elementData = {
        'id': 'test_1',
        'type': 'collection',
        'x': 100.0,
        'y': 100.0,
        'width': 200.0,
        'height': 200.0,
      };

      // 添加元素
      adapter.addElement(elementData);
      expect(adapter.elements.length, 1);
      expect(adapter.canUndo, true);

      // 撤销
      adapter.undo();
      expect(adapter.elements, isEmpty);
      expect(adapter.canRedo, true);

      // 重做
      adapter.redo();
      expect(adapter.elements.length, 1);
    });

    test('should update element correctly', () {
      final elementData = {
        'id': 'test_1',
        'type': 'collection',
        'x': 100.0,
        'y': 100.0,
        'width': 200.0,
        'height': 200.0,
      };

      adapter.addElement(elementData);

      // 更新元素位置
      adapter.updateElement('test_1', {'x': 150.0, 'y': 150.0});

      final updatedElement = adapter.elements.first;
      expect(updatedElement['x'], 150.0);
      expect(updatedElement['y'], 150.0);
    });
  });
}
