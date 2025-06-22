import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  const dbPath = 'charasgem.db';
  if (await File(dbPath).exists()) {
    final db = await databaseFactoryFfi.openDatabase(dbPath);
    final result =
        await db.rawQuery('SELECT * FROM settings WHERE key LIKE "config_%"');
    print('Config data in database:');
    for (final row in result) {
      print('Key: ${row['key']}');
      print('Value: ${row['value']}');
      print('---');
    }
    await db.close();
  } else {
    print('Database file does not exist');
  }
}
