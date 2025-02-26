import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/section_header.dart';

class PracticeDetailPage extends StatelessWidget {
  final String practiceId;

  const PracticeDetailPage({
    super.key,
    required this.practiceId,
  });

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      navigationInfo: const Text('练习详情'),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: '编辑',
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: '删除',
          onPressed: () {},
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingMedium),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: '练习内容',
                      padding: EdgeInsets.all(AppSizes.spacingMedium),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _buildPreviewArea(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spacingMedium),
            Expanded(
              child: _buildInfoPanel(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContent(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoField('练习日期', '2024-01-01', theme),
        _buildInfoField('练习字数', '100', theme),
        _buildInfoField('练习时长', '30分钟', theme),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save_alt),
            label: const Text('导出练习'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSizes.spacingTiny),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '练习信息',
            padding: EdgeInsets.all(AppSizes.spacingMedium),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.spacingMedium),
              child: _buildInfoContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(BuildContext context) {
    // TODO: 实现预览区域
    return const Center(child: Text('练习图片预览'));
  }
}
