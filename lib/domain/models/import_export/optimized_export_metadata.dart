import 'package:freezed_annotation/freezed_annotation.dart';

part 'optimized_export_metadata.freezed.dart';
part 'optimized_export_metadata.g.dart';

/// 优化的导出元数据结构
/// 使用独立的数据版本系统，简化版本管理
@freezed
class OptimizedExportMetadata with _$OptimizedExportMetadata {
  const OptimizedExportMetadata._();

  const factory OptimizedExportMetadata({
    /// 数据版本（独立于应用版本）
    required String dataVersion,
    
    /// 导出时间
    required DateTime exportTime,
    
    /// 导出平台
    @Default('flutter') String platform,
    
    /// 应用版本（用于参考）
    required String appVersion,
    
    /// 导出类型
    required OptimizedExportType exportType,
    
    /// 导出选项
    required OptimizedExportOptions options,
    
    /// 数据统计
    required OptimizedExportStatistics statistics,
    
    /// 文件清单
    required List<OptimizedFileInfo> files,
    
    /// 校验信息
    required OptimizedChecksumInfo checksums,
    
    /// 扩展信息（用于未来扩展）
    @Default({}) Map<String, dynamic> extensions,
  }) = _OptimizedExportMetadata;

  factory OptimizedExportMetadata.fromJson(Map<String, dynamic> json) =>
      _$OptimizedExportMetadataFromJson(json);

  /// 获取兼容性信息
  OptimizedCompatibilityInfo get compatibilityInfo {
    return OptimizedCompatibilityInfo(
      dataVersion: dataVersion,
      minRequiredAppVersion: _getMinRequiredAppVersion(),
      recommendedAppVersion: _getRecommendedAppVersion(),
      isBackwardCompatible: _isBackwardCompatible(),
    );
  }

  /// 获取文件总大小
  int get totalFileSize {
    return files.fold(0, (sum, file) => sum + file.fileSize);
  }

  /// 获取压缩率
  double get compressionRatio {
    if (statistics.originalSize == 0) return 0.0;
    return 1.0 - (statistics.compressedSize / statistics.originalSize);
  }

  /// 验证元数据完整性
  bool get isValid {
    return dataVersion.isNotEmpty &&
           appVersion.isNotEmpty &&
           files.isNotEmpty &&
           checksums.isValid;
  }

  String _getMinRequiredAppVersion() {
    switch (dataVersion) {
      case 'ie_v1':
        return '1.0.0';
      case 'ie_v2':
        return '1.1.0';
      case 'ie_v3':
        return '1.2.0';
      case 'ie_v4':
        return '1.3.0';
      default:
        return '1.0.0';
    }
  }

  String _getRecommendedAppVersion() {
    switch (dataVersion) {
      case 'ie_v1':
        return '1.1.0';
      case 'ie_v2':
        return '1.2.0';
      case 'ie_v3':
        return '1.3.0';
      case 'ie_v4':
        return '1.3.0';
      default:
        return '1.3.0';
    }
  }

  bool _isBackwardCompatible() {
    // ie_v4 向后兼容所有版本
    // ie_v3 向后兼容 ie_v1, ie_v2
    // ie_v2 向后兼容 ie_v1
    // ie_v1 不向后兼容
    switch (dataVersion) {
      case 'ie_v4':
      case 'ie_v3':
      case 'ie_v2':
        return true;
      case 'ie_v1':
        return false;
      default:
        return false;
    }
  }
}

/// 优化的导出类型
@freezed
class OptimizedExportType with _$OptimizedExportType {
  const factory OptimizedExportType({
    /// 主要类型
    required String primary,
    
    /// 子类型
    String? secondary,
    
    /// 包含的数据类型
    required List<String> includedDataTypes,
    
    /// 是否包含关联数据
    @Default(false) bool includeRelatedData,
  }) = _OptimizedExportType;

  factory OptimizedExportType.fromJson(Map<String, dynamic> json) =>
      _$OptimizedExportTypeFromJson(json);
}

/// 优化的导出选项
@freezed
class OptimizedExportOptions with _$OptimizedExportOptions {
  const factory OptimizedExportOptions({
    /// 压缩级别 (0-9)
    @Default(6) int compressionLevel,
    
    /// 是否包含图片
    @Default(true) bool includeImages,
    
    /// 是否包含元数据
    @Default(true) bool includeMetadata,
    
    /// 是否生成缩略图
    @Default(false) bool generateThumbnails,
    
    /// 图片质量 (0-100)
    @Default(85) int imageQuality,
    
    /// 最大图片尺寸
    int? maxImageSize,
    
    /// 自定义选项
    @Default({}) Map<String, dynamic> customOptions,
  }) = _OptimizedExportOptions;

  factory OptimizedExportOptions.fromJson(Map<String, dynamic> json) =>
      _$OptimizedExportOptionsFromJson(json);
}

/// 优化的导出统计
@freezed
class OptimizedExportStatistics with _$OptimizedExportStatistics {
  const OptimizedExportStatistics._();

  const factory OptimizedExportStatistics({
    /// 作品数量
    @Default(0) int workCount,
    
    /// 集字数量
    @Default(0) int characterCount,
    
    /// 图片数量
    @Default(0) int imageCount,
    
    /// 文件数量
    @Default(0) int fileCount,
    
    /// 原始大小（字节）
    @Default(0) int originalSize,
    
    /// 压缩后大小（字节）
    @Default(0) int compressedSize,
    
    /// 处理时间（毫秒）
    @Default(0) int processingTimeMs,
    
    /// 扩展统计
    @Default({}) Map<String, int> extendedStats,
  }) = _OptimizedExportStatistics;

  factory OptimizedExportStatistics.fromJson(Map<String, dynamic> json) =>
      _$OptimizedExportStatisticsFromJson(json);

  /// 获取总项目数
  int get totalItems => workCount + characterCount;

  /// 获取压缩率
  double get compressionRatio {
    if (originalSize == 0) return 0.0;
    return 1.0 - (compressedSize / originalSize);
  }

  /// 获取处理速度（项目/秒）
  double get processingSpeed {
    if (processingTimeMs == 0) return 0.0;
    return (totalItems * 1000.0) / processingTimeMs;
  }
}

/// 优化的文件信息
@freezed
class OptimizedFileInfo with _$OptimizedFileInfo {
  const factory OptimizedFileInfo({
    /// 文件名
    required String fileName,
    
    /// 文件路径（在压缩包内）
    required String filePath,
    
    /// 文件类型
    required String fileType,
    
    /// 文件大小（字节）
    required int fileSize,
    
    /// 文件校验和
    required String checksum,
    
    /// MIME类型
    String? mimeType,
    
    /// 创建时间
    DateTime? createdAt,
    
    /// 修改时间
    DateTime? modifiedAt,
    
    /// 扩展属性
    @Default({}) Map<String, dynamic> attributes,
  }) = _OptimizedFileInfo;

  factory OptimizedFileInfo.fromJson(Map<String, dynamic> json) =>
      _$OptimizedFileInfoFromJson(json);
}

/// 优化的校验信息
@freezed
class OptimizedChecksumInfo with _$OptimizedChecksumInfo {
  const OptimizedChecksumInfo._();

  const factory OptimizedChecksumInfo({
    /// 整体校验和
    required String overall,
    
    /// 数据校验和
    required String dataChecksum,
    
    /// 文件校验和
    required String filesChecksum,
    
    /// 校验算法
    @Default('sha256') String algorithm,
    
    /// 校验时间
    required DateTime checksumTime,
  }) = _OptimizedChecksumInfo;

  factory OptimizedChecksumInfo.fromJson(Map<String, dynamic> json) =>
      _$OptimizedChecksumInfoFromJson(json);

  /// 验证校验信息是否有效
  bool get isValid {
    return overall.isNotEmpty &&
           dataChecksum.isNotEmpty &&
           filesChecksum.isNotEmpty &&
           algorithm.isNotEmpty;
  }
}

/// 优化的兼容性信息
@freezed
class OptimizedCompatibilityInfo with _$OptimizedCompatibilityInfo {
  const factory OptimizedCompatibilityInfo({
    /// 数据版本
    required String dataVersion,
    
    /// 最低要求应用版本
    required String minRequiredAppVersion,
    
    /// 推荐应用版本
    required String recommendedAppVersion,
    
    /// 是否向后兼容
    required bool isBackwardCompatible,
    
    /// 兼容性说明
    String? compatibilityNotes,
  }) = _OptimizedCompatibilityInfo;

  factory OptimizedCompatibilityInfo.fromJson(Map<String, dynamic> json) =>
      _$OptimizedCompatibilityInfoFromJson(json);
}
