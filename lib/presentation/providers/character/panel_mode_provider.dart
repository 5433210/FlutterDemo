import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 右侧面板模式枚举
enum PanelMode {
  preview, // 字符预览模式
  grid,    // 采集结果模式
}

/// 右侧面板模式状态管理
class PanelModeNotifier extends StateNotifier<PanelMode> {
  PanelModeNotifier() : super(PanelMode.preview);

  /// 设置面板模式
  void setMode(PanelMode mode) {
    state = mode;
  }

  /// 切换面板模式
  void toggleMode() {
    state = state == PanelMode.preview ? PanelMode.grid : PanelMode.preview;
  }
}

/// 右侧面板模式provider
final panelModeProvider = StateNotifierProvider<PanelModeNotifier, PanelMode>(
  (ref) => PanelModeNotifier(),
);