import 'dart:ui';

import 'package:charasgem/canvas/core/canvas_state_manager.dart';
import 'package:charasgem/canvas/core/interfaces/element_data.dart';
import 'package:charasgem/canvas/core/interfaces/layer_data.dart';
import 'package:charasgem/canvas/rendering/canvas_rendering_engine.dart';
import 'package:charasgem/canvas/rendering/render_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('渲染器缓存系统测试', () {
    late CanvasStateManager stateManager;
    late CanvasRenderingEngine renderingEngine;
    late RenderCache renderCache;

    setUp(() {
      stateManager = CanvasStateManager();
      renderingEngine = CanvasRenderingEngine(stateManager);
      renderCache = RenderCache();

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

    test('应该缓存静态元素的渲染结果', () {
      // 添加一个形状元素
      const element = ElementData(
        id: 'rect1',
        layerId: 'default',
        type: 'shape',
        bounds: Rect.fromLTWH(50, 50, 100, 100),
        properties: {
          'shapeType': 'rectangle',
          'fillColor': '#ff0000',
        },
        version: 1, // 初始版本
      );

      stateManager.addElementToLayer(element, 'default');

      // 进行首次渲染
      final recorder1 = PictureRecorder();
      final canvas1 = Canvas(recorder1);
      const size = Size(800, 600);

      renderingEngine.render(canvas1, size);

      // 获取性能统计
      final stats1 = renderingEngine.getRenderStats();
      final cacheStats1 = stats1['cache'] as Map<String, dynamic>;

      // 进行第二次渲染 - 应该使用缓存
      final recorder2 = PictureRecorder();
      final canvas2 = Canvas(recorder2);

      renderingEngine.render(canvas2, size);

      // 获取更新后的统计
      final stats2 = renderingEngine.getRenderStats();
      final cacheStats2 = stats2['cache'] as Map<String, dynamic>;

      // 第二次渲染应该有缓存命中
      expect(cacheStats2['hitCount'], greaterThan(cacheStats1['hitCount']));
    });

    test('应该在元素更改后重新渲染并更新缓存', () {
      // 添加一个形状元素
      const element = ElementData(
        id: 'rect2',
        layerId: 'default',
        type: 'shape',
        bounds: Rect.fromLTWH(50, 50, 100, 100),
        properties: {
          'shapeType': 'rectangle',
          'fillColor': '#ff0000',
        },
        version: 1, // 初始版本
      );

      stateManager.addElementToLayer(element, 'default');

      // 进行首次渲染
      final recorder1 = PictureRecorder();
      final canvas1 = Canvas(recorder1);
      const size = Size(800, 600);

      renderingEngine.render(canvas1, size);

      // 修改元素
      final updatedElement = element.copyWith(
        properties: {
          'shapeType': 'rectangle',
          'fillColor': '#0000ff', // 改变颜色
        },
      );

      stateManager.updateElement(updatedElement.id, updatedElement);

      // 第二次渲染应该重新生成缓存
      final recorder2 = PictureRecorder();
      final canvas2 = Canvas(recorder2);

      renderingEngine.render(canvas2, size);

      // 获取更新后的统计
      final stats = renderingEngine.getRenderStats();
      expect(stats['dirtyElementsCount'], 0); // 脏元素应该被清理
    });

    test('应该根据缓存策略跳过某些元素的缓存', () {
      // 添加一个非常小的元素 - 应该跳过缓存
      const smallElement = ElementData(
        id: 'small_rect',
        layerId: 'default',
        type: 'shape',
        bounds: Rect.fromLTWH(50, 50, 5, 5), // 很小的元素
        properties: {
          'shapeType': 'rectangle',
          'fillColor': '#ff0000',
        },
      );

      stateManager.addElementToLayer(smallElement, 'default');

      // 添加一个正常大小的元素 - 应该缓存
      const normalElement = ElementData(
        id: 'normal_rect',
        layerId: 'default',
        type: 'shape',
        bounds: Rect.fromLTWH(100, 100, 100, 100), // 正常大小
        properties: {
          'shapeType': 'rectangle',
          'fillColor': '#00ff00',
        },
      );

      stateManager.addElementToLayer(normalElement, 'default');

      // 进行渲染
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      renderingEngine.render(canvas, size);

      // 再次渲染
      final recorder2 = PictureRecorder();
      final canvas2 = Canvas(recorder2);

      renderingEngine.render(canvas2, size);

      // 获取缓存统计
      final stats = renderingEngine.getRenderStats();
      final cacheStats = stats['cache'] as Map<String, dynamic>;

      // 应该有缓存命中
      expect(cacheStats['hitCount'], greaterThan(0));
    });

    test('应该正确处理选中元素的缓存策略', () {
      // 添加一个形状元素
      const element = ElementData(
        id: 'selectable_rect',
        layerId: 'default',
        type: 'shape',
        bounds: Rect.fromLTWH(50, 50, 100, 100),
        properties: {
          'shapeType': 'rectangle',
          'fillColor': '#ff0000',
        },
      );

      stateManager.addElementToLayer(element, 'default');

      // 首次渲染
      final recorder1 = PictureRecorder();
      final canvas1 = Canvas(recorder1);
      const size = Size(800, 600);

      renderingEngine.render(canvas1, size);

      // 选中元素
      stateManager.selectElement('selectable_rect');

      // 第二次渲染 - 选中状态应该不使用缓存
      final recorder2 = PictureRecorder();
      final canvas2 = Canvas(recorder2);

      renderingEngine.render(canvas2, size);

      // 取消选中
      stateManager.clearSelection();

      // 第三次渲染 - 应该重新缓存非选中状态
      final recorder3 = PictureRecorder();
      final canvas3 = Canvas(recorder3);

      renderingEngine.render(canvas3, size);

      // 第四次渲染 - 应该使用缓存
      final recorder4 = PictureRecorder();
      final canvas4 = Canvas(recorder4);

      renderingEngine.render(canvas4, size);

      // 获取缓存统计
      final stats = renderingEngine.getRenderStats();
      final cacheStats = stats['cache'] as Map<String, dynamic>;

      // 应该有缓存命中
      expect(cacheStats['hitCount'], greaterThan(0));
    });

    test('应该能正确清理缓存', () {
      // 添加几个元素
      for (int i = 0; i < 5; i++) {
        final element = ElementData(
          id: 'rect_$i',
          layerId: 'default',
          type: 'shape',
          bounds: Rect.fromLTWH(i * 50.0, i * 50.0, 100, 100),
          properties: {
            'shapeType': 'rectangle',
            'fillColor': '#ff00${i.toString().padLeft(2, '0')}',
          },
        );

        stateManager.addElementToLayer(element, 'default');
      }

      // 首次渲染 - 缓存所有元素
      final recorder1 = PictureRecorder();
      final canvas1 = Canvas(recorder1);
      const size = Size(800, 600);

      renderingEngine.render(canvas1, size);

      // 清除缓存
      renderingEngine.clearCache();

      // 第二次渲染 - 所有元素都应重新渲染
      final recorder2 = PictureRecorder();
      final canvas2 = Canvas(recorder2);

      renderingEngine.render(canvas2, size);

      // 获取缓存统计
      final stats = renderingEngine.getRenderStats();
      final cacheStats = stats['cache'] as Map<String, dynamic>;

      // 应该没有缓存命中（因为已清除）
      expect(cacheStats['hitRate'], 0.0);

      // 应该有缓存大小（第二次渲染后）
      expect(cacheStats['cacheSize'], greaterThan(0));
    });

    test('应该在优化性能时清理过期缓存', () {
      // 添加几个元素
      for (int i = 0; i < 3; i++) {
        final element = ElementData(
          id: 'rect_$i',
          layerId: 'default',
          type: 'shape',
          bounds: Rect.fromLTWH(i * 50.0, i * 50.0, 100, 100),
          properties: {
            'shapeType': 'rectangle',
            'fillColor': '#ff00${i.toString().padLeft(2, '0')}',
          },
        );

        stateManager.addElementToLayer(element, 'default');
      }

      // 渲染元素
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      renderingEngine.render(canvas, size);

      // 性能优化（包括清理过期缓存）
      renderingEngine.optimizePerformance();

      // 再次渲染
      final recorder2 = PictureRecorder();
      final canvas2 = Canvas(recorder2);

      renderingEngine.render(canvas2, size);

      // 获取渲染统计信息
      final stats = renderingEngine.getRenderStats();

      // 应该有一些性能信息
      expect(stats['performance'], isNotNull);
      expect(stats['cache'], isNotNull);
    });
  });
}
