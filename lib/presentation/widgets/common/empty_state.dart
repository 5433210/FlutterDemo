import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

class EmptyState extends StatelessWidget {
  final EmptyStateType type;
  final String? message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? customContent;

  const EmptyState({
    super.key,
    this.type = EmptyStateType.noResults,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.customContent,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingLarge),
        child: customContent ?? _buildDefaultContent(context),
      ),
    );
  }

  Widget _buildDefaultContent(BuildContext context) {
    final theme = Theme.of(context);

    // 根据类型设置默认图标和消息
    final IconData defaultIcon = _getDefaultIcon();
    final String defaultMessage = _getDefaultMessage();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon ?? defaultIcon,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        Text(
          message ?? defaultMessage,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSizes.spacingLarge),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionLabel!),
          ),
        ],
      ],
    );
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case EmptyStateType.noWorks:
        return Icons.collections_outlined;
      case EmptyStateType.noCharacters:
        return Icons.text_fields_outlined;
      case EmptyStateType.noPractices:
        return Icons.edit_note_outlined;
      case EmptyStateType.noResults:
        return Icons.search_off_outlined;
      case EmptyStateType.noSelection:
        return Icons.select_all_outlined;
      case EmptyStateType.error:
        return Icons.error_outline;
      case EmptyStateType.custom:
        return Icons.info_outline;
    }
  }

  String _getDefaultMessage() {
    switch (type) {
      case EmptyStateType.noWorks:
        return '没有作品\n点击添加按钮导入作品';
      case EmptyStateType.noCharacters:
        return '没有字形\n从作品中提取字形后可在此查看';
      case EmptyStateType.noPractices:
        return '没有练习\n点击添加按钮创建新练习';
      case EmptyStateType.noResults:
        return '没有找到匹配的结果\n尝试更改搜索条件';
      case EmptyStateType.noSelection:
        return '未选择任何项目\n点击项目以选择';
      case EmptyStateType.error:
        return '加载失败\n请稍后再试';
      case EmptyStateType.custom:
        return '';
    }
  }
}

enum EmptyStateType {
  noWorks,
  noCharacters,
  noPractices,
  noResults,
  noSelection,
  error,
  custom,
}
