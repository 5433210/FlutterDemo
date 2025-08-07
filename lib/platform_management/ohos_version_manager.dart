/// 鸿蒙OS平台版本管理器
library ohos_version_manager;

import 'dart:io';

import 'dart:convert';

import 'platform_version_manager.dart';

/// 鸿蒙OS平台版本管理器实现
class OHOSVersionManager extends PlatformVersionManager {
  static const String _appConfigPath = 'ohos/app/app.json5';
  static const String _entryConfigPath = 'ohos/entry/src/main/module.json5';
  static const String _backupSuffix = '.version_backup';
  
  @override
  String get platformId => 'ohos';
  
  @override
  String get platformDisplayName => '鸿蒙OS';
  
  @override
  Future<PlatformVersionInfo> getCurrentVersion() async {
    try {
      final appConfigFile = File(_appConfigPath);
      if (!appConfigFile.existsSync()) {
        throw Exception('鸿蒙OS app.json5 文件不存在: $_appConfigPath');
      }
      
      final content = await appConfigFile.readAsString();
      final appConfig = _parseJson5Content(content);
      
      final versionName = appConfig['app']?['versionName']?.toString() ?? '1.0.0';
      final versionCode = appConfig['app']?['versionCode']?.toString() ?? '1';
      
      return PlatformVersionInfo(
        versionName: versionName,
        versionCode: versionCode,
        platformId: platformId,
        platformDisplayName: platformDisplayName,
        additionalProperties: {
          'configPath': _appConfigPath,
          'extractedAt': DateTime.now().toIso8601String(),
          'versionName': versionName,
          'versionCode': versionCode,
        },
      );
    } catch (e) {
      throw Exception('获取鸿蒙OS版本信息失败: $e');
    }
  }
  
  @override
  Future<bool> updateVersion(String versionName, String versionCode) async {
    try {
      final appConfigFile = File(_appConfigPath);
      if (!appConfigFile.existsSync()) {
        throw Exception('鸿蒙OS app.json5 文件不存在');
      }
      
      // 备份当前配置
      await backupConfig();
      
      final content = await appConfigFile.readAsString();
      final updatedContent = _updateVersionInContent(content, versionName, versionCode);
      
      await appConfigFile.writeAsString(updatedContent);
      
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
      throw Exception('更新鸿蒙OS版本失败: $e');
    }
  }
  
  @override
  bool validateVersionFormat(String versionName, String versionCode) {
    // 鸿蒙OS版本格式验证
    final versionNamePattern = RegExp(r'^\d+\.\d+\.\d+$');
    if (!versionNamePattern.hasMatch(versionName)) {
      return false;
    }
    
    // versionCode必须是正整数
    final versionCodeInt = int.tryParse(versionCode);
    return versionCodeInt != null && versionCodeInt > 0;
  }
  
  @override
  List<String> getConfigFilePaths() {
    return [_appConfigPath, _entryConfigPath];
  }
  
  @override
  Future<bool> backupConfig() async {
    try {
      final appConfigFile = File(_appConfigPath);
      if (!appConfigFile.existsSync()) {
        return false;
      }
      
      final backupFile = File('$_appConfigPath$_backupSuffix');
      await appConfigFile.copy(backupFile.path);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> restoreConfig() async {
    try {
      final backupFile = File('$_appConfigPath$_backupSuffix');
      if (!backupFile.existsSync()) {
        return false;
      }
      
      final appConfigFile = File(_appConfigPath);
      await backupFile.copy(appConfigFile.path);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 解析JSON5内容为Map（简化版解析器）
  Map<String, dynamic> _parseJson5Content(String content) {
    try {
      // 移除JSON5注释和多余空白
      String cleanContent = content;
      
      // 移除单行注释 //
      cleanContent = cleanContent.replaceAll(RegExp(r'//.*$', multiLine: true), '');
      
      // 移除多行注释 /* */
      cleanContent = cleanContent.replaceAll(RegExp(r'/\*[\s\S]*?\*/', multiLine: true), '');
      
      // 移除尾随逗号
      cleanContent = cleanContent.replaceAll(RegExp(r',(\s*[}\]])'), r'$1');
      
      // 尝试解析为JSON
      return json.decode(cleanContent) as Map<String, dynamic>;
    } catch (e) {
      // 如果JSON解析失败，尝试手动提取版本信息
      return _extractVersionFromJson5(content);
    }
  }
  
  /// 手动从JSON5内容中提取版本信息
  Map<String, dynamic> _extractVersionFromJson5(String content) {
    final result = <String, dynamic>{
      'app': <String, dynamic>{},
    };
    
    // 提取versionName
    final versionNameMatch = RegExp(r'"versionName"\s*:\s*"([^"]+)"').firstMatch(content);
    if (versionNameMatch != null) {
      result['app']['versionName'] = versionNameMatch.group(1);
    }
    
    // 提取versionCode
    final versionCodeMatch = RegExp(r'"versionCode"\s*:\s*(\d+)').firstMatch(content);
    if (versionCodeMatch != null) {
      result['app']['versionCode'] = int.parse(versionCodeMatch.group(1)!);
    }
    
    return result;
  }
  
  /// 更新JSON5内容中的版本信息
  String _updateVersionInContent(String content, String versionName, String versionCode) {
    // 更新versionName
    final versionNamePattern = RegExp(r'("versionName"\s*:\s*)"[^"]+"');
    content = content.replaceFirst(versionNamePattern, '${versionNamePattern.firstMatch(content)!.group(1)}"$versionName"');
    
    // 更新versionCode
    final versionCodePattern = RegExp(r'("versionCode"\s*:\s*)\d+');
    content = content.replaceFirst(versionCodePattern, '${versionCodePattern.firstMatch(content)!.group(1)}$versionCode');
    
    return content;
  }
  
  /// 获取鸿蒙OS特定的版本配置信息
  Future<Map<String, dynamic>> getOHOSSpecificInfo() async {
    try {
      final appConfigFile = File(_appConfigPath);
      if (!appConfigFile.existsSync()) {
        return {};
      }
      
      final content = await appConfigFile.readAsString();
      final appConfig = _parseJson5Content(content);
      final info = <String, dynamic>{};
      
      // 提取应用基本信息
      final appInfo = appConfig['app'] as Map<String, dynamic>?;
      if (appInfo != null) {
        info['bundleName'] = appInfo['bundleName'];
        info['vendor'] = appInfo['vendor'];
        info['minAPIVersion'] = appInfo['minAPIVersion'];
        info['targetAPIVersion'] = appInfo['targetAPIVersion'];
        info['apiReleaseType'] = appInfo['apiReleaseType'];
      }
      
      return info;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// 验证鸿蒙OS构建环境
  Future<Map<String, dynamic>> validateBuildEnvironment() async {
    final result = <String, dynamic>{
      'isValid': false,
      'issues': <String>[],
      'recommendations': <String>[],
    };
    
    try {
      // 检查app.json5文件
      final appConfigFile = File(_appConfigPath);
      if (!appConfigFile.existsSync()) {
        result['issues'].add('app.json5文件不存在');
        return result;
      }
      
      // 检查鸿蒙OS目录结构
      final ohosDir = Directory('ohos');
      if (!ohosDir.existsSync()) {
        result['issues'].add('ohos目录不存在');
        return result;
      }
      
      // 检查关键文件
      final requiredFiles = [
        'ohos/entry/src/main/module.json5',
        'ohos/entry/src/main/ets/entryability/EntryAbility.ets',
        'ohos/entry/src/main/ets/pages/Index.ets',
        'ohos/build-profile.json5',
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
        result['recommendations'].add('鸿蒙OS构建环境配置正确');
      } else {
        result['recommendations'].add('请修复上述问题后重新检查');
        result['recommendations'].add('确保已安装DevEco Studio和HarmonyOS SDK');
      }
      
      return result;
    } catch (e) {
      result['issues'].add('环境验证失败: $e');
      return result;
    }
  }
} 