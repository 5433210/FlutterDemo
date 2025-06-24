import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../infrastructure/logging/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/settings/settings_section.dart';

final appVersionInfoProvider = FutureProvider<AppVersionInfoData>((ref) async {
  return await AppVersionInfoService.getVersionInfo();
});

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

class AppVersionInfoService {
  static Future<AppVersionInfoData> getVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      // 处理Windows平台的版本格式问题
      String version = packageInfo.version;
      String buildNumber = packageInfo.buildNumber;

      // Windows可能返回 "1.0.1.0" 格式，需要转换为 "1.0.1"
      if (Platform.isWindows && version.contains('.')) {
        final parts = version.split('.');
        if (parts.length == 4 && parts[3] == '0') {
          version = parts.take(3).join('.');
        }
      }

      // 如果buildNumber为空，尝试从version中提取
      if (buildNumber.isEmpty && version.contains('+')) {
        final versionParts = version.split('+');
        if (versionParts.length == 2) {
          version = versionParts[0];
          buildNumber = versionParts[1];
        }
      }

      // 如果仍然为空，使用默认值
      if (buildNumber.isEmpty) {
        buildNumber = '20250623001';
      }

      return AppVersionInfoData(
        appName: packageInfo.appName,
        appVersion: version,
        buildNumber: buildNumber,
        buildTime: DateTime.now().toIso8601String(),
        buildEnvironment: kDebugMode ? 'debug' : 'release',
        gitCommit: null,
        gitBranch: null,
        platformName: _getPlatformName(),
        operatingSystem: _getOperatingSystem(),
        flutterVersion: _getFlutterVersion(),
        dartVersion: _getDartVersion(),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '获取应用版本信息失败',
        data: {
          'operation': 'get_version_info',
          'error': e.toString(),
        },
        tag: 'system',
        error: e,
        stackTrace: stackTrace,
      ); // 返回默认信息，使用本地化"未知"
      return AppVersionInfoData(
        appName: 'Char As Gem',
        appVersion: '1.0.0',
        buildNumber: 'Unknown', // 这里将在UI层显示时被替换为本地化文本
        buildTime: DateTime.now().toIso8601String(),
        buildEnvironment: kDebugMode ? 'debug' : 'release',
        platformName: _getPlatformName(),
        operatingSystem: _getOperatingSystem(),
        flutterVersion: _getFlutterVersion(),
        dartVersion: _getDartVersion(),
      );
    }
  }

  static String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown Platform'; // 这里将在UI层显示时被替换为本地化文本
  }

  static String _getOperatingSystem() {
    if (kIsWeb) return 'Web Browser';
    return Platform.operatingSystem;
  }

  static String _getFlutterVersion() {
    // 这里可以根据需要从构建信息中获取，暂时返回固定值
    return 'Flutter ${const String.fromEnvironment('FLUTTER_VERSION', defaultValue: '3.29.2')}';
  }

  static String _getDartVersion() {
    // 这里可以根据需要从构建信息中获取，暂时返回固定值
    return 'Dart ${const String.fromEnvironment('DART_VERSION', defaultValue: '3.7.0')}';
  }
}

class AppVersionSettings extends ConsumerWidget {
  const AppVersionSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final versionInfoAsync = ref.watch(appVersionInfoProvider);

    return SettingsSection(
      title: l10n.about,
      children: [
        versionInfoAsync.when(
          data: (versionInfo) =>
              _buildVersionInfo(context, l10n, theme, versionInfo),
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

  Widget _buildVersionInfo(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    AppVersionInfoData versionInfo,
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
              Text('${l10n.appVersion}: ${versionInfo.appVersion}'),
              Text(
                  '${l10n.buildNumber}: ${versionInfo.buildNumber == "Unknown" ? l10n.unknown : versionInfo.buildNumber}'),
              Text('${l10n.buildEnvironment}: ${versionInfo.buildEnvironment}'),
            ],
          ),
          isThreeLine: true,
        ),

        // 系统信息
        ListTile(
          leading: Icon(
            Icons.phone_android,
            color: theme.colorScheme.secondary,
          ),
          title: Text(l10n.systemInfo),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.operatingSystem}: ${versionInfo.operatingSystem}'),
              Text(versionInfo.flutterVersion),
              Text(versionInfo.dartVersion),
            ],
          ),
          isThreeLine: true,
        ),

        // 复制版本信息按钮
        ListTile(
          leading: Icon(
            Icons.copy,
            color: theme.colorScheme.tertiary,
          ),
          title: Text(l10n.copyVersionInfo),
          onTap: () => _copyVersionInfo(context, l10n, versionInfo),
          trailing: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Future<void> _copyVersionInfo(
    BuildContext context,
    AppLocalizations l10n,
    AppVersionInfoData versionInfo,
  ) async {
    try {
      final formattedInfo = versionInfo.toFormattedString(l10n);
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
        '用户复制版本信息',
        data: {
          'operation': 'copy_version_info',
          'appVersion': versionInfo.appVersion,
          'platform': versionInfo.platformName,
        },
        tag: 'ui',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '复制版本信息失败',
        data: {
          'operation': 'copy_version_info',
          'error': e.toString(),
        },
        tag: 'ui',
        error: e,
        stackTrace: stackTrace,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('复制失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
