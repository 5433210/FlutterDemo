import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 自定义光标类，提供应用程序中使用的自定义光标
class CustomCursors {
  /// 私有构造函数，防止实例化
  CustomCursors._();

  /// 十字光标 - 用于精确选择
  static MouseCursor get crosshair {
    // 在Windows上使用cell光标，通常显示为十字形
    if (Theme.of(NavigationService.navigatorKey.currentContext!).platform == TargetPlatform.windows) {
      return SystemMouseCursors.cell;
    }
    // 在其他平台上使用precise光标
    return SystemMouseCursors.precise;
  }

  /// 抓取光标 - 用于平移操作
  static MouseCursor get grab {
    // 在Windows上使用move光标，通常显示为四向箭头
    if (Theme.of(NavigationService.navigatorKey.currentContext!).platform == TargetPlatform.windows) {
      return SystemMouseCursors.move;
    }
    // 在其他平台上使用grab光标
    return SystemMouseCursors.grab;
  }
}

/// 导航服务，用于获取全局上下文
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
