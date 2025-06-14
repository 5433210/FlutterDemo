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
  /// 获取所有活动参考线列表
  /// 🔧 修改：拖拽过程中只显示高亮参考线，其余参考线不显示
  List<Guideline> get activeGuidelines {
    final allGuidelines = <Guideline>[];
    
    if (_isDragging) {
      // 拖拽过程中：只显示高亮参考线
      allGuidelines.addAll(_highlightedGuidelines);
    } else {
      // 非拖拽状态：显示所有参考线（保持原有逻辑）
      allGuidelines.addAll(_dynamicGuidelines);
      allGuidelines.addAll(_staticGuidelines);
      allGuidelines.addAll(_highlightedGuidelines);
    }
    
    EditPageLogger.editPageDebug(
      '🔍 [TRACE] activeGuidelines getter调用',
      data: {
        'dynamicCount': _dynamicGuidelines.length,
        'staticCount': _staticGuidelines.length,
        'highlightedCount': _highlightedGuidelines.length,
        'totalCount': allGuidelines.length,
        'isDragging': _isDragging,
        'onlyHighlighted': _isDragging,
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
    String operationType = 'translate', // 🔧 新增：操作类型
    String? resizeDirection, // 🔧 新增：Resize方向
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

    // 3. 计算高亮参考线（根据操作类型和拖拽方向）
    _calculateHighlightedGuidelines(
      operationType: operationType,
      resizeDirection: resizeDirection,
    );

    // 4. 同步到输出
    _syncToOutput();

    EditPageLogger.editPageDebug(
      '🚀 实时更新参考线系统',
      data: {
        'elementId': elementId,
        'position': '${draftPosition.dx}, ${draftPosition.dy}',
        'size': '${elementSize.width}x${elementSize.height}',
        'regenerateStatic': regenerateStatic,
        'operationType': operationType,
        'resizeDirection': resizeDirection,
        'dynamicCount': _dynamicGuidelines.length,
        'staticCount': _staticGuidelines.length,
        'highlightedCount': _highlightedGuidelines.length,
      },
    );
  }  /// 🚀 核心方法：执行对齐吸附（鼠标释放时调用）
  /// 支持两种操作类型：
  /// - 平移操作：动态参考线所在的边或中线移动到高亮参考线位置，使元素整体平移
  /// - Resize操作：动态参考线所在边移动到高亮参考线位置，使元素大小变化
  /// 🔧 改进：支持多条高亮参考线（角点拖拽时）
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

    double alignedX = currentPosition.dx;
    double alignedY = currentPosition.dy;
    double alignedWidth = elementSize.width;
    double alignedHeight = elementSize.height;
    List<Map<String, dynamic>> alignmentDetails = [];

    // 🔧 处理多条高亮参考线
    for (final highlightedGuideline in _highlightedGuidelines) {
      Map<String, dynamic>? alignmentDetail = _processSingleGuideline(
        highlightedGuideline,
        currentPosition,
        elementSize,
        operationType,
        resizeDirection,
      );

      if (alignmentDetail != null) {
        alignmentDetails.add(alignmentDetail);

        // 应用对齐结果
        if (highlightedGuideline.direction == AlignmentDirection.horizontal) {
          if (alignmentDetail.containsKey('alignedY')) {
            alignedY = alignmentDetail['alignedY'];
          }
          if (alignmentDetail.containsKey('alignedHeight')) {
            alignedHeight = alignmentDetail['alignedHeight'];
          }
        } else {
          if (alignmentDetail.containsKey('alignedX')) {
            alignedX = alignmentDetail['alignedX'];
          }
          if (alignmentDetail.containsKey('alignedWidth')) {
            alignedWidth = alignmentDetail['alignedWidth'];
          }
        }
      }
    }

    final alignedPosition = Offset(alignedX, alignedY);
    final alignedSize = Size(alignedWidth, alignedHeight);
    final hasAlignment = alignmentDetails.isNotEmpty;

    EditPageLogger.editPageDebug(
      '🎯 执行对齐吸附（多参考线支持）',
      data: {
        'elementId': elementId,
        'operationType': operationType,
        'resizeDirection': resizeDirection,
        'originalPosition': '${currentPosition.dx}, ${currentPosition.dy}',
        'alignedPosition': '${alignedX}, ${alignedY}',
        'originalSize': '${elementSize.width}x${elementSize.height}',
        'alignedSize': '${alignedWidth}x${alignedHeight}',
        'hasAlignment': hasAlignment,
        'highlightedGuidelinesCount': _highlightedGuidelines.length,
        'alignmentDetailsCount': alignmentDetails.length,
        'alignmentDetails': alignmentDetails,
      },
    );

    return {
      'position': alignedPosition,
      'size': alignedSize,
      'hasAlignment': hasAlignment,
      'alignmentInfo': {
        'details': alignmentDetails,
        'highlightedGuidelines': _highlightedGuidelines.map((g) => g.id).toList(),
        'operationType': operationType,
        'resizeDirection': resizeDirection,
      },
    };
  }
  /// 处理单个高亮参考线的对齐
  Map<String, dynamic>? _processSingleGuideline(
    Guideline highlightedGuideline,
    Offset currentPosition,
    Size elementSize,
    String operationType,
    String? resizeDirection,
  ) {
    if (highlightedGuideline.direction == AlignmentDirection.horizontal) {
      return _processHorizontalGuideline(
        highlightedGuideline,
        currentPosition,
        elementSize,
        operationType,
        resizeDirection,
      );
    } else {
      return _processVerticalGuideline(
        highlightedGuideline,
        currentPosition,
        elementSize,
        operationType,
        resizeDirection,
      );
    }
  }

  /// 处理水平方向的参考线对齐
  Map<String, dynamic>? _processHorizontalGuideline(
    Guideline highlightedGuideline,
    Offset currentPosition,
    Size elementSize,
    String operationType,
    String? resizeDirection,
  ) {
    if (operationType == 'translate') {
      // 平移操作：找到与高亮参考线距离最近的动态参考线，然后对齐
      Guideline? closestDynamicGuideline;
      double minDistance = double.infinity;
      
      for (final dynamicGuideline in _dynamicGuidelines) {
        if (dynamicGuideline.direction == highlightedGuideline.direction) {
          final distance = (dynamicGuideline.position - highlightedGuideline.position).abs();
          if (distance < minDistance) {
            minDistance = distance;
            closestDynamicGuideline = dynamicGuideline;
          }
        }
      }
      
      if (closestDynamicGuideline != null) {
        double targetY = _calculateAlignedYFromDynamicGuideline(
          closestDynamicGuideline, 
          highlightedGuideline.position, 
          elementSize
        );
        
        return {
          'type': 'translate',
          'direction': 'horizontal',
          'guideline': highlightedGuideline.id,
          'dynamicGuideline': closestDynamicGuideline.id,
          'guidelineType': highlightedGuideline.type.toString(),
          'dynamicGuidelineType': closestDynamicGuideline.type.toString(),
          'originalY': currentPosition.dy,
          'alignedY': targetY,
          'distance': minDistance,
        };
      }
    } else if (operationType == 'resize' && resizeDirection != null) {
      return _processHorizontalResize(
        highlightedGuideline,
        currentPosition,
        elementSize,
        resizeDirection,
      );
    }

    return null;
  }

  /// 处理垂直方向的参考线对齐
  Map<String, dynamic>? _processVerticalGuideline(
    Guideline highlightedGuideline,
    Offset currentPosition,
    Size elementSize,
    String operationType,
    String? resizeDirection,
  ) {
    if (operationType == 'translate') {
      // 平移操作：找到与高亮参考线距离最近的动态参考线，然后对齐
      Guideline? closestDynamicGuideline;
      double minDistance = double.infinity;
      
      for (final dynamicGuideline in _dynamicGuidelines) {
        if (dynamicGuideline.direction == highlightedGuideline.direction) {
          final distance = (dynamicGuideline.position - highlightedGuideline.position).abs();
          if (distance < minDistance) {
            minDistance = distance;
            closestDynamicGuideline = dynamicGuideline;
          }
        }
      }
      
      if (closestDynamicGuideline != null) {
        double targetX = _calculateAlignedXFromDynamicGuideline(
          closestDynamicGuideline, 
          highlightedGuideline.position, 
          elementSize
        );
        
        return {
          'type': 'translate',
          'direction': 'vertical',
          'guideline': highlightedGuideline.id,
          'dynamicGuideline': closestDynamicGuideline.id,
          'guidelineType': highlightedGuideline.type.toString(),
          'dynamicGuidelineType': closestDynamicGuideline.type.toString(),
          'originalX': currentPosition.dx,
          'alignedX': targetX,
          'distance': minDistance,
        };
      }
    } else if (operationType == 'resize' && resizeDirection != null) {
      return _processVerticalResize(
        highlightedGuideline,
        currentPosition,
        elementSize,
        resizeDirection,
      );
    }

    return null;
  }

  /// 处理水平方向的Resize对齐
  Map<String, dynamic>? _processHorizontalResize(
    Guideline highlightedGuideline,
    Offset currentPosition,
    Size elementSize,
    String resizeDirection,
  ) {
    double targetY = highlightedGuideline.position;
    
    if (resizeDirection.contains('top')) {
      // 上边界对齐
      double deltaY = targetY - currentPosition.dy;
      double newHeight = elementSize.height - deltaY;
      
      if (newHeight > 20) {
        return {
          'type': 'resize',
          'direction': 'horizontal',
          'edge': 'top',
          'guideline': highlightedGuideline.id,
          'guidelineType': highlightedGuideline.type.toString(),
          'originalY': currentPosition.dy,
          'alignedY': targetY,
          'originalHeight': elementSize.height,
          'alignedHeight': newHeight,
          'distance': (currentPosition.dy - targetY).abs(),
        };
      }    } else if (resizeDirection.contains('bottom')) {
      // 下边界对齐
      double newHeight = targetY - currentPosition.dy;
      
      if (newHeight > 20) {
        return {
          'type': 'resize',
          'direction': 'horizontal',
          'edge': 'bottom',
          'guideline': highlightedGuideline.id,
          'guidelineType': highlightedGuideline.type.toString(),
          'originalHeight': elementSize.height,
          'alignedHeight': newHeight,
          'distance': ((currentPosition.dy + elementSize.height) - targetY).abs(),
        };
      }
    }

    return null;
  }

  /// 处理垂直方向的Resize对齐
  Map<String, dynamic>? _processVerticalResize(
    Guideline highlightedGuideline,
    Offset currentPosition,
    Size elementSize,
    String resizeDirection,
  ) {
    double targetX = highlightedGuideline.position;
      if (resizeDirection.contains('left')) {
      // 左边界对齐
      double deltaX = targetX - currentPosition.dx;
      double newWidth = elementSize.width - deltaX;
      
      if (newWidth > 20) {
        return {
          'type': 'resize',
          'direction': 'vertical',
          'edge': 'left',
          'guideline': highlightedGuideline.id,
          'guidelineType': highlightedGuideline.type.toString(),
          'originalX': currentPosition.dx,
          'alignedX': targetX,
          'originalWidth': elementSize.width,
          'alignedWidth': newWidth,
          'distance': (currentPosition.dx - targetX).abs(),
        };
      }
    } else if (resizeDirection.contains('right')) {
      // 右边界对齐
      double newWidth = targetX - currentPosition.dx;
      
      if (newWidth > 20) {
        return {
          'type': 'resize',
          'direction': 'vertical',
          'edge': 'right',
          'guideline': highlightedGuideline.id,
          'guidelineType': highlightedGuideline.type.toString(),
          'originalWidth': elementSize.width,
          'alignedWidth': newWidth,
          'distance': ((currentPosition.dx + elementSize.width) - targetX).abs(),
        };
      }
    }

    return null;
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
  }  /// 计算高亮参考线
  /// 🔧 简化逻辑：最多一条横向、一条纵向高亮参考线
  void _calculateHighlightedGuidelines({
    String operationType = 'translate',
    String? resizeDirection,
  }) {
    _highlightedGuidelines.clear();

    if (_dynamicGuidelines.isEmpty || _staticGuidelines.isEmpty) {
      return;
    }

    // 分别计算横向和纵向的高亮参考线
    final horizontalHighlighted = _findBestHorizontalGuideline(operationType, resizeDirection);
    final verticalHighlighted = _findBestVerticalGuideline(operationType, resizeDirection);

    // 添加找到的高亮参考线
    if (horizontalHighlighted != null) {
      _highlightedGuidelines.add(_markGuidelineAsHighlighted(horizontalHighlighted));
    }
    if (verticalHighlighted != null) {
      _highlightedGuidelines.add(_markGuidelineAsHighlighted(verticalHighlighted));
    }

    EditPageLogger.editPageDebug(
      '✨ 计算高亮参考线（简化逻辑）',
      data: {
        'operationType': operationType,
        'resizeDirection': resizeDirection,
        'dynamicCount': _dynamicGuidelines.length,
        'staticCount': _staticGuidelines.length,
        'highlightedCount': _highlightedGuidelines.length,
        'displayThreshold': _displayThreshold,
        'horizontalFound': horizontalHighlighted != null,
        'verticalFound': verticalHighlighted != null,
        'horizontalType': horizontalHighlighted?.type.toString(),
        'verticalType': verticalHighlighted?.type.toString(),
      },
    );
  }

  /// 找到最佳的横向高亮参考线
  Guideline? _findBestHorizontalGuideline(String operationType, String? resizeDirection) {
    // 获取参与检测的水平动态参考线
    final candidateDynamicGuidelines = _getCandidateHorizontalDynamicGuidelines(operationType, resizeDirection);
    
    if (candidateDynamicGuidelines.isEmpty) {
      return null;
    }    // 获取所有水平静态参考线，排除被拖拽元素自身的参考线
    final horizontalStaticGuidelines = _staticGuidelines
        .where((g) => g.direction == AlignmentDirection.horizontal && 
                     g.sourceElementId != _draggingElementId)
        .toList();

    if (horizontalStaticGuidelines.isEmpty) {
      return null;
    }

    // 找到距离最近且在阈值内的匹配
    Guideline? bestStatic;
    double minDistance = double.infinity;

    for (final dynamicGuideline in candidateDynamicGuidelines) {
      for (final staticGuideline in horizontalStaticGuidelines) {
        final distance = (dynamicGuideline.position - staticGuideline.position).abs();
        if (distance <= _displayThreshold && distance < minDistance) {
          minDistance = distance;
          bestStatic = staticGuideline;
        }
      }
    }

    return bestStatic;
  }

  /// 找到最佳的纵向高亮参考线
  Guideline? _findBestVerticalGuideline(String operationType, String? resizeDirection) {
    // 获取参与检测的垂直动态参考线
    final candidateDynamicGuidelines = _getCandidateVerticalDynamicGuidelines(operationType, resizeDirection);
    
    if (candidateDynamicGuidelines.isEmpty) {
      return null;
    }    // 获取所有垂直静态参考线，排除被拖拽元素自身的参考线
    final verticalStaticGuidelines = _staticGuidelines
        .where((g) => g.direction == AlignmentDirection.vertical && 
                     g.sourceElementId != _draggingElementId)
        .toList();

    if (verticalStaticGuidelines.isEmpty) {
      return null;
    }

    // 找到距离最近且在阈值内的匹配
    Guideline? bestStatic;
    double minDistance = double.infinity;

    for (final dynamicGuideline in candidateDynamicGuidelines) {
      for (final staticGuideline in verticalStaticGuidelines) {
        final distance = (dynamicGuideline.position - staticGuideline.position).abs();
        if (distance <= _displayThreshold && distance < minDistance) {
          minDistance = distance;
          bestStatic = staticGuideline;
        }
      }
    }

    return bestStatic;
  }

  /// 获取参与检测的水平动态参考线
  List<Guideline> _getCandidateHorizontalDynamicGuidelines(String operationType, String? resizeDirection) {
    final horizontalDynamicGuidelines = _dynamicGuidelines
        .where((g) => g.direction == AlignmentDirection.horizontal)
        .toList();

    if (operationType == 'translate') {
      // 平移模式：所有水平动态参考线都参与
      return horizontalDynamicGuidelines;
    }

    if (operationType == 'resize' && resizeDirection != null) {
      // Resize模式：根据控制点类型筛选
      return _filterHorizontalGuidelinesForResize(horizontalDynamicGuidelines, resizeDirection);
    }

    return horizontalDynamicGuidelines;
  }

  /// 获取参与检测的垂直动态参考线
  List<Guideline> _getCandidateVerticalDynamicGuidelines(String operationType, String? resizeDirection) {
    final verticalDynamicGuidelines = _dynamicGuidelines
        .where((g) => g.direction == AlignmentDirection.vertical)
        .toList();

    if (operationType == 'translate') {
      // 平移模式：所有垂直动态参考线都参与
      return verticalDynamicGuidelines;
    }

    if (operationType == 'resize' && resizeDirection != null) {
      // Resize模式：根据控制点类型筛选
      return _filterVerticalGuidelinesForResize(verticalDynamicGuidelines, resizeDirection);
    }

    return verticalDynamicGuidelines;
  }

  /// 为Resize操作筛选水平动态参考线
  List<Guideline> _filterHorizontalGuidelinesForResize(
    List<Guideline> horizontalGuidelines, 
    String resizeDirection
  ) {
    switch (resizeDirection) {
      case 'top':
      case 'top-left':
      case 'top-right':
        // 拖拽顶部相关：只考虑上边缘参考线
        return horizontalGuidelines
            .where((g) => g.type == GuidelineType.horizontalTopEdge)
            .toList();
      case 'bottom':
      case 'bottom-left':
      case 'bottom-right':
        // 拖拽底部相关：只考虑下边缘参考线
        return horizontalGuidelines
            .where((g) => g.type == GuidelineType.horizontalBottomEdge)
            .toList();
      default:
        // 左右边控制点：不涉及水平参考线
        return [];
    }
  }

  /// 为Resize操作筛选垂直动态参考线
  List<Guideline> _filterVerticalGuidelinesForResize(
    List<Guideline> verticalGuidelines, 
    String resizeDirection
  ) {
    switch (resizeDirection) {
      case 'left':
      case 'top-left':
      case 'bottom-left':
        // 拖拽左侧相关：只考虑左边缘参考线
        return verticalGuidelines
            .where((g) => g.type == GuidelineType.verticalLeftEdge)
            .toList();
      case 'right':
      case 'top-right':
      case 'bottom-right':
        // 拖拽右侧相关：只考虑右边缘参考线
        return verticalGuidelines
            .where((g) => g.type == GuidelineType.verticalRightEdge)
            .toList();
      default:
        // 上下边控制点：不涉及垂直参考线
        return [];
    }
  }

  /// 根据动态参考线类型计算对齐后的Y坐标
  double _calculateAlignedYFromDynamicGuideline(
    Guideline dynamicGuideline, 
    double targetPosition, 
    Size elementSize
  ) {
    switch (dynamicGuideline.type) {
      case GuidelineType.horizontalCenterLine:
        // 如果动态参考线是中心线，则元素中心对齐到目标位置
        return targetPosition - elementSize.height / 2;
      case GuidelineType.horizontalTopEdge:
        // 如果动态参考线是上边缘，则元素上边缘对齐到目标位置
        return targetPosition;
      case GuidelineType.horizontalBottomEdge:
        // 如果动态参考线是下边缘，则元素下边缘对齐到目标位置
        return targetPosition - elementSize.height;
      default:
        return targetPosition;
    }
  }

  /// 根据动态参考线类型计算对齐后的X坐标
  double _calculateAlignedXFromDynamicGuideline(
    Guideline dynamicGuideline, 
    double targetPosition, 
    Size elementSize
  ) {
    switch (dynamicGuideline.type) {
      case GuidelineType.verticalCenterLine:
        // 如果动态参考线是中心线，则元素中心对齐到目标位置
        return targetPosition - elementSize.width / 2;
      case GuidelineType.verticalLeftEdge:
        // 如果动态参考线是左边缘，则元素左边缘对齐到目标位置
        return targetPosition;
      case GuidelineType.verticalRightEdge:
        // 如果动态参考线是右边缘，则元素右边缘对齐到目标位置
        return targetPosition - elementSize.width;
      default:
        return targetPosition;
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
