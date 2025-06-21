import 'export_data_model.dart';
import 'import_data_model.dart';

/// 数据模型工厂方法
/// 提供简化的构造函数来创建复杂的数据模型实例
class ModelFactories {
  
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
    String version = '1.0.0',
    ExportType exportType = ExportType.worksOnly,
    String appVersion = '1.0.0',
    String platform = 'flutter',
  }) {
    return ExportMetadata(
      version: version,
      exportTime: DateTime.now(),
      exportType: exportType,
      options: createBasicExportOptions(exportType),
      appVersion: appVersion,
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
  static CompatibilityInfo createBasicCompatibilityInfo() {
    return CompatibilityInfo(
      minSupportedVersion: '1.0.0',
      recommendedVersion: '1.0.0',
    );
  }
  
  /// 创建基础的导出清单
  static ExportManifest createBasicExportManifest() {
    return ExportManifest(
      summary: ExportSummary(),
      files: [],
      statistics: createBasicExportStatistics(),
      validations: [],
    );
  }
  
  /// 创建基础的导出统计
  static ExportStatistics createBasicExportStatistics() {
    return ExportStatistics(
      customConfigs: CustomConfigStatistics(),
    );
  }
  
  /// 创建成功的导入验证结果
  static ImportValidationResult createSuccessValidationResult() {
    return ImportValidationResult(
      status: ValidationStatus.passed,
      isValid: true,
      messages: [],
      statistics: ImportDataStatistics(),
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
      statistics: ImportDataStatistics(),
      compatibility: createBasicCompatibilityCheckResult(),
      fileIntegrity: createBasicFileIntegrityResult(),
      dataIntegrity: createBasicDataIntegrityResult(),
    );
  }
  
  /// 创建基础的兼容性检查结果
  static CompatibilityCheckResult createBasicCompatibilityCheckResult() {
    return CompatibilityCheckResult(
      isCompatible: true,
      dataFormatVersion: '1.0.0',
      appVersion: '1.0.0',
      level: CompatibilityLevel.fullCompatible,
    );
  }
  
  /// 创建基础的文件完整性结果
  static FileIntegrityResult createBasicFileIntegrityResult() {
    return FileIntegrityResult(
      isIntact: true,
    );
  }
  
  /// 创建基础的数据完整性结果
  static DataIntegrityResult createBasicDataIntegrityResult() {
    return DataIntegrityResult(
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
    return ImportOptions();
  }
} 