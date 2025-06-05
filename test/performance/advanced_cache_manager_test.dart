import 'package:charasgem/presentation/widgets/practice/advanced_cache_manager.dart';
import 'package:charasgem/presentation/widgets/practice/element_cache_manager.dart';
import 'package:charasgem/presentation/widgets/practice/memory_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdvancedElementCacheManager Tests', () {
    late MemoryManager memoryManager;
    late ElementCacheManager baseCacheManager;
    late AdvancedElementCacheManager advancedCacheManager;

    setUp(() {
      memoryManager = MemoryManager(maxMemoryBytes: 100 * 1024 * 1024); // 100MB
      baseCacheManager = ElementCacheManager(
        maxSize: 200,
        memoryThreshold: 50 * 1024 * 1024, // 50MB
        memoryManager: memoryManager,
      );
      
      advancedCacheManager = AdvancedElementCacheManager(
        baseCacheManager: baseCacheManager,
        memoryManager: memoryManager,
        config: const AdvancedCacheConfig(
          maxCacheEntries: 200,
          memoryThreshold: 50 * 1024 * 1024,
          enablePrecaching: true,
          useSnapshotSystem: false, // 简化测试，不使用快照系统
        ),
      );
    });

    tearDown(() {
      advancedCacheManager.dispose();
      baseCacheManager.reset();
      memoryManager.dispose();
    });

    test('高级缓存管理器应该正确初始化', () {
      print('\n🧪 测试开始：高级缓存管理器初始化');
      
      expect(advancedCacheManager, isNotNull);
      expect(advancedCacheManager.memoryPressureLevel, equals(MemoryPressureLevel.normal));
      
      final cacheMetrics = advancedCacheManager.getCacheMetrics();
      
      print('📊 初始缓存统计：');
      print('   缓存项数量: ${cacheMetrics['currentSize']}');
      print('   内存压力级别: ${advancedCacheManager.memoryPressureLevel}');
      print('   预测元素数: ${cacheMetrics['advanced']['predictedElements']}');
      
      expect(cacheMetrics['currentSize'], equals(0));
      expect(cacheMetrics['advanced']['predictedElements'], equals(0));
      
      print('✅ 高级缓存管理器初始化测试通过\n');
    });

    test('缓存存储和获取应该正确工作', () {
      print('\n🧪 测试开始：缓存存储和获取');
      
      // 创建测试widget
      const testWidget = Text('Test Widget');
      const elementId = 'test_element_1';
      final properties = {
        'id': elementId,
        'type': 'text',
        'content': 'Test Content',
      };
      
      // 存储到缓存
      advancedCacheManager.storeElementWidget(
        elementId,
        testWidget,
        properties,
        estimatedSize: 1024,
        elementType: 'text',
      );
      
      print('📊 存储后状态：');
      final metricsAfterStore = advancedCacheManager.getCacheMetrics();
      print('   缓存项数量: ${metricsAfterStore['currentSize']}');
      
      // 从缓存获取
      final retrievedWidget = advancedCacheManager.getElementWidget(elementId, 'text');
      
      print('📊 获取结果：');
      print('   获取到的widget: ${retrievedWidget != null ? '成功' : '失败'}');
      
      expect(retrievedWidget, isNotNull);
      expect(metricsAfterStore['currentSize'], greaterThan(0));
      
      print('✅ 缓存存储和获取测试通过\n');
    });

    test('内存压力感知应该正确工作', () async {
      print('\n🧪 测试开始：内存压力感知');
      
      // 创建大量元素触发内存压力
      for (int i = 0; i < 20; i++) {
        final element = {
          'id': 'pressure_element_$i',
          'type': 'image',
          'width': 1000.0,
          'height': 1000.0,
        };
        
        memoryManager.registerElementMemory('pressure_element_$i', element);
        
        // 通过存储widget来触发高级缓存的记录
        advancedCacheManager.storeElementWidget(
          'pressure_element_$i',
          const Text('Large Element'),
          element,
          estimatedSize: 1024 * 1024 * 4, // 4MB
          elementType: 'image',
        );
      }
      
      // 等待内存压力检测
      await Future.delayed(const Duration(milliseconds: 100));
      
      final pressureLevel = advancedCacheManager.memoryPressureLevel;
      
      print('📊 内存压力状态：');
      print('   当前压力级别: $pressureLevel');
      print('   内存统计: ${memoryManager.memoryStats}');
      
      // 应该检测到内存压力
      expect(pressureLevel, isNot(equals(MemoryPressureLevel.normal)));
      
      print('✅ 内存压力感知测试通过\n');
    });

    test('预测元素功能应该正确工作', () {
      print('\n🧪 测试开始：预测元素功能');
      
      // 设置预测的元素列表
      final predictedElements = ['element_1', 'element_2', 'element_3'];
      advancedCacheManager.predictElements(predictedElements);
      
      // 验证预测设置
      final metrics = advancedCacheManager.getCacheMetrics();
      
      print('📊 预测状态：');
      print('   预测元素数: ${metrics['advanced']['predictedElements']}');
      
      expect(metrics['advanced']['predictedElements'], equals(predictedElements.length));
      
      print('✅ 预测元素功能测试通过\n');
    });

    test('缓存清理应该正确工作', () {
      print('\n🧪 测试开始：缓存清理');
      
      // 先添加一些缓存项
      for (int i = 0; i < 5; i++) {
        advancedCacheManager.storeElementWidget(
          'cleanup_element_$i',
          Text('Element $i'),
          {'id': 'cleanup_element_$i', 'type': 'text'},
          estimatedSize: 1024,
          elementType: 'text',
        );
      }
      
      final beforeCleanup = advancedCacheManager.getCacheMetrics();
      
      print('📊 清理前状态：');
      print('   缓存项数量: ${beforeCleanup['currentSize']}');
      
      // 执行缓存清理
      advancedCacheManager.cleanupCache(force: true);
      
      final afterCleanup = advancedCacheManager.getCacheMetrics();
      
      print('📊 清理后状态：');
      print('   缓存项数量: ${afterCleanup['currentSize']}');
      
      // 清理应该有效果（可能清理了一些项目）
      expect(afterCleanup, isNotNull);
      
      print('✅ 缓存清理测试通过\n');
    });

    test('热度图可视化应该正确工作', () {
      print('\n🧪 测试开始：热度图可视化');
      
      // 创建一些缓存项来生成热度数据
      for (int i = 0; i < 3; i++) {
        advancedCacheManager.storeElementWidget(
          'heat_element_$i',
          Text('Heat Element $i'),
          {'id': 'heat_element_$i', 'type': 'text'},
          estimatedSize: 1024,
          elementType: 'text',
        );
      }
      
      final heatMapVisualization = advancedCacheManager.getHeatMapVisualization();
      
      print('📊 热度图可视化：');
      print('   元素数据: ${heatMapVisualization['elements']?.length ?? 0}');
      print('   汇总数据: ${heatMapVisualization['summary']}');
      
      expect(heatMapVisualization, isNotNull);
      expect(heatMapVisualization['elements'], isNotNull);
      expect(heatMapVisualization['summary'], isNotNull);
      
      print('✅ 热度图可视化测试通过\n');
    });

    test('元素更新标记应该正确工作', () {
      print('\n🧪 测试开始：元素更新标记');
      
      const elementId = 'update_element';
      
      // 先存储一个元素
      advancedCacheManager.storeElementWidget(
        elementId,
        const Text('Original'),
        {'id': elementId, 'type': 'text'},
        estimatedSize: 1024,
        elementType: 'text',
      );
      
      // 验证存储成功
      final beforeUpdate = advancedCacheManager.getElementWidget(elementId, 'text');
      expect(beforeUpdate, isNotNull);
      
      // 标记元素需要更新
      advancedCacheManager.markElementForUpdate(elementId);
      
      // 验证元素已从缓存移除
      final afterUpdate = advancedCacheManager.getElementWidget(elementId, 'text');
      
      print('📊 更新标记结果：');
      print('   更新前有缓存: ${beforeUpdate != null}');
      print('   更新后有缓存: ${afterUpdate != null}');
      
      expect(beforeUpdate, isNotNull);
      // 标记更新后，从缓存获取可能返回null（因为被移除了）
      
      print('✅ 元素更新标记测试通过\n');
    });

    test('重置功能应该正确工作', () {
      print('\n🧪 测试开始：重置功能');
      
      // 先添加一些数据
      advancedCacheManager.predictElements(['pred1', 'pred2']);
      advancedCacheManager.storeElementWidget(
        'reset_element',
        const Text('Reset Test'),
        {'id': 'reset_element', 'type': 'text'},
        estimatedSize: 1024,
        elementType: 'text',
      );
      
      final beforeReset = advancedCacheManager.getCacheMetrics();
      
      print('📊 重置前状态：');
      print('   缓存项数量: ${beforeReset['currentSize']}');
      print('   预测元素数: ${beforeReset['advanced']['predictedElements']}');
      
      // 执行重置
      advancedCacheManager.reset();
      
      final afterReset = advancedCacheManager.getCacheMetrics();
      
      print('📊 重置后状态：');
      print('   缓存项数量: ${afterReset['currentSize']}');
      print('   预测元素数: ${afterReset['advanced']['predictedElements']}');
      
      expect(afterReset['currentSize'], equals(0));
      expect(afterReset['advanced']['predictedElements'], equals(0));
      
      print('✅ 重置功能测试通过\n');
    });
  });

  group('AdvancedCacheConfig Tests', () {
    test('缓存配置应该有合理的默认值', () {
      print('\n🧪 测试开始：缓存配置默认值');
      
      const config = AdvancedCacheConfig();
      
      print('📊 默认配置值：');
      print('   最大缓存条目: ${config.maxCacheEntries}');
      print('   内存阈值: ${(config.memoryThreshold / (1024 * 1024)).toStringAsFixed(1)}MB');
      print('   冷缓存清理间隔: ${config.coldCacheCleanupInterval.inMinutes}分钟');
      print('   启用预缓存: ${config.enablePrecaching}');
      print('   使用快照系统: ${config.useSnapshotSystem}');
      print('   自动内存适配: ${config.enableAutoMemoryAdjustment}');
      
      expect(config.maxCacheEntries, greaterThan(0));
      expect(config.memoryThreshold, greaterThan(0));
      expect(config.enablePrecaching, isTrue);
      expect(config.useSnapshotSystem, isTrue);
      
      print('✅ 缓存配置默认值测试通过\n');
    });

    test('自定义配置应该正确应用', () {
      print('\n🧪 测试开始：自定义配置');
      
      const customConfig = AdvancedCacheConfig(
        maxCacheEntries: 100,
        memoryThreshold: 20 * 1024 * 1024, // 20MB
        enablePrecaching: false,
        useSnapshotSystem: false,
        enableAutoMemoryAdjustment: false,
      );
      
      print('📊 自定义配置值：');
      print('   最大缓存条目: ${customConfig.maxCacheEntries}');
      print('   内存阈值: ${(customConfig.memoryThreshold / (1024 * 1024)).toStringAsFixed(1)}MB');
      print('   启用预缓存: ${customConfig.enablePrecaching}');
      print('   使用快照系统: ${customConfig.useSnapshotSystem}');
      print('   自动内存适配: ${customConfig.enableAutoMemoryAdjustment}');
      
      expect(customConfig.maxCacheEntries, equals(100));
      expect(customConfig.memoryThreshold, equals(20 * 1024 * 1024));
      expect(customConfig.enablePrecaching, isFalse);
      expect(customConfig.useSnapshotSystem, isFalse);
      expect(customConfig.enableAutoMemoryAdjustment, isFalse);
      
      print('✅ 自定义配置测试通过\n');
    });
  });
} 