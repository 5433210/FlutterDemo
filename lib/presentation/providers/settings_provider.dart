import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/app_theme_mode.dart';
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

    final themeMode = AppThemeMode.fromString(
      prefs.getString('theme_mode'),
    );

    final useSystemFont = prefs.getBool('use_system_font') ?? true;
    final customFontFamily = prefs.getString('custom_font_family');
    final scaleFactor = prefs.getDouble('scale_factor') ?? 1.0;

    state = SettingsState(
      themeMode: themeMode,
      useSystemFont: useSystemFont,
      customFontFamily: customFontFamily,
      scaleFactor: scaleFactor,
    );
  }
}

/// Settings state model
class SettingsState {
  final AppThemeMode themeMode;
  final bool useSystemFont;
  final String? customFontFamily;
  final double scaleFactor;

  const SettingsState({
    this.themeMode = AppThemeMode.system,
    this.useSystemFont = true,
    this.customFontFamily,
    this.scaleFactor = 1.0,
  });

  SettingsState copyWith({
    AppThemeMode? themeMode,
    bool? useSystemFont,
    String? customFontFamily,
    double? scaleFactor,
    bool clearCustomFont = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      useSystemFont: useSystemFont ?? this.useSystemFont,
      customFontFamily:
          clearCustomFont ? null : (customFontFamily ?? this.customFontFamily),
      scaleFactor: scaleFactor ?? this.scaleFactor,
    );
  }
}
