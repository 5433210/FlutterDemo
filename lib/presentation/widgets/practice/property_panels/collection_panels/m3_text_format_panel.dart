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

    final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 100.0;
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
                value: fontSize.clamp(10, 500), // Clamp for slider range
                min: 10,
                max: 500, // Slider max 500 for usability, but input field allows up to 2000
                divisions: 490,
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
                min: 10,
                max: 2000,
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

        // Horizontal alignment - using Card with IconButtons like text panel
        Text(
          '${l10n.textPropertyPanelTextAlign}:',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Left align
                Tooltip(
                  message: l10n.alignLeft,
                  child: IconButton(
                    icon: const Icon(Icons.format_align_left),
                    isSelected: textAlign == 'left',
                    selectedIcon: Icon(Icons.format_align_left,
                        color: colorScheme.primary),
                    onPressed: () {
                      onContentPropertyChanged('textAlign', 'left');
                    },
                  ),
                ),
                // Center align
                Tooltip(
                  message: l10n.alignCenter,
                  child: IconButton(
                    icon: const Icon(Icons.format_align_center),
                    isSelected: textAlign == 'center',
                    selectedIcon: Icon(Icons.format_align_center,
                        color: colorScheme.primary),
                    onPressed: () {
                      onContentPropertyChanged('textAlign', 'center');
                    },
                  ),
                ),
                // Right align
                Tooltip(
                  message: l10n.alignRight,
                  child: IconButton(
                    icon: const Icon(Icons.format_align_right),
                    isSelected: textAlign == 'right',
                    selectedIcon: Icon(Icons.format_align_right,
                        color: colorScheme.primary),
                    onPressed: () {
                      onContentPropertyChanged('textAlign', 'right');
                    },
                  ),
                ),
                // Justify
                Tooltip(
                  message: l10n.distribution,
                  child: IconButton(
                    icon: const Icon(Icons.format_align_justify),
                    isSelected: textAlign == 'justify',
                    selectedIcon: Icon(Icons.format_align_justify,
                        color: colorScheme.primary),
                    onPressed: () {
                      onContentPropertyChanged('textAlign', 'justify');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16.0),

        // Vertical alignment - using Card with IconButtons like text panel
        Text(
          '${l10n.textPropertyPanelVerticalAlign}:',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Top align
                Tooltip(
                  message: l10n.alignTop,
                  child: IconButton(
                    icon: const Icon(Icons.vertical_align_top),
                    isSelected: verticalAlign == 'top',
                    selectedIcon: Icon(Icons.vertical_align_top,
                        color: colorScheme.primary),
                    onPressed: () {
                      onContentPropertyChanged('verticalAlign', 'top');
                    },
                  ),
                ),
                // Middle align
                Tooltip(
                  message: l10n.alignMiddle,
                  child: IconButton(
                    icon: const Icon(Icons.vertical_align_center),
                    isSelected: verticalAlign == 'middle',
                    selectedIcon: Icon(Icons.vertical_align_center,
                        color: colorScheme.primary),
                    onPressed: () {
                      onContentPropertyChanged('verticalAlign', 'middle');
                    },
                  ),
                ),
                // Bottom align
                Tooltip(
                  message: l10n.alignBottom,
                  child: IconButton(
                    icon: const Icon(Icons.vertical_align_bottom),
                    isSelected: verticalAlign == 'bottom',
                    selectedIcon: Icon(Icons.vertical_align_bottom,
                        color: colorScheme.primary),
                    onPressed: () {
                      onContentPropertyChanged('verticalAlign', 'bottom');
                    },
                  ),
                ),
                // Justify
                Tooltip(
                  message: l10n.distribution,
                  child: IconButton(
                    icon: const Icon(Icons.height),
                    isSelected: verticalAlign == 'justify',
                    selectedIcon:
                        Icon(Icons.height, color: colorScheme.primary),
                    onPressed: () {
                      onContentPropertyChanged('verticalAlign', 'justify');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16.0),

        // Writing direction - using Card with IconButtons like text panel
        Text(
          '${l10n.textPropertyPanelWritingMode}:',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Horizontal Left-to-Right
                Tooltip(
                  message: l10n.horizontalLeftToRight,
                  child: IconButton(
                    icon: const Icon(Icons.format_textdirection_l_to_r),
                    isSelected: writingMode == 'horizontal-l',
                    selectedIcon: Icon(Icons.format_textdirection_l_to_r,
                        color: colorScheme.primary),
                    onPressed: () {
                      onContentPropertyChanged('writingMode', 'horizontal-l');
                    },
                  ),
                ),
                // Vertical Right-to-Left
                Tooltip(
                  message: l10n.verticalRightToLeft,
                  child: IconButton(
                    icon: const Icon(Icons.format_textdirection_r_to_l),
                    isSelected: writingMode == 'vertical-r',
                    selectedIcon: Icon(Icons.format_textdirection_r_to_l,
                        color: colorScheme.primary),
                    onPressed: () {
                      onContentPropertyChanged('writingMode', 'vertical-r');
                    },
                  ),
                ),
                // Horizontal Right-to-Left
                Tooltip(
                  message: l10n.horizontalRightToLeft,
                  child: IconButton(
                    icon: const Icon(Icons.format_textdirection_r_to_l),
                    isSelected: writingMode == 'horizontal-r',
                    selectedIcon: Icon(Icons.format_textdirection_r_to_l,
                        color: colorScheme.primary),
                    onPressed: () {
                      onContentPropertyChanged('writingMode', 'horizontal-r');
                    },
                  ),
                ),
                // Vertical Left-to-Right
                Tooltip(
                  message: l10n.verticalLeftToRight,
                  child: IconButton(
                    icon: const Icon(Icons.format_textdirection_l_to_r),
                    isSelected: writingMode == 'vertical-l',
                    selectedIcon: Icon(Icons.format_textdirection_l_to_r,
                        color: colorScheme.primary),
                    onPressed: () {
                      onContentPropertyChanged('writingMode', 'vertical-l');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
