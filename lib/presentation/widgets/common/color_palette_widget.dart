import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../l10n/app_localizations.dart';

/// 通用颜色调色板控件
/// 包含颜色显示、颜色代码输入和颜色选择功能
class ColorPaletteWidget extends StatefulWidget {
  /// 当前颜色值
  final Color initialColor;

  /// 颜色变化回调
  final ValueChanged<Color> onColorChanged;

  /// 标签文本（可选）
  final String? labelText;

  /// 是否显示透明度滑块
  final bool enableAlpha;

  /// 是否显示文本输入框
  final bool showTextField;

  /// 外部提供的文本编辑控制器
  final TextEditingController? textEditingController;

  /// 构造函数
  const ColorPaletteWidget({
    Key? key,
    required this.initialColor,
    required this.onColorChanged,
    this.labelText,
    this.enableAlpha = false,
    this.showTextField = true,
    this.textEditingController,
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayLabel = widget.labelText ?? l10n.color;

    return Row(
      children: [
        // 颜色标签
        Expanded(
          flex: 2,
          child: Text(displayLabel),
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              prefixText: '#',
              hintText: l10n.colorCode,
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

  @override
  void didUpdateWidget(ColorPaletteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果外部传入的颜色发生变化，更新内部状态
    if (oldWidget.initialColor != widget.initialColor) {
      _currentColor = widget.initialColor;
      // Schedule the text update after the build phase is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateColorCodeText();
      });
    }
  }

  @override
  void dispose() {
    _colorCodeController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;

    // 使用外部提供的控制器或创建新的控制器
    if (widget.textEditingController != null) {
      _colorCodeController = widget.textEditingController!;
      // 确保控制器有正确的初始值
      if (_colorCodeController.text.isEmpty) {
        _colorCodeController.text = _colorToHex(_currentColor);
      }
    } else {
      _colorCodeController =
          TextEditingController(text: _colorToHex(_currentColor));
    }

    // 监听焦点变化，当失去焦点时应用颜色
    _focusNode.addListener(_onFocusChange);
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
      // Schedule the text update to avoid build phase issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateColorCodeText();
      });
    }
  }

  /// 将颜色转换为十六进制字符串（不带#前缀）
  String _colorToHex(Color color) {
    // 直接使用RGB值构建十六进制字符串
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');

    final hexColor = '$r$g$b';
    return hexColor;
  }

  /// 从十六进制字符串解析颜色
  Color _hexToColor(String hexString) {
    try {
      final hexCode = hexString.replaceAll('#', '');

      // 确保颜色格式正确
      String cleanHex = hexCode;
      if (cleanHex.length < 6) {
        cleanHex = cleanHex.padRight(6, 'F');
      } else if (cleanHex.length > 6) {
        cleanHex = cleanHex.substring(0, 6);
      }

      // 添加完全不透明的 alpha 通道
      cleanHex = 'FF$cleanHex';

      // 解析颜色
      final int colorValue = int.parse(cleanHex, radix: 16);
      final Color color = Color(colorValue);
      return color;
    } catch (e) {
      debugPrint('Color parsing error: $e');
      return Colors.black;
    }
  }

  /// 焦点变化处理
  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _applyColorFromText();
    }
  }

  /// 显示颜色选择器对话框
  void _showColorPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayLabel = widget.labelText ?? l10n.color;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.selectColor(displayLabel)),
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
              child: Text(l10n.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(l10n.confirm),
              onPressed: () {
                // Schedule the text update after the dialog is closed
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _updateColorCodeText();
                });
                widget.onColorChanged(_currentColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// 更新颜色代码文本
  void _updateColorCodeText() {
    final hexCode = _colorToHex(_currentColor);
    if (_colorCodeController.text != hexCode) {
      _colorCodeController.text = hexCode;
    }
  }
}
