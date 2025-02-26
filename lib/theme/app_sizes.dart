import 'package:flutter/material.dart';

class AppSizes {
  // Window breakpoints
  static const double minWindowWidth = 1024.0;
  static const double minWindowHeight = 768.0;
  static const double breakpointXs = 600.0;
  static const double breakpointSm = 768.0;
  static const double breakpointMd = 992.0;
  static const double breakpointLg = 1200.0;
  static const double breakpointXl = 1400.0;

  // Base spacing
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Typography (字体尺寸)
  static const double fontTiny = 12.0;
  static const double fontSmall = 14.0;
  static const double fontMedium = 16.0;
  static const double fontLarge = 20.0;
  static const double fontTitle = 24.0;

  // Layout components
  static const double appBarHeight = 56.0;
  static const double sidebarWidth = 256.0;
  static const double headerHeight = 56.0;
  static const double toolbarHeight = 56.0;
  static const double footerHeight = 64.0;
  static const double tableHeaderHeight = 48.0;
  static const double pageBarHeight = 48.0;
  static const double pageToolbarHeight = 48.0;
  static const double navigationRailWidth = 72.0;
  
  // Button dimensions
  static const double buttonHeight = 36.0;
  static const double buttonMinWidth = 64.0;
  static const double buttonIconSize = 18.0;
  static const double buttonElevation = 2.0;
  static const double buttonHeightLarge = 44.0;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 8.0,
  );

  // Radius (圆角)
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;

  // Content constraints
  static const double minContentWidth = minWindowWidth * 0.8;  // 80% of min window width
  static const double minContentHeight = minWindowHeight * 0.8; // 80% of min window height
  static const double maxContentWidth = breakpointLg;
  static const double contentPadding = m;

  // Form elements
  static const double formWidth = 320.0;
  static const double formFieldHeight = 48.0;
  static const double formSpacing = m;
  static const double formLabelWidth = 120.0;
  static const double formFieldSpacing = s;

  // Cards (卡片)
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const double cardRadius = 8.0;
  static const double cardElevation = 1.0;
  static const double cardElevationSelected = 4.0;

  // Dialog dimensions
  static const double dialogMinWidth = 400.0;
  static const double dialogMaxWidth = minWindowWidth * 0.9;
  static const double dialogMinHeight = 300.0;
  static const double dialogMaxHeight = minWindowHeight * 0.9;
  static const double dialogHeaderHeight = 56.0;
  static const double dialogFooterHeight = 64.0;
  static const double dialogContentPadding = m;
  static const double dialogWidth = 400.0;
  static const double dialogWidthWide = 600.0;
  static const double dialogHeight = 600.0;
  static const double dialogHeightTall = 800.0;
  
  // Work import dialog specific
  static const double workImportDialogWidth = minWindowWidth * 0.8;
  static const double workImportDialogHeight = minWindowHeight * 0.8;
  static const double workImportPreviewWidth = workImportDialogWidth * 0.6;
  static const double workImportFormWidth = workImportDialogWidth * 0.4;

  // List items
  static const double thumbnailSize = 80.0;
  static const double listItemHeight = 120.0;
  static const double listItemSpacing = s;
  static const double listItemMinHeight = 100.0;
  static const double listItemMaxHeight = 120.0;
  static const double listItemPadding = m;

  // Grid & List (网格和列表)
  static const int gridCrossAxisCount = 4;
  static const double gridMainAxisSpacing = m;
  static const double gridCrossAxisSpacing = m;
  static const double gridCardWidth = 240.0;
  static const double gridCardImageHeight = 180.0;
  static const double gridCardInfoHeight = 120.0;
  static const double gridItemTotalHeight = 320.0;
  static const double gridItemImageHeight = 200.0;
  static const double gridItemWidth = 200.0;
  static const double gridItemPadding = m;
  static const double gridCardPadding = m;

  // Icons (图标尺寸)
  static const double iconTiny = 16.0;
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXSmall = 8.0;

  // Shared components
  static const double dividerThickness = 1.0;
  static const double iconSize = 24.0;
  static const double tooltipHeight = 24.0;

  static const double spacingTiny = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  
  // Prevent instantiation
  const AppSizes._();
}