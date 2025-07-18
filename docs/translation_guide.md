# 字字珠玑 - 多语言翻译指南

## 概述

本文档为专业翻译人员提供翻译指南，帮助完成日语和韩语的本地化工作。

## 文件结构

### ARB 文件位置
- **中文（模板）**: `lib/l10n/app_zh.arb`
- **英文**: `lib/l10n/app_en.arb`
- **日语**: `lib/l10n/app_ja.arb` ⚠️ **需要翻译**
- **韩语**: `lib/l10n/app_ko.arb` ⚠️ **需要翻译**

### 生成的本地化文件
- `lib/l10n/app_localizations.dart` - 主文件
- `lib/l10n/app_localizations_ja.dart` - 日语实现
- `lib/l10n/app_localizations_ko.dart` - 韩语实现

## 应用背景

**字字珠玑 (Char As Gem)** 是一款书法作品数字化管理以及配套的书法字帖创作生成工具应用。

### 核心功能
1. **作品管理** - 书法作品的数字化存储和管理
2. **字符采集** - 从书法作品中提取单个字符
3. **字帖生成** - 创建练习用的书法字帖
4. **图库管理** - 管理相关图片资源
5. **备份恢复** - 数据备份和恢复功能

## 翻译原则

### 1. 术语一致性
- **作品** → 日语: 作品 (さくひん) / 韩语: 작품
- **集字** → 日语: 文字収集 / 韩语: 글자 수집
- **字帖** → 日语: 字帖 (じちょう) / 韩语: 글씨 연습장
- **书法** → 日语: 書道 (しょどう) / 韩语: 서예
- **练习** → 日语: 練習 (れんしゅう) / 韩语: 연습

### 2. 界面元素翻译
- **按钮文本** - 简洁明了，符合平台习惯
- **菜单项** - 使用标准术语
- **错误信息** - 清晰易懂，提供解决方案
- **提示文本** - 友好且有帮助

### 3. 文化适应
- **日语**: 使用适当的敬语形式，符合日本软件界面习惯
- **韩语**: 使用标准韩语，避免过于正式或非正式的表达

## 需要特别注意的术语

### 书法相关术语
| 中文 | 英文 | 日语建议 | 韩语建议 |
|------|------|----------|----------|
| 楷书 | Regular Script | 楷書 (かいしょ) | 해서 |
| 行书 | Running Script | 行書 (ぎょうしょ) | 행서 |
| 草书 | Cursive Script | 草書 (そうしょ) | 초서 |
| 隶书 | Clerical Script | 隷書 (れいしょ) | 예서 |
| 篆书 | Seal Script | 篆書 (てんしょ) | 전서 |
| 毛笔 | Brush | 筆 (ふで) | 붓 |
| 硬笔 | Hard Pen | 硬筆 (こうひつ) | 경필 |

### 技术术语
| 中文 | 英文 | 日语建议 | 韩语建议 |
|------|------|----------|----------|
| 导入 | Import | インポート | 가져오기 |
| 导出 | Export | エクスポート | 내보내기 |
| 备份 | Backup | バックアップ | 백업 |
| 恢复 | Restore | 復元 | 복원 |
| 设置 | Settings | 設定 | 설정 |
| 缓存 | Cache | キャッシュ | 캐시 |

## 占位符处理

ARB 文件中包含占位符，翻译时需要保持占位符不变：

```json
{
  "deleteMessage": "即将删除{count}项，此操作无法撤消。",
  "error": "错误：{message}",
  "titleUpdated": "标题已更新为\"{title}\""
}
```

**翻译示例**：
```json
// 日语
{
  "deleteMessage": "{count}項目を削除します。この操作は元に戻せません。",
  "error": "エラー：{message}",
  "titleUpdated": "タイトルが\"{title}\"に更新されました"
}

// 韩语
{
  "deleteMessage": "{count}개 항목을 삭제합니다. 이 작업은 취소할 수 없습니다.",
  "error": "오류: {message}",
  "titleUpdated": "제목이 \"{title}\"로 업데이트되었습니다"
}
```

## 翻译工作流程

### 1. 准备工作
- 了解应用功能和界面布局
- 熟悉书法相关术语
- 准备术语表和风格指南

### 2. 翻译步骤
1. **打开 ARB 文件** - 使用支持 JSON 的编辑器
2. **逐项翻译** - 保持键名不变，只翻译值
3. **保持格式** - 确保 JSON 格式正确
4. **测试验证** - 在应用中测试翻译效果

### 3. 质量检查
- **术语一致性** - 相同概念使用相同翻译
- **界面适配** - 考虑文本长度对界面的影响
- **功能测试** - 确保翻译后功能正常

## 当前翻译状态

### 日语 (app_ja.arb)
- ✅ 基础词汇已翻译（约30个）
- ⚠️ 剩余1330+项需要专业翻译
- 📋 重点：书法术语、界面元素、错误信息

### 韩语 (app_ko.arb)
- ✅ 基础词汇已翻译（约30个）
- ⚠️ 剩余1330+项需要专业翻译
- 📋 重点：书法术语、界面元素、错误信息

## 技术支持

### 生成本地化代码
翻译完成后，运行以下命令生成代码：
```bash
flutter gen-l10n
```

### 测试翻译
1. 修改应用语言设置
2. 检查界面显示效果
3. 测试各项功能

## 联系方式

如有翻译相关问题，请联系：
- **邮箱**: charasgem@outlook.com
- **项目**: 字字珠玑 (Char As Gem)

## 附录

### 已翻译的基础词汇

#### 日语
- add → 追加
- cancel → キャンセル
- confirm → 確認
- delete → 削除
- edit → 編集
- export → エクスポート
- import → インポート
- save → 保存
- settings → 設定
- about → について

#### 韩语
- add → 추가
- cancel → 취소
- confirm → 확인
- delete → 삭제
- edit → 편집
- export → 내보내기
- import → 가져오기
- save → 저장
- settings → 설정
- about → 정보

---

**最后更新**: 2025年7月18日  
**版本**: 1.0
