/// 擦除模式
enum EraseMode {
  /// 普通擦除
  normal,

  /// 精确擦除
  precise,

  /// 智能擦除
  smart,

  /// 矩形擦除
  rectangle,

  /// 圆形擦除
  circle;

  /// 获取笔刷大小范围
  (double, double) get brushSizeRange {
    switch (this) {
      case EraseMode.normal:
        return (10.0, 50.0);
      case EraseMode.precise:
        return (5.0, 20.0);
      case EraseMode.smart:
        return (15.0, 60.0);
      case EraseMode.rectangle:
        return (20.0, 100.0);
      case EraseMode.circle:
        return (20.0, 100.0);
    }
  }

  /// 获取默认笔刷大小
  double get defaultBrushSize {
    switch (this) {
      case EraseMode.normal:
        return 20.0;
      case EraseMode.precise:
        return 10.0;
      case EraseMode.smart:
        return 30.0;
      case EraseMode.rectangle:
        return 40.0;
      case EraseMode.circle:
        return 40.0;
    }
  }

  /// 获取模式名称
  String get displayName {
    switch (this) {
      case EraseMode.normal:
        return '普通擦除';
      case EraseMode.precise:
        return '精确擦除';
      case EraseMode.smart:
        return '智能擦除';
      case EraseMode.rectangle:
        return '矩形擦除';
      case EraseMode.circle:
        return '圆形擦除';
    }
  }

  /// 是否支持笔压感应
  bool get supportsPressure {
    switch (this) {
      case EraseMode.normal:
      case EraseMode.precise:
        return true;
      default:
        return false;
    }
  }
}
