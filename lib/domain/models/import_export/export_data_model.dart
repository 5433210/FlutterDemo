import 'package:freezed_annotation/freezed_annotation.dart';

import '../work/work_entity.dart';
import '../work/work_image.dart';
import '../character/character_entity.dart';

part 'export_data_model.freezed.dart';
part 'export_data_model.g.dart';

/// 导出数据模型
@freezed
class ExportDataModel with _$ExportDataModel {
  const factory ExportDataModel({
    /// 导出元数据
    required ExportMetadata metadata,
    
    /// 作品数据列表
    @Default([]) List<WorkEntity> works,
    
    /// 作品图片数据列表
    @Default([]) List<WorkImage> workImages,
    
    /// 集字数据列表
    @Default([]) List<CharacterEntity> characters,
    
    /// 导出清单
    required ExportManifest manifest,
  }) = _ExportDataModel;

  factory ExportDataModel.fromJson(Map<String, dynamic> json) =>
      _$ExportDataModelFromJson(json);
}

/// 导出元数据
@freezed
class ExportMetadata with _$ExportMetadata {
  const factory ExportMetadata({
    /// 导出版本
    @Default('1.0.0') String version,
    
    /// 导出时间
    required DateTime exportTime,
    
    /// 导出类型
    required ExportType exportType,
    
    /// 导出选项
    required ExportOptions options,
    
    /// 应用版本
    required String appVersion,
    
    /// 平台信息
    required String platform,
    
    /// 数据格式版本
    @Default('1.0.0') String dataFormatVersion,
    
    /// 兼容性信息
    required CompatibilityInfo compatibility,
  }) = _ExportMetadata;

  factory ExportMetadata.fromJson(Map<String, dynamic> json) =>
      _$ExportMetadataFromJson(json);
}

/// 导出清单
@freezed
class ExportManifest with _$ExportManifest {
  const factory ExportManifest({
    /// 汇总信息
    required ExportSummary summary,
    
    /// 文件列表
    required List<ExportFileInfo> files,
    
    /// 数据统计
    required ExportStatistics statistics,
    
    /// 验证信息
    required List<ExportValidation> validations,
  }) = _ExportManifest;

  factory ExportManifest.fromJson(Map<String, dynamic> json) =>
      _$ExportManifestFromJson(json);
}

/// 导出汇总信息
@freezed
class ExportSummary with _$ExportSummary {
  const factory ExportSummary({
    /// 作品总数
    @Default(0) int workCount,
    
    /// 集字总数
    @Default(0) int characterCount,
    
    /// 图片文件总数
    @Default(0) int imageCount,
    
    /// 数据文件总数
    @Default(0) int dataFileCount,
    
    /// 压缩包大小（字节）
    @Default(0) int totalSize,
    
    /// 原始数据大小（字节）
    @Default(0) int originalSize,
    
    /// 压缩率
    @Default(0.0) double compressionRatio,
  }) = _ExportSummary;

  factory ExportSummary.fromJson(Map<String, dynamic> json) =>
      _$ExportSummaryFromJson(json);
}

/// 导出文件信息
@freezed
class ExportFileInfo with _$ExportFileInfo {
  const factory ExportFileInfo({
    /// 文件名
    required String fileName,
    
    /// 文件路径（在压缩包中）
    required String filePath,
    
    /// 文件类型
    required ExportFileType fileType,
    
    /// 文件大小（字节）
    required int fileSize,
    
    /// 文件校验和
    required String checksum,
    
    /// 校验算法
    @Default('MD5') String checksumAlgorithm,
    
    /// 是否必需文件
    @Default(true) bool isRequired,
    
    /// 文件描述
    String? description,
  }) = _ExportFileInfo;

  factory ExportFileInfo.fromJson(Map<String, dynamic> json) =>
      _$ExportFileInfoFromJson(json);
}

/// 导出统计信息
@freezed
class ExportStatistics with _$ExportStatistics {
  const factory ExportStatistics({
    /// 按风格分组的作品数量
    @Default({}) Map<String, int> worksByStyle,
    
    /// 按工具分组的作品数量
    @Default({}) Map<String, int> worksByTool,
    
    /// 按日期分组的作品数量
    @Default({}) Map<String, int> worksByDate,
    
    /// 按字符分组的集字数量
    @Default({}) Map<String, int> charactersByChar,
    
    /// 文件格式统计
    @Default({}) Map<String, int> filesByFormat,
    
    /// 自定义配置统计
    required CustomConfigStatistics customConfigs,
  }) = _ExportStatistics;

  factory ExportStatistics.fromJson(Map<String, dynamic> json) =>
      _$ExportStatisticsFromJson(json);
}

/// 自定义配置统计
@freezed
class CustomConfigStatistics with _$CustomConfigStatistics {
  const factory CustomConfigStatistics({
    /// 自定义书法风格列表
    @Default([]) List<String> customStyles,
    
    /// 自定义书写工具列表
    @Default([]) List<String> customTools,
    
    /// 自定义风格使用次数
    @Default({}) Map<String, int> customStyleUsage,
    
    /// 自定义工具使用次数
    @Default({}) Map<String, int> customToolUsage,
  }) = _CustomConfigStatistics;

  factory CustomConfigStatistics.fromJson(Map<String, dynamic> json) =>
      _$CustomConfigStatisticsFromJson(json);
}

/// 导出验证信息
@freezed
class ExportValidation with _$ExportValidation {
  const factory ExportValidation({
    /// 验证类型
    required ExportValidationType type,
    
    /// 验证状态
    required ValidationStatus status,
    
    /// 验证消息
    required String message,
    
    /// 验证详情
    Map<String, dynamic>? details,
    
    /// 验证时间
    required DateTime timestamp,
  }) = _ExportValidation;

  factory ExportValidation.fromJson(Map<String, dynamic> json) =>
      _$ExportValidationFromJson(json);
}

/// 兼容性信息
@freezed
class CompatibilityInfo with _$CompatibilityInfo {
  const factory CompatibilityInfo({
    /// 最低支持版本
    required String minSupportedVersion,
    
    /// 推荐版本
    required String recommendedVersion,
    
    /// 兼容性标记
    @Default([]) List<String> compatibilityFlags,
    
    /// 向下兼容性
    @Default(true) bool backwardCompatible,
    
    /// 向前兼容性
    @Default(false) bool forwardCompatible,
  }) = _CompatibilityInfo;

  factory CompatibilityInfo.fromJson(Map<String, dynamic> json) =>
      _$CompatibilityInfoFromJson(json);
}

/// 导出选项
@freezed
class ExportOptions with _$ExportOptions {
  const factory ExportOptions({
    /// 导出类型
    required ExportType type,
    
    /// 导出格式
    required ExportFormat format,
    
    /// 是否包含图片文件
    @Default(true) bool includeImages,
    
    /// 是否包含元数据
    @Default(true) bool includeMetadata,
    
    /// 是否压缩数据
    @Default(true) bool compressData,
    
    /// 版本信息
    @Default('1.0') String version,
    
    /// 是否包含关联数据
    @Default(true) bool includeRelatedData,
    
    /// 压缩级别 (0-9)
    @Default(6) int compressionLevel,
    
    /// 是否生成缩略图
    @Default(true) bool generateThumbnails,
    
    /// 文件名前缀
    String? fileNamePrefix,
    
    /// 自定义选项
    @Default({}) Map<String, dynamic> customOptions,
  }) = _ExportOptions;

  factory ExportOptions.fromJson(Map<String, dynamic> json) =>
      _$ExportOptionsFromJson(json);
}

/// 导出类型枚举
enum ExportType {
  /// 仅作品
  worksOnly,
  /// 作品和关联集字
  worksWithCharacters,
  /// 仅集字
  charactersOnly,
  /// 集字和来源作品
  charactersWithWorks,
  /// 完整数据
  fullData,
}

/// 导出文件类型枚举
enum ExportFileType {
  /// 数据文件
  data,
  /// 图片文件
  image,
  /// 缩略图
  thumbnail,
  /// 元数据文件
  metadata,
  /// 清单文件
  manifest,
  /// 配置文件
  config,
}

/// 导出验证类型枚举
enum ExportValidationType {
  /// 数据完整性
  dataIntegrity,
  /// 文件完整性
  fileIntegrity,
  /// 关联关系
  relationships,
  /// 格式验证
  format,
  /// 大小限制
  sizeLimit,
}

/// 验证状态枚举
enum ValidationStatus {
  /// 通过
  passed,
  /// 警告
  warning,
  /// 失败
  failed,
  /// 跳过
  skipped,
}

/// 导出格式枚举
enum ExportFormat {
  /// JSON 文件
  json,
  /// ZIP 压缩包
  zip,
  /// 备份文件
  backup,
} 