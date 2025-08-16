import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';
import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/panel_mode_provider.dart';
import '../../providers/character/tool_mode_provider.dart';
import '../common/m3_page_navigation_bar.dart';
import 'm3_delete_confirmation_dialog.dart';

class M3NavigationBar extends ConsumerWidget implements PreferredSizeWidget {
  final String workId;
  final VoidCallback onBack;
  final VoidCallback? onHelp;

  const M3NavigationBar({
    super.key,
    required this.workId,
    required this.onBack,
    this.onHelp,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final collectionState = ref.watch(characterCollectionProvider);
    final toolMode = ref.watch(toolModeProvider);
    final panelMode = ref.watch(panelModeProvider);

    // Calculate status text
    String statusText = '';
    if (collectionState.processing) {
      statusText = l10n.processing;
    } else if (collectionState.error != null) {
      statusText = l10n.error(collectionState.error!);
    }

    return M3PageNavigationBar(
      title: l10n.characterCollectionTitle,
      onBackPressed: onBack,
      titleActions: statusText.isNotEmpty
          ? [
              const SizedBox(width: AppSizes.m),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s, vertical: AppSizes.xs),
                decoration: BoxDecoration(
                  color: collectionState.error != null
                      ? colorScheme.error.withValues(alpha: 0.1)
                      : colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.m),
                ),
                child: Text(
                  statusText,
                  style: textTheme.bodyMedium?.copyWith(
                    color: collectionState.error != null
                        ? colorScheme.error
                        : colorScheme.primary,
                  ),
                ),
              ),
            ]
          : null,
      actions: [
        // 组合工具按钮（移动/框选）
        _buildCombinedToolButton(context, ref, toolMode),
        
        // 分隔线
        Container(
          height: 24,
          width: 1,
          color: colorScheme.outline.withValues(alpha: 0.3),
          margin: const EdgeInsets.symmetric(horizontal: 8),
        ),
        
        // 删除按钮
        _buildDeleteButton(context, ref, collectionState),
        
        const SizedBox(width: 12),
        
        // 面板切换按钮
        _buildPanelToggleButton(context, ref, panelMode),
      ],
    );
  }

  /// 构建组合工具按钮
  Widget _buildCombinedToolButton(BuildContext context, WidgetRef ref, Tool toolMode) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final bool isPanMode = toolMode == Tool.pan;
    final String tooltipText = isPanMode 
        ? l10n.characterCollectionToolPan 
        : l10n.characterCollectionToolBox;
    final IconData iconData = isPanMode ? Icons.pan_tool : Icons.crop_square;
    final String labelText = isPanMode ? '移动' : '框选';

    return Tooltip(
      message: tooltipText,
      child: Material(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // 切换工具模式
            final newTool = isPanMode ? Tool.select : Tool.pan;
            ref.read(toolModeProvider.notifier).setMode(newTool);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  iconData,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  labelText,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.swap_horiz,
                  size: 14,
                  color: colorScheme.primary.withAlpha(180),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建删除按钮
  Widget _buildDeleteButton(BuildContext context, WidgetRef ref, dynamic collectionState) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    final hasSelection = collectionState.regions
        .where((CharacterRegion e) => e.isSelected)
        .isNotEmpty;

    return Tooltip(
      message: l10n.deleteSelected,
      child: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: hasSelection
            ? () async {
                final selectedIds = collectionState.regions
                    .where((CharacterRegion e) => e.isSelected)
                    .map((e) => e.id)
                    .toList();

                if (selectedIds.isEmpty) return;

                bool shouldDelete = await M3DeleteConfirmationDialog.show(
                  context,
                  count: selectedIds.length,
                  isBatch: selectedIds.length > 1,
                );

                if (shouldDelete) {
                  ref
                      .read(characterCollectionProvider.notifier)
                      .deleteBatchRegions(selectedIds);
                }
              }
            : null,
        style: IconButton.styleFrom(
          foregroundColor: hasSelection
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// 构建面板切换按钮
  Widget _buildPanelToggleButton(BuildContext context, WidgetRef ref, PanelMode panelMode) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final bool isPreviewMode = panelMode == PanelMode.preview;
    final String tooltipText = isPreviewMode 
        ? '切换到采集结果' 
        : '切换到字符预览';
    final IconData iconData = isPreviewMode ? Icons.view_list : Icons.preview;
    final String labelText = isPreviewMode ? '结果' : '预览';

    return Tooltip(
      message: tooltipText,
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ref.read(panelModeProvider.notifier).toggleMode();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  iconData,
                  size: 18,
                  color: colorScheme.onSurface,
                ),
                const SizedBox(width: 6),
                Text(
                  labelText,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 帮助相关方法已移除，因为帮助按钮已屏蔽
}
