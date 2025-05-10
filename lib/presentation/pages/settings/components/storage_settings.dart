import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../presentation/providers/storage_info_provider.dart';
import '../../../../theme/app_sizes.dart';
import '../../../../utils/file_size_formatter.dart';
import '../../../widgets/settings/settings_section.dart';

class StorageSettings extends ConsumerWidget {
  const StorageSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageInfo = ref.watch(storageInfoProvider);
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SettingsSection(
      title: l10n.storageSettings,
      icon: Icons.storage_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: storageInfo.when(
            data: (info) => _buildStorageInfo(context, info),
            loading: () => Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
            error: (error, stackTrace) => const Center(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int count,
    required int size,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSizes.p12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: colorScheme.primary),
          const SizedBox(width: AppSizes.p16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall),
                const SizedBox(height: AppSizes.p8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('数量', style: textTheme.bodyMedium),
                    Text('$count', style: textTheme.bodyLarge),
                  ],
                ),
                const SizedBox(height: AppSizes.p4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('存储空间', style: textTheme.bodyMedium),
                    Text(
                      FileSizeFormatter.format(size),
                      style: textTheme.bodyLarge,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, StorageInfo info) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // 对子目录按大小排序，从大到小
    final sortedDirs = [...info.subdirectories];
    sortedDirs.sort((a, b) => b.size.compareTo(a.size));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.storageLocation}: ${info.path}',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSizes.p8),
        Text(
          '${l10n.cacheSize}: ${FileSizeFormatter.format(info.cacheSize)}',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSizes.p16),
        Row(
          children: [
            Icon(Icons.storage_outlined, size: 20, color: colorScheme.primary),
            const SizedBox(width: AppSizes.p8),
            Text(
              l10n.storageDetails,
              style: textTheme.titleSmall?.copyWith(color: colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p8),
        ...sortedDirs.map((dir) {
          final percentage =
              (dir.size / info.usedSize * 100).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.p4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dir.name,
                  style: textTheme.bodyMedium,
                ),
                Text(
                  '${FileSizeFormatter.format(dir.size)} ($percentage%)',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: AppSizes.p8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: textTheme.labelMedium),
            Text(value, style: textTheme.bodyLarge),
          ],
        ),
      ],
    );
  }

  Widget _buildStorageBar(BuildContext context, StorageInfo info) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final usagePercentage = info.usagePercentage.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.storageUsed} ${FileSizeFormatter.format(info.usedSize)} / ${FileSizeFormatter.format(info.totalSize)}',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSizes.p8),
        LinearProgressIndicator(
          value: usagePercentage / 100,
          backgroundColor: colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      ],
    );
  }

  Widget _buildStorageInfo(BuildContext context, StorageInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryGrid(context, info),
        const SizedBox(height: AppSizes.p16),
        _buildStorageBar(context, info),
        const SizedBox(height: AppSizes.p16),
        _buildDetailsSection(context, info),
      ],
    );
  }

  Widget _buildSummaryGrid(BuildContext context, StorageInfo info) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                context,
                label: l10n.workCount,
                value: info.workCount.toString(),
                icon: Icons.image_outlined,
              ),
            ),
            const SizedBox(width: AppSizes.p16),
            Expanded(
              child: _buildInfoItem(
                context,
                label: l10n.characterCount,
                value: info.characterCount.toString(),
                icon: Icons.font_download_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p16),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                context,
                label: l10n.libraryCount,
                value: info.libraryCount.toString(),
                icon: Icons.photo_library_outlined,
              ),
            ),
            const SizedBox(width: AppSizes.p16),
            Expanded(
              child: _buildInfoItem(
                context,
                label: l10n.files,
                value: info.fileCount.toString(),
                icon: Icons.insert_drive_file_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context, StorageInfo info) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                context,
                label: l10n.workCount,
                value: info.workCount.toString(),
                icon: Icons.image_outlined,
              ),
            ),
            const SizedBox(width: AppSizes.p16),
            Expanded(
              child: _buildInfoItem(
                context,
                label: l10n.characterCount,
                value: info.characterCount.toString(),
                icon: Icons.font_download_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p16),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                context,
                label: l10n.libraryCount,
                value: info.libraryCount.toString(),
                icon: Icons.photo_library_outlined,
              ),
            ),
            const SizedBox(width: AppSizes.p16),
            Expanded(
              child: _buildInfoItem(
                context,
                label: l10n.files,
                value: info.fileCount.toString(),
                icon: Icons.insert_drive_file_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
