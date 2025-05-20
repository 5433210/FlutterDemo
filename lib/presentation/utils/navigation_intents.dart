import 'package:flutter/material.dart';

/// 切换标签页的Intent
class ActivateTabIntent extends Intent {
  final int index;

  const ActivateTabIntent(this.index);
}

/// 切换侧边栏展开/收起状态的Intent
class ToggleNavigationIntent extends Intent {
  const ToggleNavigationIntent();
}
