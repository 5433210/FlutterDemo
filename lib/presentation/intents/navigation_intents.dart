import 'package:flutter/material.dart';

/// 激活特定标签页的Intent
class ActivateTabIntent extends Intent {
  final int index;

  const ActivateTabIntent(this.index);
}

/// 清除导航历史的Intent
class ClearNavigationHistoryIntent extends Intent {
  const ClearNavigationHistoryIntent();
}

/// 返回上一页的Intent
class NavigateBackIntent extends Intent {
  const NavigateBackIntent();
}

/// 在指定的功能区内导航的Intent
class NavigateToRouteIntent extends Intent {
  final String routeName;
  final Object? arguments;
  final bool replace;

  const NavigateToRouteIntent({
    required this.routeName,
    this.arguments,
    this.replace = false,
  });
}

/// 保存导航状态的Intent
class SaveNavigationStateIntent extends Intent {
  const SaveNavigationStateIntent();
}

/// 切换导航栏展开/收起状态的Intent
class ToggleNavigationIntent extends Intent {
  const ToggleNavigationIntent();
}
