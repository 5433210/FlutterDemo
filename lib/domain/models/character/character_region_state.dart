/// 字符区域颜色方案
class CharacterRegionColorScheme {
  /// 已保存的普通状态颜色
  static const normalSaved = 0xFF00C853; // 绿色

  /// 未保存的普通状态颜色
  static const normalUnsaved = 0xFFFFD700; // 黄色

  /// 选中状态颜色（增强版）
  static const selected = 0xFF2196F3; // 改为蓝色，更容易区分

  /// 调整状态颜色
  static const adjusting = 0xFF1976D2; // 深蓝色

  /// 多选选中状态的强调色
  static const multiSelected = 0xFF3F51B5; // 靛蓝色，用于多选状态

  /// 已保存的普通状态透明度
  static const normalSavedOpacity = 0.08; // 略微增加以提高可见性

  /// 未保存的普通状态透明度
  static const normalUnsavedOpacity = 0.15; // 增加可见性

  /// 选中状态透明度（增强版）
  static const selectedOpacity = 0.35; // 显著增加透明度以提高可见性

  /// 调整状态透明度
  static const adjustingOpacity = 0.3; // 略微增加

  /// 多选状态透明度
  static const multiSelectedOpacity = 0.4; // 最高透明度，确保多选状态最显眼

  /// 选中状态边框宽度
  static const selectedBorderWidth = 3.0; // 增加边框宽度

  /// 多选状态边框宽度
  static const multiSelectedBorderWidth = 3.5; // 最粗的边框

  /// 普通状态边框宽度
  static const normalBorderWidth = 1.5;

  /// 调整状态边框宽度
  static const adjustingBorderWidth = 2.5;
}

/// 表示字符区域的状态
enum CharacterRegionState {
  /// 普通状态，初始状态
  normal,

  /// 选中状态（Pan模式下）
  selected,

  /// 调整状态（Select模式下）
  adjusting
}
