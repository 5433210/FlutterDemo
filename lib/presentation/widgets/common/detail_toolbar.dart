import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_sizes.dart';

class DetailBadge {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;

  const DetailBadge({
    required this.text,
    this.backgroundColor,
    this.textColor,
  });
}

class DetailToolbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData? leadingIcon;
  final String? subtitle;
  final DetailBadge? badge;
  final List<DetailToolbarAction> actions;
  final VoidCallback? onBack;

  const DetailToolbar({
    super.key,
    required this.title,
    this.leadingIcon,
    this.subtitle,
    this.badge,
    this.actions = const [],
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack ?? () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon!,
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: AppSizes.s),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s,
                vertical: AppSizes.xxs,
              ),
              decoration: BoxDecoration(
                color: badge!.backgroundColor ?? AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!.text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: badge!.textColor ?? Colors.white,
                    ),
              ),
            ),
        ],
      ),
      actions: actions.map((action) {
        return IconButton(
          icon: Icon(
            action.icon,
            color: action.color,
          ),
          tooltip: action.tooltip,
          onPressed: action.onPressed,
        );
      }).toList(),
    );
  }
}

class DetailToolbarAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;
  final bool primary;

  const DetailToolbarAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.primary = false,
  });
}
