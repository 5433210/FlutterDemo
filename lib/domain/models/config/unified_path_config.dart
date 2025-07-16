import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// 统一路径配置模型
/// 用于同时管理数据路径和备份路径配置
class UnifiedPathConfig {
  /// 数据路径配置
  final DataPathSection dataPath;

  /// 备份路径配置
  final BackupPathSection backupPath;

  /// 配置更新时间
  final DateTime lastUpdated;

  const UnifiedPathConfig({
    required this.dataPath,
    required this.backupPath,
    required this.lastUpdated,
  });

  /// 创建默认配置
  factory UnifiedPathConfig.defaultConfig() {
    return UnifiedPathConfig(
      dataPath: DataPathSection.defaultConfig(),
      backupPath: BackupPathSection.defaultConfig(),
      lastUpdated: DateTime.now(),
    );
  }

  /// 从 JSON 创建
  factory UnifiedPathConfig.fromJson(Map<String, dynamic> json) {
    return UnifiedPathConfig(
      dataPath: json.containsKey('dataPath')
          ? DataPathSection.fromJson(json['dataPath'])
          : DataPathSection.defaultConfig(),
      backupPath: json.containsKey('backupPath')
          ? BackupPathSection.fromJson(json['backupPath'])
          : BackupPathSection.defaultConfig(),
      lastUpdated: json.containsKey('lastUpdated')
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'dataPath': dataPath.toJson(),
      'backupPath': backupPath.toJson(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// 复制并修改部分属性
  UnifiedPathConfig copyWith({
    DataPathSection? dataPath,
    BackupPathSection? backupPath,
    DateTime? lastUpdated,
  }) {
    return UnifiedPathConfig(
      dataPath: dataPath ?? this.dataPath,
      backupPath: backupPath ?? this.backupPath,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedPathConfig &&
          runtimeType == other.runtimeType &&
          dataPath == other.dataPath &&
          backupPath == other.backupPath &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode =>
      dataPath.hashCode ^ backupPath.hashCode ^ lastUpdated.hashCode;

  @override
  String toString() {
    return 'UnifiedPathConfig(dataPath: $dataPath, backupPath: $backupPath, lastUpdated: $lastUpdated)';
  }
}

/// 数据路径配置部分
class DataPathSection {
  /// 是否使用默认路径
  final bool useDefaultPath;

  /// 自定义数据路径
  final String? customPath;

  /// 历史数据路径列表
  final List<String> historyPaths;

  /// 是否需要重启应用
  final bool requiresRestart;

  const DataPathSection({
    required this.useDefaultPath,
    this.customPath,
    this.historyPaths = const [],
    required this.requiresRestart,
  });

  /// 获取实际使用的数据路径
  Future<String> getActualDataPath() async {
    if (useDefaultPath || customPath == null) {
      final appSupportDir = await getApplicationSupportDirectory();
      return path.join(
          appSupportDir.path, PathConfigConstants.defaultDataSubDirectory);
    }
    return customPath!;
  }

  /// 创建默认配置
  factory DataPathSection.defaultConfig() {
    return const DataPathSection(
      useDefaultPath: true,
      customPath: null,
      historyPaths: [],
      requiresRestart: false,
    );
  }

  /// 创建自定义路径配置
  factory DataPathSection.withCustomPath(String customPath, {List<String>? historyPaths}) {
    return DataPathSection(
      useDefaultPath: false,
      customPath: customPath,
      historyPaths: historyPaths ?? const [],
      requiresRestart: true,
    );
  }

  /// 从 JSON 创建
  factory DataPathSection.fromJson(Map<String, dynamic> json) {
    return DataPathSection(
      useDefaultPath: json['useDefaultPath'] as bool? ?? true,
      customPath: json['customPath'] as String?,
      historyPaths: json.containsKey('historyPaths')
          ? List<String>.from(json['historyPaths'])
          : const [],
      requiresRestart: json['requiresRestart'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'useDefaultPath': useDefaultPath,
      'customPath': customPath,
      'historyPaths': historyPaths,
      'requiresRestart': requiresRestart,
    };
  }

  /// 复制并修改部分属性
  DataPathSection copyWith({
    bool? useDefaultPath,
    String? customPath,
    List<String>? historyPaths,
    bool? requiresRestart,
  }) {
    return DataPathSection(
      useDefaultPath: useDefaultPath ?? this.useDefaultPath,
      customPath: customPath ?? this.customPath,
      historyPaths: historyPaths ?? this.historyPaths,
      requiresRestart: requiresRestart ?? this.requiresRestart,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataPathSection &&
          runtimeType == other.runtimeType &&
          useDefaultPath == other.useDefaultPath &&
          customPath == other.customPath &&
          _listEquals(historyPaths, other.historyPaths) &&
          requiresRestart == other.requiresRestart;

  @override
  int get hashCode =>
      useDefaultPath.hashCode ^
      customPath.hashCode ^
      historyPaths.hashCode ^
      requiresRestart.hashCode;

  @override
  String toString() {
    return 'DataPathSection(useDefaultPath: $useDefaultPath, customPath: $customPath, historyPaths: $historyPaths, requiresRestart: $requiresRestart)';
  }
  
  // 辅助方法：比较两个列表是否相等
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// 备份路径配置部分
class BackupPathSection {
  /// 备份路径
  final String path;

  /// 历史备份路径列表
  final List<String> historyPaths;

  /// 创建时间
  final DateTime createdTime;

  /// 描述
  final String description;

  const BackupPathSection({
    required this.path,
    this.historyPaths = const [],
    required this.createdTime,
    required this.description,
  });

  /// 创建默认配置
  factory BackupPathSection.defaultConfig() {
    return BackupPathSection(
      path: '',  // 空字符串表示未设置，需要在运行时确定默认路径
      historyPaths: const [],
      createdTime: DateTime.now(),
      description: '默认备份位置',
    );
  }

  /// 从 JSON 创建
  factory BackupPathSection.fromJson(Map<String, dynamic> json) {
    return BackupPathSection(
      path: json['path'] as String? ?? '',
      historyPaths: json.containsKey('historyPaths')
          ? List<String>.from(json['historyPaths'])
          : const [],
      createdTime: json.containsKey('createdTime')
          ? DateTime.parse(json['createdTime'])
          : DateTime.now(),
      description: json['description'] as String? ?? '备份位置',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'historyPaths': historyPaths,
      'createdTime': createdTime.toIso8601String(),
      'description': description,
    };
  }

  /// 复制并修改部分属性
  BackupPathSection copyWith({
    String? path,
    List<String>? historyPaths,
    DateTime? createdTime,
    String? description,
  }) {
    return BackupPathSection(
      path: path ?? this.path,
      historyPaths: historyPaths ?? this.historyPaths,
      createdTime: createdTime ?? this.createdTime,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupPathSection &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          _listEquals(historyPaths, other.historyPaths) &&
          createdTime == other.createdTime &&
          description == other.description;

  @override
  int get hashCode =>
      path.hashCode ^
      historyPaths.hashCode ^
      createdTime.hashCode ^
      description.hashCode;

  @override
  String toString() {
    return 'BackupPathSection(path: $path, historyPaths: $historyPaths, createdTime: $createdTime, description: $description)';
  }
  
  // 辅助方法：比较两个列表是否相等
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// 路径配置常量
class PathConfigConstants {
  static const String unifiedPathConfigKey = 'unified_path_config';
  static const String defaultDataSubDirectory = 'charasgem';
  static const String defaultBackupSubDirectory = 'backups';
  static const String registryFileName = 'backup_registry.json';
} 