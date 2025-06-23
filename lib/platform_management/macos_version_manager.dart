/// macOS平台版本管理器
library macos_version_manager;

import 'dart:io';

import 'platform_version_manager.dart';

/// macOS平台版本管理器实现
class MacOSVersionManager extends PlatformVersionManager {
  static const String _infoPlistPath = 'macos/Runner/Info.plist';
  static const String _backupSuffix = '.version_backup';
  
  @override
  String get platformId => 'macos';
  
  @override
  String get platformDisplayName => 'macOS';
  
  @override
  Future<PlatformVersionInfo> getCurrentVersion() async {
    try {
      final infoPlistFile = File(_infoPlistPath);
      if (!infoPlistFile.existsSync()) {
        throw Exception('macOS Info.plist 文件不存在: $_infoPlistPath');
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
      throw Exception('获取macOS版本信息失败: $e');
    }
  }
  
  @override
  Future<bool> updateVersion(String versionName, String versionCode) async {
    try {
      final infoPlistFile = File(_infoPlistPath);
      if (!infoPlistFile.existsSync()) {
        throw Exception('macOS Info.plist 文件不存在');
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
        await restoreConfig();
        throw Exception('版本更新验证失败');
      }
      
      return true;
    } catch (e) {
      await restoreConfig();
      throw Exception('更新macOS版本失败: $e');
    }
  }
  
  @override
  bool validateVersionFormat(String versionName, String versionCode) {
    // 验证版本名称格式 (如: 1.0.0)
    final versionNamePattern = RegExp(r'^\d+\.\d+\.\d+$');
    if (!versionNamePattern.hasMatch(versionName)) {
      return false;
    }
    
    // macOS的CFBundleVersion可以是数字或字符串
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
    final pattern = RegExp(
      r'<key>CFBundleShortVersionString</key>\s*<string>([^<]+)</string>',
      multiLine: true,
    );
    
    final match = pattern.firstMatch(content);
    if (match != null) {
      return match.group(1)!;
    }
    
    throw Exception('无法在macOS Info.plist中找到CFBundleShortVersionString');
  }
  
  /// 从Info.plist内容中提取CFBundleVersion
  String _extractCFBundleVersion(String content) {
    final pattern = RegExp(
      r'<key>CFBundleVersion</key>\s*<string>([^<]+)</string>',
      multiLine: true,
    );
    
    final match = pattern.firstMatch(content);
    if (match != null) {
      return match.group(1)!;
    }
    
    throw Exception('无法在macOS Info.plist中找到CFBundleVersion');
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
  
  /// 获取macOS特定的版本配置信息
  Future<Map<String, dynamic>> getMacOSSpecificInfo() async {
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
      
      // 提取Minimum System Version
      final minSystemMatch = RegExp(
        r'<key>LSMinimumSystemVersion</key>\s*<string>([^<]+)</string>',
        multiLine: true,
      ).firstMatch(content);
      if (minSystemMatch != null) {
        info['minimumSystemVersion'] = minSystemMatch.group(1);
      }
      
      return info;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// 验证macOS构建环境
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
        result['issues'].add('macOS Info.plist文件不存在');
        return result;
      }
      
      // 检查macOS目录结构
      final macosDir = Directory('macos');
      if (!macosDir.existsSync()) {
        result['issues'].add('macos目录不存在');
        return result;
      }
      
      // 检查关键文件
      final requiredFiles = [
        'macos/Runner.xcodeproj/project.pbxproj',
        'macos/Runner/AppDelegate.swift',
        'macos/Runner/MainFlutterWindow.swift',
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
      
      if (result['issues'].isEmpty) {
        result['isValid'] = true;
        result['recommendations'].add('macOS构建环境配置正确');
      } else {
        result['recommendations'].add('请修复上述问题后重新检查');
        result['recommendations'].add('确保已安装Xcode和macOS开发工具');
      }
      
      return result;
    } catch (e) {
      result['issues'].add('环境验证失败: $e');
      return result;
    }
  }
} 