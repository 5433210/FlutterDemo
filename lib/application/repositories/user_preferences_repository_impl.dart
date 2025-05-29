import '../../domain/models/user/user_preferences.dart';
import '../../domain/repositories/user_preferences_repository.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/persistence/database_interface.dart';

class UserPreferencesRepositoryImpl implements UserPreferencesRepository {
  static const String _keyThreshold = 'default_threshold';
  static const String _keyNoiseReduction = 'default_noise_reduction';
  static const String _keyBrushSize = 'default_brush_size';
  static const String _keyInverted = 'default_inverted';
  static const String _keyShowContour = 'default_show_contour';
  static const String _keyContrast = 'default_contrast';
  static const String _keyBrightness = 'default_brightness';
  final DatabaseInterface _db;

  UserPreferencesRepositoryImpl(this._db);

  @override
  Future<double> getDefaultNoiseReduction() async {
    try {
      final result = await _db.rawQuery(
        'SELECT value FROM settings WHERE key = ? LIMIT 1',
        [_keyNoiseReduction],
      );

      if (result.isNotEmpty) {
        return double.tryParse(result.first['value'] as String) ?? 0.0;
      }
      return 0.0; // 默认值
    } catch (e) {
      AppLogger.error('获取默认降噪设置失败', error: e);
      return 0.0;
    }
  }

  @override
  Future<double> getDefaultThreshold() async {
    try {
      final result = await _db.rawQuery(
        'SELECT value FROM settings WHERE key = ? LIMIT 1',
        [_keyThreshold],
      );

      if (result.isNotEmpty) {
        return double.tryParse(result.first['value'] as String) ?? 128.0;
      }
      return 128.0; // 默认值
    } catch (e) {
      AppLogger.error('获取默认阈值失败', error: e);
      return 128.0;
    }
  }

  @override
  Future<UserPreferences> getUserPreferences() async {
    try {
      // 获取所有偏好设置
      final results = await _db.rawQuery(
        'SELECT key, value FROM settings WHERE key IN (?, ?, ?, ?, ?, ?, ?)',
        [
          _keyThreshold,
          _keyNoiseReduction,
          _keyBrushSize,
          _keyInverted,
          _keyShowContour,
          _keyContrast,
          _keyBrightness,
        ],
      );

      // 创建设置映射
      final settings = <String, String>{};
      for (final row in results) {
        settings[row['key'] as String] = row['value'] as String;
      }

      // 构建用户偏好设置对象
      return UserPreferences(
        defaultThreshold:
            double.tryParse(settings[_keyThreshold] ?? '') ?? 128.0,
        defaultNoiseReduction:
            double.tryParse(settings[_keyNoiseReduction] ?? '') ?? 0.0,
        defaultBrushSize:
            double.tryParse(settings[_keyBrushSize] ?? '') ?? 10.0,
        defaultInverted: settings[_keyInverted] == 'true',
        defaultShowContour: settings[_keyShowContour] == 'true',
        defaultContrast: double.tryParse(settings[_keyContrast] ?? '') ?? 1.0,
        defaultBrightness:
            double.tryParse(settings[_keyBrightness] ?? '') ?? 0.0,
        updateTime: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('获取用户偏好设置失败', error: e);
      // 返回默认设置
      return const UserPreferences();
    }
  }

  @override
  Future<void> resetToDefaults() async {
    try {
      // 删除所有相关设置，让它们回到默认值
      await _db.rawUpdate(
        'DELETE FROM settings WHERE key IN (?, ?, ?, ?, ?, ?, ?)',
        [
          _keyThreshold,
          _keyNoiseReduction,
          _keyBrushSize,
          _keyInverted,
          _keyShowContour,
          _keyContrast,
          _keyBrightness,
        ],
      );

      AppLogger.info('用户偏好设置已重置为默认值');
    } catch (e) {
      AppLogger.error('重置用户偏好设置失败', error: e);
      rethrow;
    }
  }

  @override
  Future<void> saveDefaultBrightness(double brightness) async {
    try {
      await _saveSetting(_keyBrightness, brightness.toString());
      AppLogger.info('默认亮度设置保存成功', data: {'brightness': brightness});
    } catch (e) {
      AppLogger.error('保存默认亮度设置失败', error: e);
      rethrow;
    }
  }

  @override
  Future<void> saveDefaultBrushSize(double brushSize) async {
    try {
      await _saveSetting(_keyBrushSize, brushSize.toString());
      AppLogger.info('默认画笔大小保存成功', data: {'brushSize': brushSize});
    } catch (e) {
      AppLogger.error('保存默认画笔大小失败', error: e);
      rethrow;
    }
  }

  @override
  Future<void> saveDefaultContrast(double contrast) async {
    try {
      await _saveSetting(_keyContrast, contrast.toString());
      AppLogger.info('默认对比度设置保存成功', data: {'contrast': contrast});
    } catch (e) {
      AppLogger.error('保存默认对比度设置失败', error: e);
      rethrow;
    }
  }

  @override
  Future<void> saveDefaultInverted(bool inverted) async {
    try {
      await _saveSetting(_keyInverted, inverted.toString());
      AppLogger.info('默认反转设置保存成功', data: {'inverted': inverted});
    } catch (e) {
      AppLogger.error('保存默认反转设置失败', error: e);
      rethrow;
    }
  }

  @override
  Future<void> saveDefaultNoiseReduction(double noiseReduction) async {
    try {
      await _saveSetting(_keyNoiseReduction, noiseReduction.toString());
      AppLogger.info('默认降噪设置保存成功', data: {'noiseReduction': noiseReduction});
    } catch (e) {
      AppLogger.error('保存默认降噪设置失败', error: e);
      rethrow;
    }
  }

  @override
  Future<void> saveDefaultShowContour(bool showContour) async {
    try {
      await _saveSetting(_keyShowContour, showContour.toString());
      AppLogger.info('默认显示轮廓设置保存成功', data: {'showContour': showContour});
    } catch (e) {
      AppLogger.error('保存默认显示轮廓设置失败', error: e);
      rethrow;
    }
  }

  @override
  Future<void> saveDefaultThreshold(double threshold) async {
    try {
      await _saveSetting(_keyThreshold, threshold.toString());
      AppLogger.info('默认阈值保存成功', data: {'threshold': threshold});
    } catch (e) {
      AppLogger.error('保存默认阈值失败', error: e);
      rethrow;
    }
  }

  @override
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    try {
      // 批量保存设置
      await _saveSetting(
          _keyThreshold, preferences.defaultThreshold.toString());
      await _saveSetting(
          _keyNoiseReduction, preferences.defaultNoiseReduction.toString());
      await _saveSetting(
          _keyBrushSize, preferences.defaultBrushSize.toString());
      await _saveSetting(_keyInverted, preferences.defaultInverted.toString());
      await _saveSetting(
          _keyShowContour, preferences.defaultShowContour.toString());
      await _saveSetting(_keyContrast, preferences.defaultContrast.toString());
      await _saveSetting(
          _keyBrightness, preferences.defaultBrightness.toString());

      AppLogger.info('用户偏好设置保存成功');
    } catch (e) {
      AppLogger.error('保存用户偏好设置失败', error: e);
      rethrow;
    }
  }

  /// 保存单个设置
  Future<void> _saveSetting(String key, String value) async {
    await _db.rawUpdate(
      'INSERT OR REPLACE INTO settings (key, value, updateTime) VALUES (?, ?, ?)',
      [key, value, DateTime.now().toIso8601String()],
    );
  }
}
