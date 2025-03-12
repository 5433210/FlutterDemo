import '../../domain/repositories/settings_repository.dart';
import '../../infrastructure/persistence/database_interface.dart';
import '../../utils/date_time_helper.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final DatabaseInterface _db;
  final String _table = 'settings';

  SettingsRepositoryImpl(this._db);

  @override
  Future<void> deleteValue(String key) async {
    await _db.delete(_table, key);
  }

  @override
  Future<String?> getValue(String key) async {
    final row = await _db.get(_table, key);
    return row?['value'] as String?;
  }

  @override
  Future<Map<String, String>> getValues(List<String> keys) async {
    final results = <String, String>{};

    for (final key in keys) {
      final value = await getValue(key);
      if (value != null) {
        results[key] = value;
      }
    }

    return results;
  }

  @override
  Future<void> setValue(String key, String value) async {
    await _db.set(_table, key, {
      'key': key,
      'value': value,
      'updateTime': DateTimeHelper.toStorageFormat(DateTime.now()),
    });
  }

  @override
  Future<void> setValues(Map<String, String> values) async {
    final now = DateTimeHelper.toStorageFormat(DateTime.now());
    final batch = values.map(
      (key, value) => MapEntry(
        key,
        {
          'key': key,
          'value': value,
          'updateTime': now,
        },
      ),
    );

    await _db.setMany(_table, batch);
  }
}
