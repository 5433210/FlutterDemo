import 'package:flutter/material.dart';

class PracticeLayerPanel extends StatefulWidget {
  final List<Map<String, dynamic>> layers;
  final Function(int) onLayerSelected;
  final Function(int, bool) onLayerVisibilityChanged;
  final Function(int, bool) onLayerLockChanged;
  final Function(int) onLayerDeleted;
  final Function(int, int) onLayerReordered;

  const PracticeLayerPanel({
    Key? key,
    required this.layers,
    required this.onLayerSelected,
    required this.onLayerVisibilityChanged,
    required this.onLayerLockChanged,
    required this.onLayerDeleted,
    required this.onLayerReordered,
  }) : super(key: key);

  @override
  State<PracticeLayerPanel> createState() => _PracticeLayerPanelState();
}

class _PracticeLayerPanelState extends State<PracticeLayerPanel> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('图层'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  // TODO: 添加新图层
                },
                tooltip: '添加图层',
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            onReorder: widget.onLayerReordered,
            children: [
              for (var i = 0; i < widget.layers.length; i++)
                ListTile(
                  key: ValueKey(widget.layers[i]['id']),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          widget.layers[i]['visible'] as bool
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => widget.onLayerVisibilityChanged(
                          i,
                          !(widget.layers[i]['visible'] as bool),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          widget.layers[i]['locked'] as bool
                              ? Icons.lock
                              : Icons.lock_open,
                        ),
                        onPressed: () => widget.onLayerLockChanged(
                          i,
                          !(widget.layers[i]['locked'] as bool),
                        ),
                      ),
                    ],
                  ),
                  title: Text(widget.layers[i]['name'] as String),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => widget.onLayerDeleted(i),
                  ),
                  selected: widget.layers[i]['selected'] as bool,
                  onTap: () => widget.onLayerSelected(i),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
