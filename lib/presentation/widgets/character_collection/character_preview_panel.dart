import 'package:flutter/material.dart';

import '../../../domain/models/character/character_region.dart';

class CharacterPreviewPanel extends StatelessWidget {
  final CharacterRegion? region;
  final String? label;
  final VoidCallback? onSave;
  final VoidCallback? onClear;

  const CharacterPreviewPanel({
    super.key,
    this.region,
    this.label,
    this.onSave,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (region == null) {
      return const Center(
        child: Text('请选择或者框选字符区域'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('区域信息', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),

        // 区域尺寸信息
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('位置',
                    'x: ${region!.rect.left.toInt()}, y: ${region!.rect.top.toInt()}'),
                const SizedBox(height: 8),
                _buildInfoRow('尺寸',
                    '${region!.rect.width.toInt()} × ${region!.rect.height.toInt()}'),
                if (region!.rotation != 0) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('旋转',
                      '${(region!.rotation * 180 / 3.14159).toStringAsFixed(1)}°'),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 操作按钮
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: onSave,
                child: const Text('保存'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: onClear,
                child: const Text('清除'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value),
      ],
    );
  }
}
