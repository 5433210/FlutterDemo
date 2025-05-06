import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/providers/cache_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../../utils/file_size_formatter.dart';
import '../../../providers/cache_settings_notifier.dart';
import '../../../widgets/settings/settings_section.dart';

class CacheSettings extends ConsumerWidget {
  const CacheSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheConfig = ref.watch(cacheSettingsNotifierProvider);
    final cacheManager = ref.watch(cacheManagerProvider);
    final l10n = AppLocalizations.of(context);

    return SettingsSection(
      title: l10n.cacheSettings,
      icon: Icons.storage_outlined,
      children: [
        // Memory Image Cache Capacity
        ListTile(
          title: Text(l10n.memoryImageCacheCapacity),
          subtitle: Text(l10n.memoryImageCacheCapacityDescription),
          trailing: SizedBox(
            width: 120,
            child: Slider(
              value: cacheConfig.memoryImageCacheCapacity.toDouble(),
              min: 50,
              max: 500,
              divisions: 9,
              label: '${cacheConfig.memoryImageCacheCapacity}',
              onChanged: (value) {
                ref
                    .read(cacheSettingsNotifierProvider.notifier)
                    .setMemoryImageCacheCapacity(value.toInt());
              },
            ),
          ),
        ),

        // Memory Data Cache Capacity
        ListTile(
          title: Text(l10n.memoryDataCacheCapacity),
          subtitle: Text(l10n.memoryDataCacheCapacityDescription),
          trailing: SizedBox(
            width: 120,
            child: Slider(
              value: cacheConfig.memoryDataCacheCapacity.toDouble(),
              min: 20,
              max: 200,
              divisions: 9,
              label: '${cacheConfig.memoryDataCacheCapacity}',
              onChanged: (value) {
                ref
                    .read(cacheSettingsNotifierProvider.notifier)
                    .setMemoryDataCacheCapacity(value.toInt());
              },
            ),
          ),
        ),

        // Disk Cache Size
        ListTile(
          title: Text(l10n.diskCacheSize),
          subtitle: Text(l10n.diskCacheSizeDescription),
          trailing: DropdownButton<int>(
            value: cacheConfig.maxDiskCacheSize,
            items: [
              DropdownMenuItem(
                value: 50 * 1024 * 1024,
                child: Text(FileSizeFormatter.format(50 * 1024 * 1024)),
              ),
              DropdownMenuItem(
                value: 100 * 1024 * 1024,
                child: Text(FileSizeFormatter.format(100 * 1024 * 1024)),
              ),
              DropdownMenuItem(
                value: 200 * 1024 * 1024,
                child: Text(FileSizeFormatter.format(200 * 1024 * 1024)),
              ),
              DropdownMenuItem(
                value: 500 * 1024 * 1024,
                child: Text(FileSizeFormatter.format(500 * 1024 * 1024)),
              ),
              DropdownMenuItem(
                value: 1024 * 1024 * 1024,
                child: Text(FileSizeFormatter.format(1024 * 1024 * 1024)),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(cacheSettingsNotifierProvider.notifier)
                    .setMaxDiskCacheSize(value);
              }
            },
          ),
        ),

        // Disk Cache TTL
        ListTile(
          title: Text(l10n.diskCacheTtl),
          subtitle: Text(l10n.diskCacheTtlDescription),
          trailing: DropdownButton<int>(
            value: cacheConfig.diskCacheTtl.inDays,
            items: [
              DropdownMenuItem(
                value: 1,
                child: Text(l10n.days(1)),
              ),
              DropdownMenuItem(
                value: 3,
                child: Text(l10n.days(3)),
              ),
              DropdownMenuItem(
                value: 7,
                child: Text(l10n.days(7)),
              ),
              DropdownMenuItem(
                value: 14,
                child: Text(l10n.days(14)),
              ),
              DropdownMenuItem(
                value: 30,
                child: Text(l10n.days(30)),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(cacheSettingsNotifierProvider.notifier)
                    .setDiskCacheTtl(Duration(days: value));
              }
            },
          ),
        ),

        // Auto Cleanup
        SwitchListTile(
          title: Text(l10n.autoCleanup),
          subtitle: Text(l10n.autoCleanupDescription),
          value: cacheConfig.autoCleanupEnabled,
          onChanged: (value) {
            ref
                .read(cacheSettingsNotifierProvider.notifier)
                .setAutoCleanupEnabled(value);
          },
        ),

        // Auto Cleanup Interval (only visible if auto cleanup is enabled)
        if (cacheConfig.autoCleanupEnabled)
          ListTile(
            title: Text(l10n.autoCleanupInterval),
            subtitle: Text(l10n.autoCleanupIntervalDescription),
            trailing: DropdownButton<int>(
              value: cacheConfig.autoCleanupInterval.inHours,
              items: [
                DropdownMenuItem(
                  value: 1,
                  child: Text(l10n.hours(1)),
                ),
                DropdownMenuItem(
                  value: 6,
                  child: Text(l10n.hours(6)),
                ),
                DropdownMenuItem(
                  value: 12,
                  child: Text(l10n.hours(12)),
                ),
                DropdownMenuItem(
                  value: 24,
                  child: Text(l10n.hours(24)),
                ),
                DropdownMenuItem(
                  value: 48,
                  child: Text(l10n.hours(48)),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(cacheSettingsNotifierProvider.notifier)
                      .setAutoCleanupInterval(Duration(hours: value));
                }
              },
            ),
          ),

        const SizedBox(height: AppSizes.p16),

        // Cache Management Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.clearCache),
              onPressed: () async {
                final confirmed = await _showClearCacheConfirmDialog(context);
                if (confirmed && context.mounted) {
                  await cacheManager.clearAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.cacheClearedMessage)),
                    );
                  }
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.restore),
              label: Text(l10n.resetToDefaults),
              onPressed: () async {
                final confirmed = await _showResetConfirmDialog(context);
                if (confirmed) {
                  await ref
                      .read(cacheSettingsNotifierProvider.notifier)
                      .resetToDefaults();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.settingsResetMessage)),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<bool> _showClearCacheConfirmDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.clearCacheConfirmTitle),
            content: Text(l10n.clearCacheConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.confirm),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showResetConfirmDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.resetSettingsConfirmTitle),
            content: Text(l10n.resetSettingsConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.confirm),
              ),
            ],
          ),
        ) ??
        false;
  }
}
