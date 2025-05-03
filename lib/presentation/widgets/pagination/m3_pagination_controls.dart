import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';

/// Material 3 pagination controls
class M3PaginationControls extends StatelessWidget {
  /// Current page number
  final int currentPage;

  /// Page size
  final int pageSize;

  /// Total number of items
  final int totalItems;

  /// Callback when page changes
  final Function(int) onPageChanged;

  /// Callback when page size changes
  final Function(int)? onPageSizeChanged;

  /// Available page sizes
  final List<int> availablePageSizes;

  const M3PaginationControls({
    super.key,
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.onPageChanged,
    this.onPageSizeChanged,
    this.availablePageSizes = const [10, 20, 50, 100],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final totalPages = (totalItems / pageSize).ceil();

    return Container(
      width: double.infinity, // Make the container take full width
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Total count
          Text(
            l10n.workBrowseTotalItems('$totalItems'),
            style: theme.textTheme.bodyMedium,
          ),

          // Pagination
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
                tooltip: 'First Page',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 1
                    ? () => onPageChanged(currentPage - 1)
                    : null,
                tooltip: 'Previous Page',
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 40),
                alignment: Alignment.center,
                child: Text(
                  '$currentPage / $totalPages',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages
                    ? () => onPageChanged(currentPage + 1)
                    : null,
                tooltip: 'Next Page',
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: currentPage < totalPages
                    ? () => onPageChanged(totalPages)
                    : null,
                tooltip: 'Last Page',
              ),
            ],
          ),

          // Page size selector (only if onPageSizeChanged is provided)
          if (onPageSizeChanged != null)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(4),
              ),
              child: PopupMenuButton<int>(
                initialValue: pageSize,
                onSelected: onPageSizeChanged,
                itemBuilder: (context) => availablePageSizes
                    .map((size) => PopupMenuItem<int>(
                          value: size,
                          height: 36,
                          child: Text(
                            l10n.workBrowseItemsPerPage('$size'),
                          ),
                        ))
                    .toList(),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.workBrowseItemsPerPage('$pageSize'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
