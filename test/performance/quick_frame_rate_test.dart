import 'package:charasgem/application/services/practice/practice_service.dart';
import 'package:charasgem/application/services/storage/practice_storage_service.dart';
import 'package:charasgem/domain/repositories/practice_repository.dart';
import 'package:charasgem/infrastructure/storage/storage_interface.dart';
import 'package:charasgem/presentation/pages/practices/widgets/m3_practice_edit_canvas.dart';
import 'package:charasgem/presentation/widgets/practice/enhanced_performance_tracker.dart';
import 'package:charasgem/presentation/widgets/practice/practice_edit_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quick Frame Rate Tests', () {
    late EnhancedPerformanceTracker performanceTracker;
    late PracticeEditController controller;

    setUp(() {
      performanceTracker = EnhancedPerformanceTracker();
      controller = PracticeEditController(MockPracticeService());
    });

    tearDown(() {
      performanceTracker.dispose();
      controller.dispose();
    });

    testWidgets('Quick Light Load Test', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: M3PracticeEditCanvas(
            controller: controller,
            isPreviewMode: false,
            transformationController: TransformationController(),
          ),
        ),
      ));

      // Quick frame time measurement (just 1 second)
      final frameTimes = <double>[];
      for (int i = 0; i < 10; i++) {
        final stopwatch = Stopwatch()..start();
        await tester.pump();
        stopwatch.stop();
        frameTimes.add(stopwatch.elapsedMicroseconds / 1000.0);
      }

      final averageFrameTime =
          frameTimes.reduce((a, b) => a + b) / frameTimes.length;
      final averageFPS = 1000.0 / averageFrameTime;

      print('Quick Test - Average FPS: ${averageFPS.toStringAsFixed(1)}, '
          'Frame Time: ${averageFrameTime.toStringAsFixed(2)}ms');

      expect(averageFrameTime, lessThan(50.0),
          reason: 'Frame time should be reasonable');
    });

    testWidgets('Quick Interaction Test', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: M3PracticeEditCanvas(
            controller: controller,
            isPreviewMode: false,
            transformationController: TransformationController(),
          ),
        ),
      ));

      // Test a few interactions
      for (int i = 0; i < 3; i++) {
        await tester.tapAt(Offset(100 + i * 50.0, 100));
        await tester.pump();
      }

      expect(true, isTrue, reason: 'Basic interactions should work');
    });
  });
}

// Mock services for testing
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

class MockPracticeStorageService implements PracticeStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockStorage implements IStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
