import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:charasgem/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';
import 'package:charasgem/presentation/widgets/practice/guideline_alignment/guideline_types.dart';

void main() {
  group('参考线对齐功能测试', () {
    late GuidelineManager manager;

    setUp(() {
      manager = GuidelineManager.instance;
    });

    test('GuidelineManager初始化测试', () {
      // 创建测试元素
      final elements = [
        {
          'id': 'element1',
          'x': 100.0,
          'y': 100.0,
          'width': 50.0,
          'height': 30.0,
          'layerId': 'layer1',
          'isHidden': false,
        },
        {
          'id': 'element2',
          'x': 200.0,
          'y': 150.0,
          'width': 40.0,
          'height': 25.0,
          'layerId': 'layer1',
          'isHidden': false,
        },
      ];

      // 初始化参考线管理器
      manager.initialize(
        elements: elements,
        pageSize: const Size(800, 600),
        enabled: true,
        snapThreshold: 5.0,
      );

      expect(manager.enabled, true);
      expect(manager.snapThreshold, 5.0);
    });

    test('detectAlignment方法测试', () {
      // 初始化参考线管理器
      final elements = [
        {
          'id': 'element1',
          'x': 100.0,
          'y': 100.0,
          'width': 50.0,
          'height': 30.0,
          'layerId': 'layer1',
          'isHidden': false,
        },
        {
          'id': 'element2',
          'x': 200.0,
          'y': 100.0, // 与element1水平对齐
          'width': 40.0,
          'height': 25.0,
          'layerId': 'layer1',
          'isHidden': false,
        },
      ];

      manager.initialize(
        elements: elements,
        pageSize: const Size(800, 600),
        enabled: true,
        snapThreshold: 5.0,
      );

      // 测试对齐检测 - 拖动element2到接近element1的位置
      final result = manager.detectAlignment(
        elementId: 'element2',
        currentPosition: const Offset(95, 102), // 接近element1的位置
        elementSize: const Size(40, 25),
      );

      expect(result, isNotNull);
      expect(result!['hasAlignment'], true);

      final newPosition = result['position'] as Offset;
      final guidelines = result['guidelines'] as List<Guideline>; // 验证对齐结果
      expect(newPosition.dy, closeTo(102.5, 1)); // Y坐标应该对齐到element1的中心线
      expect(guidelines.isNotEmpty, true);
    });

    test('generateGuidelines方法测试', () {
      // 初始化参考线管理器
      final elements = [
        {
          'id': 'element1',
          'x': 100.0,
          'y': 100.0,
          'width': 50.0,
          'height': 30.0,
          'layerId': 'layer1',
          'isHidden': false,
        },
      ];

      manager.initialize(
        elements: elements,
        pageSize: const Size(800, 600),
        enabled: true,
        snapThreshold: 5.0,
      ); // 生成参考线 - 使用接近页面中心的位置
      final hasGuidelines = manager.generateGuidelines(
        elementId: 'element1',
        draftPosition: const Offset(375, 285), // 接近页面中心 (400, 300)
        draftSize: const Size(50, 30),
      );

      expect(hasGuidelines, true);
      expect(manager.activeGuidelines.isNotEmpty, true);
    });

    test('页面边缘对齐测试', () {
      // 初始化参考线管理器 - 只有页面，没有其他元素
      manager.initialize(
        elements: [],
        pageSize: const Size(800, 600),
        enabled: true,
        snapThreshold: 5.0,
      );

      // 测试左边缘对齐
      final result = manager.detectAlignment(
        elementId: 'test',
        currentPosition: const Offset(2, 100), // 接近左边缘
        elementSize: const Size(50, 30),
      );

      expect(result, isNotNull);
      if (result != null) {
        final newPosition = result['position'] as Offset;
        expect(newPosition.dx, closeTo(0, 1)); // 应该对齐到左边缘
      }
    });

    test('中心线对齐测试', () {
      // 初始化参考线管理器
      manager.initialize(
        elements: [],
        pageSize: const Size(800, 600),
        enabled: true,
        snapThreshold: 10.0,
      );

      // 测试页面水平中心线对齐
      final result = manager.detectAlignment(
        elementId: 'test',
        currentPosition: const Offset(100, 295), // 接近水平中心 (600/2 - 30/2)
        elementSize: const Size(50, 30),
      );

      expect(result, isNotNull);
      if (result != null) {
        final newPosition = result['position'] as Offset;
        expect(newPosition.dy, closeTo(285, 5)); // 应该对齐到水平中心线
      }
    });

    test('禁用参考线时不应该生成对齐', () {
      // 初始化参考线管理器但禁用
      manager.initialize(
        elements: [],
        pageSize: const Size(800, 600),
        enabled: false, // 禁用参考线
        snapThreshold: 5.0,
      );

      // 测试对齐检测
      final result = manager.detectAlignment(
        elementId: 'test',
        currentPosition: const Offset(2, 100),
        elementSize: const Size(50, 30),
      );

      expect(result, isNull); // 禁用时应该返回null
    });
  });
}
