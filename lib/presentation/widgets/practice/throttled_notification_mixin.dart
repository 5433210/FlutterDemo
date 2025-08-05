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
    
    try {
      _notificationTimer = Timer(delay, () {
        _actualNotificationCount++;
        super.notifyListeners();
        
        // 如果有待处理的更新，继续执行
        if (_hasPendingUpdate) {
          _hasPendingUpdate = false;
          throttledNotifyListeners(delay: delay);
        }
      });
    } catch (e) {
      // 定时器创建失败时记录错误并立即通知
      EditPageLogger.editPageError(
        '节流通知定时器创建失败',
        data: {'error': e.toString(), 'operation': 'throttle_timer_error'},
      );
      super.notifyListeners();
    }
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
  
  /// 记录节流性能日志（仅在有显著性能影响时记录）
  void logThrottlePerformance() {
    final stats = getThrottleStats();
    final savedCalls = stats['savedCalls']!;
    
    // 🚀 优化：提高性能统计记录阈值，减少频繁日志
    if (savedCalls > 100) { // 从50次提高到100次
      final efficiencyPercent = _throttledCallCount > 0 
          ? (savedCalls / _throttledCallCount * 100).toStringAsFixed(1)
          : '0.0';
          
      EditPageLogger.performanceInfo(
        '节流通知显著优化',
        data: {
          'savedCalls': savedCalls,
          'efficiencyPercent': '$efficiencyPercent%',
          'operation': 'throttle_performance_milestone',
        },
      );
    }
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
  int _dragSessionCount = 0;
  
  /// 开始拖拽模式（使用更激进的节流）
  void startDragMode() {
    _isDragging = true;
    _dragSessionCount++;
    
    // 🚀 优化：进一步减少拖拽模式日志，只在首次或重要里程碑时记录
    if (kDebugMode && (_dragSessionCount == 1 || _dragSessionCount % 20 == 0)) {
      EditPageLogger.editPageDebug(
        '拖拽优化模式里程碑',
        data: {'operation': 'drag_mode_milestone', 'sessionCount': _dragSessionCount},
      );
    }
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
    
    try {
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
    } catch (e) {
      // 拖拽定时器失败时记录错误并立即通知
      EditPageLogger.editPageError(
        '拖拽通知定时器失败',
        data: {'error': e.toString(), 'operation': 'drag_timer_error'},
      );
      notifyListeners();
    }
  }
  
  /// 结束拖拽模式
  void endDragMode() {
    _isDragging = false;
    _dragNotificationTimer?.cancel();
    _hasPendingDragUpdate = false;
    
    // 拖拽结束后立即触发最终更新
    notifyListeners();
    
    // 🚀 优化：进一步减少拖拽结束日志频率
    if (kDebugMode && _dragSessionCount % 25 == 0) {
      EditPageLogger.editPageDebug(
        '拖拽会话里程碑',
        data: {'operation': 'drag_milestone', 'totalSessions': _dragSessionCount},
      );
    }
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
  int _batchOperationCount = 0;
  
  /// 开始批量更新模式
  void startBatchUpdate() {
    _batchMode = true;
    _batchOperationCount++;
    
    // 🚀 优化：进一步减少批量操作日志频率
    if (_batchOperationCount == 1 || _batchOperationCount % 50 == 0) {
      EditPageLogger.editPageDebug(
        '批量更新里程碑',
        data: {'operation': 'batch_update_milestone', 'count': _batchOperationCount},
      );
    }
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
      
      // 🚀 优化：进一步减少批量提交日志频率
      if (_batchOperationCount % 25 == 0) {
        EditPageLogger.editPageDebug(
          '批量更新提交里程碑',
          data: {'operation': 'batch_commit_milestone', 'totalOperations': _batchOperationCount},
        );
      }
    }
    // 移除无变更的日志记录以减少噪音
  }
} 