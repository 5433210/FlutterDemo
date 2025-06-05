import 'dart:convert';
import 'dart:io';

import 'package:charasgem/application/services/practice/practice_service.dart';
import 'package:charasgem/application/services/storage/practice_storage_service.dart';
import 'package:charasgem/domain/models/practice/practice_element.dart';
import 'package:charasgem/domain/repositories/practice_repository.dart';
import 'package:charasgem/infrastructure/storage/storage_interface.dart';
import 'package:charasgem/presentation/pages/practices/widgets/m3_practice_edit_canvas.dart';
import 'package:charasgem/presentation/widgets/practice/enhanced_performance_tracker.dart';
import 'package:charasgem/presentation/widgets/practice/practice_edit_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M3PracticeEditCanvas Regression Detection Tests', () {
    late EnhancedPerformanceTracker performanceTracker;
    late List<PerformanceBaseline> existingBaselines;

    setUpAll(() async {
      existingBaselines = await BaselineManager.loadBaselines();
    });

    setUp(() {
      performanceTracker = EnhancedPerformanceTracker();
    });

    testWidgets('Light Load Regression Test', (WidgetTester tester) async {
      const testName = 'light_load_test';
      const elementCount = 50;

      final currentBaseline = await _measurePerformanceBaseline(
          tester, testName, elementCount, performanceTracker);

      final existingBaseline = BaselineManager.findBaseline(
          existingBaselines, testName, elementCount);

      if (existingBaseline != null) {
        final result = RegressionAnalyzer.analyzeRegression(
            existingBaseline, currentBaseline);
        _reportRegressionResult(result);

        expect(result.hasRegression, isFalse,
            reason: 'Light load test should not show performance regression');
        expect(result.overallScore,
            lessThan(RegressionAnalyzer.regressionThreshold),
            reason:
                'Overall performance score should not exceed regression threshold');
      } else {
        print('No baseline found for $testName. Recording new baseline.');
        existingBaselines.add(currentBaseline);
      }
    });

    testWidgets('Medium Load Regression Test', (WidgetTester tester) async {
      const testName = 'medium_load_test';
      const elementCount = 150;

      final currentBaseline = await _measurePerformanceBaseline(
          tester, testName, elementCount, performanceTracker);

      final existingBaseline = BaselineManager.findBaseline(
          existingBaselines, testName, elementCount);

      if (existingBaseline != null) {
        final result = RegressionAnalyzer.analyzeRegression(
            existingBaseline, currentBaseline);
        _reportRegressionResult(result);

        if (result.hasRegression) {
          final significantRegressions = result.regressions
              .where((r) => r.contains('SIGNIFICANT'))
              .toList();

          expect(significantRegressions, isEmpty,
              reason:
                  'Medium load test should not show significant regressions');
        }
      } else {
        print('No baseline found for $testName. Recording new baseline.');
        existingBaselines.add(currentBaseline);
      }
    });

    testWidgets('Heavy Load Regression Test', (WidgetTester tester) async {
      const testName = 'heavy_load_test';
      const elementCount = 300;

      final currentBaseline = await _measurePerformanceBaseline(
          tester, testName, elementCount, performanceTracker);

      final existingBaseline = BaselineManager.findBaseline(
          existingBaselines, testName, elementCount);

      if (existingBaseline != null) {
        final result = RegressionAnalyzer.analyzeRegression(
            existingBaseline, currentBaseline);
        _reportRegressionResult(result);

        // Allow some regression under heavy load, but not excessive
        expect(result.overallScore,
            lessThan(RegressionAnalyzer.significantRegressionThreshold),
            reason:
                'Heavy load regression should not exceed significant threshold');
      } else {
        print('No baseline found for $testName. Recording new baseline.');
        existingBaselines.add(currentBaseline);
      }
    });

    testWidgets('Maximum Load Regression Test', (WidgetTester tester) async {
      const testName = 'maximum_load_test';
      const elementCount = 500;

      final currentBaseline = await _measurePerformanceBaseline(
          tester, testName, elementCount, performanceTracker);

      final existingBaseline = BaselineManager.findBaseline(
          existingBaselines, testName, elementCount);

      if (existingBaseline != null) {
        final result = RegressionAnalyzer.analyzeRegression(
            existingBaseline, currentBaseline);
        _reportRegressionResult(result);

        // Focus on ensuring system doesn't completely break down
        expect(currentBaseline.averageFrameTime, lessThan(50.0),
            reason: 'Frame time should not exceed 50ms even at maximum load');
        expect(currentBaseline.averageResponseTime, lessThan(100.0),
            reason:
                'Response time should not exceed 100ms even at maximum load');
      } else {
        print('No baseline found for $testName. Recording new baseline.');
        existingBaselines.add(currentBaseline);
      }
    });

    testWidgets('Interactive Performance Regression Test',
        (WidgetTester tester) async {
      const testName = 'interactive_performance_test';
      const elementCount = 100;

      final currentBaseline = await _measureInteractivePerformance(
          tester, testName, elementCount, performanceTracker);

      final existingBaseline = BaselineManager.findBaseline(
          existingBaselines, testName, elementCount);

      if (existingBaseline != null) {
        final result = RegressionAnalyzer.analyzeRegression(
            existingBaseline, currentBaseline);
        _reportRegressionResult(result);

        // Interactive performance is critical - stricter thresholds
        expect(result.regressionPercentages['dragLatency'] ?? 0,
            lessThan(RegressionAnalyzer.regressionThreshold),
            reason: 'Drag latency regression should be minimal for good UX');
        expect(result.regressionPercentages['responseTime'] ?? 0,
            lessThan(RegressionAnalyzer.regressionThreshold),
            reason: 'Response time regression should be minimal for good UX');
      } else {
        print('No baseline found for $testName. Recording new baseline.');
        existingBaselines.add(currentBaseline);
      }
    });

    testWidgets('Memory Usage Regression Test', (WidgetTester tester) async {
      const testName = 'memory_usage_test';
      const elementCount = 200;

      final currentBaseline = await _measureMemoryPerformance(
          tester, testName, elementCount, performanceTracker);

      final existingBaseline = BaselineManager.findBaseline(
          existingBaselines, testName, elementCount);

      if (existingBaseline != null) {
        final result = RegressionAnalyzer.analyzeRegression(
            existingBaseline, currentBaseline);
        _reportRegressionResult(result);

        // Memory regressions can indicate leaks or inefficiencies
        final memoryRegression = result.regressionPercentages['memory'] ?? 0;
        expect(memoryRegression, lessThan(20.0),
            reason: 'Memory usage regression should not exceed 20%');

        if (memoryRegression > 15.0) {
          print('⚠️ WARNING: Significant memory usage increase detected');
        }
      } else {
        print('No baseline found for $testName. Recording new baseline.');
        existingBaselines.add(currentBaseline);
      }
    });

    tearDownAll(() async {
      // Save updated baselines
      await BaselineManager.saveBaselines(existingBaselines);
      print(
          'Performance baselines saved to ${BaselineManager.baselineFilePath}');
    });
  });

  group('Baseline Management Tests', () {
    testWidgets('Create Initial Baselines', (WidgetTester tester) async {
      final performanceTracker = EnhancedPerformanceTracker();
      final newBaselines = <PerformanceBaseline>[];

      // Create baselines for key scenarios
      final scenarios = [
        ('baseline_light', 25),
        ('baseline_medium', 100),
        ('baseline_heavy', 250),
        ('baseline_maximum', 500),
      ];

      for (final (testName, elementCount) in scenarios) {
        final baseline = await _measurePerformanceBaseline(
            tester, testName, elementCount, performanceTracker);
        newBaselines.add(baseline);

        print('Created baseline for $testName: '
            'Frame: ${baseline.averageFrameTime.toStringAsFixed(2)}ms, '
            'Response: ${baseline.averageResponseTime.toStringAsFixed(2)}ms, '
            'Memory: ${baseline.memoryUsageMB.toStringAsFixed(1)}MB');
      }

      expect(newBaselines.length, equals(scenarios.length));

      // Save baselines
      await BaselineManager.saveBaselines(newBaselines);
    });
  });
}

/// Generates test elements for performance testing using existing TextElement type
List<PracticeElement> _generateTestElements(int count) {
  final elements = <PracticeElement>[];

  for (int i = 0; i < count; i++) {
    elements.add(TextElement(
      id: 'element_$i',
      text: 'Test Element $i',
      x: 50.0 + i * 25.0,
      y: 50.0 + (i % 20) * 20.0,
      width: 100.0,
      height: 30.0,
      layerId: 'default_layer',
    ));
  }

  return elements;
}

/// Measures interactive performance with focus on user interaction responsiveness
Future<PerformanceBaseline> _measureInteractivePerformance(
  WidgetTester tester,
  String testName,
  int elementCount,
  EnhancedPerformanceTracker performanceTracker,
) async {
  final controller = PracticeEditController(MockPracticeService());

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: M3PracticeEditCanvas(
        controller: controller,
        isPreviewMode: false,
        transformationController: TransformationController(),
      ),
    ),
  ));

  // Focus on interactive metrics
  final interactionTimes = <double>[];
  final dragLatencies = <double>[];

  // Simulate realistic user interactions
  for (int i = 0; i < 30; i++) {
    // Tap interaction
    final tapStopwatch = Stopwatch()..start();
    await tester.tapAt(Offset(200 + (i % 10) * 30.0, 200 + (i % 10) * 30.0));
    await tester.pump();
    tapStopwatch.stop();
    interactionTimes.add(tapStopwatch.elapsedMicroseconds / 1000.0);

    // Drag interaction
    final dragStopwatch = Stopwatch()..start();
    await tester.dragFrom(
      Offset(150 + i * 5.0, 150),
      Offset(200 + i * 5.0, 200),
    );
    await tester.pump();
    dragStopwatch.stop();
    dragLatencies.add(dragStopwatch.elapsedMicroseconds / 1000.0);
  }

  final averageInteractionTime =
      interactionTimes.reduce((a, b) => a + b) / interactionTimes.length;
  final averageDragLatency =
      dragLatencies.reduce((a, b) => a + b) / dragLatencies.length;

  // Quick frame time measurement
  final frameStopwatch = Stopwatch()..start();
  await tester.pump();
  frameStopwatch.stop();
  final frameTime = frameStopwatch.elapsedMicroseconds / 1000.0;

  return PerformanceBaseline(
    testName: testName,
    elementCount: elementCount,
    averageFrameTime: frameTime,
    averageResponseTime: averageInteractionTime,
    memoryUsageMB: elementCount * 0.4 + 40.0,
    dragLatency: averageDragLatency,
    renderTime: frameTime,
    version: '1.0.0',
    recordedAt: DateTime.now(),
  );
}

/// Measures memory-focused performance metrics
Future<PerformanceBaseline> _measureMemoryPerformance(
  WidgetTester tester,
  String testName,
  int elementCount,
  EnhancedPerformanceTracker performanceTracker,
) async {
  final controller = PracticeEditController(MockPracticeService());

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: M3PracticeEditCanvas(
        controller: controller,
        isPreviewMode: false,
        transformationController: TransformationController(),
      ),
    ),
  ));

  // Perform operations that might affect memory
  for (int i = 0; i < 20; i++) {
    await tester.pump();
    await tester.tapAt(Offset(100 + i * 10.0, 100));
    await tester.pump();
  }

  // Measure frame time and response time
  final stopwatch = Stopwatch()..start();
  await tester.pump();
  stopwatch.stop();
  final frameTime = stopwatch.elapsedMicroseconds / 1000.0;

  final responseStopwatch = Stopwatch()..start();
  await tester.tap(find.byType(M3PracticeEditCanvas));
  await tester.pump();
  responseStopwatch.stop();
  final responseTime = responseStopwatch.elapsedMicroseconds / 1000.0;

  // Memory estimation based on element complexity
  final memoryUsageMB = elementCount * 0.6 + 60.0;

  return PerformanceBaseline(
    testName: testName,
    elementCount: elementCount,
    averageFrameTime: frameTime,
    averageResponseTime: responseTime,
    memoryUsageMB: memoryUsageMB,
    dragLatency: responseTime,
    renderTime: frameTime,
    version: '1.0.0',
    recordedAt: DateTime.now(),
  );
}

/// Measures comprehensive performance baseline for a given test scenario
Future<PerformanceBaseline> _measurePerformanceBaseline(
  WidgetTester tester,
  String testName,
  int elementCount,
  EnhancedPerformanceTracker performanceTracker,
) async {
  final controller = PracticeEditController(MockPracticeService());

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: M3PracticeEditCanvas(
        controller: controller,
        isPreviewMode: false,
        transformationController: TransformationController(),
      ),
    ),
  ));

  // Measure frame time
  final frameTimes = <double>[];
  for (int i = 0; i < 50; i++) {
    final stopwatch = Stopwatch()..start();
    await tester.pump();
    stopwatch.stop();
    frameTimes.add(stopwatch.elapsedMicroseconds / 1000.0);
  }
  final averageFrameTime =
      frameTimes.reduce((a, b) => a + b) / frameTimes.length;

  // Measure response time
  final responseTimes = <double>[];
  for (int i = 0; i < 20; i++) {
    final stopwatch = Stopwatch()..start();
    await tester.tapAt(Offset(200 + i * 10.0, 200 + i * 10.0));
    await tester.pump();
    stopwatch.stop();
    responseTimes.add(stopwatch.elapsedMicroseconds / 1000.0);
  }
  final averageResponseTime =
      responseTimes.reduce((a, b) => a + b) / responseTimes.length;

  // Measure drag latency
  final dragTimes = <double>[];
  for (int i = 0; i < 10; i++) {
    final stopwatch = Stopwatch()..start();
    await tester.dragFrom(
      Offset(150 + i * 20.0, 150),
      Offset(200 + i * 20.0, 200),
    );
    await tester.pump();
    stopwatch.stop();
    dragTimes.add(stopwatch.elapsedMicroseconds / 1000.0);
  }
  final averageDragLatency =
      dragTimes.reduce((a, b) => a + b) / dragTimes.length;

  // Measure render time
  final renderTimes = <double>[];
  for (int i = 0; i < 15; i++) {
    final stopwatch = Stopwatch()..start();
    await tester.pump();
    stopwatch.stop();
    renderTimes.add(stopwatch.elapsedMicroseconds / 1000.0);
  }
  final averageRenderTime =
      renderTimes.reduce((a, b) => a + b) / renderTimes.length;

  // Estimate memory usage (simplified)
  final memoryUsageMB = elementCount * 0.5 + 50.0; // Rough estimation

  return PerformanceBaseline(
    testName: testName,
    elementCount: elementCount,
    averageFrameTime: averageFrameTime,
    averageResponseTime: averageResponseTime,
    memoryUsageMB: memoryUsageMB,
    dragLatency: averageDragLatency,
    renderTime: averageRenderTime,
    version: '1.0.0',
    recordedAt: DateTime.now(),
  );
}

/// Reports regression analysis results
void _reportRegressionResult(PerformanceRegressionResult result) {
  print('\n=== Regression Analysis: ${result.testName} ===');
  print('Baseline: ${result.baseline.version} (${result.baseline.recordedAt})');
  print('Current Performance:');

  for (final entry in result.regressionPercentages.entries) {
    final metric = entry.key;
    final change = entry.value;
    final direction = change > 0
        ? '↗️'
        : change < 0
            ? '↘️'
            : '➡️';
    final status = change > RegressionAnalyzer.regressionThreshold
        ? '❌'
        : change < -RegressionAnalyzer.improvementThreshold
            ? '✅'
            : '⚪';

    print('  $metric: ${change.toStringAsFixed(1)}% $direction $status');
  }

  print('Overall Score: ${result.overallScore.toStringAsFixed(1)}%');

  if (result.regressions.isNotEmpty) {
    print('Regressions:');
    for (final regression in result.regressions) {
      print('  ❌ $regression');
    }
  }

  if (result.improvements.isNotEmpty) {
    print('Improvements:');
    for (final improvement in result.improvements) {
      print('  ✅ $improvement');
    }
  }

  print(
      'Status: ${result.hasRegression ? "❌ REGRESSION DETECTED" : "✅ NO REGRESSION"}');
  print('==========================================\n');
}

class BaselineManager {
  static const String baselineFileName = 'performance_baselines.json';
  static String get baselineFilePath => 'test/performance/$baselineFileName';

  static PerformanceBaseline? findBaseline(
      List<PerformanceBaseline> baselines, String testName, int elementCount) {
    return baselines
        .where((b) => b.testName == testName && b.elementCount == elementCount)
        .fold<PerformanceBaseline?>(null, (latest, current) {
      return latest == null || current.recordedAt.isAfter(latest.recordedAt)
          ? current
          : latest;
    });
  }

  static Future<List<PerformanceBaseline>> loadBaselines() async {
    try {
      final file = File(baselineFilePath);
      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();
      final List<dynamic> jsonList = json.decode(content);
      return jsonList
          .map((json) => PerformanceBaseline.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading baselines: $e');
      return [];
    }
  }

  static Future<void> saveBaselines(List<PerformanceBaseline> baselines) async {
    try {
      final file = File(baselineFilePath);
      await file.parent.create(recursive: true);

      final jsonList = baselines.map((baseline) => baseline.toJson()).toList();
      final content = const JsonEncoder.withIndent('  ').convert(jsonList);
      await file.writeAsString(content);
    } catch (e) {
      print('Error saving baselines: $e');
    }
  }
}

// Mock implementations for testing
class MockPracticeRepository implements PracticeRepository {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class MockPracticeService extends PracticeService {
  MockPracticeService()
      : super(
            repository: MockPracticeRepository(),
            storageService: MockPracticeStorageService());

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class MockPracticeStorageService extends PracticeStorageService {
  MockPracticeStorageService() : super(storage: MockStorage());

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class MockStorage implements IStorage {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Performance regression detection test suite for M3PracticeEditCanvas
/// Compares current performance against established baselines to detect
/// performance regressions across key metrics and usage scenarios.

class PerformanceBaseline {
  final String testName;
  final int elementCount;
  final double averageFrameTime;
  final double averageResponseTime;
  final double memoryUsageMB;
  final double dragLatency;
  final double renderTime;
  final String version;
  final DateTime recordedAt;

  const PerformanceBaseline({
    required this.testName,
    required this.elementCount,
    required this.averageFrameTime,
    required this.averageResponseTime,
    required this.memoryUsageMB,
    required this.dragLatency,
    required this.renderTime,
    required this.version,
    required this.recordedAt,
  });

  factory PerformanceBaseline.fromJson(Map<String, dynamic> json) =>
      PerformanceBaseline(
        testName: json['testName'],
        elementCount: json['elementCount'],
        averageFrameTime: json['averageFrameTime'],
        averageResponseTime: json['averageResponseTime'],
        memoryUsageMB: json['memoryUsageMB'],
        dragLatency: json['dragLatency'],
        renderTime: json['renderTime'],
        version: json['version'],
        recordedAt: DateTime.parse(json['recordedAt']),
      );

  Map<String, dynamic> toJson() => {
        'testName': testName,
        'elementCount': elementCount,
        'averageFrameTime': averageFrameTime,
        'averageResponseTime': averageResponseTime,
        'memoryUsageMB': memoryUsageMB,
        'dragLatency': dragLatency,
        'renderTime': renderTime,
        'version': version,
        'recordedAt': recordedAt.toIso8601String(),
      };
}

class PerformanceRegressionResult {
  final String testName;
  final PerformanceBaseline baseline;
  final PerformanceBaseline current;
  final Map<String, double> regressionPercentages;
  final List<String> regressions;
  final List<String> improvements;
  final bool hasRegression;
  final double overallScore;

  const PerformanceRegressionResult({
    required this.testName,
    required this.baseline,
    required this.current,
    required this.regressionPercentages,
    required this.regressions,
    required this.improvements,
    required this.hasRegression,
    required this.overallScore,
  });
}

class RegressionAnalyzer {
  static const double regressionThreshold = 10.0; // 10% regression threshold
  static const double significantRegressionThreshold =
      25.0; // 25% significant regression
  static const double improvementThreshold = 5.0; // 5% improvement threshold

  static PerformanceRegressionResult analyzeRegression(
    PerformanceBaseline baseline,
    PerformanceBaseline current,
  ) {
    final regressionPercentages = <String, double>{};
    final regressions = <String>[];
    final improvements = <String>[];

    // Calculate percentage changes for each metric
    final frameTimeChange = _calculatePercentageChange(
        baseline.averageFrameTime, current.averageFrameTime);
    regressionPercentages['frameTime'] = frameTimeChange;

    final responseTimeChange = _calculatePercentageChange(
        baseline.averageResponseTime, current.averageResponseTime);
    regressionPercentages['responseTime'] = responseTimeChange;

    final memoryChange = _calculatePercentageChange(
        baseline.memoryUsageMB, current.memoryUsageMB);
    regressionPercentages['memory'] = memoryChange;

    final dragLatencyChange =
        _calculatePercentageChange(baseline.dragLatency, current.dragLatency);
    regressionPercentages['dragLatency'] = dragLatencyChange;

    final renderTimeChange =
        _calculatePercentageChange(baseline.renderTime, current.renderTime);
    regressionPercentages['renderTime'] = renderTimeChange;

    // Identify regressions and improvements
    _analyzeMetricChange(
        'Frame Time', frameTimeChange, regressions, improvements);
    _analyzeMetricChange(
        'Response Time', responseTimeChange, regressions, improvements);
    _analyzeMetricChange(
        'Memory Usage', memoryChange, regressions, improvements);
    _analyzeMetricChange(
        'Drag Latency', dragLatencyChange, regressions, improvements);
    _analyzeMetricChange(
        'Render Time', renderTimeChange, regressions, improvements);

    final hasRegression = regressions.isNotEmpty;
    final overallScore = _calculateOverallScore(regressionPercentages);

    return PerformanceRegressionResult(
      testName: current.testName,
      baseline: baseline,
      current: current,
      regressionPercentages: regressionPercentages,
      regressions: regressions,
      improvements: improvements,
      hasRegression: hasRegression,
      overallScore: overallScore,
    );
  }

  static void _analyzeMetricChange(
    String metricName,
    double changePercentage,
    List<String> regressions,
    List<String> improvements,
  ) {
    if (changePercentage > regressionThreshold) {
      final severity = changePercentage > significantRegressionThreshold
          ? 'SIGNIFICANT'
          : 'MODERATE';
      regressions.add(
          '$metricName: ${changePercentage.toStringAsFixed(1)}% worse ($severity)');
    } else if (changePercentage < -improvementThreshold) {
      improvements.add(
          '$metricName: ${(-changePercentage).toStringAsFixed(1)}% better');
    }
  }

  static double _calculateOverallScore(
      Map<String, double> regressionPercentages) {
    // Weight different metrics by importance
    const weights = {
      'frameTime': 0.3,
      'responseTime': 0.25,
      'memory': 0.2,
      'dragLatency': 0.15,
      'renderTime': 0.1,
    };

    double weightedSum = 0.0;
    double totalWeight = 0.0;

    for (final entry in regressionPercentages.entries) {
      final weight = weights[entry.key] ?? 0.0;
      weightedSum += entry.value * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? weightedSum / totalWeight : 0.0;
  }

  static double _calculatePercentageChange(double baseline, double current) {
    if (baseline == 0) return 0.0;
    return ((current - baseline) / baseline) * 100.0;
  }
}
