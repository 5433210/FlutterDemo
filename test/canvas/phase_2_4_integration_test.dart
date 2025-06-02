import 'package:charasgem/canvas/core/canvas_state_manager.dart';
import 'package:charasgem/canvas/core/interfaces/layer_data.dart';
import 'package:charasgem/canvas/interaction/magnetic_alignment_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 2.4 Integration Tests', () {
    late CanvasStateManager stateManager;

    setUp(() {
      stateManager = CanvasStateManager();

      // 创建默认图层
      const defaultLayer = LayerData(
        id: 'default',
        name: 'Default Layer',
        visible: true,
        locked: false,
        opacity: 1.0,
        blendMode: 'normal',
      );
      stateManager.createLayer(defaultLayer);
      stateManager.selectLayer('default');
    });

    group('Magnetic Alignment Manager', () {
      test('should initialize and configure correctly', () {
        final alignmentManager = MagneticAlignmentManager(stateManager);

        // Test configuration
        alignmentManager.configureGrid(
          size: 20.0,
          snapDistance: 10.0,
          enabled: true,
        );

        alignmentManager.configureElementSnap(
          snapDistance: 8.0,
          enabled: true,
        );

        // Basic functionality test
        final result = alignmentManager.alignPosition(
          const Offset(25.0, 25.0),
          [],
        );

        expect(result, isNotNull);
        expect(result.originalPosition, const Offset(25.0, 25.0));
      });

      test('should track performance statistics', () {
        final alignmentManager = MagneticAlignmentManager(stateManager);

        alignmentManager.resetPerformanceStats();

        // Perform some operations
        for (int i = 0; i < 5; i++) {
          alignmentManager.alignPosition(Offset(i * 10.0, i * 10.0), []);
        }

        final stats = alignmentManager.getPerformanceStats();
        expect(stats.totalOperations, 5);
        expect(stats.totalProcessingTime, greaterThanOrEqualTo(0));
      });

      test('should handle guides correctly', () {
        final alignmentManager = MagneticAlignmentManager(stateManager);

        // Clear guides
        alignmentManager.clearGuides();
        expect(alignmentManager.getActiveGuides(), isEmpty);

        // Perform alignment that might generate guides
        alignmentManager.alignPosition(const Offset(10.0, 10.0), []);

        // Should be able to get guides (even if empty)
        final guides = alignmentManager.getActiveGuides();
        expect(guides, isNotNull);
      });
    });

    group('Phase 2.4 System Integration', () {
      test('should create all Phase 2.4 managers without errors', () {
        // Test that all managers can be instantiated
        expect(() {
          final alignmentManager = MagneticAlignmentManager(stateManager);

          // Test basic operations
          alignmentManager.configureGrid(size: 20.0);
          alignmentManager.configureElementSnap(snapDistance: 10.0);

          final result = alignmentManager.alignPosition(
            const Offset(0.0, 0.0),
            [],
          );

          expect(result, isNotNull);
        }, returnsNormally);
      });

      test('should handle multiple element alignment modes', () {
        final alignmentManager = MagneticAlignmentManager(stateManager);

        final positions = {
          'elem1': const Offset(15.0, 15.0),
          'elem2': const Offset(35.0, 35.0),
        };

        // Test independent mode
        final independentResult = alignmentManager.alignMultipleElements(
          positions,
          mode: AlignmentMode.independent,
        );

        expect(independentResult.results, hasLength(2));
        expect(independentResult.mode, AlignmentMode.independent);

        // Test grouped mode
        final groupedResult = alignmentManager.alignMultipleElements(
          positions,
          mode: AlignmentMode.grouped,
        );

        expect(groupedResult.results, hasLength(2));
        expect(groupedResult.mode, AlignmentMode.grouped);

        // Test chain mode
        final chainResult = alignmentManager.alignMultipleElements(
          positions,
          mode: AlignmentMode.chain,
        );

        expect(chainResult.results, hasLength(2));
        expect(chainResult.mode, AlignmentMode.chain);
      });
    });
  });
}
