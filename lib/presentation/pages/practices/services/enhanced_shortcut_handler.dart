import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../adapters/property_panel_adapter.dart';
import '../services/enhanced_clipboard_manager.dart';
import '../services/enhanced_undo_redo_manager.dart';
import '../services/format_painter_service.dart';

/// 增强的快捷键处理器
class EnhancedShortcutHandler extends ChangeNotifier {
  /// 撤销重做管理器
  final EnhancedUndoRedoManager? _undoRedoManager;

  /// 快捷键配置映射
  Map<ShortcutActionType, ShortcutConfig> _configs =
      Map.from(ShortcutConfig.defaultConfigs);

  /// 动作处理器映射
  final Map<ShortcutActionType, VoidCallback> _actionHandlers = {};

  /// 适配器映射
  Map<String, PropertyPanelAdapter> _adapters = {};

  /// 上下文相关的回调
  List<Map<String, dynamic>> Function()? _getSelectedElements;
  Function(List<String>)? _selectElements;
  Function(Map<String, dynamic>)? _addElement;
  Function(String)? _removeElement;
  Function(String, Map<String, dynamic>)? _updateElement;

  /// 构造函数
  EnhancedShortcutHandler({
    EnhancedUndoRedoManager? undoRedoManager,
  }) : _undoRedoManager = undoRedoManager;

  /// 获取所有可用动作
  List<ShortcutActionType> get availableActions => ShortcutActionType.values;

  /// 获取快捷键配置
  Map<ShortcutActionType, ShortcutConfig> get configs =>
      Map.unmodifiable(_configs);

  /// 导出配置
  Map<String, dynamic> exportConfig() {
    return _configs.map((action, config) => MapEntry(
          action.name,
          {
            'keySet': config.keySet.keys.map((k) => k.keyId).toList(),
            'description': config.description,
            'enabled': config.enabled,
          },
        ));
  }

  /// 检查快捷键冲突
  List<ShortcutActionType> getConflictingActions(LogicalKeySet keySet) {
    return _configs.entries
        .where((entry) => entry.value.keySet == keySet)
        .map((entry) => entry.key)
        .toList();
  }

  /// 获取动作的快捷键字符串
  String? getShortcutString(ShortcutActionType action) {
    final config = _configs[action];
    if (config == null) return null;

    return _formatKeySet(config.keySet);
  }

  /// 处理快捷键事件
  bool handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    for (final config in _configs.values) {
      if (!config.enabled) continue;

      if (config.keySet.accepts(event, HardwareKeyboard.instance)) {
        return _executeAction(config.action);
      }
    }

    return false;
  }

  /// 导入配置
  void importConfig(Map<String, dynamic> configData) {
    try {
      final newConfigs = <ShortcutActionType, ShortcutConfig>{};

      for (final entry in configData.entries) {
        final actionName = entry.key;
        final configMap = entry.value as Map<String, dynamic>;

        final action = ShortcutActionType.values.firstWhere(
          (a) => a.name == actionName,
          orElse: () => throw Exception('未知动作: $actionName'),
        );
        final keyIds = (configMap['keySet'] as List).cast<int>();
        final keys = keyIds
            .map((id) => LogicalKeyboardKey.findKeyByKeyId(id))
            .where((key) => key != null)
            .cast<LogicalKeyboardKey>()
            .toSet();

        newConfigs[action] = ShortcutConfig(
          keySet: LogicalKeySet.fromSet(keys),
          action: action,
          description: configMap['description'] as String,
          enabled: configMap['enabled'] as bool? ?? true,
        );
      }

      _configs = newConfigs;
      notifyListeners();
    } catch (e) {
      debugPrint('快捷键处理器: 导入配置失败 - $e');
    }
  }

  /// 注册动作处理器
  void registerActionHandler(ShortcutActionType action, VoidCallback handler) {
    _actionHandlers[action] = handler;
  }

  /// 批量注册动作处理器
  void registerActionHandlers(Map<ShortcutActionType, VoidCallback> handlers) {
    _actionHandlers.addAll(handlers);
  }

  /// 重置为默认配置
  void resetToDefaults() {
    _configs = Map.from(ShortcutConfig.defaultConfigs);
    notifyListeners();
  }

  /// 设置上下文回调
  void setContextCallbacks({
    List<Map<String, dynamic>> Function()? getSelectedElements,
    Function(List<String>)? selectElements,
    Function(Map<String, dynamic>)? addElement,
    Function(String)? removeElement,
    Function(String, Map<String, dynamic>)? updateElement,
  }) {
    _getSelectedElements = getSelectedElements;
    _selectElements = selectElements;
    _addElement = addElement;
    _removeElement = removeElement;
    _updateElement = updateElement;
  }

  /// 更新适配器映射
  void updateAdapters(Map<String, PropertyPanelAdapter> adapters) {
    _adapters = Map.from(adapters);
  }

  /// 更新快捷键配置
  void updateConfig(ShortcutActionType action, ShortcutConfig config) {
    _configs[action] = config;
    notifyListeners();
  }

  /// 执行动作
  bool _executeAction(ShortcutActionType action) {
    try {
      // 优先使用注册的处理器
      if (_actionHandlers.containsKey(action)) {
        _actionHandlers[action]!();
        return true;
      }

      // 使用内置处理器
      return _executeBuiltinAction(action);
    } catch (e) {
      debugPrint('快捷键处理器: 执行动作 $action 失败 - $e');
      return false;
    }
  }

  /// 执行内置动作
  bool _executeBuiltinAction(ShortcutActionType action) {
    switch (action) {
      case ShortcutActionType.undo:
        _undoRedoManager?.undo();
        return true;

      case ShortcutActionType.redo:
        _undoRedoManager?.redo();
        return true;

      case ShortcutActionType.copy:
        return _handleCopy();

      case ShortcutActionType.paste:
        return _handlePaste();

      case ShortcutActionType.delete:
        return _handleDelete();

      case ShortcutActionType.selectAll:
        return _handleSelectAll();

      case ShortcutActionType.copyFormat:
        return _handleCopyFormat();

      case ShortcutActionType.applyFormat:
        return _handleApplyFormat();

      default:
        debugPrint('快捷键处理器: 未实现的内置动作 $action');
        return false;
    }
  }

  /// 格式化按键集合为字符串
  String _formatKeySet(LogicalKeySet keySet) {
    final keys = <String>[];

    if (keySet.keys.contains(LogicalKeyboardKey.control)) {
      keys.add('Ctrl');
    }
    if (keySet.keys.contains(LogicalKeyboardKey.shift)) {
      keys.add('Shift');
    }
    if (keySet.keys.contains(LogicalKeyboardKey.alt)) {
      keys.add('Alt');
    }
    if (keySet.keys.contains(LogicalKeyboardKey.meta)) {
      keys.add('Cmd');
    }

    // 添加主要按键
    final mainKey = keySet.keys.firstWhere(
      (key) =>
          key != LogicalKeyboardKey.control &&
          key != LogicalKeyboardKey.shift &&
          key != LogicalKeyboardKey.alt &&
          key != LogicalKeyboardKey.meta,
      orElse: () => LogicalKeyboardKey.space,
    );

    keys.add(_getKeyLabel(mainKey));

    return keys.join('+');
  }

  /// 获取按键标签
  String _getKeyLabel(LogicalKeyboardKey key) {
    // 字母键
    if (key.keyId >= LogicalKeyboardKey.keyA.keyId &&
        key.keyId <= LogicalKeyboardKey.keyZ.keyId) {
      return String.fromCharCode(
          key.keyId - LogicalKeyboardKey.keyA.keyId + 65);
    }

    // 数字键
    if (key.keyId >= LogicalKeyboardKey.digit0.keyId &&
        key.keyId <= LogicalKeyboardKey.digit9.keyId) {
      return (key.keyId - LogicalKeyboardKey.digit0.keyId).toString();
    }

    // 特殊键
    switch (key) {
      case LogicalKeyboardKey.space:
        return 'Space';
      case LogicalKeyboardKey.enter:
        return 'Enter';
      case LogicalKeyboardKey.escape:
        return 'Esc';
      case LogicalKeyboardKey.delete:
        return 'Del';
      case LogicalKeyboardKey.backspace:
        return 'Backspace';
      case LogicalKeyboardKey.tab:
        return 'Tab';
      case LogicalKeyboardKey.equal:
        return '=';
      case LogicalKeyboardKey.minus:
        return '-';
      default:
        return key.keyLabel;
    }
  }

  /// 处理应用格式操作
  bool _handleApplyFormat() {
    if (!FormatPainterService.instance.hasFormat) {
      debugPrint('快捷键处理器: 没有可应用的格式');
      return false;
    }

    final selectedElements = _getSelectedElements?.call() ?? [];
    if (selectedElements.isEmpty) {
      debugPrint('快捷键处理器: 没有选中的元素来应用格式');
      return false;
    }

    final modifiedElements = FormatPainterService.instance.applyFormat(
      selectedElements,
      _adapters,
    );

    // 更新元素
    for (final element in modifiedElements) {
      final elementId = element['id'] as String?;
      if (elementId != null) {
        _updateElement?.call(elementId, element);
      }
    }

    return true;
  }

  /// 处理复制操作
  bool _handleCopy() {
    final selectedElements = _getSelectedElements?.call() ?? [];
    if (selectedElements.isEmpty) return false;

    EnhancedClipboardManager.instance.copyElements(selectedElements, _adapters);
    return true;
  }

  /// 处理复制格式操作
  bool _handleCopyFormat() {
    final selectedElements = _getSelectedElements?.call() ?? [];
    if (selectedElements.length != 1) {
      debugPrint('快捷键处理器: 复制格式需要选中一个元素');
      return false;
    }

    final element = selectedElements.first;
    final elementType = element['type'] as String?;
    if (elementType == null) return false;

    final adapter = _adapters[elementType];
    if (adapter == null) {
      debugPrint('快捷键处理器: 未找到类型 $elementType 的适配器');
      return false;
    }

    FormatPainterService.instance.copyFormat(element, adapter);
    return true;
  }

  /// 处理删除操作
  bool _handleDelete() {
    final selectedElements = _getSelectedElements?.call() ?? [];
    if (selectedElements.isEmpty) return false;

    for (final element in selectedElements) {
      final elementId = element['id'] as String?;
      if (elementId != null) {
        _removeElement?.call(elementId);
      }
    }
    return true;
  }

  /// 处理粘贴操作
  bool _handlePaste() {
    final pastedElements = EnhancedClipboardManager.instance.pasteElements();
    if (pastedElements == null || pastedElements.isEmpty) return false;

    for (final element in pastedElements) {
      _addElement?.call(element);
    }
    return true;
  }

  /// 处理全选操作
  bool _handleSelectAll() {
    // 这里需要根据实际情况实现全选逻辑
    debugPrint('快捷键处理器: 执行全选操作');
    return true;
  }
}

/// 快捷键动作类型
enum ShortcutActionType {
  // 文件操作
  save,
  saveAs,
  export,

  // 编辑操作
  undo,
  redo,
  cut,
  copy,
  paste,
  delete,
  selectAll,

  // 格式操作
  copyFormat,
  applyFormat,

  // 对象操作
  group,
  ungroup,
  bringToFront,
  sendToBack,
  moveUp,
  moveDown,

  // 视图操作
  zoomIn,
  zoomOut,
  zoomToFit,
  resetView,
  toggleGrid,
  toggleSnap,

  // 面板操作
  toggleLeftPanel,
  toggleRightPanel,
  togglePropertyPanel,

  // 工具操作
  selectTool,
  textTool,
  imageTool,
  shapeTool,
}

/// 快捷键配置
class ShortcutConfig {
  /// 默认快捷键配置
  static final Map<ShortcutActionType, ShortcutConfig> defaultConfigs = {
    // 文件操作
    ShortcutActionType.save: ShortcutConfig(
      keySet:
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS),
      action: ShortcutActionType.save,
      description: '保存',
    ),
    ShortcutActionType.saveAs: ShortcutConfig(
      keySet: LogicalKeySet(LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift, LogicalKeyboardKey.keyS),
      action: ShortcutActionType.saveAs,
      description: '另存为',
    ),
    ShortcutActionType.export: ShortcutConfig(
      keySet:
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyE),
      action: ShortcutActionType.export,
      description: '导出',
    ),

    // 编辑操作
    ShortcutActionType.undo: ShortcutConfig(
      keySet:
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ),
      action: ShortcutActionType.undo,
      description: '撤销',
    ),
    ShortcutActionType.redo: ShortcutConfig(
      keySet:
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY),
      action: ShortcutActionType.redo,
      description: '重做',
    ),
    ShortcutActionType.cut: ShortcutConfig(
      keySet:
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyX),
      action: ShortcutActionType.cut,
      description: '剪切',
    ),
    ShortcutActionType.copy: ShortcutConfig(
      keySet:
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC),
      action: ShortcutActionType.copy,
      description: '复制',
    ),
    ShortcutActionType.paste: ShortcutConfig(
      keySet:
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV),
      action: ShortcutActionType.paste,
      description: '粘贴',
    ),
    ShortcutActionType.delete: ShortcutConfig(
      keySet: LogicalKeySet(LogicalKeyboardKey.delete),
      action: ShortcutActionType.delete,
      description: '删除',
    ),
    ShortcutActionType.selectAll: ShortcutConfig(
      keySet:
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA),
      action: ShortcutActionType.selectAll,
      description: '全选',
    ),

    // 格式操作
    ShortcutActionType.copyFormat: ShortcutConfig(
      keySet: LogicalKeySet(LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift, LogicalKeyboardKey.keyC),
      action: ShortcutActionType.copyFormat,
      description: '复制格式',
    ),
    ShortcutActionType.applyFormat: ShortcutConfig(
      keySet: LogicalKeySet(LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift, LogicalKeyboardKey.keyV),
      action: ShortcutActionType.applyFormat,
      description: '应用格式',
    ),

    // 对象操作
    ShortcutActionType.group: ShortcutConfig(
      keySet:
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyG),
      action: ShortcutActionType.group,
      description: '组合',
    ),
    ShortcutActionType.ungroup: ShortcutConfig(
      keySet: LogicalKeySet(LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift, LogicalKeyboardKey.keyG),
      action: ShortcutActionType.ungroup,
      description: '取消组合',
    ),

    // 视图操作
    ShortcutActionType.zoomIn: ShortcutConfig(
      keySet:
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.equal),
      action: ShortcutActionType.zoomIn,
      description: '放大',
    ),
    ShortcutActionType.zoomOut: ShortcutConfig(
      keySet:
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.minus),
      action: ShortcutActionType.zoomOut,
      description: '缩小',
    ),
    ShortcutActionType.zoomToFit: ShortcutConfig(
      keySet:
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit0),
      action: ShortcutActionType.zoomToFit,
      description: '适应窗口',
    ),
  };
  final LogicalKeySet keySet;
  final ShortcutActionType action;
  final String description;

  final bool enabled;

  const ShortcutConfig({
    required this.keySet,
    required this.action,
    required this.description,
    this.enabled = true,
  });
}
