import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../common/editable_number_field.dart';
import '../m3_panel_styles.dart';
import 'm3_collection_color_utils.dart';

// 简单的颜色选择器组件
class ColorPicker extends StatefulWidget {
  final Color color;
  final Function(Color) onColorChanged;

  const ColorPicker({
    Key? key,
    required this.color,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

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

    return M3PanelStyles.buildPanelCard(
      context: context,
      title: l10n.visualSettings,
      initiallyExpanded: true,
      children: [
        // Color settings
        M3PanelStyles.buildSectionTitle(
            context, l10n.collectionPropertyPanelColorSettings),
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
                    onContentPropertyChanged(
                        'fontColor', CollectionColorUtils.colorToHex(color));
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
        M3PanelStyles.buildSectionTitle(context, l10n.textPropertyPanelPadding),
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
        M3PanelStyles.buildSectionTitle(
            context, l10n.collectionPropertyPanelAutoLineBreak),
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
    );
  }

  // 显示颜色选择器对话框
  void showColorPickerDialog(
    BuildContext context,
    String initialColor,
    Function(Color) onColorSelected,
  ) {
    final Color color = CollectionColorUtils.hexToColor(initialColor);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择颜色'), // 使用硬编码文本，因为本地化字符串尚未定义
        content: SingleChildScrollView(
          child: ColorPicker(
            color: color,
            onColorChanged: onColorSelected,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'), // 使用硬编码文本，因为本地化字符串尚未定义
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'), // 使用硬编码文本，因为本地化字符串尚未定义
          ),
        ],
      ),
    );
  }
}

class _ColorPickerState extends State<ColorPicker> {
  late Color _currentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 当前颜色预览
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: _currentColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline),
          ),
        ),
        const SizedBox(height: 16),

        // 预设颜色
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildColorButton(Colors.black),
            _buildColorButton(Colors.white),
            _buildColorButton(Colors.red),
            _buildColorButton(Colors.pink),
            _buildColorButton(Colors.purple),
            _buildColorButton(Colors.deepPurple),
            _buildColorButton(Colors.indigo),
            _buildColorButton(Colors.blue),
            _buildColorButton(Colors.lightBlue),
            _buildColorButton(Colors.cyan),
            _buildColorButton(Colors.teal),
            _buildColorButton(Colors.green),
            _buildColorButton(Colors.lightGreen),
            _buildColorButton(Colors.lime),
            _buildColorButton(Colors.yellow),
            _buildColorButton(Colors.amber),
            _buildColorButton(Colors.orange),
            _buildColorButton(Colors.deepOrange),
            _buildColorButton(Colors.brown),
            _buildColorButton(Colors.grey),
            _buildColorButton(Colors.blueGrey),
            _buildColorButton(Colors.transparent),
          ],
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _currentColor = widget.color;
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _currentColor == color;
    final isTransparent = color == Colors.transparent;

    return InkWell(
      onTap: () {
        setState(() {
          _currentColor = color;
        });
        widget.onColorChanged(color);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isTransparent
            ? const Icon(Icons.block, color: Colors.red)
            : isSelected
                ? Icon(
                    Icons.check,
                    color: color.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                  )
                : null,
      ),
    );
  }
}
