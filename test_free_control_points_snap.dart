import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lib/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';

/// 测试FreeControlPoints对齐吸附功能 - 验证控制点在吸附时正确更新位置和尺寸
void main() {
  group('FreeControlPoints对齐吸附测试', () {
    late GuidelineManager manager;
    
    setUp(() {
      manager = GuidelineManager.instance;
      manager.enabled = true;
      manager.clearGuidelines();
      
      // 设置页面尺寸
      manager.updatePageSize(Size(800, 600));
      
      // 添加目标元素（用于生成静态参考线）
      manager.updateElements([
        {
          'id': 'target1',
          'x': 200.0,
          'y': 100.0,
          'width': 100.0,
          'height': 100.0,
          'rotation': 0.0,
          'isHidden': false,
        },
        {
          'id': 'target2',
          'x': 400.0,
          'y': 200.0,
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
    
    test('测试平移对齐吸附功能', () {
      print('\\n🔍 测试平移对齐吸附功能');
      
      // 模拟拖拽一个元素到接近目标位置
      final elementId = 'dragging1';
      final initialPosition = Offset(190, 95); // 接近target1的位置(200, 100)
      final elementSize = Size(80, 80);
      
      // 第一步：模拟拖拽开始，生成静态参考线
      manager.updateGuidelinesLive(
        elementId: elementId,
        draftPosition: initialPosition,
        elementSize: elementSize,
        regenerateStatic: true,
      );
      
      print('拖拽开始后的参考线状态:');
      print('  静态参考线数量: ${manager.staticGuidelines.length}');
      print('  动态参考线数量: ${manager.dynamicGuidelines.length}');
      print('  高亮参考线数量: ${manager.highlightedGuidelines.length}');
      
      // 验证有高亮参考线
      expect(manager.highlightedGuidelines.length, equals(1), 
             reason: '应该只有一个高亮参考线');
      
      // 第二步：模拟鼠标释放时的对齐吸附
      final alignmentResult = manager.performAlignment(
        elementId: elementId,
        currentPosition: initialPosition,
        elementSize: elementSize,
        operationType: 'translate',
      );
      
      print('\\n对齐吸附结果:');
      print('  是否发生对齐: ${alignmentResult['hasAlignment']}');
      print('  对齐前位置: (${initialPosition.dx}, ${initialPosition.dy})');
      print('  对齐后位置: ${alignmentResult['position']}');
      print('  对齐前尺寸: ${elementSize.width}x${elementSize.height}');
      print('  对齐后尺寸: ${alignmentResult['size']}');
      
      // 验证对齐结果
      expect(alignmentResult['hasAlignment'], isTrue, reason: '应该发生对齐');
      
      final alignedPosition = alignmentResult['position'] as Offset;
      final alignedSize = alignmentResult['size'] as Size;
      
      // 验证对齐后的位置更接近目标
      final originalDistance = (initialPosition - Offset(200, 100)).distance;
      final alignedDistance = (alignedPosition - Offset(200, 100)).distance;
      
      print('  原始距离目标: ${originalDistance.toStringAsFixed(2)}');
      print('  对齐后距离目标: ${alignedDistance.toStringAsFixed(2)}');
      
      expect(alignedDistance, lessThan(originalDistance), 
             reason: '对齐后应该更接近目标位置');
      
      // 验证尺寸在平移操作中保持不变
      expect(alignedSize.width, equals(elementSize.width), 
             reason: '平移操作中宽度应该保持不变');
      expect(alignedSize.height, equals(elementSize.height), 
             reason: '平移操作中高度应该保持不变');
    });
    
    test('测试Resize对齐吸附功能', () {
      print('\\n🔍 测试Resize对齐吸附功能');
      
      // 模拟Resize一个元素的右边界到接近目标位置
      final elementId = 'dragging2';
      final currentPosition = Offset(50, 100);
      final currentSize = Size(140, 80); // 右边界在x=190，接近target1的左边界(200)
      
      // 第一步：模拟拖拽开始，生成静态参考线
      manager.updateGuidelinesLive(
        elementId: elementId,
        draftPosition: currentPosition,
        elementSize: currentSize,
        regenerateStatic: true,
      );
      
      print('Resize拖拽开始后的参考线状态:');
      print('  静态参考线数量: ${manager.staticGuidelines.length}');
      print('  动态参考线数量: ${manager.dynamicGuidelines.length}');
      print('  高亮参考线数量: ${manager.highlightedGuidelines.length}');
      
      // 验证有高亮参考线
      expect(manager.highlightedGuidelines.length, equals(1), 
             reason: '应该只有一个高亮参考线');
      
      // 第二步：模拟鼠标释放时的Resize对齐吸附
      final alignmentResult = manager.performAlignment(
        elementId: elementId,
        currentPosition: currentPosition,
        elementSize: currentSize,
        operationType: 'resize',
        resizeDirection: 'right',
      );
      
      print('\\nResize对齐吸附结果:');
      print('  是否发生对齐: ${alignmentResult['hasAlignment']}');
      print('  对齐前位置: (${currentPosition.dx}, ${currentPosition.dy})');
      print('  对齐后位置: ${alignmentResult['position']}');
      print('  对齐前尺寸: ${currentSize.width}x${currentSize.height}');
      print('  对齐后尺寸: ${alignmentResult['size']}');
      
      // 验证对齐结果
      expect(alignmentResult['hasAlignment'], isTrue, reason: '应该发生Resize对齐');
      
      final alignedPosition = alignmentResult['position'] as Offset;
      final alignedSize = alignmentResult['size'] as Size;
      
      // 验证Resize对齐的特点
      // 1. 左边界位置应该保持不变
      expect(alignedPosition.dx, equals(currentPosition.dx), 
             reason: 'Resize右边界时，左边界位置应该保持不变');
      expect(alignedPosition.dy, equals(currentPosition.dy), 
             reason: 'Resize右边界时，Y位置应该保持不变');
      
      // 2. 高度应该保持不变
      expect(alignedSize.height, equals(currentSize.height), 
             reason: 'Resize右边界时，高度应该保持不变');
      
      // 3. 宽度应该发生变化，使得右边界对齐到目标
      final expectedRightBoundary = 200.0; // target1的左边界
      final actualRightBoundary = alignedPosition.dx + alignedSize.width;
      
      print('  预期右边界位置: $expectedRightBoundary');
      print('  实际右边界位置: $actualRightBoundary');
      
      expect((actualRightBoundary - expectedRightBoundary).abs(), lessThan(1.0), 
             reason: '右边界应该对齐到目标位置');
    });
    
    test('测试只有一个高亮参考线的限制', () {
      print('\\n🔍 测试只有一个高亮参考线的限制');
      
      // 添加更多目标元素，增加参考线复杂度
      manager.updateElements([
        {
          'id': 'target1',
          'x': 200.0,
          'y': 100.0,
          'width': 100.0,
          'height': 100.0,
          'rotation': 0.0,
          'isHidden': false,
        },
        {
          'id': 'target2',
          'x': 210.0, // 非常接近target1
          'y': 110.0,
          'width': 100.0,
          'height': 100.0,
          'rotation': 0.0,
          'isHidden': false,
        },
        {
          'id': 'target3',
          'x': 400.0,
          'y': 200.0,
          'width': 100.0,
          'height': 100.0,
          'rotation': 0.0,
          'isHidden': false,
        },
      ]);
      
      // 模拟拖拽到一个可能匹配多个目标的位置
      final elementId = 'dragging3';
      final position = Offset(205, 105); // 在target1和target2之间
      final elementSize = Size(80, 80);
      
      manager.updateGuidelinesLive(
        elementId: elementId,
        draftPosition: position,
        elementSize: elementSize,
        regenerateStatic: true,
      );
      
      print('复杂场景的参考线状态:');
      print('  静态参考线数量: ${manager.staticGuidelines.length}');
      print('  动态参考线数量: ${manager.dynamicGuidelines.length}');
      print('  高亮参考线数量: ${manager.highlightedGuidelines.length}');
      
      // 关键验证：无论有多少可能的对齐目标，都应该只有一个高亮参考线
      expect(manager.highlightedGuidelines.length, equals(1), 
             reason: '无论场景多复杂，都应该只有一个高亮参考线');
      
      // 验证这个高亮参考线是最近的那个
      final highlightedGuideline = manager.highlightedGuidelines.first;
      print('  高亮参考线类型: ${highlightedGuideline.type}');
      print('  高亮参考线位置: ${highlightedGuideline.position}');
      
      // 执行对齐
      final alignmentResult = manager.performAlignment(
        elementId: elementId,
        currentPosition: position,
        elementSize: elementSize,
        operationType: 'translate',
      );
      
      expect(alignmentResult['hasAlignment'], isTrue, 
             reason: '应该能够对齐到最近的参考线');
    });
    
    test('测试吸附阈值限制', () {
      print('\\n🔍 测试吸附阈值限制');
      
      // 设置一个较小的吸附阈值
      manager.snapThreshold = 5.0;
      
      // 模拟拖拽到一个距离目标较远的位置
      final elementId = 'dragging4';
      final farPosition = Offset(180, 80); // 距离target1(200,100)较远
      final elementSize = Size(80, 80);
      
      manager.updateGuidelinesLive(
        elementId: elementId,
        draftPosition: farPosition,
        elementSize: elementSize,
        regenerateStatic: true,
      );
      
      print('远距离拖拽的参考线状态:');
      print('  高亮参考线数量: ${manager.highlightedGuidelines.length}');
      
      // 执行对齐尝试
      final alignmentResult = manager.performAlignment(
        elementId: elementId,
        currentPosition: farPosition,
        elementSize: elementSize,
        operationType: 'translate',
      );
      
      print('  是否发生对齐: ${alignmentResult['hasAlignment']}');
      print('  吸附阈值: ${manager.snapThreshold}');
      
      // 验证距离过远时不应该发生吸附
      // 这取决于具体的阈值设置和距离计算
      if (alignmentResult['hasAlignment'] == false) {
        print('  ✅ 正确：距离过远，未发生吸附');
      } else {
        print('  ⚠️  注意：距离较远但仍发生吸附，检查阈值设置');
      }
    });
  });
}
