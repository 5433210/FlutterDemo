import 'dart:io';

import '../../domain/interfaces/import_export_data_adapter.dart';
import '../../domain/models/import_export/import_export_data_version_definition.dart';
import '../../infrastructure/logging/logger.dart';
import '../adapters/import_export_adapter_manager.dart';
import 'import_export_version_mapping_service.dart';

/// 统一导入导出升级服务
class UnifiedImportExportUpgradeService {
  static final UnifiedImportExportUpgradeService _instance = 
      UnifiedImportExportUpgradeService._internal();
  factory UnifiedImportExportUpgradeService() => _instance;
  UnifiedImportExportUpgradeService._internal();

  late final ImportExportAdapterManager _adapterManager;
  bool _isInitialized = false;

  /// 初始化服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _adapterManager = ImportExportAdapterManager();
      _adapterManager.initialize();
      
      _isInitialized = true;
      AppLogger.info('统一导入导出升级服务初始化完成', tag: 'UnifiedImportExportUpgradeService');
    } catch (e, stackTrace) {
      AppLogger.error('统一导入导出升级服务初始化失败', 
          error: e, stackTrace: stackTrace, tag: 'UnifiedImportExportUpgradeService');
      rethrow;
    }
  }

  /// 检测导出文件的数据版本
  Future<String?> detectExportDataVersion(String exportFilePath) async {
    try {
      AppLogger.info('检测导出文件数据版本', 
          data: {'filePath': exportFilePath}, tag: 'UnifiedImportExportUpgradeService');

      final file = File(exportFilePath);
      if (!await file.exists()) {
        AppLogger.warning('导出文件不存在', 
            data: {'filePath': exportFilePath}, tag: 'UnifiedImportExportUpgradeService');
        return null;
      }

      // 根据文件扩展名和内容检测版本
      if (exportFilePath.toLowerCase().endsWith('.json')) {
        // ie_v1 格式通常是 JSON 文件
        return await _detectJsonVersion(exportFilePath);
      } else if (exportFilePath.toLowerCase().endsWith('.zip')) {
        // ie_v2+ 格式通常是 ZIP 文件
        return await _detectZipVersion(exportFilePath);
      }

      AppLogger.warning('无法识别的文件格式', 
          data: {'filePath': exportFilePath}, tag: 'UnifiedImportExportUpgradeService');
      return null;

    } catch (e, stackTrace) {
      AppLogger.error('检测导出文件数据版本失败', 
          error: e, stackTrace: stackTrace, tag: 'UnifiedImportExportUpgradeService');
      return null;
    }
  }

  /// 检查导入兼容性
  Future<ImportExportCompatibility> checkImportCompatibility(
    String exportFilePath,
    String currentAppVersion,
  ) async {
    try {
      AppLogger.info('检查导入兼容性', 
          data: {'exportFile': exportFilePath, 'appVersion': currentAppVersion}, 
          tag: 'UnifiedImportExportUpgradeService');

      // 1. 检测导出文件版本
      final exportDataVersion = await detectExportDataVersion(exportFilePath);
      if (exportDataVersion == null) {
        AppLogger.warning('无法检测导出文件版本', 
            data: {'exportFile': exportFilePath}, tag: 'UnifiedImportExportUpgradeService');
        return ImportExportCompatibility.incompatible;
      }

      // 2. 检查兼容性
      final compatibility = ImportExportVersionMappingService.checkExportCompatibility(
        exportDataVersion,
        currentAppVersion,
      );

      AppLogger.info('兼容性检查完成', 
          data: {
            'exportVersion': exportDataVersion,
            'appVersion': currentAppVersion,
            'compatibility': compatibility.toString(),
          }, 
          tag: 'UnifiedImportExportUpgradeService');

      return compatibility;

    } catch (e, stackTrace) {
      AppLogger.error('检查导入兼容性失败', 
          error: e, stackTrace: stackTrace, tag: 'UnifiedImportExportUpgradeService');
      return ImportExportCompatibility.incompatible;
    }
  }

  /// 执行导入升级
  Future<ImportUpgradeResult> performImportUpgrade(
    String exportFilePath,
    String currentAppVersion,
  ) async {
    try {
      AppLogger.info('开始执行导入升级', 
          data: {'exportFile': exportFilePath, 'appVersion': currentAppVersion}, 
          tag: 'UnifiedImportExportUpgradeService');

      // 1. 检测源版本
      final sourceVersion = await detectExportDataVersion(exportFilePath);
      if (sourceVersion == null) {
        return ImportUpgradeResult.error('无法检测导出文件版本');
      }

      // 2. 获取目标版本
      final targetVersion = ImportExportVersionMappingService.getDataVersionForApp(currentAppVersion);

      // 3. 检查兼容性
      final compatibility = ImportExportVersionMappingService.checkCompatibility(
        sourceVersion,
        targetVersion,
      );

      switch (compatibility) {
        case ImportExportCompatibility.compatible:
          return ImportUpgradeResult.compatible(sourceVersion, targetVersion);

        case ImportExportCompatibility.upgradable:
          return await _performUpgrade(sourceVersion, targetVersion, exportFilePath);

        case ImportExportCompatibility.appUpgradeRequired:
          return ImportUpgradeResult.appUpgradeRequired(sourceVersion, targetVersion);

        case ImportExportCompatibility.incompatible:
          return ImportUpgradeResult.incompatible(sourceVersion, targetVersion);
      }

    } catch (e, stackTrace) {
      AppLogger.error('执行导入升级失败', 
          error: e, stackTrace: stackTrace, tag: 'UnifiedImportExportUpgradeService');
      return ImportUpgradeResult.error('升级过程中发生错误: ${e.toString()}');
    }
  }

  /// 获取升级建议
  String getUpgradeSuggestion(String exportFilePath, String currentAppVersion) {
    try {
      // 这是一个同步方法，用于快速获取建议
      // 实际的版本检测可能需要异步操作，这里提供基本建议
      
      if (exportFilePath.toLowerCase().endsWith('.json')) {
        // 可能是 ie_v1 格式
        return ImportExportVersionMappingService.getUpgradeSuggestion('ie_v1', 
            ImportExportVersionMappingService.getDataVersionForApp(currentAppVersion));
      } else if (exportFilePath.toLowerCase().endsWith('.zip')) {
        // 可能是 ie_v2+ 格式，需要进一步检测
        return '正在分析文件格式，请稍候...';
      }

      return '无法识别的文件格式，请检查文件是否正确';

    } catch (e) {
      AppLogger.error('获取升级建议失败', 
          error: e, tag: 'UnifiedImportExportUpgradeService');
      return '获取升级建议时发生错误';
    }
  }

  /// 获取兼容性描述
  String getCompatibilityDescription(ImportExportCompatibility compatibility) {
    return ImportExportVersionMappingService.getCompatibilityDescription(compatibility);
  }

  /// 检查是否支持指定版本的升级
  bool supportsUpgrade(String sourceVersion, String targetVersion) {
    if (!_isInitialized) return false;
    return _adapterManager.supportsConversion(sourceVersion, targetVersion);
  }

  /// 获取所有支持的数据版本
  List<String> getSupportedDataVersions() {
    return ImportExportVersionMappingService.getAllSupportedDataVersions();
  }

  /// 获取版本映射信息
  Map<String, dynamic> getVersionMappingInfo() {
    return ImportExportVersionMappingService.getVersionMappingInfo();
  }

  /// 验证映射配置一致性
  bool validateMappingConsistency() {
    return ImportExportVersionMappingService.validateMappingConsistency();
  }

  /// 执行升级
  Future<ImportUpgradeResult> _performUpgrade(
    String sourceVersion,
    String targetVersion,
    String exportFilePath,
  ) async {
    try {
      AppLogger.info('开始执行数据升级', 
          data: {
            'sourceVersion': sourceVersion,
            'targetVersion': targetVersion,
            'filePath': exportFilePath,
          }, 
          tag: 'UnifiedImportExportUpgradeService');

      // 1. 获取升级路径
      final adapters = _adapterManager.getUpgradePath(sourceVersion, targetVersion);
      if (adapters.isEmpty) {
        return ImportUpgradeResult.error('无法找到从 $sourceVersion 到 $targetVersion 的升级路径');
      }

      // 2. 执行升级链
      final upgradeChainResult = await _adapterManager.executeUpgradeChain(adapters, exportFilePath);
      if (!upgradeChainResult.success) {
        return ImportUpgradeResult.error(
          '升级链执行失败: ${upgradeChainResult.errorMessage ?? upgradeChainResult.message}'
        );
      }

      // 3. 执行后处理
      if (upgradeChainResult.finalOutputPath != null) {
        await _adapterManager.executePostProcessing(adapters, upgradeChainResult.finalOutputPath!);
      }

      // 4. 验证升级结果
      if (upgradeChainResult.finalOutputPath != null) {
        final isValid = await _adapterManager.validateUpgradeResult(
          adapters, 
          upgradeChainResult.finalOutputPath!
        );
        
        if (!isValid) {
          return ImportUpgradeResult.error('升级结果验证失败');
        }
      }

      AppLogger.info('数据升级完成', 
          data: {
            'sourceVersion': sourceVersion,
            'targetVersion': targetVersion,
            'outputPath': upgradeChainResult.finalOutputPath,
          }, 
          tag: 'UnifiedImportExportUpgradeService');

      return ImportUpgradeResult.upgraded(
        sourceVersion,
        targetVersion,
        upgradeChainResult.finalOutputPath!,
        upgradeChainResult,
      );

    } catch (e, stackTrace) {
      AppLogger.error('执行数据升级失败', 
          error: e, stackTrace: stackTrace, tag: 'UnifiedImportExportUpgradeService');
      return ImportUpgradeResult.error('升级过程中发生错误: ${e.toString()}');
    }
  }

  /// 检测 JSON 文件版本
  Future<String?> _detectJsonVersion(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      
      // 简单的版本检测逻辑
      if (content.contains('"dataFormatVersion"')) {
        // 包含版本字段，可能是较新版本
        if (content.contains('"ie_v2"')) return 'ie_v2';
        if (content.contains('"ie_v3"')) return 'ie_v3';
        if (content.contains('"ie_v4"')) return 'ie_v4';
      }
      
      // 默认认为是 ie_v1
      return 'ie_v1';

    } catch (e) {
      AppLogger.error('检测 JSON 版本失败', error: e, tag: 'UnifiedImportExportUpgradeService');
      return null;
    }
  }

  /// 检测 ZIP 文件版本
  Future<String?> _detectZipVersion(String filePath) async {
    try {
      // 这里需要解析 ZIP 文件内容来检测版本
      // 为了简化，先返回默认版本
      // 实际实现中需要解析 ZIP 内的 metadata 文件
      
      // 临时实现：根据文件名模式推测
      if (filePath.contains('_v4')) return 'ie_v4';
      if (filePath.contains('_v3')) return 'ie_v3';
      if (filePath.contains('_v2')) return 'ie_v2';
      
      // 默认认为是 ie_v2（最早的 ZIP 格式）
      return 'ie_v2';

    } catch (e) {
      AppLogger.error('检测 ZIP 版本失败', error: e, tag: 'UnifiedImportExportUpgradeService');
      return null;
    }
  }

  /// 清理临时文件
  Future<void> cleanupTemporaryFiles(UpgradeChainResult upgradeResult) async {
    if (!_isInitialized) return;
    
    try {
      await _adapterManager.cleanupTemporaryFiles(upgradeResult.adapterResults);
      AppLogger.info('临时文件清理完成', tag: 'UnifiedImportExportUpgradeService');
    } catch (e, stackTrace) {
      AppLogger.error('清理临时文件失败', 
          error: e, stackTrace: stackTrace, tag: 'UnifiedImportExportUpgradeService');
    }
  }
}
