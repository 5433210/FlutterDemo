import 'package:flutter/material.dart';

/// The theme mode options supported by the application
enum AppThemeMode {
  /// System theme mode (follows device settings)
  system,

  /// Light theme mode
  light,

  /// Dark theme mode
  dark;

  /// Get a friendly display name for the theme mode
  String get displayName {
    return switch (this) {
      AppThemeMode.system => '跟随系统',
      AppThemeMode.light => '浅色模式',
      AppThemeMode.dark => '深色模式',
    };
  }

  /// Get the icon for the theme mode
  IconData get icon {
    return switch (this) {
      AppThemeMode.system => Icons.settings_system_daydream_outlined,
      AppThemeMode.light => Icons.light_mode_outlined,
      AppThemeMode.dark => Icons.dark_mode_outlined,
    };
  }

  /// Convert to Flutter's ThemeMode
  ThemeMode toFlutterThemeMode() {
    return switch (this) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
  }

  /// Convert to string value (for storage)
  String toStorageValue() {
    return name;
  }

  /// Parse from string value (for storage)
  static AppThemeMode fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'system' => AppThemeMode.system,
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system, // Default to system if unknown
    };
  }
}
