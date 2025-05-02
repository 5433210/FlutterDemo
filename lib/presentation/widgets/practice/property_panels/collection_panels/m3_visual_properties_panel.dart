import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../common/editable_number_field.dart';
import 'm3_collection_color_utils.dart';

/// Material 3 visual properties panel for collection content
class M3VisualPropertiesPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;
    final content = element['content'] as Map<String, dynamic>;
    final fontColor = content['fontColor'] as String? ?? '#000000';
    final backgroundColor =
        content['backgroundColor'] as String? ?? 'transparent';
    final padding = (content['padding'] as num?)?.toDouble() ?? 0.0;
    final enableSoftLineBreak =
        content['enableSoftLineBreak'] as bool? ?? false;

    return ExpansionTile(
      title: Text(
        l10n.visualSettings,
        style: textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      initiallyExpanded: true,
      collapsedIconColor: colorScheme.onSurfaceVariant,
      iconColor: colorScheme.primary,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color settings
              Text(
                '${l10n.collectionPropertyPanelColorSettings}:',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Text(
                    '${l10n.textPropertyPanelFontColor}:',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  InkWell(
                    onTap: () {
                      showColorPickerDialog(
                        context,
                        fontColor,
                        (color) {
                          onContentPropertyChanged('fontColor',
                              CollectionColorUtils.colorToHex(color));
                        },
                      );
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
                    onTap: () {
                      showColorPickerDialog(
                        context,
                        backgroundColor,
                        (color) {
                          onContentPropertyChanged('backgroundColor',
                              CollectionColorUtils.colorToHex(color));
                        },
                      );
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
              Text(
                '${l10n.opacity}:',
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
                      value: opacity,
                      min: 0.0,
                      max: 1.0,
                      divisions: 100,
                      label: '${(opacity * 100).round()}%',
                      activeColor: colorScheme.primary,
                      inactiveColor: colorScheme.surfaceContainerHighest,
                      onChanged: (value) {
                        onPropertyChanged('opacity', value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    flex: 2,
                    child: EditableNumberField(
                      label: l10n.opacity,
                      value: opacity * 100, // Convert to percentage
                      suffix: '%',
                      min: 0,
                      max: 100,
                      decimalPlaces: 0,
                      onChanged: (value) {
                        // Convert back to 0-1 range
                        onPropertyChanged('opacity', value / 100);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16.0),

              // Padding
              Text(
                '${l10n.textPropertyPanelPadding}:',
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
                      value: padding,
                      min: 0,
                      max: 50,
                      divisions: 50,
                      label: '${padding.round()}px',
                      activeColor: colorScheme.primary,
                      inactiveColor: colorScheme.surfaceContainerHighest,
                      onChanged: (value) {
                        onContentPropertyChanged('padding', value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    flex: 2,
                    child: EditableNumberField(
                      label: l10n.textPropertyPanelPadding,
                      value: padding,
                      suffix: 'px',
                      min: 0,
                      max: 100,
                      decimalPlaces: 0,
                      onChanged: (value) {
                        onContentPropertyChanged('padding', value);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16.0),

              // Auto line break
              Text(
                '${l10n.collectionPropertyPanelAutoLineBreak}:',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Switch(
                    value: enableSoftLineBreak,
                    activeColor: colorScheme.primary,
                    onChanged: (value) {
                      onContentPropertyChanged('enableSoftLineBreak', value);
                    },
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    enableSoftLineBreak
                        ? l10n.collectionPropertyPanelAutoLineBreakEnabled
                        : l10n.collectionPropertyPanelAutoLineBreakDisabled,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: l10n.collectionPropertyPanelAutoLineBreakTooltip,
                    child: Icon(
                      Icons.info_outline,
                      size: 16.0,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
