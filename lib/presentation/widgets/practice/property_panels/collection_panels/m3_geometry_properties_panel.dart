import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../common/editable_number_field.dart';

/// Material 3 Collection geometry properties panel
class M3GeometryPropertiesPanel extends StatelessWidget {
  final Map<String, dynamic> element;
  final Function(String, dynamic) onPropertyChanged;

  const M3GeometryPropertiesPanel({
    Key? key,
    required this.element,
    required this.onPropertyChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;

    return ExpansionTile(
      title: Text(
        l10n.geometryProperties,
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
              // Position (X and Y)
              Row(
                children: [
                  Expanded(
                    child: EditableNumberField(
                      label: 'X',
                      value: x,
                      suffix: 'px',
                      min: 0,
                      max: 10000,
                      onChanged: (value) => onPropertyChanged('x', value),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: EditableNumberField(
                      label: 'Y',
                      value: y,
                      suffix: 'px',
                      min: 0,
                      max: 10000,
                      onChanged: (value) => onPropertyChanged('y', value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),

              // Dimensions (Width and Height)
              Row(
                children: [
                  Expanded(
                    child: EditableNumberField(
                      label: l10n.width,
                      value: width,
                      suffix: 'px',
                      min: 10,
                      max: 10000,
                      onChanged: (value) => onPropertyChanged('width', value),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: EditableNumberField(
                      label: l10n.height,
                      value: height,
                      suffix: 'px',
                      min: 10,
                      max: 10000,
                      onChanged: (value) => onPropertyChanged('height', value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),

              // Rotation
              EditableNumberField(
                label: l10n.rotation,
                value: rotation,
                suffix: '°',
                min: -360,
                max: 360,
                decimalPlaces: 1,
                onChanged: (value) => onPropertyChanged('rotation', value),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
