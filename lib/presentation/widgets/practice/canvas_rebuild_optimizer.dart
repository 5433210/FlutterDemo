import 'dart:async';
import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'practice_edit_controller.dart';

/// 🚀 Canvas重建优化器
/// 通过智能监听和状态分发来减少不必要的Canvas重建
class CanvasRebuildOptimizer extends ChangeNotifier {
  final PracticeEditController _controller;
  
  // 🔧 重建节流机制
  Timer? _rebuildTimer;
  bool _hasPendingRebuild = false;
  static const Duration _rebuildThrottle = Duration(milliseconds: 16); // ~60fps
  
  // 🔧 状态缓存 - 避免相同状态的重复重建
  String? _lastStateHash;
  int _rebuildCount = 0;
  int _skippedRebuilds = 0;
  
  // 🔧 重建原因跟踪
  final List<String> _rebuildReasons = [];
  final Map<String, int> _rebuildReasonCounts = {};
  
  // 🔧 智能监听器
  bool _isListening = false;
  
  // 🚀 节流通知相关
  Timer? _notificationTimer;
  bool _hasPendingUpdate = false;
  DateTime _lastNotificationTime = DateTime.now();
  static const Duration _notificationThrottle = Duration(milliseconds: 16); // 60 FPS
  
  CanvasRebuildOptimizer(this._controller) {
    _setupIntelligentListening();
  }
  
  /// 获取重建统计信息
  Map<String, dynamic> getRebuildStats() {
    return {
      'totalRebuilds': _rebuildCount,
      'skippedRebuilds': _skippedRebuilds,
      'skipRate': (_rebuildCount + _skippedRebuilds) > 0 
          ? _skippedRebuilds / (_rebuildCount + _skippedRebuilds) 
          : 0.0,
      'rebuildReasons': Map.from(_rebuildReasonCounts),
      'hasPendingRebuild': _hasPendingRebuild,
    };
  }
  
  /// 🚀 智能重建请求 - 带节流和去重
  void requestRebuild(String reason) {
    // 记录重建原因
    _rebuildReasons.add(reason);
    _rebuildReasonCounts[reason] = (_rebuildReasonCounts[reason] ?? 0) + 1;
    
    // 生成当前状态哈希
    final currentStateHash = _generateStateHash();
    
    // 检查是否为重复状态
    if (_lastStateHash == currentStateHash) {
      _skippedRebuilds++;
      EditPageLogger.performanceInfo(
        '跳过重复Canvas重建',
        data: {
          'reason': reason,
          'stateHash': currentStateHash,
          'optimization': 'duplicate_state_skip',
        },
      );
      return;
    }
    
    // 如果已有待处理的重建，取消之前的定时器
    if (_hasPendingRebuild) {
      _rebuildTimer?.cancel();
    }
    
    _hasPendingRebuild = true;
    
    // 设置节流定时器
    _rebuildTimer = Timer(_rebuildThrottle, () {
      _executePendingRebuild(reason, currentStateHash);
    });
  }
  
  /// 🚀 强制立即重建 - 用于关键操作
  void forceRebuild(String reason) {
    _rebuildTimer?.cancel();
    _hasPendingRebuild = false;
    
    final currentStateHash = _generateStateHash();
    _executePendingRebuild(reason, currentStateHash);
  }
  
  /// 执行待处理的重建
  void _executePendingRebuild(String reason, String stateHash) {
    _hasPendingRebuild = false;
    _lastStateHash = stateHash;
    _rebuildCount++;
    
    EditPageLogger.performanceInfo(
      'Canvas重建执行',
      data: {
        'reason': reason,
        'rebuildCount': _rebuildCount,
        'stateHash': stateHash,
        'optimization': 'throttled_rebuild',
      },
    );
    
    // 触发实际的重建
    _throttledNotifyListeners(operation: 'rebuild', data: {
      'reason': reason,
      'rebuildCount': _rebuildCount,
      'stateHash': stateHash,
    });
    
    // 清理重建原因历史（保留最近10个）
    if (_rebuildReasons.length > 10) {
      _rebuildReasons.removeAt(0);
    }
  }
  
  /// 生成状态哈希用于去重
  String _generateStateHash() {
    final state = _controller.state;
    return '${state.currentPageIndex}_'
           '${state.selectedElementIds.length}_'
           '${state.currentTool}_'
           '${state.currentPageElements.length}_'
           '${state.gridVisible}_'
           '${state.snapEnabled}';
  }
  
  /// 设置智能监听
  void _setupIntelligentListening() {
    // 监听控制器变化，但使用智能过滤
    _controller.addListener(_analyzeControllerChange);
    _isListening = true;
  }
  
  /// 分析控制器变化，决定是否需要重建
  void _analyzeControllerChange() {
    // 分析变化类型，只对影响Canvas显示的变化进行重建
    final state = _controller.state;
    
    // 检查关键状态变化
    final criticalChanges = <String>[];
    
    // 页面变化
    if (_lastPageIndex != state.currentPageIndex) {
      criticalChanges.add('page_change');
      _lastPageIndex = state.currentPageIndex;
    }
    
    // 元素数量变化
    if (_lastElementCount != state.currentPageElements.length) {
      criticalChanges.add('element_count_change');
      _lastElementCount = state.currentPageElements.length;
    }
    
    // 选择状态变化
    if (_lastSelectedCount != state.selectedElementIds.length) {
      criticalChanges.add('selection_change');
      _lastSelectedCount = state.selectedElementIds.length;
    }
    
    // 工具变化
    if (_lastTool != state.currentTool) {
      criticalChanges.add('tool_change');
      _lastTool = state.currentTool;
    }
    
    // 网格设置变化
    if (_lastGridVisible != state.gridVisible || _lastSnapEnabled != state.snapEnabled) {
      criticalChanges.add('grid_settings_change');
      _lastGridVisible = state.gridVisible;
      _lastSnapEnabled = state.snapEnabled;
    }
    
    // 如果有关键变化，请求重建
    if (criticalChanges.isNotEmpty) {
      requestRebuild(criticalChanges.join('+'));
    }
  }
  
  // 状态缓存变量
  int? _lastPageIndex;
  int? _lastElementCount;
  int? _lastSelectedCount;
  String? _lastTool;
  bool? _lastGridVisible;
  bool? _lastSnapEnabled;
  
  /// 🚀 节流通知方法 - 避免Canvas重建优化器过于频繁地触发UI更新
  void _throttledNotifyListeners({
    required String operation,
    Map<String, dynamic>? data,
  }) {
    final now = DateTime.now();
    if (now.difference(_lastNotificationTime) >= _notificationThrottle) {
      _lastNotificationTime = now;
      
      EditPageLogger.performanceInfo(
        'Canvas重建优化器通知',
        data: {
          'operation': operation,
          'rebuildCount': _rebuildCount,
          'skippedRebuilds': _skippedRebuilds,
          'optimization': 'throttled_canvas_rebuild_notification',
          ...?data,
        },
      );
      
      super.notifyListeners();
    } else {
      // 缓存待处理的更新
      if (!_hasPendingUpdate) {
        _hasPendingUpdate = true;
        _notificationTimer?.cancel();
        _notificationTimer = Timer(_notificationThrottle, () {
          _hasPendingUpdate = false;
          
          EditPageLogger.performanceInfo(
            'Canvas重建优化器延迟通知',
            data: {
              'operation': operation,
              'rebuildCount': _rebuildCount,
              'skippedRebuilds': _skippedRebuilds,
              'optimization': 'throttled_delayed_canvas_rebuild_notification',
              ...?data,
            },
          );
          
          super.notifyListeners();
        });
      }
    }
  }
  
  @override
  void dispose() {
    _rebuildTimer?.cancel();
    if (_isListening) {
      _controller.removeListener(_analyzeControllerChange);
      _isListening = false;
    }
    super.dispose();
  }
}

/// 🚀 优化的Canvas监听器Widget
/// 替代直接的ListenableBuilder，提供智能重建功能
class OptimizedCanvasListener extends StatefulWidget {
  final PracticeEditController controller;
  final Widget Function(BuildContext context, PracticeEditController controller) builder;
  
  const OptimizedCanvasListener({
    super.key,
    required this.controller,
    required this.builder,
  });
  
  @override
  State<OptimizedCanvasListener> createState() => _OptimizedCanvasListenerState();
}

class _OptimizedCanvasListenerState extends State<OptimizedCanvasListener> {
  late CanvasRebuildOptimizer _optimizer;
  
  @override
  void initState() {
    super.initState();
    _optimizer = CanvasRebuildOptimizer(widget.controller);
    _optimizer.addListener(_onOptimizerRebuild);
  }
  
  @override
  void dispose() {
    _optimizer.removeListener(_onOptimizerRebuild);
    _optimizer.dispose();
    super.dispose();
  }
  
  void _onOptimizerRebuild() {
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.controller);
  }
} 