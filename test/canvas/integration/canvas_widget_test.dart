// Canvas Widget Integration Test
// 测试新Canvas架构的完整集成功能

import 'package:charasgem/canvas/compatibility/canvas_controller_adapter.dart';
import 'package:charasgem/canvas/ui/canvas_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CanvasWidget Integration Tests', () {
    testWidgets('Canvas应该正确渲染和交互', (WidgetTester tester) async {
      // 创建控制器
      final controller = CanvasControllerAdapter();

      // 创建Canvas组件
      const configuration = CanvasConfiguration(
        size: Size(400, 300),
        backgroundColor: Colors.white,
        showGrid: true,
        enableGestures: true,
        enablePerformanceMonitoring: true,
      );

      final canvasWidget = CanvasWidget(
        configuration: configuration,
        controller: controller,
      );

      // 构建Widget (这会触发CanvasWidget内部的状态管理器初始化和controller attach)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: canvasWidget,
          ),
        ),
      );

      // 等待Widget完全初始化
      await tester.pump();

      // 添加一个测试元素（使用旧API格式）
      final testElement = {
        'id': 'test-element-1',
        'type': 'image',
        'x': 50.0,
        'y': 50.0,
        'width': 100.0,
        'height': 100.0,
        'test': 'value',
      };

      controller.addElement(testElement);

      // 等待状态更新
      await tester.pump();

      // 验证Widget正确构建
      expect(find.byType(CanvasWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));

      // 验证元素已添加到状态管理器
      expect(controller.elements.length, equals(1));
      expect(controller.elements.first['id'], equals('test-element-1'));

      // 验证手势处理器正常工作
      await tester.tap(find.byType(CanvasWidget));
      await tester.pump();

      // 测试基本交互
      await tester.drag(find.byType(CanvasWidget), const Offset(10, 10));
      await tester.pump();

      // 验证状态没有出错
      expect(tester.takeException(), isNull);
    });

    testWidgets('Canvas应该正确处理多个元素', (WidgetTester tester) async {
      // 创建控制器
      final controller = CanvasControllerAdapter();

      // 创建Canvas组件
      const config = CanvasConfiguration(
        size: Size(400, 300),
        backgroundColor: Colors.white,
        showGrid: false,
        enableGestures: true,
        enablePerformanceMonitoring: false,
      );

      final canvasWidget = CanvasWidget(
        configuration: config,
        controller: controller,
      );

      // 构建Widget (这会触发CanvasWidget内部的状态管理器初始化和controller attach)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: canvasWidget,
          ),
        ),
      );

      // 等待Widget完全初始化
      await tester.pump();

      // 添加多个测试元素
      final elements = [
        {
          'id': 'element-1',
          'type': 'text',
          'x': 10.0,
          'y': 10.0,
          'width': 80.0,
          'height': 30.0,
          'content': 'Text 1',
        },
        {
          'id': 'element-2',
          'type': 'image',
          'x': 100.0,
          'y': 100.0,
          'width': 60.0,
          'height': 60.0,
          'source': 'image.png',
        },
        {
          'id': 'element-3',
          'type': 'shape',
          'x': 200.0,
          'y': 50.0,
          'width': 40.0,
          'height': 40.0,
          'shape': 'circle',
        },
      ];

      // 添加元素
      for (final element in elements) {
        controller.addElement(element);
        await tester.pump(); // 等待每个元素的状态更新
      }

      // 验证所有元素都添加成功
      expect(controller.elements.length, equals(3));

      // 验证可以选择元素
      controller.selectElement('element-2');
      expect(controller.selectedElementIds.contains('element-2'), isTrue);

      // 验证撤销/重做功能
      expect(controller.canUndo, isTrue);

      // 验证Canvas渲染正常
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Canvas应该正确处理性能监控', (WidgetTester tester) async {
      final controller = CanvasControllerAdapter();

      const configuration = CanvasConfiguration(
        size: Size(200, 200),
        enablePerformanceMonitoring: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CanvasWidget(
            configuration: configuration,
            controller: controller,
          ),
        ),
      );

      // 等待Widget完全初始化
      await tester.pump();

      // 触发一些重绘
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // 验证没有性能监控相关的错误
      expect(tester.takeException(), isNull);
    });
  });
}
