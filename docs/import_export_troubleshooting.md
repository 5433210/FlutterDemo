# 导入导出故障排除指南

## 概述

本文档提供导入导出功能常见问题的诊断和解决方案，帮助开发者和用户快速解决技术问题。

## 常见错误类型

### 🔴 版本兼容性错误

#### 错误信息：`ImportExportCompatibility.incompatible`

**症状：**
- 导入对话框显示红色"不兼容"状态
- 无法进行导入操作
- 错误日志显示版本不匹配

**原因分析：**
1. 导入文件由更新版本的应用创建
2. 文件格式已过时且无法升级
3. 文件损坏导致版本检测失败

**解决方案：**

```bash
# 1. 检查应用版本
flutter --version
# 确保使用最新版本

# 2. 验证文件完整性
file import_file.zip
unzip -t import_file.zip

# 3. 查看详细错误信息
grep "version" logs/import_export.log
```

**代码修复：**
```dart
// 添加更详细的版本检查日志
Future<ImportExportCompatibility> checkCompatibility(String filePath) async {
  try {
    final version = await detectFileVersion(filePath);
    AppLogger.debug('检测到文件版本: $version');
    
    final compatibility = ImportExportVersionMappingService.checkCompatibility(
      version, getCurrentDataVersion());
    
    AppLogger.info('兼容性检查结果: ${compatibility.name}');
    return compatibility;
  } catch (e) {
    AppLogger.error('版本检查失败', error: e);
    return ImportExportCompatibility.incompatible;
  }
}
```

#### 错误信息：`需要升级应用版本`

**解决方案：**
1. 升级应用到最新版本
2. 或请文件创建者使用兼容版本重新导出

### 🟠 文件格式错误

#### 错误信息：`无效的文件格式`

**症状：**
- 文件选择后无法识别
- ZIP文件解压失败
- JSON解析错误

**诊断步骤：**

```bash
# 1. 检查文件类型
file -b import_file.zip
# 应该显示: Zip archive data

# 2. 检查ZIP文件结构
unzip -l import_file.zip
# 应该包含: export_data.json, metadata.json

# 3. 验证JSON格式
jq . export_data.json
# 检查JSON语法是否正确
```

**修复方法：**

```dart
// 增强文件验证逻辑
Future<bool> validateFileFormat(String filePath) async {
  try {
    if (filePath.endsWith('.zip')) {
      return await _validateZipFile(filePath);
    } else if (filePath.endsWith('.json')) {
      return await _validateJsonFile(filePath);
    }
    return false;
  } catch (e) {
    AppLogger.error('文件格式验证失败', error: e);
    return false;
  }
}

Future<bool> _validateZipFile(String filePath) async {
  final file = File(filePath);
  final bytes = await file.readAsBytes();
  
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    
    // 检查必需文件
    final requiredFiles = ['export_data.json', 'metadata.json'];
    for (final required in requiredFiles) {
      if (!archive.any((f) => f.name == required)) {
        AppLogger.warning('缺少必需文件: $required');
        return false;
      }
    }
    
    return true;
  } catch (e) {
    AppLogger.error('ZIP文件验证失败', error: e);
    return false;
  }
}
```

### ⚡ 性能问题

#### 错误信息：`内存不足` / `处理超时`

**症状：**
- 大文件导入时应用崩溃
- 处理过程中界面卡顿
- 内存使用量持续增长

**性能监控：**

```dart
// 添加性能监控
class PerformanceMonitor {
  static final Stopwatch _stopwatch = Stopwatch();
  static int _initialMemory = 0;
  
  static void startMonitoring() {
    _stopwatch.start();
    _initialMemory = _getCurrentMemoryUsage();
    AppLogger.info('开始性能监控', data: {
      'initialMemory': _formatBytes(_initialMemory),
    });
  }
  
  static void logProgress(String operation, int progress) {
    final currentMemory = _getCurrentMemoryUsage();
    final memoryIncrease = currentMemory - _initialMemory;
    
    AppLogger.info('操作进度', data: {
      'operation': operation,
      'progress': '$progress%',
      'elapsedTime': '${_stopwatch.elapsedMilliseconds}ms',
      'memoryUsage': _formatBytes(currentMemory),
      'memoryIncrease': _formatBytes(memoryIncrease),
    });
  }
  
  static void stopMonitoring() {
    _stopwatch.stop();
    final finalMemory = _getCurrentMemoryUsage();
    
    AppLogger.info('性能监控结束', data: {
      'totalTime': '${_stopwatch.elapsedMilliseconds}ms',
      'finalMemory': _formatBytes(finalMemory),
      'memoryIncrease': _formatBytes(finalMemory - _initialMemory),
    });
  }
}
```

**优化方案：**

```dart
// 流式处理大文件
Future<ImportResult> processLargeFile(String filePath) async {
  const chunkSize = 1024 * 1024; // 1MB chunks
  
  try {
    final file = File(filePath);
    final fileSize = await file.length();
    
    if (fileSize > 50 * 1024 * 1024) { // > 50MB
      return await _processFileInChunks(file, chunkSize);
    } else {
      return await _processFileNormally(file);
    }
  } catch (e) {
    return ImportResult.error('文件处理失败: $e');
  }
}

Future<ImportResult> _processFileInChunks(File file, int chunkSize) async {
  final stream = file.openRead();
  final chunks = <List<int>>[];
  
  await for (final chunk in stream) {
    chunks.add(chunk);
    
    // 定期清理内存
    if (chunks.length > 100) {
      await _processChunks(chunks);
      chunks.clear();
    }
  }
  
  // 处理剩余chunks
  if (chunks.isNotEmpty) {
    await _processChunks(chunks);
  }
  
  return ImportResult.success();
}
```

### 🔧 数据完整性问题

#### 错误信息：`数据验证失败`

**症状：**
- 导入后数据不完整
- 关联关系丢失
- 图片文件缺失

**数据验证增强：**

```dart
class DataIntegrityValidator {
  static Future<ValidationResult> validateImportData(ExportDataModel data) async {
    final issues = <ValidationIssue>[];
    
    // 1. 检查数据完整性
    issues.addAll(await _validateDataCompleteness(data));
    
    // 2. 检查关联关系
    issues.addAll(await _validateRelationships(data));
    
    // 3. 检查文件引用
    issues.addAll(await _validateFileReferences(data));
    
    return ValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
    );
  }
  
  static Future<List<ValidationIssue>> _validateDataCompleteness(ExportDataModel data) async {
    final issues = <ValidationIssue>[];
    
    // 检查必需字段
    if (data.works.isEmpty && data.characters.isEmpty) {
      issues.add(ValidationIssue.error('导入数据为空'));
    }
    
    // 检查数据格式
    for (final work in data.works) {
      if (work.id.isEmpty) {
        issues.add(ValidationIssue.warning('作品ID为空: ${work.name}'));
      }
    }
    
    return issues;
  }
  
  static Future<List<ValidationIssue>> _validateRelationships(ExportDataModel data) async {
    final issues = <ValidationIssue>[];
    final workIds = data.works.map((w) => w.id).toSet();
    
    // 检查字符关联的作品是否存在
    for (final character in data.characters) {
      if (!workIds.contains(character.workId)) {
        issues.add(ValidationIssue.error(
          '字符关联的作品不存在: ${character.id} -> ${character.workId}'
        ));
      }
    }
    
    return issues;
  }
}
```

## 调试工具

### 日志分析工具

```dart
// 日志分析器
class LogAnalyzer {
  static Future<List<LogEntry>> analyzeImportExportLogs() async {
    final logFile = File('logs/import_export.log');
    if (!await logFile.exists()) {
      return [];
    }
    
    final lines = await logFile.readAsLines();
    final entries = <LogEntry>[];
    
    for (final line in lines) {
      if (line.contains('ERROR') || line.contains('WARNING')) {
        entries.add(LogEntry.fromLine(line));
      }
    }
    
    return entries;
  }
  
  static void generateDiagnosticReport() {
    final report = DiagnosticReport()
      ..addSection('系统信息', _getSystemInfo())
      ..addSection('版本信息', _getVersionInfo())
      ..addSection('错误日志', _getErrorLogs())
      ..addSection('性能指标', _getPerformanceMetrics());
    
    report.saveToFile('diagnostic_report.txt');
  }
}
```

### 性能分析工具

```dart
// 性能分析器
class PerformanceProfiler {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, int> _counters = {};
  
  static void startTimer(String name) {
    _timers[name] = Stopwatch()..start();
  }
  
  static void stopTimer(String name) {
    final timer = _timers[name];
    if (timer != null) {
      timer.stop();
      AppLogger.info('性能计时', data: {
        'operation': name,
        'duration': '${timer.elapsedMilliseconds}ms',
      });
    }
  }
  
  static void incrementCounter(String name) {
    _counters[name] = (_counters[name] ?? 0) + 1;
  }
  
  static void generatePerformanceReport() {
    final report = StringBuffer();
    report.writeln('=== 性能分析报告 ===');
    
    report.writeln('\n计时器:');
    _timers.forEach((name, timer) {
      report.writeln('  $name: ${timer.elapsedMilliseconds}ms');
    });
    
    report.writeln('\n计数器:');
    _counters.forEach((name, count) {
      report.writeln('  $name: $count');
    });
    
    File('performance_report.txt').writeAsStringSync(report.toString());
  }
}
```

## 环境特定问题

### Windows平台

**文件路径问题：**
```dart
// 处理Windows路径分隔符
String normalizePath(String path) {
  if (Platform.isWindows) {
    return path.replaceAll('/', '\\');
  }
  return path;
}

// 处理长路径问题
Future<bool> checkPathLength(String path) async {
  if (Platform.isWindows && path.length > 260) {
    AppLogger.warning('路径过长，可能导致问题: $path');
    return false;
  }
  return true;
}
```

**权限问题：**
```dart
// 检查文件权限
Future<bool> checkFilePermissions(String filePath) async {
  try {
    final file = File(filePath);
    
    // 检查读权限
    if (!await file.exists()) {
      return false;
    }
    
    // 尝试读取文件
    await file.readAsBytes();
    
    return true;
  } catch (e) {
    AppLogger.error('权限检查失败', error: e);
    return false;
  }
}
```

### macOS/Linux平台

**文件系统大小写敏感：**
```dart
// 处理大小写敏感问题
Future<String?> findFileIgnoreCase(String directory, String fileName) async {
  final dir = Directory(directory);
  if (!await dir.exists()) {
    return null;
  }
  
  await for (final entity in dir.list()) {
    if (entity is File) {
      final name = path.basename(entity.path);
      if (name.toLowerCase() == fileName.toLowerCase()) {
        return entity.path;
      }
    }
  }
  
  return null;
}
```

## 自动化诊断

### 健康检查脚本

```dart
// 系统健康检查
class SystemHealthChecker {
  static Future<HealthCheckResult> performHealthCheck() async {
    final results = <String, bool>{};
    
    // 检查存储空间
    results['storage'] = await _checkStorageSpace();
    
    // 检查内存使用
    results['memory'] = await _checkMemoryUsage();
    
    // 检查文件权限
    results['permissions'] = await _checkFilePermissions();
    
    // 检查网络连接
    results['network'] = await _checkNetworkConnection();
    
    // 检查服务状态
    results['services'] = await _checkServiceStatus();
    
    return HealthCheckResult(results);
  }
  
  static Future<bool> _checkStorageSpace() async {
    // 检查可用存储空间是否足够
    const minRequiredSpace = 100 * 1024 * 1024; // 100MB
    
    try {
      final tempDir = Directory.systemTemp;
      final stat = await tempDir.stat();
      // 注意：这里需要使用平台特定的API获取磁盘空间
      return true; // 简化实现
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> _checkMemoryUsage() async {
    // 检查内存使用是否正常
    final currentMemory = _getCurrentMemoryUsage();
    const maxMemoryThreshold = 500 * 1024 * 1024; // 500MB
    
    return currentMemory < maxMemoryThreshold;
  }
}
```

### 自动修复工具

```dart
// 自动修复工具
class AutoRepairTool {
  static Future<RepairResult> attemptAutoRepair(String issue) async {
    switch (issue) {
      case 'corrupted_cache':
        return await _clearCache();
      case 'invalid_temp_files':
        return await _cleanTempFiles();
      case 'permission_denied':
        return await _fixPermissions();
      default:
        return RepairResult.notSupported(issue);
    }
  }
  
  static Future<RepairResult> _clearCache() async {
    try {
      final cacheDir = Directory('cache/import_export');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      return RepairResult.success('缓存已清理');
    } catch (e) {
      return RepairResult.failed('清理缓存失败: $e');
    }
  }
  
  static Future<RepairResult> _cleanTempFiles() async {
    try {
      final tempDir = Directory.systemTemp;
      final importExportTemp = Directory('${tempDir.path}/import_export');
      
      if (await importExportTemp.exists()) {
        await importExportTemp.delete(recursive: true);
      }
      
      return RepairResult.success('临时文件已清理');
    } catch (e) {
      return RepairResult.failed('清理临时文件失败: $e');
    }
  }
}
```

## 预防措施

### 定期维护

```dart
// 定期维护任务
class MaintenanceScheduler {
  static void scheduleRegularMaintenance() {
    Timer.periodic(Duration(hours: 24), (timer) {
      _performDailyMaintenance();
    });
    
    Timer.periodic(Duration(days: 7), (timer) {
      _performWeeklyMaintenance();
    });
  }
  
  static Future<void> _performDailyMaintenance() async {
    // 清理临时文件
    await AutoRepairTool._cleanTempFiles();
    
    // 压缩日志文件
    await _compressOldLogs();
    
    // 验证缓存完整性
    await _validateCache();
  }
  
  static Future<void> _performWeeklyMaintenance() async {
    // 完整的健康检查
    await SystemHealthChecker.performHealthCheck();
    
    // 生成诊断报告
    LogAnalyzer.generateDiagnosticReport();
    
    // 清理过期缓存
    await _clearExpiredCache();
  }
}
```

### 监控和告警

```dart
// 监控系统
class MonitoringSystem {
  static void startMonitoring() {
    // 监控内存使用
    Timer.periodic(Duration(minutes: 5), (timer) {
      _checkMemoryUsage();
    });
    
    // 监控错误率
    Timer.periodic(Duration(minutes: 1), (timer) {
      _checkErrorRate();
    });
  }
  
  static void _checkMemoryUsage() {
    final currentMemory = _getCurrentMemoryUsage();
    const warningThreshold = 400 * 1024 * 1024; // 400MB
    const criticalThreshold = 600 * 1024 * 1024; // 600MB
    
    if (currentMemory > criticalThreshold) {
      _sendAlert('内存使用过高', AlertLevel.critical);
    } else if (currentMemory > warningThreshold) {
      _sendAlert('内存使用警告', AlertLevel.warning);
    }
  }
  
  static void _sendAlert(String message, AlertLevel level) {
    AppLogger.error('系统告警', data: {
      'message': message,
      'level': level.name,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // 可以添加更多告警渠道，如推送通知等
  }
}
```

---

**文档版本：** 1.0  
**最后更新：** 2024-01-15  
**维护者：** 开发团队
