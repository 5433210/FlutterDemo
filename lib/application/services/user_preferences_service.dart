import '../../domain/models/character/processing_options.dart';
import '../../domain/models/user/user_preferences.dart';
import '../../domain/repositories/user_preferences_repository.dart';
import '../../infrastructure/logging/logger.dart';

/// 用户偏好设置服务
class UserPreferencesService {
  final UserPreferencesRepository _repository;

  UserPreferencesService(this._repository);

  /// 获取默认降噪设置
  Future<double> getDefaultNoiseReduction() async {
    return await _repository.getDefaultNoiseReduction();
  }

  /// 获取默认的处理选项
  Future<ProcessingOptions> getDefaultProcessingOptions() async {
    try {
      final preferences = await _repository.getUserPreferences();

      return ProcessingOptions(
        threshold: preferences.defaultThreshold,
        noiseReduction: preferences.defaultNoiseReduction,
        brushSize: preferences.defaultBrushSize,
        inverted: preferences.defaultInverted,
        showContour: preferences.defaultShowContour,
        contrast: preferences.defaultContrast,
        brightness: preferences.defaultBrightness,
      );
    } catch (e) {
      AppLogger.error('获取默认处理选项失败', error: e);
      // 返回硬编码的默认值
      return const ProcessingOptions();
    }
  }

  /// 获取默认阈值
  Future<double> getDefaultThreshold() async {
    return await _repository.getDefaultThreshold();
  }

  /// 获取用户偏好设置
  Future<UserPreferences> getUserPreferences() async {
    return await _repository.getUserPreferences();
  }

  /// 重置为默认值
  Future<void> resetToDefaults() async {
    await _repository.resetToDefaults();
  }

  /// 将当前设置保存为默认值
  Future<void> saveCurrentAsDefaults(ProcessingOptions currentOptions) async {
    try {
      final preferences = UserPreferences(
        defaultThreshold: currentOptions.threshold,
        defaultNoiseReduction: currentOptions.noiseReduction,
        defaultBrushSize: currentOptions.brushSize,
        defaultInverted: currentOptions.inverted,
        defaultShowContour: currentOptions.showContour,
        defaultContrast: currentOptions.contrast,
        defaultBrightness: currentOptions.brightness,
        updateTime: DateTime.now(),
      );

      await _repository.saveUserPreferences(preferences);
      AppLogger.info('当前设置已保存为默认值');
    } catch (e) {
      AppLogger.error('保存当前设置为默认值失败', error: e);
      rethrow;
    }
  }

  /// 保存默认亮度设置
  Future<void> saveDefaultBrightness(double brightness) async {
    await _repository.saveDefaultBrightness(brightness);
  }

  /// 保存默认画笔大小
  Future<void> saveDefaultBrushSize(double brushSize) async {
    await _repository.saveDefaultBrushSize(brushSize);
  }

  /// 保存默认对比度设置
  Future<void> saveDefaultContrast(double contrast) async {
    await _repository.saveDefaultContrast(contrast);
  }

  /// 保存默认反色设置
  Future<void> saveDefaultInverted(bool inverted) async {
    await _repository.saveDefaultInverted(inverted);
  }

  /// 保存默认降噪设置
  Future<void> saveDefaultNoiseReduction(double noiseReduction) async {
    await _repository.saveDefaultNoiseReduction(noiseReduction);
  }

  /// 保存默认显示轮廓设置
  Future<void> saveDefaultShowContour(bool showContour) async {
    await _repository.saveDefaultShowContour(showContour);
  }

  /// 保存默认阈值
  Future<void> saveDefaultThreshold(double threshold) async {
    await _repository.saveDefaultThreshold(threshold);
  }

  /// 保存用户偏好设置
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    await _repository.saveUserPreferences(preferences);
  }
}
