import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../common/editable_number_field.dart';
import '../practice_edit_controller.dart';
import '../text_renderer.dart';
import 'element_common_property_panel.dart';
import 'layer_info_panel.dart';
import 'practice_property_panel_base.dart';

// 列数据类，用于存储列的Widget和字符
class ColumnData {
  final Widget widget;
  final List<String> chars;

  ColumnData(this.widget, this.chars);
}

/// 文本内容属性面板
class TextPropertyPanel extends PracticePropertyPanel {
  // 文本控制器静态变量
  static final TextEditingController _textController = TextEditingController();

  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;

  const TextPropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
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

    // 字号现在使用 EditableNumberField 控件显示和编辑

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

    return ListView(
      shrinkWrap: true, // 确保ListView不会无限扩展
      children: [
        // 基本属性面板 (放在最前面)
        ElementCommonPropertyPanel(
          element: element,
          onElementPropertiesChanged: onElementPropertiesChanged,
          controller: controller,
        ),

        // 图层信息
        LayerInfoPanel(layer: layer),

        // 几何属性部分
        materialExpansionTile(
          title: const Text('几何属性'),
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
                          label: '宽度',
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
                          label: '高度',
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
                    label: '旋转',
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
          title: const Text('视觉设置'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 透明度
                  const Text('透明度:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
                          label: '透明度',
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
                  const Text('内边距:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
                          onChanged: (value) {
                            _updateContentProperty('padding', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
                        child: EditableNumberField(
                          label: '内边距',
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
          title: const Text('文本设置'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文本内容
                  const Text('文本内容:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  _buildTextContentField(text),

                  const SizedBox(height: 16.0),

                  // 文本预览
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('预览:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      // 添加预览文本切换按钮
                      TextButton(
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
                        child: const Text('切换测试文本'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 添加预览模式指示器
                      if (writingMode.startsWith('vertical'))
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Wrap(
                            spacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: Colors.blue),
                              Text(
                                '竖排文本预览 - 超出高度自动换列，可横向滚动',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      // 使用外层容器定义大小和样式
                      SizedBox(
                        width: double.infinity,
                        height: 200, // 增加高度，便于测试垂直对齐
                        child: Container(
                          alignment: Alignment.topRight,
                          decoration: BoxDecoration(
                            color: getBackgroundColor(),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4.0),
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
                  const Text('字体设置:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: EditableNumberField(
                          label: '字号',
                          value: fontSize,
                          suffix: 'px',
                          min: 1,
                          max: 200,
                          onChanged: (value) {
                            _updateContentProperty('fontSize', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // 字体颜色选择器
                      Tooltip(
                        message: '点击选择字体颜色',
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: getFontColor(),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4.0),
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

                                  // 打印调试信息
                                  developer.log('设置字体颜色: $hexColor');

                                  // 更新属性
                                  // 调用 _updateContentProperty 会自动通知外部更新
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
                          decoration: const InputDecoration(
                            labelText: '字体',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
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
                        message: '点击选择背景颜色',
                        child: Container(
                          width: 44,
                          height: 44,
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
                                      developer.log(
                                          '颜色转换: R=$r, G=$g, B=$b -> $hexColor');
                                    }

                                    // 打印调试信息
                                    developer.log('设置背景颜色: $hexColor');

                                    // 更新属性
                                    // 调用 _updateContentProperty 会自动通知外部更新
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

                  const SizedBox(height: 16.0),

                  // 字体样式
                  const Text('字体样式:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0, // 水平间距
                    runSpacing: 8.0, // 垂直间距
                    children: [
                      // 加粗按钮
                      ElevatedButton.icon(
                        icon: const Icon(Icons.format_bold),
                        label: const Text('粗体'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              fontWeight == 'bold' ? Colors.blue : null,
                          foregroundColor:
                              fontWeight == 'bold' ? Colors.white : null,
                        ),
                        onPressed: () {
                          _updateContentProperty('fontWeight',
                              fontWeight == 'bold' ? 'normal' : 'bold');
                        },
                      ),
                      // 斜体按钮
                      ElevatedButton.icon(
                        icon: const Icon(Icons.format_italic),
                        label: const Text('斜体'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              fontStyle == 'italic' ? Colors.blue : null,
                          foregroundColor:
                              fontStyle == 'italic' ? Colors.white : null,
                        ),
                        onPressed: () {
                          _updateContentProperty('fontStyle',
                              fontStyle == 'italic' ? 'normal' : 'italic');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8.0),

                  Wrap(
                    spacing: 8.0, // 水平间距
                    runSpacing: 8.0, // 垂直间距
                    children: [
                      // 下划线按钮
                      ElevatedButton.icon(
                        icon: const Icon(Icons.format_underlined),
                        label: const Text('下划线'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: underline ? Colors.blue : null,
                          foregroundColor: underline ? Colors.white : null,
                        ),
                        onPressed: () {
                          _updateContentProperty('underline', !underline);
                        },
                      ),
                      // 删除线按钮
                      ElevatedButton.icon(
                        icon: const Icon(Icons.strikethrough_s),
                        label: const Text('删除线'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: lineThrough ? Colors.blue : null,
                          foregroundColor: lineThrough ? Colors.white : null,
                        ),
                        onPressed: () {
                          _updateContentProperty('lineThrough', !lineThrough);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 对齐方式
                  const Text('水平对齐:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ToggleButtons(
                      isSelected: [
                        textAlign == 'left',
                        textAlign == 'center',
                        textAlign == 'right',
                        textAlign == 'justify',
                      ],
                      onPressed: (index) {
                        String newAlign;
                        switch (index) {
                          case 0:
                            newAlign = 'left';
                            break;
                          case 1:
                            newAlign = 'center';
                            break;
                          case 2:
                            newAlign = 'right';
                            break;
                          case 3:
                            newAlign = 'justify';
                            break;
                          default:
                            newAlign = 'left';
                        }
                        _updateContentProperty('textAlign', newAlign);
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.align_horizontal_left),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.align_horizontal_center),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.align_horizontal_right),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.format_align_justify),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // 垂直对齐
                  const Text('垂直对齐:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ToggleButtons(
                      isSelected: [
                        verticalAlign == 'top',
                        verticalAlign == 'middle',
                        verticalAlign == 'bottom',
                        verticalAlign == 'justify',
                      ],
                      onPressed: (index) {
                        String newAlign;
                        switch (index) {
                          case 0:
                            newAlign = 'top';
                            break;
                          case 1:
                            newAlign = 'middle';
                            break;
                          case 2:
                            newAlign = 'bottom';
                            break;
                          case 3:
                            newAlign = 'justify';
                            break;
                          default:
                            newAlign = 'top';
                        }
                        _updateContentProperty('verticalAlign', newAlign);
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.vertical_align_top),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.vertical_align_center),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.vertical_align_bottom),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.format_align_justify),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // 书写方向 (修改后的选项)
                  const Text('书写方向:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      _buildWritingModeButton(
                        mode: 'horizontal-l',
                        label: '横排左书',
                        currentMode: writingMode,
                        icon: Icons.format_textdirection_l_to_r,
                      ),
                      _buildWritingModeButton(
                        mode: 'vertical-r',
                        label: '竖排右书',
                        currentMode: writingMode,
                        icon: Icons.format_textdirection_r_to_l,
                      ),
                      _buildWritingModeButton(
                        mode: 'horizontal-r',
                        label: '横排右书',
                        currentMode: writingMode,
                        icon: Icons.keyboard_double_arrow_left,
                      ),
                      _buildWritingModeButton(
                        mode: 'vertical-l',
                        label: '竖排左书',
                        currentMode: writingMode,
                        icon: Icons.keyboard_double_arrow_right,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 字间距设置
                  const Text('字间距:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  EditableNumberField(
                    label: '字间距',
                    value: letterSpacing,
                    suffix: 'px',
                    min: -5.0,
                    max: 20.0,
                    decimalPlaces: 1,
                    onChanged: (value) {
                      _updateContentProperty('letterSpacing', value);
                    },
                  ),

                  const SizedBox(height: 16.0),

                  // 行间距设置
                  const Text('行高倍数:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  EditableNumberField(
                    label: '行高倍数',
                    value: lineHeight,
                    suffix: 'x',
                    min: 0.5,
                    max: 3.0,
                    decimalPlaces: 1,
                    onChanged: (value) {
                      _updateContentProperty('lineHeight', value);
                    },
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
        // 打印调试信息
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

  // 注意：原来的 _buildNumberField 方法已经被 EditableNumberField 控件替代

  // 辅助方法：构建文本内容输入字段
  Widget _buildTextContentField(String initialText) {
    // 确保控制器内容与初始文本一致
    if (_textController.text != initialText) {
      _textController.text = initialText;
    }

    return TextField(
      controller: _textController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
        // 打印调试信息
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

  // 构建书写方向按钮
  Widget _buildWritingModeButton({
    required String mode,
    required String label,
    required String currentMode,
    required IconData icon,
  }) {
    final isSelected = mode == currentMode;
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : null,
        foregroundColor: isSelected ? Colors.white : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: () {
        _updateContentProperty('writingMode', mode);
      },
    );
  }

  // 颜色选择器对话框
  Future<void> _showColorPicker(BuildContext context, String initialColor,
      Function(Color) onColorSelected) async {
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
          title: const Text('选择颜色'),
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
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
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
              child: const Text('取消'),
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
