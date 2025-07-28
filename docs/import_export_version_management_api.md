# 导入导出版本管理 API 文档

## 概述

本文档描述了导入导出版本管理系统的API接口，包括版本检测、兼容性检查、数据升级等核心功能。

## 核心组件

### 1. ImportExportDataVersionDefinition

数据版本定义类，管理所有导入导出数据版本信息。

```dart
class ImportExportDataVersionDefinition {
  static const Map<String, ImportExportDataVersionInfo> versions;
  
  // 获取版本信息
  static ImportExportDataVersionInfo? getVersionInfo(String version);
  
  // 检查版本是否存在
  static bool isValidVersion(String version);
  
  // 获取所有版本列表
  static List<String> getAllVersions();
  
  // 比较版本
  static int compareVersions(String version1, String version2);
  
  // 计算升级路径
  static List<String> calculateUpgradePath(String from, String to);
}
```

**支持的数据版本：**
- `ie_v1`: 基础导入导出格式
- `ie_v2`: 增强元数据支持
- `ie_v3`: 优化数据结构
- `ie_v4`: 完整功能支持

### 2. ImportExportVersionMappingService

版本映射服务，处理应用版本与数据版本的映射关系。

```dart
class ImportExportVersionMappingService {
  // 获取应用版本对应的数据版本
  static String getDataVersionForApp(String appVersion);
  
  // 获取数据库版本对应的数据版本
  static String getDataVersionForDatabase(int databaseVersion);
  
  // 检查版本兼容性
  static ImportExportCompatibility checkCompatibility(
    String sourceVersion, 
    String targetVersion
  );
  
  // 获取兼容性矩阵
  static Map<String, Map<String, ImportExportCompatibility>> getCompatibilityMatrix();
}
```

**兼容性类型：**
- `compatible`: 完全兼容，无需升级
- `upgradable`: 可升级，需要数据转换
- `appUpgradeRequired`: 需要升级应用版本
- `incompatible`: 不兼容，无法处理

### 3. ImportExportDataAdapter

数据适配器接口，定义版本间的数据转换逻辑。

```dart
abstract class ImportExportDataAdapter {
  String get sourceVersion;
  String get targetVersion;
  String get adapterName;
  
  // 获取适配器描述
  String getDescription();
  
  // 检查是否支持转换
  bool supportsConversion(String from, String to);
  
  // 预处理
  Future<ImportExportAdapterResult> preProcess(String inputFilePath);
  
  // 后处理
  Future<ImportExportAdapterResult> postProcess(String inputFilePath);
  
  // 验证数据
  Future<bool> validate(String filePath);
}
```

### 4. ImportExportAdapterManager

适配器管理器，协调多个适配器的执行。

```dart
class ImportExportAdapterManager {
  // 注册适配器
  void registerAdapter(ImportExportDataAdapter adapter);
  
  // 注销适配器
  void unregisterAdapter(String adapterKey);
  
  // 获取已注册的适配器
  Map<String, ImportExportDataAdapter> getRegisteredAdapters();
  
  // 检查是否支持转换
  bool supportsConversion(String sourceVersion, String targetVersion);
  
  // 执行升级链
  Future<UpgradeChainResult> executeUpgradeChain(
    String inputFilePath,
    String sourceVersion,
    String targetVersion,
  );
}
```

### 5. UnifiedImportExportUpgradeService

统一升级服务，提供高级的版本管理功能。

```dart
class UnifiedImportExportUpgradeService {
  // 初始化服务
  Future<void> initialize();
  
  // 检查导入兼容性
  Future<ImportExportCompatibility> checkImportCompatibility(
    String filePath,
    String currentAppVersion,
  );
  
  // 执行导入升级
  Future<ImportUpgradeResult> performImportUpgrade(
    String exportFilePath,
    String currentAppVersion,
  );
  
  // 检测文件版本
  Future<String?> detectFileVersion(String filePath);
  
  // 验证文件完整性
  Future<bool> validateFile(String filePath);
}
```

## 数据模型

### ImportExportDataVersionInfo

```dart
@freezed
class ImportExportDataVersionInfo with _$ImportExportDataVersionInfo {
  const factory ImportExportDataVersionInfo({
    required String version,
    required String description,
    required List<String> supportedAppVersions,
    required List<int> databaseVersionRange,
    required List<String> features,
    DateTime? releaseDate,
    bool? deprecated,
  }) = _ImportExportDataVersionInfo;
}
```

### ImportUpgradeResult

```dart
@freezed
class ImportUpgradeResult with _$ImportUpgradeResult {
  const factory ImportUpgradeResult({
    required ImportUpgradeStatus status,
    required String sourceVersion,
    required String targetVersion,
    required String message,
    String? upgradedFilePath,
    UpgradeChainResult? upgradeChainResult,
    String? errorMessage,
  }) = _ImportUpgradeResult;
}
```

### UpgradeChainResult

```dart
@freezed
class UpgradeChainResult with _$UpgradeChainResult {
  const factory UpgradeChainResult({
    required bool isSuccess,
    required List<String> executedAdapters,
    required String sourceVersion,
    required String targetVersion,
    String? outputFilePath,
    String? errorMessage,
    List<ImportExportAdapterStatistics>? statistics,
  }) = _UpgradeChainResult;
}
```

## 使用示例

### 基本版本检查

```dart
// 检查版本兼容性
final compatibility = ImportExportVersionMappingService.checkCompatibility(
  'ie_v1', 'ie_v4'
);

if (compatibility == ImportExportCompatibility.upgradable) {
  print('需要升级数据');
} else if (compatibility == ImportExportCompatibility.compatible) {
  print('版本兼容');
}
```

### 执行导入升级

```dart
final upgradeService = UnifiedImportExportUpgradeService();
await upgradeService.initialize();

// 检查导入文件兼容性
final compatibility = await upgradeService.checkImportCompatibility(
  '/path/to/export.zip',
  '1.3.0', // 当前应用版本
);

// 执行升级（如果需要）
if (compatibility == ImportExportCompatibility.upgradable) {
  final result = await upgradeService.performImportUpgrade(
    '/path/to/export.zip',
    '1.3.0',
  );
  
  if (result.status == ImportUpgradeStatus.upgraded) {
    print('升级成功: ${result.upgradedFilePath}');
  }
}
```

### 自定义适配器

```dart
class CustomV1ToV2Adapter extends ImportExportDataAdapter {
  @override
  String get sourceVersion => 'ie_v1';
  
  @override
  String get targetVersion => 'ie_v2';
  
  @override
  String get adapterName => 'CustomV1ToV2Adapter';
  
  @override
  Future<ImportExportAdapterResult> preProcess(String inputFilePath) async {
    // 实现预处理逻辑
    try {
      // 读取和转换数据
      final result = await _convertData(inputFilePath);
      
      return ImportExportAdapterResult.success(
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
        outputFilePath: result.outputPath,
        statistics: result.statistics,
      );
    } catch (e) {
      return ImportExportAdapterResult.failure(
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
        errorMessage: e.toString(),
      );
    }
  }
  
  // 实现其他必需方法...
}

// 注册自定义适配器
final adapterManager = ImportExportAdapterManager();
adapterManager.registerAdapter(CustomV1ToV2Adapter());
```

## 错误处理

### 常见错误类型

1. **版本不兼容错误**
   ```dart
   ImportExportCompatibility.incompatible
   ```

2. **文件格式错误**
   ```dart
   ImportExportAdapterResult.failure(
     errorMessage: '无效的文件格式'
   )
   ```

3. **升级失败错误**
   ```dart
   ImportUpgradeResult.error('升级过程中发生错误')
   ```

### 错误处理最佳实践

```dart
try {
  final result = await upgradeService.performImportUpgrade(filePath, appVersion);
  
  switch (result.status) {
    case ImportUpgradeStatus.compatible:
      // 直接导入
      break;
    case ImportUpgradeStatus.upgraded:
      // 使用升级后的文件
      break;
    case ImportUpgradeStatus.appUpgradeRequired:
      // 提示用户升级应用
      break;
    case ImportUpgradeStatus.incompatible:
      // 显示不兼容错误
      break;
    case ImportUpgradeStatus.error:
      // 处理错误
      print('升级错误: ${result.errorMessage}');
      break;
  }
} catch (e) {
  // 处理异常
  print('升级异常: $e');
}
```

## 性能考虑

### 缓存机制

系统内置了多级缓存机制：

1. **版本映射缓存**: 缓存应用版本到数据版本的映射
2. **兼容性矩阵缓存**: 缓存版本兼容性检查结果
3. **适配器缓存**: 缓存已注册的适配器实例

### 性能优化建议

1. **批量处理**: 对于多个文件，使用批量处理API
2. **流式处理**: 对于大文件，使用流式处理避免内存溢出
3. **并发控制**: 合理控制并发升级任务数量
4. **资源清理**: 及时清理临时文件和缓存

## 配置选项

### 环境变量

```bash
# 启用调试日志
IMPORT_EXPORT_DEBUG=true

# 设置临时目录
IMPORT_EXPORT_TEMP_DIR=/tmp/import_export

# 设置最大并发数
IMPORT_EXPORT_MAX_CONCURRENT=3
```

### 配置文件

```yaml
import_export:
  version_management:
    cache_enabled: true
    cache_ttl: 3600  # 1小时
    temp_cleanup: true
    max_file_size: 104857600  # 100MB
  
  adapters:
    timeout: 30000  # 30秒
    retry_count: 3
    parallel_execution: true
```

## 扩展性

### 添加新版本

1. 在 `ImportExportDataVersionDefinition` 中添加新版本定义
2. 更新版本映射服务的映射表
3. 实现必要的适配器
4. 更新兼容性矩阵
5. 添加相应的测试用例

### 自定义适配器

继承 `ImportExportDataAdapter` 接口，实现自定义的数据转换逻辑。

### 插件系统

系统支持通过插件方式扩展功能：

```dart
abstract class ImportExportPlugin {
  String get name;
  String get version;
  
  Future<void> initialize();
  Future<void> dispose();
}
```
