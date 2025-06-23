import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../l10n/app_localizations.dart';
import 'practice_edit_controller.dart';

/// Material 3 layer management panel
class M3PracticeLayerPanel extends StatefulWidget {
  final PracticeEditController controller;
  final Function(String) onLayerSelect;
  final Function(String, bool) onLayerVisibilityToggle;
  final Function(String, bool) onLayerLockToggle;
  final VoidCallback onAddLayer;
  final Function(String) onDeleteLayer;
  final Function(int, int) onReorderLayer;

  const M3PracticeLayerPanel({
    super.key,
    required this.controller,
    required this.onLayerSelect,
    required this.onLayerVisibilityToggle,
    required this.onLayerLockToggle,
    required this.onAddLayer,
    required this.onDeleteLayer,
    required this.onReorderLayer,
  });

  @override
  State<M3PracticeLayerPanel> createState() => _M3PracticeLayerPanelState();
}

class _M3PracticeLayerPanelState extends State<M3PracticeLayerPanel> {
  // For storing the layer ID being edited and temporary name
  String? _editingLayerId;
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final layers = widget.controller.state.layers;

    EditPageLogger.propertyPanelDebug(
      '图层管理面板构建',
      data: {
        'layersCount': layers.length,
        'selectedLayerId': widget.controller.state.selectedLayerId,
        'editingLayerId': _editingLayerId,
        'operation': 'layer_panel_build',
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLayerToolbar(l10n, colorScheme),
        Expanded(
          child: _buildLayerList(l10n, colorScheme),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Add focus listener to apply name changes when focus is lost
    _focusNode.addListener(_onFocusChange);
  }

  void _applyLayerNameChange() {
    if (_editingLayerId != null) {
      final newName = _nameController.text.trim();
      final layerId = _editingLayerId!;
      final layers = widget.controller.state.layers;
      final layer =
          layers.firstWhere((l) => l['id'] == layerId, orElse: () => {});
      final oldName = layer['name'] as String? ?? 'Unknown';

      if (newName.isNotEmpty && newName != oldName) {
        EditPageLogger.propertyPanelDebug(
          '图层名称修改',
          data: {
            'layerId': layerId,
            'oldName': oldName,
            'newName': newName,
            'operation': 'layer_rename',
          },
        );

        try {
          // Modify layer name
          widget.controller.renameLayer(layerId, newName);

          EditPageLogger.propertyPanelDebug(
            '图层名称修改成功',
            data: {
              'layerId': layerId,
              'newName': newName,
              'operation': 'layer_rename_success',
            },
          );
        } catch (error, stackTrace) {
          EditPageLogger.propertyPanelError(
            '图层名称修改失败',
            error: error,
            stackTrace: stackTrace,
            data: {
              'layerId': layerId,
              'newName': newName,
              'operation': 'layer_rename_error',
            },
          );
        }
      }

      // Reset edit state
      setState(() {
        _editingLayerId = null;
      });
    }
  }

  /// Build layer item
  Widget _buildLayerItem(
    BuildContext context,
    Map<String, dynamic> layer,
    int index,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    final id = layer['id'] as String;
    final name = layer['name'] as String;
    final isVisible = layer['isVisible'] as bool? ?? true;
    final isLocked = layer['isLocked'] as bool? ?? false;
    final isSelected = widget.controller.state.selectedLayerId == id;
    final isEditing = _editingLayerId == id;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: ValueKey(id),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.7)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            EditPageLogger.propertyPanelDebug(
              '图层选择',
              data: {
                'layerId': id,
                'layerName': name,
                'wasSelected': isSelected,
                'operation': 'layer_select',
              },
            );
            widget.onLayerSelect(id);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // Visibility toggle button
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    onPressed: () {
                      EditPageLogger.propertyPanelDebug(
                        '图层可见性切换',
                        data: {
                          'layerId': id,
                          'layerName': name,
                          'fromVisible': isVisible,
                          'toVisible': !isVisible,
                          'operation': 'layer_visibility_toggle',
                        },
                      );
                      widget.onLayerVisibilityToggle(id, !isVisible);
                    },
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color:
                          isVisible ? colorScheme.primary : colorScheme.outline,
                      size: 18,
                    ),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    tooltip: isVisible ? 'Hide Layer' : 'Show Layer',
                  ),
                ),

                // Lock toggle button
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    onPressed: () {
                      EditPageLogger.propertyPanelDebug(
                        '图层锁定状态切换',
                        data: {
                          'layerId': id,
                          'layerName': name,
                          'fromLocked': isLocked,
                          'toLocked': !isLocked,
                          'operation': 'layer_lock_toggle',
                        },
                      );
                      widget.onLayerLockToggle(id, !isLocked);
                    },
                    icon: Icon(
                      isLocked ? Icons.lock : Icons.lock_open,
                      color:
                          isLocked ? colorScheme.tertiary : colorScheme.outline,
                      size: 18,
                    ),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    tooltip: isLocked ? 'Unlock Layer' : 'Lock Layer',
                  ),
                ),
                const SizedBox(width: 8),

                // Layer name area - show different UI based on edit state
                Expanded(
                  child: isEditing
                      ? TextField(
                          controller: _nameController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                            border: InputBorder.none,
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                          ),
                          autofocus: true,
                          onSubmitted: (_) => _applyLayerNameChange(),
                          style: textTheme.bodyMedium,
                        )
                      : Text(
                          name,
                          style: textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),

                // Action buttons - use Wrap to auto-wrap and avoid overflow
                if (!isEditing)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 96),
                    child: Wrap(
                      spacing: 0,
                      children: [
                        // Rename button
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _editingLayerId = id;
                                _nameController.text = name;
                              });
                              // Ensure focus on next frame
                              Future.microtask(() => _focusNode.requestFocus());
                            },
                            icon: Icon(
                              Icons.edit,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            tooltip: AppLocalizations.of(context).renameLayer,
                          ),
                        ),

                        // Delete layer button
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            onPressed: () =>
                                _showDeleteLayerDialog(context, id, name, l10n),
                            icon: Icon(
                              Icons.delete,
                              size: 16,
                              color: colorScheme.error,
                            ),
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            tooltip: l10n.deleteLayer,
                          ),
                        ),

                        // Drag handle
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: ReorderableDragStartListener(
                              index: index,
                              child: Icon(
                                Icons.drag_handle,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build layer list
  Widget _buildLayerList(AppLocalizations l10n, ColorScheme colorScheme) {
    final layers = widget.controller.state.layers;
    final textTheme = Theme.of(context).textTheme;

    if (layers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_clear, size: 48, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              l10n.noLayers,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Reverse the layer list so top layers show at the top
    // This makes the layer panel order consistent with rendering order: top layers in panel are rendered last
    final reversedLayers = layers.reversed.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ReorderableListView.builder(
        itemCount: reversedLayers.length,
        itemBuilder: (context, index) => _buildLayerItem(
          context,
          reversedLayers[index],
          index,
          l10n,
          colorScheme,
        ),
        onReorder: (oldIndex, newIndex) {
          // Since we reversed the layer list, adjust indices
          final actualOldIndex = layers.length - 1 - oldIndex;
          final actualNewIndex = layers.length -
              1 -
              (newIndex > oldIndex ? newIndex - 1 : newIndex);

          final movedLayer = layers[actualOldIndex];

          EditPageLogger.propertyPanelDebug(
            '图层重新排序',
            data: {
              'layerId': movedLayer['id'],
              'layerName': movedLayer['name'],
              'fromIndex': actualOldIndex,
              'toIndex': actualNewIndex,
              'totalLayers': layers.length,
              'operation': 'layer_reorder',
            },
          );

          widget.onReorderLayer(actualOldIndex, actualNewIndex);
        },
        proxyDecorator: (child, index, animation) {
          return Material(
            elevation: 4,
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            child: child,
          );
        },
      ),
    );
  }

  /// Build layer toolbar
  Widget _buildLayerToolbar(AppLocalizations l10n, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Text(
            l10n.layer,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () {
              final currentLayersCount = widget.controller.state.layers.length;

              EditPageLogger.propertyPanelDebug(
                '添加新图层',
                data: {
                  'currentLayersCount': currentLayersCount,
                  'operation': 'layer_add',
                },
              );

              widget.onAddLayer();
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.addLayer),
            style: FilledButton.styleFrom(),
          ),
        ],
      ),
    );
  }

  /// Focus change handler
  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _applyLayerNameChange();
    }
  }

  /// Show delete layer confirmation dialog
  Future<void> _showDeleteLayerDialog(
    BuildContext context,
    String layerId,
    String layerName,
    AppLocalizations l10n,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteLayerConfirmMessage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteLayerMessage),
            const SizedBox(height: 16),
            Text(
              'Layer: $layerName',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (result == true) {
      EditPageLogger.propertyPanelDebug(
        '确认删除图层',
        data: {
          'layerId': layerId,
          'layerName': layerName,
          'operation': 'layer_delete_confirmed',
        },
      );

      try {
        widget.onDeleteLayer(layerId);

        EditPageLogger.propertyPanelDebug(
          '图层删除成功',
          data: {
            'layerId': layerId,
            'layerName': layerName,
            'operation': 'layer_delete_success',
          },
        );
      } catch (error, stackTrace) {
        EditPageLogger.propertyPanelError(
          '图层删除失败',
          error: error,
          stackTrace: stackTrace,
          data: {
            'layerId': layerId,
            'layerName': layerName,
            'operation': 'layer_delete_error',
          },
        );
      }
    } else {
      EditPageLogger.propertyPanelDebug(
        '取消删除图层',
        data: {
          'layerId': layerId,
          'layerName': layerName,
          'operation': 'layer_delete_cancelled',
        },
      );
    }
  }
}
