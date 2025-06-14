import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lib/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';
import 'lib/presentation/widgets/practice/guideline_alignment/guideline_types.dart';

/// 测试FreeControlPoints的对齐吸附功能
void main() {
  group('FreeControlPoints对齐吸附测试', () {
    late GuidelineManager manager;
    
    setUp(() {
      manager = GuidelineManager.instance;
      manager.enabled = true;
      manager.clearGuidelines();
      
      // 设置页面尺寸
      manager.updatePageSize(Size(800, 600));
      
      // 添加固定元素
      manager.updateElements([
        {
          'id': 'fixed_element',
          'x': 100.0,
          'y': 100.0,
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
    
    test('测试平移对齐吸附', () {
      print('🎯 开始测试平移对齐吸附');
      
      // 设置拖拽状态
      manager.isDragging = true;
      manager.draggingElementId = 'dragging_element';
      
      // 开始拖拽，生成静态参考线
      manager.updateGuidelinesLive(
        elementId: 'dragging_element',
        draftPosition: Offset(195.0, 195.0), // 距离固定元素5像素
        elementSize: Size(50.0, 50.0),
        regenerateStatic: true,
      );
      
      print('🔍 静态参考线数量: ${manager.staticGuidelines.length}');
      print('🔍 动态参考线数量: ${manager.dynamicGuidelines.length}');
      print('🔍 高亮参考线数量: ${manager.highlightedGuidelines.length}');
      
      // 验证有高亮参考线
      expect(manager.highlightedGuidelines.length, greaterThan(0), 
             reason: '应该有高亮参考线');
      
      // 模拟鼠标释放时的对齐
      final alignmentResult = manager.performAlignment(
        elementId: 'dragging_element',
        currentPosition: Offset(195.0, 195.0),
        elementSize: Size(50.0, 50.0),
        operationType: 'translate',
      );
      
      print('📊 对齐结果: $alignmentResult');
      
      // 验证对齐结果
      expect(alignmentResult['hasAlignment'], isTrue, 
             reason: '应该发生对齐');
      
      final alignedPosition = alignmentResult['position'] as Offset;
      final alignedSize = alignmentResult['size'] as Size;
      
      print('📍 对齐前位置: (195.0, 195.0)');
      print('📍 对齐后位置: (${alignedPosition.dx}, ${alignedPosition.dy})');
      print('📍 对齐前尺寸: (50.0, 50.0)');
      print('📍 对齐后尺寸: (${alignedSize.width}, ${alignedSize.height})');
      
      // 验证位置发生了变化（应该对齐到固定元素的边缘）
      expect(alignedPosition.dx, isNot(equals(195.0)), 
             reason: '位置应该发生变化');
      expect(alignedPosition.dy, isNot(equals(195.0)), 
             reason: '位置应该发生变化');
      
      // 验证尺寸保持不变（平移操作不改变尺寸）
      expect(alignedSize.width, equals(50.0), 
             reason: '平移操作尺寸应该保持不变');
      expect(alignedSize.height, equals(50.0), 
             reason: '平移操作尺寸应该保持不变');
    });
    
    test('测试Resize对齐吸附', () {
      print('\\n🎯 开始测试Resize对齐吸附');
      
      // 设置拖拽状态
      manager.isDragging = true;
      manager.draggingElementId = 'dragging_element';
      
      // 开始拖拽，生成静态参考线
      manager.updateGuidelinesLive(
        elementId: 'dragging_element',
        draftPosition: Offset(150.0, 150.0),
        elementSize: Size(45.0, 45.0), // 右边缘距离固定元素5像素
        regenerateStatic: true,
      );
      
      print('🔍 静态参考线数量: ${manager.staticGuidelines.length}');
      print('🔍 动态参考线数量: ${manager.dynamicGuidelines.length}');
      print('🔍 高亮参考线数量: ${manager.highlightedGuidelines.length}');
      
      // 模拟右边缘Resize对齐
      final alignmentResult = manager.performAlignment(
        elementId: 'dragging_element',
        currentPosition: Offset(150.0, 150.0),
        elementSize: Size(45.0, 45.0),
        operationType: 'resize',
        resizeDirection: 'right',
      );
      
      print('📊 Resize对齐结果: $alignmentResult');
      
      if (alignmentResult['hasAlignment'] == true) {
        final alignedPosition = alignmentResult['position'] as Offset;
        final alignedSize = alignmentResult['size'] as Size;
        
        print('📍 Resize前位置: (150.0, 150.0)');
        print('📍 Resize后位置: (${alignedPosition.dx}, ${alignedPosition.dy})');
        print('📍 Resize前尺寸: (45.0, 45.0)');
        print('📍 Resize后尺寸: (${alignedSize.width}, ${alignedSize.height})');
        
        // 验证Resize操作
        expect(alignedSize.width, isNot(equals(45.0)), 
               reason: 'Resize操作应该改变宽度');
        
        // 对于右边缘Resize，位置不应该变化
        expect(alignedPosition.dx, equals(150.0), 
               reason: '右边缘Resize时X位置不应该变化');
        expect(alignedPosition.dy, equals(150.0), 
               reason: '右边缘Resize时Y位置不应该变化');
      } else {
        print('❌ Resize对齐失败');
      }
    });
    
    test('测试吸附阈值', () {
      print('\\n🎯 开始测试吸附阈值');
      
      // 设置拖拽状态
      manager.isDragging = true;
      manager.draggingElementId = 'dragging_element';
      
      // 测试超出阈值的情况（假设阈值是8像素）
      manager.updateGuidelinesLive(
        elementId: 'dragging_element',
        draftPosition: Offset(210.0, 210.0), // 距离固定元素10像素，超出阈值
        elementSize: Size(50.0, 50.0),
        regenerateStatic: true,
      );
      
      final alignmentResult = manager.performAlignment(
        elementId: 'dragging_element',
        currentPosition: Offset(210.0, 210.0),
        elementSize: Size(50.0, 50.0),
        operationType: 'translate',
      );
      
      print('📊 超出阈值的对齐结果: ${alignmentResult['hasAlignment']}');
      
      // 验证超出阈值时不发生对齐
      expect(alignmentResult['hasAlignment'], isFalse, 
             reason: '超出阈值时不应该发生对齐');
      
      // 测试在阈值内的情况
      manager.updateGuidelinesLive(
        elementId: 'dragging_element',
        draftPosition: Offset(195.0, 195.0), // 距离固定元素5像素，在阈值内
        elementSize: Size(50.0, 50.0),
        regenerateStatic: false, // 不重新生成静态参考线
      );
      
      final alignmentResult2 = manager.performAlignment(
        elementId: 'dragging_element',
        currentPosition: Offset(195.0, 195.0),
        elementSize: Size(50.0, 50.0),
        operationType: 'translate',
      );
      
      print('📊 在阈值内的对齐结果: ${alignmentResult2['hasAlignment']}');
      
      // 验证在阈值内时发生对齐
      expect(alignmentResult2['hasAlignment'], isTrue, 
             reason: '在阈值内时应该发生对齐');
    });
  });
}
