import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'alignment_config.dart';
import 'alignment_detector.dart';
import 'alignment_mode_manager.dart';
import 'alignment_types.dart';

/// 拖拽对齐处理器
///
/// 实时检测算法的核心挑战是在保证响应性的同时提供准确的对齐反馈。
/// 算法采用了增量计算和临时状态的设计模式。
class DragAlignmentHandler {
  final List<Map<String, dynamic>> _allElements;
  final ValueNotifier<List<AlignmentMatch>> _activeAlignments;
  final double Function() _getScaleFactor;

  /// 构造函数
  ///
  /// 参数:
  /// - [allElements]: 所有元素的引用
  /// - [getScaleFactor]: 获取当前缩放因子的回调
  DragAlignmentHandler({
    required List<Map<String, dynamic>> allElements,
    required double Function() getScaleFactor,
  })  : _allElements = allElements,
        _activeAlignments = ValueNotifier([]),
        _getScaleFactor = getScaleFactor;

  /// 获取当前活跃的对齐匹配数量
  int get activeAlignmentCount => _activeAlignments.value.length;

  /// 活跃对齐状态通知器
  ValueNotifier<List<AlignmentMatch>> get activeAlignments => _activeAlignments;

  /// 检查是否有活跃的对齐
  bool get hasActiveAlignments => _activeAlignments.value.isNotEmpty;

  /// 强制清除所有活跃对齐
  void clearActiveAlignments() {
    _activeAlignments.value = [];
  }

  /// 清理资源
  void dispose() {
    _activeAlignments.dispose();
  }

  /// 处理拖拽结束
  ///
  /// 拖拽结束对齐算法：
  /// 实现了智能的位置调整策略，确保用户释放鼠标时元素能够精确对齐：
  ///
  /// 调整策略：
  /// 1. 累积调整：将所有活跃对齐的调整量进行矢量叠加
  /// 2. 精确定位：确保最终位置精确对齐到参考线
  /// 3. 状态清理：处理完成后清除所有临时对齐状态
  ///
  /// 数学原理：
  /// 最终位置 = 原始拖拽位置 + 所有对齐调整的矢量和
  Offset onDragEnd(String elementId, Offset finalDelta) {
    var adjustedDelta = finalDelta;

    if (AlignmentModeManager.isGuideLineAlignmentEnabled &&
        _activeAlignments.value.isNotEmpty) {
      // 选择最佳对齐目标
      final bestAlignment = _selectBestAlignment(_activeAlignments.value);

      if (bestAlignment != null) {
        // 应用对齐调整
        adjustedDelta += bestAlignment.adjustment;

        // 记录对齐操作（用于调试和分析）
        _logAlignmentAction(elementId, bestAlignment);
      }
    }

    // 清除活跃对齐
    _activeAlignments.value = [];

    return adjustedDelta;
  }

  /// 处理拖拽更新
  ///
  /// 算法工作流程：
  /// 1. 临时状态创建：每次拖拽更新时，创建元素的临时副本
  /// 2. 增量检测：只对拖拽元素进行对齐检测，其他元素保持静态
  /// 3. 状态管理：使用ValueNotifier实现响应式状态更新
  ///
  /// 性能优化考虑：
  /// - 避免频繁GC：复用临时对象，减少内存分配  /// - 计算缓存：相同位置的检测结果可以缓存
  /// - 阈值过滤：早期过滤掉距离过远的匹配，减少后续计算
  void onDragUpdate(String elementId, Offset delta) {
    EditPageLogger.canvasDebug('开始拖拽对齐检测', data: {
      'elementId': elementId,
      'delta': '$delta',
      'operation': 'drag_alignment_update',
      'isGuideLineEnabled': AlignmentModeManager.isGuideLineAlignmentEnabled,
    });

    if (!AlignmentModeManager.isGuideLineAlignmentEnabled) {
      // 如果未启用参考线对齐，清空活跃对齐
      if (_activeAlignments.value.isNotEmpty) {
        EditPageLogger.canvasDebug('清空拖拽对齐状态', data: {
          'elementId': elementId,
          'operation': 'drag_alignment_clear',
        });
        _activeAlignments.value = [];
      }
      return;
    }

    EditPageLogger.canvasDebug('检测拖拽对齐', data: {
      'elementId': elementId,
      'totalElements': _allElements.length,
      'operation': 'drag_alignment_detect',
    });

    // 找到被拖拽的元素
    final draggedElement = _findElement(elementId);
    if (draggedElement == null) {
      EditPageLogger.canvasDebug('拖拽元素未找到', data: {
        'elementId': elementId,
        'operation': 'drag_alignment_element_not_found',
      });
      return;
    }

    EditPageLogger.canvasDebug('找到拖拽元素', data: {
      'elementId': elementId,
      'operation': 'drag_alignment_element_found',
    });

    // 创建临时位置的元素副本
    final tempElement = Map<String, dynamic>.from(draggedElement);
    tempElement['x'] = (tempElement['x'] as num).toDouble() + delta.dx;
    tempElement['y'] = (tempElement['y'] as num).toDouble() + delta.dy;

    // 检测对齐
    final otherElements =
        _allElements.where((e) => e['id'] != elementId).toList();
    EditPageLogger.canvasDebug('准备对齐检测', data: {
      'elementId': elementId,
      'otherElementsCount': otherElements.length,
      'operation': 'drag_alignment_prepare_detection',
    });
    final alignments = AlignmentDetector.detectAlignments(
      tempElement,
      otherElements,
      scaleFactor: _getScaleFactor(),
    );

    EditPageLogger.canvasDebug('对齐检测完成', data: {
      'elementId': elementId,
      'alignmentsCount': alignments.length,
      'operation': 'drag_alignment_detection_complete',
    });

    // 更新活跃对齐
    _activeAlignments.value = alignments;
    EditPageLogger.canvasDebug('活跃对齐状态更新', data: {
      'elementId': elementId,
      'activeAlignmentsCount': _activeAlignments.value.length,
      'operation': 'drag_alignment_state_update',
    });

    // 提供触觉反馈
    if (alignments.isNotEmpty && AlignmentConfig.enableHapticFeedback) {
      _provideTactileFeedback();
    }
  }

  /// 更新所有元素数据
  ///
  /// 用于动态更新所有元素的引用，确保对齐检测使用最新的元素位置和尺寸信息
  void updateElements(List<Map<String, dynamic>> newElements) {
    EditPageLogger.canvasDebug('更新拖拽对齐处理器元素数据', data: {
      'elementsCount': newElements.length,
      'previousElementsCount': _allElements.length,
      'operation': 'drag_alignment_update_elements',
    });

    _allElements.clear();
    _allElements.addAll(newElements);

    EditPageLogger.canvasDebug('拖拽对齐元素数据更新完成', data: {
      'currentElementsCount': _allElements.length,
      'elementIds': _allElements.map((e) => e['id']).toList(),
      'operation': 'drag_alignment_elements_updated',
    });
  }

  /// 查找指定ID的元素
  Map<String, dynamic>? _findElement(String elementId) {
    try {
      return _allElements.firstWhere((element) => element['id'] == elementId);
    } catch (e) {
      EditPageLogger.canvasDebug('元素查找失败', data: {
        'elementId': elementId,
        'error': e.toString(),
        'operation': 'drag_alignment_element_search_error',
      });
      return null;
    }
  }

  /// 获取对齐类型的优先级
  ///
  /// 优先级设计原理：
  /// 1. 中线对中线（权重1）：视觉平衡感最强，符合人类对称美学
  /// 2. 边线对边线（权重2）：适合创建整齐的边界对齐
  /// 3. 混合对齐（权重3）：用于特殊设计需求，优先级最低
  int _getAlignmentTypePriority(AlignmentType type) {
    switch (type) {
      case AlignmentType.centerToCenter:
        return 1; // 最高优先级
      case AlignmentType.edgeToEdge:
        return 2;
      case AlignmentType.centerToEdge:
      case AlignmentType.edgeToCenter:
        return 3; // 最低优先级
    }
  }

  /// 记录对齐操作（用于分析和调试）
  void _logAlignmentAction(String elementId, AlignmentMatch alignment) {
    if (AlignmentConfig.enablePerformanceLogging) {
      EditPageLogger.canvasDebug('元素自动对齐', data: {
        'elementId': elementId,
        'alignmentType': alignment.alignmentType.toString(),
        'distance': alignment.distance,
        'adjustmentDx': alignment.adjustment.dx,
        'adjustmentDy': alignment.adjustment.dy,
        'operation': 'drag_alignment_action',
      });
    }
  }

  /// 提供触觉反馈
  void _provideTactileFeedback() {
    try {
      // 在移动设备上提供轻微震动反馈
      HapticFeedback.lightImpact();
    } catch (e) {
      // 忽略触觉反馈错误（某些平台可能不支持）
      EditPageLogger.canvasDebug('触觉反馈失败', data: {
        'error': e.toString(),
        'operation': 'drag_alignment_haptic_feedback_error',
      });
    }
  }

  /// 选择最佳对齐目标
  ///
  /// 选择策略层次：
  /// 1. 距离优先：距离最近的对齐具有绝对优先权
  /// 2. 类型优先：当距离相同时，按对齐类型的视觉美感排序
  /// 3. 确定性原则：算法保证在相同输入下始终返回相同结果
  ///
  /// 算法复杂度：O(n log n)，主要消耗在排序阶段
  AlignmentMatch? _selectBestAlignment(List<AlignmentMatch> alignments) {
    if (alignments.isEmpty) return null;

    // 优先级排序：
    // 1. 距离最近的对齐
    // 2. 中线对中线优于边线对边线
    // 3. 同类型对齐优于混合对齐
    alignments.sort((a, b) {
      // 首先按距离排序
      final distanceComparison = a.distance.compareTo(b.distance);
      if (distanceComparison != 0) return distanceComparison;

      // 距离相同时，按对齐类型优先级排序
      final aPriority = _getAlignmentTypePriority(a.alignmentType);
      final bPriority = _getAlignmentTypePriority(b.alignmentType);
      return aPriority.compareTo(bPriority);
    });

    return alignments.first;
  }
}
