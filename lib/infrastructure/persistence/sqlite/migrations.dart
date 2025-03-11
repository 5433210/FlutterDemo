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
    creationDate INTEGER,
    createTime INTEGER NOT NULL,
    updateTime INTEGER NOT NULL,
    tags TEXT,
    status TEXT NOT NULL DEFAULT 'draft',
    imageCount INTEGER DEFAULT 0
  );

  -- 角色表
  CREATE TABLE IF NOT EXISTS characters (
    id TEXT PRIMARY KEY,
    workId TEXT NOT NULL,
    char TEXT NOT NULL,
    region TEXT NOT NULL,
    tags TEXT,
    createTime INTEGER NOT NULL,
    updateTime INTEGER NOT NULL,
    FOREIGN KEY (workId) REFERENCES works (id) ON DELETE CASCADE
  );

  -- 字帖表
  CREATE TABLE IF NOT EXISTS practices (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    pages TEXT NOT NULL,
    tags TEXT,
    createTime INTEGER NOT NULL,
    updateTime INTEGER NOT NULL
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
    updateTime INTEGER NOT NULL
  );

  -- 创建索引
  CREATE INDEX IF NOT EXISTS idx_characters_workId ON characters(workId);
  CREATE INDEX IF NOT EXISTS idx_characters_char ON characters(char);
  ''',

  // 版本 2: 添加作品图片管理 - 表和索引
  '''CREATE TABLE IF NOT EXISTS work_images (
    id TEXT PRIMARY KEY,
    workId TEXT NOT NULL,
    indexInWork INTEGER NOT NULL,
    path TEXT NOT NULL,
    width INTEGER NOT NULL,
    height INTEGER NOT NULL,
    format TEXT NOT NULL,
    size INTEGER NOT NULL,
    thumbnailPath TEXT,
    createTime INTEGER NOT NULL,
    updateTime INTEGER NOT NULL,
    FOREIGN KEY (workId) REFERENCES works (id) ON DELETE CASCADE
  )''',

  '''CREATE INDEX IF NOT EXISTS idx_work_images_workId ON work_images(workId)''',

  '''CREATE INDEX IF NOT EXISTS idx_work_images_index ON work_images(workId, indexInWork)''',

  // 版本 2: 添加作品图片管理 - ALTER TABLE
  '''ALTER TABLE works 
  ADD COLUMN firstImageId TEXT REFERENCES work_images(id)''',

  '''ALTER TABLE works 
  ADD COLUMN lastImageUpdateTime INTEGER''',

  // 版本 2: 添加作品图片管理 - 触发器
  '''CREATE TRIGGER IF NOT EXISTS update_work_image_count_insert 
  AFTER INSERT ON work_images
  BEGIN
    UPDATE works 
    SET imageCount = (
      SELECT COUNT(*) 
      FROM work_images 
      WHERE workId = NEW.workId
    )
    WHERE id = NEW.workId;
  END''',

  '''CREATE TRIGGER IF NOT EXISTS update_work_image_count_delete 
  AFTER DELETE ON work_images
  BEGIN
    UPDATE works 
    SET imageCount = (
      SELECT COUNT(*) 
      FROM work_images 
      WHERE workId = OLD.workId
    )
    WHERE id = OLD.workId;
  END''',

  '''CREATE TRIGGER IF NOT EXISTS update_work_first_image_on_insert 
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
    lastImageUpdateTime = strftime('%s', 'now') * 1000
    WHERE id = NEW.workId;
  END''',

  '''CREATE TRIGGER IF NOT EXISTS update_work_first_image_on_update 
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
    lastImageUpdateTime = strftime('%s', 'now') * 1000
    WHERE id = NEW.workId;
  END''',

  '''CREATE TRIGGER IF NOT EXISTS update_work_first_image_on_delete 
  AFTER DELETE ON work_images
  BEGIN
    UPDATE works 
    SET firstImageId = (
      SELECT id FROM work_images WHERE workId = OLD.workId ORDER BY indexInWork ASC LIMIT 1
    ),
    lastImageUpdateTime = strftime('%s', 'now') * 1000
    WHERE id = OLD.workId;
  END''',

  // 版本 3: 时间字段UTC迁移
  '''
  -- Works表时间字段迁移
  ALTER TABLE works ADD COLUMN creationDate_new TEXT;
  ALTER TABLE works ADD COLUMN createTime_new TEXT;
  ALTER TABLE works ADD COLUMN updateTime_new TEXT;
  ALTER TABLE works ADD COLUMN lastImageUpdateTime_new TEXT;

  UPDATE works SET 
    creationDate_new = datetime(creationDate/1000, 'unixepoch'),
    createTime_new = datetime(createTime/1000, 'unixepoch'),
    updateTime_new = datetime(updateTime/1000, 'unixepoch'),
    lastImageUpdateTime_new = 
      CASE 
        WHEN lastImageUpdateTime IS NOT NULL 
        THEN datetime(lastImageUpdateTime/1000, 'unixepoch')
        ELSE NULL 
      END;

  -- Work Images表时间字段迁移
  ALTER TABLE work_images ADD COLUMN createTime_new TEXT;
  ALTER TABLE work_images ADD COLUMN updateTime_new TEXT;

  UPDATE work_images SET 
    createTime_new = datetime(createTime/1000, 'unixepoch'),
    updateTime_new = datetime(updateTime/1000, 'unixepoch');

  -- Characters表时间字段迁移
  ALTER TABLE characters ADD COLUMN createTime_new TEXT;
  ALTER TABLE characters ADD COLUMN updateTime_new TEXT;

  UPDATE characters SET 
    createTime_new = datetime(createTime/1000, 'unixepoch'),
    updateTime_new = datetime(updateTime/1000, 'unixepoch');

  -- Practices表时间字段迁移
  ALTER TABLE practices ADD COLUMN createTime_new TEXT;
  ALTER TABLE practices ADD COLUMN updateTime_new TEXT;

  UPDATE practices SET 
    createTime_new = datetime(createTime/1000, 'unixepoch'),
    updateTime_new = datetime(updateTime/1000, 'unixepoch');

  -- Settings表时间字段迁移
  ALTER TABLE settings ADD COLUMN updateTime_new TEXT;

  UPDATE settings SET 
    updateTime_new = datetime(updateTime/1000, 'unixepoch');
  ''',

  '''
  -- 删除原有列并重命名新列
  -- Works表
  ALTER TABLE works DROP COLUMN creationDate;
  ALTER TABLE works DROP COLUMN createTime;
  ALTER TABLE works DROP COLUMN updateTime;
  ALTER TABLE works DROP COLUMN lastImageUpdateTime;

  ALTER TABLE works RENAME COLUMN creationDate_new TO creationDate;
  ALTER TABLE works RENAME COLUMN createTime_new TO createTime;
  ALTER TABLE works RENAME COLUMN updateTime_new TO updateTime;
  ALTER TABLE works RENAME COLUMN lastImageUpdateTime_new TO lastImageUpdateTime;

  -- Work Images表
  ALTER TABLE work_images DROP COLUMN createTime;
  ALTER TABLE work_images DROP COLUMN updateTime;

  ALTER TABLE work_images RENAME COLUMN createTime_new TO createTime;
  ALTER TABLE work_images RENAME COLUMN updateTime_new TO updateTime;

  -- Characters表
  ALTER TABLE characters DROP COLUMN createTime;
  ALTER TABLE characters DROP COLUMN updateTime;

  ALTER TABLE characters RENAME COLUMN createTime_new TO createTime;
  ALTER TABLE characters RENAME COLUMN updateTime_new TO updateTime;

  -- Practices表
  ALTER TABLE practices DROP COLUMN createTime;
  ALTER TABLE practices DROP COLUMN updateTime;

  ALTER TABLE practices RENAME COLUMN createTime_new TO createTime;
  ALTER TABLE practices RENAME COLUMN updateTime_new TO updateTime;

  -- Settings表
  ALTER TABLE settings DROP COLUMN updateTime;
  ALTER TABLE settings RENAME COLUMN updateTime_new TO updateTime;
  ''',

  '''
  -- 创建新的索引
  CREATE INDEX IF NOT EXISTS idx_works_creationDate ON works(creationDate);
  CREATE INDEX IF NOT EXISTS idx_works_createTime ON works(createTime);
  CREATE INDEX IF NOT EXISTS idx_works_updateTime ON works(updateTime);

  CREATE INDEX IF NOT EXISTS idx_work_images_createTime ON work_images(createTime);
  CREATE INDEX IF NOT EXISTS idx_work_images_updateTime ON work_images(updateTime);

  CREATE INDEX IF NOT EXISTS idx_characters_createTime ON characters(createTime);
  CREATE INDEX IF NOT EXISTS idx_characters_updateTime ON characters(updateTime);

  CREATE INDEX IF NOT EXISTS idx_practices_createTime ON practices(createTime);
  CREATE INDEX IF NOT EXISTS idx_practices_updateTime ON practices(updateTime);

  CREATE INDEX IF NOT EXISTS idx_settings_updateTime ON settings(updateTime);
  ''',

  '''
  -- 更新触发器以使用UTC时间格式
  DROP TRIGGER IF EXISTS update_work_first_image_on_insert;
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

  DROP TRIGGER IF EXISTS update_work_first_image_on_update;
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

  DROP TRIGGER IF EXISTS update_work_first_image_on_delete;
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
  '''
];
