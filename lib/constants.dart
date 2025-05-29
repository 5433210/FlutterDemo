import 'package:flutter/material.dart';

// 项目常量集合
// 本文件收集了项目中使用的常量，按文件和类型分组
// 包含常量名称、值、所在文件和行号信息

/// 主题相关常量

// 来自 lib/theme/app_colors.dart
class AppColors {
  // 主颜色
  static const primary = Color(0xFF2196F3); // 行: 4
  static const primaryLight = Color(0xFF64B5F6); // 行: 5
  static const primaryDark = Color(0xFF1976D2); // 行: 6

  // 次要颜色
  static const secondary = Color(0xFF4CAF50); // 行: 9
  static const secondaryLight = Color(0xFF81C784); // 行: 10
  static const secondaryDark = Color(0xFF388E3C); // 行: 11

  // 背景颜色
  static const background = Color(0xFFF5F5F5); // 行: 14
  static const surface = Colors.white; // 行: 15
  static const selectedCard = Color(0xFFE3F2FD); // 行: 16

  // 文本颜色
  static const textPrimary = Color(0xFF212121); // 行: 19
  static const textSecondary = Color(0xFF757575); // 行: 20
  static const textHint = Color(0xFFBDBDBD); // 行: 21

  // 状态颜色
  static const success = Color(0xFF4CAF50); // 行: 24
  static const warning = Color(0xFFFFC107); // 行: 25
  static const error = Color(0xFFF44336); // 行: 26
  static const info = Color(0xFF2196F3); // 行: 27

  // 其他颜色
  static const cardShadow = Color(0x1F000000); // 行: 30
  static const divider = Color(0xFFE0E0E0); // 行: 31

  // 图标颜色
  static const iconPrimary = Color(0xFF616161); // 行: 34
  static const iconSecondary = Color(0xFF9E9E9E); // 行: 35
  static const iconDisabled = Color(0xFFBDBDBD); // 行: 36
}

// 来自 lib/theme/app_text_styles.dart
class AppTextStyles {
  static const displayLarge = TextStyle(); // 行: 5
  static const displayMedium = TextStyle(); // 行: 11
  static const displaySmall = TextStyle(); // 行: 17
  static const headlineLarge = TextStyle(); // 行: 23
  static const headlineMedium = TextStyle(); // 行: 29
  static const headlineSmall = TextStyle(); // 行: 35
  static const titleLarge = TextStyle(); // 行: 41
  static const titleMedium = TextStyle(); // 行: 47
  static const titleSmall = TextStyle(); // 行: 53
  static const bodyLarge = TextStyle(); // 行: 59
  static const bodyMedium = TextStyle(); // 行: 65
  static const bodySmall = TextStyle(); // 行: 71
  static const labelLarge = TextStyle(); // 行: 77
  static const labelMedium = TextStyle(); // 行: 83
  static const labelSmall = TextStyle(); // 行: 89
}

// 来自 lib/theme/app_sizes.dart
class AppSizes {
  // 内边距
  static const double p2 = 2.0; // 行: 3
  static const double p4 = 4.0; // 行: 4
  static const double p8 = 8.0; // 行: 5
  static const double p12 = 12.0; // 行: 6
  static const double p16 = 16.0; // 行: 7
  static const double p24 = 24.0; // 行: 8
  static const double p32 = 32.0; // 行: 9
  static const double p48 = 48.0; // 行: 10
  static const double p64 = 64.0; // 行: 11

  // 外边距
  static const double m2 = 2.0; // 行: 14
  static const double m4 = 4.0; // 行: 15
  static const double m8 = 8.0; // 行: 16
  static const double m12 = 12.0; // 行: 17
  static const double m16 = 16.0; // 行: 18
  static const double m24 = 24.0; // 行: 19
  static const double m32 = 32.0; // 行: 20
  static const double m48 = 48.0; // 行: 21
  static const double m64 = 64.0; // 行: 22

  // 尺寸别名
  static const double xxs = 2.0; // 行: 25
  static const double xs = 4.0; // 行: 26
  static const double s = 8.0; // 行: 27
  static const double m = 16.0; // 行: 28
  static const double l = 24.0; // 行: 29
  static const double xl = 32.0; // 行: 30
  static const double xxl = 48.0; // 行: 31

  // 间距
  static const double spacingTiny = 2.0; // 行: 34
  static const double spacingSmall = 8.0; // 行: 35
  static const double spacingMedium = 16.0; // 行: 36
  static const double spacingLarge = 24.0; // 行: 37

  // 圆角
  static const double r4 = 4.0; // 行: 40
  static const double r8 = 8.0; // 行: 41
  static const double r12 = 12.0; // 行: 42
  static const double r16 = 16.0; // 行: 43
  static const double r24 = 24.0; // 行: 44

  static const double radiusSmall = 4.0; // 行: 46
  static const double radiusMedium = 8.0; // 行: 47
  static const double radiusLarge = 12.0; // 行: 48

  // 卡片相关
  static const double cardRadius = 8.0; // 行: 51
  static const double cardElevation = 1.0; // 行: 52
  static const double cardElevationSelected = 4.0; // 行: 53

  // 图标尺寸
  static const double iconSmall = 16.0; // 行: 56
  static const double iconMedium = 24.0; // 行: 57
  static const double iconLarge = 32.0; // 行: 58

  // 布局尺寸
  static const double appBarHeight = 48.0; // 行: 61
  static const double sidebarWidth = 256.0; // 行: 62
  static const double navigationRailWidth = 72.0; // 行: 63
  static const double dividerThickness = 1.0; // 行: 64
  static const double pageToolbarHeight = 48.0; // 行: 65
  static const double dialogHeaderHeight = 48.0; // 行: 66
  static const double tableHeaderHeight = 48.0; // 行: 67

  // 网格布局相关
  static const double gridCardWidth = 280.0; // 行: 70
  static const double gridCardImageHeight = 200.0; // 行: 71
  static const double gridCardInfoHeight = 80.0; // 行: 72
  static const int gridCrossAxisCount = 4; // 行: 73
  static const double gridMainAxisSpacing = 16.0; // 行: 74
  static const double gridCrossAxisSpacing = 16.0; // 行: 75

  // 表单相关
  static const double formFieldSpacing = 16.0; // 行: 78

  // 响应式布局断点
  static const double breakpointXs = 600.0; // 行: 81
  static const double breakpointMd = 905.0; // 行: 82
  static const double breakpointLg = 1240.0; // 行: 83
  static const double breakpointXl = 1440.0; // 行: 84
}

// 来自 lib/theme/app_images.dart
class AppImages {
  static const double iconSizeSmall = 16; // 行: 2
}

/// 路由相关常量

// 来自 lib/routes/app_routes.dart
class AppRoutes {
  static const home = '/'; // 行: 15
  static const workBrowse = '/work_browse'; // 行: 16
  static const workDetail = '/work_detail'; // 行: 17
  static const workImport = '/work_import'; // 行: 18
  static const characterList = '/character_list'; // 行: 19
  static const characterDetail = '/character_detail'; // 行: 20
  static const practiceList = '/practice_list'; // 行: 21
  static const practiceDetail = '/practice_detail'; // 行: 22
  static const practiceEdit = '/practice_edit'; // 行: 23
  static const settings = '/settings'; // 行: 24
}

/// 工具类常量

// 来自 lib/utils/file_size_formatter.dart
class FileSizeConstants {
  static const suffixes = [
    'B',
    'KB',
    'MB',
    'GB',
    'TB',
    'PB',
    'EB',
    'ZB',
    'YB'
  ]; // 行: 11
}

// 来自 lib/utils/cache/path_cache.dart
class PathCacheConstants {
  static const int cacheTtlMs = 5000; // 5 seconds   // 行: 16
}

/// 特性模块常量

// 来自 lib/widgets/character_edit/character_edit_canvas.dart
class CharacterEditCanvasConstants {}

// 来自 lib/widgets/character_edit/character_edit_panel.dart
class CharacterEditPanelConstants {}

// 来自 lib/widgets/character_edit/keyboard/shortcut_handler.dart
class ShortcutHandlerConstants {
  // 快捷键（简化表示）
  static const String save = 'Ctrl+S'; // 行: 6
  static const String undo = 'Ctrl+Z'; // 行: 12
  static const String redo = 'Ctrl+Shift+Z'; // 行: 18
  static const String openInput = 'Ctrl+I'; // 行: 24
  static const String toggleInvert = 'I'; // 行: 30
  static const String toggleImageInvert = 'Alt+I'; // 行: 36
  static const String toggleContour = 'C'; // 行: 42
  static const String togglePanMode = 'Space'; // 行: 48
  static const String increaseBrushSize = ']'; // 行: 54
  static const String decreaseBrushSize = '['; // 行: 60

  // 笔刷相关常量
  static const double brushSizeStep = 5.0; // 行: 66
  static const double minBrushSize = 1.0; // 行: 69
  static const double maxBrushSize = 50.0; // 行: 70
}

// 来自 lib/widgets/character_edit/layers/ui_layer.dart
class UILayerConstants {
  static const arrowSize = 4.0; // 行: 317
}

// 来自 lib/presentation/widgets/practice/property_panels/practice_property_panel_image.dart
class PracticePropertyPanelImageConstants {
  static const previewFitMode = 'contain'; // 行: 1286
  static const distance = 4.0; // 每段虚线的长度      // 行: 1876
  static const cornerSize = 8.0; // 行: 2071
}

/// 常用UI常量（从代码中收集的字面量）

// EdgeInsets常量
class AppEdgeInsets {
  // 常用填充
  static const all8 = EdgeInsets.all(8.0);
  static const all16 = EdgeInsets.all(16.0);
  static const all12 = EdgeInsets.all(12.0);
  static const all4 = EdgeInsets.all(4.0);

  // 水平和垂直填充
  static const symmetric16_8 =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
  static const symmetric8_4 =
      EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0);
  static const symmetric12_8 =
      EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);
  static const symmetric16_12 =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);

  // 特定方向填充
  static const onlyBottom8 = EdgeInsets.only(bottom: 8.0);
  static const onlyBottom12 = EdgeInsets.only(bottom: 12.0);
  static const onlyTop8 = EdgeInsets.only(top: 8.0);
  static const onlyLeft8 = EdgeInsets.only(left: 8.0);
  static const onlyRight8 = EdgeInsets.only(right: 8.0);
}

// 透明度常量
class AppOpacity {
  static const full = 1.0;
  static const none = 0.0;
  static const medium = 0.5;
  static const light = 0.3;
  static const extraLight = 0.1;
  static const semiTransparent = 0.7;
}

// 尺寸相关常量
class AppDimensions {
  // 屏幕/组件比例
  static const minScale = 0.5;
  static const maxScale = 2.0;
  static const defaultScale = 1.0;

  // 动画时长
  static const defaultAnimationDuration = Duration(milliseconds: 300);
  static const fastAnimationDuration = Duration(milliseconds: 150);
  static const slowAnimationDuration = Duration(milliseconds: 500);
}

// 字符串常量
class AppStrings {
  // 图像适应模式
  static const fitModeContain = 'contain';
  static const fitModeCover = 'cover';
  static const fitModeFill = 'fill';
  static const fitModeNone = 'none';

  // 图像适应模式标签
  static const fitModeContainLabel = '适应';
  static const fitModeCoverLabel = '填充';
  static const fitModeFillLabel = '拉伸';
  static const fitModeNoneLabel = '原始';

  // 文件后缀
  static const jsonExtension = '.json';
  static const pngExtension = '.png';
  static const jpgExtension = '.jpg';

  // 路径
  static const testReportsPath = 'test/reports';
  static const testLogsPath = 'test/logs';
  static const testDataPath = 'test/data';
  static const testBackupPath = 'test/backup';

  // 常用消息
  static const loadingMessage = '加载中...';
  static const errorMessage = '发生错误';
  static const successMessage = '操作成功';
  static const noImageSelectedMessage = '没有选择图片';
}

// 颜色透明度常量
class AppColorOpacity {
  static const alphaBorder = 77; // 0.3 opacity
  static const alphaLight = 26; // 0.1 opacity
  static const alphaMedium = 128; // 0.5 opacity
  static const alphaHigh = 179; // 0.7 opacity
  static const alphaWatermark = 51; // 0.2 opacity
}

// 数值限制常量
class AppLimits {
  // 最小最大默认值
  static const minPosition = 0.0;
  static const maxPosition = 10000.0;
  static const minSize = 10.0;
  static const maxSize = 10000.0;
  static const minRotation = -360.0;
  static const maxRotation = 360.0;

  // 特定数值
  static const defaultMinimumImageSize = 1.0; // 最小图像尺寸（像素）
  static const defaultMaxImageCrop = 0.5; // 最大可裁剪比例（50%）
}

// BorderRadius常量
class AppBorderRadius {
  static const small = BorderRadius.all(Radius.circular(4.0));
  static const medium = BorderRadius.all(Radius.circular(8.0));
  static const large = BorderRadius.all(Radius.circular(12.0));
}
