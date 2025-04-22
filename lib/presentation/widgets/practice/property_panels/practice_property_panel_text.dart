import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../practice_edit_controller.dart';
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
  // 字号控制器
  static final TextEditingController _fontSizeController =
      TextEditingController();

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

    // 初始化字号控制器
    if (_fontSizeController.text != fontSize.toString()) {
      _fontSizeController.text = fontSize.toString();
    }

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
                        child: _buildNumberField(
                          label: 'X',
                          value: x,
                          onChanged: (value) => _updateProperty('x', value),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: _buildNumberField(
                          label: 'Y',
                          value: y,
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
                        child: _buildNumberField(
                          label: '宽度',
                          value: width,
                          onChanged: (value) => _updateProperty('width', value),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: _buildNumberField(
                          label: '高度',
                          value: height,
                          onChanged: (value) =>
                              _updateProperty('height', value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // 旋转角度
                  _buildNumberField(
                    label: '旋转',
                    value: rotation,
                    suffix: '°',
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
                  // 透明度滑块
                  const Text('透明度:'),
                  Row(
                    children: [
                      Expanded(
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            return Slider(
                              value: opacity,
                              min: 0.0,
                              max: 1.0,
                              divisions: 100,
                              label: '${(opacity * 100).toStringAsFixed(0)}%',
                              onChanged: (value) {
                                setState(() {});
                                _updateProperty('opacity', value);
                              },
                              onChangeEnd: (value) {
                                _updateProperty('opacity', value);
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text('${(opacity * 100).toStringAsFixed(0)}%'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 内边距设置
                  const Text('内边距:'),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: padding,
                          min: 0.0,
                          max: 30.0,
                          divisions: 30,
                          label: padding.toStringAsFixed(0),
                          onChanged: (value) {
                            _updateContentProperty('padding', value);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text('${padding.toStringAsFixed(0)}px'),
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
                        child: TextField(
                          controller: _fontSizeController,
                          decoration: const InputDecoration(
                            labelText: '字号',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            // 尝试解析字体大小
                            final newValue = double.tryParse(value);
                            if (newValue != null && newValue > 0) {
                              _updateContentProperty('fontSize', newValue);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // 字体颜色选择器
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: getFontColor(),
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: InkWell(
                          onTap: () =>
                              _showColorPicker(context, fontColor, (color) {
                            // 转换颜色为十六进制
                            final hexColor =
                                '#${(color.r.round() << 16 | color.g.round() << 8 | color.b.round()).toRadixString(16).padLeft(6, '0').toUpperCase()}';
                            _updateContentProperty('fontColor', hexColor);
                          }),
                          child:
                              const Icon(Icons.colorize, color: Colors.white),
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
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: getBackgroundColor(),
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: InkWell(
                          onTap: () => _showColorPicker(
                              context,
                              backgroundColor == 'transparent'
                                  ? '#00FFFFFF'
                                  : backgroundColor, (color) {
                            if (color.a == 0) {
                              _updateContentProperty(
                                  'backgroundColor', 'transparent');
                            } else {
                              _updateContentProperty('backgroundColor',
                                  '#${(color.r.round() << 16 | color.g.round() << 8 | color.b.round()).toRadixString(16).padLeft(6, '0').toUpperCase()}');
                            }
                          }),
                          child: backgroundColor == 'transparent'
                              ? const Icon(Icons.format_color_reset,
                                  color: Colors.grey)
                              : const Icon(Icons.format_color_fill,
                                  color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 字体样式
                  const Text('字体样式:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
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
                      const SizedBox(width: 8.0),
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

                  Row(
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
                      const SizedBox(width: 8.0),
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
                  ToggleButtons(
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
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(Icons.align_horizontal_left),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(Icons.align_horizontal_center),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(Icons.align_horizontal_right),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(Icons.format_align_justify),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 垂直对齐
                  const Text('垂直对齐:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  ToggleButtons(
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
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(Icons.vertical_align_top),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(Icons.vertical_align_center),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(Icons.vertical_align_bottom),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(Icons.format_align_justify),
                      ),
                    ],
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
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: letterSpacing,
                          min: -5.0,
                          max: 20.0,
                          divisions: 50,
                          label: letterSpacing.toStringAsFixed(1),
                          onChanged: (value) {
                            _updateContentProperty('letterSpacing', value);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text('${letterSpacing.toStringAsFixed(1)}px'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 行间距设置
                  const Text('行高倍数:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: lineHeight,
                          min: 0.5,
                          max: 3.0,
                          divisions: 25,
                          label: lineHeight.toStringAsFixed(1),
                          onChanged: (value) {
                            _updateContentProperty('lineHeight', value);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text('${lineHeight.toStringAsFixed(1)}x'),
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

  // 辅助方法：横排左书（从左到右）
  Widget _buildHorizontalLeftToRight(
      String text, TextStyle style, String textAlign) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 对于 justify 对齐，我们需要使用单个 Text 组件包含所有文本
        if (textAlign == 'justify') {
          return SingleChildScrollView(
            child: SizedBox(
              width: constraints.maxWidth,
              child: Text(
                text,
                style: style,
                textAlign: _getTextAlign(textAlign),
              ),
            ),
          );
        }

        // 对于其他对齐方式，我们使用每行一个 Text 组件
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: _getColumnAlignment(textAlign),
            mainAxisSize: MainAxisSize.min,
            children: _splitTextToLines(text).map((line) {
              return SizedBox(
                width: constraints.maxWidth, // 使用父容器的实际宽度
                child: Text(
                  line,
                  style: style,
                  textAlign: _getTextAlign(textAlign),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // 辅助方法：横排右书（从右到左）
  Widget _buildHorizontalRightToLeft(
      String text, TextStyle style, String textAlign) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 对于 justify 对齐，我们需要使用单个 Text 组件包含所有文本
        if (textAlign == 'justify') {
          // 反转整个文本，但保持换行符
          final lines = _splitTextToLines(text);
          final reversedLines = lines
              .map((line) => String.fromCharCodes(line.runes.toList().reversed))
              .toList();
          final reversedText = reversedLines.join('\n');

          return SingleChildScrollView(
            child: SizedBox(
              width: constraints.maxWidth,
              child: Text(
                reversedText,
                style: style,
                textAlign: _getTextAlign(textAlign),
              ),
            ),
          );
        }

        // 对于其他对齐方式，我们使用每行一个 Text 组件
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: _getColumnAlignment(textAlign),
            mainAxisSize: MainAxisSize.min,
            children: _splitTextToLines(text).map((line) {
              // 反转每一行文本，实现从右到左阅读
              return SizedBox(
                width: constraints.maxWidth, // 使用父容器的实际宽度
                child: Text(
                  String.fromCharCodes(line.runes.toList().reversed),
                  style: style,
                  textAlign: _getTextAlign(textAlign),
                ),
              );
            }).toList(),
          ),
        );
      },
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
    // 创建文本装饰列表
    final List<TextDecoration> decorations = [];
    if (underline) decorations.add(TextDecoration.underline);
    if (lineThrough) decorations.add(TextDecoration.lineThrough);

    // 解析颜色
    Color parsedFontColor;
    try {
      parsedFontColor = Color(int.parse(fontColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      parsedFontColor = Colors.black;
    }

    // 创建基本文本样式
    final TextStyle textStyle = TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
      fontStyle: fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
      color: parsedFontColor,
      letterSpacing: letterSpacing,
      height: lineHeight,
      decoration: decorations.isEmpty
          ? TextDecoration.none
          : TextDecoration.combine(decorations),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // 创建包含垂直对齐的容器
        Widget buildAlignedContainer(Widget child) {
          // 处理垂直对齐
          Alignment alignment;
          switch (verticalAlign) {
            case 'top':
              alignment = Alignment.topCenter;
              break;
            case 'middle':
              alignment = Alignment.center;
              break;
            case 'bottom':
              alignment = Alignment.bottomCenter;
              break;
            case 'justify':
              // 对于垂直对齐为 justify 时，我们使用特殊处理
              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: child,
              );
            default:
              alignment = Alignment.topCenter;
          }

          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            alignment: alignment,
            child: child,
          );
        }

        // 根据书写模式选择不同的渲染方式
        Widget textWidget;
        if (writingMode == 'horizontal-r') {
          textWidget = _buildHorizontalRightToLeft(text, textStyle, textAlign);
        } else {
          textWidget = _buildHorizontalLeftToRight(text, textStyle, textAlign);
        }

        // 应用垂直对齐
        return buildAlignedContainer(textWidget);
      },
    );
  }

  // 辅助方法：构建数字输入字段
  Widget _buildNumberField({
    required String label,
    required double value,
    String suffix = '',
    required Function(double) onChanged,
  }) {
    final controller = TextEditingController(text: value.toString());
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffix: Text(suffix),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final newValue = double.tryParse(value);
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }

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

  // 统一的垂直文本布局方法，处理从右到左和从左到右两种模式
  Widget _buildVerticalTextLayout({
    required String text,
    required TextStyle style,
    required String verticalAlign,
    required String textAlign,
    required BoxConstraints constraints,
    required bool isRightToLeft,
  }) {
    if (text.isEmpty) {
      text = '预览文本内容\n第二行文本\n第三行文本';
    }

    // 处理行和字符
    List<String> lines = text.split('\n');

    // 如果是从右到左模式，反转行顺序
    if (isRightToLeft) {
      lines = lines.reversed.toList();
    }

    // 计算每列可容纳的最大字符数
    final charHeight = style.fontSize ?? 16.0;
    final effectiveLineHeight = style.height ?? 1.2;
    final effectiveLetterSpacing = style.letterSpacing ?? 0.0;
    final maxCharsPerColumn = _calculateMaxCharsPerColumn(
      constraints.maxHeight,
      charHeight,
      effectiveLineHeight,
      effectiveLetterSpacing,
    );

    // 生成所有列的数据
    final allColumns = <Widget>[];
// 为每一行创建列，并记录每行的起始位置
    int lineStartIndex = 0;
    for (final line in lines) {
      final chars = line.characters.toList();
      int charIdx = 0;
      final lineStartIndex = allColumns.length; // 记录这一行的起始位置

      while (charIdx < chars.length) {
        // 计算当前列要显示多少字符
        final charsInThisColumn =
            math.min(maxCharsPerColumn, chars.length - charIdx);
        final columnChars = chars.sublist(charIdx, charIdx + charsInThisColumn);

        // 创建当前列的Widget
        final columnWidget = Container(
          width: charHeight * 1.5, // 设置固定宽度，基于字体大小
          height: constraints.maxHeight,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          alignment: _getVerticalAlignment(verticalAlign),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: _getVerticalMainAlignment(textAlign),
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: _getVerticalMainAlignment(textAlign),
                    children: columnChars.map((char) {
                      // 确保 letterSpacing 不为负值
                      final effectivePadding = effectiveLetterSpacing > 0
                          ? effectiveLetterSpacing
                          : 0.0;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: effectivePadding,
                        ),
                        child: Text(
                          char,
                          style: style,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );

        // 按照书写方向决定列的添加位置
        if (isRightToLeft) {
          // 竖排左书：将新列插入到这一行的起始位置，确保超长的部分出现在左侧
          allColumns.insert(lineStartIndex, columnWidget);
        } else {
          // 竖排右书：新列添加到末尾，保持从左到右的顺序
          allColumns.add(columnWidget);
        }
        charIdx += charsInThisColumn;
      }

      // 在每行末尾添加分隔符，除非是最后一行
      // if (line != lines.last) {
      //   allColumns.add(
      //     Container(
      //       width: 1,
      //       height: constraints.maxHeight,
      //       margin: const EdgeInsets.symmetric(horizontal: 8.0),
      //       color: Colors.grey.withAlpha(77),
      //     ),
      //   );
      // }
    }

    // 确保有内容显示，即使没有文本
    if (allColumns.isEmpty) {
      return SizedBox(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        child: const Center(
          child: Text(
            '暂无内容',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // 根据书写方向确定列的排列顺序
    // 根据书写方向确定列的排列顺序：
    // 竖排左书(isRightToLeft=true) - 从右向左显示
    // 竖排右书(isRightToLeft=false) - 从左向右显示
    final List<Widget> columns =
        !isRightToLeft ? allColumns.reversed.toList() : allColumns;

    // 创建ScrollController，用于控制滚动位置
    final ScrollController scrollController = ScrollController();

    // 布局完成后设置滚动位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        if (isRightToLeft) {
          // 竖排左书，滚动到最右侧
          scrollController.jumpTo(0);
        } else {
          // 竖排右书，滚动到最左侧
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      }
    });

    return SizedBox(
      width: constraints.maxWidth,
      child: Align(
        alignment: isRightToLeft ? Alignment.centerRight : Alignment.centerLeft,
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            textDirection:
                isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: _getRowCrossAlignment(verticalAlign),
            children: columns,
          ),
        ),
      ),
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
    // 创建文本装饰列表
    final List<TextDecoration> decorations = [];
    if (underline) decorations.add(TextDecoration.underline);
    if (lineThrough) decorations.add(TextDecoration.lineThrough);

    // 解析颜色
    Color parsedFontColor;
    try {
      parsedFontColor = Color(int.parse(fontColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      parsedFontColor = Colors.black;
    }

    // 创建基本文本样式
    final TextStyle textStyle = TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
      fontStyle: fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
      color: parsedFontColor,
      letterSpacing: letterSpacing,
      height: lineHeight,
      decoration: decorations.isEmpty
          ? TextDecoration.none
          : TextDecoration.combine(decorations),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据书写模式选择不同的渲染方式
        Widget contentWidget;
        if (writingMode == 'vertical-r') {
          contentWidget = _buildVerticalTextLayout(
            text: text,
            style: textStyle,
            verticalAlign: verticalAlign,
            textAlign: textAlign,
            constraints: constraints,
            isRightToLeft: false,
          );
        } else {
          // vertical-l
          contentWidget = _buildVerticalTextLayout(
            text: text,
            style: textStyle,
            verticalAlign: verticalAlign,
            textAlign: textAlign,
            constraints: constraints,
            isRightToLeft: true,
          );
        }

        // 注意：这里不需要使用 ScrollController 和对齐方式
        // 因为内容已经在 _buildVerticalTextLayout 中处理了

        return Container(
          alignment: Alignment.centerRight,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: ClipRect(clipBehavior: Clip.hardEdge, child: contentWidget),
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

  // 计算每列最多可容纳的字符数
  int _calculateMaxCharsPerColumn(double maxHeight, double charHeight,
      double lineHeight, double letterSpacing) {
    // 计算单个字符的有效高度（包括行高和字间距）
    final effectiveCharHeight = charHeight * lineHeight + letterSpacing;

    // 计算可容纳的最大字符数（向下取整）
    return (maxHeight / effectiveCharHeight).floor();
  }

  // 辅助方法：获取列对齐方式
  CrossAxisAlignment _getColumnAlignment(String textAlign) {
    switch (textAlign) {
      case 'left':
        return CrossAxisAlignment.start;
      case 'center':
        return CrossAxisAlignment.center;
      case 'right':
        return CrossAxisAlignment.end;
      case 'justify':
        return CrossAxisAlignment.stretch;
      default:
        return CrossAxisAlignment.start;
    }
  }

  // 获取行的交叉轴对齐方式 (用于垂直文本中的行对齐)
  CrossAxisAlignment _getRowCrossAlignment(String verticalAlign) {
    switch (verticalAlign) {
      case 'top': // 在垂直模式中对应左对齐
        return CrossAxisAlignment.start;
      case 'middle':
        return CrossAxisAlignment.center;
      case 'bottom': // 在垂直模式中对应右对齐
        return CrossAxisAlignment.end;
      case 'justify':
        return CrossAxisAlignment.stretch;
      default:
        return CrossAxisAlignment.center;
    }
  }

  // 辅助方法：获取文本对齐方式
  TextAlign _getTextAlign(String textAlign) {
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
  }

  // 获取垂直对齐方式（用于Container的alignment属性）
  Alignment _getVerticalAlignment(String textAlign) {
    switch (textAlign) {
      case 'left': // 在垂直模式中对应顶部对齐
        return Alignment.topCenter;
      case 'center':
        return Alignment.center;
      case 'right': // 在垂直模式中对应底部对齐
        return Alignment.bottomCenter;
      case 'justify':
        return Alignment.center; // justify使用center，实际布局由内部控制
      default:
        return Alignment.topCenter;
    }
  }

  // 获取垂直方向主轴对齐方式
  MainAxisAlignment _getVerticalMainAlignment(String textAlign) {
    switch (textAlign) {
      case 'left': // 在垂直模式中对应顶部对齐
        return MainAxisAlignment.start;
      case 'center':
        return MainAxisAlignment.center;
      case 'right': // 在垂直模式中对应底部对齐
        return MainAxisAlignment.end;
      case 'justify':
        return MainAxisAlignment.spaceBetween;
      default:
        return MainAxisAlignment.start;
    }
  }

  // 颜色选择器对话框
  Future<void> _showColorPicker(BuildContext context, String initialColor,
      Function(Color) onColorSelected) async {
    Color currentColor;
    if (initialColor == 'transparent') {
      currentColor = Colors.transparent;
    } else {
      try {
        currentColor = Color(int.parse(initialColor.replaceFirst('#', '0xFF')));
      } catch (e) {
        currentColor = Colors.black;
      }
    }

    // 构建颜色选择器
    // 在实际应用中，你应该使用专门的颜色选择器库
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
                return InkWell(
                  onTap: () {
                    onColorSelected(colors[index]);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors[index],
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: colors[index] == currentColor
                          ? Icon(
                              Icons.check,
                              color: colors[index] == Colors.white ||
                                      colors[index] == Colors.transparent
                                  ? Colors.black
                                  : Colors.white,
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

  // 辅助方法：将文本分割为行
  List<String> _splitTextToLines(String text) {
    return text.split('\n');
  }

  // 更新内容属性
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
