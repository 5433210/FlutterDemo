import 'package:flutter/material.dart';

import 'practice_edit_controller.dart';

/// 图层管理面板
class PracticeLayerPanel extends StatefulWidget {
  final PracticeEditController controller;
  final Function(String) onLayerSelect;
  final Function(String, bool) onLayerVisibilityToggle;
  final Function(String, bool) onLayerLockToggle;
  final VoidCallback onAddLayer;
  final Function(String) onDeleteLayer;
  final Function(int, int) onReorderLayer;

  const PracticeLayerPanel({
    Key? key,
    required this.controller,
    required this.onLayerSelect,
    required this.onLayerVisibilityToggle,
    required this.onLayerLockToggle,
    required this.onAddLayer,
    required this.onDeleteLayer,
    required this.onReorderLayer,
  }) : super(key: key);

  @override
  State<PracticeLayerPanel> createState() => _PracticeLayerPanelState();
}

class _PracticeLayerPanelState extends State<PracticeLayerPanel> {
  // 用于存储正在编辑的图层ID和临时名称
  String? _editingLayerId;
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLayerToolbar(),
        Expanded(
          child: _buildLayerList(),
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
    // 添加焦点监听器，以便在失去焦点时应用名称更改
    _focusNode.addListener(_onFocusChange);
  }

  void _applyLayerNameChange() {
    if (_editingLayerId != null) {
      final newName = _nameController.text.trim();
      if (newName.isNotEmpty) {
        // 修改图层名称
        widget.controller.renameLayer(_editingLayerId!, newName);
        // 重置编辑状态
        setState(() {
          _editingLayerId = null;
        });
      }
    }
  }

  /// 构建图层项
  Widget _buildLayerItem(
      BuildContext context, Map<String, dynamic> layer, int index) {
    final id = layer['id'] as String;
    final name = layer['name'] as String;
    final isVisible = layer['isVisible'] as bool? ?? true;
    final isLocked = layer['isLocked'] as bool? ?? false;
    final isSelected = widget.controller.state.selectedLayerId == id;
    final isEditing = _editingLayerId == id;

    return Container(
      key: ValueKey(id),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withAlpha(25) : null,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected
              ? Colors.blue.withAlpha(128)
              : Colors.grey.withAlpha(51),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onLayerSelect(id),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // 可见性切换按钮
                SizedBox(
                  width: 26,
                  height: 26,
                  child: InkWell(
                    onTap: () => widget.onLayerVisibilityToggle(id, !isVisible),
                    borderRadius: BorderRadius.circular(4),
                    child: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: isVisible ? Colors.blue : Colors.grey,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // 锁定切换按钮
                SizedBox(
                  width: 26,
                  height: 26,
                  child: InkWell(
                    onTap: () => widget.onLayerLockToggle(id, !isLocked),
                    borderRadius: BorderRadius.circular(4),
                    child: Icon(
                      isLocked ? Icons.lock : Icons.lock_open,
                      color: isLocked ? Colors.orange : Colors.grey,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 图层名称区域 - 根据是否处于编辑状态显示不同的UI
                Expanded(
                  child: isEditing
                      ? TextField(
                          controller: _nameController,
                          focusNode: _focusNode,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            border: InputBorder.none,
                          ),
                          autofocus: true,
                          onSubmitted: (_) => _applyLayerNameChange(),
                        )
                      : GestureDetector(
                          onDoubleTap: () {
                            setState(() {
                              _editingLayerId = id;
                              _nameController.text = name;
                            });
                            // 确保下一帧就聚焦
                            Future.microtask(() => _focusNode.requestFocus());
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected ? Colors.blue : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),

                // 操作按钮 - 使用Wrap来自动换行，避免溢出
                if (!isEditing)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 72),
                    child: Wrap(
                      spacing: 0,
                      children: [
                        // 重命名按钮
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _editingLayerId = id;
                                _nameController.text = name;
                              });
                              // 确保下一帧就聚焦
                              Future.microtask(() => _focusNode.requestFocus());
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                        // 删除图层按钮
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: InkWell(
                            onTap: () =>
                                _showDeleteLayerDialog(context, id, name),
                            borderRadius: BorderRadius.circular(4),
                            child: const Icon(
                              Icons.delete,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),

                        // 拖拽按钮
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: ReorderableDragStartListener(
                              index: index,
                              child: const Icon(
                                Icons.drag_handle,
                                size: 16,
                                color: Colors.grey,
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
  Widget _buildLayerList() {
    final layers = widget.controller.state.layers;

    if (layers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_clear, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('没有图层，请添加图层', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // 将图层列表反转，使顶层显示在最上面
    // 这样图层面板中的顺序与渲染顺序一致：顶部的图层在渲染时最后绘制
    final reversedLayers = layers.reversed.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ReorderableListView.builder(
        itemCount: reversedLayers.length,
        itemBuilder: (context, index) =>
            _buildLayerItem(context, reversedLayers[index], index),
        onReorder: (oldIndex, newIndex) {
          // 由于我们反转了图层列表，需要调整索引
          final actualOldIndex = layers.length - 1 - oldIndex;
          final actualNewIndex = layers.length -
              1 -
              (newIndex > oldIndex ? newIndex - 1 : newIndex);
          widget.onReorderLayer(actualOldIndex, actualNewIndex);
        },
        buildDefaultDragHandles: false, // 禁用默认拖动手柄
        proxyDecorator: (child, index, animation) {
          // 自定义拖动时的视觉效果
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              return Material(
                elevation: 4.0 * animation.value,
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
                shadowColor: Colors.blue.withAlpha(128),
                child: child,
              );
            },
            child: child,
          );
        },
      ),
    );
  }

  /// 构建图层工具栏
  Widget _buildLayerToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 标题
          const Flexible(
            child: Text(
              '图层',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 工具按钮组
          Wrap(
            spacing: 0,
            children: [
              // 添加图层按钮
              SizedBox(
                width: 32,
                height: 32,
                child: Tooltip(
                  message: '添加新图层',
                  child: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: Colors.blue,
                    onPressed: widget.onAddLayer,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                  ),
                ),
              ),

              // 全部显示/隐藏按钮
              SizedBox(
                width: 32,
                height: 32,
                child: Tooltip(
                  message: '切换所有图层可见性',
                  child: IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {
                      final allVisible = widget.controller.state.layers
                          .every((layer) => layer['isVisible'] == true);

                      // 如果所有图层都可见，则隐藏所有；否则显示所有
                      for (final layer in widget.controller.state.layers) {
                        widget.onLayerVisibilityToggle(
                            layer['id'], !allVisible);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                  ),
                ),
              ),

              // 全部锁定/解锁按钮
              SizedBox(
                width: 32,
                height: 32,
                child: Tooltip(
                  message: '切换所有图层锁定状态',
                  child: IconButton(
                    icon: const Icon(Icons.lock_outline),
                    onPressed: () {
                      final allLocked = widget.controller.state.layers
                          .every((layer) => layer['isLocked'] == true);

                      // 如果所有图层都被锁定，则解锁所有；否则锁定所有
                      for (final layer in widget.controller.state.layers) {
                        widget.onLayerLockToggle(layer['id'], !allLocked);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _editingLayerId != null) {
      // 当输入框失去焦点时，应用名称更改
      _applyLayerNameChange();
    }
  }

  /// 显示删除图层确认对话框
  void _showDeleteLayerDialog(
      BuildContext context, String layerId, String layerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除图层'),
        content: Text('确定要删除图层 "$layerName" 吗？图层中的所有元素都将被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              widget.onDeleteLayer(layerId);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
