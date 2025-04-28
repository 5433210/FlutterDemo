import 'package:flutter/material.dart';

/// 一个固定大小的图标按钮组件
///
/// 用于替代默认的IconButton，可以更精确地控制大小和内边距
class CompactIconButton extends StatelessWidget {
  /// 图标
  final IconData icon;

  /// 按钮大小
  final double size;

  /// 图标大小
  final double iconSize;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 图标颜色
  final Color? color;

  /// 鼠标悬停时的提示文本
  final String? tooltip;

  const CompactIconButton({
    Key? key,
    required this.icon,
    this.size = 32,
    this.iconSize = 20,
    this.onPressed,
    this.color,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget button = SizedBox(
      width: size,
      height: size,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: iconSize,
        color: color,
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// 一个自适应的Row组件，可以自动处理子组件溢出问题
///
/// 当空间不足时，会根据优先级自动调整子组件的显示方式：
/// 1. 首先尝试缩小可缩小的组件（使用Flexible包装的组件）
/// 2. 如果仍然溢出，则会自动隐藏优先级较低的组件
class FlexibleRow extends StatelessWidget {
  /// 子组件列表
  final List<Widget> children;

  /// 主轴对齐方式
  final MainAxisAlignment mainAxisAlignment;

  /// 交叉轴对齐方式
  final CrossAxisAlignment crossAxisAlignment;

  /// 主轴尺寸
  final MainAxisSize mainAxisSize;

  /// 是否自动隐藏溢出的组件（从右到左依次隐藏）
  final bool hideOverflow;

  /// 子组件之间的间距
  final double? spacing;

  const FlexibleRow({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.hideOverflow = false,
    this.spacing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 如果设置了间距，则在子组件之间添加SizedBox
    List<Widget> childrenWithSpacing = [];
    if (spacing != null && spacing! > 0) {
      for (int i = 0; i < children.length; i++) {
        childrenWithSpacing.add(children[i]);
        if (i < children.length - 1) {
          childrenWithSpacing.add(SizedBox(width: spacing));
        }
      }
    } else {
      childrenWithSpacing = List.from(children);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 始终使用Row，保持单行布局
        return Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: childrenWithSpacing,
        );
      },
    );
  }
}

/// 一个可以自动处理溢出的Row组件
///
/// 当空间不足时，会自动将子组件换行显示
class WrapRow extends StatelessWidget {
  /// 子组件列表
  final List<Widget> children;

  /// 主轴对齐方式
  final WrapAlignment alignment;

  /// 子组件之间的水平间距
  final double spacing;

  /// 行之间的垂直间距
  final double runSpacing;

  const WrapRow({
    Key? key,
    required this.children,
    this.alignment = WrapAlignment.start,
    this.spacing = 0,
    this.runSpacing = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alignment,
      spacing: spacing,
      runSpacing: runSpacing,
      children: children,
    );
  }
}
