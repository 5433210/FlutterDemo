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
        bool hasAllUIComponentListeners =
            _hasAllUIComponentListeners(affectedUIComponents);

        if (hasAllUIComponentListeners ||
            (affectedUIComponents?.isEmpty ?? true)) {
          dispatchSuccessful = true;
          // 成功使用智能分发，不需要详细日志
        } else {
          dispatchSuccessful = false;
          EditPageLogger.performanceWarning('部分UI组件未注册监听器', data: {
            'changeType': changeType,
            'reason': 'missing_ui_component_listeners',
          });
        }
      } catch (e) {
        // 智能分发器调用失败，使用回退机制
        dispatchSuccessful = false;
      }

      // 使用回退机制确保UI更新
      if (!dispatchSuccessful) {
        throttledNotifyListeners();
      }
    } catch (e) {
      EditPageLogger.controllerError('智能通知发生异常', error: e);
      // 异常时使用回退机制
      try {
        throttledNotifyListeners();
      } catch (fallbackError) {
        EditPageLogger.controllerError('回退通知失败', error: fallbackError);
      }
    }
  }

  /// 节流通知方法 - 由实现类提供
  void throttledNotifyListeners(
      {Duration delay = const Duration(milliseconds: 16)});

  /// 检查所有UI组件是否都有监听器
  bool _hasAllUIComponentListeners(List<String>? affectedUIComponents) {
    if (affectedUIComponents == null || affectedUIComponents.isEmpty) {
      return true; // 没有UI组件需要通知，认为成功
    }

    try {
      // 检查每个UI组件是否都有监听器
      for (String component in affectedUIComponents) {
        bool hasListener =
            intelligentDispatcher.hasUIComponentListener(component);
        if (!hasListener) {
          return false;
        }
      }
      return true;
    } catch (e) {
      // 检查失败，保守起见，认为没有全部注册
      return false;
    }
  }
}
