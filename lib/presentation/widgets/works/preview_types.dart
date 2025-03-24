import 'package:flutter/material.dart';

/// 预览模式枚举
enum PreviewMode {
  /// 导入模式
  import,

  /// 编辑模式
  edit,

  /// 查看模式
  view,

  /// 提取模式
  extract,
}

/// 工具栏操作项
class ToolbarAction {
  /// 图标
  final IconData icon;

  /// 标题
  final String? tooltip;

  /// 是否可用
  final bool enabled;

  /// 操作回调
  final VoidCallback? onPressed;

  /// 位置
  final ToolbarActionPlacement placement;

  const ToolbarAction({
    required this.icon,
    this.tooltip,
    this.enabled = true,
    this.onPressed,
    this.placement = ToolbarActionPlacement.left,
  });

  /// 创建一个新的 ToolbarAction 实例，可选择性地覆盖现有属性
  ToolbarAction copyWith({
    IconData? icon,
    String? tooltip,
    bool? enabled,
    VoidCallback? onPressed,
    ToolbarActionPlacement? placement,
  }) {
    return ToolbarAction(
      icon: icon ?? this.icon,
      tooltip: tooltip ?? this.tooltip,
      enabled: enabled ?? this.enabled,
      onPressed: onPressed ?? this.onPressed,
      placement: placement ?? this.placement,
    );
  }
}

/// 工具栏操作位置枚举
enum ToolbarActionPlacement {
  /// 左侧
  left,

  /// 右侧
  right,

  /// 居中
  center,
}
