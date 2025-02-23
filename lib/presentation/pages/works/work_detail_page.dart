import 'package:flutter/material.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/page_toolbar.dart';
import '../../widgets/section_header.dart';
import '../../../theme/app_sizes.dart';
import '../../dialogs/export_dialog.dart';
import '../../dialogs/delete_confirmation_dialog.dart';
import '../../dialogs/work_edit_dialog.dart';
import '../../widgets/character/character_extraction_panel.dart';
import '../../widgets/window/title_bar.dart';
import '../practices/practice_detail_page.dart';
import '../../dialogs/character_detail_dialog.dart';

class WorkDetailPage extends StatelessWidget {
  final String workId;

  const WorkDetailPage({
    super.key,
    required this.workId,
  });

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      navigationInfo: const Text('作品详情'),
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
            // 左侧预览区域
            Expanded(
              flex: 2,
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: '作品内容'),
                    const Divider(height: 1),
                    Expanded(
                      child: _buildPreviewSection(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spacingMedium),
            // 右侧信息区域
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: '基本信息'),
                    Expanded(
                      child: _buildInfoSection(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return const Center(child: Text('图片预览区域'));
  }

  Widget _buildInfoSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoItem('作品名称', '兰亭集序', theme),
          _buildInfoItem('作者', '王羲之', theme),
          _buildInfoItem('朝代', '晋', theme),
          _buildInfoItem('字体', '行书', theme),
          _buildInfoItem('创建时间', '2024-01-01', theme),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.save_alt),
              label: const Text('导出作品'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSizes.spacingTiny),
          Text(
            value,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class CharacterDetailPage extends StatelessWidget {
  final String charId;
  final VoidCallback onBack;

  const CharacterDetailPage({super.key, required this.charId, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: const Text('字帖详情', style: TextStyle(fontSize: 20)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('字帖 $charId'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}
