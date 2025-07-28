# 导入导出版本管理集成指南

## 概述

本指南详细说明如何将导入导出版本管理系统集成到现有的Flutter应用中，包括服务配置、UI集成、错误处理等方面。

## 快速开始

### 1. 依赖配置

确保在 `pubspec.yaml` 中包含必要的依赖：

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.9
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  archive: ^3.4.9

dev_dependencies:
  build_runner: ^2.4.7
  freezed: ^2.4.6
  json_serializable: ^6.7.1
```

### 2. 服务注册

在应用启动时注册版本管理服务：

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化版本管理服务
  final upgradeService = UnifiedImportExportUpgradeService();
  await upgradeService.initialize();
  
  runApp(
    ProviderScope(
      overrides: [
        // 注册服务提供者
        unifiedImportExportUpgradeServiceProvider.overrideWithValue(upgradeService),
      ],
      child: MyApp(),
    ),
  );
}
```

### 3. 提供者配置

创建Riverpod提供者：

```dart
// lib/presentation/providers/import_export_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final unifiedImportExportUpgradeServiceProvider = 
    Provider<UnifiedImportExportUpgradeService>((ref) {
  throw UnimplementedError('需要在main.dart中覆盖此提供者');
});

final importExportAdapterManagerProvider = 
    Provider<ImportExportAdapterManager>((ref) {
  return ImportExportAdapterManager();
});

final importExportVersionMappingProvider = 
    Provider<ImportExportVersionMappingService>((ref) {
  return ImportExportVersionMappingService();
});
```

## 服务集成

### 1. 导入服务集成

更新现有的导入服务以支持版本管理：

```dart
// lib/application/services/import_service_impl.dart
class ImportServiceImpl implements ImportService {
  final UnifiedImportExportUpgradeService _upgradeService;
  
  ImportServiceImpl(this._upgradeService);
  
  @override
  Future<ImportResult> importData(String filePath, ImportOptions options) async {
    try {
      // 1. 验证文件
      final isValid = await _upgradeService.validateFile(filePath);
      if (!isValid) {
        return ImportResult.error('文件格式无效');
      }
      
      // 2. 检查版本兼容性
      const currentAppVersion = '1.3.0'; // 从配置获取
      final compatibility = await _upgradeService.checkImportCompatibility(
        filePath, currentAppVersion);
      
      // 3. 处理不同兼容性情况
      switch (compatibility) {
        case ImportExportCompatibility.incompatible:
          return ImportResult.error('文件版本不兼容');
          
        case ImportExportCompatibility.appUpgradeRequired:
          return ImportResult.error('需要升级应用版本');
          
        case ImportExportCompatibility.upgradable:
          // 执行升级
          final upgradeResult = await _upgradeService.performImportUpgrade(
            filePath, currentAppVersion);
          
          if (upgradeResult.status != ImportUpgradeStatus.upgraded) {
            return ImportResult.error('版本升级失败: ${upgradeResult.errorMessage}');
          }
          
          // 使用升级后的文件
          filePath = upgradeResult.upgradedFilePath!;
          break;
          
        case ImportExportCompatibility.compatible:
          // 直接处理
          break;
      }
      
      // 4. 执行实际导入
      return await _performActualImport(filePath, options);
      
    } catch (e) {
      return ImportResult.error('导入失败: $e');
    }
  }
  
  Future<ImportResult> _performActualImport(String filePath, ImportOptions options) async {
    // 实现实际的导入逻辑
    // ...
  }
}
```

### 2. 导出服务集成

更新导出服务以包含版本信息：

```dart
// lib/application/services/export_service_impl.dart
class ExportServiceImpl implements ExportService {
  @override
  Future<ExportResult> exportData(List<String> selectedIds, ExportOptions options) async {
    try {
      // 1. 获取当前版本信息
      const currentAppVersion = '1.3.0';
      final dataVersion = ImportExportVersionMappingService.getDataVersionForApp(
        currentAppVersion);
      
      // 2. 创建导出元数据
      final metadata = ExportMetadata(
        version: '1.0',
        platform: 'flutter',
        exportTime: DateTime.now(),
        options: options,
        exportType: _determineExportType(selectedIds),
        appVersion: currentAppVersion,
        dataFormatVersion: dataVersion,
        compatibility: const CompatibilityInfo(
          minSupportedVersion: '1.0.0',
          recommendedVersion: '1.3.0',
        ),
      );
      
      // 3. 执行导出
      return await _performActualExport(selectedIds, options, metadata);
      
    } catch (e) {
      return ExportResult.error('导出失败: $e');
    }
  }
}
```

## UI集成

### 1. 导入对话框集成

使用增强的导入对话框：

```dart
// lib/presentation/pages/works/works_page.dart
class WorksPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // ... 其他UI组件
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showImportDialog(context),
        child: Icon(Icons.file_download),
      ),
    );
  }
  
  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ImportDialogWithVersion(
        pageType: PageType.works,
        onImport: (options, filePath) async {
          // 处理导入
          final importService = ref.read(importServiceProvider);
          final result = await importService.importData(filePath, options);
          
          if (result.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('导入成功')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('导入失败: ${result.errorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}
```

### 2. 导出对话框集成

```dart
void _showExportDialog(BuildContext context, List<String> selectedIds) {
  showDialog(
    context: context,
    builder: (context) => ExportDialogWithVersion(
      pageType: PageType.works,
      selectedIds: selectedIds,
      onExport: (options, targetPath) async {
        final exportService = ref.read(exportServiceProvider);
        final result = await exportService.exportData(selectedIds, options);
        
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('导出成功: $targetPath')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('导出失败: ${result.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    ),
  );
}
```

### 3. 版本兼容性状态显示

创建版本状态指示器组件：

```dart
// lib/presentation/widgets/version_compatibility_indicator.dart
class VersionCompatibilityIndicator extends StatelessWidget {
  final ImportExportCompatibility compatibility;
  final String? sourceVersion;
  final String? targetVersion;
  
  const VersionCompatibilityIndicator({
    Key? key,
    required this.compatibility,
    this.sourceVersion,
    this.targetVersion,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor() {
    switch (compatibility) {
      case ImportExportCompatibility.compatible:
        return Colors.green;
      case ImportExportCompatibility.upgradable:
        return Colors.orange;
      case ImportExportCompatibility.appUpgradeRequired:
        return Colors.blue;
      case ImportExportCompatibility.incompatible:
        return Colors.red;
    }
  }
  
  IconData _getStatusIcon() {
    switch (compatibility) {
      case ImportExportCompatibility.compatible:
        return Icons.check_circle;
      case ImportExportCompatibility.upgradable:
        return Icons.upgrade;
      case ImportExportCompatibility.appUpgradeRequired:
        return Icons.system_update;
      case ImportExportCompatibility.incompatible:
        return Icons.error;
    }
  }
  
  String _getStatusText() {
    switch (compatibility) {
      case ImportExportCompatibility.compatible:
        return '兼容';
      case ImportExportCompatibility.upgradable:
        return '可升级';
      case ImportExportCompatibility.appUpgradeRequired:
        return '需要升级应用';
      case ImportExportCompatibility.incompatible:
        return '不兼容';
    }
  }
}
```

## 错误处理和日志

### 1. 错误处理策略

```dart
// lib/application/services/error_handling_service.dart
class ImportExportErrorHandler {
  static ImportResult handleImportError(dynamic error, StackTrace stackTrace) {
    // 记录错误日志
    AppLogger.error(
      '导入操作失败',
      error: error,
      stackTrace: stackTrace,
      tag: 'import_export',
    );
    
    // 根据错误类型返回用户友好的错误信息
    if (error is FileSystemException) {
      return ImportResult.error('文件访问失败，请检查文件权限');
    } else if (error is FormatException) {
      return ImportResult.error('文件格式错误，请选择有效的导出文件');
    } else if (error is VersionIncompatibilityException) {
      return ImportResult.error('文件版本不兼容，请升级应用或使用兼容的文件');
    } else {
      return ImportResult.error('导入失败，请重试或联系技术支持');
    }
  }
  
  static ExportResult handleExportError(dynamic error, StackTrace stackTrace) {
    AppLogger.error(
      '导出操作失败',
      error: error,
      stackTrace: stackTrace,
      tag: 'import_export',
    );
    
    if (error is FileSystemException) {
      return ExportResult.error('文件保存失败，请检查存储空间和权限');
    } else if (error is OutOfMemoryError) {
      return ExportResult.error('内存不足，请减少导出数据量或重启应用');
    } else {
      return ExportResult.error('导出失败，请重试或联系技术支持');
    }
  }
}
```

### 2. 日志配置

```dart
// lib/infrastructure/logging/import_export_logger.dart
class ImportExportLogger {
  static void logVersionCheck(String filePath, String detectedVersion, 
      ImportExportCompatibility compatibility) {
    AppLogger.info(
      '版本兼容性检查',
      data: {
        'filePath': filePath,
        'detectedVersion': detectedVersion,
        'compatibility': compatibility.name,
      },
      tag: 'version_check',
    );
  }
  
  static void logUpgradeStart(String sourceVersion, String targetVersion) {
    AppLogger.info(
      '开始版本升级',
      data: {
        'sourceVersion': sourceVersion,
        'targetVersion': targetVersion,
      },
      tag: 'version_upgrade',
    );
  }
  
  static void logUpgradeComplete(UpgradeChainResult result) {
    AppLogger.info(
      '版本升级完成',
      data: {
        'success': result.isSuccess,
        'executedAdapters': result.executedAdapters,
        'sourceVersion': result.sourceVersion,
        'targetVersion': result.targetVersion,
        'outputFilePath': result.outputFilePath,
      },
      tag: 'version_upgrade',
    );
  }
}
```

## 测试集成

### 1. 单元测试

```dart
// test/application/services/import_service_test.dart
void main() {
  group('ImportService Version Management Tests', () {
    late ImportServiceImpl importService;
    late MockUnifiedImportExportUpgradeService mockUpgradeService;
    
    setUp(() {
      mockUpgradeService = MockUnifiedImportExportUpgradeService();
      importService = ImportServiceImpl(mockUpgradeService);
    });
    
    test('should handle compatible file import', () async {
      // 安排
      when(mockUpgradeService.validateFile(any)).thenAnswer((_) async => true);
      when(mockUpgradeService.checkImportCompatibility(any, any))
          .thenAnswer((_) async => ImportExportCompatibility.compatible);
      
      // 执行
      final result = await importService.importData('/test/file.zip', ImportOptions());
      
      // 验证
      expect(result.isSuccess, isTrue);
      verify(mockUpgradeService.validateFile('/test/file.zip')).called(1);
      verify(mockUpgradeService.checkImportCompatibility('/test/file.zip', '1.3.0')).called(1);
    });
    
    test('should handle upgradable file import', () async {
      // 安排
      when(mockUpgradeService.validateFile(any)).thenAnswer((_) async => true);
      when(mockUpgradeService.checkImportCompatibility(any, any))
          .thenAnswer((_) async => ImportExportCompatibility.upgradable);
      when(mockUpgradeService.performImportUpgrade(any, any))
          .thenAnswer((_) async => ImportUpgradeResult.upgraded(
            sourceVersion: 'ie_v1',
            targetVersion: 'ie_v4',
            upgradedFilePath: '/test/upgraded_file.zip',
          ));
      
      // 执行
      final result = await importService.importData('/test/file.zip', ImportOptions());
      
      // 验证
      expect(result.isSuccess, isTrue);
      verify(mockUpgradeService.performImportUpgrade('/test/file.zip', '1.3.0')).called(1);
    });
  });
}
```

### 2. 集成测试

```dart
// test/integration/import_export_integration_test.dart
void main() {
  group('Import/Export Integration Tests', () {
    testWidgets('should show version compatibility in import dialog', (tester) async {
      // 构建应用
      await tester.pumpWidget(TestApp());
      
      // 打开导入对话框
      await tester.tap(find.byIcon(Icons.file_download));
      await tester.pumpAndSettle();
      
      // 验证版本兼容性指示器存在
      expect(find.byType(VersionCompatibilityIndicator), findsOneWidget);
      
      // 选择文件
      await tester.tap(find.text('选择文件'));
      await tester.pumpAndSettle();
      
      // 验证兼容性状态更新
      expect(find.text('兼容'), findsOneWidget);
    });
  });
}
```

## 性能优化

### 1. 缓存配置

```dart
// lib/infrastructure/cache/version_cache.dart
class VersionCache {
  static final Map<String, ImportExportCompatibility> _compatibilityCache = {};
  static final Map<String, String> _versionMappingCache = {};
  
  static ImportExportCompatibility? getCachedCompatibility(String key) {
    return _compatibilityCache[key];
  }
  
  static void cacheCompatibility(String key, ImportExportCompatibility compatibility) {
    _compatibilityCache[key] = compatibility;
  }
  
  static void clearCache() {
    _compatibilityCache.clear();
    _versionMappingCache.clear();
  }
}
```

### 2. 异步处理

```dart
// 使用Isolate进行大文件处理
Future<ImportResult> _processLargeFileInIsolate(String filePath) async {
  final result = await compute(_processFileInBackground, filePath);
  return result;
}

static ImportResult _processFileInBackground(String filePath) {
  // 在后台Isolate中处理文件
  // ...
}
```

## 部署和配置

### 1. 环境配置

```yaml
# config/app_config.yaml
import_export:
  version_management:
    enabled: true
    cache_enabled: true
    max_file_size: 104857600  # 100MB
    temp_directory: "/tmp/import_export"
    
  adapters:
    timeout_seconds: 30
    retry_count: 3
    parallel_execution: true
    
  logging:
    level: "info"
    enable_performance_logging: true
```

### 2. 生产环境优化

```dart
// lib/config/production_config.dart
class ProductionConfig {
  static const bool enableDebugLogging = false;
  static const int maxConcurrentUpgrades = 2;
  static const Duration upgradeTimeout = Duration(minutes: 5);
  static const int maxCacheSize = 1000;
}
```

## 故障排除

### 常见问题和解决方案

1. **版本检测失败**
   - 检查文件格式是否正确
   - 验证文件是否损坏
   - 确认文件包含必要的元数据

2. **升级过程失败**
   - 检查磁盘空间是否充足
   - 验证文件权限
   - 查看详细错误日志

3. **性能问题**
   - 启用缓存机制
   - 减少并发处理数量
   - 使用流式处理大文件

4. **内存不足**
   - 分批处理大量数据
   - 及时清理临时文件
   - 使用Isolate处理大文件

### 调试工具

```dart
// lib/debug/import_export_debugger.dart
class ImportExportDebugger {
  static void enableDebugMode() {
    // 启用详细日志
    // 显示性能指标
    // 保留临时文件用于调试
  }
  
  static void dumpVersionInfo() {
    // 输出所有版本信息
    // 显示兼容性矩阵
    // 列出已注册的适配器
  }
}
```
