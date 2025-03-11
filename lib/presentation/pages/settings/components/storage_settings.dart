import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../presentation/providers/storage_info_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_sizes.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../utils/file_size_formatter.dart';

class StorageSettings extends ConsumerWidget {
  const StorageSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageInfo = ref.watch(storageInfoProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('存储空间', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSizes.p16),
            storageInfo.when(
              data: (info) => _buildStorageInfo(info),
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('加载失败: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(StorageInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('存储位置: ${info.path}', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSizes.p8),
        Text(
          '缓存大小: ${FileSizeFormatter.format(info.cacheSize)}',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSizes.p16),
        for (final dir in info.subdirectories) ...[
          Text(
            '${dir.name}: ${FileSizeFormatter.format(dir.size)}',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSizes.p4),
        ],
      ],
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppSizes.p8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.labelMedium),
            Text(value, style: AppTextStyles.bodyLarge),
          ],
        ),
      ],
    );
  }

  Widget _buildStorageBar(StorageInfo info) {
    final usagePercentage = info.usagePercentage.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '已使用 ${FileSizeFormatter.format(info.usedSize)} / ${FileSizeFormatter.format(info.totalSize)}',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSizes.p8),
        LinearProgressIndicator(
          value: usagePercentage / 100,
          backgroundColor: AppColors.background,
          valueColor: const AlwaysStoppedAnimation<Color>(
            AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStorageInfo(StorageInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummarySection(info),
        const SizedBox(height: AppSizes.p16),
        _buildStorageBar(info),
        const SizedBox(height: AppSizes.p16),
        _buildDetailsSection(info),
      ],
    );
  }

  Widget _buildSummarySection(StorageInfo info) {
    return Row(
      children: [
        _buildInfoItem(
          label: '作品数量',
          value: '${info.workCount}',
          icon: Icons.image_outlined,
        ),
        const SizedBox(width: AppSizes.p24),
        _buildInfoItem(
          label: '文件数量',
          value: '${info.fileCount}',
          icon: Icons.folder_outlined,
        ),
      ],
    );
  }
}
