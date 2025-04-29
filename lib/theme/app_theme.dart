import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_sizes.dart';
import 'app_text_styles.dart';

/// Application Theme
class AppTheme {
  /// 获取Material 3亮色主题
  static ThemeData lightM3() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: AppSizes.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
      ),
      dividerTheme: const DividerThemeData(
        space: 1,
        thickness: 1,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        labelType: NavigationRailLabelType.all,
        useIndicator: true,
        minWidth: AppSizes.navigationRailWidth,
        minExtendedWidth: 200,
      ),
    );
  }

  /// 获取Material 3暗色主题
  static ThemeData darkM3() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: AppSizes.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
      ),
      dividerTheme: const DividerThemeData(
        space: 1,
        thickness: 1,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        labelType: NavigationRailLabelType.all,
        useIndicator: true,
        minWidth: AppSizes.navigationRailWidth,
        minExtendedWidth: 200,
      ),
    );
  }

  /// 获取暗色主题
  static ThemeData dark() {
    return ThemeData.dark().copyWith(
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: Colors.grey[850]!,
        onSurface: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
      ),
    );
  }

  /// 获取亮色主题
  static ThemeData light() {
    return ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardTheme: CardTheme(
        elevation: AppSizes.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.iconPrimary,
        size: AppSizes.iconMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.r4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p8,
        ),
      ),
    );
  }
}
