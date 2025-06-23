/// Linux平台版本管理器
library linux_version_manager;

import 'dart:io';

import 'platform_version_manager.dart';

/// Linux平台版本管理器实现
class LinuxVersionManager extends PlatformVersionManager {
  static const String _cmakeListsPath = 'linux/CMakeLists.txt';
  static const String _backupSuffix = '.version_backup';
  
  @override
  String get platformId => 'linux';
  
  @override
  String get platformDisplayName => 'Linux';
  
  @override
  Future<PlatformVersionInfo> getCurrentVersion() async {
    try {
      final cmakeFile = File(_cmakeListsPath);
      if (!cmakeFile.existsSync()) {
        throw Exception('Linux CMakeLists.txt 文件不存在: $_cmakeListsPath');
      }
      
      final content = await cmakeFile.readAsString();
      final versionString = _extractAppVersionString(content);
      
      // 从版本字符串中分离版本名称和构建号
      final parts = versionString.split('-');
      final versionName = parts.isNotEmpty ? parts[0] : versionString;
      final versionCode = parts.length > 1 ? parts[1] : versionString;
      
      return PlatformVersionInfo(
        versionName: versionName,
        versionCode: versionCode,
        platformId: platformId,
        platformDisplayName: platformDisplayName,
        additionalProperties: {
          'configPath': _cmakeListsPath,
          'extractedAt': DateTime.now().toIso8601String(),
          'APP_VERSION_STRING': versionString,
        },
      );
    } catch (e) {
      throw Exception('获取Linux版本信息失败: $e');
    }
  }
  
  @override
  Future<bool> updateVersion(String versionName, String versionCode) async {
    try {
      final cmakeFile = File(_cmakeListsPath);
      if (!cmakeFile.existsSync()) {
        throw Exception('Linux CMakeLists.txt 文件不存在');
      }
      
      // 备份当前配置
      await backupConfig();
      
      final content = await cmakeFile.readAsString();
      final versionString = '$versionName-$versionCode';
      final updatedContent = _updateVersionInContent(content, versionString);
      
      await cmakeFile.writeAsString(updatedContent);
      
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
      throw Exception('更新Linux版本失败: $e');
    }
  }
  
  @override
  bool validateVersionFormat(String versionName, String versionCode) {
    // Linux版本格式验证
    final versionPattern = RegExp(r'^\d+\.\d+\.\d+$');
    return versionPattern.hasMatch(versionName);
  }
  
  @override
  List<String> getConfigFilePaths() {
    return [_cmakeListsPath];
  }
  
  @override
  Future<bool> backupConfig() async {
    try {
      final cmakeFile = File(_cmakeListsPath);
      if (!cmakeFile.existsSync()) {
        return false;
      }
      
      final backupFile = File('$_cmakeListsPath$_backupSuffix');
      await cmakeFile.copy(backupFile.path);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> restoreConfig() async {
    try {
      final backupFile = File('$_cmakeListsPath$_backupSuffix');
      if (!backupFile.existsSync()) {
        return false;
      }
      
      final cmakeFile = File(_cmakeListsPath);
      await backupFile.copy(cmakeFile.path);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 从CMakeLists.txt内容中提取APP_VERSION_STRING
  String _extractAppVersionString(String content) {
    // 匹配 set(APP_VERSION_STRING "1.0.0-123")
    final patterns = [
      RegExp(r'set\s*\(\s*APP_VERSION_STRING\s+"([^"]+)"\s*\)', multiLine: true),
      RegExp(r'APP_VERSION_STRING\s+"([^"]+)"', multiLine: true),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        return match.group(1)!;
      }
    }
    
    throw Exception('无法在CMakeLists.txt中找到APP_VERSION_STRING');
  }
  
  /// 更新CMakeLists.txt内容中的版本信息
  String _updateVersionInContent(String content, String versionString) {
    // 更新 set(APP_VERSION_STRING "version")
    final patterns = [
      RegExp(r'(set\s*\(\s*APP_VERSION_STRING\s+)"[^"]+"(\s*\))', multiLine: true),
      RegExp(r'(APP_VERSION_STRING\s+)"[^"]+"', multiLine: true),
    ];
    
    for (final pattern in patterns) {
      if (pattern.hasMatch(content)) {
        final match = pattern.firstMatch(content)!;
        if (match.groupCount >= 2) {
          content = content.replaceFirst(pattern, '${match.group(1)}"$versionString"${match.group(2)}');
        } else {
          content = content.replaceFirst(pattern, '${match.group(1)}"$versionString"');
        }
        break;
      }
    }
    
    return content;
  }
  
  /// 获取Linux特定的版本配置信息
  Future<Map<String, dynamic>> getLinuxSpecificInfo() async {
    try {
      final cmakeFile = File(_cmakeListsPath);
      if (!cmakeFile.existsSync()) {
        return {};
      }
      
      final content = await cmakeFile.readAsString();
      final info = <String, dynamic>{};
      
      // 提取项目名称
      final projectNameMatch = RegExp(r'project\s*\(\s*([^\s)]+)', multiLine: true).firstMatch(content);
      if (projectNameMatch != null) {
        info['projectName'] = projectNameMatch.group(1);
      }
      
      // 提取CMAKE版本要求
      final cmakeVersionMatch = RegExp(r'cmake_minimum_required\s*\(\s*VERSION\s+([^)]+)\)', multiLine: true).firstMatch(content);
      if (cmakeVersionMatch != null) {
        info['cmakeMinimumVersion'] = cmakeVersionMatch.group(1);
      }
      
      // 提取C++标准
      final cppStandardMatch = RegExp(r'set\s*\(\s*CMAKE_CXX_STANDARD\s+(\d+)\s*\)', multiLine: true).firstMatch(content);
      if (cppStandardMatch != null) {
        info['cxxStandard'] = int.parse(cppStandardMatch.group(1)!);
      }
      
      return info;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// 验证Linux构建环境
  Future<Map<String, dynamic>> validateBuildEnvironment() async {
    final result = <String, dynamic>{
      'isValid': false,
      'issues': <String>[],
      'recommendations': <String>[],
    };
    
    try {
      // 检查CMakeLists.txt文件
      final cmakeFile = File(_cmakeListsPath);
      if (!cmakeFile.existsSync()) {
        result['issues'].add('CMakeLists.txt文件不存在');
        return result;
      }
      
      // 检查Linux目录结构
      final linuxDir = Directory('linux');
      if (!linuxDir.existsSync()) {
        result['issues'].add('linux目录不存在');
        return result;
      }
      
      // 检查关键文件
      final requiredFiles = [
        'linux/flutter/CMakeLists.txt',
        'linux/runner/main.cc',
        'linux/runner/CMakeLists.txt',
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
        result['recommendations'].add('Linux构建环境配置正确');
      } else {
        result['recommendations'].add('请修复上述问题后重新检查');
        result['recommendations'].add('确保已安装CMake、GTK开发库和C++编译器');
      }
      
      return result;
    } catch (e) {
      result['issues'].add('环境验证失败: $e');
      return result;
    }
  }
} 