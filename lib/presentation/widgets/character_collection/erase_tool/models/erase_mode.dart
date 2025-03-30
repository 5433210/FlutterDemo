/// 缓存类型枚举
enum CacheType {
  /// 静态缓存（已确认的擦除结果）
  static,

  /// 动态缓存（临时预览）
  dynamic,

  /// 合成缓存（最终显示）
  composite,
}

/// 擦除工具的模式枚举
enum EraseMode {
  /// 普通擦除模式
  normal,

  /// 智能擦除模式（例如可以根据边缘检测自动调整擦除区域）
  smart,

  /// 精确擦除模式（更小的笔刷和更精确的控制）
  precise,
}

/// 图层类型枚举
enum LayerType {
  /// 原始图像层
  original,

  /// 擦除缓冲层
  buffer,

  /// 擦除预览层
  preview,

  /// UI交互层
  ui,
}
