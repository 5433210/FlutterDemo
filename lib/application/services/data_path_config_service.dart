import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/config/data_path_config.dart';
import '../../infrastructure/logging/logger.dart';
import '../../version_config.dart';
import 'unified_path_config_service.dart';

/// 数据路径配置服务
///
/// 负责管理应用的数据存储路径配置，包括：
/// - 读取和写入配置文件
/// - 路径有效性验证
/// - 版本兼容性检查
/// - 数据迁移协调
class DataPathConfigService {
  static const String _configFileName = 'config.json';
  static const String _dataVersionFileName = 'data_version.json';
  static bool _useUnifiedConfig = true; // 控制是否使用统一配置
  
  // 添加标志位，防止递归读取
  static bool _readingFromUnifiedConfig = false;

  /// 获取默认数据路径（固定路径，用于存放config.json）
  static Future<String> getDefaultDataPath() async {
    final appSupportDir = await getApplicationSupportDirectory();
    return path.join(appSupportDir.path, 'charasgem');
  }

  /// 获取配置文件路径
  static Future<String> getConfigFilePath() async {
    final defaultPath = await getDefaultDataPath();
    return path.join(defaultPath, _configFileName);
  }

  /// 读取数据路径配置
  static Future<DataPathConfig> readConfig() async {
    try {
      if (_useUnifiedConfig && !_readingFromUnifiedConfig) {
        return await _readFromUnifiedConfig();
      } else {
        return await _legacyReadConfig();
      }
    } catch (e, stack) {
      AppLogger.error('读取数据路径配置失败',
          error: e, stackTrace: stack, tag: 'DataPathConfig');
      // 如果统一配置失败，尝试回退到旧配置
      if (_useUnifiedConfig && !_readingFromUnifiedConfig) {
        AppLogger.warning('从统一配置读取失败，回退到旧方法', tag: 'DataPathConfig');
        _useUnifiedConfig = false;
        return await _legacyReadConfig();
      }
      // 发生错误时返回默认配置
      return DataPathConfig.defaultConfig();
    }
  }

  /// 从统一配置读取数据路径配置
  static Future<DataPathConfig> _readFromUnifiedConfig() async {
    // 设置标志位，防止递归调用
    _readingFromUnifiedConfig = true;
    
    try {
      AppLogger.debug('从统一配置读取数据路径配置', tag: 'DataPathConfig');
      final unifiedConfig = await UnifiedPathConfigService.readConfig();
      
      final dataPathConfig = DataPathConfig(
        useDefaultPath: unifiedConfig.dataPath.useDefaultPath,
        customPath: unifiedConfig.dataPath.customPath,
        historyPaths: unifiedConfig.dataPath.historyPaths,
        lastUpdated: unifiedConfig.lastUpdated,
        requiresRestart: unifiedConfig.dataPath.requiresRestart,
      );
      
      AppLogger.debug('从统一配置读取数据路径配置成功', tag: 'DataPathConfig');
      return dataPathConfig;
    } catch (e, stack) {
      AppLogger.error('从统一配置读取数据路径配置失败',
          error: e, stackTrace: stack, tag: 'DataPathConfig');
      rethrow;
    } finally {
      // 重置标志位
      _readingFromUnifiedConfig = false;
    }
  }

  /// 旧的读取配置方法
  static Future<DataPathConfig> _legacyReadConfig() async {
    try {
      final configPath = await getConfigFilePath();
      final configFile = File(configPath);

      if (!await configFile.exists()) {
        AppLogger.debug('配置文件不存在，使用默认配置', tag: 'DataPathConfig');
        return DataPathConfig.defaultConfig();
      }

      final configContent = await configFile.readAsString();
      final configJson = jsonDecode(configContent) as Map<String, dynamic>;

      final config = DataPathConfig.fromJson(configJson);
      final actualPath = await config.getActualDataPath();
      AppLogger.debug('读取数据路径配置成功: $actualPath', tag: 'DataPathConfig');

      return config;
    } catch (e, stack) {
      AppLogger.error('旧方法读取数据路径配置失败',
          error: e, stackTrace: stack, tag: 'DataPathConfig');
      // 发生错误时返回默认配置
      return DataPathConfig.defaultConfig();
    }
  }

  /// 写入数据路径配置
  static Future<void> writeConfig(DataPathConfig config) async {
    try {
      if (_useUnifiedConfig) {
        await _writeToUnifiedConfig(config);
      } else {
        await _legacyWriteConfig(config);
      }
    } catch (e, stack) {
      AppLogger.error('写入数据路径配置失败',
          error: e, stackTrace: stack, tag: 'DataPathConfig');
      // 如果统一配置失败，尝试回退到旧配置
      if (_useUnifiedConfig) {
        AppLogger.warning('写入统一配置失败，回退到旧方法', tag: 'DataPathConfig');
        _useUnifiedConfig = false;
        await _legacyWriteConfig(config);
      } else {
        rethrow;
      }
    }
  }

  /// 写入到统一配置
  static Future<void> _writeToUnifiedConfig(DataPathConfig config) async {
    // 读取当前统一配置
    final unifiedConfig = await UnifiedPathConfigService.readConfig();
    
    // 更新数据路径部分
    final updatedConfig = unifiedConfig.copyWith(
      dataPath: unifiedConfig.dataPath.copyWith(
        useDefaultPath: config.useDefaultPath,
        customPath: config.customPath,
        historyPaths: config.historyPaths,
        requiresRestart: config.requiresRestart,
      ),
      lastUpdated: DateTime.now(),
    );
    
    // 保存更新后的配置
    await UnifiedPathConfigService.writeConfig(updatedConfig);
    
    final actualPath = await config.getActualDataPath();
    AppLogger.info('数据路径配置写入统一配置成功: $actualPath', tag: 'DataPathConfig');
  }

  /// 旧的写入配置方法
  static Future<void> _legacyWriteConfig(DataPathConfig config) async {
    try {
      final configPath = await getConfigFilePath();
      final configFile = File(configPath);

      // 确保目录存在
      await configFile.parent.create(recursive: true);

      final configJson = config.toJson();
      await configFile.writeAsString(
        jsonEncode(configJson),
        mode: FileMode.write,
      );

      final actualPath = await config.getActualDataPath();
      AppLogger.info('数据路径配置写入成功: $actualPath', tag: 'DataPathConfig');
    } catch (e, stack) {
      AppLogger.error('旧方法写入数据路径配置失败',
          error: e, stackTrace: stack, tag: 'DataPathConfig');
      rethrow;
    }
  }

  /// 验证路径是否可用
  static Future<PathValidationResult> validatePath(String pathStr) async {
    try {
      if (pathStr.trim().isEmpty) {
        return PathValidationResult.invalid('路径不能为空');
      }

      final directory = Directory(pathStr);

      // 检查路径是否存在
      if (!await directory.exists()) {
        // 尝试创建目录
        try {
          await directory.create(recursive: true);
        } catch (e) {
          return PathValidationResult.invalid('无法创建目录: $e');
        }
      }

      // 检查读写权限
      final testFile = File(path.join(pathStr, 'test_permission.tmp'));
      try {
        await testFile.writeAsString('test');
        await testFile.delete();
      } catch (e) {
        return PathValidationResult.invalid('目录没有读写权限: $e');
      }

      return PathValidationResult.valid();
    } catch (e) {
      return PathValidationResult.invalid('路径验证失败: $e');
    }
  }

  /// 获取当前应用版本
  static Future<String> getCurrentAppVersion() async {
    try {
      // 从应用的version.json文件读取版本信息
      final versionFile = File('version.json');
      if (await versionFile.exists()) {
        final content = await versionFile.readAsString();
        final versionJson = jsonDecode(content) as Map<String, dynamic>;
        final version = versionJson['version'] as Map<String, dynamic>;
        return '${version['major']}.${version['minor']}.${version['patch']}';
      }
    } catch (e) {
      AppLogger.warning('无法读取应用版本信息', error: e, tag: 'DataPathConfig');
    }

    // 降级抛出异常而不是返回默认版本
    try {
      return VersionConfig.versionInfo.shortVersion;
    } catch (e) {
      AppLogger.error('VersionConfig未初始化', 
          tag: 'DataPathConfig', data: {'error': e.toString()});
      throw StateError('无法获取应用版本，请确保 VersionConfig 已正确初始化: $e');
    }
  }

  /// 检查数据路径的版本兼容性
  static Future<DataCompatibilityResult> checkDataCompatibility(
      String dataPath) async {
    try {
      final versionFile = File(path.join(dataPath, _dataVersionFileName));

      if (!await versionFile.exists()) {
        // 检查是否为新的数据路径（空目录或只有少量非数据文件）
        final directory = Directory(dataPath);
        if (!await directory.exists()) {
          return DataCompatibilityResult.newDataPath();
        }

        final contents = await directory.list().toList();
        final dataFiles = contents.where((entity) {
          final name = path.basename(entity.path);
          return !name.startsWith('.') &&
              name != 'config.json' &&
              name != 'Thumbs.db' &&
              name != 'desktop.ini';
        }).toList();

        if (dataFiles.isEmpty) {
          return DataCompatibilityResult.newDataPath();
        } else {
          return DataCompatibilityResult.unknownState('目录存在但无版本信息文件');
        }
      }

      // 读取数据版本信息
      final content = await versionFile.readAsString();
      final versionJson = jsonDecode(content) as Map<String, dynamic>;
      final dataVersion = versionJson['appVersion'] as String;

      // 获取当前应用版本
      final currentVersion = await getCurrentAppVersion();

      // 进行版本兼容性比较
      final compatibility = _compareVersions(currentVersion, dataVersion);

      AppLogger.debug(
          '版本兼容性检查: 当前=$currentVersion, 数据=$dataVersion, 结果=$compatibility',
          tag: 'DataPathConfig');

      switch (compatibility) {
        case VersionCompatibility.compatible:
          return DataCompatibilityResult.compatible();
        case VersionCompatibility.upgradable:
          return DataCompatibilityResult.upgradable(dataVersion);
        case VersionCompatibility.incompatible:
          return DataCompatibilityResult.incompatible(dataVersion);
        case VersionCompatibility.needsAppUpgrade:
          return DataCompatibilityResult.needsAppUpgrade(dataVersion);
      }
    } catch (e, stack) {
      AppLogger.error('检查数据兼容性失败',
          error: e, stackTrace: stack, tag: 'DataPathConfig');
      return DataCompatibilityResult.unknownState('版本检查失败: $e');
    }
  }

  /// 写入数据版本信息
  static Future<void> writeDataVersion(String dataPath) async {
    try {
      final currentVersion = await getCurrentAppVersion();
      final versionFile = File(path.join(dataPath, _dataVersionFileName));

      // 确保目录存在
      await versionFile.parent.create(recursive: true);

      final versionInfo = {
        'appVersion': currentVersion,
        'lastModified': DateTime.now().toUtc().toIso8601String(),
      };

      await versionFile.writeAsString(
        jsonEncode(versionInfo),
        mode: FileMode.write,
      );

      AppLogger.debug('写入数据版本信息: $currentVersion', tag: 'DataPathConfig');
    } catch (e, stack) {
      AppLogger.error('写入数据版本信息失败',
          error: e, stackTrace: stack, tag: 'DataPathConfig');
      rethrow;
    }
  }

  /// 比较两个版本号的兼容性
  static VersionCompatibility _compareVersions(
      String currentVersion, String dataVersion) {
    try {
      final current = _parseVersion(currentVersion);
      final data = _parseVersion(dataVersion);

      // 主版本不同 -> 不兼容
      if (current.major != data.major) {
        if (current.major > data.major) {
          return VersionCompatibility.incompatible; // 需要迁移工具
        } else {
          return VersionCompatibility.needsAppUpgrade; // 需要升级应用
        }
      }

      // 主版本相同，比较次版本和修订版本
      if (current.minor > data.minor ||
          (current.minor == data.minor && current.patch > data.patch)) {
        return VersionCompatibility.upgradable; // 可升级
      } else if (current.minor == data.minor && current.patch == data.patch) {
        return VersionCompatibility.compatible; // 完全兼容
      } else {
        return VersionCompatibility.needsAppUpgrade; // 数据版本更新，需要升级应用
      }
    } catch (e) {
      AppLogger.error('版本比较失败', error: e, tag: 'DataPathConfig');
      return VersionCompatibility.incompatible; // 出错时返回不兼容
    }
  }

  /// 解析版本号
  static _Version _parseVersion(String version) {
    final parts = version.split('.');
    if (parts.length < 3) {
      throw FormatException('无效的版本号格式: $version');
    }
    return _Version(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
  
  /// 添加历史数据路径
  /// 当切换数据路径时，将旧路径添加到历史记录中
  static Future<void> addHistoryDataPath(String path) async {
    try {
      if (path.trim().isEmpty) {
        return;
      }
      
      if (_useUnifiedConfig) {
        await UnifiedPathConfigService.addHistoryDataPath(path);
      } else {
        final config = await readConfig();
        
        // 检查路径是否已存在于历史记录中
        if (config.historyPaths.contains(path)) {
          return;
        }
        
        // 添加到历史记录
        final updatedConfig = config.copyWith(
          historyPaths: [...config.historyPaths, path],
          lastUpdated: DateTime.now(),
        );
        
        await writeConfig(updatedConfig);
      }
      
      AppLogger.info('添加历史数据路径: $path', tag: 'DataPathConfig');
    } catch (e, stack) {
      AppLogger.error('添加历史数据路径失败',
          error: e, stackTrace: stack, tag: 'DataPathConfig');
    }
  }
  
  /// 获取历史数据路径列表
  static Future<List<String>> getHistoryDataPaths() async {
    try {
      if (_useUnifiedConfig) {
        return await UnifiedPathConfigService.getHistoryDataPaths();
      } else {
        final config = await readConfig();
        return config.historyPaths;
      }
    } catch (e, stack) {
      AppLogger.error('获取历史数据路径失败',
          error: e, stackTrace: stack, tag: 'DataPathConfig');
      return [];
    }
  }
  
  /// 删除历史数据路径
  static Future<bool> removeHistoryDataPath(String path) async {
    try {
      if (_useUnifiedConfig) {
        return await UnifiedPathConfigService.cleanHistoryDataPath(path);
      } else {
        final config = await readConfig();
        
        // 检查路径是否在历史记录中
        if (!config.historyPaths.contains(path)) {
          return false;
        }
        
        // 从历史记录中移除
        final historyPaths = List<String>.from(config.historyPaths)
          ..removeWhere((p) => p == path);
        
        // 更新配置
        final updatedConfig = config.copyWith(
          historyPaths: historyPaths,
          lastUpdated: DateTime.now(),
        );
        
        await writeConfig(updatedConfig);
        
        AppLogger.info('删除历史数据路径: $path', tag: 'DataPathConfig');
        return true;
      }
    } catch (e, stack) {
      AppLogger.error('删除历史数据路径失败',
          error: e, stackTrace: stack, tag: 'DataPathConfig');
      return false;
    }
  }

  /// 清理所有历史数据路径
  static Future<int> clearAllHistoryDataPaths() async {
    try {
      if (_useUnifiedConfig) {
        // 统一配置服务没有直接清理所有历史路径的方法，需要手动实现
        final historyPaths = await UnifiedPathConfigService.getHistoryDataPaths();
        int count = 0;
        
        for (final path in historyPaths) {
          final success = await UnifiedPathConfigService.cleanHistoryDataPath(path);
          if (success) count++;
        }
        
        return count;
      } else {
        final config = await readConfig();
        
        final count = config.historyPaths.length;
        if (count == 0) return 0;
        
        // 更新配置，清空历史记录
        final updatedConfig = config.copyWith(
          historyPaths: [],
          lastUpdated: DateTime.now(),
        );
        
        await writeConfig(updatedConfig);
        
        AppLogger.info('清理所有历史数据路径: $count 个', tag: 'DataPathConfig');
        return count;
      }
    } catch (e, stack) {
      AppLogger.error('清理历史数据路径失败',
          error: e, stackTrace: stack, tag: 'DataPathConfig');
      return 0;
    }
  }
}

/// 版本兼容性
enum VersionCompatibility {
  compatible, // 完全兼容
  upgradable, // 可升级（数据版本较旧）
  incompatible, // 不兼容（需要迁移工具）
  needsAppUpgrade, // 需要升级应用（数据版本较新）
}

/// 版本信息
class _Version {
  final int major;
  final int minor;
  final int patch;

  const _Version(this.major, this.minor, this.patch);
}

/// 路径验证结果
class PathValidationResult {
  final bool isValid;
  final String? errorMessage;

  const PathValidationResult._(this.isValid, this.errorMessage);

  factory PathValidationResult.valid() =>
      const PathValidationResult._(true, null);
  factory PathValidationResult.invalid(String message) =>
      PathValidationResult._(false, message);
}

/// 数据兼容性检查结果
class DataCompatibilityResult {
  final DataCompatibilityStatus status;
  final String? dataVersion;
  final String? message;

  const DataCompatibilityResult._(this.status, this.dataVersion, this.message);

  factory DataCompatibilityResult.compatible() =>
      const DataCompatibilityResult._(
          DataCompatibilityStatus.compatible, null, null);

  factory DataCompatibilityResult.upgradable(String dataVersion) =>
      DataCompatibilityResult._(
          DataCompatibilityStatus.upgradable, dataVersion, null);

  factory DataCompatibilityResult.incompatible(String dataVersion) =>
      DataCompatibilityResult._(
          DataCompatibilityStatus.incompatible, dataVersion, null);

  factory DataCompatibilityResult.needsAppUpgrade(String dataVersion) =>
      DataCompatibilityResult._(
          DataCompatibilityStatus.needsAppUpgrade, dataVersion, null);

  factory DataCompatibilityResult.newDataPath() =>
      const DataCompatibilityResult._(
          DataCompatibilityStatus.newDataPath, null, null);

  factory DataCompatibilityResult.unknownState(String message) =>
      DataCompatibilityResult._(
          DataCompatibilityStatus.unknownState, null, message);
}

/// 数据兼容性状态
enum DataCompatibilityStatus {
  compatible, // 兼容
  upgradable, // 可升级
  incompatible, // 不兼容
  needsAppUpgrade, // 需要升级应用
  newDataPath, // 新数据路径
  unknownState, // 未知状态
}
