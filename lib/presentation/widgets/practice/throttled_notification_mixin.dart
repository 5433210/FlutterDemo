import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';

/// 节流通知混入
/// 用于优化高频操作中的UI更新性能
mixin ThrottledNotificationMixin on ChangeNotifier {
  Timer? _notificationTimer;
  bool _hasPendingUpdate = false;
  int _throttledCallCount = 0;
  int _actualNotificationCount = 0;
  
  /// 节流通知，避免过度频繁的UI更新
  void throttledNotifyListeners({
    Duration delay = const Duration(milliseconds: 16), // 60 FPS
  }) {
    _throttledCallCount++;
    
    if (_notificationTimer?.isActive == true) {
      _hasPendingUpdate = true;
      return;
    }
    
    _notificationTimer = Timer(delay, () {
      _actualNotificationCount++;
      super.notifyListeners();
      
      // 如果有待处理的更新，继续执行
      if (_hasPendingUpdate) {
        _hasPendingUpdate = false;
        throttledNotifyListeners(delay: delay);
      }
    });
  }
  
  /// 立即通知（用于关键操作）
  void immediateNotifyListeners() {
    _notificationTimer?.cancel();
    _hasPendingUpdate = false;
    _actualNotificationCount++;
    super.notifyListeners();
  }
  
  /// 获取节流统计信息
  Map<String, int> getThrottleStats() {
    return {
      'throttledCalls': _throttledCallCount,
      'actualNotifications': _actualNotificationCount,
      'savedCalls': _throttledCallCount - _actualNotificationCount,
    };
  }
  
  /// 重置统计信息
  void resetThrottleStats() {
    _throttledCallCount = 0;
    _actualNotificationCount = 0;
  }
  
  /// 记录节流性能日志
  void logThrottlePerformance() {
    final stats = getThrottleStats();
    final efficiencyPercent = _throttledCallCount > 0 
        ? (stats['savedCalls']! / _throttledCallCount * 100).toStringAsFixed(1)
        : '0.0';
        
    EditPageLogger.performanceInfo(
      '节流通知性能统计',
      data: {
        'throttledCalls': stats['throttledCalls'],
        'actualNotifications': stats['actualNotifications'],
        'savedCalls': stats['savedCalls'],
        'efficiencyPercent': '$efficiencyPercent%',
        'operation': 'throttle_performance_stats',
      },
    );
  }
  
  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }
}

/// 拖拽专用的高性能通知混入
mixin DragOptimizedNotificationMixin on ChangeNotifier {
  Timer? _dragNotificationTimer;
  bool _isDragging = false;
  bool _hasPendingDragUpdate = false;
  
  /// 开始拖拽模式（使用更激进的节流）
  void startDragMode() {
    _isDragging = true;
    EditPageLogger.performanceInfo(
      '开始拖拽模式，启用高性能节流',
      data: {'operation': 'start_drag_mode'},
    );
  }
  
  /// 拖拽过程中的通知（高度节流）
  void dragNotifyListeners() {
    if (!_isDragging) {
      // 非拖拽模式，使用正常通知
      notifyListeners();
      return;
    }
    
    if (_dragNotificationTimer?.isActive == true) {
      _hasPendingDragUpdate = true;
      return;
    }
    
    _dragNotificationTimer = Timer(
      const Duration(milliseconds: 32), // 30 FPS during drag
      () {
        notifyListeners();
        if (_hasPendingDragUpdate) {
          _hasPendingDragUpdate = false;
          dragNotifyListeners();
        }
      },
    );
  }
  
  /// 结束拖拽模式
  void endDragMode() {
    _isDragging = false;
    _dragNotificationTimer?.cancel();
    _hasPendingDragUpdate = false;
    
    // 拖拽结束后立即触发最终更新
    notifyListeners();
    
    EditPageLogger.performanceInfo(
      '结束拖拽模式，恢复正常更新频率',
      data: {'operation': 'end_drag_mode'},
    );
  }
  
  @override
  void dispose() {
    _dragNotificationTimer?.cancel();
    super.dispose();
  }
}

/// 批量更新混入
mixin BatchNotificationMixin on ChangeNotifier {
  bool _batchMode = false;
  bool _hasPendingBatchUpdate = false;
  
  /// 开始批量更新模式
  void startBatchUpdate() {
    _batchMode = true;
    EditPageLogger.performanceInfo(
      '开始批量更新模式',
      data: {'operation': 'start_batch_update'},
    );
  }
  
  /// 批量模式中的通知（延迟到批量结束）
  void batchNotifyListeners() {
    if (_batchMode) {
      _hasPendingBatchUpdate = true;
    } else {
      notifyListeners();
    }
  }
  
  /// 结束批量更新并触发通知
  void commitBatchUpdate() {
    _batchMode = false;
    if (_hasPendingBatchUpdate) {
      _hasPendingBatchUpdate = false;
      notifyListeners();
      
      EditPageLogger.performanceInfo(
        '提交批量更新',
        data: {'operation': 'commit_batch_update'},
      );
    } else {
      EditPageLogger.performanceInfo(
        '批量更新无变更，跳过通知',
        data: {'operation': 'skip_batch_update'},
      );
    }
  }
} 