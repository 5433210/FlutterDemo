import 'package:charasgem/presentation/widgets/practice/advanced_cache_manager.dart';
import 'package:charasgem/presentation/widgets/practice/element_cache_manager.dart';
import 'package:charasgem/presentation/widgets/practice/element_snapshot.dart';
import 'package:charasgem/presentation/widgets/practice/memory_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdvancedElementCacheManager Tests', () {
    late ElementCacheManager baseCacheManager;
    late MemoryManager memoryManager;
    late ElementSnapshotManager snapshotManager;
    late AdvancedElementCacheManager advancedCacheManager;

    setUp(() {
      baseCacheManager = ElementCacheManager();
      memoryManager = MemoryManager();
      snapshotManager = ElementSnapshotManager();

      advancedCacheManager = AdvancedElementCacheManager(
        baseCacheManager: baseCacheManager,
        memoryManager: memoryManager,
        snapshotManager: snapshotManager,
      );
    });

    test('WeakElementCache basic functionality', () {
      // Create WeakElementCache instance
      final weakCache = WeakElementCache();

      // Store widgets
      const widget1 = SizedBox(width: 100, height: 100);
      const widget2 = Text('Test Widget');

      weakCache.put('widget1', widget1);
      weakCache.put('widget2', widget2);

      // Verify size
      expect(weakCache.size, 2);
      expect(weakCache.keys.contains('widget1'), true);
      expect(weakCache.keys.contains('widget2'), true);

      // Retrieve widgets
      final retrievedWidget1 = weakCache.get('widget1');
      expect(retrievedWidget1, widget1);

      // Remove a widget
      weakCache.remove('widget1');
      expect(weakCache.size, 1);
      expect(weakCache.keys.contains('widget1'), false);

      // Clear all
      weakCache.clear();
      expect(weakCache.size, 0);
    });

    test('AdvancedElementCacheManager basic functionality', () {
      // Test storing and retrieving widgets
      const testWidget = SizedBox(width: 200, height: 200);
      final properties = {
        'id': 'test1',
        'type': 'container',
        'width': 200.0,
        'height': 200.0,
      };

      // Store widget
      advancedCacheManager.storeElementWidget(
        'test1',
        testWidget,
        properties,
        elementType: 'container',
      );

      // Retrieve widget
      final retrievedWidget =
          advancedCacheManager.getElementWidget('test1', 'container');
      expect(retrievedWidget, isNotNull);

      // Get cache metrics
      final metrics = advancedCacheManager.getCacheMetrics();
      expect(metrics, isNotNull);

      // Mark element for update and verify it's removed from cache
      advancedCacheManager.markElementForUpdate('test1');
      final afterUpdateWidget =
          advancedCacheManager.getElementWidget('test1', 'container');
      expect(afterUpdateWidget, isNull);
    });

    test('Heat map functionality', () {
      // Add multiple elements and access them different number of times
      for (int i = 0; i < 10; i++) {
        final id = 'element$i';
        const widget = SizedBox(width: 100, height: 100);
        final properties = {'id': id, 'type': 'container'};

        advancedCacheManager.storeElementWidget(id, widget, properties);

        // Access elements with different frequencies to create heat map
        for (int j = 0; j < i; j++) {
          advancedCacheManager.getElementWidget(id, 'container');
        }
      }

      // Get heat map visualization
      final heatMap = advancedCacheManager.getHeatMapVisualization();
      expect(heatMap, isNotNull);
      expect(heatMap['elements'], isNotNull);

      // Verify heat levels distribution
      final summary = heatMap['summary'] as Map<String, dynamic>;
      expect(summary, isNotNull);
    });
  });
}
