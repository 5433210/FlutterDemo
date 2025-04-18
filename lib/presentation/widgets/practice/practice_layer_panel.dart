import 'package:flutter/material.dart';

class PracticeLayerPanel extends StatefulWidget {
  final List<Map<String, dynamic>> layers;
  final Function(int) onLayerSelected;
  final Function(int, bool) onLayerVisibilityChanged;
  final Function(int, bool) onLayerLockChanged;
  final Function(int) onLayerDeleted;
  final Function(int, int) onLayerReordered;
  final Function(int, String) onLayerRenamed;
  final VoidCallback onAddLayer;
  final VoidCallback onDeleteAllLayers;
  final VoidCallback onShowAllLayers;

  const PracticeLayerPanel({
    super.key,
    required this.layers,
    required this.onLayerSelected,
    required this.onLayerVisibilityChanged,
    required this.onLayerLockChanged,
    required this.onLayerDeleted,
    required this.onLayerReordered,
    required this.onLayerRenamed,
    required this.onAddLayer,
    required this.onDeleteAllLayers,
    required this.onShowAllLayers,
  });

  @override
  State<PracticeLayerPanel> createState() => _PracticeLayerPanelState();
}

class _PracticeLayerPanelState extends State<PracticeLayerPanel> {
  // 编辑图层名称的控制器
  final TextEditingController _renameController = TextEditingController();
  int? _editingLayerIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 图层面板标题和操作按钮
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('图层', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: widget.onAddLayer,
                tooltip: '添加图层',
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: widget.onDeleteAllLayers,
                tooltip: '删除所有图层',
              ),
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: widget.onShowAllLayers,
                tooltip: '显示所有图层',
              ),
            ],
          ),
        ),

        // 图层列表
        Expanded(
          child: widget.layers.isEmpty
              ? const Center(child: Text('没有图层，请添加图层'))
              : ReorderableListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  onReorder: widget.onLayerReordered,
                  children: [
                    for (var i = 0; i < widget.layers.length; i++)
                      _buildLayerTile(i),
                  ],
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  /// 构建图层列表项
  Widget _buildLayerTile(int index) {
    final layer = widget.layers[index];
    final isEditing = _editingLayerIndex == index;

    return ListTile(
      key: ValueKey(layer['id']),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 可见性按钮
          IconButton(
            icon: Icon(
              layer['visible'] as bool
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: layer['visible'] as bool ? Colors.blue : Colors.grey,
            ),
            onPressed: () => widget.onLayerVisibilityChanged(
              index,
              !(layer['visible'] as bool),
            ),
            tooltip: layer['visible'] as bool ? '隐藏图层' : '显示图层',
          ),

          // 锁定按钮
          IconButton(
            icon: Icon(
              layer['locked'] as bool ? Icons.lock : Icons.lock_open,
              color: layer['locked'] as bool ? Colors.red : Colors.grey,
            ),
            onPressed: () => widget.onLayerLockChanged(
              index,
              !(layer['locked'] as bool),
            ),
            tooltip: layer['locked'] as bool ? '解锁图层' : '锁定图层',
          ),
        ],
      ),

      // 图层名称（可编辑）
      title: isEditing
          ? TextField(
              controller: _renameController,
              autofocus: true,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  widget.onLayerRenamed(index, value);
                }
                setState(() {
                  _editingLayerIndex = null;
                });
              },
            )
          : Text(
              layer['name'] as String,
              style: TextStyle(
                fontWeight: layer['selected'] as bool
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),

      // 操作按钮
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 重命名按钮
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _renameController.text = layer['name'] as String;
              setState(() {
                _editingLayerIndex = index;
              });
            },
            tooltip: '重命名图层',
          ),

          // 删除按钮
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => widget.onLayerDeleted(index),
            tooltip: '删除图层',
          ),
        ],
      ),

      selected: layer['selected'] as bool,
      selectedTileColor: Colors.blue.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
      onTap: () => widget.onLayerSelected(index),
    );
  }
}
