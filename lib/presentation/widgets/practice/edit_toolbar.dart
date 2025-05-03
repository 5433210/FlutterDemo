import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';
import 'practice_edit_controller.dart';

/// 编辑工具栏
class EditToolbar extends StatelessWidget implements PreferredSizeWidget {
  final PracticeEditController controller;
  final bool gridVisible;
  final bool snapEnabled;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleSnap;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onGroupElements;
  final VoidCallback onUngroupElements;
  final VoidCallback onBringToFront;
  final VoidCallback onSendToBack;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;

  const EditToolbar({
    Key? key,
    required this.controller,
    required this.gridVisible,
    required this.snapEnabled,
    required this.onToggleGrid,
    required this.onToggleSnap,
    required this.onCopy,
    required this.onPaste,
    required this.onGroupElements,
    required this.onUngroupElements,
    required this.onBringToFront,
    required this.onSendToBack,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasSelection = controller.state.selectedElementIds.isNotEmpty;
    final isMultiSelected = controller.state.selectedElementIds.length > 1;
    final hasSelectedGroup =
        hasSelection && !isMultiSelected && _isSelectedElementGroup();

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(
          vertical: AppSizes.xs, horizontal: AppSizes.s),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 编辑操作组
            _buildToolbarGroup(
              title: l10n.practiceEditEditOperations,
              children: [
                _buildToolbarButton(
                  context: context,
                  icon: Icons.copy,
                  tooltip: l10n.practiceEditCopy,
                  onPressed: hasSelection ? onCopy : null,
                ),
                _buildToolbarButton(
                  context: context,
                  icon: Icons.paste,
                  tooltip: l10n.practiceEditPaste,
                  onPressed: onPaste,
                ),
                _buildToolbarButton(
                  context: context,
                  icon: Icons.delete,
                  tooltip: l10n.practiceEditDelete,
                  onPressed: hasSelection ? onDelete : null,
                ),
                _buildToolbarButton(
                  context: context,
                  icon: Icons.group,
                  tooltip: l10n.practiceEditGroup,
                  onPressed: isMultiSelected ? onGroupElements : null,
                ),
                _buildToolbarButton(
                  context: context,
                  icon: Icons.format_shapes,
                  tooltip: l10n.practiceEditUngroup,
                  onPressed: hasSelectedGroup ? onUngroupElements : null,
                ),
              ],
            ),

            const SizedBox(width: AppSizes.s),
            const VerticalDivider(),
            const SizedBox(width: AppSizes.s),

            // 层级操作组
            _buildToolbarGroup(
              title: l10n.practiceEditLayerOperations,
              children: [
                _buildToolbarButton(
                  context: context,
                  icon: Icons.vertical_align_top,
                  tooltip: l10n.practiceEditBringToFront,
                  onPressed: hasSelection ? onBringToFront : null,
                ),
                _buildToolbarButton(
                  context: context,
                  icon: Icons.vertical_align_bottom,
                  tooltip: l10n.practiceEditSendToBack,
                  onPressed: hasSelection ? onSendToBack : null,
                ),
                _buildToolbarButton(
                  context: context,
                  icon: Icons.arrow_upward,
                  tooltip: l10n.practiceEditMoveUp,
                  onPressed: hasSelection ? onMoveUp : null,
                ),
                _buildToolbarButton(
                  context: context,
                  icon: Icons.arrow_downward,
                  tooltip: l10n.practiceEditMoveDown,
                  onPressed: hasSelection ? onMoveDown : null,
                ),
              ],
            ),

            const SizedBox(width: AppSizes.s),
            const VerticalDivider(),
            const SizedBox(width: AppSizes.s),

            // 辅助功能组
            _buildToolbarGroup(
              title: l10n.practiceEditHelperFunctions,
              children: [
                _buildToolbarButton(
                  context: context,
                  icon: gridVisible ? Icons.grid_on : Icons.grid_off,
                  tooltip: gridVisible
                      ? l10n.practiceEditHideGrid
                      : l10n.practiceEditShowGrid,
                  onPressed: onToggleGrid,
                  isActive: gridVisible,
                ),
                _buildToolbarButton(
                  context: context,
                  icon: Icons.format_line_spacing,
                  tooltip: snapEnabled
                      ? l10n.practiceEditDisableSnap
                      : l10n.practiceEditEnableSnap,
                  onPressed: onToggleSnap,
                  isActive: snapEnabled,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建工具栏按钮
  Widget _buildToolbarButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool isActive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive
              ? colorScheme.primary
              : onPressed == null
                  ? colorScheme.onSurface.withOpacity(0.38)
                  : null,
          size: 20,
        ),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }

  /// 构建工具栏分组
  Widget _buildToolbarGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 工具组标题
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: AppSizes.s),
        // 工具按钮组
        ...children,
      ],
    );
  }

  /// 检查选中的元素是否为组合元素
  bool _isSelectedElementGroup() {
    if (controller.state.selectedElementIds.isEmpty) return false;

    final id = controller.state.selectedElementIds.first;
    final element = controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == id,
      orElse: () => {'type': ''},
    );

    return element['type'] == 'group';
  }
}
