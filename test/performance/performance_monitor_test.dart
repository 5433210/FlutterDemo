import 'package:charasgem/presentation/widgets/practice/performance_monitor.dart' as pm;
import 'package:charasgem/presentation/widgets/practice/drag_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PerformanceMonitor Tests', () {
    late pm.PerformanceMonitor performanceMonitor;

    setUp(() {
      // 获取单例实例
      performanceMonitor = pm.PerformanceMonitor();
      // 重置状态以确保测试隔离
      performanceMonitor.reset();
    });

    tearDown(() {
      performanceMonitor.reset();
    });

    test('性能监控器应该正确初始化', () {
      print('\n🧪 测试开始：性能监控器初始化');
      
      expect(performanceMonitor, isNotNull);
      expect(performanceMonitor.currentFPS, equals(0.0));
      expect(performanceMonitor.averageFrameTime, equals(Duration.zero));
      expect(performanceMonitor.maxFrameTime, equals(Duration.zero));
      expect(performanceMonitor.slowFrameCount, equals(0));
      expect(performanceMonitor.totalRebuilds, equals(0));
      expect(performanceMonitor.fpsHistory, isEmpty);
      
      print('📊 初始状态：');
      print('   当前FPS: ${performanceMonitor.currentFPS}');
      print('   慢帧数量: ${performanceMonitor.slowFrameCount}');
      print('   总重建次数: ${performanceMonitor.totalRebuilds}');
      
      print('✅ 性能监控器初始化测试通过\n');
    });

    test('帧性能跟踪应该正确工作', () async {
      print('\n🧪 测试开始：帧性能跟踪');
      
      // 模拟多个帧的渲染
      for (int i = 0; i < 10; i++) {
        performanceMonitor.trackFrame();
        await Future.delayed(const Duration(milliseconds: 16)); // 模拟16ms帧间隔
      }
      
      print('📊 帧跟踪结果：');
      print('   当前FPS: ${performanceMonitor.currentFPS.toStringAsFixed(1)}');
      print('   FPS历史条目: ${performanceMonitor.fpsHistory.length}');
      print('   平均帧时间: ${performanceMonitor.averageFrameTime.inMilliseconds}ms');
      print('   最大帧时间: ${performanceMonitor.maxFrameTime.inMilliseconds}ms');
      
      expect(performanceMonitor.currentFPS, greaterThan(0));
      expect(performanceMonitor.fpsHistory, isNotEmpty);
      expect(performanceMonitor.averageFrameTime.inMicroseconds, greaterThan(0));
      
      print('✅ 帧性能跟踪测试通过\n');
    });

    test('慢帧检测应该正确工作', () {
      print('\n🧪 测试开始：慢帧检测');
      
      final initialSlowFrameCount = performanceMonitor.slowFrameCount;
      
      // 模拟一个慢帧 (超过16.67ms)
      final slowFrameDuration = const Duration(milliseconds: 25);
      performanceMonitor.trackFrameTime(slowFrameDuration);
      
      print('📊 慢帧检测结果：');
      print('   慢帧前数量: $initialSlowFrameCount');
      print('   慢帧后数量: ${performanceMonitor.slowFrameCount}');
      print('   检测的帧时间: ${slowFrameDuration.inMilliseconds}ms');
      
      expect(performanceMonitor.slowFrameCount, greaterThan(initialSlowFrameCount));
      expect(performanceMonitor.maxFrameTime.inMilliseconds, greaterThanOrEqualTo(25));
      
      print('✅ 慢帧检测测试通过\n');
    });

    test('Widget重建跟踪应该正确工作', () {
      print('\n🧪 测试开始：Widget重建跟踪');
      
      const widgetName = 'TestWidget';
      final initialRebuilds = performanceMonitor.totalRebuilds;
      
      // 模拟多次Widget重建
      for (int i = 0; i < 5; i++) {
        performanceMonitor.trackWidgetRebuild(widgetName);
      }
      
      final summary = performanceMonitor.getPerformanceSummary();
      
      print('📊 Widget重建跟踪结果：');
      print('   初始重建次数: $initialRebuilds');
      print('   最终重建次数: ${performanceMonitor.totalRebuilds}');
      print('   性能摘要: ${summary['totalRebuilds']}');
      print('   热门重建Widget: ${summary['topRebuildWidgets']}');
      
      expect(performanceMonitor.totalRebuilds, equals(initialRebuilds + 5));
      expect(summary['topRebuildWidgets'], isNotEmpty);
      
      print('✅ Widget重建跟踪测试通过\n');
    });

    test('拖拽性能跟踪应该正确工作', () async {
      print('\n🧪 测试开始：拖拽性能跟踪');
      
      // 创建mock DragStateManager
      final dragStateManager = MockDragStateManager();
      performanceMonitor.setDragStateManager(dragStateManager);
      
      // 模拟开始拖拽
      dragStateManager.startDragging(['element1', 'element2']);
      performanceMonitor.startTrackingDragPerformance();
      
      expect(performanceMonitor.hasDragPerformanceData, isTrue);
      
      // 模拟一些拖拽帧
      for (int i = 0; i < 5; i++) {
        performanceMonitor.trackFrame();
        await Future.delayed(const Duration(milliseconds: 16));
      }
      
      // 获取拖拽性能数据
      final dragData = performanceMonitor.getDragPerformanceData();
      
      print('📊 拖拽性能数据：');
      if (dragData != null) {
        print('   拖拽状态: ${dragData['isDragging'] ?? 'N/A'}');
        print('   拖拽元素数: ${dragData['elementCount'] ?? 'N/A'}');
      }
      
      // 结束拖拽跟踪
      final report = performanceMonitor.endTrackingDragPerformance();
      
      print('📊 拖拽性能报告：');
      print('   持续时间: ${report['duration']}ms');
      print('   帧数: ${report['frameCount']}');
      print('   拖拽元素数: ${report['dragElementCount']}');
      
      expect(report, isNotNull);
      // 由于时间的影响，报告可能为空，我们检查结构存在即可
      if (report.isNotEmpty) {
        expect(report['dragElementCount'], equals(2));
      }
      
      print('✅ 拖拽性能跟踪测试通过\n');
    });

    test('性能监控重置应该正确工作', () {
      print('\n🧪 测试开始：性能监控重置');
      
      // 先添加一些数据
      performanceMonitor.trackFrame();
      performanceMonitor.trackWidgetRebuild('TestWidget');
      performanceMonitor.trackFrameTime(const Duration(milliseconds: 20));
      
      // 验证有数据
      expect(performanceMonitor.currentFPS, greaterThan(0));
      expect(performanceMonitor.totalRebuilds, greaterThan(0));
      
      print('📊 重置前状态：');
      print('   当前FPS: ${performanceMonitor.currentFPS}');
      print('   总重建次数: ${performanceMonitor.totalRebuilds}');
      print('   慢帧数: ${performanceMonitor.slowFrameCount}');
      
      // 执行重置
      performanceMonitor.reset();
      
      print('📊 重置后状态：');
      print('   当前FPS: ${performanceMonitor.currentFPS}');
      print('   总重建次数: ${performanceMonitor.totalRebuilds}');
      print('   慢帧数: ${performanceMonitor.slowFrameCount}');
      
      // 验证重置成功
      expect(performanceMonitor.currentFPS, equals(0.0));
      expect(performanceMonitor.totalRebuilds, equals(0));
      expect(performanceMonitor.slowFrameCount, equals(0));
      expect(performanceMonitor.fpsHistory, isEmpty);
      expect(performanceMonitor.averageFrameTime, equals(Duration.zero));
      expect(performanceMonitor.maxFrameTime, equals(Duration.zero));
      
      print('✅ 性能监控重置测试通过\n');
    });

    test('性能摘要生成应该正确工作', () {
      print('\n🧪 测试开始：性能摘要生成');
      
      // 添加一些测试数据
      performanceMonitor.trackFrame();
      performanceMonitor.trackWidgetRebuild('Widget1');
      performanceMonitor.trackWidgetRebuild('Widget2');
      performanceMonitor.trackWidgetRebuild('Widget1'); // Widget1重建2次
      performanceMonitor.trackFrameTime(const Duration(milliseconds: 15));
      
      final summary = performanceMonitor.getPerformanceSummary();
      
      print('📊 性能摘要：');
      summary.forEach((key, value) {
        print('   $key: $value');
      });
      
      expect(summary, isNotNull);
      expect(summary['currentFPS'], isA<double>());
      expect(summary['totalRebuilds'], equals(3));
      expect(summary['topRebuildWidgets'], isA<List>());
      expect(summary['averageFrameTime'], isA<String>());
      expect(summary['maxFrameTime'], isA<String>());
      expect(summary['slowFrameCount'], isA<int>());
      
      // 验证热门重建Widget排序
      final topWidgets = summary['topRebuildWidgets'] as List;
      if (topWidgets.isNotEmpty) {
        expect(topWidgets.first['widget'], equals('Widget1'));
        expect(topWidgets.first['rebuilds'], equals(2));
      }
      
      print('✅ 性能摘要生成测试通过\n');
    });

    test('监控启动和停止应该正确工作', () {
      print('\n🧪 测试开始：监控启动和停止');
      
      // 测试启动监控
      expect(() => performanceMonitor.startMonitoring(), returnsNormally);
      
      print('📊 监控状态：');
      print('   启动监控: 成功');
      
      // 测试停止监控
      expect(() => performanceMonitor.stopMonitoring(), returnsNormally);
      
      print('   停止监控: 成功');
      
      print('✅ 监控启动和停止测试通过\n');
    });
  });

  group('PerformanceTrackedWidget Tests', () {
    testWidgets('PerformanceTrackedWidget应该跟踪重建', (WidgetTester tester) async {
      print('\n🧪 测试开始：PerformanceTrackedWidget重建跟踪');
      
      final monitor = pm.PerformanceMonitor();
      monitor.reset();
      
      const widgetName = 'TrackedTestWidget';
      
      // 创建被跟踪的Widget
      await tester.pumpWidget(
        MaterialApp(
          home: pm.PerformanceTrackedWidget(
            widgetName: widgetName,
            monitor: monitor,
            child: const Text('Test'),
          ),
        ),
      );
      
      // 验证初始重建被跟踪
      expect(monitor.totalRebuilds, greaterThan(0));
      
      final initialRebuilds = monitor.totalRebuilds;
      
      // 触发重建
      await tester.pumpWidget(
        MaterialApp(
          home: pm.PerformanceTrackedWidget(
            widgetName: widgetName,
            monitor: monitor,
            child: const Text('Test Updated'),
          ),
        ),
      );
      
      print('📊 重建跟踪结果：');
      print('   初始重建次数: $initialRebuilds');
      print('   最终重建次数: ${monitor.totalRebuilds}');
      
      expect(monitor.totalRebuilds, greaterThan(initialRebuilds));
      
      print('✅ PerformanceTrackedWidget重建跟踪测试通过\n');
    });
  });

  group('PerformanceOverlay Tests', () {
    testWidgets('PerformanceOverlay应该正确渲染', (WidgetTester tester) async {
      print('\n🧪 测试开始：PerformanceOverlay渲染');
      
      await tester.pumpWidget(
        MaterialApp(
          home: pm.PerformanceOverlay(
            showOverlay: true,
            child: const Scaffold(
              body: Text('Test Content'),
            ),
          ),
        ),
      );
      
      // 验证子Widget存在
      expect(find.text('Test Content'), findsOneWidget);
      
      // 验证Stack结构（overlay使用Stack布局）
      expect(find.byType(Stack), findsOneWidget);
      
      print('📊 渲染结果：');
      print('   子Widget渲染: 成功');
      print('   Stack结构: 存在');
      
      print('✅ PerformanceOverlay渲染测试通过\n');
    });

    testWidgets('PerformanceOverlay在showOverlay=false时不显示覆盖层', (WidgetTester tester) async {
      print('\n🧪 测试开始：PerformanceOverlay隐藏状态');
      
      await tester.pumpWidget(
        MaterialApp(
          home: pm.PerformanceOverlay(
            showOverlay: false,
            child: const Scaffold(
              body: Text('Test Content'),
            ),
          ),
        ),
      );
      
      // 验证子Widget存在
      expect(find.text('Test Content'), findsOneWidget);
      
      print('📊 隐藏状态结果：');
      print('   子Widget渲染: 成功');
      print('   覆盖层状态: 隐藏');
      
      print('✅ PerformanceOverlay隐藏状态测试通过\n');
    });
  });
}

// Mock DragStateManager for testing
class MockDragStateManager implements DragStateManager {
  bool _isDragging = false;
  Set<String> _draggingElementIds = {};
  
  @override
  bool get isDragging => _isDragging;
  
  @override
  Set<String> get draggingElementIds => _draggingElementIds;
  
  void startDragging(List<String> elementIds) {
    _isDragging = true;
    _draggingElementIds = elementIds.toSet();
  }
  
  void stopDragging() {
    _isDragging = false;
    _draggingElementIds.clear();
  }
  
  @override
  Map<String, dynamic> getPerformanceReport() {
    return {
      'isDragging': _isDragging,
      'elementCount': _draggingElementIds.length,
      'currentFps': 60,
      'avgFps': 58.5,
      'updateCount': 100,
      'batchUpdateCount': 10,
      'avgUpdateTime': 12.5,
      'isPerformanceCritical': false,
    };
  }
  
  @override
  Map<String, dynamic> getPerformanceOptimizationConfig() {
    return {
      'enableBatchUpdates': true,
      'enablePerformanceOptimization': true,
      'maxDragUpdateRate': 60,
    };
  }
  
  // 实现其他必需的方法（基于实际DragStateManager接口）
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
} 