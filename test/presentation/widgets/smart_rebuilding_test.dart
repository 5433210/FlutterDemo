import 'package:charasgem/presentation/pages/practices/widgets/element_change_types.dart';
import 'package:charasgem/presentation/widgets/practice/dirty_tracker.dart';
import 'package:charasgem/presentation/widgets/practice/element_cache_manager.dart';
import 'package:charasgem/presentation/widgets/practice/selective_rebuild_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DirtyTracker Tests', () {
    late DirtyTracker dirtyTracker;

    setUp(() {
      dirtyTracker = DirtyTracker();
    });

    tearDown(() {
      dirtyTracker.dispose();
    });

    test('should mark elements as dirty and clean', () {
      expect(dirtyTracker.isElementDirty('element1'), isFalse);

      // Mark as dirty
      dirtyTracker.markElementDirty('element1', ElementChangeType.positionOnly);
      expect(dirtyTracker.isElementDirty('element1'), isTrue);
      expect(dirtyTracker.dirtyElements.contains('element1'), isTrue);
      expect(dirtyTracker.getDirtyReasons('element1'),
          contains(ElementChangeType.positionOnly));

      // Mark as clean
      dirtyTracker.markElementClean('element1');
      expect(dirtyTracker.isElementDirty('element1'), isFalse);
      expect(dirtyTracker.getElementVersion('element1'),
          equals(1)); // Global version incremented
    });

    test('should handle batch operations efficiently', () {
      // Start batch
      dirtyTracker.startBatch();

      // Mark multiple elements dirty
      dirtyTracker.markElementDirty('element1', ElementChangeType.positionOnly);
      dirtyTracker.markElementDirty('element2', ElementChangeType.sizeOnly);
      dirtyTracker.markElementDirty('element3', ElementChangeType.contentOnly);

      // Elements should not be dirty yet (batch mode)
      expect(dirtyTracker.dirtyElements.length, equals(0));

      // End batch
      dirtyTracker.endBatch();

      // Now elements should be dirty
      expect(dirtyTracker.dirtyElements.length, equals(3));
      expect(dirtyTracker.isElementDirty('element1'), isTrue);
      expect(dirtyTracker.isElementDirty('element2'), isTrue);
      expect(dirtyTracker.isElementDirty('element3'), isTrue);
    });

    test('should track dirty reasons correctly', () {
      dirtyTracker.markElementDirty('element1', ElementChangeType.positionOnly);
      dirtyTracker.markElementDirty('element1', ElementChangeType.opacity);

      final reasons = dirtyTracker.getDirtyReasons('element1');
      expect(reasons.length, equals(2));
      expect(reasons, contains(ElementChangeType.positionOnly));
      expect(reasons, contains(ElementChangeType.opacity));
    });
    test('should provide accurate statistics', () {
      dirtyTracker.markElementDirty('element1', ElementChangeType.positionOnly);
      dirtyTracker.markElementDirty('element2', ElementChangeType.sizeOnly);
      dirtyTracker.markElementClean('element1');

      final stats = dirtyTracker.getStats();
      expect(stats.dirtyElementsCount, equals(1)); // Only element2 is dirty
      expect(
          stats.totalTrackedElements, equals(1)); // Only element1 has a version
      expect(stats.globalVersion, equals(3)); // 3 operations = version 3
    });
  });

  group('SelectiveRebuildManager Tests', () {
    late DirtyTracker dirtyTracker;
    late ElementCacheManager cacheManager;
    late SelectiveRebuildManager rebuildManager;

    setUp(() {
      dirtyTracker = DirtyTracker();
      cacheManager = ElementCacheManager();
      rebuildManager = SelectiveRebuildManager(
        dirtyTracker: dirtyTracker,
        cacheManager: cacheManager,
      );
    });

    tearDown(() {
      rebuildManager.dispose();
      cacheManager.dispose();
      dirtyTracker.dispose();
    });

    test('should determine rebuild necessity correctly', () {
      // Initially no rebuild needed
      expect(rebuildManager.shouldRebuildElement('element1'), isFalse);

      // Mark as dirty
      dirtyTracker.markElementDirty('element1', ElementChangeType.positionOnly);
      expect(rebuildManager.shouldRebuildElement('element1'), isTrue);

      // After rebuild completion
      rebuildManager.startElementRebuild('element1');
      rebuildManager.completeElementRebuild('element1', Container());
      expect(rebuildManager.shouldRebuildElement('element1'), isFalse);
    });

    test('should track rebuild metrics', () {
      dirtyTracker.markElementDirty('element1', ElementChangeType.positionOnly);
      dirtyTracker.markElementDirty('element2', ElementChangeType.sizeOnly);

      // Complete one rebuild
      rebuildManager.startElementRebuild('element1');
      rebuildManager.completeElementRebuild('element1', Container());

      // Skip one rebuild
      rebuildManager.skipElementRebuild('element2', 'test reason');

      final metrics = rebuildManager.getMetrics();
      expect(metrics.totalRebuilds, equals(1));
      expect(metrics.skippedRebuilds, equals(1));
      expect(metrics.rebuildEfficiency, equals(0.5)); // 50% skipped
    });

    test('should provide appropriate rebuild strategies', () {
      // Test different change types
      expect(
        rebuildManager.getRebuildStrategy(
            'element1', ElementChangeType.contentOnly),
        equals(RebuildStrategy.contentUpdate),
      );

      expect(
        rebuildManager.getRebuildStrategy(
            'element1', ElementChangeType.positionOnly),
        equals(RebuildStrategy.layoutUpdate),
      );

      expect(
        rebuildManager.getRebuildStrategy(
            'element1', ElementChangeType.sizeOnly),
        equals(RebuildStrategy.fullRebuild),
      );

      expect(
        rebuildManager.getRebuildStrategy(
            'element1', ElementChangeType.opacity),
        equals(RebuildStrategy.minimalRebuild),
      );
    });

    test('should prevent circular rebuilds', () {
      dirtyTracker.markElementDirty('element1', ElementChangeType.positionOnly);

      expect(rebuildManager.shouldRebuildElement('element1'), isTrue);

      // Start rebuild
      rebuildManager.startElementRebuild('element1');

      // Should not rebuild while already rebuilding
      expect(rebuildManager.shouldRebuildElement('element1'), isFalse);

      // Complete rebuild
      rebuildManager.completeElementRebuild('element1', Container());

      // Can rebuild again if marked dirty
      dirtyTracker.markElementDirty('element1', ElementChangeType.sizeOnly);
      expect(rebuildManager.shouldRebuildElement('element1'), isTrue);
    });

    test('should handle batch rebuild efficiently', () {
      final elementIds = ['element1', 'element2', 'element3'];

      // Mark some elements dirty
      dirtyTracker.markElementDirty('element1', ElementChangeType.positionOnly);
      dirtyTracker.markElementDirty('element3', ElementChangeType.sizeOnly);
      // element2 is not dirty

      final rebuiltElements = rebuildManager.processBatchRebuild(elementIds);

      expect(rebuiltElements.length, equals(2)); // Only element1 and element3
      expect(rebuiltElements, contains('element1'));
      expect(rebuiltElements, contains('element3'));
      expect(rebuiltElements, isNot(contains('element2')));

      final metrics = rebuildManager.getMetrics();
      expect(metrics.skippedRebuilds, equals(1)); // element2 was skipped
    });
  });

  group('Integration Tests', () {
    late DirtyTracker dirtyTracker;
    late ElementCacheManager cacheManager;
    late SelectiveRebuildManager rebuildManager;

    setUp(() {
      dirtyTracker = DirtyTracker();
      cacheManager = ElementCacheManager();
      rebuildManager = SelectiveRebuildManager(
        dirtyTracker: dirtyTracker,
        cacheManager: cacheManager,
      );
    });

    void tearDown() {
      rebuildManager.dispose();
      cacheManager.dispose();
      dirtyTracker.dispose();
    }

    test('should optimize rebuild efficiency in realistic scenario', () {
      // Simulate a canvas with 10 elements
      final elementIds = List.generate(10, (i) => 'element_$i');

      // Mark all elements for initial render
      for (final id in elementIds) {
        dirtyTracker.markElementDirty(id, ElementChangeType.created);
      }

      // Process initial batch rebuild
      var rebuiltElements = rebuildManager.processBatchRebuild(elementIds);
      expect(rebuiltElements.length, equals(10)); // All need initial render

      // Complete rebuilds
      for (final id in rebuiltElements) {
        rebuildManager.startElementRebuild(id);
        rebuildManager.completeElementRebuild(id, Container());
      }

      // Now only modify 2 elements
      dirtyTracker.markElementDirty(
          'element_1', ElementChangeType.positionOnly);
      dirtyTracker.markElementDirty('element_5',
          ElementChangeType.sizeOnly); // Process second batch rebuild
      rebuiltElements = rebuildManager.processBatchRebuild(elementIds);
      expect(rebuiltElements.length, equals(2)); // Only 2 need rebuild

      // Complete the second batch rebuilds (this was missing!)
      for (final id in rebuiltElements) {
        rebuildManager.startElementRebuild(id);
        rebuildManager.completeElementRebuild(id, Container());
      }
      final metrics = rebuildManager.getMetrics();
      expect(metrics.rebuildEfficiency,
          greaterThanOrEqualTo(0.4)); // ≥40% efficiency
      expect(metrics.totalRebuilds, equals(12)); // 10 initial + 2 updates
      expect(metrics.skippedRebuilds,
          equals(8)); // 8 elements skipped in second batch
    });
  });
}
