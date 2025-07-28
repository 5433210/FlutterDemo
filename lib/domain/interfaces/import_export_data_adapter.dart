import 'package:freezed_annotation/freezed_annotation.dart';

part 'import_export_data_adapter.freezed.dart';
part 'import_export_data_adapter.g.dart';

/// 导入导出数据适配器接口
abstract class ImportExportDataAdapter {
  /// 源数据版本
  String get sourceDataVersion;

  /// 目标数据版本
  String get targetDataVersion;

  /// 适配器名称
  String get adapterName => '$sourceDataVersion->$targetDataVersion';

  /// 预处理：数据格式转换
  Future<ImportExportAdapterResult> preProcess(String exportFilePath);

  /// 后处理：数据完整性验证
  Future<ImportExportAdapterResult> postProcess(String importedDataPath);

  /// 验证：确认升级成功
  Future<bool> validate(String dataPath);

  /// 获取适配器描述
  String getDescription() => '数据格式适配器：$sourceDataVersion → $targetDataVersion';

  /// 检查是否支持指定的版本转换
  bool supportsConversion(String fromVersion, String toVersion) {
    return sourceDataVersion == fromVersion && targetDataVersion == toVersion;
  }
}

/// 导入导出适配器结果
@freezed
class ImportExportAdapterResult with _$ImportExportAdapterResult {
  const factory ImportExportAdapterResult({
    /// 操作是否成功
    required bool success,

    /// 结果消息
    required String message,

    /// 输出文件路径（成功时）
    String? outputPath,

    /// 错误代码（失败时）
    String? errorCode,

    /// 错误详情（失败时）
    Map<String, dynamic>? errorDetails,

    /// 处理统计信息
    ImportExportAdapterStatistics? statistics,

    /// 处理时间戳
    @Default(null) DateTime? timestamp,

    /// 额外数据
    @Default({}) Map<String, dynamic> metadata,
  }) = _ImportExportAdapterResult;

  factory ImportExportAdapterResult.fromJson(Map<String, dynamic> json) =>
      _$ImportExportAdapterResultFromJson(json);

  /// 创建成功结果
  factory ImportExportAdapterResult.success({
    required String message,
    String? outputPath,
    ImportExportAdapterStatistics? statistics,
    Map<String, dynamic>? metadata,
  }) {
    return ImportExportAdapterResult(
      success: true,
      message: message,
      outputPath: outputPath,
      statistics: statistics,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  /// 创建失败结果
  factory ImportExportAdapterResult.failure({
    required String message,
    String? errorCode,
    Map<String, dynamic>? errorDetails,
    Map<String, dynamic>? metadata,
  }) {
    return ImportExportAdapterResult(
      success: false,
      message: message,
      errorCode: errorCode,
      errorDetails: errorDetails,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
  }
}

/// 导入导出适配器统计信息
@freezed
class ImportExportAdapterStatistics with _$ImportExportAdapterStatistics {
  const ImportExportAdapterStatistics._();

  const factory ImportExportAdapterStatistics({
    /// 处理开始时间
    required DateTime startTime,

    /// 处理结束时间
    required DateTime endTime,

    /// 处理耗时（毫秒）
    required int durationMs,

    /// 处理的文件数量
    @Default(0) int processedFiles,

    /// 转换的数据记录数量
    @Default(0) int convertedRecords,

    /// 原始数据大小（字节）
    @Default(0) int originalSizeBytes,

    /// 转换后数据大小（字节）
    @Default(0) int convertedSizeBytes,

    /// 跳过的记录数量
    @Default(0) int skippedRecords,

    /// 错误记录数量
    @Default(0) int errorRecords,

    /// 详细统计信息
    @Default({}) Map<String, dynamic> details,
  }) = _ImportExportAdapterStatistics;

  factory ImportExportAdapterStatistics.fromJson(Map<String, dynamic> json) =>
      _$ImportExportAdapterStatisticsFromJson(json);

  /// 计算处理速度（记录/秒）
  double get recordsPerSecond {
    if (durationMs == 0) return 0.0;
    return convertedRecords / (durationMs / 1000.0);
  }

  /// 计算数据压缩率
  double get compressionRatio {
    if (originalSizeBytes == 0) return 0.0;
    return 1.0 - (convertedSizeBytes / originalSizeBytes);
  }

  /// 计算成功率
  double get successRate {
    final totalRecords = convertedRecords + skippedRecords + errorRecords;
    if (totalRecords == 0) return 0.0;
    return convertedRecords / totalRecords;
  }
}

/// 升级链结果
@freezed
class UpgradeChainResult with _$UpgradeChainResult {
  const UpgradeChainResult._();

  const factory UpgradeChainResult({
    /// 升级是否成功
    required bool success,

    /// 结果消息
    required String message,

    /// 最终输出路径
    String? finalOutputPath,

    /// 各个适配器的结果
    required List<ImportExportAdapterResult> adapterResults,

    /// 总体统计信息
    UpgradeChainStatistics? statistics,

    /// 错误信息（失败时）
    String? errorMessage,

    /// 失败的适配器索引（失败时）
    int? failedAdapterIndex,
  }) = _UpgradeChainResult;

  factory UpgradeChainResult.fromJson(Map<String, dynamic> json) =>
      _$UpgradeChainResultFromJson(json);

  /// 创建成功结果
  factory UpgradeChainResult.success(
    List<ImportExportAdapterResult> results, {
    String? finalOutputPath,
    UpgradeChainStatistics? statistics,
  }) {
    return UpgradeChainResult(
      success: true,
      message: '升级链执行成功',
      finalOutputPath: finalOutputPath,
      adapterResults: results,
      statistics: statistics,
    );
  }

  /// 创建失败结果
  factory UpgradeChainResult.failed(
    List<ImportExportAdapterResult> results, {
    String? errorMessage,
    int? failedAdapterIndex,
  }) {
    return UpgradeChainResult(
      success: false,
      message: errorMessage ?? '升级链执行失败',
      adapterResults: results,
      errorMessage: errorMessage,
      failedAdapterIndex: failedAdapterIndex,
    );
  }
}

/// 升级链统计信息
@freezed
class UpgradeChainStatistics with _$UpgradeChainStatistics {
  const UpgradeChainStatistics._();

  const factory UpgradeChainStatistics({
    /// 总开始时间
    required DateTime startTime,

    /// 总结束时间
    required DateTime endTime,

    /// 总耗时（毫秒）
    required int totalDurationMs,

    /// 执行的适配器数量
    required int adapterCount,

    /// 总处理记录数
    @Default(0) int totalRecords,

    /// 总处理文件数
    @Default(0) int totalFiles,

    /// 原始数据大小
    @Default(0) int originalSizeBytes,

    /// 最终数据大小
    @Default(0) int finalSizeBytes,

    /// 各适配器耗时分布
    @Default({}) Map<String, int> adapterDurations,
  }) = _UpgradeChainStatistics;

  factory UpgradeChainStatistics.fromJson(Map<String, dynamic> json) =>
      _$UpgradeChainStatisticsFromJson(json);

  /// 计算平均适配器耗时
  double get averageAdapterDuration {
    if (adapterCount == 0) return 0.0;
    return totalDurationMs / adapterCount;
  }

  /// 计算总体处理速度
  double get overallProcessingSpeed {
    if (totalDurationMs == 0) return 0.0;
    return totalRecords / (totalDurationMs / 1000.0);
  }
}

/// 导入升级结果
@freezed
class ImportUpgradeResult with _$ImportUpgradeResult {
  const ImportUpgradeResult._();

  const factory ImportUpgradeResult({
    /// 升级状态
    required ImportUpgradeStatus status,

    /// 源数据版本
    required String sourceVersion,

    /// 目标数据版本
    required String targetVersion,

    /// 结果消息
    required String message,

    /// 升级后的文件路径
    String? upgradedFilePath,

    /// 升级链结果
    UpgradeChainResult? upgradeChainResult,

    /// 错误信息
    String? errorMessage,
  }) = _ImportUpgradeResult;

  factory ImportUpgradeResult.fromJson(Map<String, dynamic> json) =>
      _$ImportUpgradeResultFromJson(json);

  /// 创建兼容结果
  factory ImportUpgradeResult.compatible(
      String sourceVersion, String targetVersion) {
    return ImportUpgradeResult(
      status: ImportUpgradeStatus.compatible,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
      message: '数据版本兼容，无需升级',
    );
  }

  /// 创建升级成功结果
  factory ImportUpgradeResult.upgraded(
    String sourceVersion,
    String targetVersion,
    String upgradedFilePath,
    UpgradeChainResult upgradeChainResult,
  ) {
    return ImportUpgradeResult(
      status: ImportUpgradeStatus.upgraded,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
      message: '数据版本升级成功',
      upgradedFilePath: upgradedFilePath,
      upgradeChainResult: upgradeChainResult,
    );
  }

  /// 创建需要应用升级结果
  factory ImportUpgradeResult.appUpgradeRequired(
      String sourceVersion, String targetVersion) {
    return ImportUpgradeResult(
      status: ImportUpgradeStatus.appUpgradeRequired,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
      message: '需要升级应用版本才能导入此数据',
    );
  }

  /// 创建不兼容结果
  factory ImportUpgradeResult.incompatible(
      String sourceVersion, String targetVersion) {
    return ImportUpgradeResult(
      status: ImportUpgradeStatus.incompatible,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
      message: '数据版本不兼容，无法导入',
    );
  }

  /// 创建错误结果
  factory ImportUpgradeResult.error(String errorMessage) {
    return ImportUpgradeResult(
      status: ImportUpgradeStatus.error,
      sourceVersion: 'unknown',
      targetVersion: 'unknown',
      message: '升级过程中发生错误',
      errorMessage: errorMessage,
    );
  }
}

/// 导入升级状态
enum ImportUpgradeStatus {
  /// 兼容，无需升级
  compatible,

  /// 已升级
  upgraded,

  /// 需要应用升级
  appUpgradeRequired,

  /// 不兼容
  incompatible,

  /// 错误
  error,
}
