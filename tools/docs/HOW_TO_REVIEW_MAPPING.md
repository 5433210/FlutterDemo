# 映射文件审核示例 - 实际操作指南

## 🔍 原始检测结果示例

```yaml
ui_text_mappings:
  error_messages:
    common_error_练习不存在:
      text_zh: "练习不存在"
      text_en: "练习不存在"          # ⚠️ 需要改为英文
      file: "application/repositories/practice_repository_impl.dart"
      line: 48
      approved: false              # ⚠️ 需要改为 true

  ui_text_widget:
    works_text_添加作品:
      text_zh: "添加作品"
      text_en: "添加作品"          # ⚠️ 需要改为英文
      file: "presentation/pages/works/work_add_page.dart"
      line: 25
      approved: false              # ⚠️ 需要改为 true
```

## ✏️ 审核后的结果

```yaml
ui_text_mappings:
  error_messages:
    common_error_练习不存在:
      text_zh: "练习不存在"
      text_en: "Practice not found"  # ✅ 已修改为英文
      file: "application/repositories/practice_repository_impl.dart"
      line: 48
      approved: true                # ✅ 已确认处理

  ui_text_widget:
    works_text_添加作品:
      text_zh: "添加作品"
      text_en: "Add Work"           # ✅ 已修改为英文
      file: "presentation/pages/works/work_add_page.dart"
      line: 25
      approved: true                # ✅ 已确认处理
```

## 📝 审核要点

### 1. 修改英文翻译
- 将 `text_en` 字段从中文改为准确的英文翻译
- 考虑UI界面的空间限制
- 保持专业术语的一致性

### 2. 确认处理标志
- 将 `approved` 从 `false` 改为 `true`
- 只有设置为 `true` 的条目才会被处理

### 3. 常见翻译参考
```
添加 → Add
删除 → Delete
编辑 → Edit
保存 → Save
取消 → Cancel
确认 → Confirm
错误 → Error
警告 → Warning
成功 → Success
失败 → Failed
```
