import 'package:flutter/material.dart';
import 'package:charasgem/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';

void main() {
  print('🚀 开始测试参考线吸附功能');

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

  // 3. 测试拖拽开始 - 设置拖拽状态
  print('\n📍 开始拖拽，设置拖拽状态');
  manager.isDragging = true;
  manager.draggingElementId = 'dragging_element';

  // 4. 测试拖拽过程中的实时参考线生成
  print('\n🔄 拖拽过程中 - 实时参考线生成');
  manager.updateGuidelinesLive(
    elementId: 'dragging_element',
    draftPosition: const Offset(105, 105), // 距离element1很近
    elementSize: const Size(50, 50),
  );

  print('动态参考线数量: ${manager.dynamicGuidelines.length}');
  print('静态参考线数量: ${manager.staticGuidelines.length}');
  print('高亮参考线数量: ${manager.highlightedGuidelines.length}');

  // 5. 测试拖拽结束时的吸附对齐
  print('\n🎯 拖拽结束 - 执行吸附对齐');
  final alignmentResult = manager.performAlignment(
    elementId: 'dragging_element',
    currentPosition: const Offset(105, 105),
    elementSize: const Size(50, 50),
  );

  print('吸附结果: ${alignmentResult['hasAlignment']}');
  print('原位置: (105, 105)');
  final alignedPosition = alignmentResult['position'] as Offset;
  print('吸附位置: (${alignedPosition.dx}, ${alignedPosition.dy})');
  
  if (alignmentResult['hasAlignment'] == true) {
    print('✅ 吸附成功！');
    print('位移距离: ${(alignedPosition - const Offset(105, 105)).distance.toStringAsFixed(2)} 像素');
  } else {
    print('❌ 没有发生吸附');
  }

  // 6. 拖拽结束后清理状态
  print('\n🧹 清理拖拽状态');
  manager.isDragging = false;
  manager.draggingElementId = null;
  manager.clearGuidelines();

  print('\n🎉 参考线吸附功能测试完成');

  // 7. 测试不同距离的吸附行为
  print('\n📐 测试不同距离的吸附行为');
  
  final testCases = [
    {'distance': 3.0, 'shouldSnap': true, 'description': '3像素距离（应该吸附）'},
    {'distance': 5.0, 'shouldSnap': true, 'description': '5像素距离（应该吸附）'},
    {'distance': 10.0, 'shouldSnap': false, 'description': '10像素距离（不应该吸附）'},
    {'distance': 15.0, 'shouldSnap': false, 'description': '15像素距离（不应该吸附）'},
  ];

  for (final testCase in testCases) {
    final distance = testCase['distance'] as double;
    final shouldSnap = testCase['shouldSnap'] as bool;
    final description = testCase['description'] as String;
    
    final testPosition = Offset(100.0 + distance, 100.0 + distance);
    
    manager.isDragging = true;
    manager.draggingElementId = 'test_element';
    
    manager.updateGuidelinesLive(
      elementId: 'test_element',
      draftPosition: testPosition,
      elementSize: const Size(50, 50),
    );
    
    final result = manager.performAlignment(
      elementId: 'test_element',
      currentPosition: testPosition,
      elementSize: const Size(50, 50),
    );
    
    final hasAlignment = result['hasAlignment'] as bool;
    final resultPosition = result['position'] as Offset;
    
    print('📊 $description');
    print('   测试位置: (${testPosition.dx}, ${testPosition.dy})');
    print('   结果位置: (${resultPosition.dx}, ${resultPosition.dy})');
    print('   发生吸附: $hasAlignment');
    print('   预期结果: $shouldSnap');
    print('   结果: ${hasAlignment == shouldSnap ? "✅ 正确" : "❌ 错误"}');
    print('');
    
    manager.isDragging = false;
    manager.draggingElementId = null;
    manager.clearGuidelines();
  }
}
