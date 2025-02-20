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
        metadata TEXT
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
    
    if (!work.containsKey('create_time')) {
      work['create_time'] = DateTime.now().millisecondsSinceEpoch;
    }
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
    List<String>? tags,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
    String? sortBy,
    bool descending = true,
  }) async {
    final db = await database;
    
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];
    
    if (style != null) {
      whereConditions.add('style = ?');
      whereArgs.add(style);
    }
    
    if (author != null) {
      whereConditions.add('author = ?');
      whereArgs.add(author);
    }

    if (fromDate != null) {
      whereConditions.add('creation_date >= ?');
      whereArgs.add(fromDate.millisecondsSinceEpoch);
    }

    if (toDate != null) {
      whereConditions.add('creation_date <= ?');
      whereArgs.add(toDate.millisecondsSinceEpoch);
    }

    if (tags != null && tags.isNotEmpty) {
      whereConditions.add('metadata LIKE ?');
      whereArgs.add('%"tags":${jsonEncode(tags)}%');
    }
    
    final where = whereConditions.isEmpty 
        ? null 
        : whereConditions.join(' AND ');

    String orderByClause;
    switch (sortBy) {
      case 'name':
        orderByClause = 'name';
        break;
      case 'author':
        orderByClause = 'author';
        break;
      case 'creationDate':
        orderByClause = 'creation_date';
        break;
      case 'updateTime':
        orderByClause = 'update_time';
        break;
      default:
        orderByClause = 'creation_date';
    }
    orderByClause += descending ? ' DESC' : ' ASC';

    final List<Map<String, dynamic>> maps = await db.query(
      'works',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderByClause,
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) {
      if (map['metadata'] != null) {
        map['metadata'] = jsonDecode(map['metadata']);
      }
      return map;
    }).toList();
  }

  Future<int> getWorksCount({
    String? style,
    String? author,
    List<String>? tags,
  }) async {
    final db = await database;
    
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];
    
    if (style != null) {
      whereConditions.add('style = ?');
      whereArgs.add(style);
    }
    
    if (author != null) {
      whereConditions.add('author = ?');
      whereArgs.add(author);
    }

    if (tags != null && tags.isNotEmpty) {
      whereConditions.add('metadata LIKE ?');
      whereArgs.add('%"tags":${jsonEncode(tags)}%');
    }
    
    final where = whereConditions.isEmpty 
        ? null 
        : whereConditions.join(' AND ');

    final result = Sqflite.firstIntValue(await db.query(
      'works',
      columns: ['COUNT(*)'],
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    ));
    
    return result ?? 0;
  }

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
    
    if (!character.containsKey('create_time')) {
      character['create_time'] = DateTime.now().millisecondsSinceEpoch;
    }
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
    
    if (!practice.containsKey('create_time')) {
      practice['create_time'] = DateTime.now().millisecondsSinceEpoch;
    }
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

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseTransaction) action) async {
    final db = await database;
    return await db.transaction((txn) {
      return action(_SqliteTransaction(txn));
    });
  }
}

class _SqliteTransaction implements DatabaseTransaction {
  final Transaction _txn;
  
  _SqliteTransaction(this._txn);

  @override
  Future<void> insertWork(Map<String, dynamic> work) async {
    await _txn.insert('works', work);
  }

  @override
  Future<void> insertCharacter(Map<String, dynamic> character) async {
    await _txn.insert('characters', character);
  }

  @override
  Future<void> updateWork(String id, Map<String, dynamic> work) async {
    await _txn.update(
      'works',
      work,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteWork(String id) async {
    await _txn.delete(
      'works',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  @override
  Future<void> insertPractice(Map<String, dynamic> practice) async {
    await _txn.insert('practices', practice);
  }
}
