/// Canvas工具栏 - 工具组组件
///
/// 职责：
/// 1. 将相关工具按钮组织在一起
/// 2. 提供可选的组标题
/// 3. 支持水平和垂直布局
/// 4. 处理工具组的展开/折叠
library;

import 'package:flutter/material.dart';

/// 可折叠的工具组
class CollapsibleToolGroup extends StatelessWidget {
  /// 工具组标题
  final String title;

  /// 工具按钮列表
  final List<Widget> children;

  /// 布局方向
  final Axis direction;

  /// 初始展开状态
  final bool initiallyExpanded;

  /// 工具组间距
  final double spacing;

  const CollapsibleToolGroup({
    super.key,
    required this.title,
    required this.children,
    required this.direction,
    this.initiallyExpanded = true,
    this.spacing = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return ToolGroup(
      title: title,
      direction: direction,
      showTitle: true,
      collapsible: true,
      initiallyExpanded: initiallyExpanded,
      spacing: spacing,
      children: children,
    );
  }
}

/// 带标题的工具组
class TitledToolGroup extends StatelessWidget {
  /// 工具组标题
  final String title;

  /// 工具按钮列表
  final List<Widget> children;

  /// 布局方向
  final Axis direction;

  /// 工具组间距
  final double spacing;

  /// 最大行数/列数
  final int? maxCrossAxisCount;

  const TitledToolGroup({
    super.key,
    required this.title,
    required this.children,
    required this.direction,
    this.spacing = 4.0,
    this.maxCrossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    return ToolGroup(
      title: title,
      direction: direction,
      showTitle: true,
      collapsible: false,
      spacing: spacing,
      maxCrossAxisCount: maxCrossAxisCount,
      children: children,
    );
  }
}

/// 工具组组件
class ToolGroup extends StatefulWidget {
  /// 工具组标题
  final String title;

  /// 工具按钮列表
  final List<Widget> children;

  /// 布局方向
  final Axis direction;

  /// 是否显示标题
  final bool showTitle;

  /// 是否可折叠
  final bool collapsible;

  /// 初始展开状态
  final bool initiallyExpanded;

  /// 工具组间距
  final double spacing;

  /// 最大行数/列数（用于换行）
  final int? maxCrossAxisCount;

  const ToolGroup({
    super.key,
    required this.title,
    required this.children,
    required this.direction,
    this.showTitle = false,
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.spacing = 4.0,
    this.maxCrossAxisCount,
  });

  @override
  State<ToolGroup> createState() => _ToolGroupState();
}

class _ToolGroupState extends State<ToolGroup>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  Widget build(BuildContext context) {
    if (widget.direction == Axis.horizontal) {
      return _buildHorizontalGroup();
    } else {
      return _buildVerticalGroup();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  Widget _buildGroupContent() {
    if (widget.children.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.direction == Axis.horizontal) {
      if (widget.maxCrossAxisCount != null) {
        return _buildWrappedHorizontalContent();
      } else {
        return _buildSingleRowContent();
      }
    } else {
      if (widget.maxCrossAxisCount != null) {
        return _buildWrappedVerticalContent();
      } else {
        return _buildSingleColumnContent();
      }
    }
  }

  Widget _buildGroupTitle() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.collapsible) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _toggleExpanded,
              child: AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _expandAnimation.value *
                        1.5708, // 90 degrees in radians
                    child: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHorizontalGroup() {
    final content = _buildGroupContent();

    if (!widget.showTitle && !widget.collapsible) {
      return content;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showTitle) _buildGroupTitle(),
        if (widget.collapsible)
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  heightFactor: _expandAnimation.value,
                  child: content,
                ),
              );
            },
          )
        else
          content,
      ],
    );
  }

  Widget _buildSingleColumnContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _intersperse(
        widget.children,
        SizedBox(height: widget.spacing),
      ).toList(),
    );
  }

  Widget _buildSingleRowContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _intersperse(
        widget.children,
        SizedBox(width: widget.spacing),
      ).toList(),
    );
  }

  Widget _buildVerticalGroup() {
    final content = _buildGroupContent();

    if (!widget.showTitle && !widget.collapsible) {
      return content;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showTitle) _buildGroupTitle(),
        if (widget.collapsible)
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  heightFactor: _expandAnimation.value,
                  child: content,
                ),
              );
            },
          )
        else
          content,
      ],
    );
  }

  Widget _buildWrappedHorizontalContent() {
    return Wrap(
      direction: Axis.horizontal,
      spacing: widget.spacing,
      runSpacing: widget.spacing,
      children: widget.children,
    );
  }

  Widget _buildWrappedVerticalContent() {
    return Wrap(
      direction: Axis.vertical,
      spacing: widget.spacing,
      runSpacing: widget.spacing,
      children: widget.children,
    );
  }

  /// 在列表项之间插入分隔符
  Iterable<T> _intersperse<T>(Iterable<T> iterable, T separator) sync* {
    final iterator = iterable.iterator;
    if (iterator.moveNext()) {
      yield iterator.current;
      while (iterator.moveNext()) {
        yield separator;
        yield iterator.current;
      }
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
}
