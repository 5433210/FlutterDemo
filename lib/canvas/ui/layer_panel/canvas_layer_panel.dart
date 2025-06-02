// filepath: lib/canvas/ui/layer_panel/canvas_layer_panel.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/canvas_state_manager.dart';
import '../../core/interfaces/layer_data.dart';

/// 画布图层管理面板
class CanvasLayerPanel extends StatefulWidget {
  /// 状态管理器
  final CanvasStateManager stateManager;

  const CanvasLayerPanel({
    Key? key,
    required this.stateManager,
  }) : super(key: key);

  @override
  State<CanvasLayerPanel> createState() => _CanvasLayerPanelState();
}

class _CanvasLayerPanelState extends State<CanvasLayerPanel> {
  /// 正在编辑名称的图层ID
  String? _editingLayerId;

  /// 图层名称编辑控制器
  final TextEditingController _nameController = TextEditingController();

  /// 文本输入焦点
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(l10n, colorScheme),
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
    _focusNode.addListener(_onFocusChange);
  }

  /// 应用图层名称更改
  void _applyLayerNameChange() {
    if (_editingLayerId != null) {
      final newName = _nameController.text.trim();
      if (newName.isNotEmpty) {
        final layer = widget.stateManager.getLayerById(_editingLayerId!);
        if (layer != null) {
          widget.stateManager.updateLayerProperties(
            _editingLayerId!,
            {'name': newName},
          );
        }
        setState(() {
          _editingLayerId = null;
        });
      }
    }
  }

  /// 构建头部工具栏
  Widget _buildHeader(AppLocalizations l10n, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Text(
            l10n.layerOperations,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _createNewLayer,
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.addLayer),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建图层项
  Widget _buildLayerItem(
    BuildContext context,
    LayerData layer,
    int index,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    final id = layer.id;
    final name = layer.name;
    final isVisible = layer.visible;
    final isLocked = layer.locked;
    final isSelected = widget.stateManager.selectedLayerId == id;
    final isEditing = _editingLayerId == id;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: ValueKey(id),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color:
            isSelected ? colorScheme.primaryContainer.withOpacity(0.7) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.stateManager.selectLayer(id),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // 可见性切换按钮
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    onPressed: () => widget.stateManager
                        .toggleLayerVisibility(id, !isVisible),
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

                // 锁定切换按钮
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    onPressed: () =>
                        widget.stateManager.toggleLayerLock(id, !isLocked),
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

                // 图层名称区域 - 基于编辑状态显示不同UI
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
                ), // 元素数量显示
                if (!isEditing) ...{
                  const SizedBox(width: 8),
                  Text(
                    '${widget.stateManager.getElementsByLayerId(id).length}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                },

                // 操作按钮
                if (!isEditing)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 96),
                    child: Wrap(
                      spacing: 0,
                      children: [
                        // 重命名按钮
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _editingLayerId = id;
                                _nameController.text = name;
                              });
                              // 确保下一帧获取焦点
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
                            tooltip: l10n.rename,
                          ),
                        ),

                        // 新增：选择图层上所有元素的按钮
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            onPressed: () => widget.stateManager
                                .selectAllElementsOnLayer(id),
                            icon: Icon(
                              Icons.select_all,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            tooltip: 'Select All Elements',
                          ),
                        ),

                        // 删除图层按钮
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
                            tooltip: l10n.delete,
                          ),
                        ),

                        // 拖动手柄
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

  /// 构建图层列表
  Widget _buildLayerList(AppLocalizations l10n, ColorScheme colorScheme) {
    final layers = widget.stateManager.layerState.sortedLayers;
    final textTheme = Theme.of(context).textTheme;

    if (layers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_clear, size: 48, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              l10n.practiceEditNoLayers,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // 反转图层列表，使顶部图层显示在顶部
    // 这使得图层面板顺序与渲染顺序一致：面板中的顶层图层最后渲染
    final reversedLayers = widget.stateManager.layerState.reversedLayers;

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
          // 由于我们反转了图层列表，调整索引
          final actualOldIndex = layers.length - 1 - oldIndex;
          final actualNewIndex = layers.length -
              1 -
              (newIndex > oldIndex ? newIndex - 1 : newIndex);
          widget.stateManager.reorderLayers(actualOldIndex, actualNewIndex);
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

  /// 创建新图层
  void _createNewLayer() {
    final l10n = AppLocalizations.of(context);
    final layerCount = widget.stateManager.layerState.layerCount;

    final newLayer = LayerData(
      id: const Uuid().v4(),
      name: '${l10n.layer} ${layerCount + 1}',
      visible: true,
      locked: false,
      opacity: 1.0,
      blendMode: 'normal',
    );

    widget.stateManager.createLayer(newLayer);
  }

  /// 焦点变化处理器
  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _applyLayerNameChange();
    }
  }

  /// 显示删除图层确认对话框
  Future<void> _showDeleteLayerDialog(
    BuildContext context,
    String layerId,
    String layerName,
    AppLocalizations l10n,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.practiceEditDeleteLayerConfirm),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.practiceEditDeleteLayerMessage),
            const SizedBox(height: 16),
            Text(
              '${l10n.layer}: $layerName',
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
      widget.stateManager.deleteLayer(layerId);
    }
  }
}
