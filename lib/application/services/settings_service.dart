import '../../infrastructure/persistence/database_interface.dart';

class SettingsService {
  final DatabaseInterface _database;
  static const String _themeKey = 'app_theme';
  static const String _fontSizeKey = 'font_size';
  static const String _gridTypeKey = 'grid_type';
  static const String _lastBackupKey = 'last_backup_time';

  SettingsService(this._database);

  // Theme settings
  Future<String> getTheme() async {
    return await _database.getSetting(_themeKey) ?? 'system';
  }

  Future<void> setTheme(String theme) async {
    await _database.setSetting(_themeKey, theme);
  }

  // Font size settings
  Future<double> getFontSize() async {
    final size = await _database.getSetting(_fontSizeKey);
    return size != null ? double.parse(size) : 16.0;
  }

  Future<void> setFontSize(double size) async {
    await _database.setSetting(_fontSizeKey, size.toString());
  }

  // Practice grid settings
  Future<String> getGridType() async {
    return await _database.getSetting(_gridTypeKey) ?? '米字格';
  }

  Future<void> setGridType(String type) async {
    await _database.setSetting(_gridTypeKey, type);
  }

  // Backup settings
  Future<DateTime?> getLastBackupTime() async {
    final timestamp = await _database.getSetting(_lastBackupKey);
    return timestamp != null 
        ? DateTime.parse(timestamp)
        : null;
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
}