import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/logging/logger.dart';

/// 工具模式Provider
final toolModeProvider = StateNotifierProvider<ToolModeNotifier, Tool>((ref) {
  return ToolModeNotifier();
});

/// 工具模式枚举
enum Tool {
  /// 平移和缩放模式（默认）
  pan,

  /// 框选工具模式
  select;

  IconData get icon {
    switch (this) {
      case Tool.pan:
        return Icons.pan_tool;
      case Tool.select:
        return Icons.crop_square;
    }
  }

  String get tooltip {
    switch (this) {
      case Tool.pan:
        return '拖拽工具 (Ctrl+V)';
      case Tool.select:
        return '框选工具 (Ctrl+B)';
    }
  }
}

/// 工具模式状态管理器
class ToolModeNotifier extends StateNotifier<Tool> {
  Tool _previousMode = Tool.pan;

  ToolModeNotifier() : super(Tool.pan);

  /// 获取当前模式
  Tool get currentMode => state;

  /// 获取前一个模式
  Tool get previousMode => _previousMode;

  /// 切换到平移模式
  void panMode() {
    _previousMode = state;
    state = Tool.pan;
  }

  /// 切换到选择模式
  void selectMode() {
    _previousMode = state;
    state = Tool.select;
  }

  /// 设置工具模式
  void setMode(Tool mode) {
    if (state != mode) {
      final oldMode = state;
      _previousMode = oldMode;
      state = mode;

      // 记录工具模式变化
      AppLogger.debug('工具模式变更', data: {
        'from': _previousMode.toString(),
        'to': state.toString(),
      });
    }
  }

  /// 切换回前一个模式
  void toggleMode() {
    final currentState = state;
    state = _previousMode;
    _previousMode = currentState;
  }
}
