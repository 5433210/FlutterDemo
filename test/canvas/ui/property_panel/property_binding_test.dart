import 'package:charasgem/canvas/core/canvas_state_manager.dart';
import 'package:charasgem/canvas/core/models/element_data.dart';
import 'package:charasgem/canvas/ui/property_panel/property_binding.dart';
import 'package:charasgem/canvas/ui/property_panel/property_panel_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PropertyBinding Tests', () {
    late CanvasStateManager stateManager;
    late PropertyPanelController controller;
    late PropertyBindingManager bindingManager;

    setUp(() {
      stateManager = CanvasStateManager();
      controller = PropertyPanelController(stateManager: stateManager);
      bindingManager = PropertyBindingManager(controller);

      // 创建测试元素
      const element = CanvasElementData(
        id: 'test1',
        type: 'text',
        bounds: Rect.fromLTWH(0, 0, 100, 50),
        properties: {'name': 'Test Element', 'fontSize': 16},
      ); // 添加元素到状态管理器
      final newElementState = stateManager.elementState.addElement(element);
      stateManager.updateElementState(newElementState);
    });

    test('创建属性绑定', () {
      final binding = bindingManager.bindElement('test1');
      expect(binding.elementId, equals('test1'));
    });

    test('直接绑定 - 立即更新', () async {
      final binding = bindingManager.bindElement(
        'test1',
        options: const PropertyBindingOptions(
          type: PropertyBindingType.direct,
        ),
      );

      binding.setProperty('fontSize', 20);

      // 直接更新应该立即生效
      final element = stateManager.elementState.getElementById('test1');
      expect(element?.properties['fontSize'], equals(20));
    });

    test('批量绑定 - 等待更新', () async {
      final binding = bindingManager.bindElement(
        'test1',
        options: const PropertyBindingOptions(
          type: PropertyBindingType.batch,
        ),
      );

      binding.setProperty('fontSize', 20);
      binding.setProperty('fontWeight', 'bold');

      // 批量更新需要等待帧更新
      final elementBefore = stateManager.elementState.getElementById('test1');
      expect(elementBefore?.properties['fontSize'], equals(16)); // 还没更新

      // 等待一帧
      await Future.delayed(const Duration(milliseconds: 20));

      // 现在应该已更新
      final elementAfter = stateManager.elementState.getElementById('test1');
      expect(elementAfter?.properties['fontSize'], equals(20));
      expect(elementAfter?.properties['fontWeight'], equals('bold'));
    });

    test('批量绑定多个元素', () async {
      // 添加另一个测试元素
      const element2 = CanvasElementData(
        id: 'test2',
        type: 'text',
        bounds: Rect.fromLTWH(200, 0, 100, 50),
        properties: {'name': 'Test Element 2', 'fontSize': 16},
      );

      final newElementState = stateManager.elementState.addElement(element2);
      stateManager.updateElementState(newElementState);

      // 批量绑定两个元素
      final bindings = bindingManager.bindElements(
        ['test1', 'test2'],
        options: const PropertyBindingOptions(
          type: PropertyBindingType.batch,
        ),
      );

      expect(bindings.length, equals(2));

      // 为两个元素设置相同的属性
      for (final binding in bindings) {
        binding.setProperty('fontSize', 24);
      }

      // 等待一帧
      await Future.delayed(const Duration(milliseconds: 20));

      // 验证两个元素都已更新
      final element1 = stateManager.elementState.getElementById('test1');
      final element2Updated = stateManager.elementState.getElementById('test2');

      expect(element1?.properties['fontSize'], equals(24));
      expect(element2Updated?.properties['fontSize'], equals(24));
    });

    test('值缓存 - 相同值不重复更新', () {
      final binding = bindingManager.bindElement('test1');

      // 初始设置
      binding.setProperty('fontSize', 20);

      // 在控制器上设置监听器来检测更新
      var updateCount = 0;
      controller.addListener(() {
        updateCount++;
      });

      // 设置相同的值
      binding.setProperty('fontSize', 20); // 不应触发更新
      binding.setProperty('fontSize', 20); // 不应触发更新

      // 设置不同的值
      binding.setProperty('fontSize', 22); // 应触发更新

      expect(updateCount, equals(1)); // 只有一次真正的更新
    });

    test('清除绑定', () {
      bindingManager.bindElement('test1');
      bindingManager.bindElement('test2');

      bindingManager.clearBindings();

      // 没有好的方法直接检查内部状态，但可以再次创建绑定验证
      final binding = bindingManager.bindElement('test1');
      expect(binding.elementId, equals('test1')); // 应该能正常创建
    });
  });
}
