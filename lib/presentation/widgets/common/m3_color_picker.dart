import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';

/// 统一的Material Design 3风格颜色选择器
class M3ColorPicker extends StatefulWidget {
  /// 当前颜色
  final Color color;

  /// 颜色改变回调 (仅用于预览)
  final ValueChanged<Color>? onColorChanged;

  /// 是否显示透明度选项
  final bool enableAlpha;

  /// 是否显示颜色代码输入
  final bool enableColorCode;

  const M3ColorPicker({
    Key? key,
    required this.color,
    this.onColorChanged,
    this.enableAlpha = true,
    this.enableColorCode = true,
  }) : super(key: key);

  @override
  State<M3ColorPicker> createState() => _M3ColorPickerState();

  /// 显示颜色选择器对话框的便捷方法
  static Future<Color?> show(
    BuildContext context, {
    required Color initialColor,
    bool enableAlpha = true,
    bool enableColorCode = true,
  }) {
    return showDialog<Color>(
      context: context,
      builder: (context) {
        return _ColorPickerDialog(
          initialColor: initialColor,
          enableAlpha: enableAlpha,
          enableColorCode: enableColorCode,
        );
      },
    );
  }
}

/// 颜色选择器对话框
class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final bool enableAlpha;
  final bool enableColorCode;

  const _ColorPickerDialog({
    required this.initialColor,
    this.enableAlpha = true,
    this.enableColorCode = true,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _currentColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.colorPicker),
      content: SizedBox(
        width: 320,
        height: 450,
        child: M3ColorPicker(
          color: _currentColor,
          onColorChanged: (color) => setState(() => _currentColor = color),
          enableAlpha: widget.enableAlpha,
          enableColorCode: widget.enableColorCode,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_currentColor),
          child: Text(l10n.confirm),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
  }
}

class _M3ColorPickerState extends State<M3ColorPicker>
    with SingleTickerProviderStateMixin {
  // 预设颜色列表
  static const List<Color> _presetColors = [
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
  late TabController _tabController;
  late TextEditingController _hexController;

  // 内部维护的当前颜色状态
  late Color _currentColor;
  bool _isValidHex = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // 颜色预览区域
        Container(
          width: double.infinity,
          height: 64,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _currentColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline),
          ),
          child: _currentColor == Colors.transparent
              ? const Center(
                  child: Icon(Icons.block, color: Colors.red),
                )
              : null,
        ),

        // 模式选择标签页
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.grid_view), text: l10n.presets),
            Tab(icon: const Icon(Icons.tune), text: l10n.adjust),
            Tab(icon: const Icon(Icons.code), text: l10n.code),
          ],
        ),

        // 标签页内容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPresetColorsTab(),
              _buildColorAdjustmentTab(),
              _buildColorCodeTab(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(M3ColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      setState(() {
        _currentColor = widget.color;
      });
      _hexController.text = _colorToHex(_currentColor).toUpperCase();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentColor = widget.color;
    _tabController = TabController(length: 3, vsync: this);
    _hexController = TextEditingController(
      text: _colorToHex(_currentColor).toUpperCase(),
    );
  }

  // 颜色调节标签页
  Widget _buildColorAdjustmentTab() {
    // 将0-1范围的颜色值转换为0-255范围显示
    final redValue = (_currentColor.r * 255).round().toDouble();
    final greenValue = (_currentColor.g * 255).round().toDouble();
    final blueValue = (_currentColor.b * 255).round().toDouble();
    final alphaValue = (_currentColor.a * 255).round().toDouble();
    
    print('🎨 [ColorPicker] 构建调节tab: R=${redValue}, G=${greenValue}, B=${blueValue}');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildColorSlider('Red', redValue,
            const Color.fromARGB(255, 255, 0, 0), (value) {
          _updateColor(_currentColor.withRed(value.round()));
        }),
        _buildColorSlider('Green', greenValue,
            const Color.fromARGB(255, 0, 255, 0), (value) {
          _updateColor(_currentColor.withGreen(value.round()));
        }),
        _buildColorSlider('Blue', blueValue,
            const Color.fromARGB(255, 0, 0, 255), (value) {
          _updateColor(_currentColor.withBlue(value.round()));
        }),
        if (widget.enableAlpha) ...[
          const Divider(),
          _buildColorSlider('Alpha', alphaValue, Colors.grey,
              (value) {
            _updateColor(_currentColor.withAlpha(value.round()));
          }),
        ],
      ],
    );
  }

  // 颜色代码标签页
  Widget _buildColorCodeTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _hexController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).colorCode,
              helperText: AppLocalizations.of(context).colorCodeHelp,
              prefixText: '#',
              errorText: _isValidHex
                  ? null
                  : AppLocalizations.of(context).colorCodeInvalid,
              border: const OutlineInputBorder(),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: _handleHexInputChange,
          ),
          const SizedBox(height: 16),
          Text('RGB: ${_currentColor.r}, ${_currentColor.g}, ${_currentColor.b}'),
          if (widget.enableAlpha) Text('Alpha: ${_currentColor.a}'),
          const SizedBox(height: 8),
          Text('Opacity: ${(_currentColor.a / 255 * 100).round()}%'),
        ],
      ),
    );
  }

  // 构建颜色滑块
  Widget _buildColorSlider(String label, double value, Color activeColor,
      ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.round()}'),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: 0,
                max: 255,
                activeColor: activeColor,
                onChanged: (newValue) {
                  print('🎨 [ColorPicker] 滑块拖动: $label = $newValue');
                  onChanged(newValue);
                },
              ),
            ),
            SizedBox(
              width: 50,
              child: TextField(
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                controller:
                    TextEditingController(text: value.round().toString()),
                onSubmitted: (inputValue) {
                  final intValue = int.tryParse(inputValue);
                  if (intValue != null && intValue >= 0 && intValue <= 255) {
                    print('🎨 [ColorPicker] 数字输入: $label = $intValue');
                    onChanged(intValue.toDouble());
                  }
                },
                onChanged: (inputValue) {
                  final intValue = int.tryParse(inputValue);
                  if (intValue != null && intValue >= 0 && intValue <= 255) {
                    print('🎨 [ColorPicker] 数字变化: $label = $intValue');
                    onChanged(intValue.toDouble());
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // 预设颜色标签页
  Widget _buildPresetColorsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _presetColors.length,
      itemBuilder: (context, index) {
        final color = _presetColors[index];
        final isSelected = _currentColor.toARGB32() == color.toARGB32();

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _updateColor(color),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: color == Colors.transparent
                  ? const Icon(Icons.block, color: Colors.red)
                  : isSelected
                      ? Icon(
                          Icons.check,
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
            ),
          ),
        );
      },
    );
  }

  // 颜色转十六进制字符串（不含#前缀）
  String _colorToHex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
  }

  // 处理颜色代码输入变化
  void _handleHexInputChange(String value) {
    print('🎨 [ColorPicker] Hex输入变化: "$value" (长度: ${value.length})');
    if (value.length == 6) {
      try {
        final color = _hexToColor(value);
        print('🎨 [ColorPicker] Hex解析成功: $color');
        setState(() => _isValidHex = true);
        // 不更新hex控制器文本，避免中断用户输入
        _updateColor(color, updateHexController: false);
      } catch (e) {
        print('🎨 [ColorPicker] Hex解析失败: $e');
        setState(() => _isValidHex = false);
      }
    } else if (value.length < 6) {
      setState(() => _isValidHex = false);
    }
  }

  // 十六进制字符串转颜色
  Color _hexToColor(String hex) {
    final cleanHex = hex.replaceAll('#', '');
    if (cleanHex.length != 6) {
      throw const FormatException('Invalid hex color code');
    }
    final value = int.parse(cleanHex, radix: 16);
    // 保持当前的alpha值，转换为正确的0-255范围
    return Color(value | 0xFF000000).withAlpha((_currentColor.a * 255).round());
  }

  // 更新颜色的统一方法
  void _updateColor(Color color, {bool updateHexController = true}) {
    print('🎨 [ColorPicker] 更新颜色: $color, updateHexController: $updateHexController');
    setState(() {
      _currentColor = color;
      if (updateHexController) {
        _hexController.text = _colorToHex(color).toUpperCase();
      }
    });
    _notifyColorChanged(color);
  }

  void _notifyColorChanged(Color color) {
    print('🎨 [ColorPicker] 通知颜色变化: $color');
    if (widget.onColorChanged != null) {
      widget.onColorChanged!(color);
    }
  }
}
