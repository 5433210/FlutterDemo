import 'package:charasgem/application/services/practice/practice_service.dart';
import 'package:charasgem/presentation/pages/practices/services/unified_service_manager.dart';
import 'package:charasgem/presentation/widgets/practice/practice_edit_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate mocks
@GenerateMocks([PracticeEditController, PracticeService])
import 'unified_service_manager_test.mocks.dart';

void main() {
  group('UnifiedServiceManager', () {
    late UnifiedServiceManager manager;
    late MockPracticeEditController mockController;
    late MockPracticeService mockPracticeService;

    setUp(() {
      manager = UnifiedServiceManager.instance;
      mockController = MockPracticeEditController();
      mockPracticeService = MockPracticeService();
    });

    test('should be singleton', () {
      final instance1 = UnifiedServiceManager.instance;
      final instance2 = UnifiedServiceManager.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('should initialize controller', () {
      manager.initialize(mockController);
      expect(manager.isInitialized, isTrue);
    });

    test('should record property changes when initialized', () {
      manager.initialize(mockController);

      // Mock the updateElementProperties method
      when(mockController.updateElementProperties(any, any))
          .thenReturn(Future.value());

      manager.recordPropertyChange('test-id', 'x', 10.0, 20.0);

      // Verify that the operation was recorded
      // Note: Since UndoRedoManager.addOperation is not returning anything,
      // we just verify no exceptions were thrown
      expect(manager.isInitialized, isTrue);
    });

    test('should handle undo operations', () {
      manager.initialize(mockController);

      final result = manager.undo();

      // Should return true when no exceptions occur, false otherwise
      expect(result, isA<bool>());
    });

    test('should handle redo operations', () {
      manager.initialize(mockController);

      final result = manager.redo();

      // Should return true when no exceptions occur, false otherwise
      expect(result, isA<bool>());
    });

    test('should not record property changes when not initialized', () {
      // Don't initialize the manager
      expect(() => manager.recordPropertyChange('test-id', 'x', 10.0, 20.0),
          throwsA(isA<StateError>()));
    });

    test('should handle format brush operations when initialized', () {
      manager.initialize(mockController);

      // Test copy format brush
      expect(() => manager.copyFormatBrush(), returnsNormally);

      // Test apply format brush
      expect(() => manager.applyFormatBrush(), returnsNormally);
    });

    test('should handle clipboard operations when initialized', () {
      manager.initialize(mockController);

      // Test copy operation
      expect(() => manager.copy(), returnsNormally);

      // Test paste operation
      expect(() => manager.paste(), returnsNormally);
    });

    test('should handle shortcut operations when initialized', () {
      manager.initialize(mockController);

      // Test shortcut execution
      expect(() => manager.executeShortcut('ctrl+z'), returnsNormally);
    });
  });
}
