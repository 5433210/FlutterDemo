import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../common/editable_number_field.dart';

/// Material 3 Text format panel for collection elements
class M3TextFormatPanel extends StatelessWidget {
  final Map<String, dynamic> content;
  final Function(String, dynamic) onContentPropertyChanged;

  const M3TextFormatPanel({
    Key? key,
    required this.content,
    required this.onContentPropertyChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 36.0;
    final lineSpacing = (content['lineSpacing'] as num?)?.toDouble() ?? 10.0;
    final letterSpacing = (content['letterSpacing'] as num?)?.toDouble() ?? 5.0;
    final textAlign = content['textAlign'] as String? ?? 'left';
    final verticalAlign = content['verticalAlign'] as String? ?? 'top';
    final writingMode = content['writingMode'] as String? ?? 'horizontal-l';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Font size
        Text(
          '${l10n.textPropertyPanelFontSize}:',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: fontSize,
                min: 1,
                max: 100,
                divisions: 99,
                label: '${fontSize.round()}px',
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                onChanged: (value) {
                  onContentPropertyChanged('fontSize', value);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: l10n.textPropertyPanelFontSize,
                value: fontSize,
                suffix: 'px',
                min: 1,
                max: 200,
                onChanged: (value) {
                  onContentPropertyChanged('fontSize', value);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // Letter spacing
        Text(
          '${l10n.textPropertyPanelLetterSpacing}:',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: letterSpacing,
                min: 0,
                max: 50,
                divisions: 50,
                label: '${letterSpacing.round()}px',
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                onChanged: (value) {
                  onContentPropertyChanged('letterSpacing', value);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: l10n.textPropertyPanelLetterSpacing,
                value: letterSpacing,
                suffix: 'px',
                min: 0,
                max: 100,
                decimalPlaces: 1,
                onChanged: (value) {
                  onContentPropertyChanged('letterSpacing', value);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // Line spacing
        Text(
          '${l10n.textPropertyPanelLineHeight}:',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: lineSpacing,
                min: 0,
                max: 50,
                divisions: 50,
                label: '${lineSpacing.round()}px',
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                onChanged: (value) {
                  onContentPropertyChanged('lineSpacing', value);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: l10n.textPropertyPanelLineHeight,
                value: lineSpacing,
                suffix: 'px',
                min: 0,
                max: 100,
                decimalPlaces: 1,
                onChanged: (value) {
                  onContentPropertyChanged('lineSpacing', value);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // Horizontal alignment
        Text(
          '${l10n.textPropertyPanelTextAlign}:',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: 'left',
                icon: const Icon(Icons.align_horizontal_left),
                tooltip: l10n.alignLeft,
              ),
              ButtonSegment<String>(
                value: 'center',
                icon: const Icon(Icons.align_horizontal_center),
                tooltip: l10n.alignCenter,
              ),
              ButtonSegment<String>(
                value: 'right',
                icon: const Icon(Icons.align_horizontal_right),
                tooltip: l10n.alignRight,
              ),
              ButtonSegment<String>(
                value: 'justify',
                icon: const Icon(Icons.format_align_justify),
                tooltip: l10n.distributeHorizontally,
              ),
            ],
            selected: {textAlign},
            onSelectionChanged: (Set<String> newSelection) {
              if (newSelection.isNotEmpty) {
                onContentPropertyChanged('textAlign', newSelection.first);
              }
            },
          ),
        ),

        const SizedBox(height: 16.0),

        // Vertical alignment
        Text(
          '${l10n.textPropertyPanelVerticalAlign}:',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: 'top',
                icon: const Icon(Icons.vertical_align_top),
                tooltip: l10n.alignTop,
              ),
              ButtonSegment<String>(
                value: 'middle',
                icon: const Icon(Icons.vertical_align_center),
                tooltip: l10n.alignMiddle,
              ),
              ButtonSegment<String>(
                value: 'bottom',
                icon: const Icon(Icons.vertical_align_bottom),
                tooltip: l10n.alignBottom,
              ),
              ButtonSegment<String>(
                value: 'justify',
                icon: const Icon(Icons.format_align_justify),
                tooltip: l10n.distributeVertically,
              ),
            ],
            selected: {verticalAlign},
            onSelectionChanged: (Set<String> newSelection) {
              if (newSelection.isNotEmpty) {
                onContentPropertyChanged('verticalAlign', newSelection.first);
              }
            },
          ),
        ),

        const SizedBox(height: 16.0),

        // Writing direction
        Text(
          '${l10n.textPropertyPanelWritingMode}:',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            _buildWritingModeButton(
              context: context,
              mode: 'horizontal-l',
              label: l10n.horizontalLeftToRight,
              currentMode: writingMode,
              icon: Icons.format_textdirection_l_to_r,
            ),
            _buildWritingModeButton(
              context: context,
              mode: 'vertical-r',
              label: l10n.verticalRightToLeft,
              currentMode: writingMode,
              icon: Icons.format_textdirection_r_to_l,
            ),
            _buildWritingModeButton(
              context: context,
              mode: 'horizontal-r',
              label: l10n.horizontalRightToLeft,
              currentMode: writingMode,
              icon: Icons.keyboard_double_arrow_left,
            ),
            _buildWritingModeButton(
              context: context,
              mode: 'vertical-l',
              label: l10n.verticalLeftToRight,
              currentMode: writingMode,
              icon: Icons.keyboard_double_arrow_right,
            ),
          ],
        ),
      ],
    );
  }

  /// Build a writing mode button with Material 3 styling
  Widget _buildWritingModeButton({
    required BuildContext context,
    required String mode,
    required String label,
    required String currentMode,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = currentMode == mode;

    return FilledButton.tonalIcon(
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: isSelected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        foregroundColor: isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
      ),
      onPressed: () {
        onContentPropertyChanged('writingMode', mode);
      },
    );
  }
}
