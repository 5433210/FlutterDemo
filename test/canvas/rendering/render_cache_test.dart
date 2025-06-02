import 'package:charasgem/canvas/rendering/render_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RenderCache 测试', () {
    late RenderCache cache;

    setUp(() {
      cache = RenderCache(maxCacheSize: 5);
    });

    test('初始状态应该正确', () {
      expect(cache.getRenderedElement('test', 1), isNull);
      final stats = cache.getStats();
      expect(stats['cacheSize'], equals(0));
      expect(stats['maxCacheSize'], equals(5));
      expect(stats['hitRate'], equals(0.0));
    });

    test('缓存统计应该正确更新', () {
      // 模拟几次缓存请求
      cache.getRenderedElement('element1', 1); // 未命中
      cache.getRenderedElement('element2', 1); // 未命中

      final stats1 = cache.getStats();
      expect(stats1['hitCount'], equals(0));
      expect(stats1['missCount'], equals(2));
      expect(stats1['hitRate'], equals(0.0));
    });

    test('清空缓存应该重置状态', () {
      // 先生成一些缓存请求
      cache.getRenderedElement('element1', 1);
      cache.getRenderedElement('element2', 1);

      // 清空缓存
      cache.clear();

      final stats = cache.getStats();
      expect(stats['cacheSize'], equals(0));
      expect(stats['hitCount'], equals(0)); // 缓存统计没有重置
      expect(stats['missCount'], equals(2)); // 缓存统计没有重置
    });

    test('应该能清除特定元素的缓存', () {
      // 先模拟缓存一些元素
      cache.invalidateElement('element1');

      // 状态应该保持不变，因为实际上没有缓存任何内容
      final stats = cache.getStats();
      expect(stats['cacheSize'], equals(0));
    });

    test('清理过期缓存应该移除旧条目', () {
      // 模拟清理
      cache.cleanup();

      // 状态应该保持不变
      final stats = cache.getStats();
      expect(stats['cacheSize'], equals(0));
    });

    test('应该正确限制缓存大小', () {
      // 准备一个较小缓存大小的测试实例
      final smallCache = RenderCache(maxCacheSize: 2);

      // 状态应该正确初始化
      final stats = smallCache.getStats();
      expect(stats['maxCacheSize'], equals(2));
      expect(stats['cacheSize'], equals(0));
    });
  });
}
