/// 版本兼容性检查服务
library version_compatibility_service;

import 'dart:convert';
import 'dart:io';

import '../../../domain/models/compatibility/version_compatibility.dart';

/// 版本兼容性检查服务
class VersionCompatibilityService {
  static const String _compatibilityConfigPath = 'compatibility_config.json';

  /// 单例实例
  static final VersionCompatibilityService _instance =
      VersionCompatibilityService._internal();
  factory VersionCompatibilityService() => _instance;
  VersionCompatibilityService._internal();

  /// 兼容性配置缓存
  final Map<String, VersionCompatibilityInfo> _compatibilityCache = {};

  /// 是否已加载配置
  bool _isConfigLoaded = false;

  /// 加载兼容性配置
  Future<void> loadCompatibilityConfig() async {
    if (_isConfigLoaded) return;

    try {
      final configFile = File(_compatibilityConfigPath);
      if (!configFile.existsSync()) {
        await _createDefaultConfig();
      }

      final content = await configFile.readAsString();
      final configData = json.decode(content) as Map<String, dynamic>;

      final compatibilityList =
          configData['compatibility'] as List<dynamic>? ?? [];

      _compatibilityCache.clear();
      for (final item in compatibilityList) {
        final info =
            VersionCompatibilityInfo.fromMap(item as Map<String, dynamic>);
        _compatibilityCache[info.version] = info;
      }

      _isConfigLoaded = true;
    } catch (e) {
      throw Exception('加载兼容性配置失败: $e');
    }
  }

  /// 检查版本兼容性
  Future<CompatibilityReport> checkVersionCompatibility(
    String sourceVersion,
    String targetVersion,
  ) async {
    await loadCompatibilityConfig();

    final sourceInfo = _compatibilityCache[sourceVersion];
    if (sourceInfo == null) {
      return _createUnknownCompatibilityReport(sourceVersion, targetVersion);
    }

    return sourceInfo.getCompatibilityReport(targetVersion);
  }

  /// 创建默认配置
  Future<void> _createDefaultConfig() async {
    final defaultConfig = {
      'version': '1.0.0',
      'description': '版本兼容性配置文件',
      'compatibility': [
        {
          'version': '1.0.0',
          'minCompatibleVersion': '1.0.0',
          'maxCompatibleVersion': null,
          'apiCompatibility': 'full',
          'dataCompatibility': 'full',
          'description': '初始版本',
          'incompatibleFeatures': [],
          'migrationSteps': [],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      ],
    };

    final configFile = File(_compatibilityConfigPath);
    await configFile.writeAsString(json.encode(defaultConfig));
  }

  /// 创建未知兼容性报告
  CompatibilityReport _createUnknownCompatibilityReport(
    String sourceVersion,
    String targetVersion,
  ) {
    return CompatibilityReport(
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
      isCompatible: false,
      apiCompatibility: CompatibilityLevel.unknown,
      dataCompatibility: CompatibilityLevel.unknown,
      description: '未找到版本 $sourceVersion 的兼容性信息',
    );
  }
}
