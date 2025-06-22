import 'package:flutter/material.dart';
import 'lib/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';

void main() {
  print('测试GuidelineManager的updateElementPosition方法...');
    // 初始化GuidelineManager
  final manager = GuidelineManager.instance;
  manager.initialize(
    enabled: true,
    pageSize: const Size(800, 600),
    elements: [
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
        'x': 200.0,
        'y': 200.0,
        'width': 60.0,
        'height': 40.0,
        'rotation': 0.0,
      },
    ],
  );

  print('✅ 初始化完成');
  print('📊 初始静态参考线数量: ${manager.staticGuidelines.length}');
  
  // 测试更新元素位置
  print('\n🔄 测试更新element1位置...');
  manager.updateElementPosition(
    elementId: 'element1',
    position: const Offset(150, 120),
    size: const Size(50, 50),
  );
  
  print('📊 更新后静态参考线数量: ${manager.staticGuidelines.length}');
    // 验证元素信息是否已更新
  final updatedElements = manager.elements;
  final element1 = updatedElements.firstWhere((e) => e['id'] == 'element1');
  print('📍 element1的新位置: (${element1['x']}, ${element1['y']})');
  
  if (element1['x'] == 150.0 && element1['y'] == 120.0) {
    print('✅ 元素位置更新成功');
  } else {
    print('❌ 元素位置更新失败');
  }
  
  // 测试拖拽状态下的行为
  print('\n🔄 测试拖拽状态下的行为...');
  manager.isDragging = true;
  manager.draggingElementId = 'element2';
  
  final beforeCount = manager.staticGuidelines.length;
  manager.updateElementPosition(
    elementId: 'element2',
    position: const Offset(250, 220),
    size: const Size(60, 40),
  );
  
  print('📊 拖拽状态下，静态参考线数量变化: $beforeCount -> ${manager.staticGuidelines.length}');
  if (manager.staticGuidelines.length == beforeCount) {
    print('✅ 拖拽状态下正确跳过了静态参考线重计算');
  } else {
    print('❌ 拖拽状态下不应该重计算静态参考线');
  }
  
  // 结束拖拽，测试是否重新计算
  manager.isDragging = false;
  manager.draggingElementId = null;
  manager.updateElementPosition(
    elementId: 'element2',
    position: const Offset(260, 230),
    size: const Size(60, 40),
  );
  
  print('📊 结束拖拽后，静态参考线数量: ${manager.staticGuidelines.length}');
  print('✅ 所有测试完成');
}
