import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // Initialize FFI
  sqfliteFfiInit();

  try {
    // Find the database file
    final dbPath = await findDatabasePath();
    if (dbPath == null) {
      print('❌ Database file not found');
      return;
    }

    print('✅ Found database at: $dbPath');

    // Open database
    final db = await databaseFactoryFfi.openDatabase(dbPath);

    // Check if tables exist and have data
    await checkTablesAndData(db);

    // Check CharacterView specifically
    await checkCharacterView(db);

    await db.close();
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<String?> findDatabasePath() async {
  // Common Windows paths for Flutter app data
  final candidates = [
    path.join(Platform.environment['USERPROFILE'] ?? '', 'AppData', 'Roaming',
        'com.example', 'demo', 'databases', 'app_database.db'),
    path.join(Platform.environment['USERPROFILE'] ?? '', 'AppData', 'Local',
        'com.example', 'demo', 'databases', 'app_database.db'),
    path.join(Directory.current.path, 'databases', 'app_database.db'),
    path.join(
        Directory.current.path,
        'build',
        'windows',
        'x64',
        'runner',
        'Debug',
        'data',
        'flutter_assets',
        'assets',
        'databases',
        'app_database.db'),
  ];

  for (final candidate in candidates) {
    if (await File(candidate).exists()) {
      return candidate;
    }
  }

  // Search recursively in common directories
  final searchDirs = [
    Directory.current.path,
    path.join(Platform.environment['USERPROFILE'] ?? '', 'AppData'),
  ];

  for (final searchDir in searchDirs) {
    final found = await searchForDatabase(Directory(searchDir));
    if (found != null) return found;
  }

  return null;
}

Future<String?> searchForDatabase(Directory dir) async {
  try {
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('app_database.db')) {
        return entity.path;
      }
    }
  } catch (e) {
    // Ignore permission errors
  }
  return null;
}

Future<void> checkTablesAndData(Database db) async {
  print('\n=== Checking Tables ===');

  // Check if tables exist
  final tables =
      await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
  print('📋 Found ${tables.length} tables:');
  for (final table in tables) {
    final tableName = table['name'] as String;
    if (!tableName.startsWith('sqlite_')) {
      final count =
          await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      final rowCount = count.first['count'] as int;
      print('  - $tableName: $rowCount rows');
    }
  }

  // Check views
  final views =
      await db.rawQuery("SELECT name FROM sqlite_master WHERE type='view'");
  print('\n📋 Found ${views.length} views:');
  for (final view in views) {
    final viewName = view['name'] as String;
    try {
      final count =
          await db.rawQuery('SELECT COUNT(*) as count FROM $viewName');
      final rowCount = count.first['count'] as int;
      print('  - $viewName: $rowCount rows');
    } catch (e) {
      print('  - $viewName: ❌ Error: $e');
    }
  }
}

Future<void> checkCharacterView(Database db) async {
  print('\n=== CharacterView Analysis ===');

  try {
    // Get schema
    final schema = await db
        .rawQuery("SELECT sql FROM sqlite_master WHERE name='CharacterView'");
    if (schema.isNotEmpty) {
      print('📋 CharacterView schema:');
      print(schema.first['sql']);
    }

    // Get sample data
    final sample = await db.rawQuery('SELECT * FROM CharacterView LIMIT 3');
    print('\n📋 Sample CharacterView data (${sample.length} rows):');
    for (int i = 0; i < sample.length; i++) {
      print('Row ${i + 1}:');
      final row = sample[i];
      for (final entry in row.entries) {
        print('  ${entry.key}: ${entry.value}');
      }
      print('');
    }

    // Check base tables
    print('\n=== Base Tables Analysis ===');

    final charactersCount =
        await db.rawQuery('SELECT COUNT(*) as count FROM characters');
    print('Characters table: ${charactersCount.first['count']} rows');

    final worksCount = await db.rawQuery('SELECT COUNT(*) as count FROM works');
    print('Works table: ${worksCount.first['count']} rows');

    // Sample from base tables
    final sampleCharacters = await db.rawQuery(
        'SELECT id, character, workId, createTime, updateTime FROM characters LIMIT 2');
    print('\nSample characters:');
    for (final char in sampleCharacters) {
      print(
          '  ID: ${char['id']}, Character: ${char['character']}, WorkID: ${char['workId']}');
    }

    final sampleWorks = await db
        .rawQuery('SELECT id, title, author, style, tool FROM works LIMIT 2');
    print('\nSample works:');
    for (final work in sampleWorks) {
      print(
          '  ID: ${work['id']}, Title: ${work['title']}, Author: ${work['author']}');
    }
  } catch (e) {
    print('❌ Error checking CharacterView: $e');
  }
}
