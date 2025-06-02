import 'package:charasgem/canvas/rendering/render_performance_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RenderPerformanceMonitor 测试', () {
    late RenderPerformanceMonitor monitor;

    setUp(() {
      monitor = RenderPerformanceMonitor();
    });

    test('初始状态应该正确', () {
      final stats = monitor.getRecentStats();
      expect(stats.frameRate, equals(0.0));
      expect(stats.frameTime, equals(0.0));
      expect(stats.elementsPerFrame, equals(0.0));
      expect(stats.cacheHitRate, equals(0.0));
    });

    test('应该正确记录单帧渲染', () {
      // 模拟帧渲染
      monitor.startFrame();

      // 模拟元素渲染
      monitor.recordElementRender();
      monitor.recordElementRender();

      // 模拟缓存命中
      monitor.recordCacheHit();

      // 结束帧
      monitor.endFrame();

      // 检查统计信息
      final stats = monitor.getRecentStats(1); // 只统计最近一帧
      expect(stats.elementsPerFrame, equals(2.0));
      expect(stats.cacheHitRate, closeTo(0.5, 0.01)); // 一半缓存命中率
    });

    test('应该能够正确记录多帧数据', () {
      // 模拟第一帧
      monitor.startFrame();
      monitor.recordElementRender();
      monitor.recordCacheHit();
      monitor.endFrame();

      // 模拟第二帧
      monitor.startFrame();
      monitor.recordElementRender();
      monitor.recordElementRender();
      monitor.recordCacheHit();
      monitor.endFrame();

      // 模拟第三帧
      monitor.startFrame();
      monitor.recordElementRender();
      monitor.recordElementRender();
      monitor.recordElementRender();
      monitor.recordCacheHit();
      monitor.recordCacheHit();
      monitor.endFrame();

      // 检查统计信息
      final stats = monitor.getRecentStats(3); // 统计最近三帧
      expect(stats.elementsPerFrame, equals(2.0)); // 平均每帧2个元素
      expect(stats.cacheHitRate, closeTo(0.5, 0.01)); // 平均缓存命中率
    });

    test('应该能正确清除统计数据', () {
      // 先录入一些数据
      monitor.startFrame();
      monitor.recordElementRender();
      monitor.endFrame();

      // 清除数据
      monitor.clear();

      // 检查统计信息已重置
      final stats = monitor.getRecentStats();
      expect(stats.frameRate, equals(0.0));
      expect(stats.frameTime, equals(0.0));
      expect(stats.elementsPerFrame, equals(0.0));
      expect(stats.cacheHitRate, equals(0.0));
    });

    test('应该能正确计算平均帧率', () {
      // 模拟帧渲染
      monitor.startFrame();
      monitor.endFrame();

      // 由于只有一帧，帧率应该为0
      expect(monitor.getAverageFrameRate(), equals(0.0));
    });

    test('应该能检测性能问题', () {
      // 空数据应该没有问题
      expect(monitor.checkPerformanceIssues(), isEmpty);

      // 模拟一些数据
      monitor.startFrame();
      monitor.endFrame();

      // 仍然应该没有明确问题
      expect(monitor.checkPerformanceIssues(), isA<List<String>>());
    });

    test('性能统计对象应该能正确转换为字符串', () {
      final stats = PerformanceStats(
        frameRate: 60.0,
        frameTime: 16.67,
        elementsPerFrame: 10.0,
        cacheHitRate: 0.8,
      );

      expect(stats.toString(), contains('60.0 FPS'));
      expect(stats.toString(), contains('16.7 ms'));
      expect(stats.toString(), contains('10.0'));
      expect(stats.toString(), contains('80.0%'));
    });
  });
}
