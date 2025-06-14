import 'package:flutter/material.dart';
import 'lib/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';

void main() {
  print('🚀 开始调试Resize对齐');
  
  final manager = GuidelineManager.instance;
  manager.enabled = true;
  manager.updatePageSize(Size(800, 600));
  
  // 设置元素
  final elements = [
    {
      'id': 'element1',
      'x': 100.0,
      'y': 100.0,
      'width': 50.0,
      'height': 50.0,
      'rotation': 0.0,
    },
    {
      'id': 'element2', 
      'x': 95.0, 
      'y': 200.0,
      'width': 60.0,
      'height': 40.0,
      'rotation': 0.0,
    },
  ];
  
  manager.updateElements(elements);
  
  print('📍 更新参考线');
  manager.updateGuidelinesLive(
    elementId: 'element2',
    draftPosition: Offset(95.0, 200.0),
    elementSize: Size(60.0, 40.0),
    operationType: 'resize',
    resizeDirection: 'left',
  );
  
  print('📊 参考线状态:');
  print('  动态参考线: ${manager.dynamicGuidelines.length}');
  print('  静态参考线: ${manager.staticGuidelines.length}');
  print('  高亮参考线: ${manager.highlightedGuidelines.length}');
  
  for (final g in manager.highlightedGuidelines) {
    print('  高亮: ${g.id}, 类型: ${g.type}, 方向: ${g.direction}, 位置: ${g.position}');
  }
  
  print('🎯 执行对齐');
  final result = manager.performAlignment(
    elementId: 'element2',
    currentPosition: Offset(95.0, 200.0),
    elementSize: Size(60.0, 40.0),
    operationType: 'resize',
    resizeDirection: 'left',
  );
  
  print('📋 对齐结果:');
  print('  hasAlignment: ${result['hasAlignment']}');
  print('  position: ${result['position']}');
  print('  size: ${result['size']}');
  print('  alignmentInfo: ${result['alignmentInfo']}');
  
  print('🎉 调试完成');
}
