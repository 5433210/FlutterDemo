/// iOS平台版本管理器
library ios_version_manager;

import 'dart:io';

import 'platform_version_manager.dart';

/// iOS平台版本管理器实现
class IOSVersionManager extends PlatformVersionManager {
  static const String _infoPlistPath = 'ios/Runner/Info.plist';
  static const String _backupSuffix = '.version_backup';
  
  @override
  String get platformId => 'ios';
  
  @override
  String get platformDisplayName => 'iOS';
  
  @override
  Future<PlatformVersionInfo> getCurrentVersion() async {
    try {
      final infoPlistFile = File(_infoPlistPath);
      if (!infoPlistFile.existsSync()) {
        throw Exception('iOS Info.plist 文件不存在: $_infoPlistPath');
      }
      
      final content = await infoPlistFile.readAsString();
      final versionName = _extractCFBundleShortVersionString(content);
      final versionCode = _extractCFBundleVersion(content);
      
      return PlatformVersionInfo(
        versionName: versionName,
        versionCode: versionCode,
        platformId: platformId,
        platformDisplayName: platformDisplayName,
        additionalProperties: {
          'configPath': _infoPlistPath,
          'extractedAt': DateTime.now().toIso8601String(),
          'CFBundleShortVersionString': versionName,
          'CFBundleVersion': versionCode,
        },
      );
    } catch (e) {
      throw Exception('获取iOS版本信息失败: $e');
    }
  }
  
  @override
  Future<bool> updateVersion(String versionName, String versionCode) async {
    try {
      final infoPlistFile = File(_infoPlistPath);
      if (!infoPlistFile.existsSync()) {
        throw Exception('iOS Info.plist 文件不存在');
      }
      
      // 备份当前配置
      await backupConfig();
      
      final content = await infoPlistFile.readAsString();
      final updatedContent = _updateVersionInContent(content, versionName, versionCode);
      
      await infoPlistFile.writeAsString(updatedContent);
      
      // 验证更新是否成功
      final updatedVersion = await getCurrentVersion();
      final success = updatedVersion.versionName == versionName && 
                     updatedVersion.versionCode == versionCode;
      
      if (!success) {
        // 如果更新失败，恢复备份
        await restoreConfig();
        throw Exception('版本更新验证失败');
      }
      
      return true;
    } catch (e) {
      // 尝试恢复备份
      await restoreConfig();
      throw Exception('更新iOS版本失败: $e');
    }
  }
  
  @override
  bool validateVersionFormat(String versionName, String versionCode) {
    // 验证版本名称格式 (如: 1.0.0)
    final versionNamePattern = RegExp(r'^\d+\.\d+\.\d+$');
    if (!versionNamePattern.hasMatch(versionName)) {
      return false;
    }
    
    // iOS的CFBundleVersion可以是数字或字符串
    // 通常使用构建号，可以是纯数字或包含点的版本号
    final versionCodePattern = RegExp(r'^[\d.]+$');
    if (!versionCodePattern.hasMatch(versionCode)) {
      return false;
    }
    
    return true;
  }
  
  @override
  List<String> getConfigFilePaths() {
    return [_infoPlistPath];
  }
  
  @override
  Future<bool> backupConfig() async {
    try {
      final infoPlistFile = File(_infoPlistPath);
      if (!infoPlistFile.existsSync()) {
        return false;
      }
      
      final backupFile = File('$_infoPlistPath$_backupSuffix');
      await infoPlistFile.copy(backupFile.path);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> restoreConfig() async {
    try {
      final backupFile = File('$_infoPlistPath$_backupSuffix');
      if (!backupFile.existsSync()) {
        return false;
      }
      
      final infoPlistFile = File(_infoPlistPath);
      await backupFile.copy(infoPlistFile.path);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 从Info.plist内容中提取CFBundleShortVersionString
  String _extractCFBundleShortVersionString(String content) {
    // 匹配 <key>CFBundleShortVersionString</key><string>1.0.0</string>
    final pattern = RegExp(
      r'<key>CFBundleShortVersionString</key>\s*<string>([^<]+)</string>',
      multiLine: true,
    );
    
    final match = pattern.firstMatch(content);
    if (match != null) {
      return match.group(1)!;
    }
    
    throw Exception('无法在Info.plist中找到CFBundleShortVersionString');
  }
  
  /// 从Info.plist内容中提取CFBundleVersion
  String _extractCFBundleVersion(String content) {
    // 匹配 <key>CFBundleVersion</key><string>123</string>
    final pattern = RegExp(
      r'<key>CFBundleVersion</key>\s*<string>([^<]+)</string>',
      multiLine: true,
    );
    
    final match = pattern.firstMatch(content);
    if (match != null) {
      return match.group(1)!;
    }
    
    throw Exception('无法在Info.plist中找到CFBundleVersion');
  }
  
  /// 更新Info.plist内容中的版本信息
  String _updateVersionInContent(String content, String versionName, String versionCode) {
    // 更新CFBundleShortVersionString
    final versionNamePattern = RegExp(
      r'(<key>CFBundleShortVersionString</key>\s*<string>)[^<]+(</string>)',
      multiLine: true,
    );
    content = content.replaceFirst(versionNamePattern, '${versionNamePattern.firstMatch(content)!.group(1)}$versionName${versionNamePattern.firstMatch(content)!.group(2)}');
    
    // 更新CFBundleVersion
    final versionCodePattern = RegExp(
      r'(<key>CFBundleVersion</key>\s*<string>)[^<]+(</string>)',
      multiLine: true,
    );
    content = content.replaceFirst(versionCodePattern, '${versionCodePattern.firstMatch(content)!.group(1)}$versionCode${versionCodePattern.firstMatch(content)!.group(2)}');
    
    return content;
  }
  
  /// 获取iOS特定的版本配置信息
  Future<Map<String, dynamic>> getIOSSpecificInfo() async {
    try {
      final infoPlistFile = File(_infoPlistPath);
      if (!infoPlistFile.existsSync()) {
        return {};
      }
      
      final content = await infoPlistFile.readAsString();
      final info = <String, dynamic>{};
      
      // 提取Bundle Identifier
      final bundleIdMatch = RegExp(
        r'<key>CFBundleIdentifier</key>\s*<string>([^<]+)</string>',
        multiLine: true,
      ).firstMatch(content);
      if (bundleIdMatch != null) {
        info['bundleIdentifier'] = bundleIdMatch.group(1);
      }
      
      // 提取Bundle Name
      final bundleNameMatch = RegExp(
        r'<key>CFBundleName</key>\s*<string>([^<]+)</string>',
        multiLine: true,
      ).firstMatch(content);
      if (bundleNameMatch != null) {
        info['bundleName'] = bundleNameMatch.group(1);
      }
      
      // 提取Bundle Display Name
      final displayNameMatch = RegExp(
        r'<key>CFBundleDisplayName</key>\s*<string>([^<]+)</string>',
        multiLine: true,
      ).firstMatch(content);
      if (displayNameMatch != null) {
        info['displayName'] = displayNameMatch.group(1);
      }
      
      // 提取Minimum OS Version
      final minOSMatch = RegExp(
        r'<key>MinimumOSVersion</key>\s*<string>([^<]+)</string>',
        multiLine: true,
      ).firstMatch(content);
      if (minOSMatch != null) {
        info['minimumOSVersion'] = minOSMatch.group(1);
      }
      
      return info;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// 验证iOS构建环境
  Future<Map<String, dynamic>> validateBuildEnvironment() async {
    final result = <String, dynamic>{
      'isValid': false,
      'issues': <String>[],
      'recommendations': <String>[],
    };
    
    try {
      // 检查Info.plist文件
      final infoPlistFile = File(_infoPlistPath);
      if (!infoPlistFile.existsSync()) {
        result['issues'].add('Info.plist文件不存在');
        return result;
      }
      
      // 检查iOS目录结构
      final iosDir = Directory('ios');
      if (!iosDir.existsSync()) {
        result['issues'].add('ios目录不存在');
        return result;
      }
      
      // 检查关键文件
      final requiredFiles = [
        'ios/Runner.xcodeproj/project.pbxproj',
        'ios/Runner/AppDelegate.swift',
        'ios/Podfile',
      ];
      
      for (final filePath in requiredFiles) {
        if (!File(filePath).existsSync()) {
          result['issues'].add('缺少必要文件: $filePath');
        }
      }
      
      // 检查版本配置
      final versionInfo = await getCurrentVersion();
      if (!validateVersionFormat(versionInfo.versionName, versionInfo.versionCode)) {
        result['issues'].add('版本格式不正确');
      }
      
      // 生成建议
      if (result['issues'].isEmpty) {
        result['isValid'] = true;
        result['recommendations'].add('iOS构建环境配置正确');
      } else {
        result['recommendations'].add('请修复上述问题后重新检查');
        result['recommendations'].add('确保已安装Xcode和CocoaPods');
      }
      
      return result;
    } catch (e) {
      result['issues'].add('环境验证失败: $e');
      return result;
    }
  }
} 