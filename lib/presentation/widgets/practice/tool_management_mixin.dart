import 'package:flutter/material.dart';

import 'practice_edit_state.dart';

/// 工具管理功能 Mixin
mixin ToolManagementMixin on ChangeNotifier {
  // 抽象接口
  PracticeEditState get state;
  void checkDisposed();

  /// 设置当前工具
  void setCurrentTool(String toolName) {
    checkDisposed();
    if (state.currentTool != toolName) {
      state.currentTool = toolName;
      
      // 根据工具类型执行相应的初始化
      _initializeTool(toolName);
      
      notifyListeners();
    }
  }

  /// 获取当前工具
  String getCurrentTool() => state.currentTool;

  /// 检查是否为选择工具
  bool isSelectTool() => state.currentTool == 'select';

  /// 检查是否为文本工具
  bool isTextTool() => state.currentTool == 'text';

  /// 检查是否为图片工具
  bool isImageTool() => state.currentTool == 'image';

  /// 检查是否为集字工具
  bool isCollectionTool() => state.currentTool == 'collection';

  /// 设置吸附功能状态
  void setSnapEnabled(bool enabled) {
    checkDisposed();
    state.snapEnabled = enabled;
    notifyListeners();
  }

  /// 切换吸附功能
  void toggleSnap() {
    checkDisposed();
    state.snapEnabled = !state.snapEnabled;
    notifyListeners();
  }

  /// 检查吸附功能是否启用
  bool isSnapEnabled() => state.snapEnabled;

  /// 获取所有可用工具列表
  List<String> getAvailableTools() {
    return [
      'select',
      'text',
      'image',
      'collection',
      'pen',
      'eraser',
      'shape',
    ];
  }

  /// 初始化工具
  void _initializeTool(String toolName) {
    // 清除当前选择（如果切换到非选择工具）
    if (toolName != 'select') {
      state.selectedElementIds.clear();
      state.selectedElement = null;
    }

    // 初始化工具特定的状态
    switch (toolName) {
      case 'text':
        _initializeDefaultToolOptions('text');
        break;
      case 'image':
        _initializeDefaultToolOptions('image');
        break;
      case 'collection':
        _initializeDefaultToolOptions('collection');
        break;
      case 'select':
      default:
        // 选择工具的初始化逻辑
        break;
    }
  }

  /// 初始化工具的默认选项
  void _initializeDefaultToolOptions(String toolName) {
    // 工具选项的初始化逻辑可以在具体实现中添加
    // 目前只是占位方法
  }
} 