import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';
import 'lib/presentation/widgets/practice/guideline_alignment/guideline_types.dart';

void main() {
  test('测试FreeControlPoints对齐吸附流程', () {
    // 初始化GuidelineManager
    final manager = GuidelineManager.instance;
    manager.enabled = true;
    manager.clearGuidelines();
    
    // 设置页面大小
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
      }
    ]);
    
    print('🔍 固定元素: (100, 100) 100x100');
    
    // 模拟拖拽开始 - 生成静态参考线
    manager.updateGuidelinesLive(
      elementId: 'dragging_element',
      draftPosition: Offset(195, 195), // 距离固定元素右下5像素
      elementSize: Size(50, 50),
      regenerateStatic: true,
    );
    
    print('🔍 拖拽开始后:');
    print('  静态参考线数量: ${manager.staticGuidelines.length}');
    print('  动态参考线数量: ${manager.dynamicGuidelines.length}');
    print('  高亮参考线数量: ${manager.highlightedGuidelines.length}');
    print('  总参考线数量: ${manager.activeGuidelines.length}');
    
    // 检查高亮参考线
    if (manager.highlightedGuidelines.isNotEmpty) {
      final highlighted = manager.highlightedGuidelines.first;
      print('🔍 高亮参考线: ${highlighted.direction} at ${highlighted.position}');
    }
    
    // 模拟鼠标释放时的对齐
    final alignmentResult = manager.performAlignment(
      elementId: 'dragging_element',
      currentPosition: Offset(195, 195),
      elementSize: Size(50, 50),
      operationType: 'translate',
    );
    
    print('🔍 对齐结果:');
    print('  hasAlignment: ${alignmentResult['hasAlignment']}');
    print('  原始位置: (195, 195)');
    print('  对齐后位置: ${alignmentResult['position']}');
    print('  原始尺寸: 50x50');
    print('  对齐后尺寸: ${alignmentResult['size']}');
    
    // 验证对齐效果
    expect(alignmentResult['hasAlignment'], isTrue, reason: '应该发生对齐');
    
    final alignedPosition = alignmentResult['position'] as Offset;
    expect(alignedPosition.dx, equals(200.0), reason: '应该对齐到右边缘');
    expect(alignedPosition.dy, equals(200.0), reason: '应该对齐到下边缘');
  });
}
