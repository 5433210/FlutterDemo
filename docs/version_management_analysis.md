# 數據版本管理分析文檔

## 概述

本文檔梳理了當前應用中備份恢復功能和作品/字符導入導出功能中對於版本差異的處理邏輯，包括版本兼容性檢查、數據遷移機制和錯誤處理策略。

## 1. 備份恢復功能中的版本管理

### 1.1 備份文件版本信息

#### 備份信息文件存放位置
**重要發現**: `backup_info.json` 文件確實存在於備份ZIP文件中，位於ZIP文件的根目錄。

#### 備份流程中的版本信息處理
1. **創建階段**:
   - 在臨時目錄中創建 `backup_info.json` 文件
   - 文件路徑: `{tempPath}/backup_info.json`
   - 然後將整個臨時目錄（包括此文件）打包到ZIP中

2. **ZIP文件結構**:
```
backup_YYYYMMDD_HHMMSS.zip
├── backup_info.json          // 版本信息文件（在ZIP根目錄）
├── data/                     // 應用數據目錄
│   ├── works/
│   ├── characters/
│   ├── practices/
│   └── library/
└── database/                 // 數據庫文件
    └── app.db
```

#### 備份信息結構（實際實現）
```json
{
  "timestamp": "2024-01-01T00:00:00.000Z",
  "description": "用戶描述",
  "backupVersion": "1.1",           // 備份格式版本
  "appVersion": "1.0.0",           // 應用版本
  "platform": "windows",           // 操作系統平台
  "compatibility": {
    "minAppVersion": "1.0.0",      // 最低支持的應用版本
    "maxAppVersion": "2.0.0",      // 最高支持的應用版本
    "dataFormat": "v1"             // 數據格式版本
  },
  "excludedDirectories": ["temp", "cache"],
  "includedDirectories": ["works", "characters", "practices", "library", "database"]
}
```

#### 支持的備份格式版本
- **1.0**: 基礎備份格式
- **1.1**: 增強備份格式（當前版本）

#### 版本信息文件的創建條件
**注意**: `backup_info.json` 文件只有在用戶提供了備份描述時才會創建：
```dart
// 創建備份描述文件
if (description != null) {
  await _createBackupInfo(tempPath, description);
}
```
如果用戶沒有提供描述，則不會創建此版本信息文件。

### 1.2 恢復時的兼容性檢查

#### 版本信息文件的讀取
恢復時，系統會嘗試從ZIP文件中讀取 `backup_info.json`：

```dart
// 查找備份信息文件
final infoFile = archive.findFile('backup_info.json');
if (infoFile != null) {
  // 解析備份信息文件
  final infoContent = utf8.decode(infoFile.content as List<int>);
  final infoJson = jsonDecode(infoContent) as Map<String, dynamic>;
  description = infoJson['description'] as String?;
}
```

#### 版本兼容性驗證邏輯
```dart
// 檢查應用版本兼容性
if (minAppVersion != null && _compareVersions(currentAppVersion, minAppVersion) < 0) {
  throw Exception('當前應用版本($currentAppVersion)低於備份要求的最低版本($minAppVersion)');
}

if (maxAppVersion != null && _compareVersions(currentAppVersion, maxAppVersion) > 0) {
  AppLogger.warning('當前應用版本可能高於備份兼容的最高版本，恢復後可能需要數據迁移');
}

// 檢查備份格式版本
const supportedBackupVersions = ['1.0', '1.1'];
if (!supportedBackupVersions.contains(backupVersion)) {
  throw Exception('不支持的備份格式版本: $backupVersion');
}
```

#### 兼容性檢查結果處理
- **兼容**: 正常恢復流程
- **版本過低**: 拋出異常，阻止恢復
- **版本過高**: 記錄警告，允許恢復但提示可能需要數據遷移
- **不支持的格式**: 拋出異常，阻止恢復
- **缺少版本信息**: 記錄警告，跳過兼容性檢查（向下兼容舊備份）

### 1.3 數據庫恢復機制

#### 恢復流程
1. **應用數據恢復**: 先恢復文件系統數據
2. **數據庫恢復**: 後恢復數據庫文件
3. **重啟機制**: 數據庫恢復需要應用重啟才能生效

#### 數據庫版本處理
- 使用SQLite的版本機制進行數據庫schema升級
- 支持從舊版本數據庫自動升級到新版本
- 迁移腳本按版本順序執行

## 2. 作品導入導出功能中的版本管理

### 2.1 導出數據版本信息

#### 導出元數據結構
```dart
class ExportMetadata {
  String version;                    // 導出版本 (默認: '1.0.0')
  DateTime exportTime;               // 導出時間
  ExportType exportType;             // 導出類型
  String appVersion;                 // 應用版本
  String platform;                   // 平台信息
  String dataFormatVersion;          // 數據格式版本 (默認: '1.0.0')
  CompatibilityInfo compatibility;   // 兼容性信息
}
```

#### 兼容性信息結構
```dart
class CompatibilityInfo {
  String minSupportedVersion;        // 最低支持版本
  String recommendedVersion;         // 推薦版本
  List<String> compatibilityFlags;  // 兼容性標記
  bool backwardCompatible;           // 向下兼容性 (默認: true)
  bool forwardCompatible;            // 向前兼容性 (默認: false)
}
```

### 2.2 導入時的版本兼容性處理

#### 文件格式驗證
```dart
// ZIP文件基本驗證
final hasExportData = archive.files.any((f) => f.name == 'export_data.json');
final hasManifest = archive.files.any((f) => f.name == 'manifest.json');

if (!hasExportData) {
  return ModelFactories.createFailedValidationResult('缺少導出數據文件');
}
if (!hasManifest) {
  return ModelFactories.createFailedValidationResult('缺少清單文件');
}
```

#### 版本兼容性檢查
```dart
class ImportCompatibilityHandler {
  bool isCompatible(String exportVersion) {
    final version = Version.parse(exportVersion);
    final currentVersion = Version.parse("1.0");
    return version <= currentVersion;
  }
  
  Map<String, dynamic> upgradeToCurrentVersion(
    Map<String, dynamic> data, 
    String fromVersion
  ) {
    switch (fromVersion) {
      case "1.0":
        return data; // 當前版本，無需升級
      default:
        throw UnsupportedError('不支持的版本: $fromVersion');
    }
  }
}
```

### 2.3 衝突解決策略

#### 衝突類型
- **ID衝突**: 相同ID的實體已存在
- **數據衝突**: 數據內容不一致
- **文件衝突**: 文件已存在
- **版本衝突**: 版本不兼容

#### 解決策略
- **跳過 (Skip)**: 跳過衝突項目
- **覆蓋 (Overwrite)**: 覆蓋現有數據
- **詢問 (Ask)**: 提示用戶選擇

## 3. 字符導入導出功能中的版本管理

### 3.1 字符數據導出

#### 導出流程
1. **數據收集**: 收集字符及關聯的作品和圖片數據
2. **版本標記**: 添加版本信息和兼容性標記
3. **文件打包**: 創建ZIP格式的導出文件

#### 版本信息處理
- 繼承作品導出的版本管理機制
- 包含字符特定的兼容性檢查
- 支持增量導出和完整導出

### 3.2 字符數據導入

#### 導入驗證
```dart
// 驗證字符數據完整性
for (final character in exportData.characters) {
  if (character.id.isEmpty) {
    validations.add(ExportValidation(
      type: ExportValidationType.dataIntegrity,
      status: ValidationStatus.failed,
      message: '字符ID不能為空',
      details: {'characterId': character.id},
    ));
  }
}
```

#### 衝突處理
- 檢查字符ID衝突
- 處理關聯作品的依賴關係
- 支持批量導入和選擇性導入

## 4. 數據庫Schema版本管理

### 4.1 遷移機制

#### SQLite版本管理
```dart
final db = await openDatabase(
  dbFullPath,
  version: migrations.length,  // 版本號等於遷移腳本數量
  onCreate: (db, version) async {
    // 執行所有遷移腳本
    for (int i = 0; i < migrations.length; i++) {
      await db.execute(migrations[i]);
    }
  },
  onUpgrade: (db, oldVersion, newVersion) async {
    // 執行增量遷移
    for (var i = oldVersion; i < newVersion; i++) {
      await db.execute(migrations[i]);
    }
  },
);
```

#### 遷移腳本管理
- 按版本順序組織遷移腳本
- 支持增量升級和完整初始化
- 包含錯誤處理和回滾機制

### 4.2 數據路徑版本管理

#### 版本兼容性檢查
```dart
enum VersionCompatibility {
  compatible,        // 完全兼容
  upgradable,       // 可升級
  incompatible,     // 不兼容，需要遷移工具
  needsAppUpgrade,  // 需要升級應用
}
```

#### 版本比較邏輯
- **主版本不同**: 不兼容或需要應用升級
- **次版本更高**: 可升級
- **版本相同**: 完全兼容
- **版本更低**: 需要應用升級

## 5. backupVersion 和 compatibility 的詳細用途解讀

### 5.1 backupVersion 的用途

#### 5.1.1 備份格式版本控制
```dart
// 當前支持的備份格式版本
const supportedBackupVersions = ['1.0', '1.1'];
```

**具體用途**：
1. **格式兼容性檢查**: 確保當前應用能夠處理該備份格式
2. **未來格式升級**: 為備份格式的演進提供版本標識
3. **錯誤預防**: 阻止不兼容格式的恢復操作

#### 5.1.2 備份格式演進路徑
- **1.0**: 基礎備份格式（可能包含所有文件，無選擇性）
- **1.1**: 增強備份格式（選擇性目錄備份，排除temp/cache）
- **未來版本**: 可能支持增量備份、壓縮優化、加密等

#### 5.1.3 實際應用場景
```dart
// 恢復時的格式檢查
if (backupVersion != null) {
  const supportedBackupVersions = ['1.0', '1.1'];
  if (!supportedBackupVersions.contains(backupVersion)) {
    throw Exception('不支持的備份格式版本: $backupVersion');
  }
}
```

### 5.2 compatibility 的用途

#### 5.2.1 應用版本兼容性控制
```json
"compatibility": {
  "minAppVersion": "1.0.0",      // 最低支持的應用版本
  "maxAppVersion": "2.0.0",      // 最高支持的應用版本
  "dataFormat": "v1"             // 數據格式版本
}
```

#### 5.2.2 具體用途詳解

**minAppVersion (最低應用版本)**:
- **用途**: 防止舊版本應用恢復新版本數據
- **場景**: 當備份包含新功能的數據結構時，舊版本應用無法正確處理
- **處理**: 如果當前應用版本低於此值，直接拋出異常阻止恢復

**maxAppVersion (最高應用版本)**:
- **用途**: 警告可能的向前兼容性問題
- **場景**: 當前應用版本高於備份創建時的最高支持版本
- **處理**: 記錄警告但允許恢復，提示可能需要數據遷移

**dataFormat (數據格式版本)**:
- **用途**: 標識備份中數據的格式版本
- **場景**: 數據庫schema變更、文件格式升級等
- **處理**: 用於數據遷移和格式轉換的依據

#### 5.2.3 實際應用場景
```dart
// 版本兼容性檢查邏輯
if (compatibility != null) {
  final minAppVersion = compatibility['minAppVersion'] as String?;
  final maxAppVersion = compatibility['maxAppVersion'] as String?;
  const currentAppVersion = '1.0.0';

  // 檢查最低版本要求
  if (minAppVersion != null &&
      _compareVersions(currentAppVersion, minAppVersion) < 0) {
    throw Exception('當前應用版本($currentAppVersion)低於備份要求的最低版本($minAppVersion)');
  }

  // 檢查最高版本警告
  if (maxAppVersion != null &&
      _compareVersions(currentAppVersion, maxAppVersion) > 0) {
    AppLogger.warning('當前應用版本可能高於備份兼容的最高版本，恢復後可能需要數據遷移');
  }
}
```

### 5.3 版本管理的實際應用場景

#### 5.3.1 應用升級場景
1. **應用從 1.0 升級到 1.5**:
   - 舊備份 (minAppVersion: "1.0", maxAppVersion: "1.2")
   - 當前版本 1.5 > maxAppVersion 1.2
   - 結果: 警告但允許恢復

2. **應用從 2.0 降級到 1.8**:
   - 新備份 (minAppVersion: "1.9", maxAppVersion: "2.5")
   - 當前版本 1.8 < minAppVersion 1.9
   - 結果: 拋出異常，阻止恢復

#### 5.3.2 數據格式變更場景
1. **數據庫schema升級**:
   - 備份時 dataFormat: "v1"
   - 恢復時檢查是否需要數據遷移
   - 自動執行格式升級腳本

2. **文件格式變更**:
   - 圖片存儲格式從PNG改為WebP
   - 通過dataFormat識別並轉換

### 5.4 改進建議

#### 5.4.1 強制創建版本信息
**當前問題**: 只有提供描述時才創建 `backup_info.json`
**建議**: 無論是否有描述都應該創建，因為版本信息對兼容性檢查至關重要

#### 5.4.2 版本信息的完善
```json
{
  "timestamp": "2024-01-01T00:00:00.000Z",
  "description": "用戶描述或自動生成",
  "backupVersion": "1.1",
  "appVersion": "1.0.0",
  "platform": "windows",
  "compatibility": {
    "minAppVersion": "1.0.0",
    "maxAppVersion": "2.0.0",
    "dataFormat": "v1",
    "schemaVersion": "1.2",        // 數據庫schema版本
    "featureFlags": ["new_ui", "advanced_export"]  // 功能標記
  },
  "dataIntegrity": {
    "checksum": "sha256_hash",     // 數據完整性校驗
    "fileCount": 1234,            // 文件數量
    "totalSize": 567890           // 總大小
  }
}
```

## 6. 總結

### 6.1 版本管理特點

1. **多層次版本控制**: 應用版本、數據格式版本、備份格式版本
2. **向下兼容**: 新版本可以處理舊版本數據
3. **漸進式升級**: 支持增量遷移和自動升級
4. **錯誤恢復**: 包含回滾機制和錯誤處理

### 6.2 重要發現

1. **備份版本信息的條件性創建**: `backup_info.json` 只有在用戶提供備份描述時才會創建
2. **向下兼容處理**: 如果備份文件中沒有版本信息，系統會跳過兼容性檢查
3. **ZIP文件結構**: 版本信息文件位於ZIP根目錄，與數據文件並列存放
4. **恢復流程的容錯性**: 即使版本信息缺失，系統仍能嘗試恢復（適用於舊版本備份）

### 6.3 改進建議

1. **版本策略統一**: 統一各模塊的版本管理策略
2. **強制版本信息**: 始終創建版本信息文件，即使沒有用戶描述
3. **遷移工具**: 開發專門的數據遷移工具
4. **測試覆蓋**: 增加版本兼容性測試用例，特別是無版本信息的情況
5. **文檔完善**: 完善版本升級指南和API文檔
6. **數據完整性**: 添加校驗和驗證機制

## 7. 備份兼容性矩陣實現方案

### 7.1 兼容性矩陣設計

基於您提出的兼容性分類，我們實現了一個完整的備份兼容性矩陣系統：

#### 7.1.1 兼容性結果分類
```dart
enum BackupCompatibilityResult {
  compatible('C', '完全兼容'),           // 直接恢復，無需升級
  dataUpgradeRequired('D', '兼容但需要升級數據'), // 需要數據庫和文件升級
  appUpgradeRequired('A', '需要升級應用'),      // 應用版本過低
  incompatible('N', '不兼容'),           // 備份版本過低，不支持
}
```

#### 7.1.2 兼容性矩陣示例
```
當前應用版本 \ 備份數據版本  1.0.0  1.0.1  1.3.5  1.3.6  1.5.0
1.0.0                    C      A      A      A      A
1.0.1                    C      C      A      A      A
1.3.5                    D      D      C      A      A
1.3.6                    D      D      C      C      A
1.5.0                    N      N      N      N      C
```

### 7.2 數據升級機制

#### 7.2.1 升級類型分類
```dart
enum DataUpgradeType {
  database,        // 數據庫升級
  fileStructure,   // 文件結構升級
  fileContent,     // 文件內容升級
  configuration,   // 配置文件升級
}
```

#### 7.2.2 升級步驟定義
每個升級步驟包含：
- **步驟ID和標題**: 唯一標識和用戶友好的名稱
- **升級類型**: 數據庫、文件結構、內容或配置
- **影響路徑**: 受影響的文件和目錄列表
- **預估時間**: 執行所需的時間估算
- **是否必需**: 區分必需和可選的升級步驟

### 7.3 實際應用流程

#### 7.3.1 恢復前檢查流程
1. **提取備份版本信息**: 從backup_info.json讀取版本
2. **查詢兼容性矩陣**: 確定兼容性結果
3. **生成升級計劃**: 根據版本差異生成升級步驟
4. **用戶確認**: 顯示兼容性結果和升級計劃

#### 7.3.2 不同兼容性結果的處理
- **C (完全兼容)**: 直接進行恢復，無需額外步驟
- **D (需要數據升級)**: 先執行數據升級，再進行恢復
- **A (需要應用升級)**: 提示用戶升級應用後再嘗試恢復
- **N (不兼容)**: 阻止恢復，建議使用對應版本的應用

### 7.4 數據升級實現

#### 7.4.1 數據庫升級
```dart
// 執行數據庫schema升級
await _executeDatabaseUpgrade(step, backupPath);
```

#### 7.4.2 文件結構升級
```dart
// 調整目錄結構和文件組織
await _executeFileStructureUpgrade(step, backupPath);
```

#### 7.4.3 文件內容升級
```dart
// 更新文件格式和內容結構
await _executeFileContentUpgrade(step, backupPath);
```

### 7.5 系統優勢

1. **明確的兼容性分類**: 四種清晰的兼容性結果
2. **靈活的矩陣配置**: 支持自定義版本兼容性規則
3. **詳細的升級指導**: 提供具體的升級步驟和時間估算
4. **用戶友好的體驗**: 清晰的提示和進度反饋
5. **安全的升級機制**: 包含備份和回滾功能

### 7.6 未來擴展

1. **動態矩陣更新**: 支持從服務器更新兼容性規則
2. **自動升級腳本**: 開發自動化的數據升級工具
3. **兼容性測試**: 建立自動化的兼容性測試框架
4. **版本預警系統**: 提前通知用戶即將到來的兼容性變更

---

*文檔生成時間: 2025-07-25*
*版本: 2.0*
*更新內容: 添加備份兼容性矩陣實現方案*
