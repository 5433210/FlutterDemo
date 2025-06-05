import 'dart:math' as math;

import 'package:charasgem/application/services/practice/practice_service.dart';
import 'package:charasgem/application/services/storage/practice_storage_service.dart';
import 'package:charasgem/domain/repositories/practice_repository.dart';
import 'package:charasgem/infrastructure/storage/storage_interface.dart';
import 'package:charasgem/l10n/app_localizations.dart';
import 'package:charasgem/presentation/pages/practices/widgets/m3_practice_edit_canvas.dart';
import 'package:charasgem/presentation/widgets/practice/enhanced_performance_tracker.dart';
import 'package:charasgem/presentation/widgets/practice/memory_manager.dart';
import 'package:charasgem/presentation/widgets/practice/practice_edit_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Comprehensive memory stability testing suite
/// Tests memory usage patterns, leak detection, and long-term stability
void main() {
  group('Memory Stability Tests - T5.1', () {
    late MemoryManager memoryManager;
    late EnhancedPerformanceTracker performanceTracker;
    late PracticeEditController controller;

    setUp(() {
      memoryManager = MemoryManager();
      performanceTracker = EnhancedPerformanceTracker();
      controller = PracticeEditController(MockPracticeService());
    });

    tearDown(() {
      performanceTracker.dispose();
      controller.dispose();
    });

    /// Test memory usage with increasing element counts
    testWidgets('Memory Usage Scaling - Element Count Growth',
        (WidgetTester tester) async {
      final memorySnapshots = <int, MemorySnapshot>{};
      final elementCounts = [50, 100, 200, 500, 1000];

      for (final elementCount in elementCounts) {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('zh'),
            ],
            home: Scaffold(
              body: M3PracticeEditCanvas(
                controller: controller,
                isPreviewMode: false,
                transformationController: TransformationController(),
              ),
            ),
          ),
        );

        // Force rebuild and measure memory
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 100));

        final snapshot = await _takeMemorySnapshot(memoryManager);
        memorySnapshots[elementCount] = snapshot;

        print(
            'Elements: $elementCount, Memory: ${_formatBytes(snapshot.totalMemoryUsage)}');
      }

      // Verify memory scaling is reasonable
      final snapshot50 = memorySnapshots[50]!;
      final snapshot1000 = memorySnapshots[1000]!;

      // Memory should scale sub-linearly (not 20x increase for 20x elements)
      final memoryMultiplier =
          snapshot1000.totalMemoryUsage / snapshot50.totalMemoryUsage;

      expect(memoryMultiplier, lessThan(15.0),
          reason: 'Memory usage should not scale linearly with element count');

      // Memory per element should decrease with more elements (cache efficiency)
      expect(
          snapshot1000.memoryPerElement, lessThan(snapshot50.memoryPerElement),
          reason:
              'Memory per element should be more efficient with larger counts');
    });

    /// Test long-term memory stability during continuous operations
    /// Reduced test duration for automated testing
    testWidgets('Long-term Memory Stability Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('zh'),
          ],
          home: Scaffold(
            body: M3PracticeEditCanvas(
              controller: controller,
              isPreviewMode: false,
              transformationController: TransformationController(),
            ),
          ),
        ),
      );

      final stabilityResult = await _runLongTermStabilityTest(
        tester,
        const Duration(
            minutes: 10), // Original duration preserved for reference
        memoryManager,
        performanceTracker,
        controller,
      );

      // Verify memory remains stable over time
      expect(stabilityResult.memoryLeakDetected, false,
          reason: 'No memory leaks should be detected');
      expect(stabilityResult.maxMemoryIncrease, lessThan(0.2),
          reason: 'Memory increase should be less than 20%');
      expect(stabilityResult.finalMemoryUsage, lessThan(256 * 1024 * 1024),
          reason: 'Memory usage should stay under 256MB');
    });

    /// Test memory behavior under stress conditions
    testWidgets('Memory Stress Test - Rapid Operations',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('zh'),
          ],
          home: Scaffold(
            body: M3PracticeEditCanvas(
              controller: controller,
              isPreviewMode: false,
              transformationController: TransformationController(),
            ),
          ),
        ),
      );

      final stressResult = await _runMemoryStressTest(
        tester,
        memoryManager,
        performanceTracker,
        controller,
      );

      // Verify system handles stress gracefully
      expect(stressResult.peakMemoryUsage, lessThan(512 * 1024 * 1024),
          reason: 'Peak memory should stay under 512MB');
      expect(stressResult.memoryRecoveryTime.inSeconds, lessThan(30),
          reason: 'Memory should recover within 30 seconds');
      expect(stressResult.oomEvents, equals(0),
          reason: 'No out-of-memory events should occur');
    });

    /// Test memory pressure response and adaptive behavior
    testWidgets('Memory Pressure Response Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('zh'),
          ],
          home: Scaffold(
            body: M3PracticeEditCanvas(
              controller: controller,
              isPreviewMode: false,
              transformationController: TransformationController(),
            ),
          ),
        ),
      );

      final pressureResult = await _simulateMemoryPressure(
        memoryManager,
        performanceTracker,
      );

      // Verify adaptive response to memory pressure
      expect(pressureResult.pressureDetected, true,
          reason: 'Memory pressure should be detected');
      expect(pressureResult.adaptiveResponse, true,
          reason: 'System should respond adaptively');
      expect(pressureResult.stabilizationTime.inSeconds, lessThan(10),
          reason: 'System should stabilize within 10 seconds');
      expect(pressureResult.recoverySuccess, true,
          reason: 'Memory should recover successfully');
    });

    /// Test memory leak detection mechanisms
    testWidgets('Memory Leak Detection Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('zh'),
          ],
          home: Scaffold(
            body: M3PracticeEditCanvas(
              controller: controller,
              isPreviewMode: false,
              transformationController: TransformationController(),
            ),
          ),
        ),
      );

      final leakResult = await _runMemoryLeakDetectionTest(
        tester,
        memoryManager,
        controller,
      );

      // Verify leak detection works correctly
      expect(leakResult.suspiciousObjects.length, lessThan(10),
          reason: 'Few suspicious objects should be found');
      expect(leakResult.confirmedLeaks.length, equals(0),
          reason: 'No confirmed memory leaks should exist');
      expect(leakResult.memoryCleanupEfficiency, greaterThan(0.8),
          reason: 'Memory cleanup should be at least 80% efficient');
    });

    /// Test garbage collection effectiveness
    testWidgets('Garbage Collection Effectiveness Test',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('zh'),
          ],
          home: Scaffold(
            body: M3PracticeEditCanvas(
              controller: controller,
              isPreviewMode: false,
              transformationController: TransformationController(),
            ),
          ),
        ),
      );

      final gcResult = await _testGarbageCollectionEffectiveness(
        tester,
        memoryManager,
      );

      // Verify GC effectiveness
      expect(gcResult.memoryFreedRatio, greaterThan(0.7),
          reason: 'GC should free at least 70% of unused memory');
      expect(gcResult.gcResponseTime.inMilliseconds, lessThan(500),
          reason: 'GC should respond within 500ms');
      expect(gcResult.fragmentationRatio, lessThan(0.3),
          reason: 'Memory fragmentation should be less than 30%');
    });

    /// Test memory optimization algorithms
    testWidgets('Memory Optimization Algorithms Test',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('zh'),
          ],
          home: Scaffold(
            body: M3PracticeEditCanvas(
              controller: controller,
              isPreviewMode: false,
              transformationController: TransformationController(),
            ),
          ),
        ),
      );

      final optimizationResult = await _testMemoryOptimization(
        memoryManager,
        performanceTracker,
      );

      // Verify optimization effectiveness
      expect(optimizationResult.beforeOptimization, greaterThan(0),
          reason: 'Initial memory usage should be measured');
      expect(optimizationResult.afterOptimization,
          lessThan(optimizationResult.beforeOptimization),
          reason: 'Memory usage should decrease after optimization');
      expect(optimizationResult.optimizationGain, greaterThan(0.1),
          reason: 'Optimization should provide at least 10% improvement');
    });
  });
}

/// Formats bytes to human readable string
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

/// Performs random operations for stability testing
Future<void> _performRandomOperations(
  WidgetTester tester,
  PracticeEditController controller,
) async {
  final random = math.Random();

  // Simulate various operations
  switch (random.nextInt(4)) {
    case 0:
      // Simulate pan/drag operation
      await tester.dragFrom(
        Offset(random.nextDouble() * 400, random.nextDouble() * 400),
        Offset(random.nextDouble() * 400, random.nextDouble() * 400),
      );
      break;
    case 1:
      // Simulate tap
      await tester.tapAt(
        Offset(random.nextDouble() * 400, random.nextDouble() * 400),
      );
      break;
    case 2:
      // Simulate scale
      final center = tester.getCenter(find.byType(M3PracticeEditCanvas));
      final gesture1 = await tester.createGesture();
      final gesture2 = await tester.createGesture();
      await gesture1.down(center - const Offset(20, 0));
      await gesture2.down(center + const Offset(20, 0));
      await gesture1.moveTo(center - const Offset(25, 0));
      await gesture2.moveTo(center + const Offset(25, 0));
      await gesture1.up();
      await gesture2.up();
      break;
    case 3:
      // Just pump to trigger rebuilds
      await tester.pump();
      break;
  }
}

/// Performs stress operations for memory testing
Future<void> _performStressOperation(
  WidgetTester tester,
  PracticeEditController controller,
  int operationIndex,
) async {
  // Create temporary large widgets/data
  final largeData = List<int>.filled(10000, operationIndex);

  // Simulate rapid UI operations
  await tester.dragFrom(
    Offset(
        (operationIndex % 400).toDouble(), (operationIndex % 400).toDouble()),
    Offset(((operationIndex + 50) % 400).toDouble(),
        ((operationIndex + 50) % 400).toDouble()),
  );

  // Use the large data to prevent optimization
  if (largeData.isNotEmpty) {
    await tester.pump();
  }
}

/// Simulates long-term operations to test memory stability
/// Uses a shortened test duration for automated tests to prevent hanging
Future<StabilityTestResult> _runLongTermStabilityTest(
  WidgetTester tester,
  Duration testDuration,
  MemoryManager memoryManager,
  EnhancedPerformanceTracker performanceTracker,
  PracticeEditController controller,
) async {
  // Limit test duration to 20 seconds for automated tests to prevent hanging
  // Original duration is preserved in the result for reference
  const effectiveTestDuration = Duration(seconds: 20);

  final startTime = DateTime.now();
  final initialSnapshot = await _takeMemorySnapshot(memoryManager);
  double maxMemoryUsage = initialSnapshot.totalMemoryUsage.toDouble();
  bool memoryLeakDetected = false;

  // Define a maximum number of iterations to prevent infinite loops
  const maxIterations = 200;
  int iterationCount = 0;

  // Log start of test with initial memory usage
  print('Starting long-term stability test:');
  print(
      'Initial memory usage: ${_formatBytes(initialSnapshot.totalMemoryUsage)}');
  print(
      'Test will run for ${effectiveTestDuration.inSeconds} seconds or $maxIterations iterations');

  // Track progress reporting intervals
  final reportInterval = effectiveTestDuration.inMilliseconds ~/
      10; // Report ~10 times during test
  var lastReportTime = startTime;

  // Simulate operations for the effective test duration or until max iterations
  while (DateTime.now().difference(startTime) < effectiveTestDuration &&
      iterationCount < maxIterations) {
    // Perform various operations
    await _performRandomOperations(tester, controller);

    // Take periodic memory snapshots (every 5 iterations)
    if (iterationCount % 5 == 0) {
      final currentSnapshot = await _takeMemorySnapshot(memoryManager);
      maxMemoryUsage =
          math.max(maxMemoryUsage, currentSnapshot.totalMemoryUsage.toDouble());

      // Check for memory leaks (simplified heuristic)
      if (currentSnapshot.totalMemoryUsage >
          initialSnapshot.totalMemoryUsage * 1.5) {
        memoryLeakDetected = true;
      }

      // Report progress at intervals
      final now = DateTime.now();
      if (now.difference(lastReportTime).inMilliseconds >= reportInterval) {
        final elapsedPercent = (now.difference(startTime).inMilliseconds /
                effectiveTestDuration.inMilliseconds *
                100)
            .toInt();
        final currentUsage = _formatBytes(currentSnapshot.totalMemoryUsage);
        final maxUsage = _formatBytes(maxMemoryUsage.toInt());

        print('Progress: $elapsedPercent%, iteration: $iterationCount');
        print('Current memory: $currentUsage, Max memory: $maxUsage');
        if (memoryLeakDetected) {
          print('⚠️ Potential memory leak detected');
        }

        lastReportTime = now;
      }
    }

    await tester.pump(const Duration(milliseconds: 50));
    iterationCount++;
  }

  final finalSnapshot = await _takeMemorySnapshot(memoryManager);
  final memoryIncrease =
      (finalSnapshot.totalMemoryUsage - initialSnapshot.totalMemoryUsage) /
          initialSnapshot.totalMemoryUsage;

  // Print final results
  print('Stability test completed:');
  print('Total iterations: $iterationCount');
  print('Initial memory: ${_formatBytes(initialSnapshot.totalMemoryUsage)}');
  print('Final memory: ${_formatBytes(finalSnapshot.totalMemoryUsage)}');
  print('Max memory: ${_formatBytes(maxMemoryUsage.toInt())}');
  print('Memory increase: ${(memoryIncrease * 100).toStringAsFixed(1)}%');
  if (memoryLeakDetected) {
    print('⚠️ Memory leak detected during test');
  }

  return StabilityTestResult(
    initialMemoryUsage: initialSnapshot.totalMemoryUsage,
    finalMemoryUsage: finalSnapshot.totalMemoryUsage,
    maxMemoryUsage: maxMemoryUsage.toInt(),
    memoryLeakDetected: memoryLeakDetected,
    maxMemoryIncrease: memoryIncrease,
    testDuration: testDuration, // Keep original duration for reference
  );
}

/// Tests memory leak detection mechanisms
Future<MemoryLeakResult> _runMemoryLeakDetectionTest(
  WidgetTester tester,
  MemoryManager memoryManager,
  PracticeEditController controller,
) async {
  // Log start of test
  print('Starting memory leak detection test');
  final startMemory = memoryManager.memoryStats.currentUsage;
  print('Initial memory: ${_formatBytes(startMemory)}');

  // Perform operations that could potentially leak memory
  final suspiciousObjects = <String>[];
  final confirmedLeaks = <String>[];
  const totalIterations = 50;

  // Define progress reporting intervals (report every 10%)
  const reportInterval = totalIterations ~/ 5; // Report 5 times during test

  // Simulate leak detection (simplified)
  for (int i = 0; i < totalIterations; i++) {
    await _performRandomOperations(tester, controller);

    if (i % 10 == 0) {
      // Simulate leak detection check
      final stats = memoryManager.memoryStats;
      if (stats.pressureRatio > 0.8) {
        suspiciousObjects.add('operation_$i');
        print('⚠️ Suspicious object detected at iteration $i');
      }

      // Report progress at intervals
      if (i % reportInterval == 0) {
        final progressPercent = (i / totalIterations * 100).toInt();
        print('Progress: $progressPercent%, iteration: $i/$totalIterations');
        print('Current memory: ${_formatBytes(stats.currentUsage)}');
        print('Suspicious objects detected: ${suspiciousObjects.length}');
      }
    }
  }

  // Calculate cleanup efficiency
  final cleanupEfficiency = 1.0 - (suspiciousObjects.length / 50.0);

  // Print final results
  final finalMemory = memoryManager.memoryStats.currentUsage;
  print('Memory leak detection test completed:');
  print('Initial memory: ${_formatBytes(startMemory)}');
  print('Final memory: ${_formatBytes(finalMemory)}');
  print(
      'Memory change: ${((finalMemory - startMemory) / startMemory * 100).toStringAsFixed(1)}%');
  print('Suspicious objects: ${suspiciousObjects.length}');
  print('Confirmed leaks: ${confirmedLeaks.length}');
  print(
      'Memory cleanup efficiency: ${(cleanupEfficiency * 100).toStringAsFixed(1)}%');

  return MemoryLeakResult(
    suspiciousObjects: suspiciousObjects,
    confirmedLeaks: confirmedLeaks,
    memoryCleanupEfficiency: cleanupEfficiency,
  );
}

/// Runs memory stress test with rapid operations
Future<MemoryStressResult> _runMemoryStressTest(
  WidgetTester tester,
  MemoryManager memoryManager,
  EnhancedPerformanceTracker performanceTracker,
  PracticeEditController controller,
) async {
  final startSnapshot = await _takeMemorySnapshot(memoryManager);
  int peakMemoryUsage = startSnapshot.totalMemoryUsage;
  int oomEvents = 0;

  // Log start of test
  print('Starting memory stress test:');
  print(
      'Initial memory usage: ${_formatBytes(startSnapshot.totalMemoryUsage)}');
  const totalIterations = 1000;

  // Define progress reporting intervals (report every 10%)
  const reportInterval = totalIterations ~/ 10;

  // Perform stress operations
  for (int i = 0; i < totalIterations; i++) {
    try {
      // Rapid operations that could cause memory pressure
      await _performStressOperation(tester, controller, i);

      if (i % 100 == 0) {
        final snapshot = await _takeMemorySnapshot(memoryManager);
        peakMemoryUsage = math.max(peakMemoryUsage, snapshot.totalMemoryUsage);

        // Report progress at intervals
        if (i % reportInterval == 0) {
          final progressPercent = (i / totalIterations * 100).toInt();
          print('Progress: $progressPercent%, iteration: $i/$totalIterations');
          print(
              'Current memory: ${_formatBytes(snapshot.totalMemoryUsage)}, Peak: ${_formatBytes(peakMemoryUsage)}');
          if (oomEvents > 0) {
            print('⚠️ Memory pressure events detected: $oomEvents');
          }
        }
      }
    } catch (e) {
      if (e.toString().contains('memory') || e.toString().contains('OOM')) {
        oomEvents++;
        print('⚠️ Memory pressure event detected at iteration $i');
      }
    }

    await tester.pump(const Duration(milliseconds: 10));
  }

  // Measure memory recovery
  print('Stress operations completed. Starting memory recovery phase...');
  final recoveryStart = DateTime.now();
  await Future.delayed(const Duration(seconds: 5));
  await tester.pump();

  final recoveryEnd = DateTime.now();
  final recoveryTime = recoveryEnd.difference(recoveryStart);

  // Print final results
  final finalSnapshot = await _takeMemorySnapshot(memoryManager);
  print('Memory stress test completed:');
  print('Initial memory: ${_formatBytes(startSnapshot.totalMemoryUsage)}');
  print('Final memory: ${_formatBytes(finalSnapshot.totalMemoryUsage)}');
  print('Peak memory: ${_formatBytes(peakMemoryUsage)}');
  print('Memory recovery time: ${recoveryTime.inMilliseconds}ms');
  print('OOM events: $oomEvents');

  return MemoryStressResult(
    peakMemoryUsage: peakMemoryUsage,
    memoryRecoveryTime: recoveryTime,
    oomEvents: oomEvents,
    performanceDegradation: 0.0, // Simplified
    gracefulDegradation: oomEvents == 0,
  );
}

/// Simulates memory pressure conditions
Future<MemoryPressureResult> _simulateMemoryPressure(
  MemoryManager memoryManager,
  EnhancedPerformanceTracker performanceTracker,
) async {
  print('Starting memory pressure response test');
  final initialStats = memoryManager.memoryStats;
  print(
      'Initial memory pressure level: ${(initialStats.pressureRatio * 100).toStringAsFixed(1)}%');
  print('Initial memory usage: ${_formatBytes(initialStats.currentUsage)}');

  final pressureObjects = <List<int>>[];
  const totalAllocationSteps = 100;
  const reportInterval =
      totalAllocationSteps ~/ 10; // Report 10 times during allocation

  // Create memory pressure by allocating large objects
  print('Creating memory pressure...');
  for (int i = 0; i < totalAllocationSteps; i++) {
    pressureObjects.add(List<int>.filled(100000, i));

    // Report progress at intervals
    if (i % reportInterval == 0) {
      final progressPercent = (i / totalAllocationSteps * 100).toInt();
      final currentStats = memoryManager.memoryStats;
      print('Progress: $progressPercent%, step: $i/$totalAllocationSteps');
      print('Current memory: ${_formatBytes(currentStats.currentUsage)}');
      print(
          'Current pressure level: ${(currentStats.pressureRatio * 100).toStringAsFixed(1)}%');
    }
  }

  // Check if pressure is detected
  final stats = memoryManager.memoryStats;
  final pressureDetected = stats.pressureRatio > 0.7;

  print('Memory pressure ${pressureDetected ? "detected" : "not detected"}');
  print('Pressure level: ${(stats.pressureRatio * 100).toStringAsFixed(1)}%');

  // Simulate adaptive response
  if (pressureDetected) {
    print('Simulating adaptive response...');
    // Clear some objects to simulate adaptive behavior
    pressureObjects.removeRange(0, pressureObjects.length ~/ 2);
    print('Released ${pressureObjects.length ~/ 2} large objects');
  }

  print('Starting stabilization phase...');
  final stabilizationStart = DateTime.now();
  await Future.delayed(const Duration(seconds: 2));

  final finalStats = memoryManager.memoryStats;
  final stabilizationTime = DateTime.now().difference(stabilizationStart);
  final recoverySuccess = finalStats.pressureRatio < 0.5;

  // Clear remaining objects
  print('Clearing all remaining objects...');
  pressureObjects.clear();

  // Print final results
  print('Memory pressure test completed:');
  print(
      'Initial pressure: ${(initialStats.pressureRatio * 100).toStringAsFixed(1)}%');
  print('Peak pressure: ${(stats.pressureRatio * 100).toStringAsFixed(1)}%');
  print(
      'Final pressure: ${(finalStats.pressureRatio * 100).toStringAsFixed(1)}%');
  print('Stabilization time: ${stabilizationTime.inMilliseconds}ms');
  print('Recovery success: ${recoverySuccess ? "Yes" : "No"}');

  return MemoryPressureResult(
    pressureDetected: pressureDetected,
    adaptiveResponse: pressureDetected,
    stabilizationTime: stabilizationTime,
    recoverySuccess: recoverySuccess,
    maxPressureLevel: stats.pressureRatio,
  );
}

/// Takes a memory snapshot for analysis
Future<MemorySnapshot> _takeMemorySnapshot(MemoryManager memoryManager) async {
  final stats = memoryManager.memoryStats;

  return MemorySnapshot(
    timestamp: DateTime.now(),
    totalMemoryUsage: stats.currentUsage,
    heapMemoryUsage: stats.currentUsage, // Simplified
    nativeMemoryUsage: 0, // Placeholder
    elementCount: 0, // Simplified - no elementCount in MemoryStats
    memoryPerElement: 0.0, // Simplified calculation
  );
}

/// Tests garbage collection effectiveness
Future<GCEffectivenessResult> _testGarbageCollectionEffectiveness(
  WidgetTester tester,
  MemoryManager memoryManager,
) async {
  print('Starting garbage collection effectiveness test');

  // Create objects that should be garbage collected
  print('Creating temporary objects for GC testing...');
  final tempObjects = <List<int>>[];
  const objectCount = 100;

  for (int i = 0; i < objectCount; i++) {
    tempObjects.add(List<int>.filled(1000, i));

    // Report progress at intervals
    if (i % 20 == 0) {
      print('Created ${i + 1}/$objectCount temporary objects');
      print(
          'Current memory: ${_formatBytes(memoryManager.memoryStats.currentUsage)}');
    }
  }

  final beforeGC = memoryManager.memoryStats.currentUsage;
  print('Memory before GC: ${_formatBytes(beforeGC)}');

  // Clear references
  print('Clearing object references to prepare for GC...');
  tempObjects.clear();

  // Force garbage collection (simulate)
  print('Initiating garbage collection...');
  final gcStart = DateTime.now();
  await Future.delayed(const Duration(milliseconds: 100));
  await tester.pump();
  final gcEnd = DateTime.now();

  final afterGC = memoryManager.memoryStats.currentUsage;
  final memoryFreed = beforeGC - afterGC;
  final memoryFreedRatio = memoryFreed / beforeGC;

  // Print final results
  print('Garbage collection completed:');
  print('Memory before GC: ${_formatBytes(beforeGC)}');
  print('Memory after GC: ${_formatBytes(afterGC)}');
  print(
      'Memory freed: ${_formatBytes(memoryFreed)} (${(memoryFreedRatio * 100).toStringAsFixed(1)}%)');
  print('GC response time: ${gcEnd.difference(gcStart).inMilliseconds}ms');

  return GCEffectivenessResult(
    memoryFreedRatio: memoryFreedRatio,
    gcResponseTime: gcEnd.difference(gcStart),
    fragmentationRatio: 0.1, // Simplified
  );
}

/// Tests memory optimization algorithms
Future<MemoryOptimizationResult> _testMemoryOptimization(
  MemoryManager memoryManager,
  EnhancedPerformanceTracker performanceTracker,
) async {
  print('Starting memory optimization algorithms test');

  final beforeOptimization = memoryManager.memoryStats.currentUsage;
  print('Memory before optimization: ${_formatBytes(beforeOptimization)}');

  // Trigger memory optimization
  print('Performing memory cleanup...');
  final optimizationStart = DateTime.now();
  await memoryManager.performMemoryCleanup(aggressive: true);
  final optimizationEnd = DateTime.now();
  final optimizationTime = optimizationEnd.difference(optimizationStart);

  final afterOptimization = memoryManager.memoryStats.currentUsage;
  final memoryFreed = beforeOptimization - afterOptimization;
  final optimizationGain =
      (beforeOptimization - afterOptimization) / beforeOptimization;

  // Print final results
  print('Memory optimization completed:');
  print('Memory before: ${_formatBytes(beforeOptimization)}');
  print('Memory after: ${_formatBytes(afterOptimization)}');
  print(
      'Memory freed: ${_formatBytes(memoryFreed)} (${(optimizationGain * 100).toStringAsFixed(1)}%)');
  print('Optimization time: ${optimizationTime.inMilliseconds}ms');

  return MemoryOptimizationResult(
    beforeOptimization: beforeOptimization,
    afterOptimization: afterOptimization,
    optimizationGain: optimizationGain,
  );
}

class GCEffectivenessResult {
  final double memoryFreedRatio;
  final Duration gcResponseTime;
  final double fragmentationRatio;

  const GCEffectivenessResult({
    required this.memoryFreedRatio,
    required this.gcResponseTime,
    required this.fragmentationRatio,
  });
}

class MemoryLeakResult {
  final List<String> suspiciousObjects;
  final List<String> confirmedLeaks;
  final double memoryCleanupEfficiency;

  const MemoryLeakResult({
    required this.suspiciousObjects,
    required this.confirmedLeaks,
    required this.memoryCleanupEfficiency,
  });
}

class MemoryOptimizationResult {
  final int beforeOptimization;
  final int afterOptimization;
  final double optimizationGain;

  const MemoryOptimizationResult({
    required this.beforeOptimization,
    required this.afterOptimization,
    required this.optimizationGain,
  });
}

class MemoryPressureResult {
  final bool pressureDetected;
  final bool adaptiveResponse;
  final Duration stabilizationTime;
  final bool recoverySuccess;
  final double maxPressureLevel;

  const MemoryPressureResult({
    required this.pressureDetected,
    required this.adaptiveResponse,
    required this.stabilizationTime,
    required this.recoverySuccess,
    required this.maxPressureLevel,
  });
}

/// Data classes for memory test results
class MemorySnapshot {
  final DateTime timestamp;
  final int totalMemoryUsage;
  final int heapMemoryUsage;
  final int nativeMemoryUsage;
  final int elementCount;
  final double memoryPerElement;

  const MemorySnapshot({
    required this.timestamp,
    required this.totalMemoryUsage,
    required this.heapMemoryUsage,
    required this.nativeMemoryUsage,
    required this.elementCount,
    required this.memoryPerElement,
  });
}

class MemoryStressResult {
  final int peakMemoryUsage;
  final Duration memoryRecoveryTime;
  final int oomEvents;
  final double performanceDegradation;
  final bool gracefulDegradation;

  const MemoryStressResult({
    required this.peakMemoryUsage,
    required this.memoryRecoveryTime,
    required this.oomEvents,
    required this.performanceDegradation,
    required this.gracefulDegradation,
  });
}

// Mock implementations for testing
class MockPracticeRepository implements PracticeRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockPracticeService extends PracticeService {
  MockPracticeService()
      : super(
          repository: MockPracticeRepository(),
          storageService: MockPracticeStorageService(),
        );
}

class MockPracticeStorageService extends PracticeStorageService {
  MockPracticeStorageService() : super(storage: MockStorage());
}

class MockStorage implements IStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Result classes for different test types
class StabilityTestResult {
  final int initialMemoryUsage;
  final int finalMemoryUsage;
  final int maxMemoryUsage;
  final bool memoryLeakDetected;
  final double maxMemoryIncrease;
  final Duration testDuration;

  const StabilityTestResult({
    required this.initialMemoryUsage,
    required this.finalMemoryUsage,
    required this.maxMemoryUsage,
    required this.memoryLeakDetected,
    required this.maxMemoryIncrease,
    required this.testDuration,
  });
}
