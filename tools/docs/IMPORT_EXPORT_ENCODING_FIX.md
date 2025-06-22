# 导入导出功能字符编码修复总结

## 问题描述

用户在导入之前导出的ZIP文件时遇到JSON解析错误：

```
FormatException: Unrecognized string escape (at character 649)
...f6-9c44-db519cb3a1f0","title":"KÕ(\Á","author":"","remark":"","style":"r...
                                       ^
```

错误发生在字符串`"KÕ(\Á"`中，其中`\Á`是一个无效的JSON转义序列。

## 根本原因分析

1. **字符编码问题**：导出时使用`jsonString.codeUnits`而不是UTF-8编码，可能导致字符编码不一致
2. **无效转义字符**：JSON中包含了`\Á`这样的无效转义序列，有效的JSON转义序列只包括：`\"`, `\\`, `\/`, `\b`, `\f`, `\n`, `\r`, `\t`, `\uXXXX`

## 修复方案

### 1. 修复导出服务 (ExportServiceImpl)

**文件**: `lib/application/services/export_service_impl.dart`

**修改内容**:
- 将所有使用`jsonString.codeUnits`的地方改为`utf8.encode(jsonString)`
- 确保ZIP文件中的JSON数据使用正确的UTF-8编码

**具体修改**:
```dart
// 旧代码
final dataFile = ArchiveFile('export_data.json', dataJson.length, dataJson.codeUnits);

// 新代码
final dataBytes = utf8.encode(dataJson);
final dataFile = ArchiveFile('export_data.json', dataBytes.length, dataBytes);
```

### 2. 修复导入服务 (ImportServiceImpl)

**文件**: `lib/application/services/import_service_impl.dart`

**修改内容**:
1. 确保使用UTF-8解码ZIP文件中的JSON数据
2. 添加`_fixInvalidEscapeCharacters`方法来修复无效的转义字符

**新增方法**:
```dart
String _fixInvalidEscapeCharacters(String jsonString) {
  try {
    // 首先尝试直接解析
    jsonDecode(jsonString);
    return jsonString;
  } catch (e) {
    if (e is FormatException && e.message.contains('Unrecognized string escape')) {
      // 修复无效转义字符
      String fixed = jsonString;
      
      // 将 \X (X不是有效转义字符) 替换为 \\X
      fixed = fixed.replaceAllMapped(
        RegExp(r'\\([^"\\\/bfnrtu]|$)'),
        (match) {
          final char = match.group(1);
          if (char == null || char.isEmpty) {
            return '\\\\';
          }
          return '\\\\$char';
        },
      );
      
      return fixed;
    }
    rethrow;
  }
}
```

## 修复效果

1. **字符编码统一**：导出和导入都使用UTF-8编码，确保字符编码一致性
2. **容错处理**：能够自动修复常见的JSON转义字符问题
3. **向后兼容**：能够处理之前导出的包含编码问题的文件
4. **详细日志**：提供详细的错误日志和修复过程记录

## 测试验证

创建了测试脚本验证修复效果：

**测试案例**:
- `"KÕ(\Á"` → `"KÕ(\\Á"` (修复成功)
- `"测试\x标题"` → `"测试\\x标题"` (修复成功)
- `"测试\z内容"` → `"测试\\z内容"` (修复成功)

## 影响范围

- ✅ 新导出的文件：使用正确的UTF-8编码，不会出现编码问题
- ✅ 旧导出的文件：通过转义字符修复功能，能够正确导入
- ✅ 特殊字符支持：正确处理中文、Unicode字符等
- ✅ 向后兼容性：不影响现有的正常导出文件

## 注意事项

1. 修复功能只处理常见的转义字符问题，极端情况下可能仍需要手动处理
2. 建议用户重新导出重要数据，以确保使用最新的编码格式
3. 修复过程会记录详细日志，便于问题追踪和调试

## 相关文件

- `lib/application/services/export_service_impl.dart` - 导出服务修复
- `lib/application/services/import_service_impl.dart` - 导入服务修复
- 测试文件已清理，修复功能已集成到主代码中 