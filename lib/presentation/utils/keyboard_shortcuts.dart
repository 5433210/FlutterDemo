import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../intents/navigation_intents.dart';

/// 管理应用程序级别的快捷键
class KeyboardShortcuts {
  /// 获取全局导航 Action 映射
  static Map<Type, Action<Intent>> getNavigationActions({
    required ValueChanged<int> onSectionSelected,
    required VoidCallback onToggleNavigation,
  }) {
    return <Type, Action<Intent>>{
      ActivateTabIntent: CallbackAction<ActivateTabIntent>(
        onInvoke: (intent) {
          onSectionSelected(intent.index);
          return null;
        },
      ),
      ToggleNavigationIntent: CallbackAction<ToggleNavigationIntent>(
        onInvoke: (intent) {
          onToggleNavigation();
          return null;
        },
      ),
    };
  }

  /// 获取全局导航快捷键映射
  static Map<LogicalKeySet, Intent> getNavigationShortcuts() {
    return <LogicalKeySet, Intent>{
      // 功能区导航快捷键
      LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit1):
          const ActivateTabIntent(0),
      LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit2):
          const ActivateTabIntent(1),
      LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit3):
          const ActivateTabIntent(2),
      LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit4):
          const ActivateTabIntent(3),
      LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit5):
          const ActivateTabIntent(4),

      // 侧边栏展开/收起快捷键
      LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyN):
          const ToggleNavigationIntent(),
    };
  }

  /// 创建一个专门用于导航的快捷键处理包装组件
  static Widget wrapWithNavigationShortcuts({
    required Widget child,
    required ValueChanged<int> onSectionSelected,
    required VoidCallback onToggleNavigation,
  }) {
    return Shortcuts(
      shortcuts: getNavigationShortcuts(),
      child: Actions(
        actions: getNavigationActions(
          onSectionSelected: onSectionSelected,
          onToggleNavigation: onToggleNavigation,
        ),
        child: child,
      ),
    );
  }
}
