import 'package:flutter/material.dart';

import 'content_tools_panel.dart';
import 'practice_layer_panel.dart';

/// 左侧面板
class LeftPanel extends StatelessWidget {
  final String currentTool;
  final Function(String) onToolSelected;
  final VoidCallback onAddTextElement;
  final Function(String) onAddCollectionElement;
  final Function(String) onAddImageElement;
  final List<Map<String, dynamic>> layers;
  final Function(String) onLayerSelected;
  final Function(String, bool) onLayerVisibilityChanged;
  final Function(String, bool) onLayerLockChanged;
  final Function(String) onLayerDeleted;
  final Function(int, int) onLayerReordered;
  final Function(String, String) onLayerRenamed;
  final VoidCallback onAddLayer;
  final VoidCallback onDeleteAllLayers;
  final VoidCallback onShowAllLayers;
  final dynamic controller; // Add controller property

  const LeftPanel({
    Key? key,
    required this.currentTool,
    required this.onToolSelected,
    required this.onAddTextElement,
    required this.onAddCollectionElement,
    required this.onAddImageElement,
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
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          // 内容工具面板
          ContentToolsPanel(
            currentTool: currentTool,
            onToolSelected: onToolSelected,
            onAddTextElement: onAddTextElement,
            onAddCollectionElement: onAddCollectionElement,
            onAddImageElement: onAddImageElement,
          ),
          Expanded(
            child: PracticeLayerPanel(
              controller: controller, // Use the provided controller
              onLayerSelect: onLayerSelected,
              onLayerVisibilityToggle: onLayerVisibilityChanged,
              onLayerLockToggle: onLayerLockChanged,
              onDeleteLayer: onLayerDeleted,
              onReorderLayer: onLayerReordered,
              onAddLayer: onAddLayer,
            ),
          ),
        ],
      ),
    );
  }
}
