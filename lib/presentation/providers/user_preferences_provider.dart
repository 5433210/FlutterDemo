import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/repositories/user_preferences_repository_impl.dart';
import '../../application/services/user_preferences_service.dart';
import '../../domain/models/character/processing_options.dart';
import '../../domain/models/user/user_preferences.dart';
import '../../domain/repositories/user_preferences_repository.dart';
import '../../infrastructure/providers/database_providers.dart';

/// 默认降噪设置提供者
final defaultNoiseReductionProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(userPreferencesServiceProvider);
  return await service.getDefaultNoiseReduction();
});

/// 默认处理选项提供者
final defaultProcessingOptionsProvider =
    FutureProvider<ProcessingOptions>((ref) async {
  final service = ref.watch(userPreferencesServiceProvider);
  return await service.getDefaultProcessingOptions();
});

/// 默认阈值提供者
final defaultThresholdProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(userPreferencesServiceProvider);
  return await service.getDefaultThreshold();
});

/// 用户偏好设置通知器提供者
final userPreferencesNotifierProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
  final service = ref.watch(userPreferencesServiceProvider);
  return UserPreferencesNotifier(service);
});

/// 用户偏好设置状态提供者
final userPreferencesProvider = FutureProvider<UserPreferences>((ref) async {
  final service = ref.watch(userPreferencesServiceProvider);
  return await service.getUserPreferences();
});

/// 用户偏好设置仓库提供者
final userPreferencesRepositoryProvider =
    Provider<UserPreferencesRepository>((ref) {
  final db = ref.watch(initializedDatabaseProvider);
  return UserPreferencesRepositoryImpl(db);
});

/// 用户偏好设置服务提供者
final userPreferencesServiceProvider = Provider<UserPreferencesService>((ref) {
  final repository = ref.watch(userPreferencesRepositoryProvider);
  return UserPreferencesService(repository);
});

/// 用户偏好设置通知器
class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  final UserPreferencesService _service;

  UserPreferencesNotifier(this._service) : super(const UserPreferences()) {
    _loadPreferences();
  }

  /// 重置为默认值
  Future<void> resetToDefaults() async {
    try {
      await _service.resetToDefaults();
      state = const UserPreferences();
    } catch (e) {
      rethrow;
    }
  }

  /// 保存当前设置为默认值
  Future<void> saveCurrentAsDefaults(ProcessingOptions currentOptions) async {
    try {
      await _service.saveCurrentAsDefaults(currentOptions);
      state = UserPreferences(
        defaultThreshold: currentOptions.threshold,
        defaultNoiseReduction: currentOptions.noiseReduction,
        defaultBrushSize: currentOptions.brushSize,
        defaultInverted: currentOptions.inverted,
        defaultShowContour: currentOptions.showContour,
        defaultContrast: currentOptions.contrast,
        defaultBrightness: currentOptions.brightness,
        updateTime: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 更新默认亮度设置
  Future<void> updateDefaultBrightness(double brightness) async {
    try {
      await _service.saveDefaultBrightness(brightness);
      state = state.copyWith(
        defaultBrightness: brightness,
        updateTime: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 更新默认画笔大小
  Future<void> updateDefaultBrushSize(double brushSize) async {
    try {
      await _service.saveDefaultBrushSize(brushSize);
      state = state.copyWith(
        defaultBrushSize: brushSize,
        updateTime: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 更新默认对比度设置
  Future<void> updateDefaultContrast(double contrast) async {
    try {
      await _service.saveDefaultContrast(contrast);
      state = state.copyWith(
        defaultContrast: contrast,
        updateTime: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 更新默认反色设置
  Future<void> updateDefaultInverted(bool inverted) async {
    try {
      await _service.saveDefaultInverted(inverted);
      state = state.copyWith(
        defaultInverted: inverted,
        updateTime: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 更新默认降噪设置
  Future<void> updateDefaultNoiseReduction(double noiseReduction) async {
    try {
      await _service.saveDefaultNoiseReduction(noiseReduction);
      state = state.copyWith(
        defaultNoiseReduction: noiseReduction,
        updateTime: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 更新默认显示轮廓设置
  Future<void> updateDefaultShowContour(bool showContour) async {
    try {
      await _service.saveDefaultShowContour(showContour);
      state = state.copyWith(
        defaultShowContour: showContour,
        updateTime: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 更新默认阈值
  Future<void> updateDefaultThreshold(double threshold) async {
    try {
      await _service.saveDefaultThreshold(threshold);
      state = state.copyWith(
        defaultThreshold: threshold,
        updateTime: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 加载用户偏好设置
  Future<void> _loadPreferences() async {
    try {
      final preferences = await _service.getUserPreferences();
      if (mounted) {
        state = preferences;
      }
    } catch (e) {
      // 保持默认状态
    }
  }
}
