import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'guideline_cache_manager.dart';
import 'guideline_types.dart';
import 'spatial_index_manager.dart';

/// 参考线管理器 - 负责生成和管理参考线
class GuidelineManager {
  /// 单例实例
  static final GuidelineManager instance = GuidelineManager._();
  // 性能优化组件
  final GuidelineCacheManager _cacheManager = GuidelineCacheManager();

  final SpatialIndexManager _spatialIndex = SpatialIndexManager();

  /// 当前页面所有元素
  final List<Map<String, dynamic>> _elements = [];

  /// 当前活动的参考线
  final List<Guideline> _activeGuidelines = [];

  /// 页面尺寸
  Size _pageSize = Size.zero;

  /// 是否启用参考线
  bool _enabled = false;

  /// 参考线对齐阈值（像素）
  double _snapThreshold = 5.0;

  // 回调函数，用于同步参考线到外部列表
  Function(List<Guideline>)? _syncGuidelinesToOutput;

  /// 私有构造函数
  GuidelineManager._();

  /// 获取活动参考线列表
  List<Guideline> get activeGuidelines => List.unmodifiable(_activeGuidelines);

  /// 获取参考线启用状态
  bool get enabled => _enabled;

  /// 更新参考线启用状态
  set enabled(bool value) {
    if (_enabled != value) {
      _enabled = value;

      // 如果禁用参考线，清空所有活动参考线
      if (!_enabled) {
        clearGuidelines();
      }
    }
  }

  /// 获取参考线阈值
  double get snapThreshold => _snapThreshold;

  /// 设置参考线阈值
  set snapThreshold(double value) {
    if (value >= 0) {
      _snapThreshold = value;
    }
  }

  /// 添加参考线
  void addGuideline(Guideline guideline) {
    // 防止重复
    if (_activeGuidelines.any((g) => g.isEquivalentTo(guideline))) {
      EditPageLogger.editPageDebug('跳过重复参考线');
      return;
    }

    _activeGuidelines.add(guideline);
    EditPageLogger.editPageDebug(
      '添加参考线',
      data: {
        'type': guideline.type.toString(),
        'direction': guideline.direction.toString(),
        'position': guideline.position,
        'totalGuidelines': _activeGuidelines.length,
      },
    );

    // 同步到输出列表
    if (_syncGuidelinesToOutput != null) {
      _syncGuidelinesToOutput!(_activeGuidelines);
    }
  }

  /// 计算对齐后的位置
  Map<String, double> calculateAlignedPosition({
    required Offset originalPosition,
    required Size size,
  }) {
    // 如果没有参考线，或未启用对齐，直接返回原始位置
    if (!_enabled || _activeGuidelines.isEmpty) {
      return {
        'x': originalPosition.dx,
        'y': originalPosition.dy,
      };
    }

    double alignedX = originalPosition.dx;
    double alignedY = originalPosition.dy;

    // 查找最佳水平对齐（影响Y坐标）
    double? bestY;
    double minYDistance = double.infinity;

    for (final guideline in _activeGuidelines
        .where((g) => g.direction == AlignmentDirection.horizontal)) {
      double candidateY;

      switch (guideline.type) {
        case GuidelineType.horizontalCenterLine:
          // 中心对齐
          candidateY = guideline.position - size.height / 2;
          break;
        case GuidelineType.horizontalTopEdge:
          // 上边缘对齐
          candidateY = guideline.position;
          break;
        case GuidelineType.horizontalBottomEdge:
          // 下边缘对齐
          candidateY = guideline.position - size.height;
          break;
        default:
          continue;
      }

      // 选择距离原始位置最近的对齐选项
      final distance = (candidateY - originalPosition.dy).abs();
      if (distance < minYDistance) {
        minYDistance = distance;
        bestY = candidateY;
      }
    }

    if (bestY != null) {
      alignedY = bestY;
    }

    // 查找最佳垂直对齐（影响X坐标）
    double? bestX;
    double minXDistance = double.infinity;

    for (final guideline in _activeGuidelines
        .where((g) => g.direction == AlignmentDirection.vertical)) {
      double candidateX;

      switch (guideline.type) {
        case GuidelineType.verticalCenterLine:
          // 中心对齐
          candidateX = guideline.position - size.width / 2;
          break;
        case GuidelineType.verticalLeftEdge:
          // 左边缘对齐
          candidateX = guideline.position;
          break;
        case GuidelineType.verticalRightEdge:
          // 右边缘对齐
          candidateX = guideline.position - size.width;
          break;
        default:
          continue;
      }

      // 选择距离原始位置最近的对齐选项
      final distance = (candidateX - originalPosition.dx).abs();
      if (distance < minXDistance) {
        minXDistance = distance;
        bestX = candidateX;
      }
    }

    if (bestX != null) {
      alignedX = bestX;
    }

    return {
      'x': alignedX,
      'y': alignedY,
    };
  }

  /// 清理过期的缓存项
  void cleanupCache() {
    _cacheManager.cleanupExpiredEntries();
  }

  /// 清空所有缓存
  void clearCache() {
    _cacheManager.clearCache();
  }

  /// 清空所有参考线
  void clearGuidelines() {
    if (_activeGuidelines.isNotEmpty) {
      _activeGuidelines.clear();

      EditPageLogger.editPageDebug(
        '清空参考线',
        data: {
          'operation': 'clear_guidelines',
        },
      );

      // 同步到输出列表
      if (_syncGuidelinesToOutput != null) {
        _syncGuidelinesToOutput!(_activeGuidelines);
      }
    }
  }

  /// 检测对齐并返回调整后的位置
  Map<String, dynamic>? detectAlignment({
    required String elementId,
    required Offset currentPosition,
    required Size elementSize,
    double? rotation,
  }) {
    // 如果未启用参考线，直接返回null
    if (!_enabled) {
      return null;
    }

    // 生成参考线
    final hasGuidelines = generateGuidelines(
      elementId: elementId,
      draftPosition: currentPosition,
      draftSize: elementSize,
      rotation: rotation,
    );

    if (!hasGuidelines || _activeGuidelines.isEmpty) {
      return null;
    }

    // 计算对齐后的位置
    final alignedPosition = calculateAlignedPosition(
      originalPosition: currentPosition,
      size: elementSize,
    );

    // 检查是否有位置调整
    final adjustedX = alignedPosition['x'];
    final adjustedY = alignedPosition['y'];

    if (adjustedX != null && adjustedY != null) {
      final newPosition = Offset(adjustedX, adjustedY);

      // 如果新位置与当前位置不同，返回对齐结果
      if ((newPosition - currentPosition).distance > 0.1) {
        EditPageLogger.editPageDebug(
          '检测到对齐',
          data: {
            'elementId': elementId,
            'originalPosition':
                '(${currentPosition.dx}, ${currentPosition.dy})',
            'alignedPosition': '(${newPosition.dx}, ${newPosition.dy})',
            'activeGuidelines': _activeGuidelines.length,
            'operation': 'detect_alignment',
          },
        );

        return {
          'position': newPosition,
          'guidelines': List<Guideline>.from(_activeGuidelines),
          'hasAlignment': true,
        };
      }
    }

    return null;
  }

  /// 为指定元素生成参考线
  bool generateGuidelines({
    required String elementId,
    required Offset draftPosition,
    required Size draftSize,
    double? rotation,
  }) {
    // 如果未启用参考线，直接返回
    if (!_enabled) {
      return false;
    }

    // 使用空间索引查找附近的元素以优化性能
    final nearbyElementIds = _spatialIndex.findNearestElements(
      draftPosition,
      maxDistance: 100.0, // 扩大搜索范围以包含更多候选元素
      maxResults: 20,
    );

    // 检查缓存
    final cachedGuidelines = _cacheManager.getCachedGuidelines(
      elementId: elementId,
      x: draftPosition.dx,
      y: draftPosition.dy,
      width: draftSize.width,
      height: draftSize.height,
      targetElementIds: nearbyElementIds,
    );

    if (cachedGuidelines != null) {
      // 使用缓存的参考线
      _activeGuidelines.clear();
      _activeGuidelines.addAll(cachedGuidelines);

      // 同步到输出列表
      if (_syncGuidelinesToOutput != null) {
        _syncGuidelinesToOutput!(_activeGuidelines);
      }

      return _activeGuidelines.isNotEmpty;
    }

    // 清空旧的参考线
    clearGuidelines();

    // 创建目标元素边界
    final targetBounds = Rect.fromLTWH(
      draftPosition.dx,
      draftPosition.dy,
      draftSize.width,
      draftSize.height,
    );

    // 生成页面边缘参考线
    _generatePageGuidelines(targetBounds);

    // 生成与其他元素的对齐参考线（使用优化后的搜索）
    _generateElementAlignmentGuidelinesOptimized(
      elementId: elementId,
      targetBounds: targetBounds,
      nearbyElementIds: nearbyElementIds,
    );

    // 缓存生成的参考线
    if (_activeGuidelines.isNotEmpty) {
      _cacheManager.cacheGuidelines(
        elementId: elementId,
        x: draftPosition.dx,
        y: draftPosition.dy,
        width: draftSize.width,
        height: draftSize.height,
        targetElementIds: nearbyElementIds,
        guidelines: _activeGuidelines,
      );
    }

    return _activeGuidelines.isNotEmpty;
  }

  /// 获取缓存统计信息
  GuidelineCacheStats getCacheStats() {
    return _cacheManager.getCacheStats();
  }

  /// 获取空间索引中的附近元素
  List<String> getNearbyElements(Offset position, {double radius = 50.0}) {
    return _spatialIndex.findNearestElements(
      position,
      maxDistance: radius,
      maxResults: 20,
    );
  }

  /// 初始化页面元素和尺寸
  void initialize({
    required List<Map<String, dynamic>> elements,
    required Size pageSize,
    bool enabled = false,
    double snapThreshold = 5.0,
  }) {
    _elements.clear();
    _elements.addAll(elements);
    _pageSize = pageSize;
    _enabled = enabled;
    _snapThreshold = snapThreshold;

    // 构建空间索引以优化性能
    _spatialIndex.buildIndex(elements);

    EditPageLogger.editPageDebug(
      '参考线管理器初始化',
      data: {
        'elementsCount': elements.length,
        'pageSize': '${pageSize.width}x${pageSize.height}',
        'enabled': enabled,
        'snapThreshold': snapThreshold,
        'spatialIndexBuilt': true,
        'operation': 'guideline_manager_init',
      },
    );
  }

  /// 无效化特定元素的缓存
  void invalidateElementCache(String elementId) {
    _cacheManager.invalidateElementCache(elementId);
  }

  /// 重建空间索引
  void rebuildSpatialIndex() {
    _spatialIndex.buildIndex(_elements);
  }

  /// 设置活动参考线输出列表
  void setActiveGuidelinesOutput(List<Guideline> outputList) {
    // 将内部的_activeGuidelines与外部列表同步
    _syncGuidelinesToOutput = (guidelines) {
      outputList.clear();
      outputList.addAll(guidelines);

      EditPageLogger.editPageDebug(
        '参考线输出同步更新',
        data: {
          'guidelinesCount': guidelines.length,
          'operation': 'sync_guidelines_to_output',
        },
      );
    };

    // 立即同步当前参考线
    if (_activeGuidelines.isNotEmpty) {
      _syncGuidelinesToOutput!(_activeGuidelines);
    }
  }

  /// 设置元素列表
  void setElements(List<Map<String, dynamic>> elements) {
    _elements.clear();
    _elements.addAll(elements);

    EditPageLogger.editPageDebug(
      '参考线管理器更新元素列表',
      data: {
        'elementsCount': elements.length,
        'operation': 'update_elements',
      },
    );
  }

  /// 更新元素集合
  void updateElements(List<Map<String, dynamic>> elements) {
    _elements.clear();
    _elements.addAll(elements);

    // 重建空间索引
    _spatialIndex.buildIndex(elements);

    // 清空相关缓存
    _cacheManager.clearCache();
  }

  /// 更新页面尺寸
  void updatePageSize(Size pageSize) {
    _pageSize = pageSize;
  }

  /// 生成与其他元素的对齐参考线（优化版本）
  void _generateElementAlignmentGuidelinesOptimized({
    required String elementId,
    required Rect targetBounds,
    required List<String> nearbyElementIds,
  }) {
    // 获取目标元素（如果存在）
    final targetElement = _elements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    // 如果目标元素不存在，仍然可以与其他元素对齐
    String? targetLayerId;
    if (targetElement.isNotEmpty) {
      targetLayerId = targetElement['layerId'] as String?;
    }
    // 只处理附近的元素以提高性能
    for (final element in _elements) {
      final currentElementId = element['id'] as String;

      // 跳过自身和不可见元素
      if (currentElementId == elementId || element['isHidden'] == true) {
        continue;
      }

      // 检查是否在附近元素列表中
      if (!nearbyElementIds.contains(currentElementId)) {
        continue;
      }

      // 如果目标元素存在且在不同图层，则跳过（可选的同图层对齐）
      if (targetLayerId != null) {
        final elementLayerId = element['layerId'] as String?;
        if (targetLayerId != elementLayerId) {
          continue;
        }
      }

      // 计算元素边界
      final elementBounds = Rect.fromLTWH(
        (element['x'] as num).toDouble(),
        (element['y'] as num).toDouble(),
        (element['width'] as num).toDouble(),
        (element['height'] as num).toDouble(),
      );

      // 检查顶边对齐
      if ((targetBounds.top - elementBounds.top).abs() <= _snapThreshold) {
        _activeGuidelines.add(
          Guideline(
            id: 'element_${element['id']}_top_edge',
            type: GuidelineType.horizontalTopEdge,
            position: elementBounds.top,
            direction: AlignmentDirection.horizontal,
            sourceElementId: element['id'] as String,
            sourceElementBounds: elementBounds,
          ),
        );
      }

      // 检查水平中心线对齐
      if ((targetBounds.center.dy - elementBounds.center.dy).abs() <=
          _snapThreshold) {
        _activeGuidelines.add(
          Guideline(
            id: 'element_${element['id']}_center_h',
            type: GuidelineType.horizontalCenterLine,
            position: elementBounds.center.dy,
            direction: AlignmentDirection.horizontal,
            sourceElementId: element['id'] as String,
            sourceElementBounds: elementBounds,
          ),
        );
      }

      // 检查垂直中心线对齐
      if ((targetBounds.center.dx - elementBounds.center.dx).abs() <=
          _snapThreshold) {
        _activeGuidelines.add(
          Guideline(
            id: 'element_${element['id']}_center_v',
            type: GuidelineType.verticalCenterLine,
            position: elementBounds.center.dx,
            direction: AlignmentDirection.vertical,
            sourceElementId: element['id'] as String,
            sourceElementBounds: elementBounds,
          ),
        );
      }

      // 检查左边对齐
      if ((targetBounds.left - elementBounds.left).abs() <= _snapThreshold) {
        _activeGuidelines.add(
          Guideline(
            id: 'element_${element['id']}_left_edge',
            type: GuidelineType.verticalLeftEdge,
            position: elementBounds.left,
            direction: AlignmentDirection.vertical,
            sourceElementId: element['id'] as String,
            sourceElementBounds: elementBounds,
          ),
        );
      }

      // 检查右边对齐
      if ((targetBounds.right - elementBounds.right).abs() <= _snapThreshold) {
        _activeGuidelines.add(
          Guideline(
            id: 'element_${element['id']}_right_edge',
            type: GuidelineType.verticalRightEdge,
            position: elementBounds.right,
            direction: AlignmentDirection.vertical,
            sourceElementId: element['id'] as String,
            sourceElementBounds: elementBounds,
          ),
        );
      }

      // 检查底边对齐
      if ((targetBounds.bottom - elementBounds.bottom).abs() <=
          _snapThreshold) {
        _activeGuidelines.add(
          Guideline(
            id: 'element_${element['id']}_bottom_edge',
            type: GuidelineType.horizontalBottomEdge,
            position: elementBounds.bottom,
            direction: AlignmentDirection.horizontal,
            sourceElementId: element['id'] as String,
            sourceElementBounds: elementBounds,
          ),
        );
      }
    }
  }

  /// 生成页面边缘参考线
  void _generatePageGuidelines(Rect targetBounds) {
    final pageCenter = Offset(_pageSize.width / 2, _pageSize.height / 2);

    // 检查水平中心线
    if ((targetBounds.center.dy - pageCenter.dy).abs() <= _snapThreshold) {
      _activeGuidelines.add(
        Guideline(
          id: 'page_center_horizontal',
          type: GuidelineType.horizontalCenterLine,
          position: pageCenter.dy,
          direction: AlignmentDirection.horizontal,
          sourceElementId: 'page',
          sourceElementBounds:
              Rect.fromLTWH(0, 0, _pageSize.width, _pageSize.height),
        ),
      );
    }

    // 检查垂直中心线
    if ((targetBounds.center.dx - pageCenter.dx).abs() <= _snapThreshold) {
      _activeGuidelines.add(
        Guideline(
          id: 'page_center_vertical',
          type: GuidelineType.verticalCenterLine,
          position: pageCenter.dx,
          direction: AlignmentDirection.vertical,
          sourceElementId: 'page',
          sourceElementBounds:
              Rect.fromLTWH(0, 0, _pageSize.width, _pageSize.height),
        ),
      );
    }

    // 检查左边缘
    if ((targetBounds.left).abs() <= _snapThreshold) {
      _activeGuidelines.add(
        Guideline(
          id: 'page_left_edge',
          type: GuidelineType.verticalLeftEdge,
          position: 0,
          direction: AlignmentDirection.vertical,
          sourceElementId: 'page',
          sourceElementBounds:
              Rect.fromLTWH(0, 0, _pageSize.width, _pageSize.height),
        ),
      );
    }

    // 检查右边缘
    if ((_pageSize.width - targetBounds.right).abs() <= _snapThreshold) {
      _activeGuidelines.add(
        Guideline(
          id: 'page_right_edge',
          type: GuidelineType.verticalRightEdge,
          position: _pageSize.width,
          direction: AlignmentDirection.vertical,
          sourceElementId: 'page',
          sourceElementBounds:
              Rect.fromLTWH(0, 0, _pageSize.width, _pageSize.height),
        ),
      );
    }

    // 检查上边缘
    if ((targetBounds.top).abs() <= _snapThreshold) {
      _activeGuidelines.add(
        Guideline(
          id: 'page_top_edge',
          type: GuidelineType.horizontalTopEdge,
          position: 0,
          direction: AlignmentDirection.horizontal,
          sourceElementId: 'page',
          sourceElementBounds:
              Rect.fromLTWH(0, 0, _pageSize.width, _pageSize.height),
        ),
      );
    }

    // 检查下边缘
    if ((_pageSize.height - targetBounds.bottom).abs() <= _snapThreshold) {
      _activeGuidelines.add(
        Guideline(
          id: 'page_bottom_edge',
          type: GuidelineType.horizontalBottomEdge,
          position: _pageSize.height,
          direction: AlignmentDirection.horizontal,
          sourceElementId: 'page',
          sourceElementBounds:
              Rect.fromLTWH(0, 0, _pageSize.width, _pageSize.height),
        ),
      );
    }
  }
}
