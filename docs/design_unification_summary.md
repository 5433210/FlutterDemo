# 設計文檔統一總結

## 統一前的問題

`backup_restore_design.md` 和 `unified_upgrade_system_design.md` 兩份文檔存在以下不一致之處：

### 1. 數據版本定義結構不同
- **backup_restore_design.md**: 使用 `AppDataVersionMapping` 類，簡單的映射表結構
- **unified_upgrade_system_design.md**: 使用 `DataVersionDefinition` 類，包含更豐富的版本信息

### 2. 適配器接口設計差異
- **backup_restore_design.md**: `DataVersionAdapter` 接口缺少數據庫集成方法
- **unified_upgrade_system_design.md**: `DataVersionUpgradeAdapter` 接口包含數據庫集成

### 3. 兼容性矩陣表述不同
- 兩份文檔使用相同的矩陣內容，但描述方式略有差異

### 4. 適配器命名不一致
- **backup_restore_design.md**: `DataAdapter_v1_to_v2`
- **unified_upgrade_system_design.md**: `DataUpgradeAdapter_v1_to_v2`

## 統一後的解決方案

### 1. 統一數據版本定義
```dart
class DataVersionDefinition {
  static const Map<String, DataVersionInfo> versions = {
    'v1': DataVersionInfo(
      version: 'v1',
      description: '基础数据结构',
      appVersions: ['1.0.0', '1.0.1', '1.0.2'],
      databaseVersion: 5,
      features: ['基础作品管理', '字符收集'],
    ),
    // ... 其他版本
  };
}
```

### 2. 統一適配器接口
```dart
abstract class DataVersionAdapter {
  String get sourceDataVersion;
  String get targetDataVersion;
  Future<PreProcessResult> preProcess(String dataPath);
  Future<PostProcessResult> postProcess(String dataPath);
  Future<bool> validateAdaptation(String dataPath);
  Future<void> integrateDatabaseMigration(String dataPath);
}
```

### 3. 統一適配器命名
- 統一使用 `DataAdapter_v1_to_v2` 命名格式

### 4. 統一backup_info.json結構
```json
{
  "timestamp": "2024-01-01T00:00:00.000Z",
  "description": "用户描述或自动生成",
  "appVersion": "1.3.5",
  "dataVersion": "v3",
  "platform": "windows",
  "dataIntegrity": {
    "checksum": "sha256_hash",
    "fileCount": 1234,
    "totalSize": 567890
  }
}
```

## 統一後的架構

### 核心組件統一
1. **數據版本管理**: 使用統一的 `DataVersionDefinition` 和 `DataVersionMappingService`
2. **適配器系統**: 使用統一的 `DataVersionAdapter` 接口
3. **兼容性檢查**: 使用統一的兼容性矩陣和檢查邏輯
4. **三階段處理**: 統一的預處理→重啟→後處理流程
5. **數據庫集成**: 統一與 migrations.dart 的集成方式

### 功能分工明確
- **統一升級系統**: 負責應用啟動時的自動升級和跨版本升級處理
- **備份恢復系統**: 負責用戶主動的數據備份和恢復操作
- **共同基礎**: 兩者共享相同的數據版本管理和適配器架構

## 實現建議

### 1. 開發優先級
1. 優先實現統一升級系統的核心組件
2. 將備份恢復功能作為統一升級系統的應用場景
3. 確保兩個系統共享相同的基礎設施

### 2. 代碼組織
```
lib/
├── application/
│   ├── services/
│   │   ├── unified_upgrade_service.dart
│   │   ├── backup_service.dart
│   │   ├── restore_service.dart
│   │   └── data_version_service.dart
│   └── adapters/
│       ├── data_version_adapter_manager.dart
│       ├── base_data_version_adapter.dart
│       └── data_versions/
│           ├── adapter_v1_to_v2.dart
│           ├── adapter_v2_to_v3.dart
│           └── adapter_v3_to_v4.dart
├── domain/
│   ├── models/
│   │   ├── data_version_definition.dart
│   │   ├── backup_info.dart
│   │   └── compatibility_matrix.dart
│   └── interfaces/
│       └── data_version_adapter.dart
```

### 3. 測試策略
- 為每個數據版本適配器編寫完整的單元測試
- 測試所有可能的升級路徑組合
- 驗證備份恢復和應用升級的一致性

## 維護指南

### 1. 新版本添加
當需要添加新的數據版本時：
1. 在 `DataVersionDefinition` 中添加新版本信息
2. 創建從上一版本到新版本的適配器
3. 更新兼容性矩陣
4. 添加相應的數據庫遷移腳本
5. 編寫完整的測試用例

### 2. 文檔同步
- 保持兩份設計文檔的同步更新
- 確保實際實現與設計文檔的一致性
- 定期檢查和更新兼容性矩陣

---

*統一完成時間: 2025-07-25*
*統一目標: 消除設計不一致，建立統一的版本管理架構*
