import 'dart:convert';
import 'dart:io';

import 'check_logger.dart';

/// 预检查缓存
class PreTestCheckCache {
  final Map<String, dynamic> results;
  final DateTime timestamp;

  const PreTestCheckCache({
    required this.results,
    required this.timestamp,
  });

  factory PreTestCheckCache.fromJson(Map<String, dynamic> json) {
    return PreTestCheckCache(
      results: json['results'] as Map<String, dynamic>? ?? {},
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// 检查缓存是否有效
  bool isValid([Duration? maxAge]) {
    maxAge ??= const Duration(hours: 1);
    final age = DateTime.now().difference(timestamp);
    return age <= maxAge;
  }

  /// 保存缓存
  Future<void> save([String? path]) async {
    path ??= 'test/config/pre_test_check.cache';
    final file = File(path);

    final dir = file.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    await file.writeAsString(jsonEncode(toJson()));
  }

  Map<String, dynamic> toJson() => {
        'results': results,
        'timestamp': timestamp.toIso8601String(),
      };

  /// 加载缓存（兼容方法）
  static Future<PreTestCheckCache?> load([String? path]) => read(path);

  /// 读取缓存
  static Future<PreTestCheckCache?> read([String? path]) async {
    path ??= 'test/config/pre_test_check.cache';
    final file = File(path);

    if (!file.existsSync()) {
      return null;
    }

    try {
      final json = jsonDecode(await file.readAsString());
      return PreTestCheckCache.fromJson(json);
    } catch (e) {
      CheckLogger.instance.error('Failed to read cache: $path', e);
      return null;
    }
  }
}

/// 预检查配置
class PreTestCheckConfig {
  /// 默认设置
  static const _defaultSettings = {
    'timeoutSeconds': 30,
    'requiredDiskSpaceMB': 100,
    'backupIntervalHours': 24,
    'enableCache': true,
    'retries': 3,
    'parallel': true,
  };
  final List<PreTestCheckItem> items;

  final Map<String, dynamic> settings;

  const PreTestCheckConfig({
    this.items = const [],
    this.settings = _defaultSettings,
  });

  factory PreTestCheckConfig.fromJson(Map<String, dynamic> json) {
    return PreTestCheckConfig(
      items: (json['items'] as List?)
              ?.map((e) => PreTestCheckItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      settings: Map<String, dynamic>.from(
          json['settings'] as Map? ?? _defaultSettings),
    );
  }
  int get backupIntervalHours =>
      settings['backupIntervalHours'] as int? ??
      _defaultSettings['backupIntervalHours'] as int;
  bool get enableCache =>
      settings['enableCache'] as bool? ??
      _defaultSettings['enableCache'] as bool;
  bool get parallel =>
      settings['parallel'] as bool? ?? _defaultSettings['parallel'] as bool;
  int get requiredDiskSpaceMB =>
      settings['requiredDiskSpaceMB'] as int? ??
      _defaultSettings['requiredDiskSpaceMB'] as int;
  int get retries =>
      settings['retries'] as int? ?? _defaultSettings['retries'] as int;

  /// 访问器
  int get timeoutSeconds =>
      settings['timeoutSeconds'] as int? ??
      _defaultSettings['timeoutSeconds'] as int;

  Map<String, dynamic> toJson() => {
        'items': items.map((item) => item.toJson()).toList(),
        'settings': settings,
      };

  /// 加载配置
  static Future<PreTestCheckConfig> load([String? path]) async {
    path ??= 'test/config/pre_test_check.json';
    final file = File(path);

    if (!file.existsSync()) {
      return _createDefaultConfig();
    }

    try {
      final json = jsonDecode(await file.readAsString());
      return PreTestCheckConfig.fromJson(json);
    } catch (e) {
      CheckLogger.instance.error('Failed to load config: $path', e);
      return _createDefaultConfig();
    }
  }

  /// 创建默认配置
  static PreTestCheckConfig _createDefaultConfig() {
    return PreTestCheckConfig(
      items: [
        const PreTestCheckItem(
          name: 'system',
          description: '系统检查',
          required: true,
        ),
        const PreTestCheckItem(
          name: 'data',
          description: '数据检查',
          required: true,
        ),
      ],
      settings: Map<String, dynamic>.from(_defaultSettings),
    );
  }
}

/// 预检查配置项
class PreTestCheckItem {
  final String name;
  final String description;
  final bool required;
  final Duration timeout;

  const PreTestCheckItem({
    required this.name,
    required this.description,
    this.required = true,
    this.timeout = const Duration(seconds: 30),
  });

  factory PreTestCheckItem.fromJson(Map<String, dynamic> json) {
    return PreTestCheckItem(
      name: json['name'] as String,
      description: json['description'] as String,
      required: json['required'] as bool? ?? true,
      timeout: Duration(seconds: json['timeout'] as int? ?? 30),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'required': required,
        'timeout': timeout.inSeconds,
      };
}
