import 'package:flutter/material.dart';
import '../../../theme/app_sizes.dart';

class WorkDetailPage extends StatelessWidget {
  final String workId;

  const WorkDetailPage({
    super.key,
    required this.workId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('作品详情'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Builder(
      builder: (context) => SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPreviewSection(),
            _buildInfoSection(context),
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
