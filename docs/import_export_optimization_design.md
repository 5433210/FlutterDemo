# 作品导入导出、集字导入导出功能优化设计

## 📋 设计概述

基于统一升级系统的成功经验，对作品导入导出、集字导入导出功能进行优化，引入数据格式版本管理、兼容性检查和自动升级机制，确保不同版本间的数据交换稳定可靠。

## 🎯 设计目标

### 1. 核心目标

- **版本管理简化**: 使用独立的导入导出数据格式版本，减少维护复杂度
- **兼容性保证**: 确保新版本应用能导入旧版本导出的数据
- **自动升级**: 导入时自动处理数据格式升级，用户无感知
- **向后兼容**: 保持与现有导入导出功能的完全兼容

### 2. 解决的问题

- **版本碎片化**: 当前使用应用版本管理导出数据，维护复杂
- **兼容性检查不足**: 缺乏系统性的版本兼容性验证
- **数据升级缺失**: 无法处理旧版本导出数据的格式升级
- **错误处理不完善**: 版本不兼容时缺乏明确的处理策略

## 🏗️ 系统架构

### 1. 数据格式版本定义

#### 1.1 导入导出数据版本体系

```dart
class ImportExportDataVersionDefinition {
  // 导入导出数据格式版本定义
  static const Map<String, ImportExportDataVersionInfo> versions = {
    'ie_v1': ImportExportDataVersionInfo(
      version: 'ie_v1',
      description: '基础导入导出格式',
      supportedAppVersions: ['1.0.0', '1.1.0'],
      databaseVersionRange: [1, 5],
      features: ['基础作品导出', '基础集字导出', 'JSON格式'],
    ),
    'ie_v2': ImportExportDataVersionInfo(
      version: 'ie_v2', 
      description: '增强导入导出格式',
      supportedAppVersions: ['1.1.0', '1.2.0'],
      databaseVersionRange: [6, 10],
      features: ['ZIP压缩', '图片文件包含', '元数据增强'],
    ),
    'ie_v3': ImportExportDataVersionInfo(
      version: 'ie_v3',
      description: '完整导入导出格式',
      supportedAppVersions: ['1.2.0', '1.3.0'],
      databaseVersionRange: [11, 15],
      features: ['关联数据导出', '批量操作', '进度监控'],
    ),
    'ie_v4': ImportExportDataVersionInfo(
      version: 'ie_v4',
      description: '优化导入导出格式',
      supportedAppVersions: ['1.3.0+'],
      databaseVersionRange: [16, 20],
      features: ['增量导入', '冲突解决', '数据验证'],
    ),
  };
}
```

#### 1.2 版本映射关系

```dart
class ImportExportVersionMappingService {
  // 应用版本 → 导入导出数据版本映射
  static const Map<String, String> appToDataVersionMap = {
    '1.0.0': 'ie_v1',
    '1.1.0': 'ie_v2', 
    '1.2.0': 'ie_v3',
    '1.3.0': 'ie_v4',
  };
  
  // 数据库版本 → 导入导出数据版本映射
  static const Map<int, String> databaseToDataVersionMap = {
    1: 'ie_v1', 2: 'ie_v1', 3: 'ie_v1', 4: 'ie_v1', 5: 'ie_v1',
    6: 'ie_v2', 7: 'ie_v2', 8: 'ie_v2', 9: 'ie_v2', 10: 'ie_v2',
    11: 'ie_v3', 12: 'ie_v3', 13: 'ie_v3', 14: 'ie_v3', 15: 'ie_v3',
    16: 'ie_v4', 17: 'ie_v4', 18: 'ie_v4', 19: 'ie_v4', 20: 'ie_v4',
  };
}
```

### 2. 兼容性矩阵

#### 2.1 四类兼容性定义

```dart
enum ImportExportCompatibility {
  compatible,     // C: 完全兼容，直接导入
  upgradable,     // D: 兼容但需升级数据格式
  appUpgradeRequired, // A: 需要升级应用
  incompatible,   // N: 不兼容，无法导入
}
```

#### 2.2 兼容性对照表

| 导出数据版本 | ie_v1 | ie_v2 | ie_v3 | ie_v4 |
|-------------|-------|-------|-------|-------|
| **ie_v1**   | C     | D     | D     | D     |
| **ie_v2**   | A     | C     | D     | D     |
| **ie_v3**   | A     | A     | C     | D     |
| **ie_v4**   | A     | A     | A     | C     |

### 3. 数据格式适配器系统

#### 3.1 适配器接口定义

```dart
abstract class ImportExportDataAdapter {
  String get sourceDataVersion;
  String get targetDataVersion;
  
  /// 预处理：数据格式转换
  Future<ImportExportAdapterResult> preProcess(String exportFilePath);
  
  /// 后处理：数据完整性验证
  Future<ImportExportAdapterResult> postProcess(String importedDataPath);
  
  /// 验证：确认升级成功
  Future<bool> validate(String dataPath);
}
```

#### 3.2 具体适配器实现

```dart
// ie_v1 → ie_v2 适配器
class ImportExportAdapter_v1_to_v2 implements ImportExportDataAdapter {
  @override
  Future<ImportExportAdapterResult> preProcess(String exportFilePath) async {
    // 1. 解析 ie_v1 格式的导出文件
    // 2. 转换数据结构到 ie_v2 格式
    // 3. 添加新的元数据字段
    // 4. 处理图片文件路径
  }
  
  @override
  Future<ImportExportAdapterResult> postProcess(String importedDataPath) async {
    // 1. 验证导入的数据完整性
    // 2. 更新索引文件
    // 3. 生成缩略图（如果需要）
  }
}

// ie_v2 → ie_v3 适配器  
class ImportExportAdapter_v2_to_v3 implements ImportExportDataAdapter {
  @override
  Future<ImportExportAdapterResult> preProcess(String exportFilePath) async {
    // 1. 处理关联数据结构变更
    // 2. 升级元数据格式
    // 3. 转换批量操作格式
  }
}

// ie_v3 → ie_v4 适配器
class ImportExportAdapter_v3_to_v4 implements ImportExportDataAdapter {
  @override
  Future<ImportExportAdapterResult> preProcess(String exportFilePath) async {
    // 1. 添加增量导入支持
    // 2. 升级冲突解决机制
    // 3. 增强数据验证规则
  }
}
```

### 4. 优化的导出数据结构

#### 4.1 简化的导出元数据

```dart
class OptimizedExportMetadata {
  final String dataFormatVersion;  // 使用导入导出数据版本 (ie_v1, ie_v2, etc.)
  final DateTime exportTime;
  final ExportType exportType;
  final String appVersion;        // 保留用于调试
  final String platform;         // 保留用于调试
  final Map<String, dynamic> formatSpecificData; // 版本特定数据
}
```

#### 4.2 版本特定数据示例

```dart
// ie_v1 格式特定数据
{
  "compressionLevel": 0,
  "includeImages": false,
  "basicMetadata": true
}

// ie_v2 格式特定数据  
{
  "compressionLevel": 6,
  "includeImages": true,
  "imageQuality": 85,
  "thumbnailGeneration": true
}

// ie_v3 格式特定数据
{
  "compressionLevel": 6,
  "includeImages": true,
  "includeRelatedData": true,
  "batchOperationSupport": true,
  "progressTracking": true
}

// ie_v4 格式特定数据
{
  "compressionLevel": 9,
  "includeImages": true,
  "includeRelatedData": true,
  "incrementalImport": true,
  "conflictResolution": "advanced",
  "dataValidation": "strict"
}
```

## 🔄 三阶段处理流程

### 1. 导入时的处理流程

#### 阶段1: 预处理 (Pre-Processing)

```dart
class ImportPreProcessor {
  Future<PreProcessResult> process(String exportFilePath) async {
    // 1. 检测导出文件的数据格式版本
    final exportVersion = await _detectDataFormatVersion(exportFilePath);
    
    // 2. 获取当前应用支持的数据格式版本
    final currentVersion = ImportExportVersionMappingService.getCurrentDataVersion();
    
    // 3. 检查兼容性
    final compatibility = ImportExportVersionMappingService.checkCompatibility(
        exportVersion, currentVersion);
    
    // 4. 如果需要升级，执行数据格式适配器链
    if (compatibility == ImportExportCompatibility.upgradable) {
      return await _executeAdapterChain(exportFilePath, exportVersion, currentVersion);
    }
    
    return PreProcessResult.compatible();
  }
}
```

#### 阶段2: 导入处理 (Import Processing)  

```dart
class OptimizedImportProcessor {
  Future<ImportResult> process(String processedFilePath) async {
    // 1. 解析处理后的导出数据
    final importData = await _parseImportData(processedFilePath);
    
    // 2. 执行标准导入流程
    return await _performStandardImport(importData);
  }
}
```

#### 阶段3: 后处理 (Post-Processing)

```dart
class ImportPostProcessor {
  Future<PostProcessResult> process(String importedDataPath) async {
    // 1. 验证导入数据完整性
    await _validateImportedData(importedDataPath);
    
    // 2. 更新索引和缓存
    await _updateIndexes(importedDataPath);
    
    // 3. 生成导入报告
    return await _generateImportReport(importedDataPath);
  }
}
```

### 2. 导出时的版本处理

#### 导出版本选择策略

```dart
class ExportVersionStrategy {
  String selectExportVersion(ExportOptions options) {
    // 1. 默认使用当前应用对应的最新数据格式版本
    final currentAppVersion = AppInfo.version;
    final defaultVersion = ImportExportVersionMappingService.getDataVersionForApp(currentAppVersion);
    
    // 2. 如果用户指定了兼容性要求，选择合适的版本
    if (options.targetCompatibility != null) {
      return _selectCompatibleVersion(options.targetCompatibility);
    }
    
    return defaultVersion;
  }
}
```

## 🔧 适配器管理器

### 1. 适配器注册和管理

```dart
class ImportExportAdapterManager {
  static final Map<String, ImportExportDataAdapter> _adapters = {
    'ie_v1->ie_v2': ImportExportAdapter_v1_to_v2(),
    'ie_v2->ie_v3': ImportExportAdapter_v2_to_v3(), 
    'ie_v3->ie_v4': ImportExportAdapter_v3_to_v4(),
  };
  
  /// 获取升级路径的所有适配器
  static List<ImportExportDataAdapter> getUpgradeAdapters(
      String fromVersion, String toVersion) {
    final upgradePath = ImportExportDataVersionDefinition.getUpgradePath(
        fromVersion, toVersion);
    
    final adapters = <ImportExportDataAdapter>[];
    for (int i = 0; i < upgradePath.length - 1; i++) {
      final from = upgradePath[i];
      final to = upgradePath[i + 1];
      final adapter = _adapters['$from->$to'];
      if (adapter != null) {
        adapters.add(adapter);
      }
    }
    
    return adapters;
  }
}
```

### 2. 跨版本升级支持

```dart
class CrossVersionUpgradeHandler {
  /// 处理跨版本升级 (如 ie_v1 → ie_v4)
  Future<UpgradeChainResult> handleCrossVersionUpgrade(
      String exportFilePath, String fromVersion, String toVersion) async {
    
    final adapters = ImportExportAdapterManager.getUpgradeAdapters(fromVersion, toVersion);
    
    String currentFilePath = exportFilePath;
    final results = <ImportExportAdapterResult>[];
    
    for (final adapter in adapters) {
      final result = await adapter.preProcess(currentFilePath);
      results.add(result);
      
      if (!result.success) {
        return UpgradeChainResult.failed(results);
      }
      
      currentFilePath = result.outputPath!;
    }
    
    return UpgradeChainResult.success(results);
  }
}
```

## 📊 统一服务接口

### 1. 统一导入导出升级服务

```dart
class UnifiedImportExportUpgradeService {
  /// 导入时的版本检查和升级
  static Future<ImportUpgradeResult> checkAndUpgradeForImport(
      String exportFilePath) async {
    
    // 1. 检测导出文件版本
    final exportVersion = await _detectExportDataVersion(exportFilePath);
    final currentVersion = ImportExportVersionMappingService.getCurrentDataVersion();
    
    // 2. 检查兼容性
    final compatibility = ImportExportVersionMappingService.checkCompatibility(
        exportVersion, currentVersion);
    
    switch (compatibility) {
      case ImportExportCompatibility.compatible:
        return ImportUpgradeResult.compatible(exportVersion, currentVersion);
        
      case ImportExportCompatibility.upgradable:
        return await _executeImportUpgrade(exportFilePath, exportVersion, currentVersion);
        
      case ImportExportCompatibility.appUpgradeRequired:
        return ImportUpgradeResult.appUpgradeRequired(exportVersion, currentVersion);
        
      case ImportExportCompatibility.incompatible:
        return ImportUpgradeResult.incompatible(exportVersion, currentVersion);
    }
  }
  
  /// 导出时的版本选择
  static String selectOptimalExportVersion(ExportOptions options) {
    return ExportVersionStrategy().selectExportVersion(options);
  }
}
```

## 🎯 实现优势

### 1. 维护简化

- **独立版本管理**: 导入导出数据版本独立于应用版本，减少 N×N 复杂度
- **适配器模式**: 新增数据格式版本只需添加适配器，无需修改核心逻辑
- **版本映射表**: 清晰的版本对应关系，易于维护和扩展

### 2. 用户体验优化

- **无感知升级**: 导入时自动处理版本升级，用户无需关心版本差异
- **明确错误提示**: 不兼容时给出清晰的错误信息和解决建议
- **进度反馈**: 升级过程中提供详细的进度信息

### 3. 系统稳定性

- **三阶段处理**: 预处理→导入→后处理的完整流程确保数据完整性
- **回滚机制**: 升级失败时能够回滚到原始状态
- **验证机制**: 每个阶段都有完整的验证确保数据正确性

### 4. 扩展性设计

- **插件化架构**: 适配器可以独立开发和测试
- **版本策略**: 支持多种导出版本选择策略
- **自定义处理**: 支持特定版本的自定义处理逻辑

## 📁 文件结构

```text
lib/
├── application/
│   ├── services/
│   │   ├── import_export_upgrade_service.dart
│   │   ├── import_export_version_mapping_service.dart
│   │   └── optimized_import_export_service.dart
│   └── adapters/
│       ├── import_export_adapter_manager.dart
│       └── import_export_versions/
│           ├── adapter_ie_v1_to_v2.dart
│           ├── adapter_ie_v2_to_v3.dart
│           └── adapter_ie_v3_to_v4.dart
├── domain/
│   ├── models/
│   │   ├── import_export_data_version_definition.dart
│   │   ├── optimized_export_metadata.dart
│   │   └── import_export_upgrade_result.dart
│   └── interfaces/
│       └── import_export_data_adapter.dart
```

## 🧪 测试策略

### 1. 版本兼容性测试

```dart
class ImportExportCompatibilityTest {
  /// 测试所有版本组合的兼容性
  void testAllVersionCompatibility() {
    final versions = ['ie_v1', 'ie_v2', 'ie_v3', 'ie_v4'];

    for (final exportVersion in versions) {
      for (final importVersion in versions) {
        final compatibility = ImportExportVersionMappingService.checkCompatibility(
            exportVersion, importVersion);

        // 验证兼容性矩阵的正确性
        _validateCompatibilityResult(exportVersion, importVersion, compatibility);
      }
    }
  }
}
```

### 2. 适配器链测试

```dart
class AdapterChainTest {
  /// 测试跨版本适配器链
  void testCrossVersionAdapterChain() {
    // 测试 ie_v1 → ie_v4 的完整升级链
    final adapters = ImportExportAdapterManager.getUpgradeAdapters('ie_v1', 'ie_v4');

    expect(adapters.length, equals(3)); // v1→v2, v2→v3, v3→v4
    expect(adapters[0].sourceDataVersion, equals('ie_v1'));
    expect(adapters[2].targetDataVersion, equals('ie_v4'));
  }
}
```

### 3. 数据完整性测试

```dart
class DataIntegrityTest {
  /// 测试升级后数据完整性
  Future<void> testUpgradeDataIntegrity() async {
    // 1. 创建 ie_v1 格式的测试数据
    final v1Data = _createV1TestData();

    // 2. 执行升级到 ie_v4
    final upgradeResult = await UnifiedImportExportUpgradeService
        .checkAndUpgradeForImport(v1Data.filePath);

    // 3. 验证升级后的数据完整性
    expect(upgradeResult.status, equals(ImportUpgradeStatus.upgraded));
    await _validateUpgradedDataIntegrity(upgradeResult.outputPath);
  }
}
```

## 🔄 迁移策略

### 1. 渐进式迁移

```dart
class ImportExportMigrationStrategy {
  /// 阶段1: 保持向后兼容
  static Future<void> phase1_BackwardCompatibility() async {
    // 1. 新系统与现有系统并行运行
    // 2. 导出时同时生成新旧两种格式
    // 3. 导入时优先使用新系统，失败时回退到旧系统
  }

  /// 阶段2: 逐步切换
  static Future<void> phase2_GradualTransition() async {
    // 1. 默认使用新系统
    // 2. 提供旧系统兼容模式开关
    // 3. 监控新系统稳定性
  }

  /// 阶段3: 完全切换
  static Future<void> phase3_CompleteTransition() async {
    // 1. 移除旧系统代码
    // 2. 清理兼容性代码
    // 3. 优化新系统性能
  }
}
```

### 2. 数据迁移工具

```dart
class ImportExportDataMigrationTool {
  /// 批量升级现有导出文件
  Future<MigrationResult> batchUpgradeExportFiles(
      List<String> filePaths) async {

    final results = <String, ImportUpgradeResult>{};

    for (final filePath in filePaths) {
      try {
        final result = await UnifiedImportExportUpgradeService
            .checkAndUpgradeForImport(filePath);
        results[filePath] = result;
      } catch (e) {
        results[filePath] = ImportUpgradeResult.error(e.toString());
      }
    }

    return MigrationResult(results);
  }
}
```

## 📈 性能优化

### 1. 缓存机制

```dart
class ImportExportVersionCache {
  static final Map<String, String> _versionCache = {};

  /// 缓存导出文件版本信息
  static Future<String> getCachedVersion(String filePath) async {
    if (_versionCache.containsKey(filePath)) {
      return _versionCache[filePath]!;
    }

    final version = await _detectVersionFromFile(filePath);
    _versionCache[filePath] = version;
    return version;
  }
}
```

### 2. 流式处理

```dart
class StreamingImportProcessor {
  /// 大文件流式处理
  Stream<ImportProgress> processLargeFile(String filePath) async* {
    final fileSize = await File(filePath).length();
    var processedBytes = 0;

    await for (final chunk in _readFileInChunks(filePath)) {
      // 处理数据块
      await _processChunk(chunk);

      processedBytes += chunk.length;
      yield ImportProgress(
        percentage: processedBytes / fileSize,
        processedBytes: processedBytes,
        totalBytes: fileSize,
      );
    }
  }
}
```

## 🛡️ 安全性考虑

### 1. 数据验证

```dart
class ImportExportSecurityValidator {
  /// 验证导入数据安全性
  Future<SecurityValidationResult> validateImportSecurity(
      String filePath) async {

    // 1. 文件大小检查
    final fileSize = await File(filePath).length();
    if (fileSize > maxAllowedFileSize) {
      return SecurityValidationResult.failed('文件过大');
    }

    // 2. 文件类型检查
    if (!_isAllowedFileType(filePath)) {
      return SecurityValidationResult.failed('不支持的文件类型');
    }

    // 3. 内容安全扫描
    final contentSafe = await _scanFileContent(filePath);
    if (!contentSafe) {
      return SecurityValidationResult.failed('文件内容不安全');
    }

    return SecurityValidationResult.passed();
  }
}
```

### 2. 权限控制

```dart
class ImportExportPermissionManager {
  /// 检查导入导出权限
  Future<bool> checkPermission(ImportExportOperation operation) async {
    switch (operation.type) {
      case OperationType.import:
        return await _checkImportPermission(operation);
      case OperationType.export:
        return await _checkExportPermission(operation);
    }
  }
}
```

## 📊 监控和日志

### 1. 操作监控

```dart
class ImportExportMonitor {
  /// 记录导入导出操作统计
  static void recordOperation(ImportExportOperation operation) {
    final metrics = ImportExportMetrics(
      operationType: operation.type,
      dataVersion: operation.dataVersion,
      fileSize: operation.fileSize,
      duration: operation.duration,
      success: operation.success,
    );

    _metricsCollector.record(metrics);
  }
}
```

### 2. 错误追踪

```dart
class ImportExportErrorTracker {
  /// 追踪和分析错误模式
  static void trackError(ImportExportError error) {
    AppLogger.error('导入导出错误',
        error: error.exception,
        tag: 'ImportExport',
        data: {
          'operation': error.operation,
          'dataVersion': error.dataVersion,
          'errorCode': error.code,
          'context': error.context,
        });
  }
}
```

## 🎯 实施计划

### 第一阶段: 核心框架 (2周)

1. **数据版本定义系统**
   - 实现 `ImportExportDataVersionDefinition`
   - 创建版本映射服务
   - 建立兼容性检查机制

2. **适配器接口和管理器**
   - 定义 `ImportExportDataAdapter` 接口
   - 实现 `ImportExportAdapterManager`
   - 创建基础适配器框架

### 第二阶段: 适配器实现 (3周)

1. **具体适配器开发**
   - 实现 `ie_v1→ie_v2` 适配器
   - 实现 `ie_v2→ie_v3` 适配器
   - 实现 `ie_v3→ie_v4` 适配器

2. **跨版本升级支持**
   - 实现适配器链执行
   - 添加错误处理和回滚机制

### 第三阶段: 服务集成 (2周)

1. **统一升级服务**
   - 实现 `UnifiedImportExportUpgradeService`
   - 集成到现有导入导出服务
   - 添加版本检测和升级逻辑

2. **优化导出服务**
   - 更新导出元数据结构
   - 实现版本选择策略
   - 优化导出性能

### 第四阶段: 测试和优化 (2周)

1. **全面测试**
   - 版本兼容性测试
   - 适配器链测试
   - 数据完整性测试
   - 性能测试

2. **文档和培训**
   - 完善技术文档
   - 创建用户指南
   - 准备迁移计划

## 📋 总结

这个优化设计基于统一升级系统的成功经验，为导入导出功能提供了：

### 核心优势

- **版本管理简化**: 独立的数据格式版本管理
- **自动升级能力**: 无感知的数据格式升级
- **向后兼容保证**: 新版本能处理所有旧版本数据
- **扩展性设计**: 易于添加新的数据格式版本

### 技术特点

- **三阶段处理**: 预处理→导入→后处理的完整流程
- **适配器模式**: 灵活的版本升级处理
- **兼容性矩阵**: 清晰的版本兼容关系
- **错误处理**: 完善的错误处理和回滚机制

### 实施保障

- **渐进式迁移**: 平滑的系统切换过程
- **全面测试**: 完整的测试覆盖
- **性能优化**: 针对大文件的优化处理
- **安全考虑**: 完善的安全验证机制

这个设计确保了导入导出功能的长期稳定性和可维护性，为用户提供了更好的数据交换体验。
