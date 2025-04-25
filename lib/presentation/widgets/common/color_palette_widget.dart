import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// 通用颜色调色板控件
/// 包含颜色显示、颜色代码输入和颜色选择功能
class ColorPaletteWidget extends StatefulWidget {
  /// 当前颜色值
  final Color initialColor;

  /// 颜色变化回调
  final ValueChanged<Color> onColorChanged;

  /// 标签文本
  final String labelText;

  /// 是否显示透明度滑块
  final bool enableAlpha;

  /// 构造函数
  const ColorPaletteWidget({
    Key? key,
    required this.initialColor,
    required this.onColorChanged,
    this.labelText = '颜色',
    this.enableAlpha = false,
  }) : super(key: key);

  @override
  State<ColorPaletteWidget> createState() => _ColorPaletteWidgetState();
}

class _ColorPaletteWidgetState extends State<ColorPaletteWidget> {
  /// 当前颜色
  late Color _currentColor;

  /// 颜色代码控制器
  late TextEditingController _colorCodeController;

  /// 焦点节点
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    _colorCodeController = TextEditingController(text: _colorToHex(_currentColor));

    // 监听焦点变化，当失去焦点时应用颜色
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(ColorPaletteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果外部传入的颜色发生变化，更新内部状态
    if (oldWidget.initialColor != widget.initialColor) {
      _currentColor = widget.initialColor;
      _updateColorCodeText();
    }
  }

  @override
  void dispose() {
    _colorCodeController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  /// 焦点变化处理
  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _applyColorFromText();
    }
  }

  /// 将颜色转换为十六进制字符串（不带#前缀）
  String _colorToHex(Color color) {
    return color.value.toRadixString(16).padLeft(8, '0').substring(2);
  }

  /// 从十六进制字符串解析颜色
  Color _hexToColor(String hexString) {
    try {
      final hexCode = hexString.replaceAll('#', '');
      if (hexCode.length == 6) {
        return Color(int.parse('FF$hexCode', radix: 16));
      } else if (hexCode.length == 8) {
        return Color(int.parse(hexCode, radix: 16));
      }
    } catch (e) {
      debugPrint('颜色解析错误: $e');
    }
    return Colors.black;
  }

  /// 更新颜色代码文本
  void _updateColorCodeText() {
    final hexCode = _colorToHex(_currentColor);
    if (_colorCodeController.text != hexCode) {
      _colorCodeController.text = hexCode;
    }
  }

  /// 从文本应用颜色
  void _applyColorFromText() {
    try {
      final newColor = _hexToColor(_colorCodeController.text);
      if (newColor != _currentColor) {
        setState(() {
          _currentColor = newColor;
        });
        widget.onColorChanged(newColor);
      }
    } catch (e) {
      // 如果解析失败，恢复为当前颜色
      _updateColorCodeText();
    }
  }

  /// 显示颜色选择器对话框
  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('选择${widget.labelText}'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _currentColor,
              onColorChanged: (color) {
                setState(() {
                  _currentColor = color;
                });
              },
              enableAlpha: widget.enableAlpha,
              displayThumbColor: true,
              hexInputController: _colorCodeController,
              portraitOnly: true,
              colorPickerWidth: 300,
              pickerAreaHeightPercent: 0.7,
              labelTypes: const [
                ColorLabelType.hex,
                ColorLabelType.rgb,
                ColorLabelType.hsv,
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                _updateColorCodeText();
                widget.onColorChanged(_currentColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 颜色标签
        Expanded(
          flex: 2,
          child: Text(widget.labelText),
        ),
        // 颜色预览
        GestureDetector(
          onTap: () => _showColorPicker(context),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _currentColor,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 颜色代码输入框
        Expanded(
          flex: 3,
          child: TextField(
            controller: _colorCodeController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              prefixText: '#',
              hintText: '颜色代码',
            ),
            style: const TextStyle(fontSize: 14),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (value) {
              // 实时预览颜色变化
              if (value.length == 6) {
                setState(() {
                  _currentColor = _hexToColor(value);
                });
              }
            },
            onSubmitted: (value) {
              _applyColorFromText();
            },
          ),
        ),
      ],
    );
  }
}
