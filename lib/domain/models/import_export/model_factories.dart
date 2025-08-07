import '../../../version_config.dart';

import 'export_data_model.dart';
import 'import_data_model.dart';

/// 数据模型工厂方法
/// 提供简化的构造函数来创建复杂的数据模型实例
class ModelFactories {
  
  /// 获取安全的版本信息（如果VersionConfig未初始化则抛出异常）
  static String _getSafeVersion() {
    try {
      return VersionConfig.versionInfo.shortVersion;
    } catch (e) {
      // 如果VersionConfig未初始化，抛出异常而不是返回默认值
      throw StateError('无法获取版本信息，请确保 VersionConfig 已正确初始化: $e');
    }
  }
  
  /// 创建空的导出数据模型
  static ExportDataModel createEmptyExportData() {
    return ExportDataModel(
      metadata: createBasicExportMetadata(),
      works: [],
      workImages: [],
      characters: [],
      manifest: createBasicExportManifest(),
    );
  }
  
  /// 创建基础的导出元数据
  static ExportMetadata createBasicExportMetadata({
    String? version,
    ExportType exportType = ExportType.worksOnly,
    String? appVersion,
    String platform = 'flutter',
  }) {
    final safeVersion = _getSafeVersion();
    return ExportMetadata(
      version: version ?? safeVersion,
      exportTime: DateTime.now(),
      exportType: exportType,
      options: createBasicExportOptions(exportType),
      appVersion: appVersion ?? safeVersion,
      platform: platform,
      compatibility: createBasicCompatibilityInfo(),
    );
  }
  
  /// 创建基础的导出选项
  static ExportOptions createBasicExportOptions(ExportType type) {
    return ExportOptions(
      type: type,
      format: ExportFormat.zip,
    );
  }
  
  /// 创建基础的兼容性信息
  static CompatibilityInfo createBasicCompatibilityInfo({
    String? minSupportedVersion,
    String? recommendedVersion,
  }) {
    final safeVersion = _getSafeVersion();
    return CompatibilityInfo(
      minSupportedVersion: minSupportedVersion ?? safeVersion,
      recommendedVersion: recommendedVersion ?? safeVersion,
    );
  }
  
  /// 创建基础的导出清单
  static ExportManifest createBasicExportManifest() {
    return ExportManifest(
      summary: const ExportSummary(),
      files: [],
      statistics: createBasicExportStatistics(),
      validations: [],
    );
  }
  
  /// 创建基础的导出统计
  static ExportStatistics createBasicExportStatistics() {
    return const ExportStatistics(
      customConfigs:  CustomConfigStatistics(),
    );
  }
  
  /// 创建成功的导入验证结果
  static ImportValidationResult createSuccessValidationResult() {
    return ImportValidationResult(
      status: ValidationStatus.passed,
      isValid: true,
      messages: [],
      statistics: const ImportDataStatistics(),
      compatibility: createBasicCompatibilityCheckResult(),
      fileIntegrity: createBasicFileIntegrityResult(),
      dataIntegrity: createBasicDataIntegrityResult(),
    );
  }
  
  /// 创建失败的导入验证结果
  static ImportValidationResult createFailedValidationResult(String message) {
    return ImportValidationResult(
      status: ValidationStatus.failed,
      isValid: false,
      messages: [
        ValidationMessage(
          level: ValidationLevel.error,
          type: ValidationType.format,
          message: message,
        ),
      ],
      statistics: const ImportDataStatistics(),
      compatibility: createBasicCompatibilityCheckResult(),
      fileIntegrity: createBasicFileIntegrityResult(),
      dataIntegrity: createBasicDataIntegrityResult(),
    );
  }
  
  /// 创建基础的兼容性检查结果
  static CompatibilityCheckResult createBasicCompatibilityCheckResult({
    String? dataFormatVersion,
    String? appVersion,
  }) {
    final safeVersion = _getSafeVersion();
    return CompatibilityCheckResult(
      isCompatible: true,
      dataFormatVersion: dataFormatVersion ?? safeVersion,
      appVersion: appVersion ?? safeVersion,
      level: CompatibilityLevel.fullCompatible,
    );
  }
  
  /// 创建基础的文件完整性结果
  static FileIntegrityResult createBasicFileIntegrityResult() {
    return const FileIntegrityResult(
      isIntact: true,
    );
  }
  
  /// 创建基础的数据完整性结果
  static DataIntegrityResult createBasicDataIntegrityResult() {
    return const DataIntegrityResult(
      isIntact: true,
    );
  }
  
  /// 创建基础的导入数据模型
  static ImportDataModel createBasicImportData({
    required ExportDataModel exportData,
    required ImportOptions options,
  }) {
    return ImportDataModel(
      exportData: exportData,
      validation: createSuccessValidationResult(),
      conflicts: [],
      options: options,
    );
  }
  
  /// 创建基础的导入选项
  static ImportOptions createBasicImportOptions() {
    return const ImportOptions();
  }
} 