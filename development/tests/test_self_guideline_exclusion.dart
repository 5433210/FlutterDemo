import 'package:flutter/material.dart';
import 'lib/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';

void main() {
  testSelfGuidelineExclusion();
}

/// 测试被拖拽元素自身的参考线不参与高亮竞选
void testSelfGuidelineExclusion() {
  print('🧪 开始测试：被拖拽元素自身参考线不参与高亮竞选');

  final manager = GuidelineManager.instance;
    // 初始化
  manager.initialize(
    pageSize: const Size(800, 600),
    enabled: true,
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
  );
  
  manager.enabled = true;
  manager.isDragging = true;
  manager.draggingElementId = 'element1';

  // 模拟拖拽 element1，使其接近自身原位置（这应该不会产生高亮）
  print('\n📍 测试场景1：拖拽元素接近自身原位置');
  manager.updateGuidelinesLive(
    elementId: 'element1',
    draftPosition: const Offset(105, 105), // 稍微偏移
    elementSize: const Size(50, 50),
    regenerateStatic: true,
    operationType: 'translate',
  );

  final highlightedGuidelines = manager.highlightedGuidelines;
  print('高亮参考线数量: ${highlightedGuidelines.length}');
  
  for (final guideline in highlightedGuidelines) {
    print('- 高亮参考线: ${guideline.id}, 来源元素: ${guideline.sourceElementId}');
    if (guideline.sourceElementId == 'element1') {
      print('❌ 错误：element1自身的参考线被高亮了！');
    }
  }

  // 测试场景2：拖拽 element1 接近 element2，这应该产生高亮
  print('\n📍 测试场景2：拖拽元素接近其他元素');
  manager.updateGuidelinesLive(
    elementId: 'element1',
    draftPosition: const Offset(195, 195), // 接近 element2
    elementSize: const Size(50, 50),
    regenerateStatic: false,
    operationType: 'translate',
  );

  final highlightedGuidelines2 = manager.highlightedGuidelines;
  print('高亮参考线数量: ${highlightedGuidelines2.length}');
  
  bool hasElement2Guidelines = false;
  bool hasElement1Guidelines = false;
  
  for (final guideline in highlightedGuidelines2) {
    print('- 高亮参考线: ${guideline.id}, 来源元素: ${guideline.sourceElementId}');
    if (guideline.sourceElementId == 'element2') {
      hasElement2Guidelines = true;
    }
    if (guideline.sourceElementId == 'element1') {
      hasElement1Guidelines = true;
      print('❌ 错误：element1自身的参考线被高亮了！');
    }
  }

  if (hasElement2Guidelines && !hasElement1Guidelines) {
    print('✅ 正确：只有element2的参考线被高亮，element1自身的参考线被正确排除');
  }

  // 测试Resize模式
  print('\n📍 测试场景3：Resize模式下的自身排除');
  manager.updateGuidelinesLive(
    elementId: 'element1',
    draftPosition: const Offset(195, 195),
    elementSize: const Size(55, 50), // 稍微调整大小
    regenerateStatic: false,
    operationType: 'resize',
    resizeDirection: 'right',
  );

  final highlightedGuidelines3 = manager.highlightedGuidelines;
  print('Resize模式高亮参考线数量: ${highlightedGuidelines3.length}');
  
  bool hasElement1InResize = false;
  for (final guideline in highlightedGuidelines3) {
    print('- 高亮参考线: ${guideline.id}, 来源元素: ${guideline.sourceElementId}');
    if (guideline.sourceElementId == 'element1') {
      hasElement1InResize = true;
      print('❌ 错误：Resize模式下element1自身的参考线被高亮了！');
    }
  }

  if (!hasElement1InResize) {
    print('✅ 正确：Resize模式下element1自身的参考线被正确排除');
  }

  print('\n🎯 测试完成');
}
