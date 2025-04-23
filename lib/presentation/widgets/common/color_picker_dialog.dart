import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 颜色选择器对话框
class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorSelected;

  const ColorPickerDialog({
    Key? key,
    required this.initialColor,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;
  late TextEditingController _hexController;
  bool _isValidHex = true;

  // 预设颜色列表
  final List<Color> _presetColors = [
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择颜色'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 颜色预览
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: _selectedColor,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // 颜色代码输入
            TextField(
              controller: _hexController,
              decoration: InputDecoration(
                labelText: '颜色代码',
                helperText: '输入6位十六进制颜色代码 (例如: FF5500)',
                prefixText: '#',
                border: const OutlineInputBorder(),
                errorText: _isValidHex ? null : '无效的颜色代码',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (value) {
                if (value.length == 6) {
                  try {
                    final color = _hexToColor(value);
                    setState(() {
                      _selectedColor = color;
                      _isValidHex = true;
                    });
                  } catch (e) {
                    setState(() {
                      _isValidHex = false;
                    });
                  }
                } else if (value.isNotEmpty) {
                  setState(() {
                    _isValidHex = value.length < 6;
                  });
                }
              },
              onSubmitted: (value) {
                if (value.length == 6) {
                  try {
                    final color = _hexToColor(value);
                    setState(() {
                      _selectedColor = color;
                      _isValidHex = true;
                    });
                  } catch (e) {
                    setState(() {
                      _isValidHex = false;
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 16),

            // 预设颜色网格
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: _presetColors.length,
                itemBuilder: (context, index) {
                  final color = _presetColors[index];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                        _hexController.text = _colorToHex(color).toUpperCase();
                        _isValidHex = true;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                          color: color == Colors.white ? Colors.grey : color,
                          width: _selectedColor.value == color.value ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _selectedColor.value == color.value
                          ? Icon(
                              Icons.check,
                              color: _getContrastingColor(color),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isValidHex
              ? () {
                  widget.onColorSelected(_selectedColor);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('确定'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _hexController = TextEditingController(
      text: _colorToHex(_selectedColor).toUpperCase(),
    );
  }

  /// 将颜色转换为十六进制字符串（不含#前缀）
  String _colorToHex(Color color) {
    try {
      // 使用安全的方式转换颜色
      final hex = color.toString();
      // 格式会是 Color(0xAARRGGBB) 或 Color(0xFFRRGGBB)
      final hexCode = hex.split('(0x')[1].split(')')[0];
      // 取后6位，即RRGGBB
      final colorCode =
          hexCode.length > 6 ? hexCode.substring(hexCode.length - 6) : hexCode;
      return colorCode; // 不包含 # 前缀
    } catch (e) {
      debugPrint('Error converting color to hex: $e');
      return 'FFFFFF'; // 出错时返回默认白色
    }
  }

  /// 获取对比色，用于在背景色上显示文本
  Color _getContrastingColor(Color color) {
    // 计算亮度（简化版本）
    final double brightness =
        (0.299 * color.r + 0.587 * color.g + 0.114 * color.b) / 255;

    // 对于亮色使用黑色文本，对于暗色使用白色文本
    return brightness > 0.5 ? Colors.black : Colors.white;
  }

  /// 将十六进制字符串转换为颜色
  Color _hexToColor(String hex) {
    try {
      // 处理空字符串或无效输入
      if (hex.isEmpty) {
        debugPrint('Empty color string, returning default black');
        return Colors.black;
      }

      // 移除 # 前缀（如果有）
      String cleanHex = hex.replaceFirst('#', '');

      // 确保字符串长度正确
      if (cleanHex.length > 6) {
        cleanHex = cleanHex.substring(0, 6);
      } else if (cleanHex.length < 6) {
        // 如果字符串太短，填充为有效的颜色
        cleanHex = cleanHex.padRight(6, '0');
      }

      final buffer = StringBuffer();
      buffer.write('ff'); // 添加透明度
      buffer.write(cleanHex);
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      debugPrint('Error parsing color: $e');
      debugPrint('Problematic color string: "$hex"');
      // 出错时返回默认颜色
      return Colors.black;
    }
  }
}
