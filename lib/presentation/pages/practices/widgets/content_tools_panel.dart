import 'package:flutter/material.dart';

import '../../../widgets/practice/practice_edit_controller.dart';

/// Widget for content tools panel
class ContentToolsPanel extends StatelessWidget {
  final PracticeEditController controller;
  final String currentTool;
  final Function(String) onToolSelected;

  const ContentToolsPanel({
    super.key,
    required this.controller,
    required this.currentTool,
    required this.onToolSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Elements',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              _buildDraggableToolButton(
                icon: Icons.text_fields,
                label: 'Text',
                toolName: 'text',
                elementType: 'text',
              ),
              _buildDraggableToolButton(
                icon: Icons.image,
                label: 'Image',
                toolName: 'image',
                elementType: 'image',
              ),
              _buildDraggableToolButton(
                icon: Icons.grid_on,
                label: 'Collection',
                toolName: 'collection',
                elementType: 'collection',
              ),
              _buildToolButton(
                icon: Icons.select_all,
                label: 'Select',
                toolName: 'select',
                onPressed: () {
                  onToolSelected('select');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build a draggable tool button
  Widget _buildDraggableToolButton({
    required IconData icon,
    required String label,
    required String toolName,
    required String elementType,
  }) {
    return Draggable<String>(
      // Drag data is element type
      data: elementType,
      // Widget shown while dragging
      feedback: Material(
        elevation: 4.0,
        child: Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(204), // 0.8 opacity
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24.0),
              const SizedBox(height: 4.0),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
      ),
      // Widget shown at original position during drag
      childWhenDragging: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.5,
          child: _buildToolButton(
            icon: icon,
            label: label,
            toolName: toolName,
            onPressed: () {}, // Disable click during drag
          ),
        ),
      ),
      // Original widget
      child: _buildToolButton(
        icon: icon,
        label: label,
        toolName: toolName,
        onPressed: () {
          onToolSelected(toolName);
          // Add corresponding element type when clicked
          switch (elementType) {
            case 'text':
              controller.addTextElement();
              break;
            case 'image':
              // Directly add empty image element without dialog
              controller.addEmptyImageElementAt(100.0, 100.0);
              break;
            case 'collection':
              // Directly add empty collection element without dialog
              controller.addEmptyCollectionElementAt(100.0, 100.0);
              break;
          }
        },
      ),
    );
  }

  /// Build a tool button
  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required String toolName,
    required VoidCallback onPressed,
  }) {
    final isSelected = currentTool == toolName;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4.0),
        child: Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withAlpha(26) : null, // 0.1 opacity
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.blue : null,
                size: 24.0,
              ),
              const SizedBox(height: 4.0),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blue : null,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
