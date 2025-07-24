import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../common/editable_number_field.dart';
import '../../common/m3_color_picker.dart';
import '../practice_edit_controller.dart';
import 'm3_element_common_property_panel.dart';
import 'm3_layer_info_panel.dart';
import 'm3_panel_styles.dart';
import 'm3_practice_property_panel_base.dart';

// 列数据类，用于存储列的Widget和字符
class ColumnData {
  final Widget widget;
  final List<String> chars;

  ColumnData(this.widget, this.chars);
}

/// 文本内容属性面板
class M3TextPropertyPanel extends M3PracticePropertyPanel {
  // 文本控制器静态变量
  static final TextEditingController _textController = TextEditingController();

  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;

  const M3TextPropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final layerId = element['layerId'] as String?;

    // 获取图层信息
    Map<String, dynamic>? layer;
    if (layerId != null) {
      layer = controller.state.getLayerById(layerId);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: [
        // 基本属性面板 (放在最前面)
        M3ElementCommonPropertyPanel(
          element: element,
          onElementPropertiesChanged: onElementPropertiesChanged,
          controller: controller,
        ),

        // 图层信息
        M3LayerInfoPanel(layer: layer), // 几何属性部分
        M3PanelStyles.buildPersistentPanelCard(
          context: context,
          panelId: 'text_geometry_properties',
          title: l10n.geometryProperties,
          defaultExpanded: true,
          children: _buildGeometryPropertiesPanelList(context),
        ),

        // 视觉属性部分
        M3PanelStyles.buildPersistentPanelCard(
          context: context,
          panelId: 'text_visual_settings',
          title: l10n.visualSettings,
          defaultExpanded: true,
          children: _buildVisualPropertiesPanelList(context),
        ),

        // 文本设置部分
        M3PanelStyles.buildPersistentPanelCard(
          context: context,
          panelId: 'text_settings',
          title: l10n.textSettings,
          defaultExpanded: true,
          children: _buildTextSettingsPanelList(context),
        ),
      ],
    );
  }

  // 构建字重按钮
  Widget _buildFontWeightButton(BuildContext context, String weight,
      String label, String currentFontWeight) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = currentFontWeight == weight;

    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        backgroundColor: isSelected
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        foregroundColor:
            isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
      ),
      onPressed: () {
        _updateContentProperty('fontWeight', weight);
      },
      child: Text(label),
    );
  }

  // 构建几何属性面板
  Widget _buildGeometryPropertiesPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 位置设置
        M3PanelStyles.buildSectionTitle(context, l10n.position),
        Row(
          children: [
            Expanded(
              child: EditableNumberField(
                label: 'X',
                value: x,
                suffix: 'px',
                min: 0,
                max: 10000,
                onChanged: (value) => _updateProperty('x', value),
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
                onChanged: (value) => _updateProperty('y', value),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // 尺寸设置
        M3PanelStyles.buildSectionTitle(context, l10n.dimensions),
        Row(
          children: [
            Expanded(
              child: EditableNumberField(
                label: l10n.width,
                value: width,
                suffix: 'px',
                min: 10,
                max: 10000,
                onChanged: (value) => _updateProperty('width', value),
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
                onChanged: (value) => _updateProperty('height', value),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // 旋转设置
        M3PanelStyles.buildSectionTitle(context, l10n.rotation),
        EditableNumberField(
          label: l10n.rotation,
          value: rotation,
          suffix: '°',
          min: -360,
          max: 360,
          decimalPlaces: 1,
          onChanged: (value) => _updateProperty('rotation', value),
        ),
      ],
    );
  }

  // 将几何属性面板内容转换为列表
  List<Widget> _buildGeometryPropertiesPanelList(BuildContext context) {
    final Widget panel = _buildGeometryPropertiesPanel(context);
    if (panel is Column) {
      return panel.children;
    }
    return [panel];
  }

  // 辅助方法：构建文本内容输入字段
  Widget _buildTextContentField(String initialText, BuildContext context) {
    // 确保控制器内容与初始文本一致
    if (_textController.text != initialText) {
      _textController.text = initialText;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _textController,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(128),
      ),
      keyboardType: TextInputType.multiline,
      maxLines: 5,
      minLines: 3,
      onChanged: (value) {
        _updateContentProperty('text', value);
      },
    );
  }

  // 构建文本设置面板
  Widget _buildTextSettingsPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    // 文本特有属性
    final content = element['content'] as Map<String, dynamic>? ?? {};
    final text = content['text'] as String? ?? '';
    final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 100.0;
    final fontFamily = content['fontFamily'] as String? ?? 'sans-serif';
    final fontWeight = content['fontWeight'] as String? ?? 'normal';
    final fontStyle = content['fontStyle'] as String? ?? 'normal';
    final fontColor = content['fontColor'] as String? ?? '#000000';
    final backgroundColor =
        content['backgroundColor'] as String? ?? 'transparent';
    final textAlign = content['textAlign'] as String? ?? 'left';
    final verticalAlign = content['verticalAlign'] as String? ?? 'top';
    final letterSpacing = (content['letterSpacing'] as num?)?.toDouble() ?? 0.0;
    final lineHeight = (content['lineHeight'] as num?)?.toDouble() ?? 1.2;
    final underline = content['underline'] as bool? ?? false;
    final lineThrough = content['lineThrough'] as bool? ?? false;
    final writingMode = content['writingMode'] as String? ?? 'horizontal-l';

    // 颜色转换
    Color getFontColor() {
      try {
        return Color(int.parse(fontColor.replaceFirst('#', '0xFF')));
      } catch (e) {
        return Colors.black;
      }
    }

    Color getBackgroundColor() {
      if (backgroundColor == 'transparent') {
        return Colors.transparent;
      }
      try {
        return Color(int.parse(backgroundColor.replaceFirst('#', '0xFF')));
      } catch (e) {
        return Colors.transparent;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 文本内容
        M3PanelStyles.buildSectionTitle(context, l10n.textContent),
        _buildTextContentField(text, context),

        const SizedBox(height: 16.0),

        // 字体设置
        M3PanelStyles.buildSectionTitle(context, l10n.fontFamily),

        // 字号设置
        M3PanelStyles.buildSectionTitle(context, l10n.fontSize),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: fontSize,
                min: 1,
                max: 500,
                divisions: 99,
                label: '${fontSize.round()}px',
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                thumbColor: colorScheme.primary,
                onChanged: (value) {
                  _updateContentProperty('fontSize', value);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: l10n.fontSize,
                value: fontSize,
                suffix: 'px',
                min: 1,
                max: 500,
                onChanged: (value) {
                  _updateContentProperty('fontSize', value);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // 字体颜色和背景颜色
        Row(
          children: [
            // 字体颜色选择器
            Tooltip(
              message: l10n.fontColor,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: getFontColor(),
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.0),
                    onTap: () async {
                      final color = await M3ColorPicker.show(
                        context,
                        initialColor: getFontColor(),
                        enableAlpha: true,
                        enableColorCode: true,
                      );
                      if (color != null) {
                        if (color == Colors.transparent) {
                          _updateContentProperty('fontColor', 'transparent');
                        } else {
                          // Convert color to hex string
                          final r =
                              color.r.toInt().toRadixString(16).padLeft(2, '0');
                          final g =
                              color.g.toInt().toRadixString(16).padLeft(2, '0');
                          final b =
                              color.b.toInt().toRadixString(16).padLeft(2, '0');
                          final hexColor = '#$r$g$b';
                          _updateContentProperty('fontColor', hexColor);
                        }
                      }
                    },
                    child: Icon(
                      Icons.format_color_text,
                      color: getFontColor().computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0), // 背景颜色选择器
            Tooltip(
              message: l10n.backgroundColor,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: getBackgroundColor(),
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(12.0),
                  // 添加棋盘格背景以便显示透明色
                  image: backgroundColor == 'transparent'
                      ? const DecorationImage(
                          image: AssetImage('assets/images/transparent_bg.png'),
                          repeat: ImageRepeat.repeat,
                        )
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.0),
                    onTap: () async {
                      final color = await M3ColorPicker.show(
                        context,
                        initialColor: getBackgroundColor(),
                        enableAlpha: true,
                        enableColorCode: true,
                      );

                      if (color != null) {
                        if (color == Colors.transparent) {
                          _updateContentProperty(
                              'backgroundColor', 'transparent');
                        } else {
                          // Convert color to hex string
                          final r =
                              color.r.toInt().toRadixString(16).padLeft(2, '0');
                          final g =
                              color.g.toInt().toRadixString(16).padLeft(2, '0');
                          final b =
                              color.b.toInt().toRadixString(16).padLeft(2, '0');
                          final hexColor = '#$r$g$b';
                          _updateContentProperty('backgroundColor', hexColor);
                        }
                      }
                    },
                    child: Icon(
                      Icons.format_color_fill,
                      color: getBackgroundColor().computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8.0),

        // 字体族设置
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: l10n.fontFamily,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                ),
                value: fontFamily,
                isExpanded: true,
                items: [
                  // System fonts
                  DropdownMenuItem(
                      value: 'sans-serif', child: Text(l10n.sansSerif)),
                  DropdownMenuItem(value: 'serif', child: Text(l10n.serif)),
                  DropdownMenuItem(
                      value: 'monospace', child: Text(l10n.monospace)),
                  // Chinese fonts (Free for Commercial Use)
                  DropdownMenuItem(
                      value: 'SourceHanSans',
                      child:
                          Text(AppLocalizations.of(context).sourceHanSansFont)),
                  DropdownMenuItem(
                      value: 'SourceHanSerif',
                      child: Text(
                          AppLocalizations.of(context).sourceHanSerifFont)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _updateContentProperty('fontFamily', value);
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // 字重设置
        M3PanelStyles.buildSectionTitle(context, l10n.fontWeight),

        // 字重滑块（针对思源字体优化）
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 字重预设按钮
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _buildFontWeightButton(context, 'w300', 'Light', fontWeight),
                _buildFontWeightButton(
                    context, 'normal', 'Regular', fontWeight),
                _buildFontWeightButton(context, 'bold', 'Bold', fontWeight),
              ],
            ),

            const SizedBox(height: 12.0),

            // 字重滑块
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Slider(
                    value: _getFontWeightValue(fontWeight),
                    min: 100,
                    max: 900,
                    divisions: 8,
                    label: _getFontWeightLabel(fontWeight),
                    activeColor: colorScheme.primary,
                    inactiveColor: colorScheme.surfaceContainerHighest,
                    thumbColor: colorScheme.primary,
                    onChanged: (value) {
                      // 将滑块值转换为字重字符串
                      final weightValue = value.round();
                      String weightString;

                      if (weightValue == 400) {
                        weightString = 'normal';
                      } else if (weightValue == 700) {
                        weightString = 'bold';
                      } else {
                        weightString = 'w$weightValue';
                      }

                      _updateContentProperty('fontWeight', weightString);
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: l10n.fontWeight,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                    ),
                    value: fontWeight,
                    isExpanded: true,
                    items: const [
                      // 按照字重从轻到重排序
                      DropdownMenuItem(
                          value: 'w100', child: Text('Thin (w100)')),
                      DropdownMenuItem(
                          value: 'w200', child: Text('Extra Light (w200)')),
                      DropdownMenuItem(
                          value: 'w300', child: Text('Light (w300)')),
                      DropdownMenuItem(
                          value: 'normal', child: Text('Regular (w400)')),
                      DropdownMenuItem(
                          value: 'w500', child: Text('Medium (w500)')),
                      DropdownMenuItem(
                          value: 'w600', child: Text('Semi Bold (w600)')),
                      DropdownMenuItem(
                          value: 'bold', child: Text('Bold (w700)')),
                      DropdownMenuItem(
                          value: 'w800', child: Text('Extra Bold (w800)')),
                      DropdownMenuItem(
                          value: 'w900', child: Text('Black (w900)')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _updateContentProperty('fontWeight', value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // 字体样式
        M3PanelStyles.buildSectionTitle(context, l10n.fontStyle),
        Row(
          children: [
            // 斜体按钮
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: fontStyle == 'italic'
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                foregroundColor: fontStyle == 'italic'
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                _updateContentProperty(
                    'fontStyle', fontStyle == 'italic' ? 'normal' : 'italic');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.format_italic, size: 18),
                  const SizedBox(width: 4),
                  Text(l10n.fontStyle),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8.0),

        Wrap(
          spacing: 8.0, // 水平间距
          runSpacing: 8.0, // 垂直间距
          children: [
            // 下划线按钮
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: underline
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                foregroundColor: underline
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                _updateContentProperty('underline', !underline);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.format_underlined, size: 18),
                  const SizedBox(width: 4),
                  Text(l10n.underline),
                ],
              ),
            ),
            // 删除线按钮
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: lineThrough
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                foregroundColor: lineThrough
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                _updateContentProperty('lineThrough', !lineThrough);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.strikethrough_s, size: 18),
                  const SizedBox(width: 4),
                  Text(l10n.lineThrough),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // 对齐方式
        M3PanelStyles.buildSectionTitle(context, l10n.horizontalAlignment),
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
                      _updateContentProperty('textAlign', 'left');
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
                      _updateContentProperty('textAlign', 'center');
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
                      _updateContentProperty('textAlign', 'right');
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
                      _updateContentProperty('textAlign', 'justify');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16.0),

        // 垂直对齐
        M3PanelStyles.buildSectionTitle(context, l10n.verticalAlignment),
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
                      _updateContentProperty('verticalAlign', 'top');
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
                      _updateContentProperty('verticalAlign', 'middle');
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
                      _updateContentProperty('verticalAlign', 'bottom');
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
                      _updateContentProperty('verticalAlign', 'justify');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16.0),

        // 书写方向
        M3PanelStyles.buildSectionTitle(context, l10n.writingMode),
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
                      _updateContentProperty('writingMode', 'horizontal-l');
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
                      _updateContentProperty('writingMode', 'vertical-r');
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
                      _updateContentProperty('writingMode', 'horizontal-r');
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
                      _updateContentProperty('writingMode', 'vertical-l');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16.0),

        // 字间距设置
        M3PanelStyles.buildSectionTitle(context, l10n.letterSpacing),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: letterSpacing.clamp(-5.0, 500.0),
                min: -5.0,
                max: 500.0,
                divisions: 505,
                label: '${letterSpacing.toStringAsFixed(1)}px',
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                thumbColor: colorScheme.primary,
                onChanged: (value) {
                  _updateContentProperty('letterSpacing', value);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: l10n.letterSpacing,
                value: letterSpacing,
                suffix: 'px',
                min: -5.0,
                max: 500.0,
                decimalPlaces: 1,
                onChanged: (value) {
                  _updateContentProperty('letterSpacing', value);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // 行间距设置
        M3PanelStyles.buildSectionTitle(context, l10n.lineHeight),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: lineHeight.clamp(0.0, 500.0),
                min: 0.0,
                max: 500.0,
                divisions: 500,
                label: '${lineHeight.toStringAsFixed(1)}px',
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                thumbColor: colorScheme.primary,
                onChanged: (value) {
                  _updateContentProperty('lineHeight', value);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: l10n.lineHeight,
                value: lineHeight,
                suffix: 'px',
                min: 0.0,
                max: 500.0,
                decimalPlaces: 1,
                onChanged: (value) {
                  _updateContentProperty('lineHeight', value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 将文本设置面板内容转换为列表
  List<Widget> _buildTextSettingsPanelList(BuildContext context) {
    final Widget panel = _buildTextSettingsPanel(context);
    if (panel is Column) {
      return panel.children;
    }
    return [panel];
  }

  // 构建视觉属性面板
  Widget _buildVisualPropertiesPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;

    // 文本特有属性
    final content = element['content'] as Map<String, dynamic>? ?? {};
    final padding = (content['padding'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 透明度
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
                thumbColor: colorScheme.primary,
                onChanged: (value) {
                  _updateProperty('opacity', value);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: l10n.opacity,
                value: opacity * 100, // 转换为百分比
                suffix: '%',
                min: 0,
                max: 100,
                decimalPlaces: 0,
                onChanged: (value) {
                  // 转换回 0-1 范围
                  _updateProperty('opacity', value / 100);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // 内边距设置
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
                thumbColor: colorScheme.primary,
                onChanged: (value) {
                  _updateContentProperty('padding', value);
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
                  _updateContentProperty('padding', value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 将视觉属性面板内容转换为列表
  List<Widget> _buildVisualPropertiesPanelList(BuildContext context) {
    final Widget panel = _buildVisualPropertiesPanel(context);
    if (panel is Column) {
      return panel.children;
    }
    return [panel];
  }

  // 获取字重标签
  String _getFontWeightLabel(String weight) {
    switch (weight) {
      case 'w100':
        return 'Thin (100)';
      case 'w200':
        return 'Extra Light (200)';
      case 'w300':
        return 'Light (300)';
      case 'normal':
        return 'Regular (400)';
      case 'w500':
        return 'Medium (500)';
      case 'w600':
        return 'Semi Bold (600)';
      case 'bold':
        return 'Bold (700)';
      case 'w800':
        return 'Extra Bold (800)';
      case 'w900':
        return 'Black (900)';
      default:
        return 'Regular (400)';
    }
  }

  // 获取字重值（用于滑块）
  double _getFontWeightValue(String weight) {
    if (weight == 'normal') return 400;
    if (weight == 'bold') return 700;

    if (weight.startsWith('w')) {
      final weightValue = int.tryParse(weight.substring(1));
      if (weightValue != null && weightValue >= 100 && weightValue <= 900) {
        return weightValue.toDouble();
      }
    }
    return 400; // 默认值
  }

  // 更新内容属性
  void _updateContentProperty(String key, dynamic value) {
    EditPageLogger.editPageDebug(
      '更新文本内容属性',
      data: {
        'key': key,
        'value': value,
        'currentWritingMode': element['content']?['writingMode'],
      },
    );

    final content = Map<String, dynamic>.from(
        element['content'] as Map<String, dynamic>? ?? {});
    content[key] = value;
    _updateProperty('content', content);

    EditPageLogger.editPageDebug(
      '文本内容属性更新完成',
      data: {'updatedContent': content},
    );
  }

  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onElementPropertiesChanged(updates);
  }
}
