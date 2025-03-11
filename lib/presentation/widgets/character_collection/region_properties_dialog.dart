import 'package:flutter/material.dart';

import '../../../domain/models/character/character_region.dart';

typedef OnSaveCallback = Future<void> Function(String? label, Color? color);

class RegionPropertiesDialog extends StatefulWidget {
  final CharacterRegion region;
  final OnSaveCallback onSave;

  const RegionPropertiesDialog({
    super.key,
    required this.region,
    required this.onSave,
  });

  @override
  State<RegionPropertiesDialog> createState() => _RegionPropertiesDialogState();
}

class _RegionPropertiesDialogState extends State<RegionPropertiesDialog> {
  final _labelController = TextEditingController();
  Color _selectedColor = Colors.blue;
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('区域属性'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标签输入
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: '标签',
                hintText: '输入字符标签',
              ),
              maxLength: 10,
              enabled: !_processing,
            ),
            const SizedBox(height: 16),

            // 颜色选择
            const Text('选择颜色标记'),
            const SizedBox(height: 8),
            _buildColorPicker(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _processing ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _processing ? null : _handleSave,
          child: _processing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('保存'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _labelController.text = widget.region.label ?? '';
    _selectedColor = widget.region.color ?? Colors.blue;
  }

  Widget _buildColorPicker() {
    final colors = [
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = color.value == _selectedColor.value;
        return GestureDetector(
          onTap:
              _processing ? null : () => setState(() => _selectedColor = color),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleSave() async {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标签')),
      );
      return;
    }

    setState(() => _processing = true);

    try {
      await widget.onSave(label, _selectedColor);
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }
}
