import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryColor = Color(0xFF3F51B5);  // Indigo
  static const Color primaryLightColor = Color(0xFF7986CB);
  static const Color primaryDarkColor = Color(0xFF303F9F);
  static const Color primaryContainerColor = Color(0xFFE8EAF6);
  static const Color onPrimaryColor = Color(0xFFFFFFFF);

  // Secondary Colors
  static const Color secondaryColor = Color(0xFF4CAF50); // Green
  static const Color secondaryLightColor = Color(0xFF81C784);
  static const Color secondaryDarkColor = Color(0xFF388E3C);
  static const Color secondaryContainerColor = Color(0xFFE8F5E9);
  static const Color onSecondaryColor = Color(0xFF000000);

  // Background Colors
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF43A047);
  static const Color warningColor = Color(0xFFFFA000);
  static const Color infoColor = Color(0xFF2196F3);

  // Text Colors
  static const Color textColor = Color(0xFF212121);
  static const Color secondaryTextColor = Color(0xFF757575);
  static const Color disabledTextColor = Color(0xFFBDBDBD);
  static const Color titleText = Color(0xFF0D1B2A);
  static const Color primaryText = Color(0xFF212121);
  static const Color secondaryText = Color(0xFF757575);

  // Border Colors
  static const Color border = Color(0xFFDDDDDD);
  static const Color divider = Color(0xFFE0E0E0);

  // Status Colors
  static const Color selected = Color(0xFFE3F2FD);
  static const Color unselected = Color(0xFFEEEEEE);
  static const Color disabled = Color(0xFFF5F5F5);
  static const Color disabledText = Color(0xFF9E9E9E);
  static const Color hover = Color(0x0A000000); // 4% opacity black
  
  // Specialty Colors
  static const Color sidebarBackground = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  static const Color filterChipSelected = Color(0xFFE1F5FE);
  static const Color filterChipUnselected = Color(0xFFF5F5F5);
  static const Color tagBackground = Color(0xFFE8F5E9);
  static const Color tagText = Color(0xFF388E3C);
  
  // Semantic Colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF2196F3);
  
  // Material Design System Colors
  static const MaterialColor primary = MaterialColor(
    0xFF3F51B5,
    <int, Color>{
      50: Color(0xFFE8EAF6),
      100: Color(0xFFC5CAE9),
      200: Color(0xFF9FA8DA),
      300: Color(0xFF7986CB),
      400: Color(0xFF5C6BC0),
      500: Color(0xFF3F51B5),
      600: Color(0xFF3949AB),
      700: Color(0xFF303F9F),
      800: Color(0xFF283593),
      900: Color(0xFF1A237E),
    },
  );

  // 防止实例化
  const AppColors._();
}