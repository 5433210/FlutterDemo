import 'dart:ui';

import 'package:charasgem/canvas/core/canvas_state_manager.dart';
import 'package:charasgem/canvas/core/interfaces/element_data.dart';
import 'package:charasgem/canvas/core/interfaces/layer_data.dart';
import 'package:charasgem/canvas/rendering/canvas_rendering_engine.dart';
import 'package:charasgem/canvas/rendering/render_quality_optimizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('渲染性能优化测试', () {
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

    test('应该能根据性能自动调整渲染质量', () {
      // 添加多个元素以增加渲染负担
      for (int i = 0; i < 20; i++) {
        final element = ElementData(
          id: 'rect_$i',
          layerId: 'default',
          type: 'shape',
          bounds: Rect.fromLTWH(i * 15.0, i * 15.0, 100, 100),
          properties: {
            'shapeType': 'rectangle',
            'fillColor': '#ff${(i * 10).toString().padLeft(4, '0')}',
          },
        );

        stateManager.addElementToLayer(element, 'default');
      }

      // 进行多次渲染，触发性能监控
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      for (int i = 0; i < 5; i++) {
        renderingEngine.render(canvas, size);
      }

      // 调用性能优化
      renderingEngine.optimizePerformance();

      // 获取当前渲染质量设置
      final qualitySettings = renderingEngine.getRenderQualitySettings();

      // 验证质量设置存在
      expect(qualitySettings, isA<RenderQualitySettings>());

      // 再次渲染
      renderingEngine.render(canvas, size);

      // 获取渲染统计
      final stats = renderingEngine.getRenderStats();

      // 应该包含渲染质量信息
      expect(stats['renderQuality'], isNotNull);
    });

    test('应该能手动控制渲染质量', () {
      // 设置低质量
      renderingEngine.setRenderQualityLevel(RenderQualityLevel.low);

      // 验证质量设置
      final lowQualitySettings = renderingEngine.getRenderQualitySettings();
      expect(lowQualitySettings.qualityLevel, equals(RenderQualityLevel.low));

      // 添加测试元素
      const element = ElementData(
        id: 'test_rect',
        layerId: 'default',
        type: 'shape',
        bounds: Rect.fromLTWH(50, 50, 100, 100),
        properties: {
          'shapeType': 'rectangle',
          'fillColor': '#ff0000',
        },
      );

      stateManager.addElementToLayer(element, 'default');

      // 渲染元素
      final recorder1 = PictureRecorder();
      final canvas1 = Canvas(recorder1);
      const size = Size(800, 600);

      renderingEngine.render(canvas1, size);

      // 获取低质量渲染的统计信息
      final lowQualityStats = renderingEngine.getRenderStats();

      // 设置高质量
      renderingEngine.setRenderQualityLevel(RenderQualityLevel.high);

      // 验证质量设置
      final highQualitySettings = renderingEngine.getRenderQualitySettings();
      expect(highQualitySettings.qualityLevel, equals(RenderQualityLevel.high));

      // 再次渲染
      final recorder2 = PictureRecorder();
      final canvas2 = Canvas(recorder2);

      renderingEngine.render(canvas2, size);

      // 获取高质量渲染的统计信息
      final highQualityStats = renderingEngine.getRenderStats();

      // 验证质量设置已更改
      expect(highQualityStats['renderQuality']['level'],
          isNot(equals(lowQualityStats['renderQuality']['level'])));
    });

    test('应该能禁用自动质量调整', () {
      // 禁用自动质量调整
      renderingEngine.setAutoQualityAdjustment(false);

      // 设置特定质量级别
      renderingEngine.setRenderQualityLevel(RenderQualityLevel.high);

      // 添加多个元素
      for (int i = 0; i < 10; i++) {
        final element = ElementData(
          id: 'rect_$i',
          layerId: 'default',
          type: 'shape',
          bounds: Rect.fromLTWH(i * 25.0, i * 25.0, 100, 100),
          properties: {
            'shapeType': 'rectangle',
            'fillColor': '#ff${(i * 20).toString().padLeft(4, '0')}',
          },
        );

        stateManager.addElementToLayer(element, 'default');
      }

      // 进行多次渲染
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      for (int i = 0; i < 5; i++) {
        renderingEngine.render(canvas, size);
      }

      // 执行性能优化
      renderingEngine.optimizePerformance();

      // 验证质量级别没有改变（因为自动调整已禁用）
      final qualitySettings = renderingEngine.getRenderQualitySettings();
      expect(qualitySettings.qualityLevel, equals(RenderQualityLevel.high));
    });

    test('应该优化视口外元素的渲染', () {
      // 添加一个在视口内的元素
      const visibleElement = ElementData(
        id: 'visible_rect',
        layerId: 'default',
        type: 'shape',
        bounds: Rect.fromLTWH(100, 100, 100, 100),
        properties: {
          'shapeType': 'rectangle',
          'fillColor': '#ff0000',
        },
      );

      stateManager.addElementToLayer(visibleElement, 'default');

      // 添加一个在视口外的元素
      const offscreenElement = ElementData(
        id: 'offscreen_rect',
        layerId: 'default',
        type: 'shape',
        bounds: Rect.fromLTWH(1000, 1000, 100, 100), // 在800x600视口外
        properties: {
          'shapeType': 'rectangle',
          'fillColor': '#00ff00',
        },
      );

      stateManager.addElementToLayer(offscreenElement, 'default');

      // 进行渲染
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600); // 视口大小

      renderingEngine.render(canvas, size);

      // 获取渲染统计
      final stats = renderingEngine.getRenderStats();

      // 应该只渲染视口内的元素
      // 注意：我们不能直接检查具体渲染了哪些元素，但可以通过性能统计推断
      final performanceStats = stats['performance'] as Map<String, dynamic>;
      expect(performanceStats['elementsPerFrame'], 1.0); // 只有一个元素被渲染
    });

    test('应该批量渲染同类型元素', () {
      // 添加多个相同类型的元素
      for (int i = 0; i < 10; i++) {
        final element = ElementData(
          id: 'shape_$i',
          layerId: 'default',
          type: 'shape', // 相同类型
          bounds: Rect.fromLTWH(i * 20.0, i * 20.0, 50, 50),
          properties: {
            'shapeType': 'rectangle',
            'fillColor': '#ff0000',
          },
        );

        stateManager.addElementToLayer(element, 'default');
      }

      // 添加不同类型的元素
      const textElement = ElementData(
        id: 'text_1',
        layerId: 'default',
        type: 'text', // 不同类型
        bounds: Rect.fromLTWH(300, 300, 100, 50),
        properties: {
          'text': 'Test Text',
          'fontSize': 16.0,
          'color': '#000000',
        },
      );

      stateManager.addElementToLayer(textElement, 'default');

      // 启用GPU加速以使用批处理
      renderingEngine.setGpuAccelerationEnabled(true);

      // 进行渲染
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      renderingEngine.render(canvas, size);

      // 获取渲染统计
      final stats = renderingEngine.getRenderStats();

      // 获取缓存统计（第一次渲染缓存应该为0）
      final cacheStats1 = stats['cache'] as Map<String, dynamic>;

      // 再次渲染 - 应该使用缓存
      final recorder2 = PictureRecorder();
      final canvas2 = Canvas(recorder2);

      renderingEngine.render(canvas2, size);

      // 获取更新后的统计
      final stats2 = renderingEngine.getRenderStats();
      final cacheStats2 = stats2['cache'] as Map<String, dynamic>;

      // 验证缓存命中率提高
      expect(cacheStats2['hitRate'], greaterThan(cacheStats1['hitRate']));
    });
  });
}
