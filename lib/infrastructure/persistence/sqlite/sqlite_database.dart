import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database_interface.dart';

class SqliteDatabase implements DatabaseInterface {
  static const String dbName = 'shufa_jizi.db';
  Database? _database;

  // Add static initialization
  static Future<void> initializePlatform() async {
    // Initialize FFI
    sqfliteFfiInit();
    // Set global factory
    databaseFactory = databaseFactoryFfi;
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initializeDatabase();
    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, dbName);

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE works (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        author TEXT,
        style TEXT,
        tool TEXT,
        creation_date INTEGER,
        create_time INTEGER NOT NULL,
        update_time INTEGER NOT NULL,
        metadata TEXT,
        image_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE characters (
        id TEXT PRIMARY KEY,
        work_id TEXT NOT NULL,
        char TEXT NOT NULL,
        pinyin TEXT,
        source_region TEXT NOT NULL,
        image TEXT NOT NULL,
        metadata TEXT,
        create_time INTEGER NOT NULL,
        update_time INTEGER NOT NULL,
        FOREIGN KEY (work_id) REFERENCES works (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE practices (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        pages TEXT NOT NULL,
        metadata TEXT,
        create_time INTEGER NOT NULL,
        update_time INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        update_time INTEGER NOT NULL
      )
    ''');

    // Create indices
    await db.execute('CREATE INDEX idx_characters_work_id ON characters(work_id)');
    await db.execute('CREATE INDEX idx_characters_char ON characters(char)');
  }

  @override
  Future<void> initialize() async {
    if (_database != null) return;
    _database = await _initializeDatabase();
  }

  @override
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Update CRUD methods
  @override
  Future<String> insertWork(Map<String, dynamic> work) async {
    final db = await database;
    final workId = const Uuid().v4();
    work['id'] = workId;
    
    work['create_time'] = DateTime.now().millisecondsSinceEpoch;
    
    work['update_time'] = DateTime.now().millisecondsSinceEpoch;
    
    if (work.containsKey('metadata')) {
      work['metadata'] = jsonEncode(work['metadata']);
    }
    
    await db.insert('works', work);
    return workId;
  }

  @override
  Future<Map<String, dynamic>?> getWork(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'works',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    
    final work = maps.first;
    if (work['metadata'] != null) {
      work['metadata'] = jsonDecode(work['metadata']);
    }
    return work;
  }

  @override
  Future<void> updateWork(String id, Map<String, dynamic> work) async {
    final db = await database;
    work['update_time'] = DateTime.now().millisecondsSinceEpoch;
    
    if (work.containsKey('metadata')) {
      work['metadata'] = jsonEncode(work['metadata']);
    }
    
    await db.update(
      'works',
      work,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteWork(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete associated characters first (cascade should handle this, but being explicit)
      await txn.delete(
        'characters',
        where: 'work_id = ?',
        whereArgs: [id],
      );
      
      // Then delete the work
      await txn.delete(
        'works',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getWorks({
    String? style,
    String? author,
    String? name,
    String? tool,        // 添加工具参数
    List<String>? tags,
    DateTime? fromDateImport,
    DateTime? toDateImport,
    DateTime? fromDateCreation,
    DateTime? toDateCreation,
    DateTime? fromDateUpdate,
    DateTime? toDateUpdate,
    int? limit,
    int? offset,
    String? sortBy,
    bool descending = true,
  }) async {
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    // 文本搜索
    _addTextSearch(whereConditions, whereArgs, name, author);
    
    // 风格筛选
    if (style != null) {
      whereConditions.add('style = ?');
      whereArgs.add(style);
    }
    
    // 工具筛选
    if (tool != null) {
      whereConditions.add('tool = ?');
      whereArgs.add(tool);
    }
    
    // 标签筛选
    _addTagSearch(whereConditions, whereArgs, tags);

    // 日期范围筛选
    _addDateRange(whereConditions, whereArgs, {
      'create_time': {
        'start': fromDateImport,
        'end': toDateImport,
      },
      'creation_date': {
        'start': fromDateCreation,
        'end': toDateCreation,
      },
      'update_time': {
        'start': fromDateUpdate,
        'end': toDateUpdate,
      },
    });

    final where = whereConditions.isEmpty ? null : whereConditions.join(' AND ');
    final orderBy = _buildOrderByClause(sortBy, descending);

    final maps = await _executeQuery(
      table: 'works',
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return maps.map(_decodeMetadata).toList();
  }

  @override
  Future<int> getWorksCount({
    String? style,
    String? author,
    String? name,
    String? tool,        // Add tool parameter
    List<String>? tags,
    DateTime? fromDateImport,
    DateTime? toDateImport,
    DateTime? fromDateCreation,
    DateTime? toDateCreation,
    DateTime? fromDateUpdate,
    DateTime? toDateUpdate
  }) async {
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    // 文本搜索
    _addTextSearch(whereConditions, whereArgs, name, author);
    
    // 风格筛选
    if (style != null) {
      whereConditions.add('style = ?');
      whereArgs.add(style);
    }
    
    // 工具筛选
    if (tool != null) {
      whereConditions.add('tool = ?');
      whereArgs.add(tool);
    }
    
    // 标签筛选
    _addTagSearch(whereConditions, whereArgs, tags);

    // 日期范围筛选
    _addDateRange(whereConditions, whereArgs, {
      'create_time': {
        'start': fromDateImport,
        'end': toDateImport,
      },
      'creation_date': {
        'start': fromDateCreation,
        'end': toDateCreation,
      },
      'update_time': {
        'start': fromDateUpdate,
        'end': toDateUpdate,
      },
    });

    final where = whereConditions.isEmpty ? null : whereConditions.join(' AND ');

    // 使用 _executeQuery 来执行计数查询
    final result = await _executeQuery(
      table: 'works',
      columns: ['COUNT(*) as count'],
      where: where,
      whereArgs: whereArgs,
    );

    return result.first['count'] as int;
  }

  @override
  Future<bool> workExists(String id) async {
    final db = await database;
    final result = Sqflite.firstIntValue(await db.query(
      'works',
      columns: ['COUNT(*)'],
      where: 'id = ?',
      whereArgs: [id],
    ));
    return (result ?? 0) > 0;
  }

  // Character CRUD methods
  @override
  Future<String> insertCharacter(Map<String, dynamic> character) async {
    final db = await database;
    final charId = const Uuid().v4();
    character['id'] = charId;
    character['create_time'] = DateTime.now().millisecondsSinceEpoch;
    character['update_time'] = DateTime.now().millisecondsSinceEpoch;
    
    if (character.containsKey('metadata')) {
      character['metadata'] = jsonEncode(character['metadata']);
    }
    if (character.containsKey('source_region')) {
      character['source_region'] = jsonEncode(character['source_region']);
    }
    
    await db.insert('characters', character);
    return charId;
  }

  @override
  Future<Map<String, dynamic>?> getCharacter(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'characters',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    
    final character = maps.first;
    if (character['metadata'] != null) {
      character['metadata'] = jsonDecode(character['metadata']);
    }
    if (character['source_region'] != null) {
      character['source_region'] = jsonDecode(character['source_region']);
    }
    return character;
  }

  @override
  Future<List<Map<String, dynamic>>> getCharactersByWorkId(String workId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'characters',
      where: 'work_id = ?',
      whereArgs: [workId],
      orderBy: 'create_time ASC',
    );
    
    return maps.map((character) {
      if (character['metadata'] != null) {
        character['metadata'] = jsonDecode(character['metadata']);
      }
      if (character['source_region'] != null) {
        character['source_region'] = jsonDecode(character['source_region']);
      }
      return character;
    }).toList();
  }

  @override
  Future<void> updateCharacter(String id, Map<String, dynamic> character) async {
    final db = await database;
    character['update_time'] = DateTime.now().millisecondsSinceEpoch;
    
    if (character.containsKey('metadata')) {
      character['metadata'] = jsonEncode(character['metadata']);
    }
    if (character.containsKey('source_region')) {
      character['source_region'] = jsonEncode(character['source_region']);
    }
    
    await db.update(
      'characters',
      character,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteCharacter(String id) async {
    final db = await database;
    await db.delete(
      'characters',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Practice CRUD methods
  @override
  Future<String> insertPractice(Map<String, dynamic> practice) async {
    final db = await database;
    final practiceId = const Uuid().v4();
    practice['id'] = practiceId;    
    practice['create_time'] = DateTime.now().millisecondsSinceEpoch;    
    practice['update_time'] = DateTime.now().millisecondsSinceEpoch;
    
    if (practice.containsKey('metadata')) {
      practice['metadata'] = jsonEncode(practice['metadata']);
    }

    if (practice.containsKey('pages')) {
      practice['pages'] = jsonEncode(practice['pages']);
    }
    
    await db.insert('practices', practice);
    return practiceId;
  }

  @override
  Future<Map<String, dynamic>?> getPractice(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'practices',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    
    final practice = maps.first;
    if (practice['metadata'] != null) {
      practice['metadata'] = jsonDecode(practice['metadata']);
    }
    if (practice['pages'] != null) {
      practice['pages'] = jsonDecode(practice['pages']);
    }
    return practice;
  }

  @override
  Future<List<Map<String, dynamic>>> getPractices({
    List<String>? characterIds, // Not used in this implementation
    String? title,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];
    
    if (title != null) {
      whereConditions.add('title LIKE ?');
      whereArgs.add('%$title%');
    }
    
    final where = whereConditions.isEmpty ? null : whereConditions.join(' AND ');

    final List<Map<String, dynamic>> maps = await db.query(
      'practices',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'create_time DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((practice) {
      if (practice['metadata'] != null) {
        practice['metadata'] = jsonDecode(practice['metadata']);
      }
      if (practice['pages'] != null) {
        practice['pages'] = jsonDecode(practice['pages']);
      }
      return practice;
    }).toList();
  }

  @override
  Future<void> updatePractice(String id, Map<String, dynamic> practice) async {
    final db = await database;
    practice['update_time'] = DateTime.now().millisecondsSinceEpoch;
    
    if (practice.containsKey('metadata')) {
      practice['metadata'] = jsonEncode(practice['metadata']);
    }
    if (practice.containsKey('pages')) {
      practice['pages'] = jsonEncode(practice['pages']);
    }
    
    await db.update(
      'practices',
      practice,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deletePractice(String id) async {
    final db = await database;
    await db.delete(
      'practices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> practiceExists(String id) async {
    final db = await database;
    final result = Sqflite.firstIntValue(await db.query(
      'practices',
      columns: ['COUNT(*)'],
      where: 'id = ?',
      whereArgs: [id],
    ));
    return (result ?? 0) > 0;
  }

  Future<int> getPracticesCount({String? title}) async {
    final db = await database;
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];
    
    if (title != null) {
      whereConditions.add('title LIKE ?');
      whereArgs.add('%$title%');
    }
    
    final where = whereConditions.isEmpty ? null : whereConditions.join(' AND ');
    
    final result = Sqflite.firstIntValue(await db.query(
      'practices',
      columns: ['COUNT(*)'],
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    ));
    
    return result ?? 0;
  }

  // Settings methods
  @override
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
        'update_time': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<String?> getSetting(String key) async {
    final db = await database;    
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  void _addTextSearch(
    List<String> conditions,
    List<dynamic> args,
    String? name,
    String? author,
  ) {
    if (name != null || author != null) {
      final searchConditions = <String>[];
      if (name != null) {
        searchConditions.add('name LIKE ?');
        args.add('%$name%');
      }
      if (author != null) {
        searchConditions.add('author LIKE ?');
        args.add('%$author%');
      }
      if (searchConditions.isNotEmpty) {
        conditions.add('(${searchConditions.join(' OR ')})');
      }
    }
  }

  void _addTagSearch(
    List<String> conditions,
    List<dynamic> args,
    List<String>? tags,
  ) {
    if (tags != null && tags.isNotEmpty) {
      final tagQueries = tags.map((tag) => 
        '(metadata LIKE ?)'
      ).join(' OR ');
      conditions.add('($tagQueries)');
      for (final tag in tags) {
        args.addAll([tag, '%"$tag"%']);
      }
    }
  }

  String? _buildOrderByClause(String? sortBy, bool descending) {
    if (sortBy == null) return null;
    
    final field = switch(sortBy) {
      'name' => 'name',
      'author' => 'author',
      'creationDate' => 'creation_date',
      'updateTime' => 'update_time',
      'importTime' => 'create_time',
      _ => sortBy
    };
    return '$field ${descending ? 'DESC' : 'ASC'}';
  }

  Future<List<Map<String, dynamic>>> _executeQuery({
    required String table,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs?.isEmpty == true ? null : whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  // 1. 提取日期范围处理方法
  void _addDateRange(
    List<String> conditions,
    List<dynamic> args,
    Map<String, Map<String, DateTime?>> dateRanges,
  ) {
    dateRanges.forEach((field, range) {
      final start = range['start'];
      final end = range['end'];
      
      if (start != null) {
        conditions.add('$field >= ?');
        args.add(start.millisecondsSinceEpoch);
      }
      if (end != null) {
        conditions.add('$field <= ?');
        args.add(end.millisecondsSinceEpoch);
      }
    });
  }

  // 2. 提取元数据解码方法
  Map<String, dynamic> _decodeMetadata(Map<String, dynamic> map) {
    final result = Map<String, dynamic>.from(map);
    for (final field in ['metadata', 'source_region', 'pages']) {
      if (result[field] != null) {
        try {
          result[field] = jsonDecode(result[field] as String);
        } catch (e) {
          print('Failed to decode $field: ${e.toString()}');
        }
      }
    }
    return result;
  }
}
