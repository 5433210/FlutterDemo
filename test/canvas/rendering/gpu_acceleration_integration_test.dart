import 'dart:ui';

import 'package:charasgem/canvas/core/canvas_state_manager.dart';
import 'package:charasgem/canvas/core/interfaces/element_data.dart';
import 'package:charasgem/canvas/core/interfaces/layer_data.dart';
import 'package:charasgem/canvas/rendering/canvas_rendering_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GPU加速集成测试', () {
    late CanvasStateManager stateManager;
    late CanvasRenderingEngine renderingEngine;

    setUp(() {
      stateManager = CanvasStateManager();
      renderingEngine = CanvasRenderingEngine(stateManager);

      // 创建默认图层
      const defaultLayer = LayerData(
        id: 'default',
        name: 'Default Layer',
        visible: true,
        locked: false,
      );
      stateManager.createLayer(defaultLayer);
    });

    tearDown(() {
      renderingEngine.dispose();
    });

    test('应该能获取GPU加速状态', () async {
      final status = await renderingEngine.getGpuAccelerationStatus();

      expect(status, isA<Map<String, dynamic>>());
      expect(status['enabled'], isA<bool>());
      expect(status['strategy'], isA<String>());
      expect(status['capabilities'], isA<Map<String, dynamic>>());
    });

    test('应该能启用/禁用GPU加速', () {
      // 启用GPU加速
      renderingEngine.setGpuAccelerationEnabled(true);

      // 检查渲染统计信息
      final stats = renderingEngine.getRenderStats();
      expect(stats['gpuAcceleration']['enabled'], isTrue);

      // 禁用GPU加速
      renderingEngine.setGpuAccelerationEnabled(false);

      // 再次检查
      final stats2 = renderingEngine.getRenderStats();
      expect(stats2['gpuAcceleration']['enabled'], isFalse);
    });

    test('应该能使用GPU加速渲染多个元素', () {
      // 添加多个元素
      for (int i = 0; i < 5; i++) {
        final element = ElementData(
          id: 'shape$i',
          layerId: 'default',
          type: 'shape',
          bounds: Rect.fromLTWH(i * 50.0, i * 50.0, 100, 100),
          properties: {
            'shapeType': 'rectangle',
            'fillColor': '#ff0000',
          },
          visible: true,
          locked: false,
        );
        stateManager.addElementToLayer(element, 'default');
      }

      // 启用GPU加速
      renderingEngine.setGpuAccelerationEnabled(true);

      // 模拟渲染
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      expect(() {
        renderingEngine.render(canvas, size);
      }, returnsNormally);

      // 获取统计信息
      final stats = renderingEngine.getRenderStats();
      expect(stats['renderCount'], equals(1));

      // 再次渲染，应该使用缓存
      expect(() {
        renderingEngine.render(canvas, size);
      }, returnsNormally);

      // 验证性能优化
      expect(() {
        renderingEngine.optimizePerformance();
      }, returnsNormally);
    });

    test('应该正确处理GPU加速下的元素选择', () {
      // 添加元素
      const element = ElementData(
        id: 'rect1',
        layerId: 'default',
        type: 'shape',
        bounds: Rect.fromLTWH(50, 50, 100, 100),
        properties: {
          'shapeType': 'rectangle',
          'fillColor': '#ff0000',
        },
        visible: true,
        locked: false,
      );

      stateManager.addElementToLayer(element, 'default');

      // 启用GPU加速
      renderingEngine.setGpuAccelerationEnabled(true);

      // 模拟渲染（未选中状态）
      final recorder1 = PictureRecorder();
      final canvas1 = Canvas(recorder1);
      const size = Size(800, 600);
      renderingEngine.render(canvas1, size);

      // 选中元素
      stateManager.selectElement('rect1');

      // 模拟渲染（选中状态）
      final recorder2 = PictureRecorder();
      final canvas2 = Canvas(recorder2);
      renderingEngine.render(canvas2, size);

      expect(stateManager.selectionState.isSelected('rect1'), isTrue);
    });
  });
}
