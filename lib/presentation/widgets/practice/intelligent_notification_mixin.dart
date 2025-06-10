import '../../../infrastructure/logging/edit_page_logger_extension.dart';

/// 智能通知基础 Mixin
/// 提供智能状态分发的抽象接口
mixin IntelligentNotificationMixin {
  /// 智能状态分发器 - 由实现类提供
  dynamic get intelligentDispatcher;

  /// 检查是否已销毁 - 由实现类提供
  void checkDisposed();

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
        intelligentDispatcher.dispatch(
          changeType: changeType,
          eventData: eventData,
          operation: operation ?? 'unknown',
          affectedElements: affectedElements,
          affectedLayers: affectedLayers,
          affectedUIComponents: affectedUIComponents,
        );

        // ✅ 总是认为智能分发成功，因为：
        // 1. 如果有监听器，会正确通知
        // 2. 如果没有监听器，也不需要回退到全局通知
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
      } catch (e) {
        EditPageLogger.performanceWarning(
          '智能状态分发器调用失败',
          data: {
            'changeType': changeType,
            'operation': operation ?? 'unknown',
            'error': e.toString(),
          },
        );
        // 只有在调用失败时才设置为失败
        dispatchSuccessful = false;
      }

      // 🚀 完全禁用回退到传统通知 - 只依赖智能状态分发器
      if (!dispatchSuccessful) {
        EditPageLogger.performanceWarning(
          '智能状态分发器调用失败，但不回退到传统通知',
          data: {
            'changeType': changeType,
            'operation': operation ?? 'unknown',
            'reason': 'avoid_traditional_ui_rebuild',
            'optimization': 'no_fallback_to_traditional_notification',
          },
        );
        // 🚀 不再回退到 throttledNotifyListeners()，完全依赖智能分发
      }
    } catch (e) {
      EditPageLogger.controllerError(
        '智能通知发生异常，但不回退到传统通知',
        data: {
          'changeType': changeType,
          'operation': operation ?? 'unknown',
          'error': e.toString(),
          'reason': 'avoid_traditional_ui_rebuild',
          'optimization': 'no_global_fallback',
        },
      );
      // 🚀 完全移除最后的回退机制，不再调用传统的 notifyListeners
    }
  }

  /// 节流通知方法 - 由实现类提供
  void throttledNotifyListeners(
      {Duration delay = const Duration(milliseconds: 16)});

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
