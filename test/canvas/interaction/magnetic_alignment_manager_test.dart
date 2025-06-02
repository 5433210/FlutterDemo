import 'package:charasgem/canvas/core/canvas_state_manager.dart';
import 'package:charasgem/canvas/core/interfaces/element_data.dart';
import 'package:charasgem/canvas/core/interfaces/layer_data.dart';
import 'package:charasgem/canvas/interaction/magnetic_alignment_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MagneticAlignmentManager Tests', () {
    late MagneticAlignmentManager alignmentManager;
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

      alignmentManager = MagneticAlignmentManager(stateManager);
    });

    group('Grid Alignment', () {
      test('should snap to grid when within snap distance', () {
        // Configure grid
        alignmentManager.configureGrid(
          size: 20.0,
          snapDistance: 10.0,
          enabled: true,
        );

        // Test position near grid point
        final result = alignmentManager.alignPosition(
          const Offset(23.0, 27.0), // Near grid point (20, 20)
          [],
        );

        expect(result.wasAligned, isTrue);
        expect(result.alignedPosition, const Offset(20.0, 20.0));
        expect(result.appliedSnaps.first.snapType, SnapType.grid);
      });

      test('should not snap to grid when outside snap distance', () {
        alignmentManager.configureGrid(
          size: 20.0,
          snapDistance: 5.0,
          enabled: true,
        );

        final result = alignmentManager.alignPosition(
          const Offset(15.0, 15.0), // Too far from grid
          [],
        );

        expect(result.wasAligned, isFalse);
        expect(result.alignedPosition, const Offset(15.0, 15.0));
      });

      test('should respect grid offset', () {
        alignmentManager.configureGrid(
          size: 20.0,
          offset: const Offset(5.0, 5.0),
          snapDistance: 10.0,
          enabled: true,
        );

        final result = alignmentManager.alignPosition(
          const Offset(23.0, 27.0), // Near grid point (25, 25) with offset
          [],
        );

        expect(result.wasAligned, isTrue);
        expect(result.alignedPosition, const Offset(25.0, 25.0));
      });

      test('should not snap when grid is disabled', () {
        alignmentManager.configureGrid(
          size: 20.0,
          snapDistance: 10.0,
          enabled: false,
        );

        final result = alignmentManager.alignPosition(
          const Offset(23.0, 27.0),
          [],
        );

        expect(result.wasAligned, isFalse);
      });
    });

    group('Element Alignment', () {
      test('should snap to element edges when within distance', () {
        // Add a reference element with explicit bounds
        const element = ElementData(
          id: 'ref1',
          layerId: 'default',
          type: 'collection',
          bounds: Rect.fromLTWH(100, 100, 50, 50),
          visible: true,
          locked: false,
        );
        stateManager.addElementToLayer(element, 'default');

        // Configure element snapping and disable grid to avoid interference
        alignmentManager.configureGrid(enabled: false);
        alignmentManager.configureElementSnap(
          snapDistance: 10.0,
          enabled: true,
        );

        // Test position near element edge - using Y=105 to avoid center line conflict
        final result = alignmentManager.alignPosition(
          const Offset(
              95.0, 105.0), // Near left edge of element, avoiding center Y
          [],
        );

        expect(result.wasAligned, isTrue);
        expect(result.alignedPosition.dx, 100.0); // Snapped to left edge
        expect(result.alignedPosition.dy, 105.0); // Y unchanged
        expect(result.appliedSnaps.first.snapType, SnapType.elementVertical);
      });

      test('should not snap to excluded elements', () {
        const element = ElementData(
          id: 'ref1',
          layerId: 'default',
          type: 'collection',
          bounds: Rect.fromLTWH(100, 100, 50, 50),
          visible: true,
          locked: false,
        );
        stateManager.addElementToLayer(element, 'default');

        // Configure element snapping and disable grid to avoid interference
        alignmentManager.configureGrid(enabled: false);
        alignmentManager.configureElementSnap(
          snapDistance: 10.0,
          enabled: true,
        );

        final result = alignmentManager.alignPosition(
          const Offset(95.0, 105.0), // Use same position as above test
          ['ref1'], // Exclude the reference element
        );

        expect(result.wasAligned, isFalse);
      });
    });

    group('Multiple Element Alignment', () {
      test('should align multiple elements independently', () {
        alignmentManager.configureGrid(
          size: 20.0,
          snapDistance: 10.0,
          enabled: true,
        );

        final positions = {
          'elem1': const Offset(23.0, 27.0),
          'elem2': const Offset(43.0, 47.0),
        };

        final result = alignmentManager.alignMultipleElements(
          positions,
          mode: AlignmentMode.independent,
        );

        expect(
            result.results['elem1']!.alignedPosition, const Offset(20.0, 20.0));
        expect(
            result.results['elem2']!.alignedPosition, const Offset(40.0, 40.0));
      });
    });

    group('Performance Tracking', () {
      test('should track performance statistics', () {
        alignmentManager.resetPerformanceStats();

        // Perform some alignment operations
        alignmentManager.alignPosition(const Offset(10, 10), []);
        alignmentManager.alignPosition(const Offset(20, 20), []);

        final stats = alignmentManager.getPerformanceStats();
        expect(stats.totalOperations, 2);
        expect(stats.totalProcessingTime, greaterThan(0));
        expect(stats.averageProcessingTime, greaterThan(0));
      });

      test('should reset performance statistics', () {
        alignmentManager.alignPosition(const Offset(10, 10), []);
        alignmentManager.resetPerformanceStats();

        final stats = alignmentManager.getPerformanceStats();
        expect(stats.totalOperations, 0);
        expect(stats.totalProcessingTime, 0);
        expect(stats.averageProcessingTime, 0);
      });
    });

    group('Alignment Guides', () {
      test('should provide alignment guides for element snapping', () {
        const element = ElementData(
          id: 'ref1',
          layerId: 'default',
          type: 'collection',
          bounds: Rect.fromLTWH(100, 100, 50, 50),
          visible: true,
          locked: false,
        );
        stateManager.addElementToLayer(element, 'default');

        // Disable grid to test only element snapping
        alignmentManager.configureGrid(enabled: false);
        alignmentManager.configureElementSnap(enabled: true);

        final result = alignmentManager.alignPosition(
          const Offset(95.0, 105.0), // Position that will snap to left edge
          [],
        );

        expect(result.guides.isNotEmpty, isTrue);
        expect(result.guides.first.type, GuideType.vertical);
      });

      test('should clear guides when requested', () {
        // Add an element to snap to
        const element = ElementData(
          id: 'ref1',
          layerId: 'default',
          type: 'collection',
          bounds: Rect.fromLTWH(100, 100, 50, 50),
          visible: true,
          locked: false,
        );
        stateManager.addElementToLayer(element, 'default');

        // Disable grid to test only element snapping
        alignmentManager.configureGrid(enabled: false);
        alignmentManager.configureElementSnap(enabled: true);

        // Perform alignment that will generate guides
        alignmentManager.alignPosition(const Offset(95.0, 105.0), []);
        expect(alignmentManager.getActiveGuides().isNotEmpty, isTrue);

        alignmentManager.clearGuides();
        expect(alignmentManager.getActiveGuides().isEmpty, isTrue);
      });
    });
  });
}
