import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

/// 详情页徽章小部件
class DetailBadge extends StatelessWidget {
  /// 徽章文本
  final String text;

  /// 徽章颜色
  final Color? color;

  /// 徽章文本颜色
  final Color? textColor;

  const DetailBadge({
    super.key,
    required this.text,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor ?? theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

/// 详情页通用工具栏，参考浏览页工具栏样式
class DetailToolbar extends StatelessWidget {
  /// 主标题
  final String title;

  /// 副标题/描述文本
  final String? subtitle;

  /// 标题前的图标
  final IconData? leadingIcon;

  /// 标题右侧的徽章内容
  final Widget? badge;

  /// 右侧操作按钮
  final List<Widget> actions;

  /// 底部边框颜色
  final Color? borderColor;

  /// 背景颜色
  final Color? backgroundColor;

  const DetailToolbar({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.badge,
    this.actions = const [],
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: borderColor ?? theme.dividerColor.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 标题区域
          Expanded(
            child: Row(
              children: [
                // 前导图标
                if (leadingIcon != null) ...[
                  Icon(
                    leadingIcon,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSizes.spacingSmall),
                ],

                // 标题和副标题
                Expanded(
                  child: subtitle != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      : Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),

                // 徽章
                if (badge != null) ...[
                  const SizedBox(width: AppSizes.spacingSmall),
                  badge!,
                ],
              ],
            ),
          ),

          // 操作按钮
          ...actions,
        ],
      ),
    );
  }
}

/// 详情页工具栏操作按钮
class DetailToolbarAction extends StatelessWidget {
  /// 按钮图标
  final IconData icon;

  /// 提示文本
  final String? tooltip;

  /// 点击事件
  final VoidCallback? onPressed;

  /// 是否禁用
  final bool disabled;

  /// 是否使用强调色
  final bool primary;

  const DetailToolbarAction({
    super.key,
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.disabled = false,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final buttonColor = disabled
        ? theme.colorScheme.onSurface.withOpacity(0.38)
        : primary
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip ?? '',
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: disabled ? null : onPressed,
        color: buttonColor,
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(8),
          minimumSize: const Size(40, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
