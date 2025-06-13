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
  final List<Guideline> _activeGuidelines = <Guideline>[];

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
  List<Guideline> get activeGuidelines {
    EditPageLogger.editPageDebug(
      '🔍 [TRACE] activeGuidelines getter调用',
      data: {
        'listType': _activeGuidelines.runtimeType.toString(),
        'listLength': _activeGuidelines.length,
        'isUnmodifiable':
            _activeGuidelines.runtimeType.toString().contains('Unmodifiable'),
        'stackTrace':
            StackTrace.current.toString().split('\n').take(5).join('; '),
        'operation': 'getter_access_trace',
      },
    );
    return List.unmodifiable(_activeGuidelines);
  }

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

  /// 🚀 新增：计算最佳对齐位置（在鼠标释放时使用）
  Map<String, dynamic>? calculateBestAlignment({
    required String elementId,
    required Offset currentPosition,
    required Size elementSize,
  }) {
    // 如果未启用参考线，直接返回null
    if (!_enabled) {
      return null;
    }

    EditPageLogger.editPageDebug(
      '🚀 开始计算最佳对齐',
      data: {
        'elementId': elementId,
        'currentPosition': '${currentPosition.dx}, ${currentPosition.dy}',
        'elementSize': '${elementSize.width}x${elementSize.height}',
        'operation': 'calculate_best_alignment',
      },
    );

    // 生成被拖拽元素的参考线
    final draggedBounds = Rect.fromLTWH(
      currentPosition.dx,
      currentPosition.dy,
      elementSize.width,
      elementSize.height,
    );

    final draggedGuidelines =
        _generateElementGuidelines(elementId, draggedBounds);

    // 收集所有其他元素和页面的参考线
    final allOtherGuidelines = <Guideline>[];

    // 添加页面参考线
    allOtherGuidelines.addAll(_generatePageGuidelinesOnly());

    // 添加其他元素的参考线
    for (final element in _elements) {
      final otherElementId = element['id'] as String;

      // 跳过自身和不可见元素
      if (otherElementId == elementId || element['isHidden'] == true) {
        continue;
      }

      final elementBounds = Rect.fromLTWH(
        (element['x'] as num).toDouble(),
        (element['y'] as num).toDouble(),
        (element['width'] as num).toDouble(),
        (element['height'] as num).toDouble(),
      );

      allOtherGuidelines
          .addAll(_generateElementGuidelines(otherElementId, elementBounds));
    }

    // 找到最佳对齐
    final bestAlignment = _findClosestAlignment(
        draggedGuidelines, allOtherGuidelines, currentPosition, elementSize);

    if (bestAlignment != null) {
      EditPageLogger.editPageDebug(
        '🚀 找到最佳对齐',
        data: {
          'originalPosition': '${currentPosition.dx}, ${currentPosition.dy}',
          'alignedPosition':
              '${bestAlignment['position'].dx}, ${bestAlignment['position'].dy}',
          'alignmentType': bestAlignment['type'],
          'distance': bestAlignment['distance'],
          'sourceGuideline': bestAlignment['sourceGuideline'].id,
          'targetGuideline': bestAlignment['targetGuideline'].id,
        },
      );
    }

    return bestAlignment;
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
      // 使用安全的方式清空列表，避免不可修改列表错误
      _activeGuidelines.removeRange(0, _activeGuidelines.length);

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
    bool isDynamicSource = false,
    bool alignToStatic = false,
    bool forceUpdate = false,
    int? maxGuidelines,
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
      isDynamicSource: isDynamicSource,
      alignToStatic: alignToStatic,
      forceUpdate: forceUpdate,
      maxGuidelines: maxGuidelines,
    );

    if (!hasGuidelines || _activeGuidelines.isEmpty) {
      return null;
    }

    // 🔹 新增：如果设置了最大参考线数量，过滤掉多余的参考线
    if (maxGuidelines != null && _activeGuidelines.length > maxGuidelines) {
      // 按距离排序参考线，保留最近的几条
      final sortedGuidelines = _activeGuidelines
        .where((g) => g.distanceToTarget != null)
        .toList()
        ..sort((a, b) => 
            (a.distanceToTarget ?? double.infinity)
            .compareTo(b.distanceToTarget ?? double.infinity));
      
      // 保留最近的几条参考线
      _activeGuidelines.clear();
      _activeGuidelines.addAll(sortedGuidelines.take(maxGuidelines));
      
      EditPageLogger.editPageDebug('限制参考线数量', data: {
        'original': sortedGuidelines.length,
        'limited': _activeGuidelines.length,
        'maxGuidelines': maxGuidelines,
        'operation': 'limit_guidelines',
      });
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
            'isDynamicSource': isDynamicSource,
            'alignToStatic': alignToStatic,
            'forceUpdate': forceUpdate,
            'maxGuidelines': maxGuidelines,
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
    bool isDynamicSource = false,
    bool alignToStatic = false,
    bool forceUpdate = false,
    int? maxGuidelines,
  }) {
    // 如果未启用参考线，直接返回
    if (!_enabled) {
      return false;
    }

    // 🔹 新增：当是动态源时，临时保存原始元素信息并替换为当前位置
    Map<String, dynamic>? originalElement;
    int elementIndex = -1;
    
    if (isDynamicSource) {
      // 查找元素索引
      elementIndex = _elements.indexWhere((e) => e['id'] == elementId);
      if (elementIndex >= 0) {
        // 保存原始信息
        originalElement = Map<String, dynamic>.from(_elements[elementIndex]);
        
        // 临时更新元素位置为当前拖拽位置
        _elements[elementIndex] = {
          ..._elements[elementIndex],
          'x': draftPosition.dx,
          'y': draftPosition.dy,
          'width': draftSize.width,
          'height': draftSize.height,
          'isDynamicSource': true,  // 标记为动态源
        };
        
        // 如果提供了旋转角度，也更新它
        if (rotation != null) {
          _elements[elementIndex]['rotation'] = rotation;
        }
        
        EditPageLogger.editPageDebug(
          '🔹 临时更新动态参考线源位置',
          data: {
            'elementId': elementId,
            'originalPosition': '${originalElement!['x']}, ${originalElement!['y']}',
            'updatedPosition': '${draftPosition.dx}, ${draftPosition.dy}',
            'operation': 'update_dynamic_source',
          },
        );
      }
    }

    try {
      // 🔧 调试：输出空间索引状态
      final spatialIndexInfo = _spatialIndex.getDebugInfo();
      EditPageLogger.editPageDebug(
        '🔧 空间索引状态检查',
        data: {
          'spatialIndexInfo': spatialIndexInfo,
          'targetPosition': '${draftPosition.dx}, ${draftPosition.dy}',
          'targetSize': '${draftSize.width}x${draftSize.height}',
          'isDynamicSource': isDynamicSource,
          'alignToStatic': alignToStatic,
          'forceUpdate': forceUpdate,
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

      // 🔧 修改：只有在不强制更新时才检查缓存
      if (!forceUpdate) {
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
          // 使用安全的方式清空列表，避免不可修改列表错误
          _activeGuidelines.removeRange(0, _activeGuidelines.length);
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
      } else {
        // 🔹 强制更新时输出日志
        EditPageLogger.editPageDebug(
          '🔧 强制重新生成参考线，跳过缓存',
          data: {
            'elementId': elementId,
            'position': '${draftPosition.dx}, ${draftPosition.dy}',
            'operation': 'force_update_guidelines',
          },
        );
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
          isDynamicSource: isDynamicSource,
          alignToStatic: alignToStatic,
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

      // 🔹 动态计算参考线与目标的距离，更新distanceToTarget属性
      if (_activeGuidelines.isNotEmpty) {
        final updatedGuidelines = _activeGuidelines.map((guideline) {
          double distance = guideline.distanceTo(targetBounds);
          return guideline.copyWith(
            distanceToTarget: distance,
            // 只有在距离小于阈值时才允许吸附
            canSnap: distance <= _snapThreshold,
          );
        }).toList();
        
        // 更新活动参考线
        _activeGuidelines.clear();
        _activeGuidelines.addAll(updatedGuidelines);
      }

      // 🔹 只在非强制更新模式下缓存结果
      if (_activeGuidelines.isNotEmpty && !forceUpdate) {
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
          'isDynamicSource': isDynamicSource,
          'alignToStatic': alignToStatic,
          'forceUpdate': forceUpdate,
          'operation': 'guidelines_generation_complete',
        },
      );

      // 同步到输出列表
      if (_syncGuidelinesToOutput != null) {
        _syncGuidelinesToOutput!(_activeGuidelines);
      }

      return _activeGuidelines.isNotEmpty;
      
    } finally {
      // 🔹 恢复原始元素信息
      if (isDynamicSource && originalElement != null && elementIndex >= 0) {
        _elements[elementIndex] = originalElement;
        
        EditPageLogger.editPageDebug(
          '🔹 恢复动态参考线源原始位置',
          data: {
            'elementId': elementId,
            'restoredPosition': '${originalElement['x']}, ${originalElement['y']}',
            'operation': 'restore_dynamic_source',
          },
        );
      }
    }
  }

  /// 🚀 新增：生成所有元素的实时参考线（用于调试显示）
  bool generateRealTimeGuidelines({
    required String draggedElementId,
    required Offset draggedPosition,
    required Size draggedSize,
  }) {
    // 如果未启用参考线，直接返回
    if (!_enabled) {
      return false;
    }

    // 清空旧的参考线
    clearGuidelines();

    EditPageLogger.editPageDebug(
      '🚀 生成实时调试参考线',
      data: {
        'draggedElementId': draggedElementId,
        'draggedPosition': '${draggedPosition.dx}, ${draggedPosition.dy}',
        'draggedSize': '${draggedSize.width}x${draggedSize.height}',
        'totalElements': _elements.length,
        'operation': 'generate_realtime_guidelines',
      },
    );

    // 为所有元素（包括被拖拽元素）生成参考线
    _generateAllElementsGuidelines(
        draggedElementId, draggedPosition, draggedSize);

    // 生成页面边缘参考线
    _generatePageGuidelinesForAllElements();

    EditPageLogger.editPageDebug(
      '🚀 实时参考线生成完成',
      data: {
        'totalGuidelines': _activeGuidelines.length,
        'horizontalGuidelines': _activeGuidelines
            .where((g) => g.direction == AlignmentDirection.horizontal)
            .length,
        'verticalGuidelines': _activeGuidelines
            .where((g) => g.direction == AlignmentDirection.vertical)
            .length,
        'operation': 'realtime_guidelines_complete',
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
    EditPageLogger.editPageDebug(
      '设置参考线输出列表',
      data: {
        'outputListType': outputList.runtimeType.toString(),
        'outputListLength': outputList.length,
        'isUnmodifiable':
            outputList.runtimeType.toString().contains('Unmodifiable'),
        'operation': 'set_active_guidelines_output',
      },
    );

    // 🔧 修复：检查是否是不可修改列表，如果是，则不设置同步回调
    if (outputList.runtimeType.toString().contains('Unmodifiable')) {
      EditPageLogger.editPageWarning(
        '无法设置同步回调：传入的是不可修改列表',
        data: {
          'outputListType': outputList.runtimeType.toString(),
          'solution': '需要传入可修改的列表，而不是通过activeGuidelines getter获取的不可修改列表',
        },
      );

      // 不设置同步回调，因为无法修改不可修改列表
      _syncGuidelinesToOutput = null;
      return;
    }

    // 将内部的_activeGuidelines与外部列表同步
    _syncGuidelinesToOutput = (guidelines) {
      try {
        EditPageLogger.editPageDebug(
          '开始同步参考线到输出',
          data: {
            'outputListType': outputList.runtimeType.toString(),
            'outputListLength': outputList.length,
            'guidelinesCount': guidelines.length,
            'isUnmodifiable':
                outputList.runtimeType.toString().contains('Unmodifiable'),
            'operation': 'sync_guidelines_before_clear',
          },
        );

        outputList.clear();
        outputList.addAll(guidelines);

        EditPageLogger.editPageDebug(
          '参考线输出同步更新完成',
          data: {
            'guidelinesCount': guidelines.length,
            'operation': 'sync_guidelines_to_output',
          },
        );
      } catch (e, stackTrace) {
        // 🔧 修复：如果同步失败（如不可修改列表错误），记录但不中断程序
        EditPageLogger.editPageError(
          '参考线输出同步失败，跳过同步',
          error: e,
          stackTrace: stackTrace,
          data: {
            'outputListType': outputList.runtimeType.toString(),
            'outputListLength': outputList.length,
            'guidelinesCount': guidelines.length,
            'operation': 'sync_guidelines_error_handled',
            'errorType': e.runtimeType.toString(),
          },
        );

        // 不抛出异常，继续执行
      }
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

  /// 🚀 新增：找到最近的对齐参考线
  Map<String, dynamic>? _findClosestAlignment(
    List<Guideline> draggedGuidelines,
    List<Guideline> targetGuidelines,
    Offset currentPosition,
    Size elementSize,
  ) {
    double minDistance = double.infinity;
    Map<String, dynamic>? bestAlignment;

    // 检查每个被拖拽元素的参考线与目标参考线的距离
    for (final draggedGuideline in draggedGuidelines) {
      for (final targetGuideline in targetGuidelines) {
        // 只比较相同方向的参考线
        if (draggedGuideline.direction != targetGuideline.direction) {
          continue;
        }

        final distance =
            (draggedGuideline.position - targetGuideline.position).abs();

        // 只考虑在阈值范围内的对齐
        if (distance <= _snapThreshold && distance < minDistance) {
          minDistance = distance;

          // 计算对齐后的位置
          Offset alignedPosition = currentPosition;

          if (draggedGuideline.direction == AlignmentDirection.horizontal) {
            // 水平对齐，调整Y坐标
            double newY = currentPosition.dy;

            switch (draggedGuideline.type) {
              case GuidelineType.horizontalTopEdge:
                newY = targetGuideline.position;
                break;
              case GuidelineType.horizontalCenterLine:
                newY = targetGuideline.position - elementSize.height / 2;
                break;
              case GuidelineType.horizontalBottomEdge:
                newY = targetGuideline.position - elementSize.height;
                break;
              default:
                continue;
            }

            alignedPosition = Offset(currentPosition.dx, newY);
          } else {
            // 垂直对齐，调整X坐标
            double newX = currentPosition.dx;

            switch (draggedGuideline.type) {
              case GuidelineType.verticalLeftEdge:
                newX = targetGuideline.position;
                break;
              case GuidelineType.verticalCenterLine:
                newX = targetGuideline.position - elementSize.width / 2;
                break;
              case GuidelineType.verticalRightEdge:
                newX = targetGuideline.position - elementSize.width;
                break;
              default:
                continue;
            }

            alignedPosition = Offset(newX, currentPosition.dy);
          }

          bestAlignment = {
            'position': alignedPosition,
            'distance': distance,
            'type':
                '${draggedGuideline.type.name}_to_${targetGuideline.type.name}',
            'sourceGuideline': draggedGuideline,
            'targetGuideline': targetGuideline,
          };
        }
      }
    }

    return bestAlignment;
  }

  /// 🚀 新增：为所有元素生成参考线（包括被拖拽元素的当前位置）
  void _generateAllElementsGuidelines(
      String draggedElementId, Offset draggedPosition, Size draggedSize) {
    // 为被拖拽元素在当前位置生成参考线
    _generateGuidelinesForElement(
      elementId: draggedElementId,
      bounds: Rect.fromLTWH(draggedPosition.dx, draggedPosition.dy,
          draggedSize.width, draggedSize.height),
      isDragged: true,
    );

    // 为所有其他元素生成参考线
    for (final element in _elements) {
      final elementId = element['id'] as String;

      // 跳过被拖拽的元素（已经在上面处理了）和不可见元素
      if (elementId == draggedElementId || element['isHidden'] == true) {
        continue;
      }

      final elementBounds = Rect.fromLTWH(
        (element['x'] as num).toDouble(),
        (element['y'] as num).toDouble(),
        (element['width'] as num).toDouble(),
        (element['height'] as num).toDouble(),
      );

      _generateGuidelinesForElement(
        elementId: elementId,
        bounds: elementBounds,
        isDragged: false,
      );
    }
  }

  /// 优化版元素对齐参考线生成
  void _generateElementAlignmentGuidelinesOptimized({
    required String elementId,
    required Rect targetBounds,
    required List<String> nearbyElementIds,
    bool isDynamicSource = false, // 🔹 新增：标记是否为动态参考线源
    bool alignToStatic = false,   // 🔹 新增：是否只对齐到静态参考线
  }) {
    // 🔧 修复：移除图层限制逻辑，允许跨图层参考线对齐
    if (nearbyElementIds.isEmpty) {
      EditPageLogger.editPageDebug('无附近元素，跳过参考线生成');
      return;
    }

    EditPageLogger.editPageDebug(
      '🔧 开始生成元素对齐参考线',
      data: {
        'elementId': elementId,
        'targetBounds': '(${targetBounds.left}, ${targetBounds.top}, ${targetBounds.right}, ${targetBounds.bottom})',
        'nearbyElementCount': nearbyElementIds.length,
        'isDynamicSource': isDynamicSource,
        'alignToStatic': alignToStatic,
        'operation': 'generate_element_alignment_guidelines',
      },
    );

    // 🔹 新增逻辑：为动态参考线源添加特殊标记
    final sourceTag = isDynamicSource ? 'dynamic_source' : 'static';

    // 目标元素的关键点
    final targetPoints = {
      'topEdge': targetBounds.top,
      'bottomEdge': targetBounds.bottom,
      'leftEdge': targetBounds.left,
      'rightEdge': targetBounds.right,
      'centerX': targetBounds.center.dx,
      'centerY': targetBounds.center.dy,
    };

    for (final otherElementId in nearbyElementIds) {
      // 跳过自身
      if (otherElementId == elementId) {
        continue;
      }

      // 🔹 新增逻辑：如果需要只对齐到静态参考线，则检查源元素类型
      final otherElement = _elements.firstWhere(
        (element) => element['id'] == otherElementId,
        orElse: () => <String, dynamic>{},
      );

      if (otherElement.isEmpty) {
        continue;
      }

      // 跳过隐藏元素
      if (otherElement['isHidden'] == true) {
        continue;
      }

      // 🔹 检查是否为动态源，如果是动态源并且只对齐到静态参考线，则跳过其他动态源
      final isOtherDynamic = otherElement['isDynamicSource'] == true;
      if (alignToStatic && isOtherDynamic) {
        EditPageLogger.editPageDebug('跳过其他动态参考线源', data: {
          'sourceElementId': elementId,
          'skippedElementId': otherElementId,
          'reason': 'only_align_to_static',
        });
        continue;
      }

      final otherBounds = Rect.fromLTWH(
        (otherElement['x'] as num).toDouble(),
        (otherElement['y'] as num).toDouble(),
        (otherElement['width'] as num).toDouble(),
        (otherElement['height'] as num).toDouble(),
      );

      // 其他元素的关键点
      final otherPoints = {
        'topEdge': otherBounds.top,
        'bottomEdge': otherBounds.bottom,
        'leftEdge': otherBounds.left,
        'rightEdge': otherBounds.right,
        'centerX': otherBounds.center.dx,
        'centerY': otherBounds.center.dy,
      };

      // 检查水平对齐（影响Y坐标）- 分为中心线和边缘对齐
      _checkHorizontalAlignment(
        targetPoints: targetPoints,
        otherPoints: otherPoints,
        otherElementId: otherElementId,
        otherBounds: otherBounds,
        sourceTag: sourceTag,      // 🔹 传递源标记
        isOtherStatic: !isOtherDynamic, // 🔹 标记是否为静态源
      );

      // 检查垂直对齐（影响X坐标）- 分为中心线和边缘对齐
      _checkVerticalAlignment(
        targetPoints: targetPoints,
        otherPoints: otherPoints,
        otherElementId: otherElementId,
        otherBounds: otherBounds,
        sourceTag: sourceTag,      // 🔹 传递源标记
        isOtherStatic: !isOtherDynamic, // 🔹 标记是否为静态源
      );
    }
  }

  /// 🚀 新增：为元素生成参考线列表（不添加到活动列表）
  List<Guideline> _generateElementGuidelines(String elementId, Rect bounds) {
    return [
      // 水平参考线
      Guideline(
        id: '${elementId}_top_edge',
        type: GuidelineType.horizontalTopEdge,
        position: bounds.top,
        direction: AlignmentDirection.horizontal,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
      Guideline(
        id: '${elementId}_center_h',
        type: GuidelineType.horizontalCenterLine,
        position: bounds.center.dy,
        direction: AlignmentDirection.horizontal,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
      Guideline(
        id: '${elementId}_bottom_edge',
        type: GuidelineType.horizontalBottomEdge,
        position: bounds.bottom,
        direction: AlignmentDirection.horizontal,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
      // 垂直参考线
      Guideline(
        id: '${elementId}_left_edge',
        type: GuidelineType.verticalLeftEdge,
        position: bounds.left,
        direction: AlignmentDirection.vertical,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
      Guideline(
        id: '${elementId}_center_v',
        type: GuidelineType.verticalCenterLine,
        position: bounds.center.dx,
        direction: AlignmentDirection.vertical,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
      Guideline(
        id: '${elementId}_right_edge',
        type: GuidelineType.verticalRightEdge,
        position: bounds.right,
        direction: AlignmentDirection.vertical,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
    ];
  }

  /// 🚀 新增：为单个元素生成所有类型的参考线
  void _generateGuidelinesForElement({
    required String elementId,
    required Rect bounds,
    bool isDragged = false,
  }) {
    final prefix = isDragged ? 'dragged_' : 'element_';

    // 生成水平参考线
    _activeGuidelines.addAll([
      // 上边缘
      Guideline(
        id: '$prefix${elementId}_top_edge',
        type: GuidelineType.horizontalTopEdge,
        position: bounds.top,
        direction: AlignmentDirection.horizontal,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
      // 水平中心线
      Guideline(
        id: '$prefix${elementId}_center_h',
        type: GuidelineType.horizontalCenterLine,
        position: bounds.center.dy,
        direction: AlignmentDirection.horizontal,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
      // 下边缘
      Guideline(
        id: '$prefix${elementId}_bottom_edge',
        type: GuidelineType.horizontalBottomEdge,
        position: bounds.bottom,
        direction: AlignmentDirection.horizontal,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
    ]);

    // 生成垂直参考线
    _activeGuidelines.addAll([
      // 左边缘
      Guideline(
        id: '$prefix${elementId}_left_edge',
        type: GuidelineType.verticalLeftEdge,
        position: bounds.left,
        direction: AlignmentDirection.vertical,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
      // 垂直中心线
      Guideline(
        id: '$prefix${elementId}_center_v',
        type: GuidelineType.verticalCenterLine,
        position: bounds.center.dx,
        direction: AlignmentDirection.vertical,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
      // 右边缘
      Guideline(
        id: '$prefix${elementId}_right_edge',
        type: GuidelineType.verticalRightEdge,
        position: bounds.right,
        direction: AlignmentDirection.vertical,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
    ]);

    EditPageLogger.editPageDebug(
      '🚀 为元素生成完整参考线',
      data: {
        'elementId': elementId,
        'isDragged': isDragged,
        'bounds':
            '${bounds.left},${bounds.top},${bounds.width},${bounds.height}',
        'guidelinesAdded': 6, // 每个元素6条参考线
      },
    );
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

  /// 🚀 新增：生成页面边缘参考线（用于显示所有页面参考线）
  void _generatePageGuidelinesForAllElements() {
    final pageCenter = Offset(_pageSize.width / 2, _pageSize.height / 2);
    final pageBounds = Rect.fromLTWH(0, 0, _pageSize.width, _pageSize.height);

    // 添加页面的所有参考线
    _activeGuidelines.addAll([
      // 水平参考线
      Guideline(
        id: 'page_top_edge',
        type: GuidelineType.horizontalTopEdge,
        position: 0,
        direction: AlignmentDirection.horizontal,
        sourceElementId: 'page',
        sourceElementBounds: pageBounds,
      ),
      Guideline(
        id: 'page_center_horizontal',
        type: GuidelineType.horizontalCenterLine,
        position: pageCenter.dy,
        direction: AlignmentDirection.horizontal,
        sourceElementId: 'page',
        sourceElementBounds: pageBounds,
      ),
      Guideline(
        id: 'page_bottom_edge',
        type: GuidelineType.horizontalBottomEdge,
        position: _pageSize.height,
        direction: AlignmentDirection.horizontal,
        sourceElementId: 'page',
        sourceElementBounds: pageBounds,
      ),
      // 垂直参考线
      Guideline(
        id: 'page_left_edge',
        type: GuidelineType.verticalLeftEdge,
        position: 0,
        direction: AlignmentDirection.vertical,
        sourceElementId: 'page',
        sourceElementBounds: pageBounds,
      ),
      Guideline(
        id: 'page_center_vertical',
        type: GuidelineType.verticalCenterLine,
        position: pageCenter.dx,
        direction: AlignmentDirection.vertical,
        sourceElementId: 'page',
        sourceElementBounds: pageBounds,
      ),
      Guideline(
        id: 'page_right_edge',
        type: GuidelineType.verticalRightEdge,
        position: _pageSize.width,
        direction: AlignmentDirection.vertical,
        sourceElementId: 'page',
        sourceElementBounds: pageBounds,
      ),
    ]);

    EditPageLogger.editPageDebug(
      '🚀 生成页面参考线',
      data: {
        'pageSize': '${_pageSize.width}x${_pageSize.height}',
        'pageGuidelinesAdded': 6,
      },
    );
  }

  /// 🚀 新增：仅生成页面参考线
  List<Guideline> _generatePageGuidelinesOnly() {
    final pageCenter = Offset(_pageSize.width / 2, _pageSize.height / 2);
    final pageBounds = Rect.fromLTWH(0, 0, _pageSize.width, _pageSize.height);

    return [
      // 水平参考线
      Guideline(
        id: 'page_top_edge',
        type: GuidelineType.horizontalTopEdge,
        position: 0,
        direction: AlignmentDirection.horizontal,
        sourceElementId: 'page',
        sourceElementBounds: pageBounds,
      ),
      Guideline(
        id: 'page_center_horizontal',
        type: GuidelineType.horizontalCenterLine,
        position: pageCenter.dy,
        direction: AlignmentDirection.horizontal,
        sourceElementId: 'page',
        sourceElementBounds: pageBounds,
      ),
      Guideline(
        id: 'page_bottom_edge',
        type: GuidelineType.horizontalBottomEdge,
        position: _pageSize.height,
        direction: AlignmentDirection.horizontal,
        sourceElementId: 'page',
        sourceElementBounds: pageBounds,
      ),
      // 垂直参考线
      Guideline(
        id: 'page_left_edge',
        type: GuidelineType.verticalLeftEdge,
        position: 0,
        direction: AlignmentDirection.vertical,
        sourceElementId: 'page',
        sourceElementBounds: pageBounds,
      ),
      Guideline(
        id: 'page_center_vertical',
        type: GuidelineType.verticalCenterLine,
        position: pageCenter.dx,
        direction: AlignmentDirection.vertical,
        sourceElementId: 'page',
        sourceElementBounds: pageBounds,
      ),
      Guideline(
        id: 'page_right_edge',
        type: GuidelineType.verticalRightEdge,
        position: _pageSize.width,
        direction: AlignmentDirection.vertical,
        sourceElementId: 'page',
        sourceElementBounds: pageBounds,
      ),
    ];
  }

  /// 检查水平方向对齐（影响Y坐标）
  void _checkHorizontalAlignment({
    required Map<String, double> targetPoints,
    required Map<String, double> otherPoints,
    required String otherElementId,
    required Rect otherBounds,
    required String sourceTag,
    required bool isOtherStatic,
  }) {
    // 顶边对齐
    double topEdgeDistance = (targetPoints['topEdge']! - otherPoints['topEdge']!).abs();
    if (topEdgeDistance <= _snapThreshold * 2) {  // 使用更大范围来显示参考线
      EditPageLogger.editPageDebug('检测到顶边对齐', data: {
        'distance': topEdgeDistance,
        'position': otherPoints['topEdge'],
        'otherElementId': otherElementId,
      });

      _activeGuidelines.add(
        Guideline(
          id: 'h_top_${otherElementId}_$sourceTag',
          type: GuidelineType.horizontalTopEdge,
          position: otherPoints['topEdge']!,
          direction: AlignmentDirection.horizontal,
          sourceElementId: otherElementId,
          sourceElementBounds: otherBounds,
          isHighlighted: topEdgeDistance <= _snapThreshold,
          distanceToTarget: topEdgeDistance,
          canSnap: isOtherStatic && topEdgeDistance <= _snapThreshold,
        ),
      );
    }

    // 水平中心线对齐
    double centerYDistance = (targetPoints['centerY']! - otherPoints['centerY']!).abs();
    if (centerYDistance <= _snapThreshold * 2) {
      EditPageLogger.editPageDebug('检测到水平中心线对齐', data: {
        'distance': centerYDistance,
        'position': otherPoints['centerY'],
        'otherElementId': otherElementId,
      });

      _activeGuidelines.add(
        Guideline(
          id: 'h_center_${otherElementId}_$sourceTag',
          type: GuidelineType.horizontalCenterLine,
          position: otherPoints['centerY']!,
          direction: AlignmentDirection.horizontal,
          sourceElementId: otherElementId,
          sourceElementBounds: otherBounds,
          isHighlighted: centerYDistance <= _snapThreshold,
          distanceToTarget: centerYDistance,
          canSnap: isOtherStatic && centerYDistance <= _snapThreshold,
        ),
      );
    }

    // 底边对齐
    double bottomEdgeDistance = (targetPoints['bottomEdge']! - otherPoints['bottomEdge']!).abs();
    if (bottomEdgeDistance <= _snapThreshold * 2) {
      EditPageLogger.editPageDebug('检测到底边对齐', data: {
        'distance': bottomEdgeDistance,
        'position': otherPoints['bottomEdge'],
        'otherElementId': otherElementId,
      });

      _activeGuidelines.add(
        Guideline(
          id: 'h_bottom_${otherElementId}_$sourceTag',
          type: GuidelineType.horizontalBottomEdge,
          position: otherPoints['bottomEdge']!,
          direction: AlignmentDirection.horizontal,
          sourceElementId: otherElementId,
          sourceElementBounds: otherBounds,
          isHighlighted: bottomEdgeDistance <= _snapThreshold,
          distanceToTarget: bottomEdgeDistance,
          canSnap: isOtherStatic && bottomEdgeDistance <= _snapThreshold,
        ),
      );
    }
  }

  /// 检查垂直方向对齐（影响X坐标）
  void _checkVerticalAlignment({
    required Map<String, double> targetPoints,
    required Map<String, double> otherPoints,
    required String otherElementId,
    required Rect otherBounds,
    required String sourceTag,
    required bool isOtherStatic,
  }) {
    // 左边对齐
    double leftEdgeDistance = (targetPoints['leftEdge']! - otherPoints['leftEdge']!).abs();
    if (leftEdgeDistance <= _snapThreshold * 2) {
      EditPageLogger.editPageDebug('检测到左边对齐', data: {
        'distance': leftEdgeDistance,
        'position': otherPoints['leftEdge'],
        'otherElementId': otherElementId,
      });

      _activeGuidelines.add(
        Guideline(
          id: 'v_left_${otherElementId}_$sourceTag',
          type: GuidelineType.verticalLeftEdge,
          position: otherPoints['leftEdge']!,
          direction: AlignmentDirection.vertical,
          sourceElementId: otherElementId,
          sourceElementBounds: otherBounds,
          isHighlighted: leftEdgeDistance <= _snapThreshold,
          distanceToTarget: leftEdgeDistance,
          canSnap: isOtherStatic && leftEdgeDistance <= _snapThreshold,
        ),
      );
    }

    // 垂直中心线对齐
    double centerXDistance = (targetPoints['centerX']! - otherPoints['centerX']!).abs();
    if (centerXDistance <= _snapThreshold * 2) {
      EditPageLogger.editPageDebug('检测到垂直中心线对齐', data: {
        'distance': centerXDistance,
        'position': otherPoints['centerX'],
        'otherElementId': otherElementId,
      });

      _activeGuidelines.add(
        Guideline(
          id: 'v_center_${otherElementId}_$sourceTag',
          type: GuidelineType.verticalCenterLine,
          position: otherPoints['centerX']!,
          direction: AlignmentDirection.vertical,
          sourceElementId: otherElementId,
          sourceElementBounds: otherBounds,
          isHighlighted: centerXDistance <= _snapThreshold,
          distanceToTarget: centerXDistance,
          canSnap: isOtherStatic && centerXDistance <= _snapThreshold,
        ),
      );
    }

    // 右边对齐
    double rightEdgeDistance = (targetPoints['rightEdge']! - otherPoints['rightEdge']!).abs();
    if (rightEdgeDistance <= _snapThreshold * 2) {
      EditPageLogger.editPageDebug('检测到右边对齐', data: {
        'distance': rightEdgeDistance,
        'position': otherPoints['rightEdge'],
        'otherElementId': otherElementId,
      });

      _activeGuidelines.add(
        Guideline(
          id: 'v_right_${otherElementId}_$sourceTag',
          type: GuidelineType.verticalRightEdge,
          position: otherPoints['rightEdge']!,
          direction: AlignmentDirection.vertical,
          sourceElementId: otherElementId,
          sourceElementBounds: otherBounds,
          isHighlighted: rightEdgeDistance <= _snapThreshold,
          distanceToTarget: rightEdgeDistance,
          canSnap: isOtherStatic && rightEdgeDistance <= _snapThreshold,
        ),
      );
    }
  }
}
