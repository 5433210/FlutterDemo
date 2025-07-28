# 7zip压缩格式升级设计方案

## 1. 概述

将当前的ZIP压缩格式升级为7zip格式，提供更好的压缩率和内置完整性校验功能。

### 1.1 改进目标

- **更高压缩率**: 7zip通常比ZIP提供20-30%更好的压缩率
- **内置完整性校验**: 7zip格式自带CRC32和SHA256校验
- **统一文件扩展名**: 使用专用扩展名区分不同类型的导出文件
- **增强安全性**: 支持加密和数字签名（未来扩展）

### 1.2 新文件扩展名规范

| 文件类型 | 扩展名 | 命名格式 | 示例 |
|---------|--------|----------|------|
| 作品导出 | `.cgw` | `export_YYYYMMDD_HHMMSS.cgw` | `export_20241128_143052.cgw` |
| 集字导出 | `.cgc` | `export_YYYYMMDD_HHMMSS.cgc` | `export_20241128_143052.cgc` |
| 数据备份 | `.cgb` | `backup_YYYYMMDD_HHMMSS.cgb` | `backup_20241128_143052.cgb` |

## 2. 技术实现方案

### 2.1 7zip库选择

推荐使用 `archive` 包的7zip支持或集成专用的7zip库：

```yaml
dependencies:
  archive: ^3.4.10  # 支持7zip格式
  crypto: ^3.0.3    # 用于额外的校验算法
```

### 2.2 压缩格式升级

#### 2.2.1 ExportFormat枚举更新

```dart
enum ExportFormat {
  json,
  sevenZip,  // 新增7zip格式
  backup,    // 备份格式也使用7zip
}
```

#### 2.2.2 文件扩展名映射

```dart
String _getFileExtension(ExportFormat format, ExportType? type) {
  switch (format) {
    case ExportFormat.json:
      return 'json';
    case ExportFormat.sevenZip:
      return _getSevenZipExtension(type);
    case ExportFormat.backup:
      return 'cgb';
  }
}

String _getSevenZipExtension(ExportType? type) {
  switch (type) {
    case ExportType.worksOnly:
    case ExportType.worksWithCharacters:
      return 'cgw';
    case ExportType.charactersOnly:
    case ExportType.charactersWithWorks:
      return 'cgc';
    case ExportType.fullData:
      return 'cgw';  // 完整数据使用作品格式
    default:
      return 'cgw';
  }
}
```

### 2.3 文件命名格式

#### 2.3.1 时间戳格式

```dart
String _generateFileName(ExportFormat format, ExportType type) {
  final now = DateTime.now();
  final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
  final extension = _getFileExtension(format, type);
  
  final prefix = format == ExportFormat.backup ? 'backup' : 'export';
  return '${prefix}_${timestamp}.$extension';
}
```

## 3. 完整性校验实现

### 3.1 7zip内置校验

7zip格式自带多层校验：
- **CRC32**: 每个文件的循环冗余校验
- **SHA256**: 整个归档的哈希校验
- **结构校验**: 归档结构完整性验证

### 3.2 导入前校验流程

```dart
Future<bool> verify7zipIntegrity(String filePath) async {
  try {
    // 1. 基础文件存在性检查
    final file = File(filePath);
    if (!await file.exists()) return false;
    
    // 2. 7zip格式验证
    final bytes = await file.readAsBytes();
    if (!_is7zipFormat(bytes)) return false;
    
    // 3. 归档完整性校验
    final archive = SevenZipDecoder().decodeBytes(bytes);
    
    // 4. 验证每个文件的CRC
    for (final archiveFile in archive) {
      if (!_verifyCRC(archiveFile)) return false;
    }
    
    // 5. 验证归档整体哈希
    return _verifyArchiveHash(bytes);
    
  } catch (e) {
    AppLogger.error('7zip完整性校验失败', error: e);
    return false;
  }
}
```

### 3.3 校验失败处理

```dart
class IntegrityVerificationResult {
  final bool isValid;
  final List<String> errors;
  final Map<String, dynamic> details;
  
  const IntegrityVerificationResult({
    required this.isValid,
    this.errors = const [],
    this.details = const {},
  });
}
```

## 4. 向后兼容性

### 4.1 格式检测

```dart
enum ArchiveFormat {
  zip,
  sevenZip,
  unknown,
}

ArchiveFormat detectArchiveFormat(String filePath) {
  final extension = path.extension(filePath).toLowerCase();
  
  switch (extension) {
    case '.zip':
      return ArchiveFormat.zip;
    case '.cgw':
    case '.cgc':
    case '.cgb':
      return ArchiveFormat.sevenZip;
    default:
      // 通过文件头检测
      return _detectByHeader(filePath);
  }
}
```

### 4.2 兼容性处理

- **导入**: 同时支持旧的ZIP格式和新的7zip格式
- **导出**: 默认使用7zip格式，提供选项切换到ZIP
- **版本适配器**: 中间文件也使用7zip格式

## 5. 实施计划

### 5.1 阶段1: 基础设施
- [ ] 集成7zip压缩库
- [ ] 更新ExportFormat枚举
- [ ] 实现文件扩展名映射
- [ ] 创建7zip压缩/解压工具类

### 5.2 阶段2: 核心功能
- [ ] 更新导出服务支持7zip
- [ ] 更新备份服务支持7zip
- [ ] 实现完整性校验功能
- [ ] 更新文件命名逻辑

### 5.3 阶段3: 兼容性
- [ ] 更新导入服务支持双格式
- [ ] 更新版本适配器支持7zip
- [ ] 实现格式自动检测
- [ ] 添加格式转换工具

### 5.4 阶段4: 测试验证
- [ ] 单元测试覆盖
- [ ] 集成测试验证
- [ ] 性能对比测试
- [ ] 兼容性测试

## 6. 风险评估

### 6.1 技术风险
- **库依赖**: 7zip库的稳定性和维护状态
- **性能影响**: 压缩/解压时间可能增加
- **内存使用**: 7zip可能需要更多内存

### 6.2 兼容性风险
- **旧版本**: 需要确保旧ZIP文件仍可导入
- **第三方工具**: 用户可能无法直接解压.cgw/.cgc/.cgb文件

### 6.3 缓解措施
- **渐进式升级**: 保持ZIP格式作为备选
- **用户教育**: 提供文档说明新格式
- **工具支持**: 提供格式转换工具

## 7. 性能预期

### 7.1 压缩率改进
- **作品文件**: 预期压缩率提升20-30%
- **图片文件**: 预期压缩率提升15-25%
- **备份文件**: 预期压缩率提升25-35%

### 7.2 完整性保障
- **错误检测**: 99.99%的文件损坏可被检测
- **恢复能力**: 支持部分损坏文件的恢复
- **验证速度**: 校验时间增加<10%

## 8. 用户体验改进

### 8.1 文件识别
- **图标关联**: 为.cgw/.cgc/.cgb文件设计专用图标
- **文件描述**: 在文件属性中显示清晰的类型说明

### 8.2 错误处理
- **友好提示**: 当文件损坏时提供清晰的错误信息
- **修复建议**: 提供可能的修复方案或替代方案

## 9. 后续扩展

### 9.1 加密支持
- **密码保护**: 支持密码保护的7zip文件
- **数字签名**: 支持文件完整性的数字签名验证

### 9.2 云端集成
- **在线校验**: 支持云端完整性校验服务
- **增量备份**: 基于7zip的增量备份功能
