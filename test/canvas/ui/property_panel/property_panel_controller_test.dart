import 'package:charasgem/canvas/core/canvas_state_manager.dart';
import 'package:charasgem/canvas/core/interfaces/element_data.dart';
import 'package:charasgem/canvas/state/element_state.dart';
import 'package:charasgem/canvas/state/selection_state.dart';
import 'package:charasgem/canvas/ui/property_panel/property_panel_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PropertyPanelController Tests', () {
    late CanvasStateManager stateManager;
    late PropertyPanelController controller;

    setUp(() {
      stateManager = CanvasStateManager();
      controller = PropertyPanelController(stateManager: stateManager);
    });

    test('初始状态应为页面', () {
      expect(controller.currentTarget?.type, equals(PropertyTargetType.page));
    });

    test('更新配置', () {
      const newConfig = PropertyPanelConfig(
        showAdvancedProperties: false,
        enableBatchEditing: false,
        debounceDelay: Duration(milliseconds: 100),
      );

      controller.updateConfig(newConfig);

      expect(controller.config.showAdvancedProperties, equals(false));
      expect(controller.config.enableBatchEditing, equals(false));
      expect(controller.config.debounceDelay,
          equals(const Duration(milliseconds: 100)));
    });
    test('更新元素属性并验证变更', () async {
      // 创建测试元素
      const element = ElementData(
        id: 'test1',
        type: 'text',
        bounds: Rect.fromLTWH(0, 0, 100, 50),
        properties: {
          'name': 'Test Element',
          'content': 'Hello',
        },
        layerId: 'default',
      );

      // 添加元素到状态管理器
      final newElementState = const ElementState().addElement(element);
      stateManager.updateElementState(newElementState);

      // 选择该元素
      final newSelectionState = const SelectionState().addToSelection('test1');
      stateManager.updateSelectionState(newSelectionState);

      // 验证当前目标是否为该元素
      expect(
          controller.currentTarget?.type, equals(PropertyTargetType.element));
      expect(controller.currentTarget?.element?.id, equals('test1'));

      // 更新属性
      controller
          .updateElementProperties('test1', {'content': 'Updated Content'});

      // 等待批量更新完成
      await Future.delayed(const Duration(milliseconds: 350));

      // 验证更新是否生效
      final updatedElement = stateManager.elementState.getElementById('test1');
      expect(updatedElement?.properties['content'], equals('Updated Content'));
    });

    test('获取共同属性', () {
      // 创建测试元素
      const element1 = ElementData(
        id: 'test1',
        type: 'text',
        bounds: Rect.fromLTWH(0, 0, 100, 50),
        properties: {'name': 'Element 1', 'fontSize': 16},
        opacity: 0.8,
        layerId: 'default',
      );

      const element2 = ElementData(
        id: 'test2',
        type: 'text',
        bounds: Rect.fromLTWH(100, 0, 100, 50),
        properties: {'name': 'Element 2', 'fontSize': 16},
        opacity: 0.8,
        layerId: 'default',
      );

      const element3 = ElementData(
        id: 'test3',
        type: 'text',
        bounds: Rect.fromLTWH(200, 0, 100, 50),
        properties: {'name': 'Element 3', 'fontSize': 20},
        opacity: 0.8,
        layerId: 'default',
      );

      // 添加元素到状态管理器
      var newElementState = const ElementState()
          .addElement(element1)
          .addElement(element2)
          .addElement(element3);
      stateManager.updateElementState(newElementState);

      // 测试共同属性
      final commonProps =
          controller.getCommonProperties(['test1', 'test2', 'test3']);

      expect(commonProps['opacity'], equals(0.8));
      expect(commonProps.containsKey('fontSize'), equals(false)); // 不同的值
    });

    test('属性历史记录功能', () async {
      // 创建测试元素
      const element = ElementData(
        id: 'test1',
        type: 'text',
        bounds: Rect.fromLTWH(0, 0, 100, 50),
        properties: {'name': 'Test Element'},
        layerId: 'default',
      );

      // 添加元素到状态管理器
      final newElementState = const ElementState().addElement(element);
      stateManager.updateElementState(newElementState);

      // 启用历史记录
      controller
          .updateConfig(const PropertyPanelConfig(showPropertyHistory: true));

      // 更新属性
      controller.updateElementProperties('test1', {'name': 'Updated Name'});

      // 等待批量更新完成
      await Future.delayed(const Duration(milliseconds: 350)); // 验证历史记录
      expect(controller.history.isNotEmpty, equals(true));
      expect(controller.history.last.targetId, equals('test1'));
      expect(
          controller.history.last.properties['name'], equals('Updated Name'));
      expect(controller.history.last.previousProperties['name'],
          equals('Updated Name'));

      // 清除历史记录
      controller.clearHistory();
      expect(controller.history.isEmpty, equals(true));
    });
  });
}
