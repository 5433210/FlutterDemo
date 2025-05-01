import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import 'practice_edit_controller.dart';
import 'property_panels/m3_practice_property_panels.dart';
import 'property_panels/practice_property_panels.dart';

/// Material 3 property panel for practice edit page
class M3PracticePropertyPanel extends ConsumerStatefulWidget {
  final PracticeEditController controller;

  const M3PracticePropertyPanel({
    super.key,
    required this.controller,
  });

  @override
  ConsumerState<M3PracticePropertyPanel> createState() =>
      _M3PracticePropertyPanelState();
}

class _M3PracticePropertyPanelState
    extends ConsumerState<M3PracticePropertyPanel> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panel header
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: Text(
            l10n.practiceEditPropertyPanel,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Panel content
        Expanded(
          child: _buildPropertyPanelContent(context, ref),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Add listener to controller to rebuild when selection changes
    widget.controller.addListener(_onControllerChanged);
  }

  /// Build an empty panel with a message
  Widget _buildEmptyPanel(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build property panel content based on selection
  Widget _buildPropertyPanelContent(BuildContext context, WidgetRef ref) {
    final selectedElementIds = widget.controller.state.selectedElementIds;
    final colorScheme = Theme.of(context).colorScheme;

    // Use existing property panels but wrap them in Material 3 styling
    Widget panel;

    if (selectedElementIds.isEmpty) {
      // Show page properties when no element is selected
      panel = M3PagePropertyPanel(
        controller: widget.controller,
        page: widget.controller.state.currentPage,
        onPagePropertiesChanged: (properties) {
          if (widget.controller.state.currentPageIndex >= 0) {
            widget.controller.updatePageProperties(properties);
          }
        },
      );
    } else if (selectedElementIds.length == 1) {
      // Show element-specific properties when one element is selected
      final id = selectedElementIds.first;
      final element = widget.controller.state.currentPageElements.firstWhere(
        (e) => e['id'] == id,
        orElse: () => <String, dynamic>{},
      );

      if (element.isNotEmpty) {
        switch (element['type']) {
          case 'text':
            // Temporarily use existing panel until M3 version is implemented
            panel = PracticePropertyPanel.forText(
              controller: widget.controller,
              element: element,
              onElementPropertiesChanged: (properties) {
                widget.controller.updateElementProperties(id, properties);
              },
            );
            break;
          case 'image':
            // Temporarily use existing panel until M3 version is implemented
            panel = PracticePropertyPanel.forImage(
              controller: widget.controller,
              element: element,
              onElementPropertiesChanged: (properties) {
                widget.controller.updateElementProperties(id, properties);
              },
              onSelectImage: () async {
                // Implement image selection logic
                // This would typically show a dialog to select an image
              },
              ref: ref,
            );
            break;
          case 'collection':
            // Temporarily use existing panel until M3 version is implemented
            panel = PracticePropertyPanel.forCollection(
              controller: widget.controller,
              element: element,
              onElementPropertiesChanged: (properties) {
                widget.controller.updateElementProperties(id, properties);
              },
              onUpdateChars: (chars) {
                // Get the current content map
                final content = Map<String, dynamic>.from(
                    element['content'] as Map<String, dynamic>);
                // Update the characters property
                content['characters'] = chars;
                // Update the element with the modified content map
                final updatedProps = {'content': content};
                widget.controller.updateElementProperties(id, updatedProps);
              },
              ref: ref,
            );
            break;
          case 'group':
            // Temporarily use existing panel until M3 version is implemented
            panel = PracticePropertyPanel.forGroup(
              controller: widget.controller,
              element: element,
              onElementPropertiesChanged: (properties) {
                widget.controller.updateElementProperties(id, properties);
              },
            );
            break;
          default:
            panel = _buildEmptyPanel(
                context, 'Unsupported element type: ${element['type']}');
        }
      } else {
        panel = _buildEmptyPanel(context, 'Element not found');
      }
    } else {
      // Show multi-selection properties when multiple elements are selected
      // Temporarily use existing panel until M3 version is implemented
      panel = PracticePropertyPanel.forMultiSelection(
        controller: widget.controller,
        selectedIds: selectedElementIds,
        onElementPropertiesChanged: (properties) {
          // Apply properties to all selected elements
          for (final id in selectedElementIds) {
            widget.controller.updateElementProperties(id, properties);
          }
        },
      );
    }

    // Wrap the existing panel in Material 3 styling
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: panel,
    );
  }

  // Controller change callback
  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }
}
