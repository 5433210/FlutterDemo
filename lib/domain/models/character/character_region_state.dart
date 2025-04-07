/// 表示字符区域的状态
enum CharacterRegionState {
  /// 普通状态，初始状态
  normal,

  /// 选中状态（Pan模式下）
  selected,

  /// 调整状态（Select模式下）
  adjusting
}

/// 字符区域颜色方案
class CharacterRegionColorScheme {
  /// 已保存的普通状态颜色
  static const normalSaved = 0xFF00C853; // 绿色

  /// 未保存的普通状态颜色
  static const normalUnsaved = 0xFF2196F3; // 蓝色

  /// 选中状态颜色
  static const selected = 0xFFFF5252; // 红色

  /// 调整状态颜色
  static const adjusting = 0xFF2196F3; // 蓝色

  /// 已保存的普通状态透明度
  static const normalSavedOpacity = 0.05;

  /// 未保存的普通状态透明度
  static const normalUnsavedOpacity = 0.1;

  /// 选中状态透明度
  static const selectedOpacity = 0.2;

  /// 调整状态透明度
  static const adjustingOpacity = 0.2;
}
