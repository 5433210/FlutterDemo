/// Windows平台版本管理器
library windows_version_manager;

import 'dart:io';

import 'platform_version_manager.dart';

/// Windows平台版本管理器实现
class WindowsVersionManager extends PlatformVersionManager {
  static const String _runnerRcPath = 'windows/runner/Runner.rc';
  static const String _backupSuffix = '.version_backup';
  
  @override
  String get platformId => 'windows';
  
  @override
  String get platformDisplayName => 'Windows';
  
  @override
  Future<PlatformVersionInfo> getCurrentVersion() async {
    try {
      final runnerRcFile = File(_runnerRcPath);
      if (!runnerRcFile.existsSync()) {
        throw Exception('Windows Runner.rc 文件不存在: $_runnerRcPath');
      }
      
      final content = await runnerRcFile.readAsString();
      final fileVersion = _extractFileVersion(content);
      final productVersion = _extractProductVersion(content);
      
      return PlatformVersionInfo(
        versionName: _formatVersionString(fileVersion),
        versionCode: fileVersion,
        platformId: platformId,
        platformDisplayName: platformDisplayName,
        additionalProperties: {
          'configPath': _runnerRcPath,
          'extractedAt': DateTime.now().toIso8601String(),
          'FileVersion': fileVersion,
          'ProductVersion': productVersion,
        },
      );
    } catch (e) {
      throw Exception('获取Windows版本信息失败: $e');
    }
  }
  
  @override
  Future<bool> updateVersion(String versionName, String versionCode) async {
    try {
      final runnerRcFile = File(_runnerRcPath);
      if (!runnerRcFile.existsSync()) {
        throw Exception('Windows Runner.rc 文件不存在');
      }
      
      // 备份当前配置
      await backupConfig();
      
      final content = await runnerRcFile.readAsString();
      final windowsVersionCode = _formatWindowsVersion(versionName, versionCode);
      final updatedContent = _updateVersionInContent(content, versionName, windowsVersionCode);
      
      await runnerRcFile.writeAsString(updatedContent);
      
      // 验证更新是否成功
      final updatedVersion = await getCurrentVersion();
      final success = updatedVersion.versionName == versionName;
      
      if (!success) {
        await restoreConfig();
        throw Exception('版本更新验证失败');
      }
      
      return true;
    } catch (e) {
      await restoreConfig();
      throw Exception('更新Windows版本失败: $e');
    }
  }
  
  @override
  bool validateVersionFormat(String versionName, String versionCode) {
    // Windows版本格式验证
    final versionPattern = RegExp(r'^\d+\.\d+\.\d+$');
    return versionPattern.hasMatch(versionName);
  }
  
  @override
  List<String> getConfigFilePaths() {
    return [_runnerRcPath];
  }
  
  @override
  Future<bool> backupConfig() async {
    try {
      final runnerRcFile = File(_runnerRcPath);
      if (!runnerRcFile.existsSync()) {
        return false;
      }
      
      final backupFile = File('$_runnerRcPath$_backupSuffix');
      await runnerRcFile.copy(backupFile.path);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> restoreConfig() async {
    try {
      final backupFile = File('$_runnerRcPath$_backupSuffix');
      if (!backupFile.existsSync()) {
        return false;
      }
      
      final runnerRcFile = File(_runnerRcPath);
      await backupFile.copy(runnerRcFile.path);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 从Runner.rc内容中提取FileVersion
  String _extractFileVersion(String content) {
    // 匹配 FILEVERSION 1,0,0,123
    final pattern = RegExp(r'FILEVERSION\s+(\d+),(\d+),(\d+),(\d+)');
    final match = pattern.firstMatch(content);
    
    if (match != null) {
      return '${match.group(1)}.${match.group(2)}.${match.group(3)}.${match.group(4)}';
    }
    
    throw Exception('无法在Runner.rc中找到FILEVERSION');
  }
  
  /// 从Runner.rc内容中提取ProductVersion
  String _extractProductVersion(String content) {
    // 匹配 PRODUCTVERSION 1,0,0,123
    final pattern = RegExp(r'PRODUCTVERSION\s+(\d+),(\d+),(\d+),(\d+)');
    final match = pattern.firstMatch(content);
    
    if (match != null) {
      return '${match.group(1)}.${match.group(2)}.${match.group(3)}.${match.group(4)}';
    }
    
    throw Exception('无法在Runner.rc中找到PRODUCTVERSION');
  }
  
  /// 格式化版本字符串 (1.0.0.123 -> 1.0.0)
  String _formatVersionString(String windowsVersion) {
    final parts = windowsVersion.split('.');
    if (parts.length >= 3) {
      return '${parts[0]}.${parts[1]}.${parts[2]}';
    }
    return windowsVersion;
  }
  
  /// 格式化Windows版本 (1.0.0 + 123 -> 1.0.0.123)
  String _formatWindowsVersion(String versionName, String buildNumber) {
    return '$versionName.$buildNumber';
  }
  
  /// 更新Runner.rc内容中的版本信息
  String _updateVersionInContent(String content, String versionName, String windowsVersion) {
    final parts = windowsVersion.split('.');
    if (parts.length != 4) {
      throw Exception('Windows版本格式错误: $windowsVersion');
    }
    
    final versionCommas = '${parts[0]},${parts[1]},${parts[2]},${parts[3]}';
    final versionDots = windowsVersion;
    
    // 更新FILEVERSION
    content = content.replaceFirst(
      RegExp(r'FILEVERSION\s+\d+,\d+,\d+,\d+'),
      'FILEVERSION $versionCommas',
    );
    
    // 更新PRODUCTVERSION
    content = content.replaceFirst(
      RegExp(r'PRODUCTVERSION\s+\d+,\d+,\d+,\d+'),
      'PRODUCTVERSION $versionCommas',
    );
    
    // 更新字符串表中的版本信息
    content = content.replaceFirst(
      RegExp(r'VALUE "FileVersion", "[^"]+"'),
      'VALUE "FileVersion", "$versionDots"',
    );
    
    content = content.replaceFirst(
      RegExp(r'VALUE "ProductVersion", "[^"]+"'),
      'VALUE "ProductVersion", "$versionDots"',
    );
    
    return content;
  }
  
  /// 获取Windows特定的版本配置信息
  Future<Map<String, dynamic>> getWindowsSpecificInfo() async {
    try {
      final runnerRcFile = File(_runnerRcPath);
      if (!runnerRcFile.existsSync()) {
        return {};
      }
      
      final content = await runnerRcFile.readAsString();
      final info = <String, dynamic>{};
      
      // 提取产品名称
      final productNameMatch = RegExp(r'VALUE "ProductName", "([^"]+)"').firstMatch(content);
      if (productNameMatch != null) {
        info['productName'] = productNameMatch.group(1);
      }
      
      // 提取公司名称
      final companyNameMatch = RegExp(r'VALUE "CompanyName", "([^"]+)"').firstMatch(content);
      if (companyNameMatch != null) {
        info['companyName'] = companyNameMatch.group(1);
      }
      
      // 提取版权信息
      final copyrightMatch = RegExp(r'VALUE "LegalCopyright", "([^"]+)"').firstMatch(content);
      if (copyrightMatch != null) {
        info['copyright'] = copyrightMatch.group(1);
      }
      
      return info;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// 验证Windows构建环境
  Future<Map<String, dynamic>> validateBuildEnvironment() async {
    final result = <String, dynamic>{
      'isValid': false,
      'issues': <String>[],
      'recommendations': <String>[],
    };
    
    try {
      // 检查Runner.rc文件
      final runnerRcFile = File(_runnerRcPath);
      if (!runnerRcFile.existsSync()) {
        result['issues'].add('Runner.rc文件不存在');
        return result;
      }
      
      // 检查Windows目录结构
      final windowsDir = Directory('windows');
      if (!windowsDir.existsSync()) {
        result['issues'].add('windows目录不存在');
        return result;
      }
      
      // 检查关键文件
      final requiredFiles = [
        'windows/CMakeLists.txt',
        'windows/runner/main.cpp',
        'windows/runner/CMakeLists.txt',
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
        result['recommendations'].add('Windows构建环境配置正确');
      } else {
        result['recommendations'].add('请修复上述问题后重新检查');
        result['recommendations'].add('确保已安装Visual Studio和Windows SDK');
      }
      
      return result;
    } catch (e) {
      result['issues'].add('环境验证失败: $e');
      return result;
    }
  }
} 