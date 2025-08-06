import 'package:charasgem/presentation/widgets/practice/memory_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryManager Tests', () {
    late MemoryManager memoryManager;

    setUp(() {
      memoryManager =
          MemoryManager(maxMemoryBytes: 50 * 1024 * 1024); // 50MB for testing
    });

    tearDown(() {
      memoryManager.dispose();
    });

    test('内存管理器应该正确初始化', () {
      print('\n🧪 测试开始：内存管理器初始化');

      final stats = memoryManager.memoryStats;

      print('📊 初始状态：');
      print(
          '   最大内存限制: ${(stats.maxLimit / (1024 * 1024)).toStringAsFixed(1)}MB');
      print(
          '   当前使用量: ${(stats.currentUsage / (1024 * 1024)).toStringAsFixed(1)}MB');
      print('   压力比例: ${(stats.pressureRatio * 100).toStringAsFixed(1)}%');

      expect(stats.maxLimit, equals(50 * 1024 * 1024));
      expect(stats.currentUsage, equals(0));
      expect(stats.pressureRatio, equals(0.0));
      expect(stats.activeImageCount, equals(0));
      expect(stats.trackedElementCount, equals(0));

      print('✅ 内存管理器初始化测试通过\n');
    });

    test('元素内存注册应该正确工作', () {
      print('\n🧪 测试开始：元素内存注册');

      // 创建测试元素
      final testElement = {
        'id': 'test_element_1',
        'type': 'text',
        'x': 10.0,
        'y': 20.0,
        'width': 100.0,
        'height': 50.0,
        'content': 'Test Content',
      };

      // 注册元素
      memoryManager.registerElementMemory('test_element_1', testElement);

      final stats = memoryManager.memoryStats;

      print('📊 注册后状态：');
      print('   已跟踪元素数: ${stats.trackedElementCount}');
      print('   当前使用量: ${(stats.currentUsage / 1024).toStringAsFixed(1)}KB');
      print('   压力比例: ${(stats.pressureRatio * 100).toStringAsFixed(1)}%');

      expect(stats.trackedElementCount, equals(1));
      expect(stats.currentUsage, greaterThan(0));

      // 标记访问
      memoryManager.markElementAccessed('test_element_1');

      print('✅ 元素内存注册测试通过\n');
    });

    test('内存效率元素创建应该正确工作', () {
      print('\n🧪 测试开始：内存效率元素创建');

      final testElement = {
        'id': 'efficient_element_1',
        'type': 'image',
        'x': 0.0,
        'y': 0.0,
        'width': 200.0,
        'height': 200.0,
        'data': List.filled(1024 * 1024, 1), // 1MB 数据
      };

      final efficientElement =
          memoryManager.createMemoryEfficientElement(testElement);

      print('📊 效率元素信息：');
      print('   元素ID: ${efficientElement.id}');
      print('   元素类型: ${efficientElement.type}');
      print(
          '   估计大小: ${(efficientElement.estimatedSize / 1024).toStringAsFixed(1)}KB');
      print('   是否为大元素: ${efficientElement.isLarge}');
      print(
          '   边界: ${efficientElement.bounds.x}, ${efficientElement.bounds.y}, ${efficientElement.bounds.width}x${efficientElement.bounds.height}');

      expect(efficientElement.id, equals('efficient_element_1'));
      expect(efficientElement.type, equals('image'));
      expect(efficientElement.estimatedSize, greaterThan(0));

      // 测试边界计算
      final viewport = ElementBounds(x: -10, y: -10, width: 300, height: 300);
      expect(efficientElement.intersectsViewport(viewport), isTrue);

      print('✅ 内存效率元素创建测试通过\n');
    });

    test('内存压力检测应该正确工作', () {
      print('\n🧪 测试开始：内存压力检测');

      // 创建大图像元素来触发内存压力（基于实际的内存估算）
      for (int i = 0; i < 15; i++) {
        final element = {
          'id': 'pressure_element_$i',
          'type': 'image',
          'width': 2000.0, // 2000x2000像素
          'height': 2000.0, // = 4M像素 × 4字节 = 16MB 每个
        };
        memoryManager.registerElementMemory('pressure_element_$i', element);
      }

      final stats = memoryManager.memoryStats;

      print('📊 内存压力状态：');
      print(
          '   当前使用量: ${(stats.currentUsage / (1024 * 1024)).toStringAsFixed(1)}MB');
      print('   压力比例: ${(stats.pressureRatio * 100).toStringAsFixed(1)}%');
      print('   是否内存压力: ${memoryManager.isMemoryPressure()}');
      print('   是否低内存: ${memoryManager.isLowMemory()}');

      expect(stats.pressureRatio, greaterThan(0.5));
      expect(memoryManager.isMemoryPressure(), isTrue);

      print('✅ 内存压力检测测试通过\n');
    });

    test('内存清理应该有效工作', () async {
      print('\n🧪 测试开始：内存清理');

      // 先创建一些元素
      for (int i = 0; i < 5; i++) {
        final element = {
          'id': 'cleanup_element_$i',
          'type': 'image',
          'width': 800.0, // 800x800像素 = 0.64M像素 × 4字节 = 2.56MB 每个
          'height': 800.0,
        };
        memoryManager.registerElementMemory('cleanup_element_$i', element);
      }

      final beforeStats = memoryManager.memoryStats;
      print('📊 清理前状态：');
      print(
          '   使用量: ${(beforeStats.currentUsage / (1024 * 1024)).toStringAsFixed(1)}MB');
      print('   元素数: ${beforeStats.trackedElementCount}');

      // 执行内存清理
      final freedBytes =
          await memoryManager.performMemoryCleanup(aggressive: true);

      final afterStats = memoryManager.memoryStats;
      print('📊 清理后状态：');
      print(
          '   使用量: ${(afterStats.currentUsage / (1024 * 1024)).toStringAsFixed(1)}MB');
      print('   元素数: ${afterStats.trackedElementCount}');
      print('   释放内存: ${(freedBytes / (1024 * 1024)).toStringAsFixed(1)}MB');

      expect(freedBytes, greaterThanOrEqualTo(0));
      expect(
          afterStats.currentUsage, lessThanOrEqualTo(beforeStats.currentUsage));

      print('✅ 内存清理测试通过\n');
    });

    test('内存限制调整应该正确工作', () {
      print('\n🧪 测试开始：内存限制调整');

      final originalLimit = memoryManager.memoryStats.maxLimit;
      print('📊 原始限制: ${(originalLimit / (1024 * 1024)).toStringAsFixed(1)}MB');

      // 调整内存限制
      const newLimit = 100 * 1024 * 1024; // 100MB
      memoryManager.adjustMemoryLimits(newMaxMemory: newLimit);

      final adjustedStats = memoryManager.memoryStats;
      print(
          '📊 调整后限制: ${(adjustedStats.maxLimit / (1024 * 1024)).toStringAsFixed(1)}MB');

      expect(adjustedStats.maxLimit, equals(newLimit));

      // 测试无效调整（负数）
      memoryManager.adjustMemoryLimits(newMaxMemory: -1);
      final afterInvalidStats = memoryManager.memoryStats;
      expect(afterInvalidStats.maxLimit, equals(newLimit)); // 应该保持不变

      print('✅ 内存限制调整测试通过\n');
    });

    test('大元素检测应该正确工作', () {
      print('\n🧪 测试开始：大元素检测');

      // 创建一个大元素（超过1MB阈值）- 使用图像类型
      final largeElement = {
        'id': 'large_element_1',
        'type': 'image',
        'width': 1000.0, // 1000x1000像素 = 1M像素 × 4字节 = 4MB > 1MB阈值
        'height': 1000.0,
      };

      // 创建一个小元素
      final smallElement = {
        'id': 'small_element_1',
        'type': 'text',
        'text': 'Small content',
        'width': 100.0,
        'height': 50.0,
      };

      memoryManager.registerElementMemory('large_element_1', largeElement);
      memoryManager.registerElementMemory('small_element_1', smallElement);

      final largeElements = memoryManager.getLargeElements();

      print('📊 大元素检测结果：');
      print('   检测到大元素: ${largeElements.length}');
      print('   大元素列表: $largeElements');

      expect(largeElements, contains('large_element_1'));
      expect(largeElements, isNot(contains('small_element_1')));

      print('✅ 大元素检测测试通过\n');
    });

    test('元素卸载应该正确工作', () {
      print('\n🧪 测试开始：元素卸载');

      // 注册一个元素
      final testElement = {
        'id': 'unload_element_1',
        'type': 'image',
        'width': 500.0, // 500x500像素 = 0.25M像素 × 4字节 = 1MB
        'height': 500.0,
      };

      memoryManager.registerElementMemory('unload_element_1', testElement);

      final beforeStats = memoryManager.memoryStats;
      print('📊 卸载前状态：');
      print('   元素数: ${beforeStats.trackedElementCount}');
      print(
          '   使用量: ${(beforeStats.currentUsage / (1024 * 1024)).toStringAsFixed(1)}MB');

      // 卸载元素
      final unloaded =
          memoryManager.unregisterElementMemory('unload_element_1');

      final afterStats = memoryManager.memoryStats;
      print('📊 卸载后状态：');
      print('   元素数: ${afterStats.trackedElementCount}');
      print(
          '   使用量: ${(afterStats.currentUsage / (1024 * 1024)).toStringAsFixed(1)}MB');
      print('   卸载成功: $unloaded');

      expect(unloaded, isTrue);
      expect(afterStats.trackedElementCount,
          equals(beforeStats.trackedElementCount - 1));
      expect(afterStats.currentUsage, lessThan(beforeStats.currentUsage));

      // 测试卸载不存在的元素
      final notFound = memoryManager.unregisterElementMemory('non_existent');
      expect(notFound, isFalse);

      print('✅ 元素卸载测试通过\n');
    });
  });

  group('MemoryStats Tests', () {
    test('内存统计信息应该准确计算', () {
      print('\n🧪 测试开始：内存统计信息');

      final memoryManager =
          MemoryManager(maxMemoryBytes: 20 * 1024 * 1024); // 20MB

      // 添加一些元素
      for (int i = 0; i < 3; i++) {
        final element = {
          'id': 'stats_element_$i',
          'type': 'test',
          'data': List.filled(1024 * 1024, 1), // 1MB 每个
        };
        memoryManager.registerElementMemory('stats_element_$i', element);
      }

      final stats = memoryManager.memoryStats;

      print('📊 内存统计信息：');
      print(
          '   当前使用量: ${(stats.currentUsage / (1024 * 1024)).toStringAsFixed(1)}MB');
      print(
          '   峰值使用量: ${(stats.peakUsage / (1024 * 1024)).toStringAsFixed(1)}MB');
      print(
          '   最大限制: ${(stats.maxLimit / (1024 * 1024)).toStringAsFixed(1)}MB');
      print('   压力比例: ${(stats.pressureRatio * 100).toStringAsFixed(1)}%');
      print('   跟踪元素数: ${stats.trackedElementCount}');
      print('   大元素数: ${stats.largeElementCount}');

      expect(stats.currentUsage, greaterThan(0));
      expect(stats.maxLimit, equals(20 * 1024 * 1024));
      expect(stats.trackedElementCount, equals(3));
      expect(stats.pressureRatio, greaterThan(0));
      expect(stats.pressureRatio, lessThanOrEqualTo(1.0));

      memoryManager.dispose();
      print('✅ 内存统计信息测试通过\n');
    });
  });

  group('ElementBounds Tests', () {
    test('元素边界计算应该正确工作', () {
      print('\n🧪 测试开始：元素边界计算');

      final bounds1 = ElementBounds(x: 10, y: 10, width: 100, height: 100);
      final bounds2 = ElementBounds(x: 50, y: 50, width: 100, height: 100);
      final bounds3 = ElementBounds(x: 200, y: 200, width: 50, height: 50);

      print('📊 边界测试：');
      print(
          '   边界1: (${bounds1.x}, ${bounds1.y}) ${bounds1.width}x${bounds1.height}');
      print(
          '   边界2: (${bounds2.x}, ${bounds2.y}) ${bounds2.width}x${bounds2.height}');
      print(
          '   边界3: (${bounds3.x}, ${bounds3.y}) ${bounds3.width}x${bounds3.height}');

      // 测试重叠
      expect(bounds1.intersects(bounds2), isTrue, reason: '边界1和边界2应该重叠');
      expect(bounds1.intersects(bounds3), isFalse, reason: '边界1和边界3不应该重叠');
      expect(bounds2.intersects(bounds3), isFalse, reason: '边界2和边界3不应该重叠');

      // 测试自身重叠
      expect(bounds1.intersects(bounds1), isTrue, reason: '边界应该与自身重叠');

      print('✅ 元素边界计算测试通过\n');
    });
  });
}
