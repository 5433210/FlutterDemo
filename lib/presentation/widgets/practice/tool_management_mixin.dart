import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'intelligent_notification_mixin.dart';
import 'practice_edit_state.dart';

/// 工具管理功能 Mixin
mixin ToolManagementMixin on ChangeNotifier implements IntelligentNotificationMixin {
  // 抽象接口
  PracticeEditState get state;
  void checkDisposed();

  /// 设置当前工具
  void setCurrentTool(String toolName) {
    checkDisposed();
    if (state.currentTool != toolName) {
      final oldTool = state.currentTool;
      state.currentTool = toolName;
      
      // 根据工具类型执行相应的初始化
      _initializeTool(toolName);
      
      EditPageLogger.controllerInfo('工具切换', 
        data: {'oldTool': oldTool, 'newTool': toolName});
      
      // 🚀 使用智能通知替代 notifyListeners
      intelligentNotify(
        changeType: 'tool_change',
        operation: 'setCurrentTool',
        eventData: {
          'oldTool': oldTool,
          'newTool': toolName,
          'timestamp': DateTime.now().toIso8601String(),
        },
        affectedUIComponents: ['toolbar', 'property_panel', 'canvas_overlay'],
        affectedLayers: ['interaction'], // 工具切换主要影响交互层
      );
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
    if (state.snapEnabled != enabled) {
      state.snapEnabled = enabled;
      EditPageLogger.controllerInfo('吸附功能状态变更', 
        data: {'enabled': enabled});
      
      // 🚀 使用智能通知替代 notifyListeners
      intelligentNotify(
        changeType: 'tool_snap_change',
        operation: 'setSnapEnabled',
        eventData: {
          'enabled': enabled,
          'timestamp': DateTime.now().toIso8601String(),
        },
        affectedUIComponents: ['toolbar', 'snap_indicator'],
        affectedLayers: ['interaction'], // 吸附功能影响交互层
      );
    }
  }

  /// 切换吸附功能
  void toggleSnap() {
    checkDisposed();
    final newState = !state.snapEnabled;
    state.snapEnabled = newState;
    EditPageLogger.controllerInfo('切换吸附功能', 
      data: {'enabled': newState});
    
    // 🚀 使用智能通知替代 notifyListeners
    intelligentNotify(
      changeType: 'tool_snap_toggle',
      operation: 'toggleSnap',
      eventData: {
        'enabled': newState,
        'timestamp': DateTime.now().toIso8601String(),
      },
      affectedUIComponents: ['toolbar', 'snap_indicator'],
      affectedLayers: ['interaction'], // 吸附功能影响交互层
    );
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
      final clearedCount = state.selectedElementIds.length;
      state.selectedElementIds.clear();
      state.selectedElement = null;
      
      if (clearedCount > 0) {
        EditPageLogger.controllerDebug('工具切换清除选择', 
          data: {'newTool': toolName, 'clearedCount': clearedCount});
      }
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