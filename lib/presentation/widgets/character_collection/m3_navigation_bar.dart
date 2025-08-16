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
        // 删除按钮
        _buildDeleteButton(context, ref, collectionState),
        
        // 分隔线
        Container(
          height: 24,
          width: 1,
          color: colorScheme.outline.withValues(alpha: 0.3),
          margin: const EdgeInsets.symmetric(horizontal: 8),
        ),
        
        // 组合工具按钮（多选/采集）
        _buildCombinedToolButton(context, ref, toolMode),
        
        const SizedBox(width: 16),
        
        // 面板切换按钮，添加右边距
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildPanelToggleButton(context, ref, panelMode),
        ),
      ],
    );
  }

  /// 构建组合工具按钮 - 改为切换控件样式
  Widget _buildCombinedToolButton(BuildContext context, WidgetRef ref, Tool toolMode) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    
    final bool isPanMode = toolMode == Tool.pan;

    return ToggleButtons(
      isSelected: [isPanMode, !isPanMode],
      onPressed: (index) {
        final newTool = index == 0 ? Tool.pan : Tool.select;
        ref.read(toolModeProvider.notifier).setMode(newTool);
      },
      borderRadius: BorderRadius.circular(8),
      constraints: const BoxConstraints(minHeight: 32, minWidth: 50),
      children: [
        Tooltip(
          message: l10n.characterCollectionToolPan,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pan_tool, size: 16),
              const SizedBox(width: 4),
              Text('多选', style: textTheme.bodySmall),
            ],
          ),
        ),
        Tooltip(
          message: l10n.characterCollectionToolBox,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.crop_square, size: 16),
              const SizedBox(width: 4),
              Text('采集', style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
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
                    .cast<String>()
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

  /// 构建面板切换按钮 - 改为切换控件样式
  Widget _buildPanelToggleButton(BuildContext context, WidgetRef ref, PanelMode panelMode) {
    final textTheme = Theme.of(context).textTheme;
    
    final bool isPreviewMode = panelMode == PanelMode.preview;

    return ToggleButtons(
      isSelected: [isPreviewMode, !isPreviewMode],
      onPressed: (index) {
        ref.read(panelModeProvider.notifier).toggleMode();
      },
      borderRadius: BorderRadius.circular(8),
      constraints: const BoxConstraints(minHeight: 32, minWidth: 50),
      children: [
        Tooltip(
          message: '字符预览',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.preview, size: 16),
              const SizedBox(width: 4),
              Text('预览', style: textTheme.bodySmall),
            ],
          ),
        ),
        Tooltip(
          message: '采集结果',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.view_list, size: 16),
              const SizedBox(width: 4),
              Text('结果', style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  // 帮助相关方法已移除，因为帮助按钮已屏蔽
}
