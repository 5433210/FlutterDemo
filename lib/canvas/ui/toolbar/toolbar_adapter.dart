/// Canvas工具栏系统 - 兼容层适配器
///
/// 职责：
/// 1. 适配新工具栏到现有系统
/// 2. 提供向后兼容的API
/// 3. 处理状态同步
/// 4. 管理工具切换逻辑
library;

import 'package:flutter/foundation.dart';

import '../../compatibility/canvas_controller_adapter.dart';
import '../../compatibility/canvas_state_adapter.dart';
import '../../core/canvas_state_manager.dart';
import 'tool_state_manager.dart';

/// 工具栏适配器 - 连接新工具栏系统与现有Canvas控制器
class ToolbarAdapter extends ChangeNotifier {
  final dynamic _stateManager;
  final ToolStateManager _toolStateManager;
  final CanvasControllerAdapter _controllerAdapter;

  /// 当前选中的工具（兼容旧API）
  String _currentTool = 'select';

  /// 工具变更监听器
  final List<Function(String)> _toolChangeListeners = [];

  ToolbarAdapter({
    required dynamic stateManager,
    required ToolStateManager toolStateManager,
    required CanvasControllerAdapter controllerAdapter,
  })  : assert(
          stateManager is CanvasStateManager ||
              stateManager is CanvasStateManagerAdapter,
          'stateManager must be a CanvasStateManager or CanvasStateManagerAdapter',
        ),
        _stateManager = stateManager,
        _toolStateManager = toolStateManager,
        _controllerAdapter = controllerAdapter {
    // 监听工具状态变更
    _toolStateManager.addListener(_onToolStateChanged);

    // 初始化工具状态
    _syncToolState();
  }

  /// 获取当前工具（兼容旧API）
  String get currentTool => _currentTool;

  /// 获取Canvas状态管理器
  dynamic get stateManager => _stateManager;

  /// 获取工具状态管理器
  ToolStateManager get toolStateManager => _toolStateManager;

  /// 添加工具变更监听器（兼容旧API）
  void addToolChangeListener(Function(String) listener) {
    _toolChangeListeners.add(listener);
  }

  @override
  void dispose() {
    _toolStateManager.removeListener(_onToolStateChanged);
    _toolChangeListeners.clear();
    super.dispose();
  }

  /// 切换到选择模式
  void enterSelectMode() {
    setTool('select');
  }

  /// 退出选择模式
  void exitSelectMode() {
    // 如果当前是选择工具，切换到平移工具
    if (_currentTool == 'select') {
      setTool('pan');
    }
  }

  /// 导出工具栏状态
  Map<String, dynamic> exportState() {
    return {
      'currentTool': _currentTool,
      'toolStateManager': _toolStateManager.exportState(),
    };
  }

  /// 获取工具配置
  T? getToolConfiguration<T extends ToolConfiguration>(ToolType toolType) {
    final config = _toolStateManager.getToolConfiguration(toolType);
    return config is T ? config : null;
  }

  /// 处理元素拖拽开始
  void handleDragElementStart(String elementType) {
    switch (elementType) {
      case 'text':
        _controllerAdapter.addTextElement();
        break;
      case 'image':
        _controllerAdapter.addEmptyImageElementAt(100.0, 100.0);
        break;
      case 'collection':
        _controllerAdapter.addEmptyCollectionElementAt(100.0, 100.0);
        break;
    }
  }

  /// 导入工具栏状态
  void importState(Map<String, dynamic> state) {
    try {
      final currentTool = state['currentTool'] as String?;
      if (currentTool != null) {
        _currentTool = currentTool;
      }

      final toolStateData = state['toolStateManager'] as Map<String, dynamic>?;
      if (toolStateData != null) {
        _toolStateManager.importState(toolStateData);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error importing toolbar state: $e');
    }
  }

  /// 获取工具是否可拖拽
  bool isToolDraggable(ToolType toolType) {
    return toolType.isCreationTool;
  }

  /// 获取工具是否启用
  bool isToolEnabled(ToolType toolType) {
    switch (toolType) {
      case ToolType.move:
      case ToolType.resize:
      case ToolType.rotate:
        // 这些工具需要有选中的元素
        return _stateManager.selectionState.selectedElementIds.isNotEmpty;
      default:
        return true;
    }
  }

  /// 移除工具变更监听器（兼容旧API）
  void removeToolChangeListener(Function(String) listener) {
    _toolChangeListeners.remove(listener);
  }

  /// 重置工具栏状态
  void resetState() {
    _toolStateManager.setTool(ToolType.select);
    _toolStateManager.resetAllConfigurations();
  }

  /// 设置工具（兼容旧API）
  void setTool(String toolName) {
    final toolType = _mapStringToToolType(toolName);
    _toolStateManager.setTool(toolType);
  }

  /// 更新工具配置
  void updateToolConfiguration<T extends ToolConfiguration>(
    ToolType toolType,
    T configuration,
  ) {
    _toolStateManager.updateToolConfiguration(toolType, configuration);
  }

  /// 将字符串工具名映射到ToolType
  ToolType _mapStringToToolType(String toolName) {
    switch (toolName) {
      case 'select':
        return ToolType.select;
      case 'text':
        return ToolType.text;
      case 'image':
        return ToolType.image;
      case 'collection':
        return ToolType.collection;
      case 'move':
        return ToolType.move;
      case 'resize':
        return ToolType.resize;
      case 'rotate':
        return ToolType.rotate;
      case 'pan':
        return ToolType.pan;
      case 'zoom':
        return ToolType.zoom;
      default:
        return ToolType.select;
    }
  }

  /// 将ToolType映射到字符串工具名
  String _mapToolTypeToString(ToolType toolType) {
    switch (toolType) {
      case ToolType.select:
        return 'select';
      case ToolType.text:
        return 'text';
      case ToolType.image:
        return 'image';
      case ToolType.collection:
        return 'collection';
      case ToolType.move:
        return 'move';
      case ToolType.resize:
        return 'resize';
      case ToolType.rotate:
        return 'rotate';
      case ToolType.pan:
        return 'pan';
      case ToolType.zoom:
        return 'zoom';
    }
  }

  /// 工具状态变更处理
  void _onToolStateChanged() {
    _syncToolState();
    notifyListeners();
  }

  /// 同步到Canvas控制器
  void _syncToController() {
    // 更新控制器的工具状态
    _controllerAdapter.state.currentTool = _currentTool;
    _controllerAdapter.notifyListeners();

    // 根据工具类型执行相应操作
    switch (_toolStateManager.currentTool) {
      case ToolType.select:
        // 进入选择模式的逻辑
        break;
      case ToolType.pan:
        // 退出选择模式
        _controllerAdapter.exitSelectMode();
        break;
      default:
        break;
    }
  }

  /// 同步工具状态
  void _syncToolState() {
    final newToolName = _mapToolTypeToString(_toolStateManager.currentTool);
    if (_currentTool != newToolName) {
      _currentTool = newToolName;

      // 通知旧API监听器
      for (final listener in _toolChangeListeners) {
        listener(_currentTool);
      }

      // 同步到Canvas控制器
      _syncToController();
    }
  }
}

/// 工具栏集成助手 - 简化工具栏系统的集成
class ToolbarIntegrationHelper {
  /// 配置默认工具设置
  static void configureDefaultTools(ToolStateManager toolStateManager) {
    // 配置文本工具默认设置
    toolStateManager.updateToolConfiguration(
      ToolType.text,
      const TextToolConfiguration(
        fontSize: 16.0,
        fontFamily: 'System',
        color: '#000000',
      ),
    );

    // 配置图像工具默认设置
    toolStateManager.updateToolConfiguration(
      ToolType.image,
      const ImageToolConfiguration(
        opacity: 1.0,
        maintainAspectRatio: true,
      ),
    );

    // 配置集字工具默认设置
    toolStateManager.updateToolConfiguration(
      ToolType.collection,
      const CollectionToolConfiguration(
        columns: 3,
        spacing: 8.0,
        sortOrder: 'newest',
      ),
    );
  }

  /// 创建完整的工具栏系统
  static ToolbarAdapter createToolbarSystem({
    required dynamic stateManager,
    required CanvasControllerAdapter controllerAdapter,
  }) {
    assert(
      stateManager is CanvasStateManager ||
          stateManager is CanvasStateManagerAdapter,
      'stateManager must be a CanvasStateManager or CanvasStateManagerAdapter',
    );

    final toolStateManager = ToolStateManager();
    return ToolbarAdapter(
      stateManager: stateManager,
      toolStateManager: toolStateManager,
      controllerAdapter: controllerAdapter,
    );
  }
}
