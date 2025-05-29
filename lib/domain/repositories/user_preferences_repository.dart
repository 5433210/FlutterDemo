import '../models/user/user_preferences.dart';

/// 用户偏好设置仓库接口
abstract class UserPreferencesRepository {
  /// 获取默认的降噪设置
  Future<double> getDefaultNoiseReduction();

  /// 获取默认的阈值设置
  Future<double> getDefaultThreshold();

  /// 获取用户偏好设置
  Future<UserPreferences> getUserPreferences();

  /// 重置为默认值
  Future<void> resetToDefaults();

  /// 保存默认的亮度设置
  Future<void> saveDefaultBrightness(double brightness);

  /// 保存默认的画笔大小
  Future<void> saveDefaultBrushSize(double brushSize);

  /// 保存默认的对比度设置
  Future<void> saveDefaultContrast(double contrast);

  /// 保存默认的反色设置
  Future<void> saveDefaultInverted(bool inverted);

  /// 保存默认的降噪设置
  Future<void> saveDefaultNoiseReduction(double noiseReduction);

  /// 保存默认的显示轮廓设置
  Future<void> saveDefaultShowContour(bool showContour);

  /// 保存默认的阈值设置
  Future<void> saveDefaultThreshold(double threshold);

  /// 保存用户偏好设置
  Future<void> saveUserPreferences(UserPreferences preferences);
}
