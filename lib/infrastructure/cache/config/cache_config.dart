/// 缓存配置类
/// 
/// 定义缓存系统的各种配置参数
class CacheConfig {
  /// 内存图像缓存容量
  final int memoryImageCacheCapacity;
  
  /// 内存数据缓存容量
  final int memoryDataCacheCapacity;
  
  /// 磁盘缓存最大大小（字节）
  final int maxDiskCacheSize;
  
  /// 磁盘缓存项最大存活时间
  final Duration diskCacheTtl;
  
  /// 是否启用自动清理
  final bool autoCleanupEnabled;
  
  /// 自动清理间隔
  final Duration autoCleanupInterval;
  
  /// 构造函数
  const CacheConfig({
    this.memoryImageCacheCapacity = 100,
    this.memoryDataCacheCapacity = 50,
    this.maxDiskCacheSize = 100 * 1024 * 1024, // 100MB
    this.diskCacheTtl = const Duration(days: 7),
    this.autoCleanupEnabled = true,
    this.autoCleanupInterval = const Duration(hours: 24),
  });
  
  /// 从JSON创建配置
  factory CacheConfig.fromJson(Map<String, dynamic> json) {
    return CacheConfig(
      memoryImageCacheCapacity: json['memoryImageCacheCapacity'] ?? 100,
      memoryDataCacheCapacity: json['memoryDataCacheCapacity'] ?? 50,
      maxDiskCacheSize: json['maxDiskCacheSize'] ?? 100 * 1024 * 1024,
      diskCacheTtl: Duration(days: json['diskCacheTtlDays'] ?? 7),
      autoCleanupEnabled: json['autoCleanupEnabled'] ?? true,
      autoCleanupInterval: Duration(hours: json['autoCleanupIntervalHours'] ?? 24),
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'memoryImageCacheCapacity': memoryImageCacheCapacity,
      'memoryDataCacheCapacity': memoryDataCacheCapacity,
      'maxDiskCacheSize': maxDiskCacheSize,
      'diskCacheTtlDays': diskCacheTtl.inDays,
      'autoCleanupEnabled': autoCleanupEnabled,
      'autoCleanupIntervalHours': autoCleanupInterval.inHours,
    };
  }
  
  /// 创建新的配置实例
  CacheConfig copyWith({
    int? memoryImageCacheCapacity,
    int? memoryDataCacheCapacity,
    int? maxDiskCacheSize,
    Duration? diskCacheTtl,
    bool? autoCleanupEnabled,
    Duration? autoCleanupInterval,
  }) {
    return CacheConfig(
      memoryImageCacheCapacity: memoryImageCacheCapacity ?? this.memoryImageCacheCapacity,
      memoryDataCacheCapacity: memoryDataCacheCapacity ?? this.memoryDataCacheCapacity,
      maxDiskCacheSize: maxDiskCacheSize ?? this.maxDiskCacheSize,
      diskCacheTtl: diskCacheTtl ?? this.diskCacheTtl,
      autoCleanupEnabled: autoCleanupEnabled ?? this.autoCleanupEnabled,
      autoCleanupInterval: autoCleanupInterval ?? this.autoCleanupInterval,
    );
  }
}
