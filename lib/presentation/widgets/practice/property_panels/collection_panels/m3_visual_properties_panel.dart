import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../infrastructure/logging/logger.dart';
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
  final Function(String, dynamic)? onPropertyUpdateStart;
  final Function(String, dynamic)? onPropertyUpdatePreview;
  final Function(String, dynamic, dynamic)? onPropertyUpdateWithUndo;
  final Function(String, dynamic)? onContentPropertyUpdateStart;
  final Function(String, dynamic)? onContentPropertyUpdatePreview;
  final Function(String, dynamic, dynamic)? onContentPropertyUpdateWithUndo;

  const M3VisualPropertiesPanel({
    Key? key,
    required this.element,
    required this.onPropertyChanged,
    required this.onContentPropertyChanged,
    this.onPropertyUpdateStart,
    this.onPropertyUpdatePreview,
    this.onPropertyUpdateWithUndo,
    this.onContentPropertyUpdateStart,
    this.onContentPropertyUpdatePreview,
    this.onContentPropertyUpdateWithUndo,
  }) : super(key: key);

  @override
  ConsumerState<M3VisualPropertiesPanel> createState() =>
      _M3VisualPropertiesPanelState();
}

class _M3VisualPropertiesPanelState
    extends ConsumerState<M3VisualPropertiesPanel> {
  // 滑块拖动时的原始值
  double? _originalOpacity;
  double? _originalPadding;

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
                  AppLogger.debug('Setting fontColor',
                      tag: 'VisualPropertiesPanel',
                      data: {'hexColor': hexColor});
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
                  AppLogger.debug('Setting backgroundColor',
                      tag: 'VisualPropertiesPanel',
                      data: {'hexColor': hexColor});
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
                onChangeStart: (value) {
                  // 拖动开始时保存原始值
                  _originalOpacity = opacity;
                  if (widget.onPropertyUpdateStart != null) {
                    widget.onPropertyUpdateStart!('opacity', opacity);
                  }
                },
                onChanged: (value) {
                  if (widget.onPropertyUpdatePreview != null) {
                    widget.onPropertyUpdatePreview!('opacity', value);
                  } else {
                    _updatePropertyPreview('opacity', value);
                  }
                },
                onChangeEnd: (value) {
                  if (widget.onPropertyUpdateWithUndo != null) {
                    widget.onPropertyUpdateWithUndo!(
                        'opacity', value, _originalOpacity);
                  } else {
                    _updatePropertyWithUndo('opacity', value, _originalOpacity);
                  }
                  _originalOpacity = null;
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
                value: padding.clamp(0, 500),
                min: 0,
                max: 500,
                divisions: 500,
                label: '${padding.round()}px',
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                onChangeStart: (value) {
                  // 拖动开始时保存原始值
                  _originalPadding = padding;
                  if (widget.onContentPropertyUpdateStart != null) {
                    widget.onContentPropertyUpdateStart!('padding', padding);
                  }
                },
                onChanged: (value) {
                  if (widget.onContentPropertyUpdatePreview != null) {
                    widget.onContentPropertyUpdatePreview!('padding', value);
                  } else {
                    _updatePropertyPreview('padding', value);
                  }
                },
                onChangeEnd: (value) {
                  if (widget.onContentPropertyUpdateWithUndo != null) {
                    widget.onContentPropertyUpdateWithUndo!(
                        'padding', value, _originalPadding);
                  } else {
                    _updateContentPropertyWithUndo(
                        'padding', value, _originalPadding);
                  }
                  _originalPadding = null;
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
                max: 500,
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

  /// 仅预览更新属性，不记录undo（用于滑块拖动过程中的实时预览）
  void _updatePropertyPreview(String key, dynamic value) {
    // 这个组件没有访问controller，所以暂时使用setState来更新UI
    // 实际的预览功能需要在父组件中实现
    setState(() {
      // UI会根据新值重新渲染
    });
  }

  /// 基于原始值更新属性并记录undo操作（用于滑块拖动结束）
  void _updatePropertyWithUndo(
      String key, dynamic newValue, dynamic originalValue) {
    // 如果有原始值且值发生了变化，使用主面板的撤销机制
    if (originalValue != null && originalValue != newValue) {
      // 先调用开始回调保存原始值
      if (widget.onPropertyUpdateStart != null) {
        widget.onPropertyUpdateStart!(key, originalValue);
      }

      // 然后更新到最终值
      widget.onPropertyChanged(key, newValue);
    } else {
      // 值没有变化，直接更新
      widget.onPropertyChanged(key, newValue);
    }
  }

  /// 基于原始值更新内容属性并记录undo操作（用于滑块拖动结束）
  void _updateContentPropertyWithUndo(
      String key, dynamic newValue, dynamic originalValue) {
    // 如果有原始值且值发生了变化，使用主面板的撤销机制
    if (originalValue != null && originalValue != newValue) {
      // 先调用开始回调保存原始值
      if (widget.onContentPropertyUpdateStart != null) {
        widget.onContentPropertyUpdateStart!(key, originalValue);
      }

      // 然后更新到最终值
      widget.onContentPropertyChanged(key, newValue);
    } else {
      // 值没有变化，直接更新
      widget.onContentPropertyChanged(key, newValue);
    }
  }
}
