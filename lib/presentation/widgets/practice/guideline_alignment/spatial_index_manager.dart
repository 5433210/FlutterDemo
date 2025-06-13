import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';

/// 空间索引配置
class SpatialIndexConfig {
  final int maxElementsPerNode;
  final int maxDepth;
  final double queryRadius;
  final bool enableCaching;

  const SpatialIndexConfig({
    this.maxElementsPerNode = 10,
    this.maxDepth = 6,
    this.queryRadius = 50.0,
    this.enableCaching = true,
  });
}

/// 空间索引管理器，用于快速查找附近的元素进行参考线对齐
class SpatialIndexManager {
  static const int _maxElementsPerNode = 10;
  static const int _maxDepth = 6;

  SpatialIndexNode? _root;
  final Map<String, Rect> _elementBounds = {};

  /// 构建空间索引
  void buildIndex(List<Map<String, dynamic>> elements) {
    _elementBounds.clear();

    // 🔧 调试：记录输入元素数量
    EditPageLogger.editPageDebug(
      '🔧 SpatialIndex构建开始',
      data: {
        'inputElementsCount': elements.length,
        'operation': 'spatial_index_build_start',
      },
    );

    // 收集所有元素的边界框
    for (final element in elements) {
      final id = element['id'] as String;
      final rect = _calculateElementBounds(element);
      if (rect != null) {
        _elementBounds[id] = rect;
        EditPageLogger.editPageDebug(
          '🔧 添加元素到空间索引',
          data: {
            'elementId': id,
            'bounds': '${rect.left},${rect.top},${rect.width},${rect.height}',
            'operation': 'add_element_to_index',
          },
        );
      } else {
        EditPageLogger.editPageDebug(
          '🔧 跳过无效元素',
          data: {
            'elementId': id,
            'elementData': element,
            'reason': '缺少位置或尺寸信息',
            'operation': 'skip_invalid_element',
          },
        );
      }
    }

    EditPageLogger.editPageDebug(
      '🔧 空间索引元素收集完成',
      data: {
        'validElementsCount': _elementBounds.length,
        'invalidElementsCount': elements.length - _elementBounds.length,
        'operation': 'element_collection_complete',
      },
    );

    if (_elementBounds.isEmpty) {
      _root = null;
      return;
    }

    // 计算总边界
    final allBounds = _calculateTotalBounds(_elementBounds.values.toList());
    EditPageLogger.editPageDebug(
      '🔧 计算总边界',
      data: {
        'totalBounds':
            '${allBounds.left},${allBounds.top},${allBounds.width},${allBounds.height}',
        'operation': 'calculate_total_bounds',
      },
    );

    // 构建四叉树
    _root = _buildQuadTree(
      bounds: allBounds,
      elementIds: _elementBounds.keys.toList(),
      level: 0,
    );

    EditPageLogger.editPageDebug(
      '🔧 四叉树构建完成',
      data: {
        'rootLevel': _root?.level,
        'rootIsLeaf': _root?.isLeaf,
        'totalElements': _elementBounds.length,
        'operation': 'quadtree_build_complete',
      },
    );
  }

  /// 清空索引
  void clear() {
    _root = null;
    _elementBounds.clear();
  }

  /// 🔧 调试：强制搜索所有元素（如果空间索引失败）
  List<String> findAllElementsWithinDistance(
    Offset point, {
    double maxDistance = 50.0,
    int maxResults = 10,
  }) {
    EditPageLogger.editPageDebug(
      '🔧 强制搜索开始',
      data: {
        'queryPoint': '${point.dx},${point.dy}',
        'maxDistance': maxDistance,
        'maxResults': maxResults,
        'totalElements': _elementBounds.length,
        'operation': 'force_search_start',
      },
    );

    final distanceMap = <String, double>{};

    for (final entry in _elementBounds.entries) {
      final distance = _calculateDistanceToRect(point, entry.value);
      if (distance <= maxDistance) {
        distanceMap[entry.key] = distance;
      }
    }

    final sortedCandidates = distanceMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final result = sortedCandidates.take(maxResults).map((e) => e.key).toList();

    EditPageLogger.editPageDebug(
      '🔧 强制搜索完成',
      data: {
        'queryPoint': '${point.dx},${point.dy}',
        'maxDistance': maxDistance,
        'totalElements': _elementBounds.length,
        'filteredCount': distanceMap.length,
        'resultCount': result.length,
        'resultIds': result,
        'operation': 'force_search_complete',
      },
    );

    return result;
  }

  /// 查找距离指定点最近的元素
  List<String> findNearestElements(
    Offset point, {
    double maxDistance = 50.0,
    int maxResults = 10,
  }) {
    if (_root == null || _elementBounds.isEmpty) {
      return [];
    }

    // 🔧 调试：记录查询参数
    EditPageLogger.editPageDebug(
      '🔧 SpatialIndex查询开始',
      data: {
        'queryPoint': '${point.dx},${point.dy}',
        'maxDistance': maxDistance,
        'maxResults': maxResults,
        'totalElements': _elementBounds.length,
        'operation': 'spatial_index_query_start',
      },
    );

    // 创建查询区域
    final queryBounds = Rect.fromCenter(
      center: point,
      width: maxDistance * 2,
      height: maxDistance * 2,
    );

    final candidates = query(queryBounds);
    EditPageLogger.editPageDebug(
      '🔧 区域查询结果',
      data: {
        'candidatesCount': candidates.length,
        'candidateIds': candidates,
        'queryBounds':
            '${queryBounds.left},${queryBounds.top},${queryBounds.width},${queryBounds.height}',
        'operation': 'region_query_result',
      },
    );

    // 按距离排序
    final distanceMap = <String, double>{};
    for (final id in candidates) {
      final bounds = _elementBounds[id];
      if (bounds != null) {
        final distance = _calculateDistanceToRect(point, bounds);
        EditPageLogger.editPageDebug(
          '🔧 计算元素距离',
          data: {
            'elementId': id,
            'distance': distance,
            'elementBounds':
                '${bounds.left},${bounds.top},${bounds.width},${bounds.height}',
            'withinRange': distance <= maxDistance,
            'operation': 'calculate_element_distance',
          },
        );
        if (distance <= maxDistance) {
          distanceMap[id] = distance;
        }
      }
    }

    final sortedCandidates = distanceMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final result = sortedCandidates.take(maxResults).map((e) => e.key).toList();

    EditPageLogger.editPageDebug(
      '🔧 SpatialIndex查询完成',
      data: {
        'queryPoint': '${point.dx},${point.dy}',
        'maxDistance': maxDistance,
        'candidatesCount': candidates.length,
        'filteredCount': distanceMap.length,
        'resultCount': result.length,
        'resultIds': result,
        'operation': 'spatial_index_query_complete',
      },
    );

    return result;
  }

  /// 🔧 调试：获取空间索引状态信息
  Map<String, dynamic> getDebugInfo() {
    return {
      'hasRoot': _root != null,
      'totalElements': _elementBounds.length,
      'elementIds': _elementBounds.keys.toList(),
      'elementBounds': _elementBounds.map((id, bounds) => MapEntry(
          id, '${bounds.left},${bounds.top},${bounds.width},${bounds.height}')),
      'rootBounds': _root?.bounds.toString(),
      'rootLevel': _root?.level,
      'rootIsLeaf': _root?.isLeaf,
    };
  }

  /// 获取元素边界
  Rect? getElementBounds(String elementId) {
    return _elementBounds[elementId];
  }

  /// 查找指定区域内的元素
  List<String> query(Rect queryBounds) {
    if (_root == null) return [];

    final result = <String>[];
    _queryNode(_root!, queryBounds, result);
    return result;
  }

  SpatialIndexNode _buildQuadTree({
    required Rect bounds,
    required List<String> elementIds,
    required int level,
  }) {
    // 如果元素数量少或者达到最大深度，创建叶子节点
    if (elementIds.length <= _maxElementsPerNode || level >= _maxDepth) {
      return SpatialIndexNode(
        bounds: bounds,
        elementIds: elementIds,
        children: [],
        level: level,
      );
    }

    // 分割成四个象限
    final centerX = bounds.left + bounds.width / 2;
    final centerY = bounds.top + bounds.height / 2;

    final quadrants = [
      // 左上
      Rect.fromLTRB(bounds.left, bounds.top, centerX, centerY),
      // 右上
      Rect.fromLTRB(centerX, bounds.top, bounds.right, centerY),
      // 左下
      Rect.fromLTRB(bounds.left, centerY, centerX, bounds.bottom),
      // 右下
      Rect.fromLTRB(centerX, centerY, bounds.right, bounds.bottom),
    ];

    final children = <SpatialIndexNode>[];

    for (final quadrant in quadrants) {
      final quadrantElements = elementIds.where((id) {
        final elementBounds = _elementBounds[id];
        return elementBounds != null &&
            _rectsIntersect(quadrant, elementBounds);
      }).toList();

      if (quadrantElements.isNotEmpty) {
        children.add(_buildQuadTree(
          bounds: quadrant,
          elementIds: quadrantElements,
          level: level + 1,
        ));
      }
    }

    return SpatialIndexNode(
      bounds: bounds,
      elementIds: [], // 非叶子节点不存储元素
      children: children,
      level: level,
    );
  }

  double _calculateDistanceToRect(Offset point, Rect rect) {
    final dx =
        math.max(0, math.max(rect.left - point.dx, point.dx - rect.right));
    final dy =
        math.max(0, math.max(rect.top - point.dy, point.dy - rect.bottom));
    return math.sqrt(dx * dx + dy * dy);
  }

  // 私有方法

  Rect? _calculateElementBounds(Map<String, dynamic> element) {
    final x = (element['x'] as num?)?.toDouble();
    final y = (element['y'] as num?)?.toDouble();
    final width = (element['width'] as num?)?.toDouble();
    final height = (element['height'] as num?)?.toDouble();

    if (x == null || y == null || width == null || height == null) {
      return null;
    }

    return Rect.fromLTWH(x, y, width, height);
  }

  Rect _calculateTotalBounds(List<Rect> rects) {
    if (rects.isEmpty) {
      return Rect.zero;
    }

    double left = rects[0].left;
    double top = rects[0].top;
    double right = rects[0].right;
    double bottom = rects[0].bottom;

    for (int i = 1; i < rects.length; i++) {
      final rect = rects[i];
      left = math.min(left, rect.left);
      top = math.min(top, rect.top);
      right = math.max(right, rect.right);
      bottom = math.max(bottom, rect.bottom);
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _queryNode(
      SpatialIndexNode node, Rect queryBounds, List<String> result) {
    // 检查节点边界是否与查询区域相交
    if (!_rectsIntersect(node.bounds, queryBounds)) {
      return;
    }

    if (node.isLeaf) {
      // 叶子节点，检查每个元素
      for (final elementId in node.elementIds) {
        final elementBounds = _elementBounds[elementId];
        if (elementBounds != null &&
            _rectsIntersect(queryBounds, elementBounds)) {
          result.add(elementId);
        }
      }
    } else {
      // 递归查询子节点
      for (final child in node.children) {
        _queryNode(child, queryBounds, result);
      }
    }
  }

  bool _rectsIntersect(Rect a, Rect b) {
    return !(a.right < b.left ||
        b.right < a.left ||
        a.bottom < b.top ||
        b.bottom < a.top);
  }
}

/// 空间索引节点
class SpatialIndexNode {
  final Rect bounds;
  final List<String> elementIds;
  final List<SpatialIndexNode> children;
  final int level;

  const SpatialIndexNode({
    required this.bounds,
    required this.elementIds,
    required this.children,
    required this.level,
  });

  bool get isLeaf => children.isEmpty;
}
