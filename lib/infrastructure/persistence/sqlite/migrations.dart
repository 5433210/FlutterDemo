/// SQLite数据库迁移脚本
const migrations = [
  // 版本 1: 创建基础表结构
  '''
  -- 作品表
  CREATE TABLE IF NOT EXISTS works (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT,
    style TEXT,
    tool TEXT,
    remark TEXT,
    creationDate TEXT,
    createTime TEXT NOT NULL,
    updateTime TEXT NOT NULL,
    tags TEXT,
    status TEXT NOT NULL DEFAULT 'draft',
    imageCount INTEGER DEFAULT 0
  );

  -- 角色表
  CREATE TABLE IF NOT EXISTS characters (
    id TEXT PRIMARY KEY,
    workId TEXT NOT NULL,
    pageId TEXT NOT NULL,
    character TEXT NOT NULL,
    region TEXT NOT NULL,
    tags TEXT,
    createTime TEXT NOT NULL,
    updateTime TEXT NOT NULL,
    FOREIGN KEY (workId) REFERENCES works (id) ON DELETE CASCADE
  );

  -- 字帖表
  CREATE TABLE IF NOT EXISTS practices (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    pages TEXT NOT NULL,
    tags TEXT,
    createTime TEXT NOT NULL,
    updateTime TEXT NOT NULL
  );

  -- 标签表
  CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT
  );

  -- 设置表
  CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updateTime TEXT NOT NULL
  );

  -- 创建索引
  CREATE INDEX IF NOT EXISTS idx_characters_workId ON characters(workId);
  CREATE INDEX IF NOT EXISTS idx_characters_char ON characters(character);
  
  
  ''',
  // 版本 2: 添加作品图片管理 - 表和索引
  '''
  
  
  CREATE TABLE IF NOT EXISTS work_images (
    id TEXT PRIMARY KEY,
    workId TEXT NOT NULL,
    indexInWork INTEGER NOT NULL,
    path TEXT NOT NULL,
    original_path TEXT,
    thumbnail_path TEXT,
    format TEXT NOT NULL,
    size INTEGER NOT NULL,
    width INTEGER NOT NULL,
    height INTEGER NOT NULL,
    createTime TEXT NOT NULL,
    updateTime TEXT NOT NULL,
    FOREIGN KEY (workId) REFERENCES works (id) ON DELETE CASCADE
  );

  CREATE INDEX IF NOT EXISTS idx_work_images_workId ON work_images(workId);
  CREATE INDEX IF NOT EXISTS idx_work_images_index ON work_images(workId, indexInWork);
  CREATE INDEX IF NOT EXISTS idx_work_images_original_path ON work_images(workId, original_path);
  CREATE UNIQUE INDEX IF NOT EXISTS idx_work_images_unique_path 
  ON work_images(workId, original_path)
  WHERE original_path IS NOT NULL;
  
  
  ''',

  // 版本 3: 添加作品字段
  '''
  
  
  ALTER TABLE works ADD COLUMN firstImageId TEXT REFERENCES work_images(id);
  ALTER TABLE works ADD COLUMN lastImageUpdateTime TEXT;
  
  
  ''',

  // 版本 4: 添加触发器
  '''
  
  
  CREATE TRIGGER IF NOT EXISTS update_work_image_count_insert
  AFTER INSERT ON work_images
  BEGIN
    UPDATE works
    SET imageCount = (
      SELECT COUNT(*)
      FROM work_images
      WHERE workId = NEW.workId
    )
    WHERE id = NEW.workId;
  END;

  CREATE TRIGGER IF NOT EXISTS update_work_image_count_delete
  AFTER DELETE ON work_images
  BEGIN
    UPDATE works
    SET imageCount = (
      SELECT COUNT(*)
      FROM work_images
      WHERE workId = OLD.workId
    )
    WHERE id = OLD.workId;
  END;

  CREATE TRIGGER IF NOT EXISTS update_work_first_image_on_insert
  AFTER INSERT ON work_images
  BEGIN
    UPDATE works
    SET firstImageId = (
      SELECT id
      FROM work_images
      WHERE workId = NEW.workId
      ORDER BY indexInWork ASC
      LIMIT 1
    ),
    lastImageUpdateTime = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
    WHERE id = NEW.workId;
  END;

  CREATE TRIGGER IF NOT EXISTS update_work_first_image_on_update
  AFTER UPDATE OF indexInWork ON work_images
  BEGIN
    UPDATE works
    SET firstImageId = (
      SELECT id
      FROM work_images
      WHERE workId = NEW.workId
      ORDER BY indexInWork ASC
      LIMIT 1
    ),
    lastImageUpdateTime = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
    WHERE id = NEW.workId;
  END;

  CREATE TRIGGER IF NOT EXISTS update_work_first_image_on_delete
  AFTER DELETE ON work_images
  BEGIN
    UPDATE works
    SET firstImageId = (
      SELECT id FROM work_images WHERE workId = OLD.workId ORDER BY indexInWork ASC LIMIT 1
    ),
    lastImageUpdateTime = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
    WHERE id = OLD.workId;
  END;
  
  
  ''',
  // 版本 5: 添加字符收藏功能
  '''
  
  
  ALTER TABLE characters ADD COLUMN isFavorite INTEGER NOT NULL DEFAULT 0;
  ALTER TABLE characters ADD COLUMN note TEXT;
  
  
  ''',

  // 版本 6: 添加临时工作项
  '''
  
  
  INSERT OR IGNORE INTO works (
    id,
    title,
    author,
    status,
    createTime,
    updateTime
  ) VALUES (
    'temp',
    '临时工作项',
    'system',
    'draft',
    datetime('now'),
    datetime('now')
  );
  
  
  ''',

  /// 版本 7: 添加CharacterView视图
  '''
  
  
  CREATE VIEW IF NOT EXISTS CharacterView AS
  SELECT 
    c.id,
    c.character,
    c.isFavorite,
    c.createTime AS collectionTime,
    c.updateTime,
    c.pageId,
    c.workId,
    c.tags,
    c.region,
    c.note,
    w.style,
    w.tool,
    w.title,
    w.author,
    w.creationDate As creationTime
  FROM 
    characters c
  LEFT JOIN
    works w ON c.workId = w.id;
  
  
  ''',

  /// 版本 8: 为 practices 表添加缩略图字段
  '''
  
  
  ALTER TABLE practices ADD COLUMN thumbnail BLOB;
  
  
  ''',

  /// 版本 9: 添加图库表结构 - 表
  '''
  
  
  CREATE TABLE IF NOT EXISTS library_items (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    format TEXT NOT NULL,
    path TEXT NOT NULL,
    width INTEGER NOT NULL,
    height INTEGER NOT NULL,
    size INTEGER NOT NULL,
    tags TEXT,
    categories TEXT,
    metadata TEXT,
    isFavorite INTEGER DEFAULT 0,
    thumbnailPath TEXT,
    thumbnail BLOB,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL,
    createTime TEXT NOT NULL,
    updateTime TEXT NOT NULL
  );
  
  
  ''',

  /// 版本 10: 添加图库分类表
  '''
  
  
  CREATE TABLE IF NOT EXISTS library_categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    parentId TEXT,
    sortOrder INTEGER DEFAULT 0,
    createTime TEXT NOT NULL,
    updateTime TEXT NOT NULL
  );
  
  
  ''',

  /// 版本 11: 添加图库索引
  '''
  
  
  CREATE INDEX IF NOT EXISTS idx_library_items_name ON library_items(name);
  CREATE INDEX IF NOT EXISTS idx_library_items_type ON library_items(type);
  CREATE INDEX IF NOT EXISTS idx_library_categories_name ON library_categories(name);
  
  
  ''',

  /// 版本 12: 为library_items表添加新列
  '''
  
  
  -- Check if columns exist before adding
 
  
  -- 将已有的时间戳数据复制到新列
  UPDATE library_items SET
    createdAt = createTime,
    updatedAt = updateTime
  WHERE createdAt IS NULL;
  
  
  ''',

  /// 版本 13: 为library_items表添加remarks列
  '''
  
  
  ALTER TABLE library_items ADD COLUMN remarks TEXT;
  
  
  ''',

  /// 版本 14: 重命名 library_items 表的字段
  '''
  
  
  -- 添加新字段
  ALTER TABLE library_items ADD COLUMN fileName TEXT;
  ALTER TABLE library_items ADD COLUMN fileSize INTEGER;
  ALTER TABLE library_items ADD COLUMN fileCreatedAt TEXT;
  ALTER TABLE library_items ADD COLUMN fileUpdatedAt TEXT;
  
  -- 复制数据
  UPDATE library_items SET
    fileName = name,
    fileSize = size,
    fileCreatedAt = createdAt,
    fileUpdatedAt = updatedAt;
  
  -- 创建新的临时表，不包含旧字段
  CREATE TABLE library_items_temp (
    id TEXT PRIMARY KEY,
    fileName TEXT NOT NULL,
    type TEXT NOT NULL,
    format TEXT NOT NULL,
    path TEXT NOT NULL,
    width INTEGER NOT NULL,
    height INTEGER NOT NULL,
    fileSize INTEGER NOT NULL,
    tags TEXT,
    categories TEXT,
    metadata TEXT,
    isFavorite INTEGER DEFAULT 0,
    thumbnail BLOB,
    fileCreatedAt TEXT NOT NULL,
    fileUpdatedAt TEXT NOT NULL,
    createTime TEXT NOT NULL,
    updateTime TEXT NOT NULL,
    remarks TEXT
  );
  
  -- 复制数据到新表
  INSERT INTO library_items_temp SELECT
    id, fileName, type, format, path, width, height, fileSize,
    tags, categories, metadata, isFavorite, thumbnail,
    fileCreatedAt, fileUpdatedAt, createTime, updateTime, remarks
  FROM library_items;
  
  -- 删除旧表
  DROP TABLE library_items;
  
  -- 重命名新表
  ALTER TABLE library_items_temp RENAME TO library_items;
  
  -- 重新创建索引
  CREATE INDEX IF NOT EXISTS idx_library_items_fileName ON library_items(fileName);
  CREATE INDEX IF NOT EXISTS idx_library_items_type ON library_items(type);
  
  
  ''',

  /// 版本 15: 为works表添加收藏字段
  '''
  
  
  ALTER TABLE works ADD COLUMN isFavorite INTEGER NOT NULL DEFAULT 0;
  
  
  ''',

  /// 版本 16: 为practices表添加收藏字段
  '''
  
  
  ALTER TABLE practices ADD COLUMN isFavorite INTEGER NOT NULL DEFAULT 0;
  
  
  ''',

  /// 版本 17: 删除创作日期字段，初始化动态配置
  '''
  -- 0. 首先删除所有相关触发器和视图，避免在表重建过程中出错
  DROP TRIGGER IF EXISTS update_work_image_count_insert;
  DROP TRIGGER IF EXISTS update_work_image_count_delete;
  DROP TRIGGER IF EXISTS update_work_first_image_on_insert;
  DROP TRIGGER IF EXISTS update_work_first_image_on_update;
  DROP TRIGGER IF EXISTS update_work_first_image_on_delete;
  
  -- 删除依赖works表的视图
  DROP VIEW IF EXISTS CharacterView;
  
  -- 1. 创建新的works表（不包含creationDate字段）
  CREATE TABLE IF NOT EXISTS works_new (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT,
    style TEXT,
    tool TEXT,
    remark TEXT,
    createTime TEXT NOT NULL,
    updateTime TEXT NOT NULL,
    tags TEXT,
    status TEXT NOT NULL DEFAULT 'draft',
    imageCount INTEGER DEFAULT 0,
    firstImageId TEXT,
    lastImageUpdateTime TEXT,
    isFavorite INTEGER NOT NULL DEFAULT 0
  );

  -- 2. 复制数据（排除creationDate字段）
  INSERT INTO works_new (
    id, title, author, style, tool, remark, 
    createTime, updateTime, tags, status, 
    imageCount, firstImageId, lastImageUpdateTime, isFavorite
  )
  SELECT 
    id, title, author, style, tool, remark, 
    createTime, updateTime, tags, status, 
    COALESCE(imageCount, 0), firstImageId, lastImageUpdateTime, COALESCE(isFavorite, 0)
  FROM works;

  -- 3. 删除旧表
  DROP TABLE works;
  -- 4. 重命名新表
  ALTER TABLE works_new RENAME TO works;

  -- 5. 重新创建索引
  CREATE INDEX IF NOT EXISTS idx_works_author ON works(author);
  CREATE INDEX IF NOT EXISTS idx_works_style ON works(style);
  CREATE INDEX IF NOT EXISTS idx_works_tool ON works(tool);
  CREATE INDEX IF NOT EXISTS idx_works_status ON works(status);
  CREATE INDEX IF NOT EXISTS idx_works_createTime ON works(createTime);
  CREATE INDEX IF NOT EXISTS idx_works_updateTime ON works(updateTime);

  -- 6. 重新创建触发器
  DROP TRIGGER IF EXISTS update_work_image_count_insert;
  DROP TRIGGER IF EXISTS update_work_image_count_delete;
  DROP TRIGGER IF EXISTS update_work_first_image_on_insert;
  DROP TRIGGER IF EXISTS update_work_first_image_on_update;
  DROP TRIGGER IF EXISTS update_work_first_image_on_delete;

  CREATE TRIGGER IF NOT EXISTS update_work_image_count_insert
  AFTER INSERT ON work_images
  BEGIN
    UPDATE works
    SET imageCount = (
      SELECT COUNT(*)
      FROM work_images
      WHERE workId = NEW.workId
    )
    WHERE id = NEW.workId;
  END;

  CREATE TRIGGER IF NOT EXISTS update_work_image_count_delete
  AFTER DELETE ON work_images
  BEGIN
    UPDATE works
    SET imageCount = (
      SELECT COUNT(*)
      FROM work_images
      WHERE workId = OLD.workId
    )
    WHERE id = OLD.workId;
  END;

  CREATE TRIGGER IF NOT EXISTS update_work_first_image_on_insert
  AFTER INSERT ON work_images
  BEGIN
    UPDATE works
    SET firstImageId = (
      SELECT id
      FROM work_images
      WHERE workId = NEW.workId
      ORDER BY indexInWork ASC
      LIMIT 1
    ),
    lastImageUpdateTime = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
    WHERE id = NEW.workId;
  END;

  CREATE TRIGGER IF NOT EXISTS update_work_first_image_on_update
  AFTER UPDATE OF indexInWork ON work_images
  BEGIN
    UPDATE works
    SET firstImageId = (
      SELECT id
      FROM work_images
      WHERE workId = NEW.workId
      ORDER BY indexInWork ASC
      LIMIT 1
    ),
    lastImageUpdateTime = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
    WHERE id = NEW.workId;
  END;

  CREATE TRIGGER IF NOT EXISTS update_work_first_image_on_delete
  AFTER DELETE ON work_images
  BEGIN
    UPDATE works
    SET firstImageId = (
      SELECT id
      FROM work_images
      WHERE workId = OLD.workId
      ORDER BY indexInWork ASC
      LIMIT 1
    ),
    lastImageUpdateTime = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
    WHERE id = OLD.workId;
  END;  
  
  -- 7. 初始化书法风格配置到settings表
  INSERT OR IGNORE INTO settings (key, value, updateTime) VALUES 
  ('style_configs', '{"category": "style", "displayName": "书法风格", "updateTime": null, "items": [{"key": "regular", "displayName": "楷书", "sortOrder": 1, "isSystem": true, "isActive": true, "localizedNames": {"en": "Regular Script", "zh": "楷书"}, "createTime": null, "updateTime": null}, {"key": "running", "displayName": "行书", "sortOrder": 2, "isSystem": true, "isActive": true, "localizedNames": {"en": "Running Script", "zh": "行书"}, "createTime": null, "updateTime": null}, {"key": "cursive", "displayName": "草书", "sortOrder": 3, "isSystem": true, "isActive": true, "localizedNames": {"en": "Cursive Script", "zh": "草书"}, "createTime": null, "updateTime": null}, {"key": "clerical", "displayName": "隶书", "sortOrder": 4, "isSystem": true, "isActive": true, "localizedNames": {"en": "Clerical Script", "zh": "隶书"}, "createTime": null, "updateTime": null}, {"key": "seal", "displayName": "篆书", "sortOrder": 5, "isSystem": true, "isActive": true, "localizedNames": {"en": "Seal Script", "zh": "篆书"}, "createTime": null, "updateTime": null}, {"key": "other", "displayName": "其他", "sortOrder": 6, "isSystem": true, "isActive": true, "localizedNames": {"en": "Other", "zh": "其他"}, "createTime": null, "updateTime": null}]}', datetime('now'));

  -- 8. 初始化书写工具配置到settings表
  INSERT OR IGNORE INTO settings (key, value, updateTime) VALUES 
  ('tool_configs', '{"category": "tool", "displayName": "书写工具", "updateTime": null, "items": [{"key": "brush", "displayName": "毛笔", "sortOrder": 1, "isSystem": true, "isActive": true, "localizedNames": {"en": "Brush", "zh": "毛笔"}, "createTime": null, "updateTime": null}, {"key": "hardPen", "displayName": "硬笔", "sortOrder": 2, "isSystem": true, "isActive": true, "localizedNames": {"en": "Hard Pen", "zh": "硬笔"}, "createTime": null, "updateTime": null}, {"key": "other", "displayName": "其他", "sortOrder": 3, "isSystem": true, "isActive": true, "localizedNames": {"en": "Other", "zh": "其他"}, "createTime": null, "updateTime": null}]}', datetime('now'));

  -- 9. 更新CharacterView视图（移除creationTime映射）
  DROP VIEW IF EXISTS CharacterView;
  CREATE VIEW IF NOT EXISTS CharacterView AS
  SELECT 
    c.id,
    c.character,
    c.isFavorite,
    c.createTime AS collectionTime,
    c.updateTime,
    c.pageId,
    c.workId,
    c.tags,
    c.region,
    c.note,
    w.style,
    w.tool,
    w.title,
    w.author
  FROM 
    characters c
  LEFT JOIN
    works w ON c.workId = w.id;
  

  ''',
];
