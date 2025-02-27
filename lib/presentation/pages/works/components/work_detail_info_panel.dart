import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/work.dart';
import '../../../../theme/app_sizes.dart';
import '../../../widgets/info_card.dart';

class WorkDetailInfoPanel extends ConsumerWidget {
  final Work work;

  const WorkDetailInfoPanel({
    super.key,
    required this.work,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本信息卡片
          InfoCard(
            title: '基本信息',
            icon: Icons.info_outline,
            content: Column(
              children: [
                _buildInfoItem('作品名称', work.name ?? '未命名作品', theme),
                _buildInfoItem('作者', work.author ?? '未知', theme),
                _buildInfoItem('风格', work.style ?? '未分类', theme),
                _buildInfoItem('工具', work.tool ?? '未知', theme),
                _buildInfoItem('年代', _formatDate(work.creationDate), theme),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.spacingMedium),

          // 图片信息卡片
          InfoCard(
            title: '图片信息',
            icon: Icons.image_outlined,
            content: Column(
              children: [
                _buildInfoItem('图片数量', '${work.imageCount ?? 0}', theme),
                _buildInfoItem('导入时间', _formatDateTime(work.createTime), theme),
                if (work.updateTime != null)
                  _buildInfoItem(
                      '最近更新', _formatDateTime(work.updateTime!), theme),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.spacingMedium),

          // 操作按钮区域
          InfoCard(
            title: '操作',
            icon: Icons.settings_outlined,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 提取字形按钮
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.text_format),
                  label: const Text('提取字形'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),

                const SizedBox(height: AppSizes.spacingSmall),

                // 导出按钮
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('导出作品'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // 元数据显示
          if (work.metadata != null && (work.metadata as Map).isNotEmpty)
            InfoCard(
              title: '其他信息',
              icon: Icons.more_horiz,
              initiallyExpanded: false,
              content: _buildMetadataSection(work.metadata as Map, theme),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(Map metadata, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: metadata.entries.map((entry) {
        return _buildInfoItem(
            entry.key.toString(), entry.value.toString(), theme);
      }).toList(),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '未知';
    return DateFormat.yMd().format(date);
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未知';
    return DateFormat.yMd().add_Hm().format(dateTime);
  }
}
