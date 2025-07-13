/// 备份配置类
/// 允许用户自定义备份行为和限制
class BackupConfig {
  /// 最大文件大小限制 (MB)
  final int maxFileSizeMB;

  /// 是否跳过缓存目录
  final bool skipCache;

  /// 是否跳过临时文件
  final bool skipTemp;

  /// 最大备份时间限制 (分钟)
  final int maxBackupTimeMinutes;

  /// 是否启用详细日志
  final bool enableVerboseLogging;

  /// 文件数量警告阈值
  final int fileCountWarningThreshold;

  const BackupConfig({
    this.maxFileSizeMB = 500,
    this.skipCache = true,
    this.skipTemp = true,
    this.maxBackupTimeMinutes = 15,
    this.enableVerboseLogging = false,
    this.fileCountWarningThreshold = 5000,
  });

  /// 默认配置
  static const BackupConfig defaultConfig = BackupConfig();

  /// 快速备份配置（跳过大文件）
  static const BackupConfig quickConfig = BackupConfig(
    maxFileSizeMB: 100,
    maxBackupTimeMinutes: 5,
  );

  /// 完整备份配置（包含所有文件）
  static const BackupConfig fullConfig = BackupConfig(
    maxFileSizeMB: 2048, // 2GB
    maxBackupTimeMinutes: 30,
    enableVerboseLogging: true,
  );

  /// 从JSON创建配置
  factory BackupConfig.fromJson(Map<String, dynamic> json) {
    return BackupConfig(
      maxFileSizeMB: json['maxFileSizeMB'] ?? 500,
      skipCache: json['skipCache'] ?? true,
      skipTemp: json['skipTemp'] ?? true,
      maxBackupTimeMinutes: json['maxBackupTimeMinutes'] ?? 15,
      enableVerboseLogging: json['enableVerboseLogging'] ?? false,
      fileCountWarningThreshold: json['fileCountWarningThreshold'] ?? 5000,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'maxFileSizeMB': maxFileSizeMB,
      'skipCache': skipCache,
      'skipTemp': skipTemp,
      'maxBackupTimeMinutes': maxBackupTimeMinutes,
      'enableVerboseLogging': enableVerboseLogging,
      'fileCountWarningThreshold': fileCountWarningThreshold,
    };
  }

  /// 复制并修改配置
  BackupConfig copyWith({
    int? maxFileSizeMB,
    bool? skipCache,
    bool? skipTemp,
    int? maxBackupTimeMinutes,
    bool? enableVerboseLogging,
    int? fileCountWarningThreshold,
  }) {
    return BackupConfig(
      maxFileSizeMB: maxFileSizeMB ?? this.maxFileSizeMB,
      skipCache: skipCache ?? this.skipCache,
      skipTemp: skipTemp ?? this.skipTemp,
      maxBackupTimeMinutes: maxBackupTimeMinutes ?? this.maxBackupTimeMinutes,
      enableVerboseLogging: enableVerboseLogging ?? this.enableVerboseLogging,
      fileCountWarningThreshold:
          fileCountWarningThreshold ?? this.fileCountWarningThreshold,
    );
  }

  /// 获取排除的目录列表
  List<String> getExcludedDirectories() {
    final excluded = <String>[];
    if (skipCache) excluded.add('cache');
    if (skipTemp) excluded.add('temp');
    return excluded;
  }

  /// 检查文件是否应该被跳过
  bool shouldSkipFile(int fileSizeBytes) {
    final fileSizeMB = fileSizeBytes / (1024 * 1024);
    return fileSizeMB > maxFileSizeMB;
  }

  @override
  String toString() {
    return 'BackupConfig('
        'maxFileSizeMB: $maxFileSizeMB, '
        'skipCache: $skipCache, '
        'skipTemp: $skipTemp, '
        'maxBackupTimeMinutes: $maxBackupTimeMinutes, '
        'enableVerboseLogging: $enableVerboseLogging, '
        'fileCountWarningThreshold: $fileCountWarningThreshold'
        ')';
  }
}
