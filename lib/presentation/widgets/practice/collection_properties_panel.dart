import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'character_selection_panel.dart';

/// 集字内容属性面板
class CollectionPropertiesPanel extends StatefulWidget {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onPropertyChanged;

  const CollectionPropertiesPanel({
    Key? key,
    required this.element,
    required this.onPropertyChanged,
  }) : super(key: key);

  @override
  State<CollectionPropertiesPanel> createState() =>
      _CollectionPropertiesPanelState();
}

class _CollectionPropertiesPanelState extends State<CollectionPropertiesPanel> {
  late TextEditingController _charactersController;
  String? _selectedCharacter;
  bool _showCharSelection = false;

  @override
  Widget build(BuildContext context) {
    final content = widget.element['content'] as Map<String, dynamic>;
    final double fontSize = (content['fontSize'] as num?)?.toDouble() ?? 24.0;
    final String fontColor = content['fontColor'] as String? ?? '#000000';
    final String backgroundColor =
        content['backgroundColor'] as String? ?? '#FFFFFF';
    final String direction = content['direction'] as String? ?? 'horizontal';
    final double charSpacing =
        (content['charSpacing'] as num?)?.toDouble() ?? 10.0;
    final double lineSpacing =
        (content['lineSpacing'] as num?)?.toDouble() ?? 10.0;
    final bool showGrid = content['gridLines'] as bool? ?? false;
    final bool showBackground = content['showBackground'] as bool? ?? true;

    // 如果正在显示字符选择面板，则显示
    if (_showCharSelection && _selectedCharacter != null) {
      return CharacterSelectionPanel(
        character: _selectedCharacter!,
        currentStyle: '楷书', // 实际应用中，应该传入当前字符的样式
        onCharacterSelected: _onCharacterStyleSelected,
        onCancel: _closeCharacterSelectionPanel,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '集字内容属性',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 字符内容输入
          const Text('字符内容:'),
          const SizedBox(height: 8),
          TextField(
            controller: _charactersController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '输入要集字的字符',
            ),
            onChanged: (value) {
              _updateContentProperty('characters', value);
            },
          ),
          const SizedBox(height: 16),

          // 集字预览
          const Text('集字预览:'),
          const SizedBox(height: 8),
          _buildCharPreview(),
          const SizedBox(height: 16),

          // 字体大小
          const Text('字体大小:'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: fontSize,
                  min: 12.0,
                  max: 72.0,
                  divisions: 60,
                  label: fontSize.round().toString(),
                  onChanged: (value) {
                    _updateContentProperty('fontSize', value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 50,
                child: TextField(
                  controller:
                      TextEditingController(text: fontSize.round().toString()),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final newValue = int.tryParse(value);
                      if (newValue != null) {
                        _updateContentProperty('fontSize', newValue.toDouble());
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 方向设置
          const Text('排列方向:'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: direction,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'horizontal', child: Text('水平')),
              DropdownMenuItem(value: 'vertical', child: Text('垂直')),
            ],
            onChanged: (value) {
              if (value != null) {
                _updateContentProperty('direction', value);
              }
            },
          ),
          const SizedBox(height: 16),

          // 间距设置
          const Text('间距设置:'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: '字符间距',
                  value: charSpacing,
                  min: 0,
                  max: 50,
                  onChanged: (value) {
                    _updateContentProperty('charSpacing', value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNumberField(
                  label: '行间距',
                  value: lineSpacing,
                  min: 0,
                  max: 50,
                  onChanged: (value) {
                    _updateContentProperty('lineSpacing', value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 颜色设置
          const Text('颜色设置:'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('字体颜色:'),
              const SizedBox(width: 8),
              _buildColorPicker(
                color: _hexToColor(fontColor),
                onColorChanged: (color) {
                  final hexColor =
                      '#${color.value.toRadixString(16).substring(2)}';
                  _updateContentProperty('fontColor', hexColor);
                },
              ),
              const SizedBox(width: 16),
              const Text('背景颜色:'),
              const SizedBox(width: 8),
              _buildColorPicker(
                color: _hexToColor(backgroundColor),
                onColorChanged: (color) {
                  final hexColor =
                      '#${color.value.toRadixString(16).substring(2)}';
                  _updateContentProperty('backgroundColor', hexColor);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 显示选项
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('显示网格线'),
                  value: showGrid,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    _updateContentProperty('gridLines', value ?? false);
                  },
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('显示背景'),
                  value: showBackground,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    _updateContentProperty('showBackground', value ?? true);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 风格应用按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.style),
                label: const Text('应用楷书风格到全部'),
                onPressed: () => _applyStyleToAll('楷书'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(CollectionPropertiesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element != widget.element) {
      final content = widget.element['content'] as Map<String, dynamic>;
      final characters = content['characters'] as String? ?? '';

      // 仅在文本实际变化时更新控制器，避免光标位置重置
      if (_charactersController.text != characters) {
        _charactersController.text = characters;
      }
    }
  }

  @override
  void dispose() {
    _charactersController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    _charactersController = TextEditingController(text: characters);
  }

  /// 应用所选风格到所有字符
  void _applyStyleToAll(String style) {
    // 实际应用中，应该将选中的风格应用到所有字符
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已将$style风格应用到所有字符')),
    );
  }

  /// 构建单个字符框
  Widget _buildCharBox(
      String char, double fontSize, String colorStr, bool showGrid) {
    final color = _hexToColor(colorStr);
    final boxSize = fontSize * 1.5;

    return InkWell(
      onTap: () => _showCharacterSelectionPanel(char),
      child: Container(
        width: boxSize,
        height: boxSize,
        decoration: BoxDecoration(
          border:
              showGrid ? Border.all(color: Colors.grey.withOpacity(0.5)) : null,
        ),
        child: Center(
          child: Text(
            char,
            style: TextStyle(
              fontSize: fontSize,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建字符预览
  Widget _buildCharPreview() {
    final content = widget.element['content'] as Map<String, dynamic>;
    final String characters = content['characters'] as String? ?? '';
    final double fontSize = (content['fontSize'] as num?)?.toDouble() ?? 24.0;
    final String fontColor = content['fontColor'] as String? ?? '#000000';
    final String backgroundColor =
        content['backgroundColor'] as String? ?? '#FFFFFF';
    final String direction = content['direction'] as String? ?? 'horizontal';
    final double charSpacing =
        (content['charSpacing'] as num?)?.toDouble() ?? 10.0;
    final double lineSpacing =
        (content['lineSpacing'] as num?)?.toDouble() ?? 10.0;
    final bool showGrid = content['gridLines'] as bool? ?? false;

    if (characters.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text('无内容，请输入字符'),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
        color: _hexToColor(backgroundColor),
      ),
      padding: const EdgeInsets.all(8),
      child: direction == 'horizontal'
          ? Wrap(
              spacing: charSpacing,
              runSpacing: lineSpacing,
              children: characters.split('').map((char) {
                return _buildCharBox(char, fontSize, fontColor, showGrid);
              }).toList(),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: characters.split('').map((char) {
                return Padding(
                  padding: EdgeInsets.only(bottom: lineSpacing),
                  child: _buildCharBox(char, fontSize, fontColor, showGrid),
                );
              }).toList(),
            ),
    );
  }

  /// 构建颜色选择器
  Widget _buildColorPicker({
    required Color color,
    required Function(Color) onColorChanged,
  }) {
    return GestureDetector(
      onTap: () {
        _showColorPicker(context, color, onColorChanged);
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// 构建数值输入字段
  Widget _buildNumberField({
    required String label,
    required double value,
    double min = 0,
    double max = 100,
    required Function(double) onChanged,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      keyboardType: TextInputType.number,
      controller: TextEditingController(text: value.toString()),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (text) {
        if (text.isNotEmpty) {
          final newValue = double.tryParse(text);
          if (newValue != null) {
            final clampedValue = newValue.clamp(min, max);
            onChanged(clampedValue);
          }
        }
      },
    );
  }

  /// 关闭字符选择面板
  void _closeCharacterSelectionPanel() {
    setState(() {
      _showCharSelection = false;
      _selectedCharacter = null;
    });
  }

  /// 将十六进制颜色字符串转换为Color对象
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// 当字形被选择时
  void _onCharacterStyleSelected(String style, String charId) {
    // 实际应用中，这里应该根据选择的字形更新数据
    // 例如更新该字符的样式、图片URL等

    // 简化处理：假设更新为选中的风格
    // 实际实现应该对应更新用于渲染的字形图片或样式信息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已应用$style风格的字形')),
    );

    _closeCharacterSelectionPanel();
  }

  /// 显示字符选择面板
  void _showCharacterSelectionPanel(String character) {
    setState(() {
      _selectedCharacter = character;
      _showCharSelection = true;
    });
  }

  /// 显示颜色选择器对话框
  void _showColorPicker(
    BuildContext context,
    Color initialColor,
    Function(Color) onColorChanged,
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
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择颜色'),
        content: SizedBox(
          width: 300,
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
                  onColorChanged(presetColors[index]);
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: presetColors[index],
                    border: Border.all(
                      color: presetColors[index] == Colors.white
                          ? Colors.grey
                          : presetColors[index],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 更新属性
  void _updateContentProperty(String key, dynamic value) {
    final Map<String, dynamic> content = Map<String, dynamic>.from(
        widget.element['content'] as Map<String, dynamic>);
    content[key] = value;

    widget.onPropertyChanged({'content': content});
  }
}
