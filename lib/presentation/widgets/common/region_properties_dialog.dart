import 'package:flutter/material.dart';

import '../../../domain/models/character/character_region.dart';

class RegionPropertiesDialog extends StatefulWidget {
  final CharacterRegion region;
  final Function(String label, Color color) onSave;

  const RegionPropertiesDialog({
    super.key,
    required this.region,
    required this.onSave,
  });

  @override
  State<RegionPropertiesDialog> createState() => _RegionPropertiesDialogState();
}

class _RegionPropertiesDialogState extends State<RegionPropertiesDialog> {
  late TextEditingController _labelController;
  late Color _selectedColor;

  final List<Color> _predefinedColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.brown,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑区域属性'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: '标签',
              hintText: '输入区域标签',
            ),
          ),
          const SizedBox(height: 16),
          const Text('颜色'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._predefinedColors.map((color) => _buildColorOption(color)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_labelController.text, _selectedColor);
            Navigator.of(context).pop();
          },
          child: const Text('保存'),
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
    _labelController = TextEditingController(text: widget.region.label);
    _selectedColor = widget.region.color ?? Colors.blue;
  }

  Widget _buildColorOption(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
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
                color: color.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
      ),
    );
  }
}
