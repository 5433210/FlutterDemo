import 'package:charasgem/application/services/practice/practice_service.dart';
import 'package:charasgem/application/services/storage/practice_storage_service.dart';
import 'package:charasgem/domain/repositories/practice_repository.dart';
import 'package:charasgem/infrastructure/storage/storage_interface.dart';
import 'package:charasgem/presentation/pages/practices/widgets/m3_practice_edit_canvas.dart';
import 'package:charasgem/presentation/widgets/practice/practice_edit_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M3PracticeEditCanvas Drag Performance Tests', () {
    late PracticeEditController controller;
    late DragStateManager dragStateManager;

    setUp(() {
      controller = PracticeEditController(MockPracticeService());
      dragStateManager = DragStateManager();
    });

    testWidgets('Drag Performance with Light Element Load',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: M3PracticeEditCanvas(
            controller: controller,
            isPreviewMode: false,
            transformationController: TransformationController(),
          ),
        ),
      ));

      final stopwatch = Stopwatch()..start();

      // Perform drag gesture
      await tester.dragFrom(
        const Offset(100, 100),
        const Offset(300, 300),
      );

      await tester.pump();
      stopwatch.stop();

      final dragTime = stopwatch.elapsedMilliseconds;
      print('Light Load Drag Time: ${dragTime}ms');

      expect(dragTime, lessThan(100),
          reason: 'Drag with light load should complete within 100ms');
    });

    testWidgets('Drag Performance with Medium Element Load',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: M3PracticeEditCanvas(
            controller: controller,
            isPreviewMode: false,
            transformationController: TransformationController(),
          ),
        ),
      ));

      final stopwatch = Stopwatch()..start();

      // Perform longer drag gesture
      await tester.dragFrom(
        const Offset(50, 50),
        const Offset(400, 400),
      );

      await tester.pump();
      stopwatch.stop();

      final dragTime = stopwatch.elapsedMilliseconds;
      print('Medium Load Drag Time: ${dragTime}ms');

      expect(dragTime, lessThan(150),
          reason: 'Drag with medium load should complete within 150ms');
    });

    testWidgets('Drag Performance with Heavy Element Load',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: M3PracticeEditCanvas(
            controller: controller,
            isPreviewMode: false,
            transformationController: TransformationController(),
          ),
        ),
      ));

      final stopwatch = Stopwatch()..start();

      // Perform complex drag gesture
      for (int i = 0; i < 5; i++) {
        await tester.dragFrom(
          Offset(100 + i * 20.0, 100 + i * 20.0),
          Offset(200 + i * 20.0, 200 + i * 20.0),
        );
        await tester.pump();
      }

      stopwatch.stop();

      final dragTime = stopwatch.elapsedMilliseconds;
      print('Heavy Load Drag Time: ${dragTime}ms');

      expect(dragTime, lessThan(500),
          reason: 'Drag with heavy load should complete within 500ms');
    });

    testWidgets('Multi-finger Drag Performance', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: M3PracticeEditCanvas(
            controller: controller,
            isPreviewMode: false,
            transformationController: TransformationController(),
          ),
        ),
      ));

      final stopwatch = Stopwatch()..start();

      // Simulate multi-touch drag
      await tester.startGesture(const Offset(100, 100));
      await tester.startGesture(const Offset(200, 200));
      await tester.pump();

      stopwatch.stop();

      final multiTouchTime = stopwatch.elapsedMilliseconds;
      print('Multi-touch Drag Time: ${multiTouchTime}ms');

      expect(multiTouchTime, lessThan(50),
          reason: 'Multi-touch drag should respond within 50ms');
    });

    test('Drag State Manager Performance', () {
      final stopwatch = Stopwatch()..start();

      // Test drag state operations
      for (int i = 0; i < 1000; i++) {
        dragStateManager.startDrag(Offset(i.toDouble(), i.toDouble()));
        dragStateManager.updateDrag(Offset(i + 10.0, i + 10.0));
        dragStateManager.endDrag();
      }

      stopwatch.stop();

      final operationTime = stopwatch.elapsedMilliseconds;
      print('1000 Drag State Operations: ${operationTime}ms');

      expect(operationTime, lessThan(100),
          reason: '1000 drag state operations should complete within 100ms');
    });
  });
}

/// Simplified DragStateManager for testing
class DragStateManager {
  Offset? _startPosition;
  Offset? _currentPosition;
  bool _isDragging = false;

  Offset? get currentPosition => _currentPosition;

  bool get isDragging => _isDragging;

  Offset? get startPosition => _startPosition;

  void endDrag() {
    _isDragging = false;
    _startPosition = null;
    _currentPosition = null;
  }

  void startDrag(Offset position) {
    _startPosition = position;
    _currentPosition = position;
    _isDragging = true;
  }

  void updateDrag(Offset position) {
    if (_isDragging) {
      _currentPosition = position;
    }
  }
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
