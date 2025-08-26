import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';

/// 详细的系统信息数据模型
class DetailedSystemInfo {
  // 应用信息
  final String appName;
  final String appVersion;
  final String buildNumber;

  // 设备硬件信息
  final String deviceModel;
  final String deviceManufacturer;
  final String deviceId;
  final bool isPhysicalDevice;

  // 操作系统信息
  final String operatingSystem;
  final String osVersion;
  final String platformName;

  // 屏幕信息
  final double screenWidth;
  final double screenHeight;
  final double pixelRatio;
  final String screenSize;
  
  // Flutter运行时信息
  final String flutterVersion;
  final String dartVersion;
  final String buildMode;
  final bool isDebugMode;

  // 内存和存储信息（如果可获取）
  final String? totalMemory;
  final String? availableMemory;
  final String? architecture;

  const DetailedSystemInfo({
    required this.appName,
    required this.appVersion,
    required this.buildNumber,
    required this.deviceModel,
    required this.deviceManufacturer,
    required this.deviceId,
    required this.isPhysicalDevice,
    required this.operatingSystem,
    required this.osVersion,
    required this.platformName,
    required this.screenWidth,
    required this.screenHeight,
    required this.pixelRatio,
    required this.screenSize,
    required this.flutterVersion,
    required this.dartVersion,
    required this.buildMode,
    required this.isDebugMode,
    this.totalMemory,
    this.availableMemory,
    this.architecture,
  });

  /// 转换为格式化字符串，用于复制或调试
  String toFormattedString(AppLocalizations l10n) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== ${l10n.systemInfo} ===');
    buffer.writeln('${l10n.operatingSystem}: $operatingSystem $osVersion');
    buffer.writeln('${l10n.platform}: $platformName');
    buffer.writeln('${l10n.deviceModel}: $deviceModel');
    buffer.writeln('${l10n.manufacturer}: $deviceManufacturer');
    buffer.writeln('${l10n.deviceId}: ${deviceId.length > 8 ? '${deviceId.substring(0, 8)}...' : deviceId}');
    buffer.writeln('${l10n.physicalDevice}: ${isPhysicalDevice ? l10n.yes : l10n.no}');
    if (architecture != null) {
      buffer.writeln('${l10n.architecture}: $architecture');
    }
    
    buffer.writeln();
    buffer.writeln('=== ${l10n.screenInfo} ===');
    buffer.writeln('${l10n.screenSize}: ${screenWidth.toInt()}x${screenHeight.toInt()}');
    buffer.writeln('${l10n.pixelDensity}: ${pixelRatio}x');
    buffer.writeln('${l10n.screenSizeCategory}: $screenSize');
    
    if (totalMemory != null) {
      buffer.writeln();
      buffer.writeln('=== ${l10n.memoryInfo} ===');
      buffer.writeln('${l10n.totalMemory}: $totalMemory');
      if (availableMemory != null) {
        buffer.writeln('${l10n.availableMemory}: $availableMemory');
      }
    }
    
    buffer.writeln();
    buffer.writeln('=== ${l10n.applicationInfo} ===');
    buffer.writeln('${l10n.applicationName}: $appName');
    buffer.writeln('${l10n.appVersion}: $appVersion');
    buffer.writeln('${l10n.buildMode}: $buildMode');
    buffer.writeln('${l10n.debugMode}: ${isDebugMode ? l10n.yes : l10n.no}');
    
    buffer.writeln();
    buffer.writeln('=== ${l10n.runtimeInfo} ===');
    buffer.writeln('${l10n.flutterVersionLabel}: $flutterVersion');
    buffer.writeln('${l10n.dartVersionLabel}: $dartVersion');
    
    return buffer.toString();
  }
}

/// 系统信息服务
class SystemInfoService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// 获取详细的系统信息
  static Future<DetailedSystemInfo> getDetailedSystemInfo() async {
    try {
      // 获取包信息
      final packageInfo = await PackageInfo.fromPlatform();
      
      // 获取屏幕信息
      final view = ui.PlatformDispatcher.instance.views.first;
      final screenSize = view.physicalSize / view.devicePixelRatio;
      
      // 获取设备信息
      final deviceInfo = await _getDeviceSpecificInfo();
      
      return DetailedSystemInfo(
        // 应用信息
        appName: packageInfo.appName,
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        
        // 设备信息
        deviceModel: deviceInfo['model'] ?? 'Unknown',
        deviceManufacturer: deviceInfo['manufacturer'] ?? 'Unknown',
        deviceId: deviceInfo['deviceId'] ?? 'Unknown',
        isPhysicalDevice: deviceInfo['isPhysicalDevice'] ?? true,
        
        // 系统信息
        operatingSystem: _getOperatingSystemName(),
        osVersion: deviceInfo['osVersion'] ?? 'Unknown',
        platformName: _getPlatformName(),
        
        // 屏幕信息
        screenWidth: screenSize.width,
        screenHeight: screenSize.height,
        pixelRatio: view.devicePixelRatio,
        screenSize: _getScreenSizeCategory(screenSize),
        
        // Flutter信息
        flutterVersion: _getFlutterVersion(),
        dartVersion: _getDartVersion(),
        buildMode: _getBuildMode(),
        isDebugMode: kDebugMode,
        
        // 其他信息
        architecture: deviceInfo['architecture'],
        totalMemory: deviceInfo['totalMemory'],
        availableMemory: deviceInfo['availableMemory'],
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '获取系统信息失败',
        error: e,
        stackTrace: stackTrace,
        tag: 'SystemInfoService',
      );
      rethrow;
    }
  }

  /// 获取平台特定的设备信息
  static Future<Map<String, dynamic>> _getDeviceSpecificInfo() async {
    final Map<String, dynamic> info = {};
    
    try {
      if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        info['model'] = windowsInfo.computerName;
        info['manufacturer'] = 'Microsoft Windows';
        info['deviceId'] = windowsInfo.computerName;
        info['isPhysicalDevice'] = true;
        info['osVersion'] = '${windowsInfo.majorVersion}.${windowsInfo.minorVersion}.${windowsInfo.buildNumber}';
        info['architecture'] = _getWindowsArchitecture();
        
        // 尝试获取内存信息
        try {
          final memoryInfo = await _getWindowsMemoryInfo();
          info.addAll(memoryInfo);
        } catch (e) {
          AppLogger.warning('无法获取Windows内存信息: $e');
        }
        
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        info['model'] = '${androidInfo.brand} ${androidInfo.model}';
        info['manufacturer'] = androidInfo.manufacturer;
        info['deviceId'] = androidInfo.id;
        info['isPhysicalDevice'] = androidInfo.isPhysicalDevice;
        info['osVersion'] = 'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})';
        info['architecture'] = androidInfo.supportedAbis.isNotEmpty ? androidInfo.supportedAbis.first : 'Unknown';
        
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        info['model'] = '${iosInfo.name} ${iosInfo.model}';
        info['manufacturer'] = 'Apple';
        info['deviceId'] = iosInfo.identifierForVendor ?? 'Unknown';
        info['isPhysicalDevice'] = iosInfo.isPhysicalDevice;
        info['osVersion'] = 'iOS ${iosInfo.systemVersion}';
        
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        info['model'] = macInfo.model;
        info['manufacturer'] = 'Apple';
        info['deviceId'] = macInfo.systemGUID ?? 'Unknown';
        info['isPhysicalDevice'] = true;
        info['osVersion'] = 'macOS ${macInfo.osRelease}';
        info['architecture'] = macInfo.arch;
        
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        info['model'] = linuxInfo.name;
        info['manufacturer'] = 'Linux';
        info['deviceId'] = linuxInfo.machineId ?? 'Unknown';
        info['isPhysicalDevice'] = true;
        info['osVersion'] = linuxInfo.prettyName;
        
      } else if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        info['model'] = '${webInfo.browserName} ${webInfo.appVersion}';
        info['manufacturer'] = webInfo.vendor ?? 'Unknown';
        info['deviceId'] = webInfo.userAgent ?? 'Unknown';
        info['isPhysicalDevice'] = false;
        info['osVersion'] = webInfo.platform ?? 'Unknown';
      }
    } catch (e) {
      AppLogger.error('获取平台特定设备信息失败: $e');
      // 返回默认值
      info['model'] = 'Unknown Device';
      info['manufacturer'] = 'Unknown';
      info['deviceId'] = 'Unknown';
      info['isPhysicalDevice'] = true;
      info['osVersion'] = 'Unknown';
    }
    
    return info;
  }

  /// 获取Windows架构信息
  static String _getWindowsArchitecture() {
    try {
      // 尝试从环境变量获取架构信息
      final arch = Platform.environment['PROCESSOR_ARCHITECTURE'];
      if (arch != null) {
        switch (arch.toUpperCase()) {
          case 'AMD64':
            return 'x64';
          case 'X86':
            return 'x86';
          case 'ARM64':
            return 'ARM64';
          default:
            return arch;
        }
      }
    } catch (e) {
      AppLogger.warning('无法获取Windows架构信息: $e');
    }
    return 'Unknown';
  }

  /// 获取Windows内存信息
  static Future<Map<String, dynamic>> _getWindowsMemoryInfo() async {
    final Map<String, dynamic> memInfo = {};
    
    try {
      // 在Windows上，我们可以尝试使用wmic命令获取内存信息
      final result = await Process.run('wmic', [
        'computersystem',
        'get',
        'TotalPhysicalMemory',
        '/value'
      ]);
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match = RegExp(r'TotalPhysicalMemory=(\d+)').firstMatch(output);
        if (match != null) {
          final bytes = int.tryParse(match.group(1) ?? '');
          if (bytes != null) {
            memInfo['totalMemory'] = _formatBytes(bytes);
          }
        }
      }
    } catch (e) {
      AppLogger.warning('使用wmic获取内存信息失败: $e');
    }
    
    return memInfo;
  }

  /// 格式化字节数
  static String _formatBytes(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// 获取操作系统名称
  static String _getOperatingSystemName() {
    if (kIsWeb) return 'Web';
    return Platform.operatingSystem;
  }

  /// 获取平台名称
  static String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  /// 获取屏幕尺寸分类
  static String _getScreenSizeCategory(ui.Size screenSize) {
    final diagonal = sqrt(screenSize.width * screenSize.width + 
                     screenSize.height * screenSize.height);
    
    if (diagonal < 5) return 'Small';
    if (diagonal < 7) return 'Medium';
    if (diagonal < 10) return 'Large';
    return 'Extra Large';
  }

  /// 获取构建模式
  static String _getBuildMode() {
    if (kDebugMode) return 'Debug';
    if (kProfileMode) return 'Profile';
    if (kReleaseMode) return 'Release';
    return 'Unknown';
  }

  /// 获取Flutter版本
  static String _getFlutterVersion() {
    return const String.fromEnvironment('FLUTTER_VERSION', defaultValue: '3.29.2');
  }

  /// 获取Dart版本
  static String _getDartVersion() {
    return const String.fromEnvironment('DART_VERSION', defaultValue: '3.7.0');
  }
}