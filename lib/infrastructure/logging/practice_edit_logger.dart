import 'package:flutter/foundation.dart';
import 'logger.dart';

/// 字帖编辑专用日志工具类
/// 提供操作会话追踪、性能监控、智能去重等功能
class PracticeEditLogger {
  static final Map<String, DateTime> _operationStartTimes = {};
  static final Map<String, dynamic> _sessionData = {};
  
  /// 开始操作会话
  static String startOperation(String operationName, [Map<String, dynamic>? initialData]) {
    final sessionId = '${operationName}_${DateTime.now().millisecondsSinceEpoch}';
    _operationStartTimes[sessionId] = DateTime.now();
    
    if (initialData != null) {
      _sessionData[sessionId] = initialData;
    }
    
    AppLogger.info(
      '开始操作: $operationName',
      tag: 'PracticeEdit',
      data: {
        'sessionId': sessionId,
        'timestamp': DateTime.now().toIso8601String(),
        ...?initialData,
      },
    );
    
    return sessionId;
  }
  
  /// 结束操作会话
  static void endOperation(String sessionId, {bool success = true, String? error}) {
    final startTime = _operationStartTimes[sessionId];
    final sessionData = _sessionData[sessionId];
    
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      if (success) {
        AppLogger.info(
          '操作完成',
          tag: 'PracticeEdit',
          data: {
            'sessionId': sessionId,
            'duration': duration,
            'success': true,
            'timestamp': DateTime.now().toIso8601String(),
            ...?sessionData,
          },
        );
      } else {
        AppLogger.error(
          '操作失败',
          tag: 'PracticeEdit',
          error: error != null ? Exception(error) : Exception('Unknown error'),
          data: {
            'sessionId': sessionId,
            'duration': duration,
            'success': false,
            'timestamp': DateTime.now().toIso8601String(),
            ...?sessionData,
          },
        );
      }
      
      _operationStartTimes.remove(sessionId);
      _sessionData.remove(sessionId);
    }
  }
  
  /// 记录用户操作
  static void logUserAction(String action, {Map<String, dynamic>? data}) {
    AppLogger.info(
      '用户操作: $action',
      tag: 'PracticeEdit',
      data: {
        'userAction': action,
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
    );
  }
  
  /// 记录业务操作
  static void logBusinessOperation(String category, String operation, {Map<String, dynamic>? metrics}) {
    AppLogger.info(
      '$category - $operation',
      tag: 'PracticeEdit',
      data: {
        'category': category,
        'operation': operation,
        'timestamp': DateTime.now().toIso8601String(),
        ...?metrics,
      },
    );
  }
  
  /// 记录调试细节
  static void debugDetail(String message, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      AppLogger.debug(
        message,
        tag: 'PracticeEdit',
        data: {
          'timestamp': DateTime.now().toIso8601String(),
          ...?data,
        },
      );
    }
  }
  
  /// 记录页面生命周期
  static void logPageLifecycle(String event, {Map<String, dynamic>? data}) {
    AppLogger.info(
      '页面生命周期: $event',
      tag: 'PracticeEdit',
      data: {
        'lifecycle': event,
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
    );
  }
  
  /// 记录性能操作
  static void logPerformanceOperation(String operation, int durationMs, {Map<String, dynamic>? data}) {
    final level = durationMs > 1000 ? 'warning' : 'info';
    
    if (level == 'warning') {
      AppLogger.warning(
        '性能警告: $operation',
        tag: 'PracticeEdit',
        data: {
          'operation': operation,
          'duration': durationMs,
          'threshold': 1000,
          'timestamp': DateTime.now().toIso8601String(),
          ...?data,
        },
      );
    } else {
      AppLogger.info(
        '性能监控: $operation',
        tag: 'PracticeEdit',
        data: {
          'operation': operation,
          'duration': durationMs,
          'timestamp': DateTime.now().toIso8601String(),
          ...?data,
        },
      );
    }
  }
  
  /// 记录文件操作
  static void logFileOperation(String operation, String filePath, {bool success = true, int? duration}) {
    AppLogger.info(
      '文件操作: $operation',
      tag: 'PracticeEdit',
      data: {
        'operation': operation,
        'filePath': filePath,
        'success': success,
        'duration': duration,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  /// 记录错误
  static void logError(String message, dynamic error, {String? sessionId, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    AppLogger.error(
      message,
      tag: 'PracticeEdit',
      error: error is Exception ? error : Exception(error.toString()),
      stackTrace: stackTrace,
      data: {
        'sessionId': sessionId,
        'timestamp': DateTime.now().toIso8601String(),
        ...?context,
      },
    );
  }
  
  /// 记录状态变化
  static void logStateChange(String component, String stateName, String newValue) {
    AppLogger.info(
      '状态变化: $component - $stateName',
      tag: 'PracticeEdit',
      data: {
        'component': component,
        'state': stateName,
        'newValue': newValue,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}

/// 性能计时器
class PerformanceTimer {
  final String operation;
  final int customThreshold;
  final DateTime _startTime;
  
  PerformanceTimer(this.operation, {this.customThreshold = 500}) 
      : _startTime = DateTime.now();
  
  /// 获取已经过的毫秒数
  int get elapsedMilliseconds => DateTime.now().difference(_startTime).inMilliseconds;
  
  /// 完成计时并记录结果
  void finish() {
    final duration = DateTime.now().difference(_startTime).inMilliseconds;
    
    if (duration > customThreshold) {
      PracticeEditLogger.logPerformanceOperation(operation, duration, data: {
        'threshold': customThreshold,
        'exceeded': true,
      });
    }
  }
  
  /// 完成渲染计时并记录结果 (canvas专用)
  void finishRender() {
    final duration = DateTime.now().difference(_startTime).inMilliseconds;
    
    if (duration > customThreshold) {
      PracticeEditLogger.logPerformanceOperation('Canvas Render: $operation', duration, data: {
        'threshold': customThreshold,
        'exceeded': true,
        'renderType': 'canvas',
      });
    }
  }
}