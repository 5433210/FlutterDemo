// 参考线对齐功能测试
// 本文件用于验证新实现的参考线对齐系统

import 'package:flutter/material.dart';
import 'package:charasgem/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';
import 'package:charasgem/presentation/widgets/practice/guideline_alignment/guideline_types.dart';

void main() {
  // 测试参考线对齐功能
  testGuidelineAlignment();
}

void testGuidelineAlignment() {
  print('🚀 开始测试参考线对齐功能');

  // 1. 初始化 GuidelineManager
  final manager = GuidelineManager.instance;
  manager.enabled = true;
  manager.snapThreshold = 8.0;
  manager.updatePageSize(const Size(800, 600));

  // 2. 模拟页面元素
  final mockElements = [
    {
      'id': 'element1',
      'x': 100.0,
      'y': 100.0,
      'width': 50.0,
      'height': 50.0,
      'isHidden': false,
    },
    {
      'id': 'element2',
      'x': 200.0,
      'y': 200.0,
      'width': 60.0,
      'height': 40.0,
      'isHidden': false,
    },
  ];

  manager.updateElements(mockElements);
  print('✅ 页面元素已更新: ${mockElements.length} 个元素');

  // 3. 测试动态参考线生成
  print('\n📍 测试动态参考线生成');
  manager.updateGuidelinesLive(
    elementId: 'dragging_element',
    draftPosition: const Offset(105, 105),
    elementSize: const Size(50, 50),
  );

  print('动态参考线数量: ${manager.dynamicGuidelines.length}');
  print('静态参考线数量: ${manager.staticGuidelines.length}');
  print('高亮参考线数量: ${manager.highlightedGuidelines.length}');
  
  // 详细分析静态参考线
  print('\n🔍 静态参考线详细分析:');
  final pageGuidelineCount = manager.staticGuidelines.where((g) => g.sourceElementId == 'page').length;
  final element1GuidelineCount = manager.staticGuidelines.where((g) => g.sourceElementId == 'element1').length;
  final element2GuidelineCount = manager.staticGuidelines.where((g) => g.sourceElementId == 'element2').length;
  
  print('页面边界参考线: $pageGuidelineCount 条');
  print('element1参考线: $element1GuidelineCount 条');
  print('element2参考线: $element2GuidelineCount 条');
  print('总计: ${pageGuidelineCount + element1GuidelineCount + element2GuidelineCount} 条');
  
  // 列出所有静态参考线的ID
  print('\n📋 所有静态参考线:');
  for (final guideline in manager.staticGuidelines) {
    print('  - ${guideline.id} (来源: ${guideline.sourceElementId})');
  }

  // 4. 测试对齐吸附
  print('\n🎯 测试对齐吸附');
  final alignmentResult = manager.performAlignment(
    elementId: 'dragging_element',
    currentPosition: const Offset(105, 105),
    elementSize: const Size(50, 50),
  );

  if (alignmentResult['hasAlignment'] == true) {
    final alignedPosition = alignmentResult['position'] as Offset;
    print('✅ 对齐成功');
    print('原位置: (105, 105)');
    print('对齐位置: (${alignedPosition.dx}, ${alignedPosition.dy})');
    print('对齐信息: ${alignmentResult['alignmentInfo']}');
  } else {
    print('❌ 未检测到对齐');
  }

  // 5. 测试调试信息
  print('\n📊 系统状态:');
  final debugInfo = manager.getDebugInfo();
  debugInfo.forEach((key, value) {
    print('$key: $value');
  });

  print('\n🎉 参考线对齐功能测试完成');
}
