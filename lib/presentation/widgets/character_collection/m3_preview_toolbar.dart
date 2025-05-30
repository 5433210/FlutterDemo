import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';
import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/tool_mode_provider.dart';
import 'm3_delete_confirmation_dialog.dart';

/// 预览工具栏
class M3PreviewToolbar extends ConsumerWidget {
  const M3PreviewToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final toolMode = ref.watch(toolModeProvider);
    final hasSelection = ref
        .watch(characterCollectionProvider)
        .regions
        .where((e) => e.isSelected)
        .isNotEmpty;

    return Material(
      color: colorScheme.surface,
      elevation: 1,
      shadowColor: colorScheme.shadow,
      child: Container(
        height: AppSizes.appBarHeight,
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tool buttons group
              _ToolButton(
                icon: Icons.pan_tool,
                tooltip: l10n.characterCollectionToolPan,
                isSelected: toolMode == Tool.pan,
                onPressed: () =>
                    ref.read(toolModeProvider.notifier).setMode(Tool.pan),
              ),
              const SizedBox(width: 4),
              _ToolButton(
                icon: Icons.crop_square,
                tooltip: l10n.characterCollectionToolSelect,
                isSelected: toolMode == Tool.select,
                onPressed: () =>
                    ref.read(toolModeProvider.notifier).setMode(Tool.select),
              ),
              const SizedBox(width: 16),

              // Divider
              const VerticalDivider(
                thickness: 1,
              ),
              const SizedBox(width: 8),

              // Delete button
              _ToolButton(
                icon: Icons.delete,
                tooltip: l10n.characterCollectionToolDelete,
                isEnabled: hasSelection,
                onPressed: hasSelection
                    ? () async {
                        final selectedIds = ref
                            .read(characterCollectionProvider)
                            .regions
                            .where((e) => e.isSelected)
                            .map((e) => e.id)
                            .toList();

                        // Check if there are selected regions
                        if (selectedIds.isEmpty) {
                          return;
                        }

                        // Use M3DeleteConfirmationDialog to show confirmation dialog
                        bool shouldDelete =
                            await M3DeleteConfirmationDialog.show(
                          context,
                          count: selectedIds.length,
                          isBatch: selectedIds.length > 1,
                        );

                        if (shouldDelete) {
                          // Delete operation also removes image files from the file system
                          ref
                              .read(characterCollectionProvider.notifier)
                              .deleteBatchRegions(selectedIds);
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tool button component
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    this.isSelected = false,
    this.isEnabled = true,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: isEnabled ? onPressed : null,
        style: IconButton.styleFrom(
          backgroundColor: isSelected ? colorScheme.primaryContainer : null,
          foregroundColor: isSelected
              ? colorScheme.primary
              : isEnabled
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
