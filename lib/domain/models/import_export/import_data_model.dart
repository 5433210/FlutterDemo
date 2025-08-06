import 'package:freezed_annotation/freezed_annotation.dart';

import 'export_data_model.dart';

part 'import_data_model.freezed.dart';
part 'import_data_model.g.dart';

/// 导入数据模型
@freezed
class ImportDataModel with _$ImportDataModel {
  const factory ImportDataModel({
    /// 解析的导出数据
    required ExportDataModel exportData,

    /// 验证结果
    required ImportValidationResult validation,

    /// 冲突信息
    @Default([]) List<ImportConflictInfo> conflicts,

    /// 导入选项
    required ImportOptions options,

    /// 导入状态
    @Default(ImportStatus.pending) ImportStatus status,
  }) = _ImportDataModel;

  factory ImportDataModel.fromJson(Map<String, dynamic> json) =>
      _$ImportDataModelFromJson(json);
}

/// 导入验证结果
@freezed
class ImportValidationResult with _$ImportValidationResult {
  const factory ImportValidationResult({
    /// 验证状态
    required ValidationStatus status,

    /// 是否通过验证
    @Default(false) bool isValid,

    /// 验证消息列表
    @Default([]) List<ValidationMessage> messages,

    /// 数据统计
    required ImportDataStatistics statistics,

    /// 兼容性检查结果
    required CompatibilityCheckResult compatibility,

    /// 文件完整性检查结果
    required FileIntegrityResult fileIntegrity,

    /// 数据完整性检查结果
    required DataIntegrityResult dataIntegrity,
  }) = _ImportValidationResult;

  factory ImportValidationResult.fromJson(Map<String, dynamic> json) =>
      _$ImportValidationResultFromJson(json);
}

/// 验证消息
@freezed
class ValidationMessage with _$ValidationMessage {
  const factory ValidationMessage({
    /// 消息级别
    required ValidationLevel level,

    /// 消息类型
    required ValidationType type,

    /// 消息内容
    required String message,

    /// 详细信息
    Map<String, dynamic>? details,

    /// 建议的操作
    String? suggestedAction,

    /// 是否可以自动修复
    @Default(false) bool canAutoFix,
  }) = _ValidationMessage;

  factory ValidationMessage.fromJson(Map<String, dynamic> json) =>
      _$ValidationMessageFromJson(json);
}

/// 导入冲突信息
@freezed
class ImportConflictInfo with _$ImportConflictInfo {
  const factory ImportConflictInfo({
    /// 冲突类型
    required ConflictType type,

    /// 冲突的实体类型
    required EntityType entityType,

    /// 冲突的实体ID
    required String entityId,

    /// 现有数据
    required Map<String, dynamic> existingData,

    /// 导入数据
    required Map<String, dynamic> importData,

    /// 冲突字段列表
    @Default([]) List<String> conflictFields,

    /// 解决策略
    ConflictResolution? resolution,

    /// 冲突描述
    required String description,
  }) = _ImportConflictInfo;

  factory ImportConflictInfo.fromJson(Map<String, dynamic> json) =>
      _$ImportConflictInfoFromJson(json);
}

/// 导入数据统计
@freezed
class ImportDataStatistics with _$ImportDataStatistics {
  const factory ImportDataStatistics({
    /// 作品总数
    @Default(0) int totalWorks,

    /// 集字总数
    @Default(0) int totalCharacters,

    /// 图片总数
    @Default(0) int totalImages,

    /// 有效作品数
    @Default(0) int validWorks,

    /// 有效集字数
    @Default(0) int validCharacters,

    /// 有效图片数
    @Default(0) int validImages,

    /// 冲突作品数
    @Default(0) int conflictWorks,

    /// 冲突集字数
    @Default(0) int conflictCharacters,

    /// 损坏文件数
    @Default(0) int corruptedFiles,

    /// 缺失文件数
    @Default(0) int missingFiles,

    /// 预计导入时间（秒）
    @Default(0) int estimatedImportTime,

    /// 预计存储空间（字节）
    @Default(0) int estimatedStorageSize,
  }) = _ImportDataStatistics;

  factory ImportDataStatistics.fromJson(Map<String, dynamic> json) =>
      _$ImportDataStatisticsFromJson(json);
}

/// 兼容性检查结果
@freezed
class CompatibilityCheckResult with _$CompatibilityCheckResult {
  const factory CompatibilityCheckResult({
    /// 是否兼容
    @Default(false) bool isCompatible,

    /// 数据格式版本
    required String dataFormatVersion,

    /// 应用版本
    required String appVersion,

    /// 兼容性级别
    required CompatibilityLevel level,

    /// 不兼容的功能列表
    @Default([]) List<String> incompatibleFeatures,

    /// 警告信息
    @Default([]) List<String> warnings,

    /// 是否需要数据迁移
    @Default(false) bool requiresMigration,
  }) = _CompatibilityCheckResult;

  factory CompatibilityCheckResult.fromJson(Map<String, dynamic> json) =>
      _$CompatibilityCheckResultFromJson(json);
}

/// 文件完整性检查结果
@freezed
class FileIntegrityResult with _$FileIntegrityResult {
  const factory FileIntegrityResult({
    /// 是否完整
    @Default(false) bool isIntact,

    /// 总文件数
    @Default(0) int totalFiles,

    /// 有效文件数
    @Default(0) int validFiles,

    /// 损坏文件列表
    @Default([]) List<CorruptedFileInfo> corruptedFiles,

    /// 缺失文件列表
    @Default([]) List<MissingFileInfo> missingFiles,

    /// 校验和验证结果
    @Default([]) List<ChecksumValidation> checksumResults,
  }) = _FileIntegrityResult;

  factory FileIntegrityResult.fromJson(Map<String, dynamic> json) =>
      _$FileIntegrityResultFromJson(json);
}

/// 数据完整性检查结果
@freezed
class DataIntegrityResult with _$DataIntegrityResult {
  const factory DataIntegrityResult({
    /// 是否完整
    @Default(false) bool isIntact,

    /// 关联关系检查结果
    @Default([]) List<RelationshipValidation> relationships,

    /// 数据格式验证结果
    @Default([]) List<FormatValidation> formats,

    /// 必需字段验证结果
    @Default([]) List<RequiredFieldValidation> requiredFields,

    /// 数据一致性检查结果
    @Default([]) List<ConsistencyValidation> consistency,
  }) = _DataIntegrityResult;

  factory DataIntegrityResult.fromJson(Map<String, dynamic> json) =>
      _$DataIntegrityResultFromJson(json);
}

/// 损坏文件信息
@freezed
class CorruptedFileInfo with _$CorruptedFileInfo {
  const factory CorruptedFileInfo({
    /// 文件路径
    required String filePath,

    /// 文件类型
    required ExportFileType fileType,

    /// 损坏类型
    required CorruptionType corruptionType,

    /// 错误描述
    required String errorDescription,

    /// 是否可以修复
    @Default(false) bool canRecover,

    /// 修复建议
    String? recoverySuggestion,
  }) = _CorruptedFileInfo;

  factory CorruptedFileInfo.fromJson(Map<String, dynamic> json) =>
      _$CorruptedFileInfoFromJson(json);
}

/// 缺失文件信息
@freezed
class MissingFileInfo with _$MissingFileInfo {
  const factory MissingFileInfo({
    /// 文件路径
    required String filePath,

    /// 文件类型
    required ExportFileType fileType,

    /// 是否必需
    @Default(true) bool isRequired,

    /// 影响的实体
    @Default([]) List<String> affectedEntities,

    /// 替代方案
    String? alternative,
  }) = _MissingFileInfo;

  factory MissingFileInfo.fromJson(Map<String, dynamic> json) =>
      _$MissingFileInfoFromJson(json);
}

/// 校验和验证
@freezed
class ChecksumValidation with _$ChecksumValidation {
  const factory ChecksumValidation({
    /// 文件路径
    required String filePath,

    /// 预期校验和
    required String expectedChecksum,

    /// 实际校验和
    required String actualChecksum,

    /// 是否匹配
    @Default(false) bool isValid,

    /// 校验算法
    @Default('MD5') String algorithm,
  }) = _ChecksumValidation;

  factory ChecksumValidation.fromJson(Map<String, dynamic> json) =>
      _$ChecksumValidationFromJson(json);
}

/// 关联关系验证
@freezed
class RelationshipValidation with _$RelationshipValidation {
  const factory RelationshipValidation({
    /// 关联类型
    required RelationshipType type,

    /// 父实体ID
    required String parentId,

    /// 子实体ID
    required String childId,

    /// 是否有效
    @Default(false) bool isValid,

    /// 错误描述
    String? errorDescription,
  }) = _RelationshipValidation;

  factory RelationshipValidation.fromJson(Map<String, dynamic> json) =>
      _$RelationshipValidationFromJson(json);
}

/// 格式验证
@freezed
class FormatValidation with _$FormatValidation {
  const factory FormatValidation({
    /// 实体类型
    required EntityType entityType,

    /// 实体ID
    required String entityId,

    /// 字段名
    required String fieldName,

    /// 是否有效
    @Default(false) bool isValid,

    /// 错误描述
    String? errorDescription,

    /// 建议值
    String? suggestedValue,
  }) = _FormatValidation;

  factory FormatValidation.fromJson(Map<String, dynamic> json) =>
      _$FormatValidationFromJson(json);
}

/// 必需字段验证
@freezed
class RequiredFieldValidation with _$RequiredFieldValidation {
  const factory RequiredFieldValidation({
    /// 实体类型
    required EntityType entityType,

    /// 实体ID
    required String entityId,

    /// 缺失字段列表
    @Default([]) List<String> missingFields,

    /// 是否有效
    @Default(false) bool isValid,
  }) = _RequiredFieldValidation;

  factory RequiredFieldValidation.fromJson(Map<String, dynamic> json) =>
      _$RequiredFieldValidationFromJson(json);
}

/// 一致性验证
@freezed
class ConsistencyValidation with _$ConsistencyValidation {
  const factory ConsistencyValidation({
    /// 一致性类型
    required ConsistencyType type,

    /// 相关实体
    @Default([]) List<String> entities,

    /// 是否一致
    @Default(false) bool isConsistent,

    /// 不一致描述
    String? inconsistencyDescription,

    /// 修复建议
    String? fixSuggestion,
  }) = _ConsistencyValidation;

  factory ConsistencyValidation.fromJson(Map<String, dynamic> json) =>
      _$ConsistencyValidationFromJson(json);
}

/// 导入选项
@freezed
class ImportOptions with _$ImportOptions {
  const factory ImportOptions({
    /// 冲突解决策略
    @Default(ConflictResolution.ask)
    ConflictResolution defaultConflictResolution,

    /// 是否覆盖现有数据
    @Default(false) bool overwriteExisting,

    /// 是否跳过损坏的文件
    @Default(true) bool skipCorruptedFiles,

    /// 是否创建备份
    @Default(true) bool createBackup,

    /// 是否验证文件完整性
    @Default(true) bool validateFileIntegrity,

    /// 是否自动修复可修复的错误
    @Default(true) bool autoFixErrors,

    /// 导入目标目录
    String? targetDirectory,

    /// 自定义选项
    @Default({}) Map<String, dynamic> customOptions,
  }) = _ImportOptions;

  factory ImportOptions.fromJson(Map<String, dynamic> json) =>
      _$ImportOptionsFromJson(json);
}

/// 导入状态枚举
enum ImportStatus {
  /// 等待中
  pending,

  /// 验证中
  validating,

  /// 等待用户确认
  awaitingConfirmation,

  /// 导入中
  importing,

  /// 完成
  completed,

  /// 失败
  failed,

  /// 已取消
  cancelled,
}

/// 验证级别枚举
enum ValidationLevel {
  /// 信息
  info,

  /// 警告
  warning,

  /// 错误
  error,

  /// 致命错误
  fatal,
}

/// 验证类型枚举
enum ValidationType {
  /// 格式验证
  format,

  /// 完整性验证
  integrity,

  /// 兼容性验证
  compatibility,

  /// 关联关系验证
  relationship,

  /// 业务规则验证
  businessRule,
}

/// 冲突类型枚举
enum ConflictType {
  /// ID冲突
  idConflict,

  /// 数据冲突
  dataConflict,

  /// 文件冲突
  fileConflict,

  /// 版本冲突
  versionConflict,
}

/// 实体类型枚举
enum EntityType {
  /// 作品
  work,

  /// 作品图片
  workImage,

  /// 集字
  character,

  /// 配置
  config,
}

/// 冲突解决策略枚举
enum ConflictResolution {
  /// 询问用户
  ask,

  /// 跳过
  skip,

  /// 覆盖
  overwrite,

  /// 保留现有
  keepExisting,

  /// 重命名
  rename,

  /// 合并
  merge,
}

/// 兼容性级别枚举
enum CompatibilityLevel {
  /// 完全兼容
  fullCompatible,

  /// 部分兼容
  partialCompatible,

  /// 不兼容但可导入
  incompatibleButImportable,

  /// 完全不兼容
  incompatible,
}

/// 损坏类型枚举
enum CorruptionType {
  /// 文件不存在
  fileNotFound,

  /// 文件损坏
  fileCorrupted,

  /// 格式错误
  formatError,

  /// 校验和不匹配
  checksumMismatch,

  /// 权限错误
  permissionError,
}

/// 关联关系类型枚举
enum RelationshipType {
  /// 作品-图片关联
  workImage,

  /// 作品-集字关联
  workCharacter,

  /// 图片-文件关联
  imageFile,
}

/// 一致性类型枚举
enum ConsistencyType {
  /// 数据一致性
  dataConsistency,

  /// 引用一致性
  referenceConsistency,

  /// 业务逻辑一致性
  businessLogicConsistency,
}
