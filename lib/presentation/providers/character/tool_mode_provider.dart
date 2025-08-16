import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';
import 'character_collection_provider.dart';

/// 工具模式Provider
final toolModeProvider = StateNotifierProvider<ToolModeNotifier, Tool>((ref) {
  return ToolModeNotifier(ref);
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

  String tooltip(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case Tool.pan:
        return l10n.toolModePanTooltip;
      case Tool.select:
        return l10n.toolModeSelectTooltip;
    }
  }
}

/// 工具模式状态管理器
class ToolModeNotifier extends StateNotifier<Tool> {
  final Ref _ref;
  Tool _previousMode = Tool.pan;

  ToolModeNotifier(this._ref) : super(Tool.pan);

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
      
      // 工具切换时清除选区状态
      try {
        final characterCollectionNotifier = _ref.read(characterCollectionProvider.notifier);
        
        // 多选切换到采集时，清除已选中的选区
        if (oldMode == Tool.pan && mode == Tool.select) {
          AppLogger.debug('多选切换到采集，清除已选中选区');
          characterCollectionNotifier.clearSelectedRegions();
        }
        // 采集切换到多选时，清除选中或adjusting的选区
        else if (oldMode == Tool.select && mode == Tool.pan) {
          AppLogger.debug('采集切换到多选，清除所有选区状态');
          characterCollectionNotifier.clearSelections();
        }
      } catch (e) {
        AppLogger.error('清除选区状态失败', error: e);
      }
      
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
