import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';
import 'guideline_alignment/guideline_types.dart';
import 'practice_edit_controller.dart';

/// Material 3 edit toolbar for practice edit page
class M3EditToolbar extends StatelessWidget implements PreferredSizeWidget {
  final PracticeEditController controller;
  final bool gridVisible;
  final bool snapEnabled; // 保留兼容性
  final AlignmentMode alignmentMode; // 新的对齐模式
  final bool canPaste;
  final VoidCallback onToggleGrid;
  final VoidCallback? onToggleSnap; // 保留兼容性
  final VoidCallback onToggleAlignmentMode; // 新的三态切换
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

  // 选择相关的操作
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;

  const M3EditToolbar({
    super.key,
    required this.controller,
    required this.gridVisible,
    required this.snapEnabled,
    required this.alignmentMode,
    this.canPaste = false,
    required this.onToggleGrid,
    this.onToggleSnap,
    required this.onToggleAlignmentMode,
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
    this.onSelectAll,
    this.onDeselectAll,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final hasSelection = controller.state.selectedElementIds.isNotEmpty;
    final isMultiSelected = controller.state.selectedElementIds.length > 1;
    final hasSelectedGroup =
        hasSelection && !isMultiSelected && _isSelectedElementGroup();
    return Container(
      width: double.infinity, // 扩展到整个画布宽度
      // 移除固定高度限制，使用自适应高度
      constraints: const BoxConstraints(minHeight: 48),
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
              title: l10n.elements,
              children: [
                _buildElementButton(
                  context: context,
                  icon: Icons.text_fields,
                  tooltip: '${l10n.text} (Alt+T)',
                  toolName: 'text',
                  isSelected: currentTool == 'text',
                  onPressed: () {
                    EditPageLogger.editPageDebug(
                      'Toolbar: Select text tool',
                      data: {
                        'selectedTool': 'text',
                        'previousTool': currentTool,
                        'operation': 'tool_select',
                      },
                    );
                    onSelectTool!('text');
                  },
                  onDragStart: onDragElementStart != null
                      ? () => onDragElementStart!(context, 'text')
                      : null,
                ),
                _buildElementButton(
                  context: context,
                  icon: Icons.image,
                  tooltip: '${l10n.image} (Alt+I)',
                  toolName: 'image',
                  isSelected: currentTool == 'image',
                  onPressed: () {
                    EditPageLogger.editPageDebug(
                      'Toolbar: Select image tool',
                      data: {
                        'selectedTool': 'image',
                        'previousTool': currentTool,
                        'operation': 'tool_select',
                      },
                    );
                    onSelectTool!('image');
                  },
                  onDragStart: onDragElementStart != null
                      ? () => onDragElementStart!(context, 'image')
                      : null,
                ),
                _buildElementButton(
                  context: context,
                  icon: Icons.grid_on,
                  tooltip: '${l10n.practiceEditCollection} (Alt+C)',
                  toolName: 'collection',
                  isSelected: currentTool == 'collection',
                  onPressed: () {
                    EditPageLogger.editPageDebug(
                      'Toolbar: Select collection tool',
                      data: {
                        'selectedTool': 'collection',
                        'previousTool': currentTool,
                        'operation': 'tool_select',
                      },
                    );
                    onSelectTool!('collection');
                  },
                  onDragStart: onDragElementStart != null
                      ? () => onDragElementStart!(context, 'collection')
                      : null,
                ),
                _buildToolbarButton(
                  context: context,
                  icon: Icons.select_all,
                  tooltip: '${l10n.select} (Alt+S)',
                  onPressed: () {
                    EditPageLogger.editPageDebug(
                      'Toolbar: Select selection tool',
                      data: {
                        'selectedTool': 'select',
                        'previousTool': currentTool,
                        'operation': 'tool_select',
                      },
                    );
                    onSelectTool!('select');
                  },
                  isActive: currentTool == 'select',
                ),
                if (onSelectAll != null)
                  _buildToolbarButton(
                    context: context,
                    icon: Icons.done_all,
                    tooltip: l10n.selectAllWithShortcut,
                    onPressed: onSelectAll,
                  ),
                if (onDeselectAll != null)
                  _buildToolbarButton(
                    context: context,
                    icon: Icons.deselect,
                    tooltip: l10n.deselectAll,
                    onPressed: onDeselectAll,
                  ),
              ],
            ),

            const SizedBox(width: AppSizes.s),
            const VerticalDivider(),
            const SizedBox(width: AppSizes.s),
          ],
          // Edit operations group
          _buildToolbarGroup(
            title: l10n.editOperations,
            children: [
              _buildToolbarButton(
                context: context,
                icon: Icons.copy,
                tooltip: l10n.copy,
                onPressed: hasSelection
                    ? () {
                        EditPageLogger.editPageDebug(
                          'Toolbar: Copy operation',
                          data: {
                            'selectedCount':
                                controller.state.selectedElementIds.length,
                            'selectedIds': controller.state.selectedElementIds,
                            'operation': 'copy_action',
                          },
                        );
                        onCopy();
                      }
                    : null,
              ),
              _buildToolbarButton(
                context: context,
                icon: Icons.paste,
                tooltip: l10n.paste,
                onPressed: canPaste
                    ? () {
                        EditPageLogger.editPageDebug(
                          'Toolbar: Paste operation',
                          data: {
                            'canPaste': canPaste,
                            'operation': 'paste_action',
                          },
                        );
                        onPaste();
                      }
                    : null,
              ),
              _buildToolbarButton(
                context: context,
                icon: Icons.delete,
                tooltip: l10n.delete,
                onPressed: hasSelection
                    ? () {
                        EditPageLogger.editPageDebug(
                          'Toolbar: Delete operation',
                          data: {
                            'selectedCount':
                                controller.state.selectedElementIds.length,
                            'selectedIds': controller.state.selectedElementIds,
                            'operation': 'delete_action',
                          },
                        );
                        onDelete();
                      }
                    : null,
              ),
              _buildToolbarButton(
                context: context,
                icon: Icons.group,
                tooltip: l10n.group,
                onPressed: isMultiSelected ? onGroupElements : null,
              ),
              _buildToolbarButton(
                context: context,
                icon: Icons.format_shapes,
                tooltip: l10n.ungroup,
                onPressed: hasSelectedGroup ? onUngroupElements : null,
              ),
            ],
          ),

          const SizedBox(width: AppSizes.s),
          const VerticalDivider(),
          const SizedBox(width: AppSizes.s),

          // Layer operations group
          _buildToolbarGroup(
            title: l10n.layerOperations,
            children: [
              _buildToolbarButton(
                context: context,
                icon: Icons.vertical_align_top,
                tooltip: l10n.bringToFront,
                onPressed: hasSelection ? onBringToFront : null,
              ),
              _buildToolbarButton(
                context: context,
                icon: Icons.vertical_align_bottom,
                tooltip: l10n.sendToBack,
                onPressed: hasSelection ? onSendToBack : null,
              ),
              _buildToolbarButton(
                context: context,
                icon: Icons.arrow_upward,
                tooltip: l10n.moveUp,
                onPressed: hasSelection ? onMoveUp : null,
              ),
              _buildToolbarButton(
                context: context,
                icon: Icons.arrow_downward,
                tooltip: l10n.moveDown,
                onPressed: hasSelection ? onMoveDown : null,
              ),
            ],
          ),

          const SizedBox(width: AppSizes.s),
          const VerticalDivider(),
          const SizedBox(width: AppSizes.s),

          // 对齐辅助组
          _buildToolbarGroup(
            title: l10n.alignmentAssist,
            children: [
              _buildToolbarButton(
                context: context,
                icon: gridVisible ? Icons.grid_on : Icons.grid_off,
                tooltip: gridVisible ? l10n.hideGrid : l10n.showGrid,
                onPressed: onToggleGrid,
                isActive: gridVisible,
              ),
              _buildAlignmentModeButton(context),
              if (onCopyFormatting != null)
                _buildToolbarButton(
                  context: context,
                  icon: Icons.format_paint,
                  tooltip: l10n.copyFormat,
                  onPressed: hasSelection ? onCopyFormatting : null,
                ),
              if (onApplyFormatBrush != null)
                _buildToolbarButton(
                  context: context,
                  icon: Icons.format_color_fill,
                  tooltip: l10n.applyFormatBrush,
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
          onTap: () {
            EditPageLogger.editPageDebug(
              'Toolbar element tool switch',
              data: {
                'toolName': toolName,
                'isSelected': isSelected,
                'tooltip': tooltip,
              },
            );
            onPressed();
          },
          borderRadius: BorderRadius.circular(8.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 36), // 确保有足够的最小宽度
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
                      overflow: TextOverflow.ellipsis,
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
                Text(
                  tooltip,
                  style: TextStyle(
                      fontSize: 12, color: colorScheme.onPrimaryContainer),
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
    Color? customColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // 计算图标颜色
    final Color iconColor = customColor ??
        (isActive
            ? colorScheme.primary
            : onPressed == null
                ? colorScheme.onSurface.withOpacity(0.3)
                : colorScheme.onSurface);

    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(
          icon,
          color: iconColor,
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
    return Wrap(
      spacing: 4, // 设置按钮之间的水平间距
      crossAxisAlignment: WrapCrossAlignment.center, // 垂直居中对齐
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

  /// 构建对齐模式按钮（三态切换）
  Widget _buildAlignmentModeButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    IconData icon;
    String tooltip;
    Color? buttonColor;

    switch (alignmentMode) {
      case AlignmentMode.none:
        icon = Icons.crop_free; // 无辅助图标
        tooltip = l10n.alignmentNone;
        buttonColor = colorScheme.onSurface.withOpacity(0.5);
        break;
      case AlignmentMode.gridSnap:
        icon = Icons.grid_view; // 网格贴附图标
        tooltip = l10n.alignmentGrid;
        buttonColor = Colors.blue;
        break;
      case AlignmentMode.guideline:
        icon = Icons.horizontal_rule; // 参考线图标
        tooltip = l10n.alignmentGuideline;
        buttonColor = Colors.orange;
        break;
    }

    return _buildToolbarButton(
      context: context,
      icon: icon,
      tooltip: tooltip,
      onPressed: onToggleAlignmentMode,
      isActive: alignmentMode != AlignmentMode.none,
      customColor: buttonColor,
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
