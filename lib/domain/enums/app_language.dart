import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The language options supported by the application
enum AppLanguage {
  /// System language (follows device settings)
  system,

  /// Simplified Chinese language
  zh,

  /// Traditional Chinese language
  zhTw,

  /// English language
  en,

  /// Japanese language
  ja,

  /// Korean language
  ko;

  /// Get the icon for the language
  IconData get icon {
    return switch (this) {
      AppLanguage.system => Icons.language,
      AppLanguage.zh => Icons.language,
      AppLanguage.zhTw => Icons.language,
      AppLanguage.en => Icons.language,
      AppLanguage.ja => Icons.language,
      AppLanguage.ko => Icons.language,
    };
  }

  /// Get a friendly display name for the language
  String getDisplayName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      AppLanguage.system => l10n.languageSystem,
      AppLanguage.zh => l10n.languageZh,
      AppLanguage.zhTw => l10n.languageZhTw,
      AppLanguage.en => l10n.languageEn,
      AppLanguage.ja => l10n.languageJa,
      AppLanguage.ko => l10n.languageKo,
    };
  }

  /// Convert to Locale or null for system
  Locale? toLocale() {
    final locale = switch (this) {
      AppLanguage.system => null, // null means follow system locale
      AppLanguage.zh => const Locale('zh'),
      AppLanguage.zhTw => const Locale('zh', 'TW'),
      AppLanguage.en => const Locale('en'),
      AppLanguage.ja => const Locale('ja'),
      AppLanguage.ko => const Locale('ko'),
    };

    debugPrint(
        'AppLanguage.toLocale: 语言设置 $this 转换为 Locale: ${locale?.toString() ?? "null (跟随系统)"}');
    return locale;
  }

  /// Convert to string value (for storage)
  String toStorageValue() {
    return name;
  }

  /// Parse from string value (for storage)
  static AppLanguage fromString(String? value) {
    debugPrint('AppLanguage.fromString: 从字符串 "$value" 解析语言设置');
    final result = switch (value?.toLowerCase()) {
      'system' => AppLanguage.system,
      'zh' => AppLanguage.zh,
      'zhtw' => AppLanguage.zhTw,
      'en' => AppLanguage.en,
      'ja' => AppLanguage.ja,
      'ko' => AppLanguage.ko,
      _ => AppLanguage.system, // Default to system if unknown
    };
    debugPrint('AppLanguage.fromString: 解析结果: $result');
    return result;
  }
}
