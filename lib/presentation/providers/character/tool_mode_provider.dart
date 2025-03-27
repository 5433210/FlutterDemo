import 'package:flutter_riverpod/flutter_riverpod.dart';

final toolModeProvider = StateNotifierProvider<ToolModeNotifier, Tool>((ref) {
  return ToolModeNotifier();
});

enum Tool {
  pan, // 拖拽工具
  selection, // 框选工具
  multiSelect, // 多选工具
  erase // 擦除工具
}

class ToolModeNotifier extends StateNotifier<Tool> {
  ToolModeNotifier() : super(Tool.pan);

  bool isEraseMode() => state == Tool.erase;

  bool isMultiSelectMode() => state == Tool.multiSelect;

  bool isPanMode() => state == Tool.pan;

  bool isSelectionMode() => state == Tool.selection;

  void setMode(Tool mode) {
    state = mode;
  }

  void toggleEraseMode() {
    state = state == Tool.erase ? Tool.pan : Tool.erase;
  }

  void toggleMultiSelectMode() {
    state = state == Tool.multiSelect ? Tool.pan : Tool.multiSelect;
  }

  void toggleSelectionMode() {
    state = state == Tool.selection ? Tool.pan : Tool.selection;
  }
}
