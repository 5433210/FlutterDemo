import '../../../infrastructure/logging/edit_page_logger_extension.dart';

/// 智能通知基础 Mixin
/// 提供智能状态分发的抽象接口
mixin IntelligentNotificationMixin {
  /// 智能状态分发器 - 由实现类提供
  dynamic get intelligentDispatcher;

  /// 检查是否已销毁 - 由实现类提供
  void checkDisposed();

  /// 节流通知方法 - 由实现类提供
  void throttledNotifyListeners({Duration delay = const Duration(milliseconds: 16)});

  /// 🚀 智能通知方法 - 优先使用分层架构，回退到节流通知
  void intelligentNotify({
    required String changeType,
    required Map<String, dynamic> eventData,
    String? operation,
    List<String>? affectedElements,
    List<String>? affectedLayers,
    List<String>? affectedUIComponents,
  }) {
    try {
      checkDisposed();
      
      // 🚀 尝试使用智能状态分发器
      bool dispatchSuccessful = false;
      
      try {
        intelligentDispatcher.dispatchStateChange(
          changeType: changeType,
          changeData: eventData,
          affectedElements: affectedElements,
          affectedLayers: affectedLayers,
          affectedUIComponents: affectedUIComponents,
        );
        
        // 检查是否有监听器被通知到
        final hasListeners = _hasRegisteredListeners(affectedLayers, affectedUIComponents, affectedElements);
        
        if (hasListeners) {
          dispatchSuccessful = true;
          EditPageLogger.performanceInfo(
            '智能状态分发成功',
            data: {
              'changeType': changeType,
              'operation': operation ?? 'unknown',
              'affectedElements': affectedElements?.length ?? 0,
              'affectedLayers': affectedLayers?.length ?? 0,
              'affectedUIComponents': affectedUIComponents?.length ?? 0,
              'optimization': 'intelligent_dispatch',
            },
          );
        }
      } catch (e) {
        EditPageLogger.performanceWarning(
          '智能状态分发器调用失败',
          data: {
            'changeType': changeType,
            'operation': operation ?? 'unknown',
            'error': e.toString(),
          },
        );
      }
      
      // 🔄 如果智能分发失败或没有监听器，回退到节流通知
      if (!dispatchSuccessful) {
        EditPageLogger.performanceInfo(
          '智能状态分发无监听器，回退到节流通知',
          data: {
            'changeType': changeType,
            'operation': operation ?? 'unknown',
            'fallback': 'throttled_notification',
          },
        );
        
        throttledNotifyListeners();
      }
      
    } catch (e) {
      EditPageLogger.controllerError(
        '智能通知完全失败，强制使用notifyListeners',
        data: {
          'changeType': changeType,
          'operation': operation ?? 'unknown',
          'error': e.toString(),
        },
      );
      
      // 最后的回退：直接调用notifyListeners
      try {
        throttledNotifyListeners();
      } catch (fallbackError) {
        EditPageLogger.controllerError(
          '节流通知也失败了',
          data: {
            'changeType': changeType,
            'operation': operation ?? 'unknown',
            'originalError': e.toString(),
            'fallbackError': fallbackError.toString(),
          },
        );
      }
    }
  }
  
  /// 检查是否有注册的监听器
  bool _hasRegisteredListeners(
    List<String>? affectedLayers,
    List<String>? affectedUIComponents,
    List<String>? affectedElements,
  ) {
    try {
      // 使用智能分发器的公共方法检查监听器
      return intelligentDispatcher.hasRegisteredListeners(
        affectedLayers: affectedLayers,
        affectedUIComponents: affectedUIComponents,
        affectedElements: affectedElements,
      );
    } catch (e) {
      // 如果检查失败，假设没有监听器
      return false;
    }
  }
} 