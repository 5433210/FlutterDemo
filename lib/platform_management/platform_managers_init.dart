/// 平台版本管理器初始化
library platform_managers_init;

import 'android_version_manager.dart';
import 'ios_version_manager.dart';
import 'platform_version_manager.dart';
import 'web_version_manager.dart';
import 'windows_version_manager.dart';
import 'macos_version_manager.dart';
import 'linux_version_manager.dart';
import 'ohos_version_manager.dart';

/// 初始化所有平台版本管理器
void initializePlatformManagers() {
  // 注册Android平台管理器
  PlatformVersionManagerFactory.registerManager(
    'android',
    AndroidVersionManager(),
  );
  
  // 注册iOS平台管理器
  PlatformVersionManagerFactory.registerManager(
    'ios',
    IOSVersionManager(),
  );
  
  // 注册Web平台管理器
  PlatformVersionManagerFactory.registerManager(
    'web',
    WebVersionManager(),
  );
  
  // 注册Windows平台管理器
  PlatformVersionManagerFactory.registerManager(
    'windows',
    WindowsVersionManager(),
  );
  
  // 注册macOS平台管理器
  PlatformVersionManagerFactory.registerManager(
    'macos',
    MacOSVersionManager(),
  );
  
  // 注册Linux平台管理器
  PlatformVersionManagerFactory.registerManager(
    'linux',
    LinuxVersionManager(),
  );
  
  // 注册鸿蒙OS平台管理器
  PlatformVersionManagerFactory.registerManager(
    'ohos',
    OHOSVersionManager(),
  );
}

/// 获取支持的平台管理器列表
List<String> getSupportedPlatformIds() {
  return PlatformVersionManagerFactory.getSupportedPlatforms();
}

/// 检查平台是否支持版本管理
bool isPlatformVersionManagementSupported(String platformId) {
  return PlatformVersionManagerFactory.isPlatformSupported(platformId);
}

/// 获取当前平台的版本管理器
PlatformVersionManager? getCurrentPlatformVersionManager() {
  return PlatformVersionManagerFactory.getCurrentPlatformManager();
}

/// 批量检查所有平台版本一致性
Future<Map<String, dynamic>> checkAllPlatformsVersionConsistency() async {
  final syncManager = VersionSyncManager.instance;
  final versions = await syncManager.checkVersionConsistency();
  return syncManager.generateConsistencyReport(versions);
}

/// 同步所有平台版本
Future<Map<String, bool>> syncAllPlatformsVersion(
  String versionName,
  String versionCode,
) async {
  final syncManager = VersionSyncManager.instance;
  return await syncManager.syncAllPlatforms(versionName, versionCode);
}

/// 验证所有平台构建环境
Future<Map<String, Map<String, dynamic>>> validateAllPlatformsBuildEnvironment() async {
  final results = <String, Map<String, dynamic>>{};
  final managers = PlatformVersionManagerFactory.getAllManagers();
  
  for (final entry in managers.entries) {
    final platformId = entry.key;
    final manager = entry.value;
    
    try {
      // 调用平台特定的环境验证方法
      Map<String, dynamic> validation;
      
      if (manager is AndroidVersionManager) {
        validation = await manager.validateBuildEnvironment();
      } else if (manager is IOSVersionManager) {
        validation = await manager.validateBuildEnvironment();
      } else if (manager is WebVersionManager) {
        validation = await manager.validateBuildEnvironment();
      } else if (manager is WindowsVersionManager) {
        validation = await manager.validateBuildEnvironment();
      } else if (manager is MacOSVersionManager) {
        validation = await manager.validateBuildEnvironment();
      } else if (manager is LinuxVersionManager) {
        validation = await manager.validateBuildEnvironment();
      } else if (manager is OHOSVersionManager) {
        validation = await manager.validateBuildEnvironment();
      } else {
        // 默认验证逻辑
        validation = {
          'isValid': true,
          'issues': <String>[],
          'recommendations': ['平台环境验证功能待实现'],
        };
      }
      
      results[platformId] = validation;
    } catch (e) {
      results[platformId] = {
        'isValid': false,
        'issues': ['环境验证异常: $e'],
        'recommendations': ['请检查平台配置'],
      };
    }
  }
  
  return results;
}

/// 生成所有平台版本信息报告
Future<Map<String, dynamic>> generateAllPlatformsVersionReport() async {
  final report = <String, dynamic>{
    'timestamp': DateTime.now().toIso8601String(),
    'platforms': <String, dynamic>{},
    'summary': <String, dynamic>{},
  };
  
  final managers = PlatformVersionManagerFactory.getAllManagers();
  final platformVersions = <String, PlatformVersionInfo>{};
  
  // 收集所有平台版本信息
  for (final entry in managers.entries) {
    final platformId = entry.key;
    final manager = entry.value;
    
    try {
      final versionInfo = await manager.getCurrentVersion();
      platformVersions[platformId] = versionInfo;
      
      report['platforms'][platformId] = {
        'versionInfo': versionInfo.toMap(),
        'configPaths': manager.getConfigFilePaths(),
        'status': 'success',
      };
    } catch (e) {
      report['platforms'][platformId] = {
        'status': 'error',
        'error': e.toString(),
        'configPaths': manager.getConfigFilePaths(),
      };
    }
  }
  
  // 生成摘要信息
  final syncManager = VersionSyncManager.instance;
  final consistencyReport = syncManager.generateConsistencyReport(platformVersions);
  
  report['summary'] = {
    'totalPlatforms': managers.length,
    'successfulPlatforms': platformVersions.length,
    'failedPlatforms': managers.length - platformVersions.length,
    'isConsistent': consistencyReport['isConsistent'],
    'versionGroups': consistencyReport['versionGroups'],
  };
  
  return report;
} 