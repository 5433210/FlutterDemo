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

  Widget _buildDetailsSection(BuildContext context, StorageInfo info) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

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
        for (final dir in info.subdirectories) ...[
          Text(
            '${dir.name}: ${FileSizeFormatter.format(dir.size)}',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSizes.p4),
        ],
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
        _buildSummarySection(context, info),
        const SizedBox(height: AppSizes.p16),
        _buildStorageBar(context, info),
        const SizedBox(height: AppSizes.p16),
        _buildDetailsSection(context, info),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context, StorageInfo info) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        _buildInfoItem(
          context,
          label: l10n.workCount,
          value: '${info.workCount}',
          icon: Icons.image_outlined,
        ),
        const SizedBox(width: AppSizes.p24),
        _buildInfoItem(
          context,
          label: l10n.fileCount,
          value: '${info.fileCount}',
          icon: Icons.folder_outlined,
        ),
      ],
    );
  }
}
