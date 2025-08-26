import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/services/system/system_info_service.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/settings/settings_section.dart';

final detailedSystemInfoProvider = FutureProvider<DetailedSystemInfo>((ref) async {
  return await SystemInfoService.getDetailedSystemInfo();
});

class AppVersionSettings extends ConsumerWidget {
  const AppVersionSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final systemInfoAsync = ref.watch(detailedSystemInfoProvider);

    return SettingsSection(
      title: l10n.about,
      children: [
        systemInfoAsync.when(
          data: (systemInfo) =>
              _buildSystemInfo(context, l10n, theme, systemInfo),
          loading: () => ListTile(
            leading: const CircularProgressIndicator(),
            title: Text(l10n.loading),
          ),
          error: (error, stack) => ListTile(
            leading: Icon(Icons.error, color: theme.colorScheme.error),
            title: Text(l10n.loadFailed),
            subtitle: Text(error.toString()),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemInfo(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    DetailedSystemInfo systemInfo,
  ) {
    return Column(
      children: [
        // 应用版本信息
        ListTile(
          leading: Icon(
            Icons.info_outline,
            color: theme.colorScheme.primary,
          ),
          title: Text(l10n.versionDetails),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.appVersion}: ${systemInfo.appVersion}'),
            ],
          ),
        ),

        // 系统信息
        ListTile(
          leading: Icon(
            Icons.computer,
            color: theme.colorScheme.secondary,
          ),
          title: Text(l10n.systemInfo),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.operatingSystem}: ${systemInfo.operatingSystem} ${systemInfo.osVersion}'),
              Text('${l10n.deviceInfo}: ${systemInfo.deviceManufacturer} ${systemInfo.deviceModel}'),
              if (systemInfo.architecture != null)
                Text('${l10n.architecture}: ${systemInfo.architecture}'),
            ],
          ),
          isThreeLine: true,
        ),

        // 硬件信息
        ListTile(
          leading: Icon(
            Icons.memory,
            color: theme.colorScheme.tertiary,
          ),
          title: Text(l10n.hardwareInfo),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.screenSize}: ${systemInfo.screenWidth.toInt()}×${systemInfo.screenHeight.toInt()} (${systemInfo.pixelRatio}x)'),
              if (systemInfo.totalMemory != null)
                Text('${l10n.totalMemory}: ${systemInfo.totalMemory}'),
              Text('${l10n.physicalDevice}: ${systemInfo.isPhysicalDevice ? l10n.yes : l10n.no}'),
            ],
          ),
          isThreeLine: true,
        ),

        // 运行环境信息
        ListTile(
          leading: Icon(
            Icons.code,
            color: theme.colorScheme.outline,
          ),
          title: Text(l10n.runtimeEnvironment),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.buildMode}: ${systemInfo.buildMode}'),
              Text('${l10n.debugMode}: ${systemInfo.isDebugMode ? l10n.yes : l10n.no}'),
            ],
          ),
          isThreeLine: true,
        ),

        // 复制系统信息按钮
        ListTile(
          leading: Icon(
            Icons.copy,
            color: theme.colorScheme.primary,
          ),
          title: Text(l10n.copyVersionInfo),
          onTap: () => _copySystemInfo(context, l10n, systemInfo),
          trailing: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Future<void> _copySystemInfo(
    BuildContext context,
    AppLocalizations l10n,
    DetailedSystemInfo systemInfo,
  ) async {
    try {
      final formattedInfo = systemInfo.toFormattedString(l10n);
      await Clipboard.setData(ClipboardData(text: formattedInfo));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.versionInfoCopied),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      AppLogger.info(
        '用户复制系统信息',
        data: {
          'operation': 'copy_system_info',
          'appVersion': systemInfo.appVersion,
          'platform': systemInfo.platformName,
        },
        tag: 'ui',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '复制系统信息失败',
        data: {
          'operation': 'copy_system_info',
          'error': e.toString(),
        },
        tag: 'ui',
        error: e,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.copyFailed(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// 保留旧的数据模型以兼容其他可能的引用
class AppVersionInfoData {
  final String appName;
  final String appVersion;
  final String buildNumber;
  final String buildTime;
  final String buildEnvironment;
  final String? gitCommit;
  final String? gitBranch;
  final String platformName;
  final String operatingSystem;
  final String flutterVersion;
  final String dartVersion;

  const AppVersionInfoData({
    required this.appName,
    required this.appVersion,
    required this.buildNumber,
    required this.buildTime,
    required this.buildEnvironment,
    this.gitCommit,
    this.gitBranch,
    required this.platformName,
    required this.operatingSystem,
    required this.flutterVersion,
    required this.dartVersion,
  });

  String toFormattedString(AppLocalizations l10n) {
    final buffer = StringBuffer();
    buffer.writeln('=== ${l10n.appVersionInfo} ===');
    buffer.writeln('${l10n.appTitle}: $appName');
    buffer.writeln('${l10n.appVersion}: $appVersion');
    buffer.writeln('${l10n.buildNumber}: $buildNumber');
    buffer.writeln('${l10n.buildTime}: $buildTime');
    buffer.writeln('${l10n.buildEnvironment}: $buildEnvironment');

    if (gitCommit != null) {
      buffer.writeln('${l10n.gitCommit}: $gitCommit');
    }
    if (gitBranch != null) {
      buffer.writeln('${l10n.gitBranch}: $gitBranch');
    }

    buffer.writeln();
    buffer.writeln('=== ${l10n.platformInfo} ===');
    buffer.writeln('${l10n.operatingSystem}: $operatingSystem');
    buffer.writeln('${l10n.flutterVersion}: $flutterVersion');
    buffer.writeln('${l10n.dartVersion}: $dartVersion');

    return buffer.toString();
  }
}
