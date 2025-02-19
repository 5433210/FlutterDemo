import 'package:flutter/material.dart';

class PracticeToolPanel extends StatelessWidget {
  final Function(String) onToolSelected;

  const PracticeToolPanel({
    Key? key,
    required this.onToolSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('页面设置', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildToolButton(
              context,
              icon: Icons.crop_landscape,
              label: '页面大小',
              onPressed: () => onToolSelected('page_size'),
            ),
            _buildToolButton(
              context,
              icon: Icons.space_bar,
              label: '页边距',
              onPressed: () => onToolSelected('margins'),
            ),
            _buildToolButton(
              context,
              icon: Icons.grid_on,
              label: '背景',
              onPressed: () => onToolSelected('background'),
            ),
          ],
        ),
        const Divider(height: 32),
        Text('内容工具', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildToolButton(
              context,
              icon: Icons.font_download,
              label: '集字填充',
              onPressed: () => onToolSelected('chars'),
            ),
            _buildToolButton(
              context,
              icon: Icons.text_fields,
              label: '文本',
              onPressed: () => onToolSelected('text'),
            ),
            _buildToolButton(
              context,
              icon: Icons.image,
              label: '图片',
              onPressed: () => onToolSelected('image'),
            ),
          ],
        ),
        const Divider(height: 32),
        Text('辅助工具', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildToolButton(
              context,
              icon: Icons.grid_4x4,
              label: '参考线',
              onPressed: () => onToolSelected('guides'),
            ),
            _buildToolButton(
              context,
              icon: Icons.straighten,
              label: '标尺',
              onPressed: () => onToolSelected('ruler'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
