import '../../domain/repositories/settings_repository.dart';
import '../../infrastructure/persistence/database_interface.dart';
import '../../utils/date_time_helper.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final DatabaseInterface _db;
  final String _table = 'settings';

  SettingsRepositoryImpl(this._db);

  @override
  Future<void> deleteValue(String key) async {
    await _db.rawDelete(
      'DELETE FROM $_table WHERE key = ?',
      [key],
    );
  }

  @override
  Future<String?> getValue(String key) async {
    final results = await _db.rawQuery(
      'SELECT value FROM $_table WHERE key = ? LIMIT 1',
      [key],
    );
    return results.isEmpty ? null : results.first['value'] as String?;
  }

  @override
  Future<Map<String, String>> getValues(List<String> keys) async {
    final results = <String, String>{};
    final placeholders = List.filled(keys.length, '?').join(',');

    final rows = await _db.rawQuery(
      'SELECT key, value FROM $_table WHERE key IN ($placeholders)',
      keys,
    );

    for (final row in rows) {
      results[row['key'] as String] = row['value'] as String;
    }

    return results;
  }

  @override
  Future<void> setValue(String key, String value) async {
    final updateTime = DateTimeHelper.toStorageFormat(DateTime.now());
    await _db.rawUpdate(
      'INSERT OR REPLACE INTO $_table (key, value, updateTime) VALUES (?, ?, ?)',
      [key, value, updateTime],
    );
  }

  @override
  Future<void> setValues(Map<String, String> values) async {
    final now = DateTimeHelper.toStorageFormat(DateTime.now());
    final batch = values.entries.map((entry) => _db.rawUpdate(
          'INSERT OR REPLACE INTO $_table (key, value, updateTime) VALUES (?, ?, ?)',
          [entry.key, entry.value, now],
        ));
    await Future.wait(batch);
  }
}
