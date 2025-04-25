import 'package:flutter/material.dart';

import '../../common/editable_number_field.dart';
import '../practice_edit_controller.dart';
import 'element_common_property_panel.dart';
import 'layer_info_panel.dart';

/// 集字内容属性面板
class CollectionPropertyPanel extends StatefulWidget {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  final Function(String) onUpdateChars;
  final PracticeEditController controller;

  const CollectionPropertyPanel({
    Key? key,
    required this.controller,
    required this.element,
    required this.onElementPropertiesChanged,
    required this.onUpdateChars,
  }) : super(key: key);

  @override
  State<CollectionPropertyPanel> createState() =>
      _CollectionPropertyPanelState();
}

class _CollectionPropertyPanelState extends State<CollectionPropertyPanel> {
  // 当前选中的字符索引
  int _selectedCharIndex = 0;

  // 当前选中字符的候选集字列表
  List<Map<String, dynamic>> _candidateCharacters = [];

  // 文本控制器
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final x = (widget.element['x'] as num).toDouble();
    final y = (widget.element['y'] as num).toDouble();
    final width = (widget.element['width'] as num).toDouble();
    final height = (widget.element['height'] as num).toDouble();
    final rotation = (widget.element['rotation'] as num?)?.toDouble() ?? 0.0;
    final opacity = (widget.element['opacity'] as num?)?.toDouble() ?? 1.0;
    final layerId = widget.element['layerId'] as String?;

    // 获取图层信息
    Map<String, dynamic>? layer;
    if (layerId != null) {
      layer = widget.controller.state.getLayerById(layerId);
    }

    // 集字特有属性
    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 36.0;
    final lineSpacing = (content['lineSpacing'] as num?)?.toDouble() ?? 10.0;
    final letterSpacing = (content['letterSpacing'] as num?)?.toDouble() ?? 5.0;
    final textAlign = content['textAlign'] as String? ?? 'left';
    final verticalAlign = content['verticalAlign'] as String? ?? 'top';
    final writingMode = content['writingMode'] as String? ?? 'horizontal-l';
    final padding = (content['padding'] as num?)?.toDouble() ?? 0.0;
    final fontColor = content['fontColor'] as String? ?? '#000000';
    final backgroundColor =
        content['backgroundColor'] as String? ?? 'transparent';

    return ListView(
      children: [
        // 基本属性部分 (放在最顶部)
        ElementCommonPropertyPanel(
          element: widget.element,
          onElementPropertiesChanged: widget.onElementPropertiesChanged,
          controller: widget.controller,
        ),

        // 图层信息部分
        LayerInfoPanel(layer: layer),

        // 几何属性部分
        ExpansionTile(
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
        ExpansionTile(
          title: const Text('视觉设置'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 字体颜色和背景颜色
                  const Text('颜色设置:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Text('字体颜色:'),
                      const SizedBox(width: 8.0),
                      GestureDetector(
                        onTap: () {
                          _showColorPicker(
                            context,
                            fontColor,
                            (color) {
                              _updateContentProperty(
                                  'fontColor', _colorToHex(color));
                            },
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _hexToColor(fontColor),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      const Text('背景颜色:'),
                      const SizedBox(width: 8.0),
                      GestureDetector(
                        onTap: () {
                          _showColorPicker(
                            context,
                            backgroundColor,
                            (color) {
                              _updateContentProperty(
                                  'backgroundColor', _colorToHex(color));
                            },
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _hexToColor(backgroundColor),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

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

        // 内容设置部分
        ExpansionTile(
          title: const Text('内容设置'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 汉字内容
                  const Text('汉字内容:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  _buildTextContentField(characters),

                  const SizedBox(height: 16.0),

                  // 集字预览
                  const Text('集字预览:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  _buildCharacterPreview(characters),

                  const SizedBox(height: 16.0),

                  // 候选集字
                  const Text('候选集字:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  _buildCandidateCharacters(),

                  const SizedBox(height: 16.0),

                  // 字号设置
                  const Text('字号:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
                          onChanged: (value) {
                            _updateContentProperty('fontSize', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
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
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 字间距设置
                  const Text('字间距:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: letterSpacing,
                          min: 0,
                          max: 50,
                          divisions: 50,
                          label: '${letterSpacing.round()}px',
                          onChanged: (value) {
                            _updateContentProperty('letterSpacing', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
                        child: EditableNumberField(
                          label: '字间距',
                          value: letterSpacing,
                          suffix: 'px',
                          min: 0,
                          max: 100,
                          decimalPlaces: 1,
                          onChanged: (value) {
                            _updateContentProperty('letterSpacing', value);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 行（列）间距设置
                  const Text('行（列）间距:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: lineSpacing,
                          min: 0,
                          max: 50,
                          divisions: 50,
                          label: '${lineSpacing.round()}px',
                          onChanged: (value) {
                            _updateContentProperty('lineSpacing', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
                        child: EditableNumberField(
                          label: '行（列）间距',
                          value: lineSpacing,
                          suffix: 'px',
                          min: 0,
                          max: 100,
                          decimalPlaces: 1,
                          onChanged: (value) {
                            _updateContentProperty('lineSpacing', value);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 水平对齐方式
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

                  // 书写方向
                  const Text('书写方向:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      _buildWritingModeButton(
                        mode: 'horizontal-l',
                        label: '横排左起',
                        currentMode: writingMode,
                        icon: Icons.format_textdirection_l_to_r,
                      ),
                      _buildWritingModeButton(
                        mode: 'vertical-r',
                        label: '竖排右起',
                        currentMode: writingMode,
                        icon: Icons.format_textdirection_r_to_l,
                      ),
                      _buildWritingModeButton(
                        mode: 'horizontal-r',
                        label: '横排右起',
                        currentMode: writingMode,
                        icon: Icons.keyboard_double_arrow_left,
                      ),
                      _buildWritingModeButton(
                        mode: 'vertical-l',
                        label: '竖排左起',
                        currentMode: writingMode,
                        icon: Icons.keyboard_double_arrow_right,
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

  @override
  void didUpdateWidget(CollectionPropertyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element != widget.element) {
      // 更新文本控制器
      final content = widget.element['content'] as Map<String, dynamic>;
      final characters = content['characters'] as String? ?? '';
      if (_textController.text != characters) {
        _textController.text = characters;
      }

      _loadCandidateCharacters();
    }
  }

  @override
  void dispose() {
    // 释放文本控制器
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 初始化文本控制器
    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    _textController.text = characters;

    _loadCandidateCharacters();
  }

  // 构建候选集字
  Widget _buildCandidateCharacters() {
    if (_candidateCharacters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: const Center(
          child: Text('无候选集字', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    final selectedChar = _selectedCharIndex < characters.length
        ? characters[_selectedCharIndex]
        : '';

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: List.generate(
          _candidateCharacters.length,
          (index) => Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '$selectedChar${_getSubscript(index + 1)}',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: index == 0 ? Colors.green : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建集字预览
  Widget _buildCharacterPreview(String characters) {
    if (characters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: const Center(
          child: Text('无集字内容', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: List.generate(
          characters.characters.length,
          (index) => GestureDetector(
            onTap: () => _selectCharacter(index),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedCharIndex == index
                      ? Colors.blue
                      : Colors.grey.shade300,
                  width: _selectedCharIndex == index ? 2.0 : 1.0,
                ),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Center(
                child: Text(
                  characters.characters.elementAt(index),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: _selectedCharIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _selectedCharIndex == index
                        ? Colors.blue
                        : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建文本内容输入字段
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
        widget.onUpdateChars(value);
        // 重置选中的字符索引
        setState(() {
          _selectedCharIndex = 0;
        });
        _loadCandidateCharacters();
      },
    );
  }

  // 构建书写模式按钮
  Widget _buildWritingModeButton({
    required String mode,
    required String label,
    required String currentMode,
    required IconData icon,
  }) {
    final isSelected = currentMode == mode;

    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : null,
        foregroundColor: isSelected ? Colors.white : null,
      ),
      onPressed: () {
        _updateContentProperty('writingMode', mode);
      },
    );
  }

  /// 将颜色转换为十六进制字符串
  String _colorToHex(Color color) {
    if (color == Colors.transparent) {
      return 'transparent';
    }

    try {
      // 将 RGB 值转换为十六进制
      final r = color.red.toRadixString(16).padLeft(2, '0');
      final g = color.green.toRadixString(16).padLeft(2, '0');
      final b = color.blue.toRadixString(16).padLeft(2, '0');
      final colorCode = '$r$g$b'.toUpperCase();

      debugPrint(
          'Converting color to hex: $color (R:${color.red}, G:${color.green}, B:${color.blue}) -> #$colorCode');
      return '#$colorCode'; // 包含 # 前缀
    } catch (e) {
      debugPrint('Error converting color to hex: $e');
      return '#000000'; // 出错时返回默认黑色
    }
  }

  // 获取下标
  String _getSubscript(int number) {
    const Map<String, String> subscripts = {
      '0': '₀',
      '1': '₁',
      '2': '₂',
      '3': '₃',
      '4': '₄',
      '5': '₅',
      '6': '₆',
      '7': '₇',
      '8': '₈',
      '9': '₉',
    };

    final String numberStr = number.toString();
    final StringBuffer result = StringBuffer();

    for (int i = 0; i < numberStr.length; i++) {
      result.write(subscripts[numberStr[i]] ?? numberStr[i]);
    }

    return result.toString();
  }

  /// 将十六进制颜色字符串转换为Color对象
  Color _hexToColor(String hexString) {
    if (hexString == 'transparent') {
      return Colors.transparent;
    }

    try {
      final buffer = StringBuffer();
      if (hexString.startsWith('#')) {
        if (hexString.length == 7) {
          // #RRGGBB format
          buffer.write('ff'); // Add full opacity
          buffer.write(hexString.substring(1));
        } else if (hexString.length == 9) {
          // #AARRGGBB format
          buffer.write(hexString.substring(1));
        } else {
          debugPrint('Invalid color format: $hexString');
          return Colors.black; // Invalid format
        }
      } else {
        if (hexString.length == 6) {
          buffer.write('ff'); // Add full opacity
          buffer.write(hexString);
        } else {
          debugPrint('Invalid color format: $hexString');
          return Colors.black;
        }
      }

      final hexValue = buffer.toString();
      final colorValue = int.parse(hexValue, radix: 16);
      final color = Color(colorValue);

      debugPrint('Parsed color: $hexString -> 0x$hexValue -> $color');

      return color;
    } catch (e) {
      debugPrint('解析颜色失败: $e, hexString: $hexString');
      return Colors.black;
    }
  }

  // 加载候选集字
  void _loadCandidateCharacters() {
    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';

    if (characters.isNotEmpty && _selectedCharIndex < characters.length) {
      // 这里应该从数据库加载候选集字
      // 暂时使用模拟数据
      setState(() {
        _candidateCharacters = List.generate(
            6,
            (index) => {
                  'id': 'char_$index',
                  'character': characters[_selectedCharIndex],
                  'thumbnailPath': '', // 实际应该是真实路径
                });
      });
    } else {
      setState(() {
        _candidateCharacters = [];
      });
    }
  }

  // 选择字符
  void _selectCharacter(int index) {
    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';

    if (index >= 0 && index < characters.length) {
      setState(() {
        _selectedCharIndex = index;
      });
      _loadCandidateCharacters();
    }
  }

  /// 显示颜色选择器对话框
  void _showColorPicker(
    BuildContext context,
    String initialColor,
    Function(Color) onColorSelected,
  ) {
    // 预设颜色列表
    final presetColors = [
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

    // 解析初始颜色（仅用于调试）
    debugPrint('显示颜色选择器，初始颜色: $initialColor');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择颜色'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: presetColors.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  onColorSelected(presetColors[index]);
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: presetColors[index],
                    border: Border.all(
                      color: presetColors[index] == Colors.white ||
                              presetColors[index] == Colors.transparent
                          ? Colors.grey
                          : presetColors[index],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: presetColors[index] == Colors.transparent
                      ? const Center(
                          child: Text('透明', style: TextStyle(fontSize: 10)))
                      : null,
                ),
              );
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('取消'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // 更新内容属性
  void _updateContentProperty(String key, dynamic value) {
    final content = Map<String, dynamic>.from(
        widget.element['content'] as Map<String, dynamic>? ?? {});
    content[key] = value;
    _updateProperty('content', content);
  }

  // 更新属性
  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    widget.onElementPropertiesChanged(updates);
  }
}
