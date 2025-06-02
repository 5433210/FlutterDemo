import 'package:charasgem/canvas/core/canvas_state_manager.dart';
import 'package:charasgem/canvas/core/interfaces/element_data.dart';
import 'package:charasgem/canvas/core/interfaces/layer_data.dart';
import 'package:charasgem/canvas/interaction/magnetic_alignment_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debug MagneticAlignmentManager', () {
    test('should debug element snapping', () {
      final stateManager = CanvasStateManager();

      // Create default layer
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

      final alignmentManager = MagneticAlignmentManager(stateManager);

      print(
          'Initial selectable elements: ${stateManager.selectableElements.length}');

      // Add a test element
      const element = ElementData(
        id: 'ref1',
        layerId: 'default',
        type: 'collection',
        bounds: Rect.fromLTWH(100, 100, 50, 50),
        visible: true,
        locked: false,
      );
      stateManager.addElementToLayer(element, 'default');

      print(
          'After adding element - selectable elements: ${stateManager.selectableElements.length}');
      print('Element bounds: ${stateManager.selectableElements.first.bounds}');
      print(
          'Element center: ${stateManager.selectableElements.first.bounds.center}');
      print(
          'Element left: ${stateManager.selectableElements.first.bounds.left}');
      print('Element top: ${stateManager.selectableElements.first.bounds.top}');
      print('Position: Offset(95.0, 125.0)');
      print('Distance to left edge: ${(95.0 - 100.0).abs()}');
      print('Distance to center Y: ${(125.0 - 125.0).abs()}');
      print(
          'Distance to top edge: ${(125.0 - 100.0).abs()}'); // Configure element snapping and disable grid
      alignmentManager.configureGrid(enabled: false);
      alignmentManager.configureElementSnap(
        snapDistance: 10.0,
        enabled: true,
      );

      // Test position near element edge
      final result = alignmentManager.alignPosition(
        const Offset(95.0, 125.0), // Near left edge of element
        [],
      );

      print('Result position: ${result.alignedPosition}');
      print('Was aligned: ${result.wasAligned}');
      print('Applied snaps: ${result.appliedSnaps.length}');
      if (result.appliedSnaps.isNotEmpty) {
        print('Snap type: ${result.appliedSnaps.first.snapType}');
      }
      print('Guides: ${result.guides.length}');

      // Test exclusion
      final excludeResult = alignmentManager.alignPosition(
        const Offset(95.0, 125.0),
        ['ref1'], // Exclude the reference element
      );
      print('Exclude result - was aligned: ${excludeResult.wasAligned}');
    });
  });
}
