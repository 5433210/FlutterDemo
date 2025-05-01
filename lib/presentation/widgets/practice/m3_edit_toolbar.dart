import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'practice_edit_controller.dart';

/// Material 3 edit toolbar for practice edit page
class M3EditToolbar extends StatelessWidget {
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

  const M3EditToolbar({
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final hasSelection = controller.state.selectedElementIds.isNotEmpty;
    final isMultiSelected = controller.state.selectedElementIds.length > 1;
    final hasSelectedGroup = hasSelection && !isMultiSelected && _isSelectedElementGroup();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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

            const SizedBox(width: 8),
            const VerticalDivider(),
            const SizedBox(width: 8),

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

            const SizedBox(width: 8),
            const VerticalDivider(),
            const SizedBox(width: 8),

            // Helper functions group
            _buildToolbarGroup(
              title: l10n.practiceEditHelperFunctions,
              children: [
                _buildToolbarButton(
                  context: context,
                  icon: gridVisible ? Icons.grid_on : Icons.grid_off,
                  tooltip: gridVisible ? l10n.practiceEditHideGrid : l10n.practiceEditShowGrid,
                  onPressed: onToggleGrid,
                  isActive: gridVisible,
                ),
                _buildToolbarButton(
                  context: context,
                  icon: Icons.format_line_spacing,
                  tooltip: snapEnabled ? l10n.practiceEditDisableSnap : l10n.practiceEditEnableSnap,
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
