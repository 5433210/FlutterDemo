/// Canvas工具栏 - 工具按钮组件
///
/// 职责：
/// 1. 渲染单个工具按钮
/// 2. 处理点击和悬停状态
/// 3. 支持不同的样式
/// 4. 提供无障碍支持
library;

import 'package:flutter/material.dart';

import '../tool_state_manager.dart';

/// 工具栏样式枚举
enum ToolbarStyle {
  /// 现代样式
  modern,

  /// 经典样式
  classic,

  /// 紧凑样式
  compact,
}

/// 工具按钮组件
class ToolButton extends StatefulWidget {
  /// 工具类型
  final ToolType toolType;

  /// 是否选中
  final bool isSelected;

  /// 点击回调
  final VoidCallback onPressed;

  /// 工具栏样式
  final ToolbarStyle style;

  /// 是否启用
  final bool enabled;

  /// 自定义图标
  final IconData? customIcon;

  /// 自定义标签
  final String? customLabel;

  /// 工具提示
  final String? tooltip;

  const ToolButton({
    super.key,
    required this.toolType,
    required this.isSelected,
    required this.onPressed,
    required this.style,
    this.enabled = true,
    this.customIcon,
    this.customLabel,
    this.tooltip,
  });

  @override
  State<ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<ToolButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData = widget.customIcon ?? _getToolIcon();
    final label = widget.customLabel ?? _getToolLabel();
    final tooltipText = widget.tooltip ?? _getToolTooltip();

    return Tooltip(
      message: tooltipText,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) {
            setState(() => _isPressed = true);
            _animationController.forward();
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _animationController.reverse();
            if (widget.enabled) {
              widget.onPressed();
            }
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
            _animationController.reverse();
          },
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPressed ? _scaleAnimation.value : 1.0,
                child: _buildButtonContent(theme, iconData, label),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  Widget _buildButtonContent(ThemeData theme, IconData iconData, String label) {
    switch (widget.style) {
      case ToolbarStyle.modern:
        return _buildModernButton(theme, iconData, label);
      case ToolbarStyle.classic:
        return _buildClassicButton(theme, iconData, label);
      case ToolbarStyle.compact:
        return _buildCompactButton(theme, iconData, label);
    }
  }

  Widget _buildClassicButton(ThemeData theme, IconData iconData, String label) {
    final colorScheme = theme.colorScheme;

    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: _getBackgroundColor(colorScheme),
        border: Border.all(
          color: _getBorderColor(colorScheme),
          width: 1,
        ),
      ),
      child: Icon(
        iconData,
        size: 20,
        color: _getIconColor(colorScheme),
      ),
    );
  }

  Widget _buildCompactButton(ThemeData theme, IconData iconData, String label) {
    final colorScheme = theme.colorScheme;

    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: _getBackgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(6),
        border: widget.isSelected
            ? Border.all(
                color: colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: Icon(
        iconData,
        size: 16,
        color: _getIconColor(colorScheme),
      ),
    );
  }

  Widget _buildModernButton(ThemeData theme, IconData iconData, String label) {
    final colorScheme = theme.colorScheme;

    return Container(
      width: 56,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: _getBackgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(colorScheme),
          width: widget.isSelected ? 2 : 1,
        ),
        boxShadow: _isHovered || widget.isSelected
            ? [
                BoxShadow(
                  color: colorScheme.primary.withAlpha(51), // 0.2 opacity
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 20,
            color: _getIconColor(colorScheme),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: _getTextColor(colorScheme),
              fontSize: 8,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    if (!widget.enabled) {
      return colorScheme.surfaceContainerHighest;
    }

    if (widget.isSelected) {
      return colorScheme.primaryContainer;
    }

    if (_isHovered) {
      return colorScheme.surfaceContainerHigh;
    }

    return colorScheme.surfaceContainer;
  }

  Color _getBorderColor(ColorScheme colorScheme) {
    if (!widget.enabled) {
      return colorScheme.outline;
    }

    if (widget.isSelected) {
      return colorScheme.primary;
    }

    if (_isHovered) {
      return colorScheme.outline;
    }

    return colorScheme.outlineVariant;
  }

  Color _getIconColor(ColorScheme colorScheme) {
    if (!widget.enabled) {
      return colorScheme.onSurface.withAlpha(97); // 0.38 opacity
    }

    if (widget.isSelected) {
      return colorScheme.onPrimaryContainer;
    }

    return colorScheme.onSurface;
  }

  Color _getTextColor(ColorScheme colorScheme) {
    if (!widget.enabled) {
      return colorScheme.onSurface.withAlpha(97); // 0.38 opacity
    }

    if (widget.isSelected) {
      return colorScheme.onPrimaryContainer;
    }

    return colorScheme.onSurface;
  }

  IconData _getToolIcon() {
    switch (widget.toolType) {
      case ToolType.select:
        return Icons.select_all;
      case ToolType.text:
        return Icons.text_fields;
      case ToolType.image:
        return Icons.image;
      case ToolType.collection:
        return Icons.grid_on;
      case ToolType.move:
        return Icons.open_with;
      case ToolType.resize:
        return Icons.crop_free;
      case ToolType.rotate:
        return Icons.rotate_90_degrees_ccw;
      case ToolType.pan:
        return Icons.pan_tool;
      case ToolType.zoom:
        return Icons.zoom_in;
    }
  }

  String _getToolLabel() {
    switch (widget.toolType) {
      case ToolType.select:
        return '选择';
      case ToolType.text:
        return '文本';
      case ToolType.image:
        return '图像';
      case ToolType.collection:
        return '集字';
      case ToolType.move:
        return '移动';
      case ToolType.resize:
        return '缩放';
      case ToolType.rotate:
        return '旋转';
      case ToolType.pan:
        return '平移';
      case ToolType.zoom:
        return '缩放';
    }
  }

  String _getToolTooltip() {
    switch (widget.toolType) {
      case ToolType.select:
        return '选择工具 (V)';
      case ToolType.text:
        return '文本工具 (T)';
      case ToolType.image:
        return '图像工具 (I)';
      case ToolType.collection:
        return '集字工具 (C)';
      case ToolType.move:
        return '移动工具 (M)';
      case ToolType.resize:
        return '缩放工具 (R)';
      case ToolType.rotate:
        return '旋转工具 (O)';
      case ToolType.pan:
        return '平移工具 (P)';
      case ToolType.zoom:
        return '缩放工具 (Z)';
    }
  }
}
