# M3PracticeEditCanvas 性能测试计划

## 测试概述

本文档详细描述了 M3PracticeEditCanvas 混合优化策略重构的性能测试计划，包括基准测试、回归测试、压力测试等，确保重构后的性能提升能够量化验证。

## 测试目标

### 主要目标

- 验证60FPS流畅交互目标达成
- 确保内存使用稳定可控
- 验证大量元素场景性能
- 保证功能完整性不受影响

### 性能基准

| 指标类型 | 目标值 | 测试条件 |
|---------|--------|---------|
| 拖拽帧率 | ≥55 FPS | 100个元素同时拖拽 |
| 交互延迟 | ≤20ms | 控制点操作响应 |
| 内存增长 | 线性可控 | 1小时连续操作 |
| 冷启动 | ≤200ms | 首次页面加载 |

## 测试环境

### 设备配置

```yaml
高性能设备:
  - iPhone 13 Pro / iPad Pro
  - Samsung Galaxy S21+
  - 目标: 60FPS稳定运行

中等性能设备:
  - iPhone 11 / iPad Air
  - Samsung Galaxy A52
  - 目标: 55FPS基本流畅

低性能设备:
  - iPhone SE 2020 / iPad 8th
  - 低端Android设备
  - 目标: 45FPS可用体验
```

### 测试数据

```yaml
元素数量场景:
  - 轻量: 10-50个元素
  - 中等: 50-150个元素  
  - 重量: 150-300个元素
  - 极限: 300-500个元素

操作类型:
  - 单元素拖拽
  - 多元素批量拖拽
  - 选择框操作
  - 缩放旋转操作
  - 属性面板更新
```

## 测试用例设计

### 1. 拖拽性能测试

#### TC-001: 单元素拖拽性能

```dart
class SingleElementDragTest {
  static Future<TestResult> runTest() async {
    final testPage = createTestPage(elementCount: 100);
    final targetElement = testPage.elements.first;
    
    // 开始性能监控
    final monitor = PerformanceMonitor();
    monitor.startRecording();
    
    // 执行5秒拖拽操作
    await simulateDrag(
      elementId: targetElement.id,
      duration: Duration(seconds: 5),
      path: _createSmoothDragPath(),
    );
    
    final result = monitor.stopRecording();
    
    // 验证性能指标
    expect(result.averageFPS, greaterThan(55));
    expect(result.droppedFrames, lessThan(5));
    expect(result.maxFrameTime.inMilliseconds, lessThan(20));
    
    return result;
  }
}
```

#### TC-002: 批量元素拖拽性能

```dart
class BatchElementDragTest {
  static Future<TestResult> runTest() async {
    final testPage = createTestPage(elementCount: 200);
    final selectedElements = testPage.elements.take(50).toList();
    
    final monitor = PerformanceMonitor();
    monitor.startRecording();
    
    // 批量选择并拖拽
    await simulateMultiSelect(selectedElements.map((e) => e.id).toList());
    await simulateBatchDrag(
      elementIds: selectedElements.map((e) => e.id).toList(),
      duration: Duration(seconds: 5),
      path: _createComplexDragPath(),
    );
    
    final result = monitor.stopRecording();
    
    // 批量操作性能要求
    expect(result.averageFPS, greaterThan(50));
    expect(result.memoryDelta, lessThan(10)); // MB
    
    return result;
  }
}
```

### 2. 内存稳定性测试

#### TC-003: 长时间操作内存测试

```dart
class LongTermMemoryTest {
  static Future<MemoryReport> runTest() async {
    final memorySnapshots = <DateTime, MemorySnapshot>[];
    final operations = [
      OperationType.drag,
      OperationType.select,
      OperationType.scale,
      OperationType.rotate,
      OperationType.add,
      OperationType.delete,
    ];
    
    final startTime = DateTime.now();
    
    // 运行1小时随机操作
    while (DateTime.now().difference(startTime).inHours < 1) {
      final operation = operations[Random().nextInt(operations.length)];
      
      // 执行随机操作
      await _performRandomOperation(operation);
      
      // 记录内存快照
      final snapshot = await MemoryProfiler.takeSnapshot();
      memorySnapshots[DateTime.now()] = snapshot;
      
      await Future.delayed(Duration(seconds: 30));
    }
    
    final report = MemoryReport(memorySnapshots);
    
    // 验证内存稳定性
    expect(report.memoryGrowthRate, lessThan(0.1)); // 每小时增长<10%
    expect(report.hasMemoryLeaks, isFalse);
    
    return report;
  }
}
```

### 3. 响应时间测试

#### TC-004: 交互响应时间测试

```dart
class InteractionResponseTest {
  static Future<ResponseReport> runTest() async {
    final operations = {
      'element_select': () => _simulateElementSelect(),
      'control_point': () => _simulateControlPointDrag(),
      'selection_box': () => _simulateSelectionBox(),
      'property_update': () => _simulatePropertyUpdate(),
    };
    
    final results = <String, List<Duration>>{};
    
    for (final entry in operations.entries) {
      final responseTimes = <Duration>[];
      
      // 每个操作测试100次
      for (int i = 0; i < 100; i++) {
        final stopwatch = Stopwatch()..start();
        await entry.value();
        stopwatch.stop();
        
        responseTimes.add(stopwatch.elapsed);
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      results[entry.key] = responseTimes;
    }
    
    final report = ResponseReport(results);
    
    // 验证响应时间
    expect(report.averageResponseTime('element_select').inMilliseconds, lessThan(20));
    expect(report.percentile90('control_point').inMilliseconds, lessThan(25));
    
    return report;
  }
}
```

### 4. 压力测试

#### TC-005: 大量元素压力测试

```dart
class StressTest {
  static Future<StressReport> runTest() async {
    final elementCounts = [100, 200, 300, 400, 500];
    final results = <int, PerformanceMetrics>{};
    
    for (final count in elementCounts) {
      // 创建大量元素场景
      final testPage = createStressTestPage(elementCount: count);
      
      final monitor = PerformanceMonitor();
      monitor.startRecording();
      
      // 执行复合操作序列
      await _performStressOperations(testPage);
      
      final metrics = monitor.stopRecording();
      results[count] = metrics;
      
      // 清理场景
      await _cleanupTestPage(testPage);
    }
    
    final report = StressReport(results);
    
    // 验证压力测试结果
    expect(report.getMetrics(500).averageFPS, greaterThan(45));
    expect(report.isPerformanceDegrading(), isFalse);
    
    return report;
  }
}
```

## 性能监控工具

### 实时监控组件

```dart
class PerformanceMonitor {
  final List<FrameMetrics> _frameHistory = [];
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _monitoringTimer;
  
  void startRecording() {
    _stopwatch.start();
    _frameHistory.clear();
    
    _monitoringTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      _recordFrame();
    });
  }
  
  PerformanceResult stopRecording() {
    _stopwatch.stop();
    _monitoringTimer?.cancel();
    
    return PerformanceResult(_frameHistory, _stopwatch.elapsed);
  }
  
  void _recordFrame() {
    final frameMetrics = FrameMetrics(
      timestamp: DateTime.now(),
      renderTime: _measureRenderTime(),
      memoryUsage: _getCurrentMemoryUsage(),
    );
    
    _frameHistory.add(frameMetrics);
    
    // 保持滑动窗口
    if (_frameHistory.length > 300) {
      _frameHistory.removeAt(0);
    }
  }
}
```

### 内存分析器

```dart
class MemoryProfiler {
  static Future<MemorySnapshot> takeSnapshot() async {
    final vm = await VMService.connect();
    final isolate = await vm.getMainIsolate();
    
    final heapUsage = await isolate.getHeapUsage();
    final objectCounts = await isolate.getObjectCounts();
    
    return MemorySnapshot(
      timestamp: DateTime.now(),
      heapUsed: heapUsage.used,
      heapCapacity: heapUsage.capacity,
      objectCounts: objectCounts,
    );
  }
  
  static MemoryReport analyzeSnapshots(List<MemorySnapshot> snapshots) {
    final growthRate = _calculateGrowthRate(snapshots);
    final leakDetection = _detectMemoryLeaks(snapshots);
    
    return MemoryReport(
      snapshots: snapshots,
      growthRate: growthRate,
      hasLeaks: leakDetection.hasLeaks,
      suspiciousObjects: leakDetection.suspiciousObjects,
    );
  }
}
```

## 自动化测试流程

### CI/CD集成

```yaml
# .github/workflows/performance_test.yml
name: Performance Test

on:
  pull_request:
    paths:
      - 'lib/presentation/pages/practices/widgets/**'
      - 'lib/presentation/widgets/practice/**'

jobs:
  performance_test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      
    - name: Run Performance Tests
      run: |
        flutter test test/performance/
        flutter test integration_test/performance_test.dart
        
    - name: Upload Performance Report
      uses: actions/upload-artifact@v3
      with:
        name: performance-report
        path: test_results/performance/
```

### 性能回归检测

```dart
class PerformanceRegressionDetector {
  static Future<void> checkRegression() async {
    final baseline = await _loadBaseline();
    final current = await _runCurrentTests();
    
    final regressions = _detectRegressions(baseline, current);
    
    if (regressions.isNotEmpty) {
      final report = _generateRegressionReport(regressions);
      await _sendAlert(report);
      throw Exception('Performance regression detected');
    }
  }
  
  static List<Regression> _detectRegressions(
    PerformanceBaseline baseline,
    PerformanceResult current,
  ) {
    final regressions = <Regression>[];
    
    // FPS回归检测
    if (current.averageFPS < baseline.averageFPS * 0.9) {
      regressions.add(Regression(
        type: RegressionType.fps,
        baseline: baseline.averageFPS,
        current: current.averageFPS,
        threshold: 0.9,
      ));
    }
    
    // 响应时间回归检测
    if (current.averageResponseTime > baseline.averageResponseTime * 1.2) {
      regressions.add(Regression(
        type: RegressionType.responseTime,
        baseline: baseline.averageResponseTime,
        current: current.averageResponseTime,
        threshold: 1.2,
      ));
    }
    
    return regressions;
  }
}
```

## 测试执行计划

### 阶段性测试计划

#### 第1-2周：基础架构测试

- 分层渲染正确性验证
- 状态管理分离测试
- 基础性能基准建立

#### 第3-4周：核心功能测试

- 拖拽操作性能测试
- 缓存系统效率测试
- 手势处理准确性测试

#### 第5-6周：性能优化测试

- 自适应调优效果测试
- 内存管理稳定性测试
- 极限场景压力测试

#### 第7-8周：全面回归测试

- 功能完整性回归测试
- 性能指标达成验证
- 用户体验测试

### 测试报告模板

```markdown
# M3Canvas 性能测试报告

## 测试摘要
- 测试日期: {date}
- 测试版本: {version}
- 测试设备: {devices}
- 测试时长: {duration}

## 关键指标
| 指标 | 目标值 | 实际值 | 达成状态 |
|------|--------|--------|----------|
| 拖拽FPS | ≥55 | {actual_fps} | {status} |
| 响应时间 | ≤20ms | {actual_response} | {status} |
| 内存稳定性 | 无泄漏 | {memory_status} | {status} |

## 详细分析
{detailed_analysis}

## 性能瓶颈
{bottlenecks}

## 优化建议
{recommendations}
```

## 总结

通过这套全面的性能测试计划，我们将能够：

1. **量化验证**重构效果，确保性能目标达成
2. **及早发现**性能回归问题，保证代码质量
3. **持续监控**生产环境性能，优化用户体验
4. **数据驱动**的性能优化决策

测试计划将与重构实施同步进行，确保每个阶段的性能提升都能得到科学验证。
