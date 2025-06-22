import 'package:flutter/material.dart';

import 'lib/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';

void main() {
  print('🧪 测试参考线显示过滤功能');

  // 初始化 GuidelineManager
  final manager = GuidelineManager.instance;
  manager.initialize(
    elements: [
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
        'width': 50.0,
        'height': 50.0,
        'isHidden': false,
      },
    ],
    pageSize: const Size(800, 600),
    enabled: true,
  );

  print('\n📍 Step 1: 非拖拽状态 - 应该没有参考线');
  manager.isDragging = false;
  var guidelines = manager.activeGuidelines;
  print('活动参考线数量: ${guidelines.length}');

  print('\n📍 Step 2: 开始拖拽 - 生成动态参考线和静态参考线');
  manager.isDragging = true;
  manager.updateGuidelinesLive(
    elementId: 'dragging_element',
    draftPosition: const Offset(105, 105), // 接近element1，应该产生高亮参考线
    elementSize: const Size(40, 40),
    regenerateStatic: true,
    operationType: 'translate',
  );

  print('\n📊 拖拽中的参考线状态:');
  print('- 动态参考线: ${manager.dynamicGuidelines.length}');
  print('- 静态参考线: ${manager.staticGuidelines.length}');
  print('- 高亮参考线: ${manager.highlightedGuidelines.length}');
  print('- 活动参考线 (应该只有高亮): ${manager.activeGuidelines.length}');

  if (manager.highlightedGuidelines.isNotEmpty) {
    print('\n✨ 高亮参考线详情:');
    for (var guideline in manager.highlightedGuidelines) {
      print('  - ${guideline.id}: ${guideline.type} at ${guideline.position}');
    }
  }

  // 验证在拖拽过程中，activeGuidelines 只包含高亮参考线
  final activeCount = manager.activeGuidelines.length;
  final highlightedCount = manager.highlightedGuidelines.length;

  if (activeCount == highlightedCount) {
    print('\n✅ 测试通过：拖拽过程中只显示高亮参考线');
    print('   活动参考线数量 ($activeCount) = 高亮参考线数量 ($highlightedCount)');
  } else {
    print('\n❌ 测试失败：拖拽过程中显示了多余的参考线');
    print('   活动参考线数量: $activeCount');
    print('   高亮参考线数量: $highlightedCount');
  }

  print('\n📍 Step 3: 结束拖拽 - 清除所有参考线');
  manager.isDragging = false;
  manager.clearGuidelines();
  guidelines = manager.activeGuidelines;
  print('结束拖拽后参考线数量: ${guidelines.length}');

  print('\n🎯 测试完成');
}
