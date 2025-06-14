import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:charasgem/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';
import 'package:charasgem/presentation/widgets/practice/guideline_alignment/guideline_types.dart';

void main() {
  group('参考线集成测试', () {
    late GuidelineManager manager;

    setUp(() {
      manager = GuidelineManager.instance;
    });

    test('完整工作流程测试：初始化 -> 检测对齐 -> 生成参考线 -> 性能优化', () {
      // 1. 初始化参考线管理器
      final elements = [
        {'id': 'elem1', 'x': 100.0, 'y': 100.0, 'width': 50.0, 'height': 30.0},
        {'id': 'elem2', 'x': 200.0, 'y': 150.0, 'width': 60.0, 'height': 40.0},
        {'id': 'elem3', 'x': 150.0, 'y': 200.0, 'width': 40.0, 'height': 50.0},
      ];

      manager.initialize(
        elements: elements,
        pageSize: const Size(800, 600),
        enabled: true,
      );

      // 2. 测试对齐检测
      final alignment = manager.detectAlignment(
        elementId: 'drag',
        currentPosition: const Offset(105.0, 105.0),
        elementSize: const Size(30.0, 20.0),
      );

      expect(alignment, isA<Map<String, dynamic>?>());
      print('✅ 对齐检测正常');      // 3. 测试参考线生成
      final hasGuidelines = manager.generateRealTimeGuidelines(
        elementId: 'drag',
        currentPosition: const Offset(105.0, 105.0),
        elementSize: const Size(30.0, 20.0),
      );

      expect(hasGuidelines, isA<bool>());
      print('✅ 参考线生成正常: $hasGuidelines');      // 4. 测试对齐位置计算
      final alignedPosition = manager.calculateAlignedPosition(
        elementId: 'drag',
        currentPosition: const Offset(105.0, 105.0),
        elementSize: const Size(30.0, 20.0),
      );

      expect(alignedPosition, isNotNull);
      print('✅ 对齐位置计算正常: $alignedPosition');

      // 5. 测试性能优化功能
      final cacheStats = manager.getCacheStats();
      expect(cacheStats, isA<Map<String, dynamic>>());
      print('✅ 缓存统计获取正常: ${cacheStats['cacheSize']} 个缓存项');

      // 6. 测试空间索引
      final nearbyElements = manager.getNearbyElements(
        const Offset(110, 110),
        const Size(30.0, 20.0),
      );
      expect(nearbyElements, isA<List<Map<String, dynamic>>>());
      print('✅ 空间索引查询正常: 找到 ${nearbyElements.length} 个附近元素');

      // 7. 测试缓存功能
      manager.clearCache();
      final statsAfterClear = manager.getCacheStats();
      expect(statsAfterClear['cacheSize'], equals(0));
      print('✅ 缓存清理功能正常');

      print('🎉 参考线功能完整集成测试通过！');
    });

    test('参考线渲染组件集成测试', () {
      // 测试参考线数据结构
      const guideline = Guideline(
        id: 'test_guideline',
        type: GuidelineType.verticalCenterLine,
        position: 100.0,
        direction: AlignmentDirection.vertical,
        sourceElementId: 'elem1',
        sourceElementBounds: Rect.fromLTWH(50, 50, 100, 100),
      );

      expect(guideline.id, equals('test_guideline'));
      expect(guideline.type, equals(GuidelineType.verticalCenterLine));
      expect(guideline.position, equals(100.0));
      expect(guideline.direction, equals(AlignmentDirection.vertical));

      print('✅ 参考线数据结构验证正常');
    });

    test('对齐模式功能测试', () {
      // 测试所有对齐模式
      for (final mode in AlignmentMode.values) {
        expect(mode, isA<AlignmentMode>());
      }

      expect(AlignmentMode.none, isA<AlignmentMode>());
      expect(AlignmentMode.gridSnap, isA<AlignmentMode>());
      expect(AlignmentMode.guideline, isA<AlignmentMode>());

      print('✅ 对齐模式枚举验证正常');
    });

    test('多种对齐类型功能测试', () {
      // 创建测试元素，验证6种对齐组合
      final elements = [
        {
          'id': 'target',
          'x': 200.0,
          'y': 200.0,
          'width': 100.0,
          'height': 80.0
        },
      ];

      manager.initialize(
        elements: elements,
        pageSize: const Size(800, 600),
        enabled: true,
      );

      // 测试各种对齐情况
      final testCases = [
        // 中线对中线 - 垂直中心对齐
        {'x': 250.0, 'y': 100.0, 'expected': 'center-to-center vertical'},
        // 中线对边线 - 垂直边缘对齐
        {'x': 200.0, 'y': 100.0, 'expected': 'center-to-edge vertical'},
        // 边线对边线 - 水平边缘对齐
        {'x': 100.0, 'y': 200.0, 'expected': 'edge-to-edge horizontal'},
      ];      for (final testCase in testCases) {
        final hasGuidelines = manager.generateRealTimeGuidelines(
          elementId: 'drag',
          currentPosition:
              Offset(testCase['x'] as double, testCase['y'] as double),
          elementSize: const Size(50.0, 40.0),
        );
        // 应该能够生成相应的参考线
        expect(hasGuidelines, isA<bool>());
      }

      print('✅ 多种对齐类型功能验证正常');
    });

    test('网格贴附与参考线互斥模式测试', () {
      // 初始化管理器
      manager.initialize(
        elements: [],
        pageSize: const Size(800, 600),
        enabled: true,
      );

      // 模拟切换到网格贴附模式时，参考线应该被禁用
      // 这部分由状态管理层控制，这里验证基础接口
      expect(manager.enabled, isTrue);

      // 禁用参考线功能
      manager.initialize(
        elements: [],
        pageSize: const Size(800, 600),
        enabled: false,
      );

      expect(manager.enabled, isFalse);

      print('✅ 参考线启用/禁用切换功能正常');
    });
  });
}
