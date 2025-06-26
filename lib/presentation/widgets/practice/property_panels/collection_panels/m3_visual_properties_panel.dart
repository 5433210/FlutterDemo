import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../common/editable_number_field.dart';
import '../../../common/m3_color_picker.dart';
import '../m3_panel_styles.dart';
import 'm3_collection_color_utils.dart';

/// Material 3 visual properties panel for collection content
class M3VisualPropertiesPanel extends ConsumerStatefulWidget {
  final Map<String, dynamic> element;
  final Function(String, dynamic) onPropertyChanged;
  final Function(String, dynamic) onContentPropertyChanged;

  const M3VisualPropertiesPanel({
    Key? key,
    required this.element,
    required this.onPropertyChanged,
    required this.onContentPropertyChanged,
  }) : super(key: key);

  @override
  ConsumerState<M3VisualPropertiesPanel> createState() =>
      _M3VisualPropertiesPanelState();
}

class _M3VisualPropertiesPanelState
    extends ConsumerState<M3VisualPropertiesPanel> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final opacity = (widget.element['opacity'] as num?)?.toDouble() ?? 1.0;
    final content = widget.element['content'] as Map<String, dynamic>;
    final fontColor = content['fontColor'] as String? ?? '#000000';
    final backgroundColor =
        content['backgroundColor'] as String? ?? 'transparent';
    final padding = (content['padding'] as num?)?.toDouble() ?? 0.0;

    return M3PanelStyles.buildPersistentPanelCard(
      context: context,
      panelId: 'collection_visual_properties',
      title: l10n.visualSettings,
      defaultExpanded: true,
      children: [
        // Color settings
        M3PanelStyles.buildSectionTitle(context, l10n.colorSettings),
        Row(
          children: [
            Text(
              '${l10n.fontColor}:',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8.0),
            InkWell(
              onTap: () async {
                final color = await M3ColorPicker.show(
                  context,
                  initialColor: CollectionColorUtils.hexToColor(fontColor),
                  enableAlpha: true,
                  enableColorCode: true,
                );
                if (color != null) {
                  final hexColor = CollectionColorUtils.colorToHex(color);
                  // Setting font color - removed print statement
                  widget.onContentPropertyChanged('fontColor', hexColor);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                decoration: BoxDecoration(
                  color: CollectionColorUtils.hexToColor(fontColor),
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 40,
                height: 40,
              ),
            ),
            const SizedBox(width: 16.0),
            Text(
              '${l10n.backgroundColor}:',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8.0),
            InkWell(
              onTap: () async {
                final color = await M3ColorPicker.show(
                  context,
                  initialColor:
                      CollectionColorUtils.hexToColor(backgroundColor),
                  enableAlpha: true,
                  enableColorCode: true,
                );
                if (color != null) {
                  final hexColor = CollectionColorUtils.colorToHex(color);
                  // Setting background color - removed print statement
                  widget.onContentPropertyChanged('backgroundColor', hexColor);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                decoration: BoxDecoration(
                  color: CollectionColorUtils.hexToColor(backgroundColor),
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 40,
                height: 40,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // Opacity
        M3PanelStyles.buildSectionTitle(context, l10n.opacity),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: opacity,
                min: 0.0,
                max: 1.0,
                divisions: 100,
                label: '${(opacity * 100).round()}%',
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                onChanged: (value) {
                  widget.onPropertyChanged('opacity', value);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: l10n.opacity,
                value: opacity * 100,
                suffix: '%',
                min: 0,
                max: 100,
                decimalPlaces: 0,
                onChanged: (value) {
                  widget.onPropertyChanged('opacity', value / 100);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // Padding
        M3PanelStyles.buildSectionTitle(context, l10n.padding),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: padding,
                min: 0,
                max: 100,
                divisions: 100,
                label: '${padding.round()}px',
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                onChanged: (value) {
                  widget.onContentPropertyChanged('padding', value);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: l10n.padding,
                value: padding,
                suffix: 'px',
                min: 0,
                max: 100,
                decimalPlaces: 0,
                onChanged: (value) {
                  widget.onContentPropertyChanged('padding', value);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),
      ],
    );
  }
}
