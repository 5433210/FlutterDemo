import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
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
    final String defaultMessage = _getDefaultMessage(context);

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

  String _getDefaultMessage(BuildContext context) {
    switch (type) {
      case EmptyStateType.noWorks:
        return AppLocalizations.of(context).emptyStateNoWorks;
      case EmptyStateType.noCharacters:
        return AppLocalizations.of(context).emptyStateNoCharacters;
      case EmptyStateType.noPractices:
        return AppLocalizations.of(context).emptyStateNoPractices;
      case EmptyStateType.noResults:
        return AppLocalizations.of(context).emptyStateNoResults;
      case EmptyStateType.noSelection:
        return AppLocalizations.of(context).emptyStateNoSelection;
      case EmptyStateType.error:
        return AppLocalizations.of(context).emptyStateError;
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
