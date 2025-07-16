import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// 数据路径配置模型
class DataPathConfig {
  /// 是否使用默认路径
  final bool useDefaultPath;

  /// 自定义数据路径
  final String? customPath;

  /// 历史数据路径列表
  final List<String> historyPaths;

  /// 配置更新时间
  final DateTime lastUpdated;

  /// 是否需要重启应用
  final bool requiresRestart;

  const DataPathConfig({
    required this.useDefaultPath,
    this.customPath,
    this.historyPaths = const [],
    required this.lastUpdated,
    required this.requiresRestart,
  });

  /// 获取实际使用的数据路径
  Future<String> getActualDataPath() async {
    if (useDefaultPath || customPath == null) {
      final appSupportDir = await getApplicationSupportDirectory();
      return path.join(
          appSupportDir.path, DataPathConstants.defaultSubDirectory);
    }
    return customPath!;
  }

  /// 创建默认配置
  factory DataPathConfig.defaultConfig() {
    return DataPathConfig(
      useDefaultPath: true,
      customPath: null,
      historyPaths: const [],
      lastUpdated: DateTime.now(),
      requiresRestart: false,
    );
  }

  /// 创建自定义路径配置
  factory DataPathConfig.withCustomPath(String customPath, {List<String>? historyPaths}) {
    return DataPathConfig(
      useDefaultPath: false,
      customPath: customPath,
      historyPaths: historyPaths ?? const [],
      lastUpdated: DateTime.now(),
      requiresRestart: true,
    );
  }

  /// 从 JSON 创建
  factory DataPathConfig.fromJson(Map<String, dynamic> json) {
    return DataPathConfig(
      useDefaultPath: json['useDefaultPath'] as bool? ?? true,
      customPath: json['customPath'] as String?,
      historyPaths: json.containsKey('historyPaths')
          ? List<String>.from(json['historyPaths'])
          : const [],
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      requiresRestart: json['requiresRestart'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'useDefaultPath': useDefaultPath,
      'customPath': customPath,
      'historyPaths': historyPaths,
      'lastUpdated': lastUpdated.toIso8601String(),
      'requiresRestart': requiresRestart,
    };
  }

  /// 复制并修改部分属性
  DataPathConfig copyWith({
    bool? useDefaultPath,
    String? customPath,
    List<String>? historyPaths,
    DateTime? lastUpdated,
    bool? requiresRestart,
  }) {
    return DataPathConfig(
      useDefaultPath: useDefaultPath ?? this.useDefaultPath,
      customPath: customPath ?? this.customPath,
      historyPaths: historyPaths ?? this.historyPaths,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      requiresRestart: requiresRestart ?? this.requiresRestart,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataPathConfig &&
          runtimeType == other.runtimeType &&
          useDefaultPath == other.useDefaultPath &&
          customPath == other.customPath &&
          _listEquals(historyPaths, other.historyPaths) &&
          lastUpdated == other.lastUpdated &&
          requiresRestart == other.requiresRestart;

  @override
  int get hashCode =>
      useDefaultPath.hashCode ^
      customPath.hashCode ^
      historyPaths.hashCode ^
      lastUpdated.hashCode ^
      requiresRestart.hashCode;

  @override
  String toString() {
    return 'DataPathConfig(useDefaultPath: $useDefaultPath, customPath: $customPath, historyPaths: $historyPaths, lastUpdated: $lastUpdated, requiresRestart: $requiresRestart)';
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

/// 数据路径配置常量
class DataPathConstants {
  static const String configFileName = 'config.json';
  static const String dataPathKey = 'dataPath';
  static const String defaultSubDirectory = 'charasgem';

  /// 获取默认数据路径的相对路径名
  static String get defaultDirectoryName => defaultSubDirectory;
}
