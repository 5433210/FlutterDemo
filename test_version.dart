import 'dart:io';

import 'lib/platform/linux_version_config.dart';
import 'lib/presentation/pages/settings/components/app_version_settings.dart';

void main() async {
  print('=== 版本信息测试 ===');

  try {
    // 测试 Linux 版本配置
    print('\n1. 测试 LinuxVersionConfig:');
    final packageInfo = await LinuxVersionConfig.getVersionInfo();
    print('  App Name: ${packageInfo.appName}');
    print('  Version: ${packageInfo.version}');
    print('  Build Number: ${packageInfo.buildNumber}');
    print('  Package Name: ${packageInfo.packageName}');

    // 测试应用版本信息服务
    print('\n2. 测试 AppVersionInfoService:');
    final versionInfo = await AppVersionInfoService.getVersionInfo();
    print('  App Name: ${versionInfo.appName}');
    print('  App Version: ${versionInfo.appVersion}');
    print('  Build Number: ${versionInfo.buildNumber}');
    print('  Build Time: ${versionInfo.buildTime}');
    print('  Build Environment: ${versionInfo.buildEnvironment}');
    print('  Platform Name: ${versionInfo.platformName}');
    print('  Operating System: ${versionInfo.operatingSystem}');
    print('  Flutter Version: ${versionInfo.flutterVersion}');
    print('  Dart Version: ${versionInfo.dartVersion}');

    // 测试是否是 Linux 平台
    print('\n3. 平台检测:');
    print('  Is Linux: ${Platform.isLinux}');
    print('  Operating System: ${Platform.operatingSystem}');
  } catch (e, stackTrace) {
    print('错误: $e');
    print('堆栈跟踪: $stackTrace');
  }
}
