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

  bool _isValidHex = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 颜色预览区域
        Container(
          width: double.infinity,
          height: 64,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline),
          ),
          child: widget.color == Colors.transparent
              ? const Center(
                  child: Icon(Icons.block, color: Colors.red),
                )
              : null,
        ),

        // 模式选择标签页
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view), text: '预设'),
            Tab(icon: Icon(Icons.tune), text: '调节'),
            Tab(icon: Icon(Icons.code), text: '代码'),
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
      _hexController.text = _colorToHex(widget.color).toUpperCase();
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
    _tabController = TabController(length: 3, vsync: this);
    _hexController = TextEditingController(
      text: _colorToHex(widget.color).toUpperCase(),
    );
  }

  // 颜色调节标签页
  Widget _buildColorAdjustmentTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildColorSlider('Red', widget.color.r.toDouble(),
            const Color.fromARGB(255, 255, 0, 0), (value) {
          _notifyColorChanged(widget.color.withRed(value.round()));
        }),
        _buildColorSlider('Green', widget.color.g.toDouble(),
            const Color.fromARGB(255, 0, 255, 0), (value) {
          _notifyColorChanged(widget.color.withGreen(value.round()));
        }),
        _buildColorSlider('Blue', widget.color.b.toDouble(),
            const Color.fromARGB(255, 0, 0, 255), (value) {
          _notifyColorChanged(widget.color.withBlue(value.round()));
        }),
        if (widget.enableAlpha) ...[
          const Divider(),
          _buildColorSlider('Alpha', widget.color.a.toDouble(), Colors.grey,
              (value) {
            _notifyColorChanged(widget.color.withAlpha(value.round()));
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
          Text('RGB: ${widget.color.r}, ${widget.color.g}, ${widget.color.b}'),
          if (widget.enableAlpha) Text('Alpha: ${widget.color.a}'),
          const SizedBox(height: 8),
          Text('Opacity: ${(widget.color.a / 255 * 100).round()}%'),
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
                onChanged: onChanged,
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
                onSubmitted: (value) {
                  final intValue = int.tryParse(value);
                  if (intValue != null && intValue >= 0 && intValue <= 255) {
                    onChanged(intValue.toDouble());
                  }
                },
              ),
            ),
          ],
        ),
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
        final isSelected = widget.color.toARGB32() == color.toARGB32();

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _notifyColorChanged(color),
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
    if (value.length == 6) {
      try {
        final color = _hexToColor(value);
        setState(() => _isValidHex = true);
        _notifyColorChanged(color);
      } catch (e) {
        setState(() => _isValidHex = false);
      }
    }
  }

  // 十六进制字符串转颜色
  Color _hexToColor(String hex) {
    final cleanHex = hex.replaceAll('#', '');
    if (cleanHex.length != 6) {
      throw const FormatException('Invalid hex color code');
    }
    final value = int.parse(cleanHex, radix: 16);
    return Color(value).withAlpha(widget.color.a.toInt());
  }

  void _notifyColorChanged(Color color) {
    if (widget.onColorChanged != null) {
      widget.onColorChanged!(color);
    }
  }
}
