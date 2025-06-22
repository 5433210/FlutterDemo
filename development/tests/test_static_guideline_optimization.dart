import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lib/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';

/// 测试静态参考线优化 - 验证静态参考线只在拖拽开始时计算一次
void main() {
  group('静态参考线优化测试', () {
    late GuidelineManager manager;
    
    setUp(() {
      manager = GuidelineManager.instance;
      manager.enabled = true;
      manager.clearGuidelines();
      
      // 设置页面尺寸
      manager.updatePageSize(Size(800, 600));
      
      // 添加一些测试元素
      manager.updateElements([
        {
          'id': 'element1',
          'x': 100.0,
          'y': 100.0,
          'width': 100.0,
          'height': 100.0,
          'rotation': 0.0,
          'isHidden': false,
        },
        {
          'id': 'element2',
          'x': 300.0,
          'y': 200.0,
          'width': 100.0,
          'height': 100.0,
          'rotation': 0.0,
          'isHidden': false,
        },
        {
          'id': 'element3',
          'x': 500.0,
          'y': 300.0,
          'width': 100.0,
          'height': 100.0,
          'rotation': 0.0,
          'isHidden': false,
        },
      ]);
    });
    
    tearDown(() {
      manager.clearGuidelines();
      manager.enabled = false;
    });
    
    test('测试拖拽开始时生成静态参考线', () {
      // 模拟拖拽开始 - regenerateStatic=true
      manager.updateGuidelinesLive(
        elementId: 'element1',
        draftPosition: Offset(120, 120),
        elementSize: Size(100, 100),
        regenerateStatic: true,
      );
      
      final initialStaticCount = manager.staticGuidelines.length;
      final initialTotalCount = manager.activeGuidelines.length;
      
      print('🔍 拖拽开始后的参考线状态:');
      print('  静态参考线数量: $initialStaticCount');
      print('  动态参考线数量: ${manager.dynamicGuidelines.length}');
      print('  高亮参考线数量: ${manager.highlightedGuidelines.length}');
      print('  总参考线数量: $initialTotalCount');
      
      // 验证静态参考线已生成
      expect(initialStaticCount, greaterThan(0), reason: '拖拽开始时应该生成静态参考线');
      expect(manager.dynamicGuidelines.length, greaterThan(0), reason: '应该生成动态参考线');
    });
    
    test('测试拖拽过程中不重新生成静态参考线', () {
      // 第一次调用 - 拖拽开始，生成静态参考线
      manager.updateGuidelinesLive(
        elementId: 'element1',
        draftPosition: Offset(120, 120),
        elementSize: Size(100, 100),
        regenerateStatic: true,
      );
      
      final initialStaticCount = manager.staticGuidelines.length;
      
      print('\\n🔍 拖拽开始 - 静态参考线基线状态:');
      print('  静态参考线数量: $initialStaticCount');
      
      // 模拟拖拽过程中的多次更新 - regenerateStatic=false
      final dragPositions = [
        Offset(130, 130),
        Offset(140, 140),
        Offset(150, 150),
        Offset(160, 160),
        Offset(170, 170),
      ];
      
      for (int i = 0; i < dragPositions.length; i++) {
        manager.updateGuidelinesLive(
          elementId: 'element1',
          draftPosition: dragPositions[i],
          elementSize: Size(100, 100),
          regenerateStatic: false, // 🔧 关键：不重新生成静态参考线
        );
        
        final currentStaticCount = manager.staticGuidelines.length;
        
        print('  拖拽步骤 ${i + 1}: 静态参考线数量 = $currentStaticCount');
        
        // 验证静态参考线数量保持不变
        expect(currentStaticCount, equals(initialStaticCount), 
               reason: '拖拽过程中静态参考线数量应该保持不变');
        
        // 验证动态参考线仍在更新
        expect(manager.dynamicGuidelines.length, greaterThan(0),
               reason: '拖拽过程中应该有动态参考线');
      }
    });
    
    test('性能测试 - 验证优化效果', () {
      // 添加更多元素以增加计算复杂度
      final elements = <Map<String, dynamic>>[];
      for (int i = 1; i <= 20; i++) {
        elements.add({
          'id': 'element$i',
          'x': (i * 50).toDouble(),
          'y': (i * 30).toDouble(),
          'width': 80.0,
          'height': 60.0,
          'rotation': 0.0,
          'isHidden': false,
        });
      }
      manager.updateElements(elements);
      
      // 测试第一次调用（含静态参考线生成）的时间
      final stopwatch1 = Stopwatch()..start();
      manager.updateGuidelinesLive(
        elementId: 'element1',
        draftPosition: Offset(120, 120),
        elementSize: Size(100, 100),
        regenerateStatic: true,
      );
      stopwatch1.stop();
      
      final timeWithStatic = stopwatch1.elapsedMilliseconds;
      
      // 测试后续调用（不含静态参考线生成）的时间
      final stopwatch2 = Stopwatch()..start();
      for (int i = 0; i < 10; i++) {
        manager.updateGuidelinesLive(
          elementId: 'element1',
          draftPosition: Offset(120 + i * 5, 120 + i * 5),
          elementSize: Size(100, 100),
          regenerateStatic: false,
        );
      }
      stopwatch2.stop();
      
      final timeWithoutStatic = stopwatch2.elapsedMilliseconds / 10; // 平均时间
      
      print('\\n🚀 性能测试结果:');
      print('  含静态参考线生成时间: ${timeWithStatic}ms');
      print('  不含静态参考线生成平均时间: ${timeWithoutStatic.toStringAsFixed(2)}ms');
      if (timeWithoutStatic > 0) {
        print('  性能提升倍数: ${(timeWithStatic / timeWithoutStatic).toStringAsFixed(2)}x');
      }
      
      // 验证性能优化效果（不含静态参考线生成应该更快或相等）
      expect(timeWithoutStatic, lessThanOrEqualTo(timeWithStatic + 1), // +1ms容差
             reason: '不重新生成静态参考线应该更快或相等');
    });
  });
}
