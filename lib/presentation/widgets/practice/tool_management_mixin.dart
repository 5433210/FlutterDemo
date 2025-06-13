import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'guideline_alignment/guideline_manager.dart';
import 'guideline_alignment/guideline_types.dart';
import 'intelligent_notification_mixin.dart';
import 'practice_edit_state.dart';

/// 工具管理功能 Mixin
mixin ToolManagementMixin on ChangeNotifier
    implements IntelligentNotificationMixin {
  // 抽象接口
  PracticeEditState get state;
  @override
  void checkDisposed();

  /// 清除活动参考线
  void clearActiveGuidelines() {
    checkDisposed();
    if (state.activeGuidelines.isNotEmpty) {
      state.activeGuidelines.clear();
      state.isGuidelinePreviewActive = false;

      EditPageLogger.controllerDebug('清除活动参考线');

      intelligentNotify(
        changeType: 'guideline_clear',
        operation: 'clearActiveGuidelines',
        eventData: {
          'timestamp': DateTime.now().toIso8601String(),
        },
        affectedUIComponents: ['canvas'],
        affectedLayers: ['guideline'],
      );
    }
  }

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

  /// 获取当前工具
  String getCurrentTool() => state.currentTool;

  /// 初始化参考线管理器
  void initializeGuidelineManager() {
    checkDisposed();

    // 如果当前页面存在，初始化GuidelineManager
    if (state.currentPageIndex >= 0 && state.pages.isNotEmpty) {
      final currentPage = state.pages[state.currentPageIndex];
      final elements = <Map<String, dynamic>>[];

      // 收集当前页面的所有元素
      final layers = currentPage['layers'] as List<dynamic>? ?? [];
      for (final layer in layers) {
        final layerMap = layer as Map<String, dynamic>;
        final layerElements = layerMap['elements'] as List<dynamic>? ?? [];
        for (final element in layerElements) {
          final elementMap = element as Map<String, dynamic>;
          elements.add({
            'id': elementMap['id'],
            'x': elementMap['x'],
            'y': elementMap['y'],
            'width': elementMap['width'],
            'height': elementMap['height'],
            'layerId': layerMap['id'],
            'isHidden': layerMap['isHidden'] ?? false,
          });
        }
      }

      final pageWidth = (currentPage['width'] as num?)?.toDouble() ?? 800.0;
      final pageHeight = (currentPage['height'] as num?)?.toDouble() ?? 600.0;

      // 初始化GuidelineManager
      GuidelineManager.instance.initialize(
        elements: elements,
        pageSize: Size(pageWidth, pageHeight),
        enabled: state.alignmentMode == AlignmentMode.guideline,
        snapThreshold: 5.0, // 使用默认阈值
      );

      // 设置参考线输出列表同步
      GuidelineManager.instance
          .setActiveGuidelinesOutput(state.activeGuidelines);

      EditPageLogger.controllerDebug('参考线管理器初始化完成', data: {
        'elementsCount': elements.length,
        'pageSize': '${pageWidth}x$pageHeight',
        'enabled': state.alignmentMode == AlignmentMode.guideline,
      });

      // 🔧 立即更新参考线管理器元素数据，确保元素同步
      updateGuidelineManagerElements();
    }
  }

  /// 检查是否为集字工具
  bool isCollectionTool() => state.currentTool == 'collection';

  /// 检查是否为图片工具
  bool isImageTool() => state.currentTool == 'image';

  /// 检查是否为选择工具
  bool isSelectTool() => state.currentTool == 'select';

  /// 检查吸附功能是否启用
  bool isSnapEnabled() => state.snapEnabled;

  /// 检查是否为文本工具
  bool isTextTool() => state.currentTool == 'text';

  /// 设置对齐模式
  void setAlignmentMode(AlignmentMode mode) {
    checkDisposed();
    if (state.alignmentMode != mode) {
      final oldMode = state.alignmentMode;
      state.alignmentMode = mode;

      // 清理之前模式的状态
      if (mode != AlignmentMode.guideline) {
        state.activeGuidelines.clear();
        state.isGuidelinePreviewActive = false;
      }

      // 更新兼容性标志
      state.snapEnabled = mode == AlignmentMode.gridSnap;

      // 如果切换到参考线模式，初始化GuidelineManager
      if (mode == AlignmentMode.guideline) {
        initializeGuidelineManager();
      }

      EditPageLogger.controllerInfo('对齐模式变更',
          data: {'oldMode': oldMode.name, 'newMode': mode.name});

      intelligentNotify(
        changeType: 'alignment_mode_change',
        operation: 'setAlignmentMode',
        eventData: {
          'oldMode': oldMode.name,
          'newMode': mode.name,
          'timestamp': DateTime.now().toIso8601String(),
        },
        affectedUIComponents: ['toolbar', 'canvas'],
        affectedLayers: ['interaction', 'guideline'],
      );
    }
  }

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

  /// 设置吸附功能状态
  void setSnapEnabled(bool enabled) {
    checkDisposed();
    if (state.snapEnabled != enabled) {
      state.snapEnabled = enabled;
      EditPageLogger.controllerInfo('吸附功能状态变更', data: {'enabled': enabled});

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

  /// 切换对齐模式
  void toggleAlignmentMode() {
    checkDisposed();
    final nextMode = switch (state.alignmentMode) {
      AlignmentMode.none => AlignmentMode.gridSnap,
      AlignmentMode.gridSnap => AlignmentMode.guideline,
      AlignmentMode.guideline => AlignmentMode.none,
    };
    setAlignmentMode(nextMode);
  }

  /// 切换吸附功能
  void toggleSnap() {
    checkDisposed();
    final newState = !state.snapEnabled;
    state.snapEnabled = newState;
    EditPageLogger.controllerInfo('切换吸附功能', data: {'enabled': newState});

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

  /// 更新活动参考线
  void updateActiveGuidelines(List<Guideline> guidelines) {
    checkDisposed();
    // 🔧 创建可修改的副本以避免"不可修改列表"错误
    state.activeGuidelines = List<Guideline>.from(guidelines);
    state.isGuidelinePreviewActive = guidelines.isNotEmpty;

    EditPageLogger.controllerDebug('更新活动参考线', data: {
      'count': guidelines.length,
      'types': guidelines.map((g) => g.type.name).toList(),
    });

    intelligentNotify(
      changeType: 'guideline_update',
      operation: 'updateActiveGuidelines',
      eventData: {
        'count': guidelines.length,
        'timestamp': DateTime.now().toIso8601String(),
      },
      affectedUIComponents: ['canvas'],
      affectedLayers: ['guideline'],
    );
  }

  /// 更新参考线管理器的元素数据
  void updateGuidelineManagerElements() {
    if (state.alignmentMode != AlignmentMode.guideline) {
      return;
    }

    checkDisposed();

    // 如果当前页面存在，更新GuidelineManager的元素数据
    if (state.currentPageIndex >= 0 && state.pages.isNotEmpty) {
      final currentPage = state.pages[state.currentPageIndex];
      final elements = <Map<String, dynamic>>[];

      // 收集当前页面的所有元素
      final layers = currentPage['layers'] as List<dynamic>? ?? [];
      for (final layer in layers) {
        final layerMap = layer as Map<String, dynamic>;
        final layerElements = layerMap['elements'] as List<dynamic>? ?? [];
        for (final element in layerElements) {
          final elementMap = element as Map<String, dynamic>;
          elements.add({
            'id': elementMap['id'],
            'x': elementMap['x'],
            'y': elementMap['y'],
            'width': elementMap['width'],
            'height': elementMap['height'],
            'layerId': layerMap['id'],
            'isHidden': layerMap['isHidden'] ?? false,
          });
        }
      }

      // 更新GuidelineManager的元素数据
      GuidelineManager.instance.updateElements(elements);

      EditPageLogger.controllerDebug('参考线管理器元素数据更新',
          data: {'elementsCount': elements.length});
    }
  }

  /// 初始化工具的默认选项
  void _initializeDefaultToolOptions(String toolName) {
    // 工具选项的初始化逻辑可以在具体实现中添加
    // 目前只是占位方法
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
}
