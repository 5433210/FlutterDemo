import 'package:flutter/material.dart';

/// 激活特定标签页的Intent
class ActivateTabIntent extends Intent {
  final int index;
  const ActivateTabIntent(this.index);
}

/// 切换导航栏展开/收起状态的Intent
class ToggleNavigationIntent extends Intent {
  const ToggleNavigationIntent();
}
