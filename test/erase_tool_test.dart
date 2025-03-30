import 'package:demo/presentation/widgets/character_collection/erase_tool/controllers/erase_tool_controller_impl.dart';
import 'package:demo/presentation/widgets/character_collection/erase_tool/models/erase_operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EraseToolController Tests', () {
    late EraseToolControllerImpl controller;

    setUp(() {
      controller = EraseToolControllerImpl();
    });

    test('initial state is correct', () {
      expect(controller.isErasing, false);
      expect(controller.canUndo, false);
      expect(controller.canRedo, false);
      expect(controller.operations, isEmpty);
      expect(controller.currentPoints, isEmpty);
    });

    test('brush size can be changed', () {
      controller.setBrushSize(15.0);
      expect(controller.brushSize, 15.0);

      // Test clamping
      controller.setBrushSize(2.0); // Below min
      expect(controller.brushSize, 3.0);

      controller.setBrushSize(35.0); // Above max
      expect(controller.brushSize, 30.0);
    });
  });

  group('EraseOperation Tests', () {
    test('can add points to operation', () {
      final operation = EraseOperation(
        id: '1',
        brushSize: 10.0,
      );

      expect(operation.points, isEmpty);

      operation.addPoint(const Offset(10, 10));
      operation.addPoint(const Offset(20, 20));

      expect(operation.points.length, 2);
      expect(operation.points[0], const Offset(10, 10));
      expect(operation.points[1], const Offset(20, 20));
    });

    test('bounds calculation is correct', () {
      final operation = EraseOperation(
        id: '1',
        brushSize: 10.0,
        points: [
          const Offset(10, 10),
          const Offset(20, 20),
          const Offset(5, 15),
        ],
      );

      final bounds = operation.getBounds();

      // With brush size 10, radius is 5
      expect(bounds.left, 0.0); // 5 - 5
      expect(bounds.top, 5.0); // 10 - 5
      expect(bounds.right, 25.0); // 20 + 5
      expect(bounds.bottom, 25.0); // 20 + 5
    });

    test('operations can be merged', () {
      final now = DateTime.now();

      final op1 = EraseOperation(
        id: '1',
        brushSize: 10.0,
        points: [const Offset(10, 10), const Offset(20, 20)],
        timestamp: now,
      );

      final op2 = EraseOperation(
        id: '2',
        brushSize: 10.0, // Same brush size
        points: [const Offset(22, 22), const Offset(30, 30)],
        timestamp:
            now.add(const Duration(milliseconds: 100)), // Close timestamp
      );

      // Last point of op1 (20,20) is close to first point of op2 (22,22)
      // Distance is ~2.8, which is less than brushSize*2 (20)
      expect(op2.canMergeWith(op1), isTrue);

      // Test with far points
      final op3 = EraseOperation(
        id: '3',
        brushSize: 10.0,
        points: [const Offset(100, 100), const Offset(110, 110)],
        timestamp: now.add(const Duration(milliseconds: 100)),
      );

      expect(op3.canMergeWith(op1), isFalse);

      // Test with different brush size
      final op4 = EraseOperation(
        id: '4',
        brushSize: 20.0, // Different brush size
        points: [const Offset(22, 22), const Offset(30, 30)],
        timestamp: now.add(const Duration(milliseconds: 100)),
      );

      expect(op4.canMergeWith(op1), isFalse);

      // Test with far timestamp
      final op5 = EraseOperation(
        id: '5',
        brushSize: 10.0,
        points: [const Offset(22, 22), const Offset(30, 30)],
        timestamp: now.add(const Duration(seconds: 1)), // Far timestamp
      );

      expect(op5.canMergeWith(op1), isFalse);
    });
  });
}
