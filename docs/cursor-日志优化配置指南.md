# Cursor 日志优化配置指南

## 🎯 配置目标
确保 Cursor AI 助手在编写和修改代码时自动遵循项目的通用日志优化原则和字帖编辑页专用规范。

## 📋 已配置的功能

### 1. 项目规则文件 (`.cursorrules`)
- 定义了通用日志优化规范和字帖编辑页专用规范
- 禁止使用 `debugPrint`、`print` 和 `log`
- 字帖编辑页组件使用 `EditPageLogger` 扩展方法
- 其他模块使用 `logger` 实例的结构化日志方法
- 规定了结构化数据格式和标签分类规范

### 2. VSCode/Cursor 设置 (`.vscode/settings.json`)
```json
{
  "cursor.ai.instructions": [
    "始终遵循 .cursorrules 文件中定义的日志优化原则",
    "禁止使用 debugPrint、print 和 log，必须使用结构化日志方法",
    "字帖编辑页组件使用 EditPageLogger 扩展方法",
    "其他模块组件使用 logger 实例的结构化日志，必须包含 tags 参数",
    "所有日志调用必须包含结构化的 data 参数和 operation 字段"
  ]
}
```

### 3. 代码片段 (`.vscode/dart.json`)
快速输入快捷键：

**字帖编辑页专用：**
- `epd` → EditPageLogger 调试日志
- `epi` → EditPageLogger 信息日志  
- `epe` → EditPageLogger 错误日志
- `ctd` → 控制器调试日志
- `cvd` → 画布调试日志
- `pfi` → 性能信息日志
- `impl` → 导入 EditPageLogger

**通用模块：**
- `logi` → Logger 信息日志
- `logd` → Logger 调试日志
- `logw` → Logger 警告日志
- `loge` → Logger 错误日志
- `lognet` → 网络请求日志
- `logui` → UI交互日志
- `imlog` → 导入通用 Logger

### 4. 检查任务 (`.vscode/tasks.json`)
- `检查非规范日志调用` - 搜索项目中的 debugPrint/print/log 使用
- `检查缺少tags的日志调用` - 检查通用模块中缺少 tags 的日志
- `检查敏感数据泄露` - 检查日志中可能的敏感信息
- `统计日志优化进度` - 显示优化完成百分比

## 🚀 使用方法

### 日常开发
1. 字帖编辑页组件：输入 `epd`、`epi` 等使用 EditPageLogger
2. 其他模块：输入 `logi`、`lognet` 等使用通用 Logger + tags
3. Cursor 会自动提示正确的日志方法和结构化参数
4. AI 助手会根据模块类型建议合适的标签

### 代码审查
1. 运行 `检查非规范日志调用` - 发现 debugPrint/print/log 使用
2. 运行 `检查缺少tags的日志调用` - 发现通用模块缺少标签
3. 运行 `检查敏感数据泄露` - 发现可能的敏感信息泄露

### 进度跟踪
1. 运行 `Tasks: Run Task` → `统计日志优化进度`
2. 查看当前优化完成率

## 📝 最佳实践

### 向 Cursor 提示时
**字帖编辑页组件：**
```
请帮我添加日志记录，使用项目的 EditPageLogger 规范
```

**通用模块组件：**
```
请帮我添加日志记录，使用 logger 实例的结构化日志，包含适当的 tags
```

### 重构现有代码时
```
请将这个文件中的所有原始日志调用替换为结构化日志，遵循 .cursorrules 规范
```

### 新功能开发时
```
请为这个功能添加完整的日志记录，根据模块类型使用正确的日志方法和标签
```

## 🔧 自定义配置

### 添加新的日志方法
在 `.vscode/dart.json` 中添加新的代码片段：
```json
"新日志类型": {
  "prefix": "缩写",
  "body": ["EditPageLogger.新方法(...)"],
  "description": "描述"
}
```

### 修改规则
编辑 `.cursorrules` 文件添加特定于组件的规则。

## ⚠️ 注意事项

1. **重启 Cursor** 后配置才会生效
2. **团队同步** - 确保所有开发者都有相同的配置文件
3. **定期检查** - 运行检查任务确保没有遗漏的日志调用
4. **AI 指导** - 在复杂重构时明确告诉 Cursor 要遵循日志规范

## 📊 配置效果

配置后，Cursor 将：
- ✅ 根据模块类型自动建议正确的日志方法
- ✅ 字帖编辑页使用 EditPageLogger，其他模块使用 logger + tags
- ✅ 提供结构化数据格式模板和标签建议
- ✅ 阻止使用 debugPrint/print/log 等原始方法
- ✅ 自动导入必要的依赖
- ✅ 提供代码片段快速输入
- ✅ 检查敏感数据泄露和缺失标签
- ✅ 统一项目的日志规范和质量 