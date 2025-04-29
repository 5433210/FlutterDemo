import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums/app_language.dart';
import '../../domain/enums/app_theme_mode.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/providers/shared_preferences_provider.dart';

/// Provider for application settings
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref ref;

  SettingsNotifier(this.ref) : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> setCustomFont(String? fontFamily) async {
    final prefs = ref.read(sharedPreferencesProvider);

    if (fontFamily == null) {
      await prefs.remove('custom_font_family');
      state = state.copyWith(clearCustomFont: true);
    } else {
      await prefs.setString('custom_font_family', fontFamily);
      state = state.copyWith(customFontFamily: fontFamily);
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    AppLogger.info('设置语言', tag: 'SettingsProvider', data: {
      'language': language.toString(),
      'previousLanguage': state.language.toString(),
    });

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('language', language.toStorageValue());

    state = state.copyWith(language: language);

    AppLogger.info('语言已设置', tag: 'SettingsProvider', data: {
      'language': language.toString(),
      'storageValue': language.toStorageValue(),
    });
  }

  Future<void> setScaleFactor(double factor) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble('scale_factor', factor);

    state = state.copyWith(scaleFactor: factor);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('theme_mode', mode.toStorageValue());

    state = state.copyWith(themeMode: mode);
  }

  Future<void> setUseSystemFont(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('use_system_font', value);

    state = state.copyWith(useSystemFont: value);
  }

  Future<void> _loadSettings() async {
    final prefs = ref.read(sharedPreferencesProvider);

    // 添加日志，记录从SharedPreferences加载设置
    AppLogger.info('从SharedPreferences加载设置', tag: 'SettingsProvider', data: {
      'theme_mode': prefs.getString('theme_mode'),
      'language': prefs.getString('language'),
      'use_system_font': prefs.getBool('use_system_font'),
      'custom_font_family': prefs.getString('custom_font_family'),
      'scale_factor': prefs.getDouble('scale_factor'),
    });

    final themeMode = AppThemeMode.fromString(
      prefs.getString('theme_mode'),
    );

    final language = AppLanguage.fromString(
      prefs.getString('language'),
    );

    final useSystemFont = prefs.getBool('use_system_font') ?? true;
    final customFontFamily = prefs.getString('custom_font_family');
    final scaleFactor = prefs.getDouble('scale_factor') ?? 1.0;

    AppLogger.info('设置已加载', tag: 'SettingsProvider', data: {
      'themeMode': themeMode.toString(),
      'language': language.toString(),
      'useSystemFont': useSystemFont,
      'customFontFamily': customFontFamily,
      'scaleFactor': scaleFactor,
    });

    state = SettingsState(
      themeMode: themeMode,
      language: language,
      useSystemFont: useSystemFont,
      customFontFamily: customFontFamily,
      scaleFactor: scaleFactor,
    );
  }
}

/// Settings state model
class SettingsState {
  final AppThemeMode themeMode;
  final AppLanguage language;
  final bool useSystemFont;
  final String? customFontFamily;
  final double scaleFactor;

  const SettingsState({
    this.themeMode = AppThemeMode.system,
    this.language = AppLanguage.system,
    this.useSystemFont = true,
    this.customFontFamily,
    this.scaleFactor = 1.0,
  });

  SettingsState copyWith({
    AppThemeMode? themeMode,
    AppLanguage? language,
    bool? useSystemFont,
    String? customFontFamily,
    double? scaleFactor,
    bool clearCustomFont = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      useSystemFont: useSystemFont ?? this.useSystemFont,
      customFontFamily:
          clearCustomFont ? null : (customFontFamily ?? this.customFontFamily),
      scaleFactor: scaleFactor ?? this.scaleFactor,
    );
  }
}
