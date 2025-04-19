import 'package:flutter/material.dart';

import 'practice_edit_controller.dart';

/// 图层管理面板
class PracticeLayerPanel extends StatelessWidget {
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

  /// 构建图层项
  Widget _buildLayerItem(
      BuildContext context, Map<String, dynamic> layer, int index) {
    final id = layer['id'] as String;
    final name = layer['name'] as String;
    final isVisible = layer['isVisible'] as bool? ?? true;
    final isLocked = layer['isLocked'] as bool? ?? false;
    final isSelected = controller.state.selectedLayerId == id;

    return Container(
      key: ValueKey(id),
      color: isSelected ? Colors.blue.withOpacity(0.1) : null,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 可见性切换
              IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: isVisible ? null : Colors.grey,
                ),
                onPressed: () => onLayerVisibilityToggle(id, !isVisible),
                tooltip: isVisible ? '隐藏图层' : '显示图层',
                iconSize: 20,
                constraints: const BoxConstraints(
                  minWidth: 30,
                  minHeight: 30,
                ),
              ),
              // 锁定切换
              IconButton(
                icon: Icon(
                  isLocked ? Icons.lock : Icons.lock_open,
                  color: isLocked ? Colors.red : null,
                ),
                onPressed: () => onLayerLockToggle(id, !isLocked),
                tooltip: isLocked ? '解锁图层' : '锁定图层',
                iconSize: 20,
                constraints: const BoxConstraints(
                  minWidth: 30,
                  minHeight: 30,
                ),
              ),
            ],
          ),
          title: GestureDetector(
            onDoubleTap: () => _showRenameDialog(context, id, name),
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          selected: isSelected,
          onTap: () => onLayerSelect(id),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 重命名按钮
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showRenameDialog(context, id, name),
                tooltip: '重命名图层',
                iconSize: 18,
                constraints: const BoxConstraints(
                  minWidth: 30,
                  minHeight: 30,
                ),
              ),
              // 删除按钮
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => onDeleteLayer(id),
                tooltip: '删除图层',
                iconSize: 18,
                constraints: const BoxConstraints(
                  minWidth: 30,
                  minHeight: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建图层列表
  Widget _buildLayerList() {
    final layers = controller.state.layers;

    if (layers.isEmpty) {
      return const Center(child: Text('没有图层'));
    }

    return Builder(
      builder: (BuildContext context) {
        return ReorderableListView(
          onReorder: onReorderLayer,
          children: [
            for (int i = 0; i < layers.length; i++)
              _buildLayerItem(context, layers[i], i),
          ],
        );
      },
    );
  }

  /// 构建图层工具栏
  Widget _buildLayerToolbar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '图层',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              // 添加图层按钮
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: '添加图层',
                onPressed: onAddLayer,
                iconSize: 20,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
              // 显示/隐藏所有图层
              IconButton(
                icon: const Icon(Icons.visibility),
                tooltip: '显示/隐藏所有图层',
                onPressed: () {
                  final allVisible = controller.state.layers
                      .every((layer) => layer['isVisible'] == true);

                  // 如果所有图层都可见，则隐藏所有；否则显示所有
                  for (final layer in controller.state.layers) {
                    onLayerVisibilityToggle(layer['id'], !allVisible);
                  }
                },
                iconSize: 20,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
              // 锁定/解锁所有图层
              IconButton(
                icon: const Icon(Icons.lock_outline),
                tooltip: '锁定/解锁所有图层',
                onPressed: () {
                  final allLocked = controller.state.layers
                      .every((layer) => layer['isLocked'] == true);

                  // 如果所有图层都被锁定，则解锁所有；否则锁定所有
                  for (final layer in controller.state.layers) {
                    onLayerLockToggle(layer['id'], !allLocked);
                  }
                },
                iconSize: 20,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 重命名图层
  void _renameLayer(String layerId, String newName) {
    // 通过controller更新图层名称
    controller.renameLayer(layerId, newName);
  }

  /// 显示重命名对话框
  void _showRenameDialog(
      BuildContext context, String layerId, String currentName) {
    final TextEditingController textController =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名图层'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: '图层名称',
            hintText: '输入新的图层名称',
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _renameLayer(layerId, value.trim());
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final newName = textController.text.trim();
              if (newName.isNotEmpty) {
                _renameLayer(layerId, newName);
                Navigator.of(context).pop();
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
