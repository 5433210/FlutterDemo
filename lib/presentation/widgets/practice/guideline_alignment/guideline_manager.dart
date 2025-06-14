import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'guideline_cache_manager.dart';
import 'guideline_types.dart';

/// 参考线管理器 - 负责生成和管理参考线
class GuidelineManager {
  /// 单例实例
  static final GuidelineManager instance = GuidelineManager._();
    // 性能优化组件
  final GuidelineCacheManager _cacheManager = GuidelineCacheManager();
  // final SpatialIndexManager _spatialIndex = SpatialIndexManager(); // 暂时不使用

  /// 当前页面所有元素
  final List<Map<String, dynamic>> _elements = [];

  /// 当前活动的动态参考线（来自正在拖拽的元素）
  final List<Guideline> _dynamicGuidelines = <Guideline>[];
  
  /// 当前活动的静态参考线（来自其他固定元素）
  final List<Guideline> _staticGuidelines = <Guideline>[];
  
  /// 当前高亮的静态参考线（距离动态参考线最近的）
  final List<Guideline> _highlightedGuidelines = <Guideline>[];

  /// 页面尺寸
  Size _pageSize = Size.zero;

  /// 是否启用参考线
  bool _enabled = false;

  /// 参考线对齐阈值（像素）
  double _snapThreshold = 8.0;
  
  /// 参考线显示阈值（像素）- 当动态参考线距离静态参考线在此范围内时才显示
  double _displayThreshold = 20.0;

  /// 当前是否处于拖拽状态
  bool _isDragging = false;
  
  /// 当前正在拖拽的元素ID
  String? _draggingElementId;

  // 回调函数，用于同步参考线到外部列表
  Function(List<Guideline>)? _syncGuidelinesToOutput;

  /// 私有构造函数
  GuidelineManager._();

  /// 获取所有活动参考线列表（动态+静态+高亮）
  List<Guideline> get activeGuidelines {
    final allGuidelines = <Guideline>[];
    allGuidelines.addAll(_dynamicGuidelines);
    allGuidelines.addAll(_staticGuidelines);
    allGuidelines.addAll(_highlightedGuidelines);
    
    EditPageLogger.editPageDebug(
      '🔍 [TRACE] activeGuidelines getter调用',
      data: {
        'dynamicCount': _dynamicGuidelines.length,
        'staticCount': _staticGuidelines.length,
        'highlightedCount': _highlightedGuidelines.length,
        'totalCount': allGuidelines.length,
        'isDragging': _isDragging,
        'operation': 'getter_access_trace',
      },
    );
    return List.unmodifiable(allGuidelines);
  }
  
  /// 获取动态参考线
  List<Guideline> get dynamicGuidelines => List.unmodifiable(_dynamicGuidelines);
  
  /// 获取静态参考线
  List<Guideline> get staticGuidelines => List.unmodifiable(_staticGuidelines);
  
  /// 获取高亮参考线
  List<Guideline> get highlightedGuidelines => List.unmodifiable(_highlightedGuidelines);

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

  /// 获取当前拖拽的元素ID
  String? get draggingElementId => _draggingElementId;

  /// 设置拖拽元素ID
  set draggingElementId(String? elementId) {
    if (_draggingElementId != elementId) {
      _draggingElementId = elementId;
      EditPageLogger.editPageDebug('GuidelineManager拖拽元素ID设置', data: {
        'draggingElementId': _draggingElementId,
        'operation': 'set_dragging_element_id',
      });
    }
  }

  /// 获取当前拖拽状态
  bool get isDragging => _isDragging;

  /// 设置拖拽状态 - 控制是否只显示动态参考线
  set isDragging(bool value) {
    if (_isDragging != value) {
      _isDragging = value;
      // 如果从拖拽状态切换到非拖拽状态，清除所有参考线
      if (!_isDragging) {
        clearGuidelines();
      }
      EditPageLogger.editPageDebug('GuidelineManager拖拽状态切换', data: {
        'isDragging': _isDragging,
        'operation': 'set_dragging_state',
      });
    }
  }

  /// 🔧 新增：调试用状态检查API
  /// 检查GuidelineManager是否已初始化
  bool get isInitialized => _elements.isNotEmpty || _pageSize != Size.zero;

  /// 获取页面尺寸
  Size get pageSize => _pageSize;

  /// 获取元素列表
  List<Map<String, dynamic>> get elements => List.from(_elements);

  /// 获取参考线阈值
  double get snapThreshold => _snapThreshold;

  /// 设置参考线阈值
  set snapThreshold(double value) {
    if (value >= 0) {
      _snapThreshold = value;
    }
  }  /// 🚀 核心方法：实时更新参考线系统
  void updateGuidelinesLive({
    required String elementId,
    required Offset draftPosition,
    required Size elementSize,
    bool clearFirst = true,
    bool regenerateStatic = true, // 🔧 新增：控制是否重新生成静态参考线
  }) {
    if (!_enabled) return;

    if (clearFirst) {
      if (regenerateStatic) {
        // 重新生成静态参考线时，清空所有参考线
        _clearAllGuidelines();
      } else {
        // 🔧 优化：不重新生成静态参考线时，只清空动态参考线和高亮参考线
        _dynamicGuidelines.clear();
        _highlightedGuidelines.clear();
      }
    }

    // 1. 生成动态参考线（来自拖拽中的元素）
    _generateDynamicGuidelines(elementId, draftPosition, elementSize);

    // 2. 🔧 优化：只在需要时生成静态参考线（拖拽开始时）
    if (regenerateStatic) {
      _generateStaticGuidelines(elementId);
    }

    // 3. 计算高亮参考线（距离动态参考线最近的静态参考线）
    _calculateHighlightedGuidelines();

    // 4. 同步到输出
    _syncToOutput();

    EditPageLogger.editPageDebug(
      '🚀 实时更新参考线系统',
      data: {
        'elementId': elementId,
        'position': '${draftPosition.dx}, ${draftPosition.dy}',
        'size': '${elementSize.width}x${elementSize.height}',
        'regenerateStatic': regenerateStatic,
        'dynamicCount': _dynamicGuidelines.length,
        'staticCount': _staticGuidelines.length,
        'highlightedCount': _highlightedGuidelines.length,
      },
    );
  }  /// 🚀 核心方法：执行对齐吸附（鼠标释放时调用）
  /// 支持两种操作类型：
  /// - 平移操作：动态参考线所在的边或中线移动到高亮参考线位置，使元素整体平移
  /// - Resize操作：动态参考线所在边移动到高亮参考线位置，使元素大小变化
  Map<String, dynamic> performAlignment({
    required String elementId,
    required Offset currentPosition,
    required Size elementSize,
    String operationType = 'translate', // 'translate' 或 'resize'
    String? resizeDirection, // 当operationType='resize'时：'left', 'right', 'top', 'bottom'
  }) {
    if (!_enabled || _highlightedGuidelines.isEmpty) {
      EditPageLogger.editPageDebug('🚫 跳过对齐吸附', data: {
        'reason': !_enabled ? 'manager_disabled' : 'no_highlighted_guidelines',
        'enabled': _enabled,
        'highlightedCount': _highlightedGuidelines.length,
      });
      return {
        'position': currentPosition,
        'size': elementSize,
        'hasAlignment': false,
        'alignmentInfo': null,
      };
    }

    // 🔧 只处理第一个（也是唯一的）高亮参考线
    final highlightedGuideline = _highlightedGuidelines.first;
    
    double alignedX = currentPosition.dx;
    double alignedY = currentPosition.dy;
    double alignedWidth = elementSize.width;
    double alignedHeight = elementSize.height;
    Map<String, dynamic>? alignmentDetail;

    if (highlightedGuideline.direction == AlignmentDirection.horizontal) {
      // 水平参考线处理
      if (operationType == 'translate') {
        // 🔧 平移操作：动态参考线所在的边或中线移动到高亮参考线位置
        double targetY = _calculateAlignedY(highlightedGuideline, elementSize);
        double distance = (currentPosition.dy - targetY).abs();
        
        if (distance <= _snapThreshold) {
          alignedY = targetY;
          alignmentDetail = {
            'type': 'translate',
            'direction': 'horizontal',
            'guideline': highlightedGuideline.id,
            'guidelineType': highlightedGuideline.type.toString(),
            'originalY': currentPosition.dy,
            'alignedY': alignedY,
            'distance': distance,
          };
        }
      } else if (operationType == 'resize') {
        // 🔧 Resize操作：动态参考线所在边移动到高亮参考线位置
        if (resizeDirection == 'top') {
          // 上边界对齐
          double targetY = highlightedGuideline.position;
          double distance = (currentPosition.dy - targetY).abs();
          
          if (distance <= _snapThreshold) {
            double deltaY = targetY - currentPosition.dy;
            alignedY = targetY;
            alignedHeight = elementSize.height - deltaY;
            
            // 确保高度不为负数
            if (alignedHeight > 20) {
              alignmentDetail = {
                'type': 'resize',
                'direction': 'horizontal',
                'edge': 'top',
                'guideline': highlightedGuideline.id,
                'guidelineType': highlightedGuideline.type.toString(),
                'originalY': currentPosition.dy,
                'alignedY': alignedY,
                'originalHeight': elementSize.height,
                'alignedHeight': alignedHeight,
                'distance': distance,
              };
            }
          }
        } else if (resizeDirection == 'bottom') {
          // 下边界对齐
          double targetY = highlightedGuideline.position;
          double currentBottom = currentPosition.dy + elementSize.height;
          double distance = (currentBottom - targetY).abs();
          
          if (distance <= _snapThreshold) {
            alignedHeight = targetY - currentPosition.dy;
            
            // 确保高度不为负数
            if (alignedHeight > 20) {
              alignmentDetail = {
                'type': 'resize',
                'direction': 'horizontal',
                'edge': 'bottom',
                'guideline': highlightedGuideline.id,
                'guidelineType': highlightedGuideline.type.toString(),
                'originalHeight': elementSize.height,
                'alignedHeight': alignedHeight,
                'distance': distance,
              };
            }
          }
        }
      }
    } else {
      // 垂直参考线处理
      if (operationType == 'translate') {
        // 🔧 平移操作：动态参考线所在的边或中线移动到高亮参考线位置
        double targetX = _calculateAlignedX(highlightedGuideline, elementSize);
        double distance = (currentPosition.dx - targetX).abs();
        
        if (distance <= _snapThreshold) {
          alignedX = targetX;
          alignmentDetail = {
            'type': 'translate',
            'direction': 'vertical',
            'guideline': highlightedGuideline.id,
            'guidelineType': highlightedGuideline.type.toString(),
            'originalX': currentPosition.dx,
            'alignedX': alignedX,
            'distance': distance,
          };
        }
      } else if (operationType == 'resize') {
        // 🔧 Resize操作：动态参考线所在边移动到高亮参考线位置
        if (resizeDirection == 'left') {
          // 左边界对齐
          double targetX = highlightedGuideline.position;
          double distance = (currentPosition.dx - targetX).abs();
          
          if (distance <= _snapThreshold) {
            double deltaX = targetX - currentPosition.dx;
            alignedX = targetX;
            alignedWidth = elementSize.width - deltaX;
            
            // 确保宽度不为负数
            if (alignedWidth > 20) {
              alignmentDetail = {
                'type': 'resize',
                'direction': 'vertical',
                'edge': 'left',
                'guideline': highlightedGuideline.id,
                'guidelineType': highlightedGuideline.type.toString(),
                'originalX': currentPosition.dx,
                'alignedX': alignedX,
                'originalWidth': elementSize.width,
                'alignedWidth': alignedWidth,
                'distance': distance,
              };
            }
          }
        } else if (resizeDirection == 'right') {
          // 右边界对齐
          double targetX = highlightedGuideline.position;
          double currentRight = currentPosition.dx + elementSize.width;
          double distance = (currentRight - targetX).abs();
          
          if (distance <= _snapThreshold) {
            alignedWidth = targetX - currentPosition.dx;
            
            // 确保宽度不为负数
            if (alignedWidth > 20) {
              alignmentDetail = {
                'type': 'resize',
                'direction': 'vertical',
                'edge': 'right',
                'guideline': highlightedGuideline.id,
                'guidelineType': highlightedGuideline.type.toString(),
                'originalWidth': elementSize.width,
                'alignedWidth': alignedWidth,
                'distance': distance,
              };
            }
          }
        }
      }
    }

    final alignedPosition = Offset(alignedX, alignedY);
    final alignedSize = Size(alignedWidth, alignedHeight);
    final hasAlignment = alignmentDetail != null;

    EditPageLogger.editPageDebug(
      '🎯 执行对齐吸附',
      data: {
        'elementId': elementId,
        'operationType': operationType,
        'resizeDirection': resizeDirection,
        'originalPosition': '${currentPosition.dx}, ${currentPosition.dy}',
        'alignedPosition': '${alignedX}, ${alignedY}',
        'originalSize': '${elementSize.width}x${elementSize.height}',
        'alignedSize': '${alignedWidth}x${alignedHeight}',
        'hasAlignment': hasAlignment,
        'alignmentDetail': alignmentDetail,
        'highlightedGuideline': {
          'id': highlightedGuideline.id,
          'type': highlightedGuideline.type.toString(),
          'direction': highlightedGuideline.direction.toString(),
          'position': highlightedGuideline.position,
        },
      },
    );

    return {
      'position': alignedPosition,
      'size': alignedSize,
      'hasAlignment': hasAlignment,
      'alignmentInfo': {
        'detail': alignmentDetail,
        'highlightedGuideline': highlightedGuideline.id,
        'operationType': operationType,
        'resizeDirection': resizeDirection,
      },
    };
  }

  /// 检测对齐（兼容旧接口）
  Map<String, dynamic>? detectAlignment({
    required String elementId,
    required Offset currentPosition,
    required Size elementSize,
  }) {
    // 在检测对齐之前更新参考线
    updateGuidelinesLive(
      elementId: elementId,
      draftPosition: currentPosition,
      elementSize: elementSize,
    );

    // 如果没有高亮参考线，则无对齐
    if (_highlightedGuidelines.isEmpty) {
      return {
        'hasAlignment': false,
        'position': currentPosition,
      };
    }

    // 执行对齐计算
    return performAlignment(
      elementId: elementId,
      currentPosition: currentPosition,
      elementSize: elementSize,
    );
  }

  /// 计算最佳对齐（兼容旧接口）
  Map<String, dynamic>? calculateBestAlignment({
    required String elementId,
    required Offset currentPosition,
    required Size elementSize,
  }) {
    return detectAlignment(
      elementId: elementId,
      currentPosition: currentPosition,
      elementSize: elementSize,
    );
  }

  /// 生成实时参考线（兼容旧接口）
  bool generateRealTimeGuidelines({
    required String elementId,
    required Offset currentPosition,
    required Size elementSize,
  }) {
    updateGuidelinesLive(
      elementId: elementId,
      draftPosition: currentPosition,
      elementSize: elementSize,
    );
    return activeGuidelines.isNotEmpty;
  }

  /// 生成动态参考线（来自拖拽中的元素）
  void _generateDynamicGuidelines(String elementId, Offset position, Size size) {
    _dynamicGuidelines.clear();

    final bounds = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    final guidelines = _generateElementGuidelines(elementId, bounds);

    // 标记为动态参考线
    for (final guideline in guidelines) {
      _dynamicGuidelines.add(_markGuidelineAsDynamic(guideline));
    }

    EditPageLogger.editPageDebug(
      '📍 生成动态参考线',
      data: {
        'elementId': elementId,
        'position': '${position.dx}, ${position.dy}',
        'size': '${size.width}x${size.height}',
        'guidelineCount': _dynamicGuidelines.length,
      },
    );
  }
  /// 生成静态参考线（来自其他固定元素）
  void _generateStaticGuidelines(String draggingElementId) {
    _staticGuidelines.clear();

    // 不再添加页面边界参考线，只保留元素间对齐
    // final pageGuidelines = _generatePageGuidelines();
    // _staticGuidelines.addAll(pageGuidelines);

    // 添加其他元素的参考线
    int elementGuidelineCount = 0;
    for (final element in _elements) {
      final elementId = element['id'] as String;
      
      // 跳过拖拽中的元素和隐藏的元素
      if (elementId == draggingElementId || element['isHidden'] == true) {
        continue;
      }

      final bounds = Rect.fromLTWH(
        (element['x'] as num).toDouble(),
        (element['y'] as num).toDouble(),
        (element['width'] as num).toDouble(),
        (element['height'] as num).toDouble(),
      );

      final elementGuidelines = _generateElementGuidelines(elementId, bounds);
      _staticGuidelines.addAll(elementGuidelines);
      elementGuidelineCount += elementGuidelines.length;
    }    EditPageLogger.editPageDebug(
      '🔗 生成静态参考线',
      data: {
        'draggingElementId': draggingElementId,
        'totalElements': _elements.length,
        'staticElementCount': _elements.where((e) => e['id'] != draggingElementId && e['isHidden'] != true).length,
        'pageGuidelinesCount': 0, // 页面参考线已禁用
        'elementGuidelinesCount': elementGuidelineCount,
        'staticGuidelineCount': _staticGuidelines.length,
        'breakdown': {
          'page': 0, // 页面参考线已禁用
          'elements': elementGuidelineCount,
          'total': _staticGuidelines.length,
        }
      },
    );
  }
  /// 计算高亮参考线（距离动态参考线最近的静态参考线）
  /// 🔧 修改：只能有一个高亮参考线，按最近原则决定
  void _calculateHighlightedGuidelines() {
    _highlightedGuidelines.clear();

    if (_dynamicGuidelines.isEmpty || _staticGuidelines.isEmpty) {
      return;
    }

    Guideline? closestStatic;
    double minDistance = double.infinity;

    // 🔧 新逻辑：在所有动态参考线和静态参考线的组合中，找到全局最近的一对
    for (final dynamicGuideline in _dynamicGuidelines) {
      for (final staticGuideline in _staticGuidelines) {
        // 只比较相同方向的参考线
        if (dynamicGuideline.direction != staticGuideline.direction) {
          continue;
        }

        final distance = (dynamicGuideline.position - staticGuideline.position).abs();
        
        // 在显示阈值内且距离最近
        if (distance <= _displayThreshold && distance < minDistance) {
          minDistance = distance;
          closestStatic = staticGuideline;
        }
      }
    }

    // 🔧 只添加一个最近的高亮参考线
    if (closestStatic != null) {
      _highlightedGuidelines.add(_markGuidelineAsHighlighted(closestStatic));
    }

    EditPageLogger.editPageDebug(
      '✨ 计算高亮参考线（单一最近原则）',
      data: {
        'dynamicCount': _dynamicGuidelines.length,
        'staticCount': _staticGuidelines.length,
        'highlightedCount': _highlightedGuidelines.length,
        'displayThreshold': _displayThreshold,
        'minDistance': minDistance.isFinite ? minDistance.toStringAsFixed(2) : 'N/A',
        'highlightedGuidelineType': closestStatic?.type.toString() ?? 'none',
      },
    );
  }

  /// 计算对齐后的Y坐标
  double _calculateAlignedY(Guideline guideline, Size elementSize) {
    switch (guideline.type) {
      case GuidelineType.horizontalCenterLine:
        return guideline.position - elementSize.height / 2;
      case GuidelineType.horizontalTopEdge:
        return guideline.position;
      case GuidelineType.horizontalBottomEdge:
        return guideline.position - elementSize.height;
      default:
        return guideline.position;
    }
  }

  /// 计算对齐后的X坐标
  double _calculateAlignedX(Guideline guideline, Size elementSize) {
    switch (guideline.type) {
      case GuidelineType.verticalCenterLine:
        return guideline.position - elementSize.width / 2;
      case GuidelineType.verticalLeftEdge:
        return guideline.position;
      case GuidelineType.verticalRightEdge:
        return guideline.position - elementSize.width;
      default:
        return guideline.position;
    }
  }

  /// 清空所有参考线
  void clearGuidelines() {
    _clearAllGuidelines();
    _syncToOutput();
    
    EditPageLogger.editPageDebug(
      '🧹 清空所有参考线',
      data: {
        'operation': 'clear_all_guidelines',
      },
    );
  }

  /// 内部：清空所有参考线列表
  void _clearAllGuidelines() {
    _dynamicGuidelines.clear();
    _staticGuidelines.clear();
    _highlightedGuidelines.clear();
  }

  /// 同步参考线到输出
  void _syncToOutput() {
    if (_syncGuidelinesToOutput != null) {
      _syncGuidelinesToOutput!(activeGuidelines);
    }
  }

  /// 初始化 GuidelineManager（兼容旧接口）
  void initialize({
    required List<Map<String, dynamic>> elements,
    required Size pageSize,
    required bool enabled,
    double? snapThreshold,
  }) {
    // 更新页面尺寸
    updatePageSize(pageSize);
    
    // 更新元素列表
    updateElements(elements);
    
    // 设置启用状态
    this.enabled = enabled;
    
    // 设置吸附阈值
    if (snapThreshold != null) {
      this.snapThreshold = snapThreshold;
    }
    
    EditPageLogger.editPageDebug(
      '🔧 GuidelineManager初始化',
      data: {
        'pageSize': '${pageSize.width}x${pageSize.height}',
        'elementCount': elements.length,
        'enabled': enabled,
        'snapThreshold': this.snapThreshold,
      },
    );
  }

  /// 设置参考线输出回调
  void setActiveGuidelinesOutput(Function(List<Guideline>) callback) {
    _syncGuidelinesToOutput = callback;
  }
  /// 更新页面元素
  void updateElements(List<Map<String, dynamic>> elements) {
    _elements.clear();
    _elements.addAll(elements);
    
    // 更新空间索引（如果需要的话）
    // _spatialIndex.updateElements(elements);
    
    EditPageLogger.editPageDebug(
      '🔄 更新页面元素',
      data: {
        'elementCount': elements.length,
        'operation': 'update_elements',
      },
    );
  }

  /// 更新页面尺寸
  void updatePageSize(Size size) {
    if (_pageSize != size) {
      _pageSize = size;
      EditPageLogger.editPageDebug(
        '📏 更新页面尺寸',
        data: {
          'size': '${size.width}x${size.height}',
          'operation': 'update_page_size',
        },
      );
    }
  }

  /// 更新单个元素的位置信息，并重新计算静态参考线
  void updateElementPosition({
    required String elementId,
    required Offset position,
    required Size size,
    double? rotation,
  }) {
    // 查找并更新元素信息
    for (int i = 0; i < _elements.length; i++) {
      if (_elements[i]['id'] == elementId) {
        _elements[i] = {
          ..._elements[i],
          'x': position.dx,
          'y': position.dy,
          'width': size.width,
          'height': size.height,
          if (rotation != null) 'rotation': rotation,
        };
        break;
      }
    }

    // 如果当前不在拖拽状态，重新生成静态参考线
    if (!isDragging) {
      _generateStaticGuidelines(''); // 空字符串表示没有拖拽元素
      _syncToOutput();
      
      EditPageLogger.editPageDebug(
        '🔄 更新元素位置后重新计算静态参考线',
        data: {
          'elementId': elementId,
          'position': '${position.dx}, ${position.dy}',
          'size': '${size.width}x${size.height}',
          'rotation': rotation?.toString() ?? 'unchanged',
          'staticGuidelineCount': _staticGuidelines.length,
          'operation': 'update_element_position',
        },
      );
    }
  }

  /// 生成单个元素的参考线
  List<Guideline> _generateElementGuidelines(String elementId, Rect bounds) {
    final guidelines = <Guideline>[];
    final center = bounds.center;

    // 水平参考线
    guidelines.addAll([
      Guideline(
        id: '${elementId}_top',
        type: GuidelineType.horizontalTopEdge,
        position: bounds.top,
        direction: AlignmentDirection.horizontal,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
      Guideline(
        id: '${elementId}_center_h',
        type: GuidelineType.horizontalCenterLine,
        position: center.dy,
        direction: AlignmentDirection.horizontal,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
      Guideline(
        id: '${elementId}_bottom',
        type: GuidelineType.horizontalBottomEdge,
        position: bounds.bottom,
        direction: AlignmentDirection.horizontal,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
    ]);

    // 垂直参考线
    guidelines.addAll([
      Guideline(
        id: '${elementId}_left',
        type: GuidelineType.verticalLeftEdge,
        position: bounds.left,
        direction: AlignmentDirection.vertical,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
      Guideline(
        id: '${elementId}_center_v',
        type: GuidelineType.verticalCenterLine,
        position: center.dx,
        direction: AlignmentDirection.vertical,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
      Guideline(
        id: '${elementId}_right',
        type: GuidelineType.verticalRightEdge,
        position: bounds.right,
        direction: AlignmentDirection.vertical,
        sourceElementId: elementId,
        sourceElementBounds: bounds,
      ),
    ]);

    return guidelines;  }

  /// 🔹 新增：将参考线标记为动态参考线
  Guideline _markGuidelineAsDynamic(Guideline guideline) {
    // 添加动态前缀，以便在GuidelineLayer中识别
    final dynamicId = guideline.id.startsWith('dynamic_')
        ? guideline.id
        : 'dynamic_${guideline.id}';

    // 设置为灰色
    return guideline.copyWith(
      id: dynamicId,
      color: const Color(0xFFA0A0A0), // 灰色
    );
  }

  /// 🔹 新增：将参考线标记为高亮参考线
  Guideline _markGuidelineAsHighlighted(Guideline guideline) {
    return guideline.copyWith(
      color: const Color(0xFF00BCD4), // 青色，表示高亮
    );
  }

  /// 获取调试信息
  Map<String, dynamic> getDebugInfo() {
    return {
      'enabled': _enabled,
      'isDragging': _isDragging,
      'draggingElementId': _draggingElementId,
      'pageSize': '${_pageSize.width}x${_pageSize.height}',
      'elementCount': _elements.length,
      'snapThreshold': _snapThreshold,
      'displayThreshold': _displayThreshold,
      'dynamicGuidelines': _dynamicGuidelines.length,
      'staticGuidelines': _staticGuidelines.length,
      'highlightedGuidelines': _highlightedGuidelines.length,
      'totalGuidelines': activeGuidelines.length,
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

  // ==================== 兼容性方法（已废弃） ====================

  /// 兼容旧接口的方法
  @Deprecated('使用 updateGuidelinesLive 代替')
  bool generateGuidelines({
    required String elementId,
    required Offset draftPosition,
    required Size elementSize,
    int? maxGuidelines,
  }) {
    updateGuidelinesLive(
      elementId: elementId,
      draftPosition: draftPosition,
      elementSize: elementSize,
    );
    return activeGuidelines.isNotEmpty;
  }

  /// 添加参考线（已废弃，改用updateGuidelinesLive）
  @Deprecated('使用 updateGuidelinesLive 代替')
  void addGuideline(Guideline guideline) {
    // 此方法已被废弃，请使用新的参考线管理结构
    EditPageLogger.editPageDebug('警告：使用了已废弃的addGuideline方法');
  }

  /// 获取附近元素（兼容旧接口）
  List<Map<String, dynamic>> getNearbyElements(Offset position, Size size) {
    final targetRect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    final nearbyElements = <Map<String, dynamic>>[];
    
    for (final element in _elements) {
      final elementRect = Rect.fromLTWH(
        (element['x'] as num).toDouble(),
        (element['y'] as num).toDouble(),
        (element['width'] as num).toDouble(),
        (element['height'] as num).toDouble(),
      );
      
      // 检查是否有重叠或足够接近
      if (targetRect.overlaps(elementRect) || 
          (targetRect.center - elementRect.center).distance < 100) {
        nearbyElements.add(element);
      }
    }
    
    return nearbyElements;
  }
  /// 获取缓存统计信息（兼容旧接口）
  Map<String, dynamic> getCacheStats() {
    final stats = _cacheManager.getCacheStats();
    return {
      'cacheSize': stats.cacheSize,
      'maxCacheSize': stats.maxCacheSize,
      'totalAccessCount': stats.totalAccessCount,
      'hitRate': stats.hitRate,
      'utilizationRate': stats.utilizationRate,
    };
  }

  /// 计算对齐位置（兼容旧接口）
  Offset calculateAlignedPosition({
    required String elementId,
    required Offset currentPosition,
    required Size elementSize,
  }) {
    final alignmentResult = performAlignment(
      elementId: elementId,
      currentPosition: currentPosition,
      elementSize: elementSize,
    );
    
    return alignmentResult['position'] as Offset;
  }
  /// 使缓存失效（兼容旧接口）
  void invalidateElementCache(String elementId) {
    _cacheManager.invalidateElementCache(elementId);
  }

  /// 重建空间索引（兼容旧接口）
  void rebuildSpatialIndex() {
    // 空间索引功能暂未实现，保留接口兼容性
    EditPageLogger.editPageDebug('空间索引重建（暂未实现）');
  }

  /// 生成动态参考线（兼容旧接口）
  void generateDynamicGuidelines({
    required String elementId,
    required Offset position,
    required Size size,
  }) {
    _generateDynamicGuidelines(elementId, position, size);
  }
}
