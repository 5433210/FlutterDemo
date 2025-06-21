# 作品和集字导入导出批量操作功能设计方案

## 目录

- [概述](#概述)
- [作品浏览页功能增强](#作品浏览页功能增强)
- [集字管理页功能增强](#集字管理页功能增强)
- [技术架构设计](#技术架构设计)
- [异常处理机制](#异常处理机制)
- [用户界面设计](#用户界面设计)
- [本地化支持](#本地化支持)
- [实现计划](#实现计划)

## 概述

本方案旨在为作品浏览页和集字管理页增加完整的导入导出功能，包括批量操作、进度提示、异常处理等核心功能。设计遵循Material 3设计规范，支持多语言本地化，确保用户体验的一致性和可靠性。

### 功能区分说明

**现有导入功能**：页面顶部的"导入"按钮，用于单个作品/集字的导入操作
**新增批量导入功能**：进入批量模式后显示的"批量导入"按钮，用于批量导入多个作品/集字的压缩包文件

两个功能相互独立，各自服务于不同的使用场景。批量导入只在批量模式下可见，避免界面混乱。

### 主要功能

1. **作品导出**：支持多选作品导出，可选择导出范围（仅作品或作品+关联集字）
2. **批量导入**：进入批量模式后显示批量导入按钮，支持导入压缩包文件，自动验证文件完整性
3. **集字导出**：支持多选集字导出，可选择导出范围（仅集字或集字+来源作品）
4. **集字批量导入**：支持批量导入集字文件，智能处理依赖关系
5. **批量操作增强**：为两个页面添加全选和取消选择功能，在批量模式下显示批量导入按钮

## 作品浏览页功能增强

### 1. 批量导入功能

#### 功能描述
在进入批量模式后，工具栏显示"批量导入"按钮，区别于页面顶部的单个作品导入功能。批量导入支持导入包含多个作品的压缩包文件。

#### 操作流程
1. 点击"批量模式"按钮进入批量模式
2. 点击工具栏中的"批量导入"按钮
3. 选择压缩包文件（.zip格式）
4. 系统自动验证文件完整性
5. 显示导入预览和冲突处理选项
6. 确认后开始批量导入，显示进度条
7. 完成后显示导入结果报告

### 2. 作品导出功能

#### 功能描述
用户可以在批量模式下选择多个作品进行导出，系统将生成包含作品数据、图片文件和导出清单的压缩包。

#### 导出选项

##### 仅导出作品
导出内容严格按照 WorkEntity/PracticeEntity 现有数据结构：
- **作品基本信息**：
  - id (string)
  - title (string) - 作品标题
  - author (string) - 作者
  - remark (string?) - 备注信息
  - style (WorkStyle/string) - 书法风格
  - tool (WorkTool/string) - 书写工具
  - creationDate (DateTime, ISO8601格式) - 创作日期
  - status (WorkStatus/string, 默认'active') - 作品状态
  - tags (List<String>) - 标签列表
  - createTime (DateTime, ISO8601格式) - 创建时间
  - updateTime (DateTime, ISO8601格式) - 更新时间
  - isFavorite (bool, 默认false) - 是否收藏  - firstImageId (string?) - 首图ID
  - imageCount (int?) - 图片数量
  - lastImageUpdateTime (DateTime?) - 最后图片更新时间
- **图片详细数据** (work_images表数据)：
  - workImages (List<WorkImageEntity>) - 作品关联的图片详细信息
  - 每个WorkImageEntity包含：
    - id (string) - 图片ID
    - workId (string) - 所属作品ID
    - indexInWork (int) - 在作品中的顺序号
    - path (string) - 图片路径
    - width (int) - 宽度
    - height (int) - 高度
    - format (string) - 格式
    - size (int) - 文件大小
    - thumbnailPath (string?) - 缩略图路径
    - createTime (DateTime) - 创建时间
    - updateTime (DateTime) - 更新时间
- **集字数据**：
  - collectedChars (List<CharacterEntity>) - 收集的字符信息
- **文件版本信息**：
  - exportVersion: "1.0" - 确保向下兼容
  - exportType: "works" - 导出类型标识

##### 导出作品及关联集字（默认）
在仅导出作品的基础上，额外包括：
- **关联集字数据**：
  - 基于 CharacterEntity 结构的集字信息
  - id (string)
  - workId (string) - 所属作品ID
  - pageId (string) - 所属页面ID
  - character (string) - 字符内容
  - region (CharacterRegion) - 区域信息
  - createTime (DateTime)
  - updateTime (DateTime)
  - isFavorite (bool)
  - tags (List<String>)
  - note (string?)
- **集字图片文件**：
  - 基于现有存储结构：characters/{characterId}/
  - {id}-original.png - 原始裁剪图
  - {id}-binary.png - 二值化图像
  - {id}-transparent.png - 透明背景图像
  - {id}-thumbnail.jpg - 缩略图
  - {id}-square-binary.png - 方形二值化图像
  - {id}-square-transparent.png - 方形透明图像
  - {id}-outline.svg - SVG轮廓（可选）
- **向下兼容性保证**：
  - 保留现有字段结构
  - 新增字段使用可选属性
  - 包含数据版本标识符

#### 文件结构
```
exported_works_[timestamp].zip
├── manifest.txt                   # 导出清单（本地化）
├── works/                         # 作品数据
│   ├── work_[id]/
│   │   ├── data.json             # 作品元数据
│   │   ├── pages/                # 页面数据
│   │   │   ├── page_1.json
│   │   │   └── ...
│   │   └── images/               # 作品图片
│   │       ├── preview.jpg
│   │       ├── thumbnail.jpg
│   │       └── pages/
│   │           ├── page_1.png
│   │           └── ...
│   └── ...
├── characters/                    # 关联集字数据（可选）
│   ├── character_[id]/
│   │   ├── data.json
│   │   └── images/
│   │       ├── default.png
│   │       ├── binary.png
│   │       └── ...
│   └── ...
└── index.json                    # 导出索引文件
```

#### 导出清单内容
```
=== 作品导出清单 ===
导出时间：2024-01-15 14:30:25
导出选项：作品及关联集字

=== 汇总信息 ===
作品总数：5
集字总数：23
图片文件：156
数据文件：28
压缩包大小：45.2 MB

=== 详细信息 ===
[作品列表]
- 作品ID: work_001
  标题: 春江花月夜
  页面数: 3
  创建时间: 2024-01-10 09:15:00
  关联集字: 8个

- 作品ID: work_002
  标题: 兰亭序
  页面数: 5
  创建时间: 2024-01-12 16:22:33
  关联集字: 15个

[集字列表]
- 集字ID: char_001
  字符: 春
  来源作品: 春江花月夜
  采集时间: 2024-01-10 10:30:15
  
...

=== 文件清单 ===
works/work_001/data.json (2.1 KB)
works/work_001/images/preview.jpg (156 KB)
...
```

### 2. 作品导入功能

#### 功能描述
用户可以选择导入文件（.zip格式），系统自动验证文件完整性并导入作品数据。

#### 导入流程
1. **文件选择**：用户选择导入文件
2. **文件验证**：检查文件格式、结构完整性
3. **冲突检测**：检查是否存在重复数据
4. **导入确认**：显示导入预览，用户确认导入选项
5. **执行导入**：显示进度条，执行导入操作
6. **结果反馈**：显示导入结果和错误报告

#### 导入选项
- **跳过重复项**：遇到重复数据时跳过
- **覆盖重复项**：用导入数据覆盖现有数据
- **重命名重复项**：为重复项生成新的名称

### 3. 批量操作增强

#### 新增按钮
- **全选按钮**：选择当前页面所有作品
- **取消选择按钮**：清除所有选择

#### 按钮位置
在现有的批量操作工具栏中添加，位于删除按钮之前。

## 集字管理页功能增强

### 1. 集字导出功能

#### 功能描述
用户可以在批量模式下选择多个集字进行导出，系统将生成包含集字数据、图片文件和导出清单的压缩包。

#### 导出选项

##### 仅导出集字
导出内容严格按照 CharacterEntity 现有数据结构：
- **集字基本信息**：
  - id (string)
  - workId (string) - 所属作品ID（引用信息，不包含完整作品数据）
  - pageId (string) - 所属页面ID
  - character (string) - 字符内容
  - createTime (DateTime, ISO8601格式)
  - updateTime (DateTime, ISO8601格式)
  - isFavorite (bool, 默认false)
  - tags (List<String>)
  - note (string?) - 用户注释
- **集字区域信息**：
  - region (CharacterRegion) - 基于现有 CharacterRegion 结构
- **集字图片文件**：
  - 基于现有存储结构：characters/{characterId}/
  - {id}-original.png - 原始裁剪图
  - {id}-binary.png - 二值化图像
  - {id}-transparent.png - 透明背景图像
  - {id}-thumbnail.jpg - 缩略图
  - {id}-square-binary.png - 方形二值化图像（如果存在）
  - {id}-square-transparent.png - 方形透明图像（如果存在）
  - {id}-outline.svg - SVG轮廓（如果存在）
- **文件版本信息**：
  - exportVersion: "1.0" - 确保向下兼容
  - exportType: "character" - 导出类型标识

##### 导出集字及来源作品（默认）
在仅导出集字的基础上，额外包括：
- **完整来源作品数据**：
  - 基于 WorkEntity 现有结构的完整作品信息
  - id, title, author, remark, style, tool
  - createTime, updateTime, isFavorite
  - status (WorkStatus), firstImageId
  - images (List<WorkImage>), tags (List<String>)
- **作品图片文件**：
  - 基于 WorkImage 结构的图片文件
  - originalPath, path, thumbnailPath
  - 按 index 组织的图片序列
- **向下兼容性保证**：
  - 保留所有现有字段结构
  - 新增字段使用可选属性
  - 包含完整的依赖关系数据

#### 文件结构
```
exported_characters_[timestamp].zip
├── manifest.txt                   # 导出清单（本地化）
├── characters/                    # 集字数据
│   ├── character_[id]/
│   │   ├── data.json             # 集字元数据
│   │   └── images/               # 集字图片
│   │       ├── default.png
│   │       ├── binary.png
│   │       ├── outline.png
│   │       └── ...
│   └── ...
├── source_works/                  # 来源作品数据（可选）
│   ├── work_[id]/
│   │   ├── data.json
│   │   ├── pages/
│   │   └── images/
│   └── ...
└── index.json                    # 导出索引文件
```

### 2. 批量导入功能

#### 功能描述
在进入批量模式后，工具栏显示"批量导入"按钮，用户可以导入集字文件，系统智能处理来源作品依赖关系。

#### 操作流程
1. 点击"批量模式"按钮进入批量模式
2. 点击工具栏中的"批量导入"按钮
3. 选择压缩包文件（.zip格式）
4. 系统自动验证文件完整性
5. 处理孤立集字的依赖关系
6. 显示导入预览和冲突处理选项
7. 确认后开始批量导入，显示进度条
8. 完成后显示导入结果报告

#### 特殊处理：孤立集字导入

当导入文件中仅包含集字数据而没有来源作品数据时，系统需要特殊处理以确保应用功能正常：

##### 1. 虚拟作品创建策略
```dart
class VirtualWorkCreator {
  Future<WorkEntity> createVirtualWork(List<CharacterEntity> orphanCharacters) async {
    // 分析集字的来源信息，尝试重建作品结构
    final sourceWorkId = orphanCharacters.first.sourceWorkId;
    final workTitle = _generateVirtualWorkTitle(orphanCharacters);
    
    return WorkEntity(
      id: sourceWorkId ?? generateNewId(),
      title: workTitle,
      isVirtual: true, // 标记为虚拟作品
      status: WorkStatus.virtual,
      pages: _createVirtualPages(orphanCharacters),
      tags: ['导入', '虚拟作品'],
      description: '由导入的集字自动生成的虚拟作品',
      createTime: DateTime.now(),
    );
  }
  
  List<PageEntity> _createVirtualPages(List<CharacterEntity> characters) {
    // 根据集字的原始页面信息分组创建虚拟页面
    final pageGroups = characters.groupBy((c) => c.sourcePageId);
    
    return pageGroups.entries.map((entry) {
      return PageEntity(
        id: entry.key ?? generateNewId(),
        title: '虚拟页面 ${entry.key}',
        isVirtual: true,
        elements: _createVirtualElements(entry.value),
        backgroundColor: Colors.white,
        size: const Size(800, 600), // 默认尺寸
      );
    }).toList();
  }
}
```

##### 2. 数据完整性保障
```dart
class OrphanCharacterHandler {
  Future<void> handleOrphanCharacters(List<CharacterEntity> characters) async {
    for (final character in characters) {
      // 2.1 补全缺失的元数据
      character.metadata = character.metadata.copyWith(
        isOrphan: true,
        virtualSourceCreated: true,
        importTimestamp: DateTime.now(),
        originalSourceReference: character.sourceWorkId,
      );
      
      // 2.2 创建默认显示配置
      if (character.displayConfig == null) {
        character.displayConfig = CharacterDisplayConfig.defaultConfig();
      }
      
      // 2.3 生成占位符图片（如果图片文件缺失）
      await _ensureImageFiles(character);
      
      // 2.4 建立新的索引关系
      await _createCharacterIndexes(character);
    }
  }
  
  Future<void> _ensureImageFiles(CharacterEntity character) async {
    final requiredFormats = ['default', 'binary', 'outline', 'thumbnail'];
    
    for (final format in requiredFormats) {
      if (!await character.hasImageFormat(format)) {
        // 从现有格式生成缺失的格式，或创建占位符
        await _generateMissingImageFormat(character, format);
      }
    }
  }
}
```

##### 3. 功能兼容性确保

###### 3.1 集字浏览功能
```dart
class CharacterBrowseCompatibility {
  // 确保虚拟作品在作品列表中正确显示
  Future<List<WorkEntity>> getWorksWithVirtual() async {
    final works = await workRepository.getAllWorks();
    final virtualWorks = works.where((w) => w.isVirtual).toList();
    
    // 为虚拟作品生成预览图
    for (final virtualWork in virtualWorks) {
      if (virtualWork.previewImage == null) {
        virtualWork.previewImage = await _generateVirtualWorkPreview(virtualWork);
      }
    }
    
    return works;
  }
  
  Future<String> _generateVirtualWorkPreview(WorkEntity virtualWork) async {
    // 使用该作品包含的集字生成预览图
    final characters = await characterRepository.getCharactersByWorkId(virtualWork.id);
    return await previewGenerator.generateFromCharacters(characters);
  }
}
```

###### 3.2 集字编辑功能
```dart
class VirtualWorkEditingSupport {
  Future<bool> canEditVirtualWork(String workId) async {
    final work = await workRepository.getWork(workId);
    
    // 虚拟作品允许有限的编辑操作
    return work?.isVirtual == true;
  }
  
  List<EditOperation> getAvailableOperations(WorkEntity virtualWork) {
    return [
      EditOperation.addCharacterElement, // 允许添加集字元素
      EditOperation.adjustCharacterLayout, // 允许调整集字布局
      EditOperation.modifyCharacterStyle, // 允许修改集字样式
      EditOperation.exportWork, // 允许导出
      // 不允许：添加其他类型元素、修改页面结构等
    ];
  }
}
```

###### 3.3 搜索和筛选功能
```dart
class VirtualWorkSearchSupport {
  Future<List<WorkEntity>> searchWorks(String query, {bool includeVirtual = true}) async {
    final results = await baseSearch(query);
    
    if (includeVirtual) {
      // 虚拟作品参与搜索，但标注来源
      final virtualResults = results.where((w) => w.isVirtual).map((w) {
        return w.copyWith(
          searchResultNote: '由导入集字生成',
          tags: [...w.tags, '虚拟作品'],
        );
      }).toList();
      
      return [...results.where((w) => !w.isVirtual), ...virtualResults];
    }
    
    return results.where((w) => !w.isVirtual).toList();
  }
}
```

##### 4. 用户界面适配
```dart
class VirtualWorkUI {
  Widget buildWorkCard(WorkEntity work) {
    if (work.isVirtual) {
      return VirtualWorkCard(
        work: work,
        showVirtualBadge: true,
        allowedOperations: _getVirtualWorkOperations(),
        onRestore: () => _showRestoreDialog(work),
      );
    }
    
    return StandardWorkCard(work: work);
  }
  
  Widget buildVirtualWorkBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 14, color: Colors.orange),
          SizedBox(width: 4),
          Text('虚拟作品', style: TextStyle(color: Colors.orange, fontSize: 12)),
        ],
      ),
    );
  }
}
```

##### 5. 数据一致性维护
```dart
class VirtualWorkMaintenance {
  // 定期检查虚拟作品的一致性
  Future<void> validateVirtualWorks() async {
    final virtualWorks = await workRepository.getVirtualWorks();
    
    for (final work in virtualWorks) {
      // 检查关联的集字是否仍然存在
      final characters = await characterRepository.getCharactersByWorkId(work.id);
      
      if (characters.isEmpty) {
        // 如果没有关联集字，删除虚拟作品
        await workRepository.deleteWork(work.id);
        continue;
      }
      
      // 更新虚拟作品的统计信息
      final updatedWork = work.copyWith(
        characterCount: characters.length,
        lastUpdateTime: DateTime.now(),
      );
      
      await workRepository.updateWork(updatedWork);
    }
  }
  
  // 提供将虚拟作品转换为真实作品的功能
  Future<WorkEntity> promoteToRealWork(String virtualWorkId) async {
    final virtualWork = await workRepository.getWork(virtualWorkId);
    
    final realWork = virtualWork.copyWith(
      isVirtual: false,
      status: WorkStatus.active,
      promotedFromVirtual: true,
      promotionTime: DateTime.now(),
    );
    
    return await workRepository.updateWork(realWork);
  }
}
```

这种设计确保了即使导入的集字数据缺少来源作品信息，用户仍然可以：
- 正常浏览和搜索集字
- 在字帖编辑器中使用集字
- 查看集字的详细信息
- 导出集字数据
- 将虚拟作品升级为真实作品

#### 导入后处理
- 重建集字索引
- 验证图片文件完整性
- 更新统计信息

### 3. 批量操作增强

#### 新增按钮
- **全选按钮**：选择当前页面所有集字
- **取消选择按钮**：清除所有选择

## 回滚操作设计

为了应对导入过程中的异常情况，系统提供了完整的操作回滚机制，确保在导入失败时能够完全恢复到操作前的状态。

### 1. 事务性操作框架

```dart
class ImportTransaction {
  final String transactionId;
  final DateTime startTime;
  final List<ImportOperation> operations;
  final DatabaseSnapshot snapshot;
  final Map<String, FileBackup> fileBackups;
  
  ImportTransaction({
    required this.transactionId,
    required this.startTime,
    this.operations = const [],
    required this.snapshot,
    this.fileBackups = const {},
  });
  
  // 记录每个操作的详细信息和回滚数据
  void recordOperation(ImportOperationType type, String entityId, 
                      Map<String, dynamic> oldData, Map<String, dynamic> newData) {
    operations.add(ImportOperation(
      type: type,
      entityId: entityId,
      oldData: oldData,
      newData: newData,
      timestamp: DateTime.now(),
      sequenceNumber: operations.length,
    ));
  }
  
  // 记录work_images表操作
  void recordWorkImageOperation(String imageId, String workId, String filePath, 
                               String? thumbnailPath) {
    operations.add(ImportOperation(
      type: ImportOperationType.workImageInsert,
      entityId: imageId,
      oldData: {},
      newData: {
        'id': imageId,
        'workId': workId,
        'path': filePath,
        'thumbnailPath': thumbnailPath,
      },
      timestamp: DateTime.now(),
      sequenceNumber: operations.length,
    ));
  }
}

enum ImportOperationType {
  createWork,           // 创建作品
  updateWork,           // 更新作品
  createCharacter,      // 创建集字
  updateCharacter,      // 更新集字
  createFile,           // 创建文件
  updateFile,           // 更新文件
  createIndex,          // 创建索引
  updateIndex,          // 更新索引
}
```

### 2. 分阶段操作与快照

```dart
class ImportService {
  Future<ImportResult> importWithRollback(String filePath, ImportOptions options) async {
    final transaction = ImportTransaction.create();
    
    try {
      // 阶段1：创建数据库快照
      await _createDatabaseSnapshot(transaction);
      
      // 阶段2：验证导入文件
      final validation = await _validateImportFile(filePath);
      if (!validation.isValid) {
        throw ImportValidationException(validation.errors);
      }
      
      // 阶段3：预处理数据
      final processedData = await _preprocessImportData(filePath, options);
      
      // 阶段4：执行数据库操作（事务性）
      await _executeDataOperations(transaction, processedData);
      
      // 阶段5：复制文件资源
      await _copyFileResources(transaction, processedData);
      
      // 阶段6：更新索引和缓存
      await _updateIndexesAndCache(transaction, processedData);
      
      // 阶段7：验证导入结果
      await _validateImportResult(transaction, processedData);
      
      // 提交事务
      await _commitTransaction(transaction);
      
      return ImportResult.success(importedCount: processedData.totalCount);
      
    } catch (Exception e) {
      // 发生异常时自动回滚
      await _rollbackTransaction(transaction, e);
      return ImportResult.failure(error: e);
    }
  }
}
```

### 3. 数据库快照与恢复

```dart
class DatabaseSnapshot {
  final String snapshotId;
  final DateTime timestamp;
  final Map<String, TableSnapshot> tableSnapshots;
  final String backupPath;
  
  static Future<DatabaseSnapshot> create(String transactionId) async {
    final snapshot = DatabaseSnapshot(
      snapshotId: transactionId,
      timestamp: DateTime.now(),
      tableSnapshots: {},
      backupPath: _generateBackupPath(transactionId),
    );
    
    // 为每个关键表创建快照
    for (final tableName in criticalTables) {
      snapshot.tableSnapshots[tableName] = await _createTableSnapshot(tableName);
    }
    
    // 创建完整数据库备份文件
    await _createDatabaseBackup(snapshot.backupPath);
    
    return snapshot;
  }
  
  Future<void> restore() async {
    try {
      // 方法1：使用表级快照恢复（快速）
      for (final entry in tableSnapshots.entries) {
        await _restoreTableFromSnapshot(entry.key, entry.value);
      }
    } catch (e) {
      // 方法2：使用完整备份恢复（安全）
      await _restoreFromFullBackup(backupPath);
    }
  }
}

class TableSnapshot {
  final String tableName;
  final List<Map<String, dynamic>> records;
  final Map<String, dynamic> metadata;
  
  Future<void> restore() async {
    // 清空当前表数据
    await database.delete(tableName);
    
    // 恢复快照数据
    for (final record in records) {
      await database.insert(tableName, record);
    }
    
    // 恢复索引和约束
    await _restoreTableMetadata(tableName, metadata);
  }
}
```

### 4. 文件系统回滚

```dart
class FileSystemRollback {
  final Map<String, FileOperation> fileOperations = {};
  
  void recordFileOperation(String filePath, FileOperationType type, {String? backupPath}) {
    fileOperations[filePath] = FileOperation(
      path: filePath,
      type: type,
      backupPath: backupPath,
      timestamp: DateTime.now(),
    );
  }
  
  Future<void> rollbackAllFileOperations() async {
    // 按时间倒序回滚文件操作
    final sortedOps = fileOperations.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    for (final operation in sortedOps) {
      try {
        await _rollbackFileOperation(operation);
      } catch (e) {
        logger.error('文件回滚失败', error: e, data: {
          'operation': operation.toJson(),
        });
      }
    }
  }
  
  Future<void> _rollbackFileOperation(FileOperation operation) async {
    switch (operation.type) {
      case FileOperationType.create:
        // 删除创建的文件
        if (await File(operation.path).exists()) {
          await File(operation.path).delete();
        }
        break;
        
      case FileOperationType.update:
        // 恢复原始文件
        if (operation.backupPath != null && await File(operation.backupPath!).exists()) {
          await File(operation.backupPath!).copy(operation.path);
          await File(operation.backupPath!).delete();
        }
        break;
        
      case FileOperationType.delete:
        // 恢复已删除的文件
        if (operation.backupPath != null && await File(operation.backupPath!).exists()) {
          await File(operation.backupPath!).copy(operation.path);
          await File(operation.backupPath!).delete();
        }
        break;
    }
  }
}

enum FileOperationType { create, update, delete, move }
```

### 5. 智能回滚策略

```dart
class RollbackStrategy {
  Future<void> executeRollback(ImportTransaction transaction, Exception error) async {
    final strategy = _selectRollbackStrategy(transaction, error);
    
    switch (strategy) {
      case RollbackType.incrementalUndo:
        await _incrementalRollback(transaction);
        break;
        
      case RollbackType.snapshotRestore:
        await _snapshotRollback(transaction);
        break;
        
      case RollbackType.hybridRollback:
        await _hybridRollback(transaction);
        break;
    }
  }
  
  RollbackType _selectRollbackStrategy(ImportTransaction transaction, Exception error) {
    // 根据操作复杂度和错误类型选择回滚策略
    if (transaction.operations.length < 100 && error is! DataCorruptionException) {
      return RollbackType.incrementalUndo;
    } else if (error is DataCorruptionException) {
      return RollbackType.snapshotRestore;
    } else {
      return RollbackType.hybridRollback;
    }
  }
  
  Future<void> _incrementalRollback(ImportTransaction transaction) async {
    // 按操作顺序倒序回滚
    final operations = transaction.operations.reversed.toList();
    
    for (final operation in operations) {
      try {
        await _undoOperation(operation);
      } catch (e) {
        // 单个操作回滚失败时，记录错误但继续回滚其他操作
        logger.warning('操作回滚失败', error: e, data: {
          'operation': operation.toJson(),
        });
      }
    }
  }
  
  Future<void> _undoOperation(ImportOperation operation) async {
    switch (operation.type) {
      case ImportOperationType.createWork:
        await workRepository.deleteWork(operation.entityId);
        break;
        
      case ImportOperationType.updateWork:
        await workRepository.updateWork(
          operation.entityId, 
          WorkEntity.fromJson(operation.oldData)
        );
        break;
        
      case ImportOperationType.createCharacter:
        await characterRepository.deleteCharacter(operation.entityId);
        break;
        
      case ImportOperationType.updateCharacter:
        await characterRepository.updateCharacter(
          operation.entityId,
          CharacterEntity.fromJson(operation.oldData)
        );
        break;
        
      // ... 其他操作类型的回滚逻辑
    }
  }
}
```

### 6. 用户界面支持

```dart
class RollbackProgressUI {
  Widget buildRollbackDialog(ImportTransaction transaction) {
    return AlertDialog(
      title: Text('导入操作回滚中...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在撤销已执行的操作，请稍候...'),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: rollbackProgress.value,
          ),
          SizedBox(height: 8),
          Text(
            '${rollbackProgress.currentStep}/${rollbackProgress.totalSteps}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
  
  Future<void> showRollbackResult(RollbackResult result) async {
    final icon = result.isSuccess 
      ? Icon(Icons.check_circle, color: Colors.green, size: 48)
      : Icon(Icons.error, color: Colors.red, size: 48);
      
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            icon,
            SizedBox(width: 16),
            Text(result.isSuccess ? '回滚成功' : '回滚失败'),
          ],
        ),
        content: Text(result.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('确定'),
          ),
        ],
      ),
    );
  }
}
```

### 7. 回滚验证与恢复确认

```dart
class RollbackVerification {
  Future<bool> verifyRollbackSuccess(ImportTransaction transaction) async {
    try {
      // 验证数据库状态
      final dbValid = await _verifyDatabaseIntegrity();
      if (!dbValid) return false;
      
      // 验证文件系统状态
      final filesValid = await _verifyFileSystemIntegrity(transaction);
      if (!filesValid) return false;
      
      // 验证索引一致性
      final indexesValid = await _verifyIndexConsistency();
      if (!indexesValid) return false;
      
      // 验证缓存状态
      final cacheValid = await _verifyCacheConsistency();
      if (!cacheValid) return false;
      
      return true;
    } catch (e) {
      logger.error('回滚验证失败', error: e);
      return false;
    }
  }
  
  Future<void> emergencyRecovery(ImportTransaction transaction) async {
    // 紧急恢复程序，用于回滚失败的情况
    try {
      // 1. 停止所有相关服务
      await _stopCriticalServices();
      
      // 2. 从完整备份恢复数据库
      await _restoreFromFullBackup(transaction.snapshot.backupPath);
      
      // 3. 清理临时文件
      await _cleanupTemporaryFiles(transaction);
      
      // 4. 重建索引
      await _rebuildAllIndexes();
      
      // 5. 重启服务
      await _restartCriticalServices();
      
      logger.info('紧急恢复完成');
    } catch (e) {
      logger.error('紧急恢复失败', error: e);
      throw EmergencyRecoveryException('系统恢复失败，请联系技术支持', e);
    }
  }
}
```

## 数据格式与向下兼容性设计

### 1. 导出数据格式规范

#### 1.1 作品导出数据格式

```json
{
  "exportInfo": {
    "exportVersion": "1.0",
    "exportType": "practice",
    "timestamp": "2024-01-01T10:00:00Z",
    "itemCount": 1,
    "includeCharacters": true
  },
  "practices": [
    {
      "id": "practice-uuid",
      "title": "字帖标题",
      "pages": [...], // 现有PracticeEntity.pages结构
      "tags": ["标签1", "标签2"],
      "status": "active",
      "createTime": "2024-01-01T10:00:00Z",
      "updateTime": "2024-01-01T10:00:00Z",
      "isFavorite": false
    }
  ],
  "relatedCharacters": [
    {
      "id": "character-uuid",
      "workId": "work-uuid",
      "pageId": "page-uuid", 
      "character": "字",
      "region": {
        // CharacterRegion现有结构
      },
      "createTime": "2024-01-01T10:00:00Z",
      "updateTime": "2024-01-01T10:00:00Z",
      "isFavorite": false,
      "tags": ["标签"],
      "note": "备注"
    }
  ],
  "relatedWorks": [
    {
      "id": "work-uuid",
      "title": "作品标题",
      "author": "作者",
      "remark": "备注",
      "style": "楷书",
      "tool": "毛笔",
      "createTime": "2024-01-01T10:00:00Z",
      "updateTime": "2024-01-01T10:00:00Z",
      "isFavorite": false,
      "status": "draft",
      "firstImageId": "image-uuid",
      "images": [...], // WorkImage数组
      "tags": ["标签"],
      "imageCount": 3
    }
  ]
}
```

#### 1.2 集字导出数据格式

```json
{
  "exportInfo": {
    "exportVersion": "1.0", 
    "exportType": "character",
    "timestamp": "2024-01-01T10:00:00Z",
    "itemCount": 1,
    "includeSourceWorks": true
  },
  "characters": [
    {
      "id": "character-uuid",
      "workId": "work-uuid",
      "pageId": "page-uuid",
      "character": "字", 
      "region": {
        // CharacterRegion现有结构
      },
      "createTime": "2024-01-01T10:00:00Z",
      "updateTime": "2024-01-01T10:00:00Z",
      "isFavorite": false,
      "tags": ["标签"],
      "note": "备注"
    }
  ],
  "sourceWorks": [
    {
      // WorkEntity完整结构
    }
  ]
}
```

### 2. 向下兼容性策略

#### 2.1 版本控制
- **导出版本号**：每个导出文件包含 `exportVersion` 字段
- **当前版本**：1.0（基线版本，严格遵循现有数据结构）
- **向前兼容**：新版本必须能读取旧版本数据
- **字段扩展**：新增字段必须为可选，不影响现有功能

#### 2.2 数据结构保护
- **核心字段保护**：现有实体的核心字段（id, createTime等）不可删除或修改类型
- **字段添加规则**：新增字段必须有默认值或为可选类型
- **类型安全**：字段类型变更必须向下兼容（如string可扩展为string?，但不可逆）

#### 2.3 导入时的兼容性处理
```dart
class ImportCompatibilityHandler {
  /// 检查导入文件版本兼容性
  bool isCompatible(String exportVersion) {
    final version = Version.parse(exportVersion);
    final currentVersion = Version.parse("1.0");
    return version <= currentVersion;
  }
  
  /// 升级旧版本数据到当前版本
  Map<String, dynamic> upgradeToCurrentVersion(
    Map<String, dynamic> data, 
    String fromVersion
  ) {
    // 根据版本差异进行数据迁移
    switch (fromVersion) {
      case "1.0":
        return data; // 当前版本，无需升级
      default:
        throw UnsupportedError('不支持的版本: $fromVersion');
    }
  }
}
```

#### 2.4 自定义字段处理

##### 自定义 style 和 tool 处理
```dart
class CustomFieldHandler {
  /// 导出时收集所有自定义值
  static Map<String, Set<String>> collectCustomValues(
    List<WorkEntity> works, 
    List<CharacterEntity> characters
  ) {
    final customStyles = <String>{};
    final customTools = <String>{};
    
    // 从作品中收集
    for (final work in works) {
      if (work.style.isNotEmpty) customStyles.add(work.style);
      if (work.tool.isNotEmpty) customTools.add(work.tool);
    }
    
    return {
      'styles': customStyles,
      'tools': customTools,
    };
  }
  
  /// 导入时验证自定义值
  static ValidationResult validateCustomValues(
    Map<String, dynamic> importData
  ) {
    final customValues = importData['customValues'] as Map<String, dynamic>?;
    if (customValues == null) return ValidationResult.success();
    
    final styles = Set<String>.from(customValues['styles'] ?? []);
    final tools = Set<String>.from(customValues['tools'] ?? []);
    
    return ValidationResult(
      hasCustomStyles: styles.isNotEmpty,
      hasCustomTools: tools.isNotEmpty,
      customStyles: styles,
      customTools: tools,
    );
  }
}
```

##### 导出数据格式扩展
```json
{
  "exportInfo": {
    "exportVersion": "1.0",
    "exportType": "practice",
    "timestamp": "2024-01-01T10:00:00Z",
    "itemCount": 1,
    "includeCharacters": true,
    "hasCustomFields": true
  },
  "customValues": {
    "styles": ["行书", "草书", "自定义风格1"],
    "tools": ["毛笔", "钢笔", "自定义工具1"]
  },
  "practices": [...],
  "relatedWorks": [
    {
      "id": "work-uuid",
      "style": "自定义风格1",  // 自定义值直接使用
      "tool": "自定义工具1",   // 自定义值直接使用
      // ... 其他字段
    }
  ]
}
```

##### 导入时的处理策略
1. **自动接受**：直接导入所有自定义值到数据库
2. **用户确认**：向用户展示自定义值列表，让用户选择是否导入
3. **映射处理**：允许用户将导入的自定义值映射到现有值

```dart
class ImportCustomFieldsDialog {
  /// 显示自定义字段确认对话框
  static Future<CustomFieldsImportConfig?> showCustomFieldsDialog(
    BuildContext context,
    ValidationResult validation,
  ) async {
    return showDialog<CustomFieldsImportConfig>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('检测到自定义字段'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (validation.hasCustomStyles)
              _buildCustomFieldSection(
                '书法风格', 
                validation.customStyles
              ),
            if (validation.hasCustomTools)
              _buildCustomFieldSection(
                '书写工具', 
                validation.customTools
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 
              CustomFieldsImportConfig.acceptAll()),
            child: Text('全部导入'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context,
              CustomFieldsImportConfig.customize()),
            child: Text('自定义映射'),
          ),
        ],
      ),
    );
  }
}
```

#### 2.5 未来扩展预留
- **元数据扩展**：在exportInfo中预留扩展字段
- **实体扩展**：为每个实体预留metadata字段用于未来扩展
- **文件格式**：支持向压缩包中添加新类型文件而不影响现有解析
- **自定义字段索引**：在exportInfo中记录包含的自定义字段类型

## 技术架构设计

### 1. 服务层设计

#### 导出服务 (ExportService)
```dart
class ExportService {
  final DatabaseService databaseService;
  final FileSystemService fileSystemService;
  
  // 导出作品（完整数据库表处理）
  Future<String> exportWorks(
    List<String> workIds, {
    bool includeCharacters = true,
    String? outputPath,
    void Function(double progress)? onProgress,
  }) async {
    final transaction = await databaseService.beginTransaction();
    try {
      onProgress?.call(0.1);
      
      // 1. 查询works表主数据
      final works = await databaseService.getWorksByIds(workIds);
      
      // 2. 查询work_images表数据（关键表）
      final workImages = await databaseService.getWorkImagesByWorkIds(workIds);
      
      onProgress?.call(0.2);
      
      // 3. 查询关联集字数据（如果需要）
      List<CharacterEntity> characters = [];
      if (includeCharacters) {
        characters = await databaseService.getCharactersByWorkIds(workIds);
      }
      
      onProgress?.call(0.3);
      
      // 4. 收集自定义字段值
      final customValues = CustomFieldHandler.collectCustomValues(works, characters);
      
      // 5. 复制作品图片文件（基于work_images表）
      final exportDir = await _createExportDirectory();
      await _copyWorkImages(workImages, exportDir);
      
      onProgress?.call(0.6);
      
      // 6. 复制集字图片文件（如果需要）
      if (includeCharacters) {
        await _copyCharacterImages(characters, exportDir);
      }
      
      onProgress?.call(0.8);
      
      // 7. 生成导出清单
      final manifest = await _generateManifest(works, workImages, characters, customValues);
      
      // 8. 创建压缩包
      final exportPath = await _createCompressedFile(exportDir, manifest, outputPath);
      
      onProgress?.call(1.0);
      await transaction.commit();
      return exportPath;
    } catch (e) {
      await transaction.rollback();
      rethrow;
    }
  }
  
  // 处理work_images表的文件复制
  Future<void> _copyWorkImages(List<WorkImageEntity> workImages, String exportDir) async {
    for (final image in workImages) {
      final workImageDir = '$exportDir/work_images/${image.workId}';
      await fileSystemService.createDirectory(workImageDir);
      
      // 复制主图片文件
      if (await fileSystemService.fileExists(image.path)) {
        final targetMainPath = '$workImageDir/${image.id}_main.${image.format}';
        await fileSystemService.copyFile(image.path, targetMainPath);
      }
      
      // 复制缩略图文件（如果存在）
      if (image.thumbnailPath != null && await fileSystemService.fileExists(image.thumbnailPath!)) {
        final targetThumbnailPath = '$workImageDir/${image.id}_thumb.${image.format}';
        await fileSystemService.copyFile(image.thumbnailPath!, targetThumbnailPath);
      }
    }
  }
  
  // 导出集字
  Future<String> exportCharacters(
    List<String> characterIds, {
    bool includeSourceWorks = true,
    String? outputPath,
    void Function(double progress)? onProgress,
  });
  
  // 生成导出清单
  Future<String> generateManifest(ExportData data, Locale locale);
}
```

#### 导入服务 (ImportService)
```dart
class ImportService {
  final DatabaseService databaseService;
  final FileSystemService fileSystemService;
  final DecompressionService decompressionService;
  
  // 验证导入文件
  Future<ImportValidationResult> validateImportFile(String filePath);
  
  // 导入作品（完整数据库表处理）
  Future<ImportResult> importWorks(
    String filePath, {
    ImportOptions? options,
    void Function(double progress)? onProgress,
  }) async {
    final transaction = await databaseService.beginTransaction();
    String? tempDir;
    
    try {
      onProgress?.call(0.1);
      
      // 1. 验证文件完整性
      await _validateImportFile(filePath);
      
      // 2. 解压缩文件到临时目录
      tempDir = await decompressionService.extractToTemp(filePath);
      
      onProgress?.call(0.2);
      
      // 3. 读取并验证数据
      final importData = await _readImportData(tempDir);
      final works = importData['works'] as List<WorkEntity>;
      final workImages = importData['workImages'] as List<WorkImageEntity>;
      final characters = importData['characters'] as List<CharacterEntity>;
      
      onProgress?.call(0.3);
      
      // 4. 处理重复数据冲突
      final conflictResolution = await _resolveConflicts(works, workImages, characters);
      
      onProgress?.call(0.4);
      
      // 5. 按依赖顺序导入数据库记录
      await _importDatabaseRecords(works, workImages, characters, conflictResolution, onProgress);
      
      onProgress?.call(0.8);
      
      // 6. 复制文件到目标位置
      await _copyImportedFiles(tempDir, workImages, characters);
      
      onProgress?.call(0.9);
      
      // 7. 验证导入完整性
      await _validateImportedData(works, workImages, characters);
      
      onProgress?.call(1.0);
      await transaction.commit();
      return ImportResult.success(works.length, characters.length);
    } catch (e) {
      await transaction.rollback();
      if (tempDir != null) {
        await _cleanupTempFiles(tempDir);
      }
      rethrow;
    }
  }
  
  // 按依赖顺序导入数据库记录
  Future<void> _importDatabaseRecords(
    List<WorkEntity> works,
    List<WorkImageEntity> workImages, 
    List<CharacterEntity> characters,
    ConflictResolution resolution,
    void Function(double progress)? onProgress,
  ) async {
    final totalSteps = works.length + workImages.length + characters.length;
    int currentStep = 0;
    
    // 1. 先导入works表（主表）
    for (final work in works) {
      if (resolution.shouldSkipWork(work.id)) {
        currentStep++;
        continue;
      }
      
      await databaseService.insertWork(work);
      currentStep++;
      onProgress?.call(0.4 + (currentStep / totalSteps) * 0.3);
    }
    
    // 2. 再导入work_images表（依赖works表）
    for (final image in workImages) {
      if (resolution.shouldSkipWorkImage(image.id)) {
        currentStep++;
        continue;
      }
      
      // 验证关联的work是否存在
      final workExists = await databaseService.workExists(image.workId);
      if (!workExists) {
        throw ImportException('Work ${image.workId} not found for image ${image.id}');
      }
      
      await databaseService.insertWorkImage(image);
      currentStep++;
      onProgress?.call(0.4 + (currentStep / totalSteps) * 0.3);
    }
    
    // 3. 最后导入characters表
    for (final character in characters) {
      if (resolution.shouldSkipCharacter(character.id)) {
        currentStep++;
        continue;
      }
      
      await databaseService.insertCharacter(character);
      currentStep++;
      onProgress?.call(0.4 + (currentStep / totalSteps) * 0.3);
    }
  }
  
  // 复制导入的文件到目标位置
  Future<void> _copyImportedFiles(
    String tempDir,
    List<WorkImageEntity> workImages,
    List<CharacterEntity> characters
  ) async {
    // 处理work_images表对应的文件
    for (final image in workImages) {
      // 复制主图片文件
      final sourceMainPath = '$tempDir/work_images/${image.workId}/${image.id}_main.${image.format}';
      if (await fileSystemService.fileExists(sourceMainPath)) {
        final targetMainPath = await fileSystemService.getWorkImagePath(
          image.workId, 
          image.id, 
          image.format
        );
        await fileSystemService.copyFile(sourceMainPath, targetMainPath);
        
        // 更新数据库中的实际路径
        await databaseService.updateWorkImagePath(image.id, targetMainPath);
      }
      
      // 复制缩略图文件（如果存在）
      if (image.thumbnailPath != null) {
        final sourceThumbnailPath = '$tempDir/work_images/${image.workId}/${image.id}_thumb.${image.format}';
        if (await fileSystemService.fileExists(sourceThumbnailPath)) {
          final targetThumbnailPath = await fileSystemService.getWorkThumbnailPath(
            image.workId, 
            image.id, 
            image.format
          );
          await fileSystemService.copyFile(sourceThumbnailPath, targetThumbnailPath);
          
          // 更新数据库中的缩略图路径
          await databaseService.updateWorkImageThumbnailPath(image.id, targetThumbnailPath);
        }
      }
    }
    
    // 处理集字图片文件
    for (final character in characters) {
      final characterImageTypes = ['default', 'binary', 'outline', 'square-binary', 'square-outline', 'square-transparent'];
      for (final type in characterImageTypes) {
        final sourceImagePath = '$tempDir/characters/${character.id}/${character.id}-$type.png';
        if (await fileSystemService.fileExists(sourceImagePath)) {
          final targetImagePath = await fileSystemService.getCharacterImagePath(
            character.id, 
            type, 
            'png'
          );
          await fileSystemService.copyFile(sourceImagePath, targetImagePath);
        }
      }
    }
  }
  
  // 验证导入数据的完整性
  Future<void> _validateImportedData(
    List<WorkEntity> works,
    List<WorkImageEntity> workImages,
    List<CharacterEntity> characters
  ) async {
    // 验证works表数据
    for (final work in works) {
      final exists = await databaseService.workExists(work.id);
      if (!exists) {
        throw ImportValidationException('Work ${work.id} was not imported correctly');
      }
    }
    
    // 验证work_images表数据和文件
    for (final image in workImages) {
      final exists = await databaseService.workImageExists(image.id);
      if (!exists) {
        throw ImportValidationException('WorkImage ${image.id} was not imported correctly');
      }
      
      // 验证关联的图片文件是否存在
      final imageFileExists = await fileSystemService.fileExists(image.path);
      if (!imageFileExists) {
        throw ImportValidationException('Image file ${image.path} was not copied correctly');
      }
    }
    
    // 验证characters表数据
    for (final character in characters) {
      final exists = await databaseService.characterExists(character.id);
      if (!exists) {
        throw ImportValidationException('Character ${character.id} was not imported correctly');
      }
    }
  }
  
  // 导入集字
  Future<ImportResult> importCharacters(
    String filePath, {
    ImportOptions? options,
    void Function(double progress)? onProgress,
  });
}
```

### 2. 数据模型

#### 导出数据模型
```dart
class ExportData {
  final List<WorkEntity> works;
  final List<CharacterEntity> characters;
  final ExportOptions options;
  final DateTime exportTime;
  final ExportStatistics statistics;
}

class ExportOptions {
  final bool includeRelatedData;
  final CompressionLevel compressionLevel;
  final bool generateThumbnails;
}
```

#### 导入数据模型
```dart
class ImportValidationResult {
  final bool isValid;
  final List<ValidationError> errors;
  final List<ValidationWarning> warnings;
  final ImportPreview preview;
}

class ImportResult {
  final bool isSuccess;
  final int importedCount;
  final int skippedCount;
  final List<ImportError> errors;
  final ImportStatistics statistics;
}
```

### 3. UI组件设计

#### 导出对话框
```dart
class ExportDialog extends StatefulWidget {
  final List<String> selectedIds;
  final ExportType exportType; // works or characters
  
  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: ExportDialogContent(),
    );
  }
}
```

#### 导入对话框
```dart
class ImportDialog extends StatefulWidget {
  final ImportType importType; // works or characters
  
  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: ImportDialogContent(),
    );
  }
}
```

#### 进度对话框
```dart
class ProgressDialog extends StatelessWidget {
  final String title;
  final String message;
  final double progress;
  final bool canCancel;
  final VoidCallback? onCancel;
}
```

### 4. 状态管理

#### 导出状态
```dart
class ExportState {
  final ExportStatus status;
  final double progress;
  final String? currentTask;
  final String? filePath;
  final String? errorMessage;
}

enum ExportStatus {
  idle, preparing, exporting, compressing, completed, error, cancelled
}
```

#### 导入状态
```dart
class ImportState {
  final ImportStatus status;
  final double progress;
  final String? currentTask;
  final ImportValidationResult? validationResult;
  final ImportResult? result;
  final String? errorMessage;
}

enum ImportStatus {
  idle, validating, confirming, importing, completed, error, cancelled
}
```

## 异常处理机制

### 1. 文件系统异常

#### 存储空间不足
```dart
try {
  await exportService.exportWorks(workIds);
} on InsufficientStorageException catch (e) {
  showDialog(
    context: context,
    builder: (context) => StorageErrorDialog(
      requiredSpace: e.requiredSpace,
      availableSpace: e.availableSpace,
    ),
  );
}
```

#### 文件访问权限
```dart
try {
  final result = await importService.importWorks(filePath);
} on FileAccessException catch (e) {
  showDialog(
    context: context,
    builder: (context) => FileAccessErrorDialog(
      filePath: e.filePath,
      errorType: e.errorType,
    ),
  );
}
```

### 2. 数据完整性异常

#### 文件损坏
```dart
class CorruptedFileException implements Exception {
  final String filePath;
  final String corruptedSection;
  final String details;
}
```

#### 数据重复
```dart
class DuplicateDataException implements Exception {
  final List<String> duplicateIds;
  final DuplicateStrategy suggestedStrategy;
}
```

### 3. 网络和系统异常

#### 操作超时
```dart
class OperationTimeoutException implements Exception {
  final Duration timeout;
  final String operation;
}
```

#### 系统资源不足
```dart
class SystemResourceException implements Exception {
  final ResourceType resourceType;
  final String details;
}
```

### 4. 自定义字段异常处理

#### 自定义字段相关异常
```dart
class CustomFieldException implements Exception {
  final String fieldType; // 'style' or 'tool'
  final String fieldValue;
  final String errorType;
}

class CustomFieldValidationException extends CustomFieldException {
  CustomFieldValidationException(String fieldType, String fieldValue)
    : super(fieldType, fieldValue, 'validation_failed');
}

class CustomFieldConflictException extends CustomFieldException {
  final List<String> conflictingValues;
  CustomFieldConflictException(String fieldType, String fieldValue, this.conflictingValues)
    : super(fieldType, fieldValue, 'conflict_detected');
}
```

#### 自定义字段异常处理流程
```dart
try {
  await importService.importWorksWithCustomFields(filePath, config);
} on CustomFieldValidationException catch (e) {
  // 自定义字段验证失败
  final shouldContinue = await showDialog<bool>(
    context: context,
    builder: (context) => CustomFieldErrorDialog(
      fieldType: e.fieldType,
      fieldValue: e.fieldValue,
      errorMessage: '检测到未知的${e.fieldType}值: ${e.fieldValue}',
      options: ['忽略此字段', '替换为默认值', '取消导入'],
    ),
  );
} on CustomFieldConflictException catch (e) {
  // 自定义字段冲突
  final resolution = await showDialog<CustomFieldResolution>(
    context: context,
    builder: (context) => CustomFieldConflictDialog(
      fieldType: e.fieldType,
      newValue: e.fieldValue,
      existingValues: e.conflictingValues,
    ),
  );
}
```

### 5. 用户友好的错误处理

#### 错误分级处理
1. **轻微错误**：显示警告，允许用户继续
2. **严重错误**：显示错误对话框，提供解决方案
3. **致命错误**：停止操作，显示详细错误信息

#### 错误恢复机制
1. **自动重试**：对于临时性错误自动重试
2. **部分成功**：当部分操作成功时，允许用户选择处理方式
3. **操作回滚**：对于导入操作，提供回滚机制

## 用户界面设计

### 1. 批量操作工具栏增强

#### 作品浏览页工具栏

**普通模式：**
```
[导入] [批量模式]
```

**批量模式（已选择项目时）：**
```
[导入] [批量模式] | 已选择: 5项 [批量导入] [全选] [取消选择] [导出] [删除]
```

#### 集字管理页工具栏

**普通模式：**
```
[导入] [批量模式]
```

**批量模式（已选择项目时）：**
```
[导入] [批量模式] | 已选择: 12项 [批量导入] [全选] [取消选择] [导出] [删除]
```

### 2. 导出对话框设计

#### 布局结构
```
┌─ 导出作品 ──────────────────────────────┐
│                                        │
│ 导出选项                                │
│ ○ 仅导出作品                            │
│ ● 导出作品及关联集字                     │
│                                        │
│ 输出设置                                │
│ 文件名: [exported_works_20240115]       │
│ 路径: [/Users/.../Downloads] [浏览]     │
│ 压缩级别: [标准 ▼]                      │
│                                        │
│ 预览信息                                │
│ 作品数量: 5                            │
│ 预计集字数量: 23                        │
│ 预计文件大小: 45.2 MB                   │
│                                        │
│              [取消] [开始导出]           │
└────────────────────────────────────────┘
```

### 3. 导入对话框设计

#### 布局结构
```
┌─ 导入作品 ──────────────────────────────┐
│                                        │
│ 文件选择                                │
│ [选择文件] exported_works_20240115.zip   │
│                                        │
│ 导入选项                                │
│ 重复处理: [跳过重复项 ▼]                │
│ □ 验证文件完整性                        │
│ □ 生成导入报告                          │
│                                        │
│ 预览信息 (验证后显示)                    │
│ 作品数量: 5                            │
│ 集字数量: 23                           │
│ 冲突项目: 2                            │
│                                        │
│              [取消] [开始导入]           │
└────────────────────────────────────────┘
```

### 4. 进度对话框设计

#### 布局结构
```
┌─ 正在导出... ───────────────────────────┐
│                                        │
│ 当前任务: 正在压缩文件...                │
│                                        │
│ ████████████████████░░░░ 85%            │
│                                        │
│ 已处理: 4/5 作品                        │
│ 已用时间: 00:02:15                      │
│ 预计剩余: 00:00:25                      │
│                                        │
│                    [取消]               │
└────────────────────────────────────────┘
```

### 6. 自定义字段处理策略

#### 自动接受策略（唯一策略）
- 直接将所有自定义 `style` 和 `tool` 值导入到数据库
- 保持数据的完整性，不丢失任何信息
- 简单高效，无需用户干预

### 7. Settings表配置处理

#### 配置同步策略
Settings表存储了系统的关键配置信息，包括：
- `style_configs`: 书法风格配置（楷书、行书、草书等）
- `tool_configs`: 书写工具配置（毛笔、硬笔等）
- 用户偏好设置（默认阈值、画笔大小等）
- 系统配置项

#### 处理规则
1. **系统预设配置保护**: 不导入/导出系统预设的style_configs和tool_configs，避免覆盖用户当前配置
2. **用户自定义配置导入**: 只导入用户自定义的style和tool配置项（isSystem=false的条目）
3. **配置合并策略**: 
   - 如果导入的自定义配置与现有配置重复（相同key），则跳过
   - 如果是新的自定义配置，则添加到现有配置列表中
4. **用户偏好设置**: 不处理其他用户偏好设置（如default_threshold等），保持当前用户环境

#### 实现细节
- **导出时**：不包含settings表数据，仅导出works、work_images、characters表的数据
- **导入时**：从导入的style和tool字段中提取自定义值，自动添加到本地style_configs和tool_configs中
- **配置更新**：使用ConfigRepository的现有API添加新的自定义配置项
- **容错保障**：如果配置服务异常，仍能正常导入数据，新的自定义值会在配置恢复后自动识别

#### 容错机制
当Settings表配置缺失或损坏时，各项功能依然能正常运行：

1. **UI组件容错**：下拉选择器会回退到硬编码的基础选项（楷书、行书、草书等）
2. **服务层容错**：ConfigService返回空列表/映射而不抛出异常
3. **自动恢复**：首次访问配置时会自动初始化默认配置
4. **导入容错**：即使配置服务异常，导入的自定义style/tool值会被保存到works表，配置恢复后可重新识别
5. **显示名称回退**：找不到对应displayName时直接使用key值显示，确保界面始终可用

#### 显示名称处理机制
当无法获取配置的显示名称时，系统会优雅地回退到key值：

```dart
// 当前代码中的实现方式
final displayName = ref.watch(styleDisplayNamesProvider).maybeWhen(
  data: (names) => names[item.key] ?? item.displayName,  // 第一级回退：使用item.displayName
  orElse: () => item.displayName,                        // 第二级回退：使用item.displayName
);

// 只读模式下的回退机制
final displayText = value != null 
  ? displayNames[value] ?? fallbackDisplayName    // 使用key值作为fallback
  : '';

// 导入时自定义配置显示
// 如果导入的作品使用了自定义style="行楷"，但本地没有对应配置：
// - 在下拉列表中会显示"行楷"（直接使用key值）
// - 功能完全正常，用户可以正常保存和使用
// - 配置服务恢复后会自动添加"行楷"到配置选项中
```

#### 导入时配置处理流程
```dart
Future<void> _processCustomConfigs(List<WorkEntity> importedWorks) async {
  try {
    // 尝试正常的配置处理流程
    await _addCustomConfigsToSettings(importedWorks);
  } catch (e) {
    // 配置服务异常时记录日志，但不影响导入
    logger.warning('配置更新失败，将在配置恢复后重新处理', 
      data: {'error': e.toString()});
    // 数据已经导入到works表，自定义值得到保留
  }
}
```

### 8. 过滤面板动态选项支持

#### 问题描述
当导入包含自定义style/tool的作品后，如果这些自定义值没有被添加到Settings配置中，过滤面板就无法显示这些选项，用户无法筛选相关作品。

#### 解决方案：混合选项提供者
为过滤面板创建新的Provider，结合配置选项和数据库中实际使用的值：

```dart
/// 过滤面板专用的风格选项提供者 - 包含配置选项 + 数据库实际值
final filterStyleOptionsProvider = FutureProvider<List<FilterOption>>((ref) async {
  // 1. 获取配置中的激活选项
  final configItems = await ref.watch(configServiceProvider)
    .getActiveConfigItems(ConfigCategories.style);
  
  // 2. 获取数据库中实际使用的风格值
  final usedStyles = await ref.watch(workRepositoryProvider)
    .getDistinctStyles();
  
  // 3. 合并并去重
  final options = <FilterOption>[];
  final seenKeys = <String>{};
  
  // 优先添加配置项（有displayName）
  for (final item in configItems) {
    if (!seenKeys.contains(item.key)) {
      options.add(FilterOption(
        key: item.key,
        displayName: item.displayName,
        isFromConfig: true,
      ));
      seenKeys.add(item.key);
    }
  }
  
  // 添加数据库中的额外值（使用key作为displayName）
  for (final style in usedStyles) {
    if (!seenKeys.contains(style) && style.isNotEmpty) {
      options.add(FilterOption(
        key: style,
        displayName: style, // 直接使用key值
        isFromConfig: false,
      ));
      seenKeys.add(style);
    }
  }
  
  return options;
});

/// 过滤选项数据模型
class FilterOption {
  final String key;
  final String displayName;
  final bool isFromConfig; // 是否来自配置（用于样式区分）
  
  const FilterOption({
    required this.key,
    required this.displayName,
    required this.isFromConfig,
  });
}

/// WorkRepository中新增方法
abstract class WorkRepository {
  // ... 现有方法
  
  /// 获取数据库中所有实际使用的书法风格
  Future<List<String>> getDistinctStyles();
  
  /// 获取数据库中所有实际使用的书写工具
  Future<List<String>> getDistinctTools();
}
```

#### 过滤面板UI更新
```dart
// M3FilterStyleSection更新
final filterOptions = ref.watch(filterStyleOptionsProvider);

return filterOptions.when(
  data: (options) => Wrap(
    children: options.map((option) {
      final isSelected = selectedStyle == option.key;
      return FilterChip(
        label: Text(option.displayName),
        selected: isSelected,
        onSelected: (selected) {
          onStyleChanged(selected ? option.key : null);
        },
        // 为非配置项添加视觉区别
        backgroundColor: option.isFromConfig 
          ? null 
          : Theme.of(context).colorScheme.surfaceVariant,
        side: option.isFromConfig 
          ? null 
          : BorderSide(
              color: Theme.of(context).colorScheme.outline,
              style: BorderStyle.solid,
            ),
      );
    }).toList(),
  ),
  loading: () => const CircularProgressIndicator(),
  error: (error, stackTrace) => Text('加载选项失败'),
);
```

#### 数据库查询实现
```dart
// WorkRepositoryImpl中新增方法
@override
Future<List<String>> getDistinctStyles() async {
  final result = await _db.rawQuery(
    'SELECT DISTINCT style FROM works WHERE style IS NOT NULL AND style != "" ORDER BY style'
  );
  return result.map((row) => row['style'] as String).toList();
}

@override
Future<List<String>> getDistinctTools() async {
  final result = await _db.rawQuery(
    'SELECT DISTINCT tool FROM works WHERE tool IS NOT NULL AND tool != "" ORDER BY tool'
  );
  return result.map((row) => row['tool'] as String).toList();
}
```

#### 优势
1. **零遗漏**：所有数据库中的作品都能被筛选到
2. **视觉区分**：用户能区分配置选项和临时选项
3. **自动同步**：导入后立即可用，无需手动配置
4. **向下兼容**：不影响现有的配置管理功能

#### 自定义配置发现和添加流程
```dart
// 1. 从导入数据中发现自定义配置
Set<String> importedStyles = importedWorks
    .map((work) => work.style)
    .where((style) => style != null)
    .toSet();

Set<String> importedTools = importedWorks
    .map((work) => work.tool)
    .where((tool) => tool != null)
    .toSet();

// 2. 获取现有配置
List<ConfigItem> existingStyles = await configRepository
    .getConfigsByCategory('style');
List<ConfigItem> existingTools = await configRepository
    .getConfigsByCategory('tool');

Set<String> existingStyleKeys = existingStyles
    .map((item) => item.key)
    .toSet();
Set<String> existingToolKeys = existingTools
    .map((item) => item.key)
    .toSet();

// 3. 找出新的自定义配置
Set<String> newStyles = importedStyles
    .difference(existingStyleKeys);
Set<String> newTools = importedTools
    .difference(existingToolKeys);

// 4. 添加新的自定义配置项
for (String style in newStyles) {
  final newStyleConfig = ConfigItem(
    key: style,
    displayName: style,
    isSystem: false,
    isActive: true,
    sortOrder: existingStyles.length + 1,
  );
  await configRepository.addConfig('style', newStyleConfig);
}

for (String tool in newTools) {
  final newToolConfig = ConfigItem(
    key: tool,
    displayName: tool,
    isSystem: false,
    isActive: true,
    sortOrder: existingTools.length + 1,
  );
  await configRepository.addConfig('tool', newToolConfig);
}
```

## 本地化支持

### 1. 新增本地化键值

#### 导出相关
```json
{
  "exportWorks": "导出作品",
  "exportCharacters": "导出集字",
  "exportWorksOnly": "仅导出作品",
  "exportWorksWithCharacters": "导出作品及关联集字",
  "exportCharactersOnly": "仅导出集字",
  "exportCharactersWithWorks": "导出集字及来源作品",
  "exportOptions": "导出选项",
  "exportSettings": "输出设置",
  "exportFileName": "文件名",
  "exportPath": "路径",
  "compressionLevel": "压缩级别",
  "estimatedFileSize": "预计文件大小",
  "startExport": "开始导出",
  "exportProgress": "导出进度",
  "exportCompleted": "导出完成",
  "exportFailed": "导出失败"
}
```

#### 导入相关
```json
{
  "importWorks": "导入作品",
  "importCharacters": "导入集字",
  "importOptions": "导入选项",
  "customFieldsDetected": "检测到自定义字段",
  "acceptAllCustomFields": "全部导入
  "duplicateHandling": "重复处理",
  "skipDuplicates": "跳过重复项",
  "overwriteDuplicates": "覆盖重复项",
  "renameDuplicates": "重命名重复项",
  "validateFileIntegrity": "验证文件完整性",
  "generateImportReport": "生成导入报告",
  "previewInfo": "预览信息",
  "conflictItems": "冲突项目",
  "startImport": "开始导入",
  "importProgress": "导入进度",
  "importCompleted": "导入完成",
  "importFailed": "导入失败"
}
```

#### 批量操作
```json
{
  "selectAll": "全选",
  "deselectAll": "取消选择",
  "selectedItems": "已选择: {count} 项",
  "batchExport": "批量导出",
  "batchImport": "批量导入"
}
```

#### 错误信息
```json
{
  "errorInsufficientStorage": "存储空间不足，需要 {required}，可用 {available}",
  "errorFileAccess": "无法访问文件：{filePath}",
  "errorCorruptedFile": "文件已损坏：{details}",
  "errorDuplicateData": "发现 {count} 个重复项",
  "errorOperationTimeout": "操作超时：{operation}",
  "errorSystemResource": "系统资源不足：{details}"
}
```

### 2. 导出清单本地化

#### 中文清单模板
```
=== 作品导出清单 ===
导出时间：{exportTime}
导出选项：{exportOption}

=== 汇总信息 ===
作品总数：{workCount}
集字总数：{characterCount}
图片文件：{imageCount}
数据文件：{dataFileCount}
压缩包大小：{fileSize}

=== 详细信息 ===
...
```

#### 英文清单模板
```
=== Work Export Manifest ===
Export Time: {exportTime}
Export Option: {exportOption}

=== Summary ===
Total Works: {workCount}
Total Characters: {characterCount}
Image Files: {imageCount}
Data Files: {dataFileCount}
Archive Size: {fileSize}

=== Details ===
...
```

## 实现计划

### 第一阶段：基础架构（1-2周）

#### 任务清单
1. **创建服务层**
   - [ ] 实现 `ExportService` 基础架构
   - [ ] 实现 `ImportService` 基础架构
   - [ ] 创建数据模型和异常类型
   - [ ] 实现文件压缩和解压缩功能

2. **状态管理**
   - [ ] 创建导出状态管理器
   - [ ] 创建导入状态管理器
   - [ ] 实现进度跟踪机制

3. **基础UI组件**
   - [ ] 实现进度对话框
   - [ ] 实现错误对话框
   - [ ] 创建文件选择组件

### 第二阶段：作品导出导入（2-3周）

#### 任务清单
1. **作品导出功能**
   - [ ] 实现作品数据导出
   - [ ] 实现关联集字导出
   - [ ] 实现导出清单生成
   - [ ] 实现文件压缩和打包

2. **作品导入功能**
   - [ ] 实现文件验证机制
   - [ ] 实现冲突检测和处理
   - [ ] 实现作品数据导入
   - [ ] 实现关联集字导入

3. **作品浏览页UI**
   - [ ] 添加导出按钮和对话框
   - [ ] 添加导入按钮和对话框
   - [ ] 添加全选和取消选择按钮
   - [ ] 集成进度显示

### 第三阶段：集字导出导入（2-3周）

#### 任务清单
1. **集字导出功能**
   - [ ] 实现集字数据导出
   - [ ] 实现来源作品导出
   - [ ] 实现多格式图片导出
   - [ ] 实现导出清单生成

2. **集字导入功能**
   - [ ] 实现集字文件验证
   - [ ] 实现孤立集字处理
   - [ ] 实现虚拟作品创建
   - [ ] 实现图片完整性检查

3. **集字管理页UI**
   - [ ] 添加导出按钮和对话框
   - [ ] 添加导入按钮和对话框
   - [ ] 添加全选和取消选择按钮
   - [ ] 集成进度显示

### 第四阶段：异常处理和优化（1-2周）

#### 任务清单
1. **异常处理**
   - [ ] 实现所有异常类型的处理
   - [ ] 实现错误恢复机制
   - [ ] 实现操作回滚功能
   - [ ] 实现用户友好的错误提示

2. **性能优化**
   - [ ] 优化大文件处理性能
   - [ ] 实现断点续传功能
   - [ ] 优化内存使用
   - [ ] 实现并行处理

3. **本地化**
   - [ ] 完成所有文本的本地化
   - [ ] 实现导出清单的多语言支持
   - [ ] 测试各语言环境下的功能

### 第五阶段：测试和文档（1周）

#### 任务清单
1. **功能测试**
   - [ ] 单元测试覆盖所有核心功能
   - [ ] 集成测试验证端到端流程
   - [ ] 异常场景测试
   - [ ] 性能测试

2. **用户测试**
   - [ ] 用户体验测试
   - [ ] 界面一致性检查
   - [ ] 多语言环境测试

3. **文档更新**
   - [ ] 更新用户手册
   - [ ] 更新开发文档
   - [ ] 创建功能演示视频

### 风险评估

#### 高风险项
1. **大文件处理**：导出/导入大量作品时可能出现内存问题
2. **文件完整性**：压缩/解压过程中的数据损坏风险
3. **跨平台兼容性**：不同操作系统的文件路径和权限问题

#### 风险缓解措施
1. **分块处理**：对大文件进行分块处理，避免内存溢出
2. **校验机制**：实现多层校验，确保数据完整性
3. **平台测试**：在所有目标平台进行充分测试

### 成功标准

1. **功能完整性**：所有设计的功能都能正常工作
2. **用户体验**：操作流程直观，错误处理友好
3. **性能表现**：大文件操作流畅，响应及时
4. **稳定性**：异常情况下不会导致数据丢失或应用崩溃
5. **本地化质量**：多语言环境下功能和文本显示正确

---

**文档版本**：1.0  
**创建日期**：2024年1月15日  
**最后更新**：2024年1月15日  
**审核状态**：待审核 