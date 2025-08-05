import 'practice_edit_logger.dart';

/// 工具栏专用日志工具类
/// 针对高频交互的工具栏操作进行优化，减少日志噪音
class ToolbarLogger {
  static final Map<String, DateTime> _lastActionTime = {};
  static final Map<String, String> _lastActionState = {};
  
  // 工具栏操作防重复间隔（毫秒）
  static const int actionDedupeInterval = 300;
  static const int stateDedupeInterval = 500;

  /// 记录工具切换操作（防重复）
  static void logToolSwitch(String from, String to) {
    const key = 'tool_switch';
    final stateKey = '${from}_to_$to';
    
    // 检查状态是否重复
    if (_lastActionState[key] == stateKey) {
      return;
    }
    
    // 检查时间间隔
    final now = DateTime.now();
    final lastTime = _lastActionTime[key];
    if (lastTime != null && 
        now.difference(lastTime).inMilliseconds < actionDedupeInterval) {
      return;
    }
    
    _lastActionTime[key] = now;
    _lastActionState[key] = stateKey;
    
    PracticeEditLogger.logUserAction('工具切换', data: {
      'from': from,
      'to': to
    });
  }

  /// 记录元素创建操作（去重）
  static void logElementCreate(String elementType) {
    final key = 'element_create_$elementType';
    final now = DateTime.now();
    final lastTime = _lastActionTime[key];
    
    // 相同类型元素创建有防重复间隔
    if (lastTime != null && 
        now.difference(lastTime).inMilliseconds < actionDedupeInterval) {
      return;
    }
    
    _lastActionTime[key] = now;
    
    PracticeEditLogger.logUserAction('创建元素', data: {
      'type': elementType
    });
  }

  /// 记录拖拽创建操作（仅开始时记录一次）
  static void logDragCreateStart(String elementType) {
    // 拖拽创建只在开始时记录，不记录过程
    PracticeEditLogger.debugDetail('拖拽创建开始', data: {
      'type': elementType
    });
  }

  /// 记录编辑操作（批量处理）
  static void logEditOperation(String operation, {Map<String, dynamic>? context}) {
    const key = 'edit_operation';
    const dedupeInterval = 200;
    final now = DateTime.now();
    final lastTime = _lastActionTime[key];
    
    // 编辑操作有适度的防重复
    if (lastTime != null && 
        now.difference(lastTime).inMilliseconds < dedupeInterval) {
      return;
    }
    
    _lastActionTime[key] = now;
    
    PracticeEditLogger.logUserAction(operation, data: context);
  }

  /// 记录网格和对齐状态切换（防重复）
  static void logViewStateToggle(String stateName, bool newValue) {
    final key = 'view_state_$stateName';
    final stateValue = newValue.toString();
    
    // 检查状态是否真的改变了
    if (_lastActionState[key] == stateValue) {
      return;
    }
    
    final now = DateTime.now();
    final lastTime = _lastActionTime[key];
    if (lastTime != null && 
        now.difference(lastTime).inMilliseconds < stateDedupeInterval) {
      return;
    }
    
    _lastActionTime[key] = now;
    _lastActionState[key] = stateValue;
    
    PracticeEditLogger.logStateChange('工具栏', stateName, 
        newValue ? '开启' : '关闭');
  }

  /// 记录对齐模式切换（三态切换专用）
  static void logAlignmentModeToggle(String fromMode, String toMode) {
    const key = 'alignment_mode';
    final stateKey = '${fromMode}_to_$toMode';
    
    // 检查是否是有意义的状态切换
    if (fromMode == toMode || _lastActionState[key] == stateKey) {
      return;
    }
    
    final now = DateTime.now();
    final lastTime = _lastActionTime[key];
    if (lastTime != null && 
        now.difference(lastTime).inMilliseconds < stateDedupeInterval) {
      return;
    }
    
    _lastActionTime[key] = now;
    _lastActionState[key] = stateKey;
    
    PracticeEditLogger.logStateChange('对齐模式', fromMode, toMode);
  }

  /// 记录选择操作摘要（而非详细信息）
  static void logSelectionOperation(String operation, int elementCount) {
    // 选择相关操作只记录操作类型和元素数量，不记录详细ID
    if (elementCount > 0) {
      PracticeEditLogger.logUserAction(operation, data: {
        'count': elementCount
      });
    }
  }

  /// 记录图层操作
  static void logLayerOperation(String operation, int elementCount) {
    if (elementCount > 0) {
      PracticeEditLogger.logUserAction(operation, data: {
        'count': elementCount
      });
    }
  }

  /// 记录组合操作
  static void logGroupOperation(String operation, int elementCount, {String? groupType}) {
    if (elementCount > 0) {
      final data = <String, dynamic>{'count': elementCount};
      if (groupType != null) {
        data['groupType'] = groupType;
      }
      PracticeEditLogger.logUserAction(operation, data: data);
    }
  }

  /// 记录格式操作（防重复）
  static void logFormatOperation(String operation) {
    const key = 'format_operation';
    const dedupeInterval = 300;
    final now = DateTime.now();
    final lastTime = _lastActionTime[key];
    
    if (lastTime != null && 
        now.difference(lastTime).inMilliseconds < dedupeInterval) {
      return;
    }
    
    _lastActionTime[key] = now;
    
    PracticeEditLogger.logUserAction(operation);
  }

  /// 记录工具栏错误（完整保留）
  static void logError(String operation, Object error, {StackTrace? stackTrace}) {
    PracticeEditLogger.logError(operation, error, 
        stackTrace: stackTrace, 
        context: {'component': 'toolbar'});
  }

  /// 清理过期状态
  static void cleanup() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _lastActionTime.entries) {
      if (now.difference(entry.value).inMinutes > 5) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _lastActionTime.remove(key);
      _lastActionState.remove(key);
    }
  }

  /// 获取工具栏日志统计信息
  static Map<String, dynamic> getStats() {
    return {
      'tracked_actions': _lastActionTime.length,
      'tracked_states': _lastActionState.length,
      'dedupe_interval_ms': actionDedupeInterval,
      'state_dedupe_interval_ms': stateDedupeInterval,
    };
  }
}