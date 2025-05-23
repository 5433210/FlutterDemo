import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../widgets/practice/practice_edit_controller.dart';

/// Material 3 widget for content tools panel
class M3ContentToolsPanel extends StatelessWidget {
  final PracticeEditController controller;
  final String currentTool;
  final Function(String) onToolSelected;

  const M3ContentToolsPanel({
    super.key,
    required this.controller,
    required this.currentTool,
    required this.onToolSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              l10n.practiceEditElements,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: [
              _buildDraggableToolButton(
                context: context,
                icon: Icons.text_fields,
                label: l10n.practiceEditText,
                toolName: 'text',
                elementType: 'text',
                colorScheme: colorScheme,
              ),
              _buildDraggableToolButton(
                context: context,
                icon: Icons.image,
                label: l10n.practiceEditImage,
                toolName: 'image',
                elementType: 'image',
                colorScheme: colorScheme,
              ),
              _buildDraggableToolButton(
                context: context,
                icon: Icons.grid_on,
                label: l10n.practiceEditCollection,
                toolName: 'collection',
                elementType: 'collection',
                colorScheme: colorScheme,
              ),
              _buildToolButton(
                context: context,
                icon: Icons.select_all,
                label: l10n.practiceEditSelect,
                toolName: 'select',
                onPressed: () {
                  onToolSelected('select');
                },
                colorScheme: colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build a draggable tool button
  Widget _buildDraggableToolButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String toolName,
    required String elementType,
    required ColorScheme colorScheme,
  }) {
    return Draggable<String>(
      // Drag data is element type
      data: elementType,
      // Widget shown while dragging
      feedback: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colorScheme.onPrimaryContainer, size: 24.0),
              const SizedBox(height: 8.0),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
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
            context: context,
            icon: icon,
            label: label,
            toolName: toolName,
            onPressed: () {}, // Disable click during drag
            colorScheme: colorScheme,
          ),
        ),
      ),
      // Original widget
      child: _buildToolButton(
        context: context,
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
        colorScheme: colorScheme,
      ),
    );
  }

  /// Build a tool button
  Widget _buildToolButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String toolName,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    final isSelected = currentTool == toolName;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer.withOpacity(0.7) : colorScheme.surfaceContainerLow,
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 24.0,
              ),
              const SizedBox(height: 8.0),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
