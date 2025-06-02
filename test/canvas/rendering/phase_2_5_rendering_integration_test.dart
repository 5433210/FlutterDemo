import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:charasgem/canvas/core/canvas_state_manager.dart';
import 'package:charasgem/canvas/core/interfaces/element_data.dart';
import 'package:charasgem/canvas/core/interfaces/layer_data.dart';
import 'package:charasgem/canvas/rendering/canvas_rendering_engine.dart';
import 'package:charasgem/canvas/rendering/render_cache.dart';
import 'package:charasgem/canvas/rendering/render_performance_monitor.dart';

void main() {
  group('Phase 2.5: 渲染器扩展测试', () {
    late CanvasStateManager stateManager;
    late CanvasRenderingEngine renderingEngine;

    setUp(() {
      stateManager = CanvasStateManager();
      renderingEngine = CanvasRenderingEngine(stateManager);

      // 每个测试前创建默认图层
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

    group('Canvas渲染引擎测试', () {
      test('应该成功初始化渲染引擎', () {
        expect(renderingEngine, isNotNull);

        final stats = renderingEngine.getRenderStats();
        expect(stats['renderCount'], equals(0));
        expect(stats['registeredRenderers'], contains('text'));
        expect(stats['registeredRenderers'], contains('image'));
        expect(stats['registeredRenderers'], contains('shape'));
        expect(stats['registeredRenderers'], contains('path'));
      });

      test('应该能够渲染基本元素', () {
        // 添加测试元素
        const textElement = ElementData(
          id: 'text1',
          layerId: 'default',
          type: 'text',
          bounds: Rect.fromLTWH(10, 10, 100, 50),
          properties: {
            'text': 'Hello World',
            'fontSize': 16.0,
            'color': '#000000',
          },
          visible: true,
          locked: false,
        );

        stateManager.addElementToLayer(textElement, 'default');

        // 模拟渲染
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(800, 600);

        expect(() {
          renderingEngine.render(canvas, size);
        }, returnsNormally);

        final stats = renderingEngine.getRenderStats();
        expect(stats['renderCount'], equals(1));
      });

      test('应该正确处理元素选择', () {
        // 添加测试元素
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
        stateManager.selectElement('rect1');

        // 模拟渲染
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(800, 600);

        expect(() {
          renderingEngine.render(canvas, size);
        }, returnsNormally);

        expect(stateManager.selectionState.isSelected('rect1'), isTrue);
      });

      test('应该提供性能统计信息', () {
        // 执行几次渲染
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(800, 600);

        for (int i = 0; i < 5; i++) {
          renderingEngine.render(canvas, size);
        }

        final stats = renderingEngine.getRenderStats();
        expect(stats['renderCount'], equals(5));
        expect(stats['performance'], isNotNull);
        expect(stats['cache'], isNotNull);
        expect(stats['performanceIssues'], isA<List>());
      });
    });

    group('渲染缓存测试', () {
      test('应该正确创建和管理缓存', () {
        final cache = RenderCache(maxCacheSize: 10);

        // 初始状态
        expect(cache.getRenderedElement('element1', 1), isNull);

        final stats = cache.getStats();
        expect(stats['hitCount'], equals(0));
        expect(stats['missCount'], equals(1));
        expect(stats['cacheSize'], equals(0));
      });

      test('应该正确清理缓存', () {
        final cache = RenderCache(maxCacheSize: 5);

        // 模拟缓存操作
        cache.invalidateElement('element1');
        cache.clear();

        final stats = cache.getStats();
        expect(stats['cacheSize'], equals(0));
      });
    });

    group('性能监控测试', () {
      test('应该正确记录渲染性能', () {
        final monitor = RenderPerformanceMonitor();

        // 模拟帧渲染
        monitor.startFrame();
        monitor.recordElementRender();
        monitor.recordCacheHit();
        monitor.endFrame();

        final stats = monitor.getRecentStats();
        expect(stats.elementsPerFrame, equals(1.0));
        expect(stats.cacheHitRate, equals(1.0));
      });

      test('应该检测性能问题', () {
        final monitor = RenderPerformanceMonitor();

        // 模拟性能数据（正常情况）
        monitor.startFrame();
        monitor.recordElementRender();
        Future.delayed(const Duration(milliseconds: 10)); // 模拟快速渲染
        monitor.endFrame();

        final issues = monitor.checkPerformanceIssues();
        expect(issues, isA<List<String>>());
      });
    });

    group('专用渲染器测试', () {
      test('应该支持不同类型的元素', () {
        final elements = [
          const ElementData(
            id: 'text1',
            layerId: 'default',
            type: 'text',
            bounds: Rect.fromLTWH(0, 0, 100, 50),
            properties: {'text': 'Test', 'fontSize': 14.0},
            visible: true,
            locked: false,
          ),
          const ElementData(
            id: 'shape1',
            layerId: 'default',
            type: 'shape',
            bounds: Rect.fromLTWH(0, 0, 100, 100),
            properties: {'shapeType': 'circle', 'fillColor': '#0000ff'},
            visible: true,
            locked: false,
          ),
          const ElementData(
            id: 'path1',
            layerId: 'default',
            type: 'path',
            bounds: Rect.fromLTWH(0, 0, 200, 200),
            properties: {'pathData': 'M 10 10 L 100 100 Z'},
            visible: true,
            locked: false,
          ),
        ];

        // 添加所有元素
        for (final element in elements) {
          stateManager.addElementToLayer(element, 'default');
        }

        // 渲染所有元素
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(800, 600);

        expect(() {
          renderingEngine.render(canvas, size);
        }, returnsNormally);

        final stats = renderingEngine.getRenderStats();
        expect(stats['renderCount'], equals(1));
      });
    });

    group('渲染优化测试', () {
      test('应该优化视口外元素的渲染', () {
        // 添加视口外元素
        const offscreenElement = ElementData(
          id: 'offscreen1',
          layerId: 'default',
          type: 'shape',
          bounds: Rect.fromLTWH(1000, 1000, 100, 100), // 视口外
          properties: {'shapeType': 'rectangle'},
          visible: true,
          locked: false,
        );

        stateManager.addElementToLayer(offscreenElement, 'default');

        // 小尺寸视口渲染
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(800, 600);

        expect(() {
          renderingEngine.render(canvas, size);
        }, returnsNormally);
      });

      test('应该正确处理性能优化', () {
        expect(() {
          renderingEngine.optimizePerformance();
        }, returnsNormally);

        expect(() {
          renderingEngine.clearCache();
        }, returnsNormally);
      });
    });
  });
}
