import 'dart:math' as math;

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

  /// 获取当前管理的元素数量
  int get elementCount => _elements.length;

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

  /// 🔧 新增：调试用状态检查API
  /// 检查GuidelineManager是否已初始化
  bool get isInitialized => _elements.isNotEmpty || _pageSize != Size.zero;

  /// 获取页面尺寸
  Size get pageSize => _pageSize;

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

  /// 🔍 调试方法：检查对齐阈值
  void debugAlignmentThreshold(Rect targetBounds, Rect otherBounds) {
    final threshold = snapThreshold;

    final distances = {
      'topEdgeDistance': (targetBounds.top - otherBounds.top).abs(),
      'centerHorizontalDistance':
          (targetBounds.center.dy - otherBounds.center.dy).abs(),
      'centerVerticalDistance':
          (targetBounds.center.dx - otherBounds.center.dx).abs(),
      'leftEdgeDistance': (targetBounds.left - otherBounds.left).abs(),
    };

    EditPageLogger.editPageDebug('对齐距离检查', data: {
      'snapThreshold': threshold,
      'distances': distances,
      'withinThreshold': distances.values.any((d) => d <= threshold),
    });
  }

  /// 🔍 调试方法：追踪参考线生成过程
  void debugGenerateGuidelines(String elementId, Offset position, Size size) {
    EditPageLogger.editPageDebug('开始生成参考线', data: {
      'elementId': elementId,
      'position': '${position.dx}, ${position.dy}',
      'size': '${size.width}x${size.height}',
      'managerEnabled': enabled,
      'elementCount': elementCount,
    });

    final hasGuidelines = generateGuidelines(
      elementId: elementId,
      draftPosition: position,
      draftSize: size,
    );

    EditPageLogger.editPageDebug('参考线生成结果', data: {
      'hasGuidelines': hasGuidelines,
      'activeGuidelinesCount': activeGuidelines.length,
    });
  }

  /// 🔍 调试方法：检查GuidelineManager状态
  void debugGuidelineManagerState() {
    final debugInfo = getDebugInfo();
    EditPageLogger.editPageDebug('GuidelineManager状态检查', data: debugInfo);

    // 检查关键状态
    if (!isInitialized) {
      EditPageLogger.editPageWarning('GuidelineManager未正确初始化');
    }

    if (!enabled) {
      EditPageLogger.editPageWarning('参考线功能已禁用');
    }

    if (elementCount == 0) {
      EditPageLogger.editPageWarning('没有可用的元素用于生成参考线');
    }
  }

  /// 🔍 调试方法：验证输出列表同步
  void debugGuidelineOutput(List<Guideline> outputList) {
    EditPageLogger.editPageDebug('设置参考线输出列表', data: {
      'outputListInitialSize': outputList.length,
    });

    setActiveGuidelinesOutput(outputList);

    // 验证同步是否成功
    EditPageLogger.editPageDebug('参考线输出列表设置完成', data: {
      'outputListCurrentSize': outputList.length,
      'managerGuidelinesCount': activeGuidelines.length,
    });
  }

  /// 🔍 调试方法：检查空间索引
  void debugSpatialIndex(String elementId, Offset position) {
    final nearbyElements = getNearbyElements(position);

    EditPageLogger.editPageDebug('空间索引查询结果', data: {
      'targetElementId': elementId,
      'queryPosition': '${position.dx}, ${position.dy}',
      'nearbyElementsCount': nearbyElements.length,
      'nearbyElementIds': nearbyElements,
      'totalElementsInManager': elementCount,
    });
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

    // 🔧 调试：输出空间索引状态
    final spatialIndexInfo = _spatialIndex.getDebugInfo();
    EditPageLogger.editPageDebug(
      '🔧 空间索引状态检查',
      data: {
        'spatialIndexInfo': spatialIndexInfo,
        'targetPosition': '${draftPosition.dx}, ${draftPosition.dy}',
        'targetSize': '${draftSize.width}x${draftSize.height}',
        'operation': 'spatial_index_debug',
      },
    );

    // 🔧 使用更大的搜索半径进行查询
    final searchRadius =
        math.max(200.0, math.max(draftSize.width, draftSize.height) * 2);
    var nearbyElementIds = _spatialIndex.findNearestElements(
      draftPosition,
      maxDistance: searchRadius,
      maxResults: 20,
    );

    // 🔧 如果空间索引查询失败，使用强制搜索
    if (nearbyElementIds.isEmpty && spatialIndexInfo['totalElements'] > 0) {
      EditPageLogger.editPageDebug(
        '🔧 空间索引查询失败，使用强制搜索',
        data: {
          'reason': '空间索引返回空结果',
          'totalElements': spatialIndexInfo['totalElements'],
          'searchRadius': searchRadius,
        },
      );

      nearbyElementIds = _spatialIndex.findAllElementsWithinDistance(
        draftPosition,
        maxDistance: searchRadius,
        maxResults: 20,
      );
    }

    EditPageLogger.editPageDebug(
      '🔧 空间索引查询结果',
      data: {
        'targetPosition': '${draftPosition.dx}, ${draftPosition.dy}',
        'searchRadius': searchRadius,
        'nearbyElementIds': nearbyElementIds,
        'totalElementsInIndex': spatialIndexInfo['totalElements'],
        'operation': 'spatial_index_query_result',
      },
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

      EditPageLogger.editPageDebug(
        '🔧 使用缓存的参考线',
        data: {
          'cachedGuidelinesCount': cachedGuidelines.length,
          'operation': 'use_cached_guidelines',
        },
      );

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

    // 🔧 确保有附近元素时才生成对齐参考线
    if (nearbyElementIds.isNotEmpty) {
      _generateElementAlignmentGuidelinesOptimized(
        elementId: elementId,
        targetBounds: targetBounds,
        nearbyElementIds: nearbyElementIds,
      );
    } else {
      EditPageLogger.editPageDebug(
        '🔧 跳过元素对齐参考线生成',
        data: {
          'reason': '未找到附近元素',
          'targetPosition': '${draftPosition.dx}, ${draftPosition.dy}',
          'searchRadius': searchRadius,
          'totalElements': spatialIndexInfo['totalElements'],
        },
      );
    }

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

    EditPageLogger.editPageDebug(
      '🔧 参考线生成完成',
      data: {
        'hasGuidelines': _activeGuidelines.isNotEmpty,
        'guidelinesCount': _activeGuidelines.length,
        'pageGuidelines':
            _activeGuidelines.where((g) => g.sourceElementId == 'page').length,
        'elementGuidelines':
            _activeGuidelines.where((g) => g.sourceElementId != 'page').length,
        'nearbyElementsCount': nearbyElementIds.length,
        'operation': 'guidelines_generation_complete',
      },
    );

    // 同步到输出列表
    if (_syncGuidelinesToOutput != null) {
      _syncGuidelinesToOutput!(_activeGuidelines);
    }

    return _activeGuidelines.isNotEmpty;
  }

  /// 获取缓存统计信息
  GuidelineCacheStats getCacheStats() {
    return _cacheManager.getCacheStats();
  }

  /// 获取调试信息
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': isInitialized,
      'enabled': enabled,
      'elementCount': elementCount,
      'activeGuidelinesCount': _activeGuidelines.length,
      'pageSize': '${_pageSize.width}x${_pageSize.height}',
      'snapThreshold': snapThreshold,
      'hasElements': _elements.isNotEmpty,
      'hasActiveGuidelines': _activeGuidelines.isNotEmpty,
    };
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

    // 验证初始化结果
    final validElements = elements
        .where((e) =>
            e['x'] != null &&
            e['y'] != null &&
            e['width'] != null &&
            e['height'] != null &&
            e['id'] != null)
        .length;

    EditPageLogger.editPageDebug(
      '参考线管理器初始化完成',
      data: {
        'totalElements': elements.length,
        'validElements': validElements,
        'invalidElements': elements.length - validElements,
        'pageSize': '${pageSize.width}x${pageSize.height}',
        'enabled': enabled,
        'snapThreshold': snapThreshold,
        'spatialIndexBuilt': true,
        'isInitialized': isInitialized,
        'operation': 'guideline_manager_init',
      },
    );

    // 如果有无效元素，记录警告
    if (validElements < elements.length) {
      EditPageLogger.editPageWarning(
        '发现无效元素数据',
        data: {
          'invalidCount': elements.length - validElements,
          'totalCount': elements.length,
        },
      );
    }
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

  /// 🔍 调试方法：验证元素数据格式
  bool validateElementData(Map<String, dynamic> element) {
    final requiredFields = ['id', 'x', 'y', 'width', 'height'];
    final missingFields =
        requiredFields.where((field) => !element.containsKey(field)).toList();

    if (missingFields.isNotEmpty) {
      EditPageLogger.editPageWarning('元素数据格式错误', data: {
        'elementId': element['id'] ?? 'unknown',
        'missingFields': missingFields,
        'availableFields': element.keys.toList(),
      });
      return false;
    }

    return true;
  }

  /// 生成与其他元素的对齐参考线（优化版本）
  void _generateElementAlignmentGuidelinesOptimized({
    required String elementId,
    required Rect targetBounds,
    required List<String> nearbyElementIds,
  }) {
    // 🔧 修复：移除图层限制逻辑，允许跨图层参考线对齐
    // 这样可以在任何可见元素之间生成参考线，不限制在同一图层

    EditPageLogger.editPageDebug(
      '🔧 生成元素对齐参考线',
      data: {
        'targetElementId': elementId,
        'targetBounds':
            '${targetBounds.left},${targetBounds.top},${targetBounds.width},${targetBounds.height}',
        'nearbyElementIds': nearbyElementIds,
        'totalElements': _elements.length,
        'snapThreshold': _snapThreshold,
        'operation': 'generate_element_guidelines',
      },
    );

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
      } // 🔧 修复：允许跨图层参考线对齐
      // 注释掉图层限制，允许所有可见元素作为参考线候选
      // if (targetLayerId != null) {
      //   final elementLayerId = element['layerId'] as String?;
      //   if (targetLayerId != elementLayerId) {
      //     continue;
      //   }
      // }      // 计算元素边界
      final elementBounds = Rect.fromLTWH(
        (element['x'] as num).toDouble(),
        (element['y'] as num).toDouble(),
        (element['width'] as num).toDouble(),
        (element['height'] as num).toDouble(),
      );

      EditPageLogger.editPageDebug(
        '🔧 检查元素对齐',
        data: {
          'currentElementId': currentElementId,
          'elementBounds':
              '${elementBounds.left},${elementBounds.top},${elementBounds.width},${elementBounds.height}',
          'targetBounds':
              '${targetBounds.left},${targetBounds.top},${targetBounds.width},${targetBounds.height}',
          'topEdgeDistance': (targetBounds.top - elementBounds.top).abs(),
          'centerHorizontalDistance':
              (targetBounds.center.dy - elementBounds.center.dy).abs(),
          'centerVerticalDistance':
              (targetBounds.center.dx - elementBounds.center.dx).abs(),
          'leftEdgeDistance': (targetBounds.left - elementBounds.left).abs(),
          'rightEdgeDistance': (targetBounds.right - elementBounds.right).abs(),
          'bottomEdgeDistance':
              (targetBounds.bottom - elementBounds.bottom).abs(),
          'snapThreshold': _snapThreshold,
          'operation': 'check_element_alignment',
        },
      ); // 检查顶边对齐
      if ((targetBounds.top - elementBounds.top).abs() <= _snapThreshold) {
        EditPageLogger.editPageDebug('🔧 生成顶边对齐参考线',
            data: {'elementId': currentElementId});
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
        EditPageLogger.editPageDebug('🔧 生成水平中心线对齐参考线',
            data: {'elementId': currentElementId});
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
        EditPageLogger.editPageDebug('🔧 生成垂直中心线对齐参考线',
            data: {'elementId': currentElementId});
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
        EditPageLogger.editPageDebug('🔧 生成左边对齐参考线',
            data: {'elementId': currentElementId});
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
        EditPageLogger.editPageDebug('🔧 生成右边对齐参考线',
            data: {'elementId': currentElementId});
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
      } // 检查底边对齐
      if ((targetBounds.bottom - elementBounds.bottom).abs() <=
          _snapThreshold) {
        EditPageLogger.editPageDebug('🔧 生成底边对齐参考线',
            data: {'elementId': currentElementId});
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

    EditPageLogger.editPageDebug(
      '🔧 检查页面对齐',
      data: {
        'targetBounds':
            '${targetBounds.left},${targetBounds.top},${targetBounds.width},${targetBounds.height}',
        'pageSize': '${_pageSize.width}x${_pageSize.height}',
        'pageCenter': '${pageCenter.dx},${pageCenter.dy}',
        'targetCenter': '${targetBounds.center.dx},${targetBounds.center.dy}',
        'horizontalCenterDistance':
            (targetBounds.center.dy - pageCenter.dy).abs(),
        'verticalCenterDistance':
            (targetBounds.center.dx - pageCenter.dx).abs(),
        'leftEdgeDistance': targetBounds.left.abs(),
        'rightEdgeDistance': (_pageSize.width - targetBounds.right).abs(),
        'topEdgeDistance': targetBounds.top.abs(),
        'bottomEdgeDistance': (_pageSize.height - targetBounds.bottom).abs(),
        'snapThreshold': _snapThreshold,
        'operation': 'check_page_alignment',
      },
    );

    // 检查水平中心线
    if ((targetBounds.center.dy - pageCenter.dy).abs() <= _snapThreshold) {
      EditPageLogger.editPageDebug('🔧 生成页面水平中心线参考线');
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
    } // 检查垂直中心线
    if ((targetBounds.center.dx - pageCenter.dx).abs() <= _snapThreshold) {
      EditPageLogger.editPageDebug('🔧 生成页面垂直中心线参考线');
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
      EditPageLogger.editPageDebug('🔧 生成页面左边缘参考线');
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
