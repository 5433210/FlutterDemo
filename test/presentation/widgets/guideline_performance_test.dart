import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:charasgem/presentation/widgets/practice/guideline_alignment/guideline_cache_manager.dart';
import 'package:charasgem/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';
import 'package:charasgem/presentation/widgets/practice/guideline_alignment/guideline_types.dart';
import 'package:charasgem/presentation/widgets/practice/guideline_alignment/spatial_index_manager.dart';

void main() {
  group('Guideline Performance Optimizations', () {
    group('SpatialIndexManager', () {
      test('should build spatial index and query nearby elements', () {
        final spatialIndex = SpatialIndexManager();

        // 创建测试元素
        final elements = [
          {'id': 'elem1', 'x': 10.0, 'y': 10.0, 'width': 50.0, 'height': 30.0},
          {
            'id': 'elem2',
            'x': 100.0,
            'y': 100.0,
            'width': 40.0,
            'height': 40.0
          },
          {'id': 'elem3', 'x': 15.0, 'y': 15.0, 'width': 30.0, 'height': 20.0},
          {
            'id': 'elem4',
            'x': 200.0,
            'y': 200.0,
            'width': 60.0,
            'height': 50.0
          },
        ];

        // 构建索引
        spatialIndex.buildIndex(elements);

        // 查找 (20, 20) 附近的元素
        final nearbyElements = spatialIndex.findNearestElements(
          const Offset(20, 20),
          maxDistance: 50.0,
        );

        // 应该找到 elem1 和 elem3
        expect(nearbyElements.length, greaterThanOrEqualTo(2));
        expect(nearbyElements, contains('elem1'));
        expect(nearbyElements, contains('elem3'));
      });

      test('should handle empty elements list', () {
        final spatialIndex = SpatialIndexManager();

        spatialIndex.buildIndex([]);
        final result = spatialIndex.findNearestElements(const Offset(100, 100));

        expect(result, isEmpty);
      });
    });

    group('GuidelineCacheManager', () {
      late GuidelineCacheManager cacheManager;

      setUp(() {
        cacheManager = GuidelineCacheManager(maxCacheSize: 5);
      });

      test('should cache and retrieve guidelines', () {
        final guidelines = [
          const Guideline(
            id: 'test1',
            type: GuidelineType.verticalCenterLine,
            position: 100.0,
            direction: AlignmentDirection.vertical,
            sourceElementId: 'elem1',
            sourceElementBounds: Rect.fromLTWH(50, 50, 100, 100),
          ),
        ];

        // 缓存参考线
        cacheManager.cacheGuidelines(
          elementId: 'elem1',
          x: 10.0,
          y: 20.0,
          width: 50.0,
          height: 30.0,
          targetElementIds: ['elem2', 'elem3'],
          guidelines: guidelines,
        );

        // 检索参考线
        final cached = cacheManager.getCachedGuidelines(
          elementId: 'elem1',
          x: 10.0,
          y: 20.0,
          width: 50.0,
          height: 30.0,
          targetElementIds: ['elem2', 'elem3'],
        );

        expect(cached, isNotNull);
        expect(cached!.length, equals(1));
        expect(cached[0].id, equals('test1'));
      });

      test('should return null for cache miss', () {
        final cached = cacheManager.getCachedGuidelines(
          elementId: 'nonexistent',
          x: 10.0,
          y: 20.0,
          width: 50.0,
          height: 30.0,
          targetElementIds: ['elem1'],
        );

        expect(cached, isNull);
      });

      test('should respect cache size limit', () {
        const guideline = Guideline(
          id: 'test',
          type: GuidelineType.verticalCenterLine,
          position: 100.0,
          direction: AlignmentDirection.vertical,
          sourceElementId: 'elem1',
          sourceElementBounds: Rect.fromLTWH(50, 50, 100, 100),
        );

        // 添加超过缓存大小限制的项
        for (int i = 0; i < 10; i++) {
          cacheManager.cacheGuidelines(
            elementId: 'elem$i',
            x: i.toDouble(),
            y: i.toDouble(),
            width: 50.0,
            height: 30.0,
            targetElementIds: ['target$i'],
            guidelines: [guideline],
          );
        }

        final stats = cacheManager.getCacheStats();
        expect(stats.cacheSize, lessThanOrEqualTo(5));
      });

      test('should invalidate specific element cache', () {
        const guideline = Guideline(
          id: 'test',
          type: GuidelineType.verticalCenterLine,
          position: 100.0,
          direction: AlignmentDirection.vertical,
          sourceElementId: 'elem1',
          sourceElementBounds: Rect.fromLTWH(50, 50, 100, 100),
        );

        // 缓存参考线
        cacheManager.cacheGuidelines(
          elementId: 'elem1',
          x: 10.0,
          y: 20.0,
          width: 50.0,
          height: 30.0,
          targetElementIds: ['elem2'],
          guidelines: [guideline],
        );

        // 验证缓存存在
        var cached = cacheManager.getCachedGuidelines(
          elementId: 'elem1',
          x: 10.0,
          y: 20.0,
          width: 50.0,
          height: 30.0,
          targetElementIds: ['elem2'],
        );
        expect(cached, isNotNull);

        // 无效化缓存
        cacheManager.invalidateElementCache('elem1');

        // 验证缓存已被清除
        cached = cacheManager.getCachedGuidelines(
          elementId: 'elem1',
          x: 10.0,
          y: 20.0,
          width: 50.0,
          height: 30.0,
          targetElementIds: ['elem2'],
        );
        expect(cached, isNull);
      });
    });

    group('GuidelineManager Performance', () {
      late GuidelineManager manager;

      setUp(() {
        manager = GuidelineManager.instance;
      });

      test('should provide cache statistics', () {
        final stats = manager.getCacheStats();
        expect(stats, isA<GuidelineCacheStats>());
      });

      test('should find nearby elements using spatial index', () {
        // 初始化一些测试元素
        final elements = [
          {'id': 'elem1', 'x': 10.0, 'y': 10.0, 'width': 50.0, 'height': 30.0},
          {
            'id': 'elem2',
            'x': 100.0,
            'y': 100.0,
            'width': 40.0,
            'height': 40.0
          },
          {'id': 'elem3', 'x': 15.0, 'y': 15.0, 'width': 30.0, 'height': 20.0},
        ];

        manager.initialize(
          elements: elements,
          pageSize: const Size(800, 600),
          enabled: true,
        );

        final nearbyElements = manager.getNearbyElements(
          const Offset(20, 20),
          radius: 50.0,
        );

        expect(nearbyElements, isA<List<String>>());
      });

      test('should handle cache cleanup', () {
        manager.cleanupCache();
        manager.clearCache();
        manager.invalidateElementCache('test');

        // 这些方法应该不抛出异常
        expect(() => manager.rebuildSpatialIndex(), returnsNormally);
      });
    });
  });
}
