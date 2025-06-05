import 'package:charasgem/application/services/practice/practice_service.dart';
import 'package:charasgem/application/services/storage/practice_storage_service.dart';
import 'package:charasgem/domain/repositories/practice_repository.dart';
import 'package:charasgem/infrastructure/storage/storage_interface.dart';
import 'package:charasgem/l10n/app_localizations.dart';
import 'package:charasgem/presentation/pages/practices/widgets/m3_practice_edit_canvas.dart';
import 'package:charasgem/presentation/widgets/practice/practice_edit_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M3PracticeEditCanvas Response Time Tests', () {
    late PracticeEditController controller;

    setUp(() {
      controller = PracticeEditController(MockPracticeService());
    });

    // Helper function to create a localized widget for testing
    Widget createLocalizedCanvas(
        TransformationController transformationController) {
      return MaterialApp(
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
            transformationController: transformationController,
          ),
        ),
      );
    }

    testWidgets('Basic Touch Response Time Test', (WidgetTester tester) async {
      await tester
          .pumpWidget(createLocalizedCanvas(TransformationController()));

      final List<double> tapResponseTimes = [];
      const int tapTestCount = 50;

      // Perform multiple tap tests to get statistical data
      for (int i = 0; i < tapTestCount; i++) {
        final stopwatch = Stopwatch()..start();

        // Simulate tap at random location
        final tapLocation = Offset(
          100 + (i % 10) * 50.0,
          100 + (i % 10) * 50.0,
        );

        await tester.tapAt(tapLocation);
        await tester.pump();

        stopwatch.stop();
        tapResponseTimes.add(stopwatch.elapsedMicroseconds / 1000.0);

        // Small delay between taps
        await tester.pump(const Duration(milliseconds: 10));
      }

      final averageResponse =
          ResponseTimeAnalysis.calculateAverage(tapResponseTimes);
      final p95Response =
          ResponseTimeAnalysis.calculatePercentile(tapResponseTimes, 95);

      print(
          'Tap Response Time - Average: ${averageResponse.toStringAsFixed(2)}ms, P95: ${p95Response.toStringAsFixed(2)}ms');

      // Verify response times are within acceptable limits
      expect(averageResponse, lessThan(16.0),
          reason: 'Average tap response should be under 16ms');
      expect(p95Response, lessThan(20.0),
          reason: 'P95 tap response should be under 20ms');
    });
    testWidgets('Pan Gesture Response Time Test', (WidgetTester tester) async {
      await tester
          .pumpWidget(createLocalizedCanvas(TransformationController()));

      final List<double> panStartTimes = [];
      final List<double> panUpdateTimes = [];
      const int panTestCount = 25;

      for (int i = 0; i < panTestCount; i++) {
        // Test pan start response
        final startStopwatch = Stopwatch()..start();

        await tester.startGesture(Offset(200 + i * 5.0, 200 + i * 5.0));
        await tester.pump();

        startStopwatch.stop();
        panStartTimes.add(startStopwatch.elapsedMicroseconds / 1000.0);

        // Test pan update response
        final updateStopwatch = Stopwatch()..start();

        await tester.dragFrom(
          Offset(200 + i * 5.0, 200 + i * 5.0),
          const Offset(50, 50),
        );
        await tester.pump();

        updateStopwatch.stop();
        panUpdateTimes.add(updateStopwatch.elapsedMicroseconds / 1000.0);

        await tester.pump(const Duration(milliseconds: 10));
      }

      final avgPanStart = ResponseTimeAnalysis.calculateAverage(panStartTimes);
      final avgPanUpdate =
          ResponseTimeAnalysis.calculateAverage(panUpdateTimes);

      print(
          'Pan Response Time - Start: ${avgPanStart.toStringAsFixed(2)}ms, Update: ${avgPanUpdate.toStringAsFixed(2)}ms');

      expect(avgPanStart, lessThan(16.0),
          reason: 'Pan start response should be under 16ms');
      expect(avgPanUpdate, lessThan(16.0),
          reason: 'Pan update response should be under 16ms');
    });
    testWidgets('Scale Response Time Test', (WidgetTester tester) async {
      final transformationController = TransformationController();

      await tester.pumpWidget(createLocalizedCanvas(transformationController));

      final List<double> scaleResponseTimes = [];
      const int scaleTestCount = 20;

      for (int i = 0; i < scaleTestCount; i++) {
        final stopwatch = Stopwatch()..start();

        // Simulate scale by directly updating the transformation controller
        // This avoids the complex gesture simulation that was causing hangs
        final scale = 1.1 + i * 0.01;
        final currentTransform = transformationController.value;
        final newTransform = Matrix4.identity()
          ..scale(scale, scale)
          ..multiply(currentTransform);

        transformationController.value = newTransform;
        await tester.pump();

        stopwatch.stop();
        scaleResponseTimes.add(stopwatch.elapsedMicroseconds / 1000.0);

        await tester.pump(const Duration(milliseconds: 10));

        // Reset transformation for next iteration
        transformationController.value = Matrix4.identity();
        await tester.pump();
      }

      final averageScale =
          ResponseTimeAnalysis.calculateAverage(scaleResponseTimes);

      print(
          'Scale Response Time - Average: ${averageScale.toStringAsFixed(2)}ms');

      expect(averageScale, lessThan(32.0),
          reason: 'Scale response should be under 32ms');
    });
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

class ResponseTimeAnalysis {
  static double calculateAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double calculatePercentile(List<double> values, double percentile) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final index = (percentile / 100.0 * (sorted.length - 1)).round();
    return sorted[index.clamp(0, sorted.length - 1)];
  }
}
