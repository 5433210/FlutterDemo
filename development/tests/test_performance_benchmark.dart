import 'package:flutter/material.dart';
import 'lib/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';

/// 性能基准测试 - 比较优化前后的性能差异
void main() {
  print('=== 静态参考线优化性能基准测试 ===\n');
  
  // 设置测试环境
  _setupTestEnvironment();
  
  // 测试1：拖拽开始时的性能（包含静态参考线生成）
  _benchmarkDragStart();
  
  // 测试2：拖拽过程中的性能（优化前 vs 优化后）
  _benchmarkDragProcess();
  
  // 测试3：大量元素时的性能差异
  _benchmarkLargeDataset();
  
  print('\n=== 性能基准测试完成 ===');
}

void _setupTestEnvironment() {
  print('设置测试环境...');
  
  GuidelineManager.instance.enabled = true;
  GuidelineManager.instance.updatePageSize(Size(1200, 800));
  
  // 添加中等数量的测试元素
  final elements = List.generate(10, (i) => {
    'id': 'element_$i',
    'x': 50.0 + (i * 120),
    'y': 50.0 + (i % 3) * 150,
    'width': 80.0 + (i % 4) * 20,
    'height': 60.0 + (i % 3) * 20,
    'rotation': 0.0,
    'isHidden': false,
  });
  
  GuidelineManager.instance.updateElements(elements);
  print('✅ 添加了 ${elements.length} 个测试元素\n');
}

void _benchmarkDragStart() {
  print('📊 基准测试1: 拖拽开始时的性能（包含静态参考线生成）');
  
  final dragElementId = 'element_0';
  final position = Offset(100, 100);
  final size = Size(100, 60);
  final iterations = 50;
  
  var totalTime = 0;
  var staticCount = 0;
  var dynamicCount = 0;
  
  print('   执行 $iterations 次拖拽开始操作...');
  
  for (int i = 0; i < iterations; i++) {
    // 清除状态
    GuidelineManager.instance.clearGuidelines();
    
    final stopwatch = Stopwatch()..start();
    GuidelineManager.instance.updateGuidelinesLive(
      elementId: dragElementId,
      draftPosition: position,
      elementSize: size,
      regenerateStatic: true, // 拖拽开始：重新生成静态参考线
    );
    stopwatch.stop();
    
    totalTime += stopwatch.elapsedMicroseconds;
    
    if (i == 0) {
      staticCount = GuidelineManager.instance.staticGuidelines.length;
      dynamicCount = GuidelineManager.instance.dynamicGuidelines.length;
    }
  }
  
  final averageTime = totalTime / iterations;
  
  print('   结果:');
  print('     - 平均时间: ${averageTime.toStringAsFixed(1)}μs');
  print('     - 生成静态参考线: $staticCount 条');
  print('     - 生成动态参考线: $dynamicCount 条');
  print('     - 总时间: ${(totalTime / 1000).toStringAsFixed(1)}ms\n');
}

void _benchmarkDragProcess() {
  print('📊 基准测试2: 拖拽过程中的性能（优化前 vs 优化后）');
  
  final dragElementId = 'element_0';
  final size = Size(100, 60);
  final iterations = 100;
  
  // 先设置拖拽开始状态
  GuidelineManager.instance.updateGuidelinesLive(
    elementId: dragElementId,
    draftPosition: Offset(100, 100),
    elementSize: size,
    regenerateStatic: true,
  );
  
  print('   测试 $iterations 次拖拽更新操作...');
  
  // 测试优化前的性能（每次都重新生成静态参考线）
  var totalTimeOld = 0;
  for (int i = 0; i < iterations; i++) {
    final position = Offset(100 + i * 2.0, 100 + i * 1.0);
    
    final stopwatch = Stopwatch()..start();
    GuidelineManager.instance.updateGuidelinesLive(
      elementId: dragElementId,
      draftPosition: position,
      elementSize: size,
      regenerateStatic: true, // 模拟优化前：每次都重新生成
    );
    stopwatch.stop();
    
    totalTimeOld += stopwatch.elapsedMicroseconds;
  }
  
  // 重置状态
  GuidelineManager.instance.updateGuidelinesLive(
    elementId: dragElementId,
    draftPosition: Offset(100, 100),
    elementSize: size,
    regenerateStatic: true,
  );
  
  // 测试优化后的性能（不重新生成静态参考线）
  var totalTimeNew = 0;
  for (int i = 0; i < iterations; i++) {
    final position = Offset(100 + i * 2.0, 100 + i * 1.0);
    
    final stopwatch = Stopwatch()..start();
    GuidelineManager.instance.updateGuidelinesLive(
      elementId: dragElementId,
      draftPosition: position,
      elementSize: size,
      regenerateStatic: false, // 🔧 优化后：不重新生成静态参考线
    );
    stopwatch.stop();
    
    totalTimeNew += stopwatch.elapsedMicroseconds;
  }
  
  final averageTimeOld = totalTimeOld / iterations;
  final averageTimeNew = totalTimeNew / iterations;
  final speedupRatio = averageTimeOld / averageTimeNew;
  final timeSavedMs = (totalTimeOld - totalTimeNew) / 1000;
  
  print('   结果:');
  print('     - 优化前平均时间: ${averageTimeOld.toStringAsFixed(1)}μs');
  print('     - 优化后平均时间: ${averageTimeNew.toStringAsFixed(1)}μs');
  print('     - 性能提升倍数: ${speedupRatio.toStringAsFixed(1)}x');
  print('     - 节省时间: ${timeSavedMs.toStringAsFixed(1)}ms');
  
  if (speedupRatio > 1.5) {
    print('     ✅ 显著的性能提升！');
  } else if (speedupRatio > 1.1) {
    print('     ✅ 有效的性能提升');
  } else {
    print('     ⚠️  性能提升不明显');
  }
  print('');
}

void _benchmarkLargeDataset() {
  print('📊 基准测试3: 大量元素情况下的性能差异');
  
  // 添加更多元素
  final largeElements = List.generate(50, (i) => {
    'id': 'large_element_$i',
    'x': (i % 10) * 120.0,
    'y': (i ~/ 10) * 100.0,
    'width': 80.0,
    'height': 60.0,
    'rotation': 0.0,
    'isHidden': false,
  });
  
  GuidelineManager.instance.updateElements(largeElements);
  
  final dragElementId = 'large_element_0';
  final size = Size(80, 60);
  final iterations = 20;
  
  print('   使用 ${largeElements.length} 个元素，执行 $iterations 次测试...');
  
  // 优化前性能
  var totalTimeOld = 0;
  for (int i = 0; i < iterations; i++) {
    final position = Offset(100 + i * 5.0, 100 + i * 3.0);
    
    final stopwatch = Stopwatch()..start();
    GuidelineManager.instance.updateGuidelinesLive(
      elementId: dragElementId,
      draftPosition: position,
      elementSize: size,
      regenerateStatic: true,
    );
    stopwatch.stop();
    
    totalTimeOld += stopwatch.elapsedMicroseconds;
  }
  
  // 重置并测试优化后性能
  GuidelineManager.instance.updateGuidelinesLive(
    elementId: dragElementId,
    draftPosition: Offset(100, 100),
    elementSize: size,
    regenerateStatic: true,
  );
  
  var totalTimeNew = 0;
  for (int i = 0; i < iterations; i++) {
    final position = Offset(100 + i * 5.0, 100 + i * 3.0);
    
    final stopwatch = Stopwatch()..start();
    GuidelineManager.instance.updateGuidelinesLive(
      elementId: dragElementId,
      draftPosition: position,
      elementSize: size,
      regenerateStatic: false,
    );
    stopwatch.stop();
    
    totalTimeNew += stopwatch.elapsedMicroseconds;
  }
  
  final averageTimeOld = totalTimeOld / iterations;
  final averageTimeNew = totalTimeNew / iterations;
  final speedupRatio = averageTimeOld / averageTimeNew;
  final staticCount = GuidelineManager.instance.staticGuidelines.length;
  
  print('   结果:');
  print('     - 生成的静态参考线数量: $staticCount 条');
  print('     - 优化前平均时间: ${averageTimeOld.toStringAsFixed(1)}μs');
  print('     - 优化后平均时间: ${averageTimeNew.toStringAsFixed(1)}μs');
  print('     - 性能提升倍数: ${speedupRatio.toStringAsFixed(1)}x');
  print('     - 总节省时间: ${((totalTimeOld - totalTimeNew) / 1000).toStringAsFixed(1)}ms');
  
  if (speedupRatio > 2.0) {
    print('     🚀 在大数据集下有显著的性能提升！');
  } else if (speedupRatio > 1.5) {
    print('     ✅ 在大数据集下有明显的性能提升');
  } else {
    print('     ⚠️  在大数据集下性能提升有限');
  }
}
