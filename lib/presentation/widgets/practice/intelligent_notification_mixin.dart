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

        // ✅ 检查是否所有预期的UI组件都有监听器
        // 如果有UI组件没有注册监听器，则需要回退到传统通知
        bool hasAllUIComponentListeners = _hasAllUIComponentListeners(affectedUIComponents);
        
        if (hasAllUIComponentListeners || (affectedUIComponents?.isEmpty ?? true)) {
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
        } else {
          dispatchSuccessful = false;
          EditPageLogger.performanceWarning(
            '部分UI组件没有注册监听器，需要回退到传统通知',
            data: {
              'changeType': changeType,
              'operation': operation ?? 'unknown',
              'affectedUIComponents': affectedUIComponents,
              'reason': 'missing_ui_component_listeners',
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
        // 只有在调用失败时才设置为失败
        dispatchSuccessful = false;
      }

      // 🔧 临时恢复回退到传统通知，直到所有UI组件注册监听器
      if (!dispatchSuccessful) {
        EditPageLogger.performanceWarning(
          '智能状态分发器调用失败，回退到传统通知',
          data: {
            'changeType': changeType,
            'operation': operation ?? 'unknown',
            'reason': 'ensure_ui_updates_during_transition_period',
            'optimization': 'temporary_fallback_to_traditional_notification',
          },
        );
        // 🔧 临时回退到传统通知，确保UI更新
        throttledNotifyListeners();
      }
    } catch (e) {
      EditPageLogger.controllerError(
        '智能通知发生异常，回退到传统通知',
        data: {
          'changeType': changeType,
          'operation': operation ?? 'unknown',
          'error': e.toString(),
          'reason': 'ensure_ui_updates_during_exception',
          'optimization': 'temporary_exception_fallback',
        },
      );
      // 🔧 临时恢复异常时的回退机制
      try {
        throttledNotifyListeners();
      } catch (fallbackError) {
        EditPageLogger.controllerError(
          '回退通知也失败了',
          data: {
            'originalError': e.toString(),
            'fallbackError': fallbackError.toString(),
          },
        );
      }
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

  /// 检查所有UI组件是否都有监听器
  bool _hasAllUIComponentListeners(List<String>? affectedUIComponents) {
    if (affectedUIComponents == null || affectedUIComponents.isEmpty) {
      return true; // 没有UI组件需要通知，认为成功
    }

    try {
      // 检查每个UI组件是否都有监听器
      for (String component in affectedUIComponents) {
        bool hasListener = intelligentDispatcher.hasUIComponentListener(component);
        if (!hasListener) {
          EditPageLogger.performanceWarning(
            'UI组件没有注册监听器',
            data: {
              'component': component,
              'reason': 'ui_component_not_registered',
            },
          );
          return false;
        }
      }
      return true;
    } catch (e) {
      EditPageLogger.performanceWarning(
        '检查UI组件监听器时发生异常',
        data: {
          'error': e.toString(),
          'affectedUIComponents': affectedUIComponents,
        },
      );
      // 如果检查失败，保守起见，认为没有全部注册
      return false;
    }
  }
}
