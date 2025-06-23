/// Android平台版本管理器
library android_version_manager;

import 'dart:io';

import 'platform_version_manager.dart';

/// Android平台版本管理器实现
class AndroidVersionManager extends PlatformVersionManager {
  static const String _buildGradlePath = 'android/app/build.gradle.kts';
  static const String _backupSuffix = '.version_backup';
  
  @override
  String get platformId => 'android';
  
  @override
  String get platformDisplayName => 'Android';
  
  @override
  Future<PlatformVersionInfo> getCurrentVersion() async {
    try {
      final buildGradleFile = File(_buildGradlePath);
      if (!buildGradleFile.existsSync()) {
        throw Exception('Android build.gradle.kts 文件不存在: $_buildGradlePath');
      }
      
      final content = await buildGradleFile.readAsString();
      final versionName = _extractVersionName(content);
      final versionCode = _extractVersionCode(content);
      
      return PlatformVersionInfo(
        versionName: versionName,
        versionCode: versionCode,
        platformId: platformId,
        platformDisplayName: platformDisplayName,
        additionalProperties: {
          'configPath': _buildGradlePath,
          'extractedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('获取Android版本信息失败: $e');
    }
  }
  
  @override
  Future<bool> updateVersion(String versionName, String versionCode) async {
    try {
      final buildGradleFile = File(_buildGradlePath);
      if (!buildGradleFile.existsSync()) {
        throw Exception('Android build.gradle.kts 文件不存在');
      }
      
      // 备份当前配置
      await backupConfig();
      
      final content = await buildGradleFile.readAsString();
      final updatedContent = _updateVersionInContent(content, versionName, versionCode);
      
      await buildGradleFile.writeAsString(updatedContent);
      
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
      throw Exception('更新Android版本失败: $e');
    }
  }
  
  @override
  bool validateVersionFormat(String versionName, String versionCode) {
    // 验证版本名称格式 (如: 1.0.0)
    final versionNamePattern = RegExp(r'^\d+\.\d+\.\d+$');
    if (!versionNamePattern.hasMatch(versionName)) {
      return false;
    }
    
    // 验证版本代码格式 (数字字符串)
    final versionCodePattern = RegExp(r'^\d+$');
    if (!versionCodePattern.hasMatch(versionCode)) {
      return false;
    }
    
    // 验证版本代码范围 (Android限制)
    final versionCodeInt = int.tryParse(versionCode);
    if (versionCodeInt == null || versionCodeInt <= 0 || versionCodeInt > 2100000000) {
      return false;
    }
    
    return true;
  }
  
  @override
  List<String> getConfigFilePaths() {
    return [_buildGradlePath];
  }
  
  @override
  Future<bool> backupConfig() async {
    try {
      final buildGradleFile = File(_buildGradlePath);
      if (!buildGradleFile.existsSync()) {
        return false;
      }
      
      final backupFile = File('$_buildGradlePath$_backupSuffix');
      await buildGradleFile.copy(backupFile.path);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> restoreConfig() async {
    try {
      final backupFile = File('$_buildGradlePath$_backupSuffix');
      if (!backupFile.existsSync()) {
        return false;
      }
      
      final buildGradleFile = File(_buildGradlePath);
      await backupFile.copy(buildGradleFile.path);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 从build.gradle.kts内容中提取版本名称
  String _extractVersionName(String content) {
    // 匹配 versionName = "1.0.0" 或 versionName("1.0.0")
    final patterns = [
      RegExp(r'versionName\s*=\s*"([^"]+)"'),
      RegExp(r'versionName\s*\(\s*"([^"]+)"\s*\)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        return match.group(1)!;
      }
    }
    
    throw Exception('无法在build.gradle.kts中找到versionName');
  }
  
  /// 从build.gradle.kts内容中提取版本代码
  String _extractVersionCode(String content) {
    // 匹配 versionCode = 123 或 versionCode(123)
    final patterns = [
      RegExp(r'versionCode\s*=\s*(\d+)'),
      RegExp(r'versionCode\s*\(\s*(\d+)\s*\)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        return match.group(1)!;
      }
    }
    
    throw Exception('无法在build.gradle.kts中找到versionCode');
  }
  
  /// 更新build.gradle.kts内容中的版本信息
  String _updateVersionInContent(String content, String versionName, String versionCode) {
    // 更新versionName
    final versionNamePatterns = [
      RegExp(r'(versionName\s*=\s*)"[^"]+"'),
      RegExp(r'(versionName\s*\(\s*)"[^"]+("?\s*\))'),
    ];
    
    for (final pattern in versionNamePatterns) {
      if (pattern.hasMatch(content)) {
        content = content.replaceFirst(pattern, '${pattern.firstMatch(content)!.group(1)}"$versionName"');
        break;
      }
    }
    
    // 更新versionCode
    final versionCodePatterns = [
      RegExp(r'(versionCode\s*=\s*)\d+'),
      RegExp(r'(versionCode\s*\(\s*)\d+(\s*\))'),
    ];
    
    for (final pattern in versionCodePatterns) {
      if (pattern.hasMatch(content)) {
        final match = pattern.firstMatch(content)!;
        if (match.groupCount >= 2) {
          content = content.replaceFirst(pattern, '${match.group(1)}$versionCode${match.group(2)}');
        } else {
          content = content.replaceFirst(pattern, '${match.group(1)}$versionCode');
        }
        break;
      }
    }
    
    return content;
  }
  
  /// 获取Android特定的版本配置信息
  Future<Map<String, dynamic>> getAndroidSpecificInfo() async {
    try {
      final buildGradleFile = File(_buildGradlePath);
      if (!buildGradleFile.existsSync()) {
        return {};
      }
      
      final content = await buildGradleFile.readAsString();
      
      // 提取其他Android特定信息
      final info = <String, dynamic>{};
      
      // 提取applicationId
      final applicationIdMatch = RegExp(r'applicationId\s*=?\s*"([^"]+)"').firstMatch(content);
      if (applicationIdMatch != null) {
        info['applicationId'] = applicationIdMatch.group(1);
      }
      
      // 提取minSdkVersion
      final minSdkMatch = RegExp(r'minSdk\s*=?\s*(\d+)').firstMatch(content);
      if (minSdkMatch != null) {
        info['minSdkVersion'] = int.parse(minSdkMatch.group(1)!);
      }
      
      // 提取targetSdkVersion
      final targetSdkMatch = RegExp(r'targetSdk\s*=?\s*(\d+)').firstMatch(content);
      if (targetSdkMatch != null) {
        info['targetSdkVersion'] = int.parse(targetSdkMatch.group(1)!);
      }
      
      // 提取compileSdkVersion
      final compileSdkMatch = RegExp(r'compileSdk\s*=?\s*(\d+)').firstMatch(content);
      if (compileSdkMatch != null) {
        info['compileSdkVersion'] = int.parse(compileSdkMatch.group(1)!);
      }
      
      return info;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// 验证Android构建环境
  Future<Map<String, dynamic>> validateBuildEnvironment() async {
    final result = <String, dynamic>{
      'isValid': false,
      'issues': <String>[],
      'recommendations': <String>[],
    };
    
    try {
      // 检查build.gradle.kts文件
      final buildGradleFile = File(_buildGradlePath);
      if (!buildGradleFile.existsSync()) {
        result['issues'].add('build.gradle.kts文件不存在');
        return result;
      }
      
      // 检查Android目录结构
      final androidDir = Directory('android');
      if (!androidDir.existsSync()) {
        result['issues'].add('android目录不存在');
        return result;
      }
      
      // 检查关键文件
      final requiredFiles = [
        'android/app/src/main/AndroidManifest.xml',
        'android/gradle.properties',
        'android/settings.gradle',
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
        result['recommendations'].add('Android构建环境配置正确');
      } else {
        result['recommendations'].add('请修复上述问题后重新检查');
      }
      
      return result;
    } catch (e) {
      result['issues'].add('环境验证失败: $e');
      return result;
    }
  }
} 