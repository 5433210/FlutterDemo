/// Canvas图层属性面板 - Phase 2.2
///
/// 注意：当前Canvas系统不支持图层管理，此面板作为占位符
/// 实际功能通过ElementPropertyPanel处理
library;

import 'package:flutter/material.dart';

import '../../../core/canvas_state_manager.dart';
import '../property_panel.dart';
import '../property_panel_controller.dart';

/// 图层属性面板 (占位符 - 系统当前不支持图层)
class LayerPropertyPanel extends StatefulWidget {
  final CanvasStateManager stateManager;
  final PropertyPanelController controller;
  final PropertyPanelStyle style;
  final Function(String, Map<String, dynamic>) onPropertyChanged;

  const LayerPropertyPanel({
    super.key,
    required this.stateManager,
    required this.controller,
    this.style = PropertyPanelStyle.modern,
    required this.onPropertyChanged,
  });

  @override
  State<LayerPropertyPanel> createState() => _LayerPropertyPanelState();
}

class _LayerPropertyPanelState extends State<LayerPropertyPanel> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.layers_outlined,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                '图层功能',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '当前Canvas系统不支持图层管理功能。\n'
                '请使用元素属性面板来管理画布内容。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      // 切换到元素选择模式
                      widget.stateManager.selectionState.clearSelection();
                    },
                    icon: const Icon(Icons.select_all),
                    label: const Text('管理元素'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
