import '../../../infrastructure/persistence/database_interface.dart';

class SettingsService {
  static const String _themeKey = 'app_theme';
  static const String _fontSizeKey = 'font_size';
  static const String _gridTypeKey = 'grid_type';
  static const String _lastBackupKey = 'last_backup_time';
  final DatabaseInterface _database;

  SettingsService(this._database);

  // Get all settings
  Future<Map<String, dynamic>> getAllSettings() async {
    final keys = [
      _themeKey,
      _fontSizeKey,
      _gridTypeKey,
      _lastBackupKey,
    ];

    final Map<String, dynamic> settings = {};
    for (final key in keys) {
      final value = await _database.getSetting(key);
      if (value != null) {
        settings[key] = value;
      }
    }

    return settings;
  }

  // Font size settings
  Future<double> getFontSize() async {
    final size = await _database.getSetting(_fontSizeKey);
    return size != null ? double.parse(size) : 16.0;
  }

  // Practice grid settings
  Future<String> getGridType() async {
    return await _database.getSetting(_gridTypeKey) ?? '米字格';
  }

  // Backup settings
  Future<DateTime?> getLastBackupTime() async {
    final timestamp = await _database.getSetting(_lastBackupKey);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  // Theme settings
  Future<String> getTheme() async {
    return await _database.getSetting(_themeKey) ?? 'system';
  }

  Future<void> setFontSize(double size) async {
    await _database.setSetting(_fontSizeKey, size.toString());
  }

  Future<void> setGridType(String type) async {
    await _database.setSetting(_gridTypeKey, type);
  }

  Future<void> setTheme(String theme) async {
    await _database.setSetting(_themeKey, theme);
  }

  Future<void> updateLastBackupTime() async {
    await _database.setSetting(
      _lastBackupKey,
      DateTime.now().toIso8601String(),
    );
  }

  // Batch settings update
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    for (final entry in settings.entries) {
      await _database.setSetting(
        entry.key,
        entry.value.toString(),
      );
    }
  }
}
