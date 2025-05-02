import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../common/editable_number_field.dart';
import '../practice_edit_controller.dart';
import '../text_renderer.dart';
import 'm3_element_common_property_panel.dart';
import 'm3_layer_info_panel.dart';
import 'practice_property_panel_base.dart';

// 列数据类，用于存储列的Widget和字符
class ColumnData {
  final Widget widget;
  final List<String> chars;

  ColumnData(this.widget, this.chars);
}

/// 文本内容属性面板
class M3TextPropertyPanel extends PracticePropertyPanel {
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
    final padding = (content['padding'] as num?)?.toDouble() ?? 0.0;

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

    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      shrinkWrap: true, // 确保ListView不会无限扩展
      children: [
        // 基本属性面板 (放在最前面)
        M3ElementCommonPropertyPanel(
          element: element,
          onElementPropertiesChanged: onElementPropertiesChanged,
          controller: controller,
        ),

        // 图层信息
        M3LayerInfoPanel(layer: layer),

        // 几何属性部分
        materialExpansionTile(
          title: Text(l10n.geometryProperties),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 8.0),
                  // 旋转角度
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
              ),
            ),
          ],
        ),

        // 视觉属性部分
        materialExpansionTile(
          title: Text(l10n.visualSettings),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 透明度
                  Text('${l10n.opacity}:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  Text('${l10n.textPropertyPanelPadding}:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          label: l10n.textPropertyPanelPadding,
                          value: padding,
                          suffix: 'px',
                          min: 0,
                          max: 100,
                          decimalPlaces: 0,
                          onChanged: (value) {
                            _updateContentProperty('padding', value);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // 文本设置部分
        materialExpansionTile(
          title: Text(l10n.textPropertyPanelTextSettings),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文本内容
                  Text('${l10n.textPropertyPanelTextContent}:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  _buildTextContentField(text, context),

                  const SizedBox(height: 16.0),

                  // 文本预览
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${l10n.textPropertyPanelPreview}:',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      // 添加预览文本切换按钮
                      FilledButton.tonal(
                        onPressed: () {
                          // 切换预览文本
                          if (text.isEmpty || text == '预览文本内容\n第二行文本\n第三行文本') {
                            // 使用更长的文本来测试溢出情况
                            _updateContentProperty('text',
                                '水平对齐模式测试\n垂直对齐模式测试\n书写方向测试\n这是一段较长的文本\n用于测试文本对齐\n和换行效果\n以及文本溢出处理\n当文本长度超出\n预览容器高度时\n应该显示滚动条\n并且能够正确应用\n不同的对齐选项');
                          } else {
                            _updateContentProperty(
                                'text', '预览文本内容\n第二行文本\n第三行文本');
                          }
                        },
                        child: Text(l10n.toggleTestText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 添加预览模式指示器
                      if (writingMode.startsWith('vertical'))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Wrap(
                            spacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: colorScheme.primary),
                              Text(
                                '竖排文本预览 - 超出高度自动换列，可横向滚动',
                                style: TextStyle(
                                    fontSize: 12, color: colorScheme.primary),
                              ),
                            ],
                          ),
                        ),
                      // 使用外层容器定义大小和样式
                      SizedBox(
                        width: double.infinity,
                        height: 200, // 增加高度，便于测试垂直对齐
                        child: Container(
                          // 移除固定的对齐方式，让内部的TextRenderer决定对齐方式
                          decoration: BoxDecoration(
                            color: getBackgroundColor(),
                            border: Border.all(color: colorScheme.outline),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          // 使用可滚动容器包裹文本预览
                          child: Padding(
                            padding: EdgeInsets.all(padding),
                            child: writingMode.startsWith('vertical')
                                ? _buildVerticalTextPreview(
                                    text: text.isEmpty
                                        ? '预览文本内容\n第二行文本\n第三行文本'
                                        : text,
                                    fontSize: fontSize,
                                    fontFamily: fontFamily,
                                    fontWeight: fontWeight,
                                    fontStyle: fontStyle,
                                    fontColor: fontColor,
                                    underline: underline,
                                    lineThrough: lineThrough,
                                    letterSpacing: letterSpacing,
                                    lineHeight: lineHeight,
                                    textAlign: textAlign,
                                    verticalAlign: verticalAlign,
                                    writingMode: writingMode,
                                  )
                                : _buildHorizontalTextPreview(
                                    text: text.isEmpty
                                        ? '预览文本内容\n第二行文本\n第三行文本'
                                        : text,
                                    fontSize: fontSize,
                                    fontFamily: fontFamily,
                                    fontWeight: fontWeight,
                                    fontStyle: fontStyle,
                                    fontColor: fontColor,
                                    underline: underline,
                                    lineThrough: lineThrough,
                                    letterSpacing: letterSpacing,
                                    lineHeight: lineHeight,
                                    textAlign: textAlign,
                                    verticalAlign: verticalAlign,
                                    writingMode: writingMode,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 字体设置
                  Text('${l10n.textPropertyPanelFontFamily}:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  // 字号设置
                  Text('${l10n.textPropertyPanelFontSize}:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          label: l10n.textPropertyPanelFontSize,
                          value: fontSize,
                          suffix: 'px',
                          min: 1,
                          max: 200,
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
                        message: l10n.textPropertyPanelFontColor,
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
                              onTap: () {
                                _showColorPicker(context, fontColor, (color) {
                                  // 转换颜色为十六进制
                                  String hexColor;
                                  if (color.a == 0) {
                                    hexColor = 'transparent';
                                  } else {
                                    // 将 0-1 范围的浮点数转换为 0-255 范围的整数
                                    final r = (color.r * 255).round();
                                    final g = (color.g * 255).round();
                                    final b = (color.b * 255).round();
                                    hexColor =
                                        '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
                                            .toUpperCase();
                                    developer.log(
                                        '颜色转换: R=$r, G=$g, B=$b -> $hexColor');
                                  }

                                  // 更新属性
                                  _updateContentProperty('fontColor', hexColor);
                                });
                              },
                              child: Icon(
                                Icons.colorize,
                                color: getFontColor().computeLuminance() > 0.5
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
                            labelText: l10n.textPropertyPanelFontFamily,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                          ),
                          value: fontFamily,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                                value: 'sans-serif', child: Text('Sans Serif')),
                            DropdownMenuItem(
                                value: 'serif', child: Text('Serif')),
                            DropdownMenuItem(
                                value: 'monospace', child: Text('Monospace')),
                            DropdownMenuItem(
                                value: 'cursive', child: Text('Cursive')),
                            DropdownMenuItem(
                                value: 'fantasy', child: Text('Fantasy')),
                            // Chinese fonts based on assets/fonts/chinese directory
                            DropdownMenuItem(
                                value: 'SourceHanSansCN', child: Text('思源黑体')),
                            DropdownMenuItem(
                                value: 'NotoSansSC',
                                child: Text('Noto Sans SC')),
                            DropdownMenuItem(
                                value: 'Microsoft YaHei', child: Text('微软雅黑')),
                            DropdownMenuItem(
                                value: 'SimSun', child: Text('宋体')),
                            DropdownMenuItem(
                                value: 'SimHei', child: Text('黑体')),
                            DropdownMenuItem(
                                value: 'SimKai', child: Text('楷体')),
                            DropdownMenuItem(
                                value: 'SimFang', child: Text('仿宋')),
                            DropdownMenuItem(value: 'SimLi', child: Text('隶书')),
                            DropdownMenuItem(
                                value: 'SimYou', child: Text('幼圆')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _updateContentProperty('fontFamily', value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // 背景颜色选择器
                      Tooltip(
                        message: l10n.textPropertyPanelBgColor,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: getBackgroundColor(),
                            border: Border.all(color: colorScheme.outline),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12.0),
                              onTap: () {
                                _showColorPicker(
                                  context,
                                  backgroundColor == 'transparent'
                                      ? '#00FFFFFF'
                                      : backgroundColor,
                                  (color) {
                                    // 检查是否是透明色
                                    String hexColor;
                                    if (color.a == 0) {
                                      hexColor = 'transparent';
                                    } else {
                                      // 将 0-1 范围的浮点数转换为 0-255 范围的整数
                                      final r = (color.r * 255).round();
                                      final g = (color.g * 255).round();
                                      final b = (color.b * 255).round();
                                      hexColor =
                                          '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
                                              .toUpperCase();
                                    }

                                    // 更新属性
                                    _updateContentProperty(
                                        'backgroundColor', hexColor);
                                  },
                                );
                              },
                              child: backgroundColor == 'transparent'
                                  ? Icon(Icons.format_color_reset,
                                      color: colorScheme.outline)
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

                  const SizedBox(height: 16.0),

                  // 字体样式
                  Text('${l10n.textPropertyPanelFontStyle}:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0, // 水平间距
                    runSpacing: 8.0, // 垂直间距
                    children: [
                      // 加粗按钮
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: fontWeight == 'bold'
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                          foregroundColor: fontWeight == 'bold'
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _updateContentProperty('fontWeight',
                              fontWeight == 'bold' ? 'normal' : 'bold');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.format_bold, size: 18),
                            const SizedBox(width: 4),
                            Text(l10n.textPropertyPanelFontWeight),
                          ],
                        ),
                      ),
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
                          _updateContentProperty('fontStyle',
                              fontStyle == 'italic' ? 'normal' : 'italic');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.format_italic, size: 18),
                            const SizedBox(width: 4),
                            Text(l10n.textPropertyPanelFontStyle),
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
                            Text(l10n.textPropertyPanelUnderline),
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
                            Text(l10n.textPropertyPanelLineThrough),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 对齐方式
                  Text('${l10n.horizontalAlignment}:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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
                              icon: const Icon(Icons.align_horizontal_left),
                              onPressed: () =>
                                  _updateContentProperty('textAlign', 'left'),
                              style: IconButton.styleFrom(
                                backgroundColor: textAlign == 'left'
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                foregroundColor: textAlign == 'left'
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          // Center align
                          Tooltip(
                            message: l10n.alignCenter,
                            child: IconButton(
                              icon: const Icon(Icons.align_horizontal_center),
                              onPressed: () =>
                                  _updateContentProperty('textAlign', 'center'),
                              style: IconButton.styleFrom(
                                backgroundColor: textAlign == 'center'
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                foregroundColor: textAlign == 'center'
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          // Right align
                          Tooltip(
                            message: l10n.alignRight,
                            child: IconButton(
                              icon: const Icon(Icons.align_horizontal_right),
                              onPressed: () =>
                                  _updateContentProperty('textAlign', 'right'),
                              style: IconButton.styleFrom(
                                backgroundColor: textAlign == 'right'
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                foregroundColor: textAlign == 'right'
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          // Justify
                          Tooltip(
                            message: l10n.distribution,
                            child: IconButton(
                              icon: const Icon(Icons.format_align_justify),
                              onPressed: () => _updateContentProperty(
                                  'textAlign', 'justify'),
                              style: IconButton.styleFrom(
                                backgroundColor: textAlign == 'justify'
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                foregroundColor: textAlign == 'justify'
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // 垂直对齐
                  Text('${l10n.verticalAlignment}:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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
                              onPressed: () => _updateContentProperty(
                                  'verticalAlign', 'top'),
                              style: IconButton.styleFrom(
                                backgroundColor: verticalAlign == 'top'
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                foregroundColor: verticalAlign == 'top'
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          // Middle align
                          Tooltip(
                            message: l10n.alignMiddle,
                            child: IconButton(
                              icon: const Icon(Icons.vertical_align_center),
                              onPressed: () => _updateContentProperty(
                                  'verticalAlign', 'middle'),
                              style: IconButton.styleFrom(
                                backgroundColor: verticalAlign == 'middle'
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                foregroundColor: verticalAlign == 'middle'
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          // Bottom align
                          Tooltip(
                            message: l10n.alignBottom,
                            child: IconButton(
                              icon: const Icon(Icons.vertical_align_bottom),
                              onPressed: () => _updateContentProperty(
                                  'verticalAlign', 'bottom'),
                              style: IconButton.styleFrom(
                                backgroundColor: verticalAlign == 'bottom'
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                foregroundColor: verticalAlign == 'bottom'
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          // Justify
                          Tooltip(
                            message: l10n.distribution,
                            child: IconButton(
                              icon: const Icon(Icons.format_align_justify),
                              onPressed: () => _updateContentProperty(
                                  'verticalAlign', 'justify'),
                              style: IconButton.styleFrom(
                                backgroundColor: verticalAlign == 'justify'
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                foregroundColor: verticalAlign == 'justify'
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // 书写方向
                  Text('${l10n.textPropertyPanelWritingMode}:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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
                              icon:
                                  const Icon(Icons.format_textdirection_l_to_r),
                              onPressed: () => _updateContentProperty(
                                  'writingMode', 'horizontal-l'),
                              style: IconButton.styleFrom(
                                backgroundColor: writingMode == 'horizontal-l'
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                foregroundColor: writingMode == 'horizontal-l'
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          // Vertical Right-to-Left
                          Tooltip(
                            message: l10n.verticalRightToLeft,
                            child: IconButton(
                              icon:
                                  const Icon(Icons.format_textdirection_r_to_l),
                              onPressed: () => _updateContentProperty(
                                  'writingMode', 'vertical-r'),
                              style: IconButton.styleFrom(
                                backgroundColor: writingMode == 'vertical-r'
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                foregroundColor: writingMode == 'vertical-r'
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          // Horizontal Right-to-Left
                          Tooltip(
                            message: l10n.horizontalRightToLeft,
                            child: IconButton(
                              icon:
                                  const Icon(Icons.keyboard_double_arrow_left),
                              onPressed: () => _updateContentProperty(
                                  'writingMode', 'horizontal-r'),
                              style: IconButton.styleFrom(
                                backgroundColor: writingMode == 'horizontal-r'
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                foregroundColor: writingMode == 'horizontal-r'
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          // Vertical Left-to-Right
                          Tooltip(
                            message: l10n.verticalLeftToRight,
                            child: IconButton(
                              icon:
                                  const Icon(Icons.keyboard_double_arrow_right),
                              onPressed: () => _updateContentProperty(
                                  'writingMode', 'vertical-l'),
                              style: IconButton.styleFrom(
                                backgroundColor: writingMode == 'vertical-l'
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                foregroundColor: writingMode == 'vertical-l'
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // 字间距设置
                  Text('${l10n.textPropertyPanelLetterSpacing}:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: letterSpacing,
                          min: -5.0,
                          max: 20.0,
                          divisions: 250,
                          label: '${letterSpacing.toStringAsFixed(1)}px',
                          activeColor: colorScheme.primary,
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
                          label: l10n.textPropertyPanelLetterSpacing,
                          value: letterSpacing,
                          suffix: 'px',
                          min: -5.0,
                          max: 20.0,
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
                  Text('${l10n.textPropertyPanelLineHeight}:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: lineHeight,
                          min: 0.5,
                          max: 3.0,
                          divisions: 25,
                          label: '${lineHeight.toStringAsFixed(1)}x',
                          activeColor: colorScheme.primary,
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
                          label: l10n.textPropertyPanelLineHeight,
                          value: lineHeight,
                          suffix: 'x',
                          min: 0.5,
                          max: 3.0,
                          decimalPlaces: 1,
                          onChanged: (value) {
                            _updateContentProperty('lineHeight', value);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 构建水平文本预览
  Widget _buildHorizontalTextPreview({
    required String text,
    required double fontSize,
    required String fontFamily,
    required String fontWeight,
    required String fontStyle,
    required String fontColor,
    required bool underline,
    required bool lineThrough,
    required double letterSpacing,
    required double lineHeight,
    required String textAlign,
    required String verticalAlign,
    required String writingMode,
  }) {
    // 创建文本样式
    final TextStyle textStyle = TextRenderer.createTextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      fontColor: fontColor,
      letterSpacing: letterSpacing,
      lineHeight: lineHeight,
      underline: underline,
      lineThrough: lineThrough,
    );

    // 使用共享的文本渲染器
    return LayoutBuilder(
      builder: (context, constraints) {
        developer.log(
            '水平文本预览参数: textAlign=$textAlign, verticalAlign=$verticalAlign, writingMode=$writingMode');
        developer.log(
            '水平文本预览约束: width=${constraints.maxWidth}, height=${constraints.maxHeight}');

        return TextRenderer.renderHorizontalText(
          text: text,
          style: textStyle,
          textAlign: textAlign,
          verticalAlign: verticalAlign,
          writingMode: writingMode,
          constraints: constraints,
          backgroundColor: Colors.transparent,
        );
      },
    );
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

  // 构建垂直文本预览
  Widget _buildVerticalTextPreview({
    required String text,
    required double fontSize,
    required String fontFamily,
    required String fontWeight,
    required String fontStyle,
    required String fontColor,
    required bool underline,
    required bool lineThrough,
    required double letterSpacing,
    required double lineHeight,
    required String textAlign,
    required String verticalAlign,
    required String writingMode,
  }) {
    // 创建文本样式
    final TextStyle textStyle = TextRenderer.createTextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      fontColor: fontColor,
      letterSpacing: letterSpacing,
      lineHeight: lineHeight,
      underline: underline,
      lineThrough: lineThrough,
    );

    // 使用共享的文本渲染器
    return LayoutBuilder(
      builder: (context, constraints) {
        developer.log(
            '垂直文本预览参数: textAlign=$textAlign, verticalAlign=$verticalAlign, writingMode=$writingMode');
        developer.log(
            '垂直文本预览约束: width=${constraints.maxWidth}, height=${constraints.maxHeight}');

        return TextRenderer.renderVerticalText(
          text: text,
          style: textStyle,
          textAlign: textAlign,
          verticalAlign: verticalAlign,
          writingMode: writingMode,
          constraints: constraints,
          backgroundColor: Colors.transparent,
        );
      },
    );
  }

  // 颜色选择器对话框
  Future<void> _showColorPicker(BuildContext context, String initialColor,
      Function(Color) onColorSelected) async {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    // 打印调试信息
    developer.log('打开颜色选择器，初始颜色: $initialColor');

    Color currentColor;
    if (initialColor == 'transparent') {
      currentColor = Colors.transparent;
    } else {
      try {
        currentColor = Color(int.parse(initialColor.replaceFirst('#', '0xFF')));
      } catch (e) {
        developer.log('解析颜色失败: $e');
        currentColor = Colors.black;
      }
    }

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
        return AlertDialog(
          title: Text(localizations.imagePropertyPanelImageSelection),
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          content: SizedBox(
            width: 300,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final color = colors[index];
                // 使用颜色的 ARGB 值进行比较
                // 将浮点数转换为整数进行比较，以避免浮点数精度问题
                final bool isSelected = (color.r * 255).round() ==
                        (currentColor.r * 255).round() &&
                    (color.g * 255).round() == (currentColor.g * 255).round() &&
                    (color.b * 255).round() == (currentColor.b * 255).round() &&
                    (color.a * 255).round() == (currentColor.a * 255).round();

                return InkWell(
                  onTap: () {
                    // 打印调试信息
                    developer.log('选择颜色: $color');
                    developer.log(
                        '颜色组件: R=${color.r}, G=${color.g}, B=${color.b}, A=${color.a}');

                    // 调用回调函数
                    onColorSelected(color);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: (color == Colors.white ||
                                      color == Colors.transparent ||
                                      color.computeLuminance() > 0.7)
                                  ? Colors.black
                                  : Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
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
              child: Text(localizations.cancel),
            ),
          ],
        );
      },
    );
  }

  // 更新内容属性
  void _updateContentProperty(String key, dynamic value) {
    // 打印调试信息
    developer.log('更新内容属性: $key = $value');
    developer.log('当前书写模式: ${element['content']['writingMode']}');

    final content = Map<String, dynamic>.from(
        element['content'] as Map<String, dynamic>? ?? {});
    content[key] = value;
    _updateProperty('content', content);

    // 打印更新后的内容
    developer.log('更新后的内容: $content');
  }

  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onElementPropertiesChanged(updates);
  }
}
