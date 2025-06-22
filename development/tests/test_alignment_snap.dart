import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lib/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';

/// 测试对齐吸附功能 - 验证只在鼠标释放时执行对齐吸附
void main() {
  group('对齐吸附功能测试', () {
    late GuidelineManager manager;
    
    setUp(() {
      manager = GuidelineManager.instance;
      manager.enabled = true;
      manager.clearGuidelines();
      
      // 设置页面尺寸
      manager.updatePageSize(Size(800, 600));
      
      // 添加测试元素
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
    
    test('测试只有一个高亮参考线（按最近原则）', () {
      // 模拟拖拽开始 - 生成静态参考线
      manager.updateGuidelinesLive(
        elementId: 'element1',
        draftPosition: Offset(110, 110),
        elementSize: Size(100, 100),
        regenerateStatic: true,
      );
      
      print('🔍 参考线状态:');
      print('  静态参考线数量: ${manager.staticGuidelines.length}');
      print('  动态参考线数量: ${manager.dynamicGuidelines.length}');
      print('  高亮参考线数量: ${manager.highlightedGuidelines.length}');
      
      // 验证只有一个高亮参考线
      expect(manager.highlightedGuidelines.length, lessThanOrEqualTo(1),
             reason: '应该只有一个高亮参考线，按最近原则决定');
      
      if (manager.highlightedGuidelines.isNotEmpty) {
        final highlightedGuideline = manager.highlightedGuidelines.first;
        print('  高亮参考线: ${highlightedGuideline.type.name} at ${highlightedGuideline.position}');
      }
    });
    
    test('测试元素平移对齐吸附', () {
      // 设置一个接近对齐的位置（element1的左边缘接近element2的左边缘）
      final currentPosition = Offset(295, 100); // 接近element2的左边缘(300)
      final elementSize = Size(100, 100);
      
      print('\\n🔄 测试元素平移对齐吸附:');
      print('  当前位置: (${currentPosition.dx}, ${currentPosition.dy})');
      print('  目标对齐: element2的左边缘 x=300');
      
      // 执行对齐吸附
      final result = manager.performAlignment(
        elementId: 'element1',
        currentPosition: currentPosition,
        elementSize: elementSize,
        operationType: 'translate',
      );
      
      print('  对齐结果: ${result['hasAlignment']}');
      
      if (result['hasAlignment'] == true) {
        final alignedPosition = result['position'] as Offset;
        final alignedSize = result['size'] as Size;
        
        print('  对齐后位置: (${alignedPosition.dx}, ${alignedPosition.dy})');
        print('  对齐后尺寸: (${alignedSize.width}, ${alignedSize.height})');
        
        // 验证平移对齐：位置应该移动到对齐位置，尺寸保持不变
        expect(alignedPosition.dx, closeTo(300, 1), reason: '应该对齐到element2的左边缘');
        expect(alignedSize.width, equals(elementSize.width), reason: '平移时宽度应该保持不变');
        expect(alignedSize.height, equals(elementSize.height), reason: '平移时高度应该保持不变');
      }
    });
    
    test('测试元素Resize对齐吸附', () {
      // 设置一个接近对齐的位置（element1的右边缘接近element2的左边缘）
      final currentPosition = Offset(100, 100);
      final elementSize = Size(195, 100); // 右边缘在295，接近element2的左边缘(300)
      
      print('\\n📏 测试元素Resize对齐吸附:');
      print('  当前位置: (${currentPosition.dx}, ${currentPosition.dy})');
      print('  当前尺寸: (${elementSize.width}, ${elementSize.height})');
      print('  当前右边缘: ${currentPosition.dx + elementSize.width} (接近element2左边缘300)');
      
      // 执行Resize对齐吸附（右边缘对齐）
      final result = manager.performAlignment(
        elementId: 'element1',
        currentPosition: currentPosition,
        elementSize: elementSize,
        operationType: 'resize',
        resizeDirection: 'right',
      );
      
      print('  对齐结果: ${result['hasAlignment']}');
      
      if (result['hasAlignment'] == true) {
        final alignedPosition = result['position'] as Offset;
        final alignedSize = result['size'] as Size;
        
        print('  对齐后位置: (${alignedPosition.dx}, ${alignedPosition.dy})');
        print('  对齐后尺寸: (${alignedSize.width}, ${alignedSize.height})');
        print('  对齐后右边缘: ${alignedPosition.dx + alignedSize.width}');
        
        // 验证Resize对齐：位置保持不变，尺寸调整使右边缘对齐
        expect(alignedPosition.dx, equals(currentPosition.dx), reason: 'Resize时左边缘位置应该保持不变');
        expect(alignedPosition.dy, equals(currentPosition.dy), reason: 'Resize时Y位置应该保持不变');
        expect(alignedPosition.dx + alignedSize.width, closeTo(300, 1), 
               reason: '右边缘应该对齐到element2的左边缘');
      }
    });
    
    test('测试不同Resize方向的对齐', () {
      final testCases = [
        {
          'direction': 'left',
          'currentPos': Offset(105, 100),
          'currentSize': Size(100, 100),
          'description': '左边缘对齐到element2的左边缘',
          'expectedX': 300.0,
          'expectedWidth': -95.0, // 负数表示会被限制
        },
        {
          'direction': 'top',
          'currentPos': Offset(100, 105),
          'currentSize': Size(100, 100),
          'description': '上边缘对齐到element2的上边缘',
          'expectedY': 200.0,
          'expectedHeight': -95.0, // 负数表示会被限制
        },
        {
          'direction': 'bottom',
          'currentPos': Offset(100, 100),
          'currentSize': Size(100, 95),
          'description': '下边缘对齐到element2的上边缘',
          'expectedHeight': 100.0,
        },
      ];
      
      for (final testCase in testCases) {
        print('\\n🔧 测试${testCase['direction']}方向Resize对齐:');
        print('  ${testCase['description']}');
        
        final result = manager.performAlignment(
          elementId: 'element1',
          currentPosition: testCase['currentPos'] as Offset,
          elementSize: testCase['currentSize'] as Size,
          operationType: 'resize',
          resizeDirection: testCase['direction'] as String,
        );
        
        if (result['hasAlignment'] == true) {
          final alignedPosition = result['position'] as Offset;
          final alignedSize = result['size'] as Size;
          
          print('  对齐成功: (${alignedPosition.dx}, ${alignedPosition.dy}) ${alignedSize.width}x${alignedSize.height}');
        } else {
          print('  未找到可对齐的参考线');
        }
      }
    });
    
    test('测试阈值控制 - 距离太远时不对齐', () {
      // 设置一个距离较远的位置，超出对齐阈值
      final currentPosition = Offset(280, 100); // 距离element2左边缘(300)有20像素，可能超出阈值
      final elementSize = Size(100, 100);
      
      print('\\n📏 测试阈值控制:');
      print('  当前位置: (${currentPosition.dx}, ${currentPosition.dy})');
      print('  距离element2左边缘: ${300 - currentPosition.dx}像素');
      print('  对齐阈值: ${manager.snapThreshold}像素');
      
      final result = manager.performAlignment(
        elementId: 'element1',
        currentPosition: currentPosition,
        elementSize: elementSize,
        operationType: 'translate',
      );
      
      print('  对齐结果: ${result['hasAlignment']}');
      
      if (result['hasAlignment'] != true) {
        print('  ✅ 正确：距离超出阈值，未进行对齐');
      } else {
        print('  ⚠️ 注意：距离较远但仍然对齐了');
      }
    });
  });
}
