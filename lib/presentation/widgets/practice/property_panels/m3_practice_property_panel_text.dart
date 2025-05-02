import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../common/editable_number_field.dart';
import '../practice_edit_controller.dart';
import 'element_common_property_panel.dart';
import 'layer_info_panel.dart';
import 'practice_property_panel_base.dart';

/// 文本属性面板 (Material 3 版本)
class M3TextPropertyPanel extends PracticePropertyPanel {
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
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;
    final layerId = element['layerId'] as String?;

    // 获取图层信息
    Map<String, dynamic>? layer;
    if (layerId != null) {
      layer = controller.state.getLayerById(layerId);
    }

    // 文本特有属性
    final content = element['content'] as Map<String, dynamic>? ?? {};
    final text = content['text'] as String? ?? '';
    final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 16.0;
    final fontFamily = content['fontFamily'] as String? ?? 'sans-serif';
    final fontWeight = content['fontWeight'] as String? ?? 'normal';
    final fontStyle = content['fontStyle'] as String? ?? 'normal';
    final color = content['color'] as String? ?? '#000000';
    final backgroundColor =
        content['backgroundColor'] as String? ?? 'transparent';
    final textAlign = content['textAlign'] as String? ?? 'left';
    final verticalAlign = content['verticalAlign'] as String? ?? 'top';
    final letterSpacing = (content['letterSpacing'] as num?)?.toDouble() ?? 0.0;
    final lineHeight = (content['lineHeight'] as num?)?.toDouble() ?? 1.2;
    final padding = (content['padding'] as num?)?.toDouble() ?? 4.0;
    final underline = content['underline'] as bool? ?? false;
    final lineThrough = content['lineThrough'] as bool? ?? false;
    final writingMode = content['writingMode'] as String? ?? 'horizontal';

    // 颜色转换函数
    Color getColor() {
      try {
        return Color(int.parse(color.replaceFirst('#', '0xFF')));
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

    return ListView(
      shrinkWrap: true,
      children: [
        // 基本属性面板(放在最前面)
        ElementCommonPropertyPanel(
          element: element,
          onElementPropertiesChanged: onElementPropertiesChanged,
          controller: controller,
        ),

        // 图层信息
        LayerInfoPanel(layer: layer),

        // 几何属性部分
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ExpansionTile(
            title: Text(l10n.textPropertyPanelGeometry),
            initiallyExpanded: true,
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 位置
                  Text(
                    '${l10n.textPropertyPanelPosition}:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8.0),

                  // X和Y位置
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

                  // 尺寸
                  Text(
                    '${l10n.textPropertyPanelDimensions}:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8.0),

                  // 宽度和高度
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
                          onChanged: (value) =>
                              _updateProperty('height', value),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 旋转角度
                  Text(
                    '${l10n.rotation}:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8.0),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: rotation,
                          min: -180,
                          max: 180,
                          divisions: 360,
                          label: '${rotation.round()}°',
                          onChanged: (value) {
                            _updateProperty('rotation', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
                        child: EditableNumberField(
                          label: l10n.rotation,
                          value: rotation,
                          suffix: '°',
                          min: -180,
                          max: 180,
                          decimalPlaces: 0,
                          onChanged: (value) {
                            _updateProperty('rotation', value);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // 视觉属性部分
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ExpansionTile(
            title: Text(l10n.textPropertyPanelVisual),
            initiallyExpanded: true,
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 透明度
                  Text(
                    '${l10n.textPropertyPanelOpacity}:',
                    style: Theme.of(context).textTheme.titleSmall,
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
                          onChanged: (value) {
                            _updateProperty('opacity', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
                        child: EditableNumberField(
                          label: l10n.textPropertyPanelOpacity,
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

                  // 内边距
                  Text(
                    '${l10n.textPropertyPanelPadding}:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8.0),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: padding,
                          min: 0,
                          max: 40,
                          divisions: 40,
                          label: '${padding.round()}px',
                          onChanged: (value) {
                            _updateContentProperty('padding', value);
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
                          max: 40,
                          decimalPlaces: 0,
                          onChanged: (value) {
                            _updateContentProperty('padding', value);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 字体颜色和背景色
                  Row(
                    children: [
                      // 字体颜色
                      Text(
                        '${l10n.textPropertyPanelFontColor}:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(width: 8.0),

                      // 字体颜色选择器
                      Tooltip(
                        message: l10n.textPropertyPanelFontColor,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: getColor(),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4.0),
                              onTap: () {
                                _showColorPicker(
                                  context,
                                  color,
                                  (color) {
                                    String hexColor;
                                    final r = (color.red * 255).round();
                                    final g = (color.green * 255).round();
                                    final b = (color.blue * 255).round();
                                    hexColor =
                                        '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
                                            .toUpperCase();
                                    _updateContentProperty('color', hexColor);
                                  },
                                );
                              },
                              child: Icon(
                                Icons.format_color_text,
                                color: getColor().computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16.0),

                      // 背景颜色
                      Text(
                        '${l10n.textPropertyPanelBgColor}:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(width: 8.0),

                      // 背景颜色选择器
                      Tooltip(
                        message: l10n.textPropertyPanelBgColor,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: getBackgroundColor(),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4.0),
                              onTap: () {
                                _showColorPicker(
                                  context,
                                  backgroundColor == 'transparent'
                                      ? '#00FFFFFF'
                                      : backgroundColor,
                                  (color) {
                                    String hexColor;
                                    if (color.alpha == 0) {
                                      hexColor = 'transparent';
                                    } else {
                                      final r = (color.red * 255).round();
                                      final g = (color.green * 255).round();
                                      final b = (color.blue * 255).round();
                                      hexColor =
                                          '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
                                              .toUpperCase();
                                    }
                                    _updateContentProperty(
                                        'backgroundColor', hexColor);
                                  },
                                );
                              },
                              child: backgroundColor == 'transparent'
                                  ? const Icon(Icons.format_color_reset,
                                      color: Colors.grey)
                                  : Icon(
                                      Icons.format_color_fill,
                                      color: getBackgroundColor()
                                                  .computeLuminance() >
                                              0.5
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // 文本设置部分
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ExpansionTile(
            title: Text(l10n.textPropertyPanelTextSettings),
            initiallyExpanded: true,
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 字号
                  Text(
                    '${l10n.textPropertyPanelFontSize}:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8.0),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: fontSize,
                          min: 8,
                          max: 72,
                          divisions: 64,
                          label: '${fontSize.round()}px',
                          onChanged: (value) {
                            _updateContentProperty('fontSize', value);
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
                          min: 8,
                          max: 72,
                          decimalPlaces: 0,
                          onChanged: (value) {
                            _updateContentProperty('fontSize', value);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 字体家族
                  Text(
                    '${l10n.textPropertyPanelFontFamily}:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8.0),

                  // 字体下拉列表
                  DropdownButtonFormField<String>(
                    value: fontFamily,
                    decoration: InputDecoration(
                      labelText: l10n.textPropertyPanelFontFamily,
                      border: const OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'sans-serif',
                        child: Text('Sans Serif'),
                      ),
                      DropdownMenuItem(
                        value: 'serif',
                        child: Text('Serif'),
                      ),
                      DropdownMenuItem(
                        value: 'monospace',
                        child: Text('Monospace'),
                      ),
                      DropdownMenuItem(
                        value: 'cursive',
                        child: Text('Cursive'),
                      ),
                      DropdownMenuItem(
                        value: 'fantasy',
                        child: Text('Fantasy'),
                      ),
                      // Chinese fonts based on assets/fonts/chinese directory
                      DropdownMenuItem(
                        value: 'SourceHanSansCN',
                        child: Text('思源黑体'),
                      ),
                      DropdownMenuItem(
                        value: 'NotoSansSC',
                        child: Text('Noto Sans SC'),
                      ),
                      DropdownMenuItem(
                        value: 'Microsoft YaHei',
                        child: Text('微软雅黑'),
                      ),
                      DropdownMenuItem(
                        value: 'SimSun',
                        child: Text('宋体'),
                      ),
                      DropdownMenuItem(
                        value: 'SimHei',
                        child: Text('黑体'),
                      ),
                      DropdownMenuItem(
                        value: 'SimKai',
                        child: Text('楷体'),
                      ),
                      DropdownMenuItem(
                        value: 'SimFang',
                        child: Text('仿宋'),
                      ),
                      DropdownMenuItem(
                        value: 'SimLi',
                        child: Text('隶书'),
                      ),
                      DropdownMenuItem(
                        value: 'SimYou',
                        child: Text('幼圆'),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        _updateContentProperty('fontFamily', value);
                      }
                    },
                  ),

                  const SizedBox(height: 16.0),

                  // 字重
                  Text(
                    '${l10n.textPropertyPanelFontWeight}:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8.0),

                  // 字重选择
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'normal',
                        label: Text('Normal'),
                        icon: Icon(Icons.text_format),
                      ),
                      ButtonSegment<String>(
                        value: 'bold',
                        label: Text('Bold'),
                        icon: Icon(Icons.format_bold),
                      ),
                    ],
                    selected: {fontWeight},
                    onSelectionChanged: (Set<String> selected) {
                      if (selected.isNotEmpty) {
                        _updateContentProperty('fontWeight', selected.first);
                      }
                    },
                  ),

                  const SizedBox(height: 16.0),

                  // 字体样式
                  Text(
                    '${l10n.textPropertyPanelFontStyle}:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8.0),

                  // 斜体选择
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'normal',
                        label: Text('Normal'),
                        icon: Icon(Icons.text_format),
                      ),
                      ButtonSegment<String>(
                        value: 'italic',
                        label: Text('Italic'),
                        icon: Icon(Icons.format_italic),
                      ),
                    ],
                    selected: {fontStyle},
                    onSelectionChanged: (Set<String> selected) {
                      if (selected.isNotEmpty) {
                        _updateContentProperty('fontStyle', selected.first);
                      }
                    },
                  ),

                  const SizedBox(height: 16.0),

                  // 文本装饰（下划线、删除线）
                  Row(
                    children: [
                      // 下划线
                      FilterChip(
                        label: Text(l10n.textPropertyPanelUnderline),
                        selected: underline,
                        onSelected: (bool selected) {
                          _updateContentProperty('underline', selected);
                        },
                        avatar: const Icon(Icons.format_underlined),
                      ),
                      const SizedBox(width: 8.0),
                      // 删除线
                      FilterChip(
                        label: Text(l10n.textPropertyPanelLineThrough),
                        selected: lineThrough,
                        onSelected: (bool selected) {
                          _updateContentProperty('lineThrough', selected);
                        },
                        avatar: const Icon(Icons.format_strikethrough),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 水平对齐
                  Text(
                    '${l10n.textPropertyPanelTextAlign}:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8.0),

                  // 水平对齐选择
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'left',
                        icon: Icon(Icons.format_align_left),
                      ),
                      ButtonSegment<String>(
                        value: 'center',
                        icon: Icon(Icons.format_align_center),
                      ),
                      ButtonSegment<String>(
                        value: 'right',
                        icon: Icon(Icons.format_align_right),
                      ),
                      ButtonSegment<String>(
                        value: 'justify',
                        icon: Icon(Icons.format_align_justify),
                      ),
                    ],
                    selected: {textAlign},
                    onSelectionChanged: (Set<String> selected) {
                      if (selected.isNotEmpty) {
                        _updateContentProperty('textAlign', selected.first);
                      }
                    },
                  ),

                  const SizedBox(height: 16.0),

                  // 垂直对齐
                  Text(
                    '${l10n.textPropertyPanelVerticalAlign}:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8.0),

                  // 垂直对齐选择
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'top',
                        icon: Icon(Icons.vertical_align_top),
                      ),
                      ButtonSegment<String>(
                        value: 'center',
                        icon: Icon(Icons.vertical_align_center),
                      ),
                      ButtonSegment<String>(
                        value: 'bottom',
                        icon: Icon(Icons.vertical_align_bottom),
                      ),
                    ],
                    selected: {verticalAlign},
                    onSelectionChanged: (Set<String> selected) {
                      if (selected.isNotEmpty) {
                        _updateContentProperty('verticalAlign', selected.first);
                      }
                    },
                  ),

                  const SizedBox(height: 16.0),

                  // 字间距
                  Text(
                    '${l10n.textPropertyPanelLetterSpacing}:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8.0),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: letterSpacing,
                          min: -5,
                          max: 20,
                          divisions: 50,
                          label: '${letterSpacing.toStringAsFixed(1)}px',
                          onChanged: (value) {
                            _updateContentProperty('letterSpacing', value);
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
                          min: -5,
                          max: 20,
                          decimalPlaces: 1,
                          onChanged: (value) {
                            _updateContentProperty('letterSpacing', value);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 行高
                  Text(
                    '${l10n.textPropertyPanelLineHeight}:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8.0),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: lineHeight,
                          min: 0.5,
                          max: 3,
                          divisions: 50,
                          label: lineHeight.toStringAsFixed(1),
                          onChanged: (value) {
                            _updateContentProperty('lineHeight', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
                        child: EditableNumberField(
                          label: l10n.textPropertyPanelLineHeight,
                          value: lineHeight,
                          min: 0.5,
                          max: 3,
                          decimalPlaces: 1,
                          onChanged: (value) {
                            _updateContentProperty('lineHeight', value);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 书写模式
                  Text(
                    '${l10n.textPropertyPanelWritingMode}:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8.0),

                  // 书写模式选择
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment<String>(
                        value: 'horizontal',
                        label: Text(l10n.textPropertyPanelHorizontal),
                        icon: const Icon(Icons.format_textdirection_l_to_r),
                      ),
                      ButtonSegment<String>(
                        value: 'vertical',
                        label: Text(l10n.textPropertyPanelVertical),
                        icon: const Icon(Icons.format_textdirection_r_to_l),
                      ),
                    ],
                    selected: {writingMode},
                    onSelectionChanged: (Set<String> selected) {
                      if (selected.isNotEmpty) {
                        _updateContentProperty('writingMode', selected.first);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // 文本内容部分
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ExpansionTile(
            title: Text(l10n.textPropertyPanelTextContent),
            initiallyExpanded: true,
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文本输入
                  TextField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.textPropertyPanelTextContent,
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    controller: TextEditingController(text: text),
                    onChanged: (value) {
                      _updateContentProperty('text', value);
                    },
                  ),

                  const SizedBox(height: 16.0),

                  // 文本预览
                  Text(
                    '${l10n.textPropertyPanelPreview}:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8.0),

                  // 预览容器
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: getBackgroundColor(),
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      text.isNotEmpty ? text : 'Text Preview',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontFamily: fontFamily,
                        fontWeight: fontWeight == 'bold'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontStyle: fontStyle == 'italic'
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: getColor(),
                        decoration: TextDecoration.combine([
                          if (underline) TextDecoration.underline,
                          if (lineThrough) TextDecoration.lineThrough,
                        ]),
                        letterSpacing: letterSpacing,
                        height: lineHeight,
                      ),
                      textAlign: () {
                        switch (textAlign) {
                          case 'left':
                            return TextAlign.left;
                          case 'center':
                            return TextAlign.center;
                          case 'right':
                            return TextAlign.right;
                          case 'justify':
                            return TextAlign.justify;
                          default:
                            return TextAlign.left;
                        }
                      }(),
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

  // 显示颜色选择器
  Future<void> _showColorPicker(BuildContext context, String initialColor,
      Function(Color) onColorSelected) async {
    // No need to parse the initial color here as we're just showing a color grid

    // 构建颜色选择器
    final List<Color> colors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.transparent,
    ];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.textPropertyPanelFontColor),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final color = colors[index];
                final isTransparent = color == Colors.transparent;
                return InkWell(
                  onTap: () {
                    onColorSelected(color);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isTransparent
                        ? const Center(
                            child: Icon(
                              Icons.format_color_reset,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }

  void _updateContentProperty(String key, dynamic value) {
    final content = Map<String, dynamic>.from(
        element['content'] as Map<String, dynamic>? ?? {});
    content[key] = value;
    _updateProperty('content', content);
  }

  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onElementPropertiesChanged(updates);
  }
}
