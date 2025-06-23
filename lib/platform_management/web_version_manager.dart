/// Web平台版本管理器
library web_version_manager;

import 'dart:convert';
import 'dart:io';

import 'platform_version_manager.dart';

/// Web平台版本管理器实现
class WebVersionManager extends PlatformVersionManager {
  static const String _manifestPath = 'web/manifest.json';
  static const String _backupSuffix = '.version_backup';
  
  @override
  String get platformId => 'web';
  
  @override
  String get platformDisplayName => 'Web';
  
  @override
  Future<PlatformVersionInfo> getCurrentVersion() async {
    try {
      final manifestFile = File(_manifestPath);
      if (!manifestFile.existsSync()) {
        throw Exception('Web manifest.json 文件不存在: $_manifestPath');
      }
      
      final content = await manifestFile.readAsString();
      final manifest = json.decode(content) as Map<String, dynamic>;
      
      final versionName = manifest['version'] as String? ?? '1.0.0';
      final versionCode = manifest['version_name'] as String? ?? versionName;
      
      return PlatformVersionInfo(
        versionName: versionName,
        versionCode: versionCode,
        platformId: platformId,
        platformDisplayName: platformDisplayName,
        additionalProperties: {
          'configPath': _manifestPath,
          'extractedAt': DateTime.now().toIso8601String(),
          'manifestData': manifest,
        },
      );
    } catch (e) {
      throw Exception('获取Web版本信息失败: $e');
    }
  }
  
  @override
  Future<bool> updateVersion(String versionName, String versionCode) async {
    try {
      final manifestFile = File(_manifestPath);
      if (!manifestFile.existsSync()) {
        throw Exception('Web manifest.json 文件不存在');
      }
      
      // 备份当前配置
      await backupConfig();
      
      final content = await manifestFile.readAsString();
      final manifest = json.decode(content) as Map<String, dynamic>;
      
      // 更新版本信息
      manifest['version'] = versionName;
      manifest['version_name'] = versionCode;
      
      // 写入更新的内容
      final updatedContent = const JsonEncoder.withIndent('  ').convert(manifest);
      await manifestFile.writeAsString(updatedContent);
      
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
      throw Exception('更新Web版本失败: $e');
    }
  }
  
  @override
  bool validateVersionFormat(String versionName, String versionCode) {
    // Web版本格式相对灵活
    final versionPattern = RegExp(r'^\d+\.\d+\.\d+');
    return versionPattern.hasMatch(versionName);
  }
  
  @override
  List<String> getConfigFilePaths() {
    return [_manifestPath];
  }
  
  @override
  Future<bool> backupConfig() async {
    try {
      final manifestFile = File(_manifestPath);
      if (!manifestFile.existsSync()) {
        return false;
      }
      
      final backupFile = File('$_manifestPath$_backupSuffix');
      await manifestFile.copy(backupFile.path);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> restoreConfig() async {
    try {
      final backupFile = File('$_manifestPath$_backupSuffix');
      if (!backupFile.existsSync()) {
        return false;
      }
      
      final manifestFile = File(_manifestPath);
      await backupFile.copy(manifestFile.path);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 获取Web特定的版本配置信息
  Future<Map<String, dynamic>> getWebSpecificInfo() async {
    try {
      final manifestFile = File(_manifestPath);
      if (!manifestFile.existsSync()) {
        return {};
      }
      
      final content = await manifestFile.readAsString();
      final manifest = json.decode(content) as Map<String, dynamic>;
      
      return {
        'name': manifest['name'],
        'short_name': manifest['short_name'],
        'description': manifest['description'],
        'start_url': manifest['start_url'],
        'display': manifest['display'],
        'theme_color': manifest['theme_color'],
        'background_color': manifest['background_color'],
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// 验证Web构建环境
  Future<Map<String, dynamic>> validateBuildEnvironment() async {
    final result = <String, dynamic>{
      'isValid': false,
      'issues': <String>[],
      'recommendations': <String>[],
    };
    
    try {
      // 检查web目录
      final webDir = Directory('web');
      if (!webDir.existsSync()) {
        result['issues'].add('web目录不存在');
        return result;
      }
      
      // 检查关键文件
      final requiredFiles = [
        'web/index.html',
        'web/manifest.json',
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
        result['recommendations'].add('Web构建环境配置正确');
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