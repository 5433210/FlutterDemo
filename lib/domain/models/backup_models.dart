/// 备份位置信息
class BackupLocation {
  final String path;
  final DateTime createdTime;
  final String description;
  final String version;

  BackupLocation({
    required this.path,
    required this.createdTime,
    required this.description,
    this.version = '1.0',
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'created_time': createdTime.toIso8601String(),
        'description': description,
        'version': version,
      };

  factory BackupLocation.fromJson(Map<String, dynamic> json) => BackupLocation(
        path: json['path'] as String,
        createdTime: DateTime.parse(json['created_time'] as String),
        description: json['description'] as String,
        version: json['version'] as String? ?? '1.0',
      );
}

/// 备份条目
class BackupEntry {
  final String id;
  final String filename;
  final String fullPath;
  final int size;
  final DateTime createdTime;
  final String? checksum;
  final String? appVersion;
  final String description;
  final String location; // 'current' or 'legacy'

  BackupEntry({
    required this.id,
    required this.filename,
    required this.fullPath,
    required this.size,
    required this.createdTime,
    this.checksum,
    this.appVersion,
    required this.description,
    required this.location,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': filename,
        'full_path': fullPath,
        'size': size,
        'created_time': createdTime.toIso8601String(),
        'checksum': checksum,
        'app_version': appVersion,
        'description': description,
        'location': location,
      };

  factory BackupEntry.fromJson(Map<String, dynamic> json) => BackupEntry(
        id: json['id'] as String,
        filename: json['filename'] as String,
        fullPath: json['full_path'] as String,
        size: json['size'] as int,
        createdTime: DateTime.parse(json['created_time'] as String),
        checksum: json['checksum'] as String?,
        appVersion: json['app_version'] as String?,
        description: json['description'] as String,
        location: json['location'] as String,
      );
}

/// 备份设置
class BackupSettings {
  final bool autoCleanup;
  final int maxBackups;
  final bool warnOnDelete;

  BackupSettings({
    this.autoCleanup = true,
    this.maxBackups = 20,
    this.warnOnDelete = true,
  });

  Map<String, dynamic> toJson() => {
        'auto_cleanup': autoCleanup,
        'max_backups': maxBackups,
        'warn_on_delete': warnOnDelete,
      };

  factory BackupSettings.fromJson(Map<String, dynamic> json) => BackupSettings(
        autoCleanup: json['auto_cleanup'] as bool? ?? true,
        maxBackups: json['max_backups'] as int? ?? 20,
        warnOnDelete: json['warn_on_delete'] as bool? ?? true,
      );
}

/// 备份统计信息
class BackupStatistics {
  final int totalBackups;
  final int currentLocationBackups;
  final int legacyLocationBackups;
  final int totalSize;
  final DateTime? lastBackupTime;

  BackupStatistics({
    required this.totalBackups,
    required this.currentLocationBackups,
    required this.legacyLocationBackups,
    required this.totalSize,
    this.lastBackupTime,
  });

  Map<String, dynamic> toJson() => {
        'total_backups': totalBackups,
        'current_location_backups': currentLocationBackups,
        'legacy_location_backups': legacyLocationBackups,
        'total_size': totalSize,
        'last_backup_time': lastBackupTime?.toIso8601String(),
      };

  factory BackupStatistics.fromJson(Map<String, dynamic> json) =>
      BackupStatistics(
        totalBackups: json['total_backups'] as int,
        currentLocationBackups: json['current_location_backups'] as int,
        legacyLocationBackups: json['legacy_location_backups'] as int,
        totalSize: json['total_size'] as int,
        lastBackupTime: json['last_backup_time'] != null
            ? DateTime.parse(json['last_backup_time'] as String)
            : null,
      );
}

/// 备份注册表
class BackupRegistry {
  final BackupLocation location;
  final List<BackupEntry> backups;
  final BackupSettings settings;
  final BackupStatistics statistics;

  BackupRegistry({
    required this.location,
    required this.backups,
    BackupSettings? settings,
    BackupStatistics? statistics,
  })  : settings = settings ?? BackupSettings(),
        statistics = statistics ?? _calculateStatistics(backups);

  static BackupStatistics _calculateStatistics(List<BackupEntry> backups) {
    final currentLocationBackups =
        backups.where((b) => b.location == 'current').length;
    final legacyLocationBackups =
        backups.where((b) => b.location == 'legacy').length;
    final totalSize = backups.fold<int>(0, (sum, backup) => sum + backup.size);
    final lastBackupTime = backups.isEmpty
        ? null
        : backups
            .map((b) => b.createdTime)
            .reduce((a, b) => a.isAfter(b) ? a : b);

    return BackupStatistics(
      totalBackups: backups.length,
      currentLocationBackups: currentLocationBackups,
      legacyLocationBackups: legacyLocationBackups,
      totalSize: totalSize,
      lastBackupTime: lastBackupTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'backup_location': location.toJson(),
        'backup_registry': backups.map((b) => b.toJson()).toList(),
        'settings': settings.toJson(),
        'statistics': statistics.toJson(),
      };

  factory BackupRegistry.fromJson(Map<String, dynamic> json) {
    final backups = (json['backup_registry'] as List<dynamic>)
        .map((b) => BackupEntry.fromJson(b as Map<String, dynamic>))
        .toList();

    return BackupRegistry(
      location: BackupLocation.fromJson(
          json['backup_location'] as Map<String, dynamic>),
      backups: backups,
      settings:
          BackupSettings.fromJson(json['settings'] as Map<String, dynamic>),
      statistics:
          BackupStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
    );
  }

  /// 添加备份
  void addBackup(BackupEntry backup) {
    backups.add(backup);
  }

  /// 移除备份
  void removeBackup(String backupId) {
    backups.removeWhere((backup) => backup.id == backupId);
  }

  /// 获取备份
  BackupEntry? getBackup(String backupId) {
    try {
      return backups.firstWhere((backup) => backup.id == backupId);
    } catch (e) {
      return null;
    }
  }

  /// 更新统计信息
  BackupRegistry updateStatistics() {
    return BackupRegistry(
      location: location,
      backups: backups,
      settings: settings,
      statistics: _calculateStatistics(backups),
    );
  }
}

/// 备份选择
enum BackupChoice {
  cancel, // 取消切换
  skipBackup, // 跳过备份，直接切换
  createBackup, // 先创建备份再切换
}

/// 备份建议
class BackupRecommendation {
  final bool needsBackupPath;
  final bool recommendBackup;
  final String reason;

  BackupRecommendation({
    required this.needsBackupPath,
    required this.recommendBackup,
    required this.reason,
  });
}

/// 数据路径切换异常
class DataPathSwitchException implements Exception {
  final String message;
  DataPathSwitchException(this.message);

  @override
  String toString() => 'DataPathSwitchException: $message';
}

/// 旧数据路径信息
class LegacyDataPath {
  final String id;
  final String path;
  final DateTime switchedTime;
  final int sizeEstimate;
  String status; // 'pending_cleanup', 'cleaned', 'ignored'
  final String description;
  DateTime? cleanedTime;

  LegacyDataPath({
    required this.id,
    required this.path,
    required this.switchedTime,
    required this.sizeEstimate,
    required this.status,
    required this.description,
    this.cleanedTime,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'switched_time': switchedTime.toIso8601String(),
        'size_estimate': sizeEstimate,
        'status': status,
        'description': description,
        'cleaned_time': cleanedTime?.toIso8601String(),
      };

  factory LegacyDataPath.fromJson(Map<String, dynamic> json) => LegacyDataPath(
        id: json['id'] as String,
        path: json['path'] as String,
        switchedTime: DateTime.parse(json['switched_time'] as String),
        sizeEstimate: json['size_estimate'] as int,
        status: json['status'] as String,
        description: json['description'] as String,
        cleanedTime: json['cleaned_time'] != null
            ? DateTime.parse(json['cleaned_time'] as String)
            : null,
      );
}

/// 路径切换预览信息
class PathSwitchPreview {
  final String? currentPath;
  final String newPath;
  final List<String> historyPaths;
  final int currentPathBackups;
  final int historyPathBackups;
  final int newPathBackups;
  final int totalBackupsAfterMerge;

  PathSwitchPreview({
    required this.currentPath,
    required this.newPath,
    required this.historyPaths,
    required this.currentPathBackups,
    required this.historyPathBackups,
    required this.newPathBackups,
    required this.totalBackupsAfterMerge,
  });

  /// 是否有备份需要合并
  bool get hasBackupsToMerge =>
      currentPathBackups > 0 || historyPathBackups > 0;

  /// 合并后的备份总数
  int get totalBackupsCount =>
      currentPathBackups + historyPathBackups + newPathBackups;

  /// 需要合并的备份数量
  int get backupsToMerge => currentPathBackups + historyPathBackups;
}
