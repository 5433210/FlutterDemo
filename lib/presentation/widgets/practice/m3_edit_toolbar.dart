import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';
import 'practice_edit_controller.dart';

/// Material 3 edit toolbar for practice edit page
class M3EditToolbar extends StatelessWidget implements PreferredSizeWidget {
  final PracticeEditController controller;
  final bool gridVisible;
  final bool snapEnabled;
  final bool canPaste;
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
  final VoidCallback? onCopyFormatting;
  final VoidCallback? onApplyFormatBrush;
  
  // 元素工具相关参数
  final String? currentTool;
  final Function(String)? onSelectTool;
  final Function(BuildContext, String)? onDragElementStart;

  const M3EditToolbar({
    super.key,
    required this.controller,
    required this.gridVisible,
    required this.snapEnabled,
    this.canPaste = false,
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
    this.onCopyFormatting,
    this.onApplyFormatBrush,
    this.currentTool,
    this.onSelectTool,
    this.onDragElementStart,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
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
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Wrap(
        spacing: AppSizes.s,
        runSpacing: AppSizes.s,
        alignment: WrapAlignment.start,
        children: [
          // 元素工具按钮（如果提供了相关参数）
          if (onSelectTool != null) ...[          
            // 元素工具组
            _buildToolbarGroup(
              title: l10n.practiceEditElements,
              children: [
                _buildElementButton(
                  context: context,
                  icon: Icons.text_fields,
                  tooltip: l10n.practiceEditText,
                  toolName: 'text',
                  isSelected: currentTool == 'text',
                  onPressed: () => onSelectTool!('text'),
                  onDragStart: onDragElementStart != null ? 
                    () => onDragElementStart!(context, 'text') : null,
                ),
                _buildElementButton(
                  context: context,
                  icon: Icons.image,
                  tooltip: l10n.practiceEditImage,
                  toolName: 'image',
                  isSelected: currentTool == 'image',
                  onPressed: () => onSelectTool!('image'),
                  onDragStart: onDragElementStart != null ? 
                    () => onDragElementStart!(context, 'image') : null,
                ),
                _buildElementButton(
                  context: context,
                  icon: Icons.grid_on,
                  tooltip: l10n.practiceEditCollection,
                  toolName: 'collection',
                  isSelected: currentTool == 'collection',
                  onPressed: () => onSelectTool!('collection'),
                  onDragStart: onDragElementStart != null ? 
                    () => onDragElementStart!(context, 'collection') : null,
                ),
                _buildToolbarButton(
                  context: context,
                  icon: Icons.select_all,
                  tooltip: l10n.practiceEditSelect,
                  onPressed: () => onSelectTool!('select'),
                  isActive: currentTool == 'select',
                ),
              ],
            ),
            
            const SizedBox(width: AppSizes.s),
            const VerticalDivider(),
            const SizedBox(width: AppSizes.s),
          ],
          // Edit operations group
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
                onPressed: canPaste ? onPaste : null,
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

          // Layer operations group
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

          // Helper functions group
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
              if (onCopyFormatting != null)
                _buildToolbarButton(
                  context: context,
                  icon: Icons.format_paint,
                  tooltip: '复制格式',
                  onPressed: hasSelection ? onCopyFormatting : null,
                ),
              if (onApplyFormatBrush != null)
                _buildToolbarButton(
                  context: context,
                  icon: Icons.format_color_fill,
                  tooltip: '应用格式刷',
                  onPressed: hasSelection ? onApplyFormatBrush : null,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build element button with optional drag functionality
  Widget _buildElementButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required String toolName,
    required bool isSelected,
    required VoidCallback onPressed,
    VoidCallback? onDragStart,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Widget button = Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected 
                      ? colorScheme.onPrimaryContainer 
                      : colorScheme.onSurface,
                ),
                const SizedBox(width: 4),
                Text(
                  tooltip,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected 
                        ? colorScheme.onPrimaryContainer 
                        : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    // 如果有拖拽功能，包装为Draggable
    if (onDragStart != null) {
      return Draggable<String>(
        data: toolName,
        feedback: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 4),
                Text(tooltip, 
                  style: TextStyle(fontSize: 12, color: colorScheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
        onDragStarted: onDragStart,
        child: button,
      );
    }
    
    return button;
  }

  /// Build toolbar button
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

  /// Build toolbar group
  Widget _buildToolbarGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Group title
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        // Tool buttons
        ...children,
      ],
    );
  }

  /// Check if the selected element is a group
  bool _isSelectedElementGroup() {
    if (controller.state.selectedElementIds.length != 1) return false;

    final id = controller.state.selectedElementIds.first;
    final element = controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == id,
      orElse: () => <String, dynamic>{},
    );

    return element.isNotEmpty && element['type'] == 'group';
  }
}
