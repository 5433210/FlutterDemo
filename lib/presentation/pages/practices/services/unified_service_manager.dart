import 'package:flutter/foundation.dart';

import '../../../widgets/practice/practice_edit_controller.dart';
import '../../../widgets/practice/undo_redo_manager.dart';
import '../adapters/group_property_adapter.dart';
import '../adapters/image_property_adapter.dart';
import '../adapters/property_panel_adapter.dart';
import '../adapters/text_property_adapter.dart';
import 'enhanced_clipboard_manager.dart';
import 'enhanced_shortcut_handler.dart';
import 'enhanced_undo_redo_manager.dart';
import 'format_painter_service.dart';

/// 统一服务管理器
/// 协调格式刷、剪贴板、撤销重做、快捷键等服务之间的交互
class UnifiedServiceManager extends ChangeNotifier {
  /// 单例实例
  static final UnifiedServiceManager _instance = UnifiedServiceManager._();

  /// 获取单例实例
  static UnifiedServiceManager get instance => _instance;

  /// 格式刷服务
  late final FormatPainterService _formatPainter;

  /// 剪贴板管理器
  late final EnhancedClipboardManager _clipboardManager;

  /// 撤销重做管理器
  late final EnhancedUndoRedoManager _undoRedoManager;

  /// 快捷键处理器
  late final EnhancedShortcutHandler _shortcutHandler;

  /// 属性面板适配器注册表
  final Map<String, PropertyPanelAdapter> _adapters = {};

  /// 当前控制器引用
  PracticeEditController? _currentController;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 私有构造函数
  UnifiedServiceManager._();

  /// 是否可以重做
  bool get canRedo => _undoRedoManager.canRedo;

  /// 是否可以撤销
  bool get canUndo => _undoRedoManager.canUndo;

  /// 获取剪贴板历史
  List<ClipboardItem> get clipboardHistory => _clipboardManager.history;

  /// 格式刷的来源类型
  String? get formatBrushSourceType => _formatPainter.sourceElementType;

  /// 是否有剪贴板内容
  bool get hasClipboardContent => _clipboardManager.hasContent;

  /// 是否有可用的格式
  bool get hasFormat => _formatPainter.hasFormat;

  /// 获取所有适配器类型
  List<String> get supportedElementTypes => _adapters.keys.toList();

  /// 应用格式刷
  bool applyFormatBrush(List<Map<String, dynamic>> selectedElements) {
    if (!_formatPainter.hasFormat || selectedElements.isEmpty) return false;

    final sourceType = _formatPainter.sourceElementType;
    if (sourceType == null) return false;

    final sourceAdapter = getAdapter(sourceType);
    if (sourceAdapter == null) return false;

    final successfulApplications = <Map<String, dynamic>>[];
    final formatData = _formatPainter.copiedFormat;
    if (formatData == null) return false;

    for (final element in selectedElements) {
      final elementType = element['type'] as String?;
      if (elementType == null) continue;

      final adapter = getAdapter(elementType);
      if (adapter == null) continue;

      try {
        // 使用简化的兼容性检查
        if (_canApplyFormatSimple(formatData, element, adapter)) {
          _applyFormatSimple(formatData, element, adapter);
          successfulApplications.add(element);
        }
      } catch (e) {
        debugPrint('统一服务管理器: 应用格式失败 - $e');
      }
    }

    return successfulApplications.isNotEmpty;
  }

  // 格式刷相关操作

  /// 清除格式刷
  void clearFormatBrush() {
    _formatPainter.clearFormat();
  }

  /// 复制元素到剪贴板
  bool copyElements(List<Map<String, dynamic>> elements) {
    if (elements.isEmpty) return false;

    try {
      _clipboardManager.copyElements(elements, _adapters);
      return true;
    } catch (e) {
      debugPrint('统一服务管理器: 复制元素失败 - $e');
      return false;
    }
  }

  /// 复制格式
  bool copyFormat(List<Map<String, dynamic>> selectedElements) {
    if (selectedElements.isEmpty) return false;

    final element = selectedElements.first;
    final elementType = element['type'] as String?;
    if (elementType == null) return false;

    final adapter = getAdapter(elementType);
    if (adapter == null) {
      debugPrint('统一服务管理器: 未找到适配器 - $elementType');
      return false;
    }

    try {
      _formatPainter.copyFormat(element, adapter);
      return true;
    } catch (e) {
      debugPrint('统一服务管理器: 复制格式失败 - $e');
      return false;
    }
  }

  /// 释放资源
  @override
  void dispose() {
    _formatPainter.removeListener(() {});
    _clipboardManager.removeListener(() {});

    super.dispose();
  }

  /// 获取适配器
  PropertyPanelAdapter? getAdapter(String elementType) {
    return _adapters[elementType];
  }

  // 剪贴板相关操作

  /// 获取调试信息
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'hasController': _currentController != null,
      'registeredAdapters': _adapters.keys.toList(),
      'formatPainter': {
        'hasFormat': _formatPainter.hasFormat,
        'sourceType': _formatPainter.sourceElementType,
      },
      'clipboard': {
        'hasContent': _clipboardManager.hasContent,
        'historyCount': _clipboardManager.history.length,
      },
      'undoRedo': {
        'canUndo': _undoRedoManager.canUndo,
        'canRedo': _undoRedoManager.canRedo,
      },
    };
  }

  /// 初始化服务管理器
  void initialize() {
    if (_isInitialized) return;

    // 初始化各个服务
    _formatPainter = FormatPainterService.instance;
    _clipboardManager = EnhancedClipboardManager.instance;
    _undoRedoManager = EnhancedUndoRedoManager();
    _shortcutHandler = EnhancedShortcutHandler();

    // 注册默认适配器
    _registerDefaultAdapters();

    // 设置服务间的交互
    _setupServiceInteractions();

    _isInitialized = true;
    debugPrint('统一服务管理器: 初始化完成');
  }

  /// 从剪贴板粘贴元素
  List<Map<String, dynamic>>? pasteElements() {
    try {
      return _clipboardManager.pasteElements();
    } catch (e) {
      debugPrint('统一服务管理器: 粘贴元素失败 - $e');
      return null;
    }
  }

  /// 从历史记录粘贴
  bool pasteFromHistory(String itemId) {
    try {
      _clipboardManager.selectHistoryItem(itemId);
      return true;
    } catch (e) {
      debugPrint('统一服务管理器: 从历史粘贴失败 - $e');
      return false;
    }
  }

  // 撤销重做相关操作
  /// 记录属性变更操作
  void recordPropertyChange(
    String elementId,
    String property,
    dynamic oldValue,
    dynamic newValue,
  ) {
    if (_currentController == null) return;

    // 创建属性更新操作
    final operation = ElementPropertyOperation(
      elementId: elementId,
      oldProperties: {property: oldValue},
      newProperties: {property: newValue},
      updateElement: (id, props) {
        // 通过控制器更新元素
        if (_currentController != null) {
          _currentController!.updateElementProperties(id, props);
        }
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 执行重做
  bool redo() {
    if (_currentController == null) return false;
    try {
      _undoRedoManager.redo();
      return true;
    } catch (e) {
      debugPrint('统一服务管理器: 重做失败 - $e');
      return false;
    }
  }

  /// 注册属性面板适配器
  void registerAdapter(String elementType, PropertyPanelAdapter adapter) {
    _adapters[elementType] = adapter;
    _updateServiceAdapters();
    debugPrint('统一服务管理器: 注册适配器 - $elementType');
  }

  // 状态属性

  /// 设置当前控制器
  void setController(PracticeEditController controller) {
    _currentController = controller;
    debugPrint('统一服务管理器: 设置控制器');
  }

  /// 执行撤销
  bool undo() {
    if (_currentController == null) return false;
    try {
      _undoRedoManager.undo();
      return true;
    } catch (e) {
      debugPrint('统一服务管理器: 撤销失败 - $e');
      return false;
    }
  }

  /// 简化的格式应用
  void _applyFormatSimple(Map<String, dynamic> formatData,
      Map<String, dynamic> element, PropertyPanelAdapter adapter) {
    // 应用通用属性
    final commonProperties = ['color', 'fontSize', 'opacity', 'rotation'];
    for (final property in commonProperties) {
      if (formatData.containsKey(property)) {
        element[property] = formatData[property];
      }
    }
  }

  /// 简化的格式兼容性检查
  bool _canApplyFormatSimple(Map<String, dynamic> formatData,
      Map<String, dynamic> element, PropertyPanelAdapter adapter) {
    // 基础检查：元素类型是否匹配
    return formatData['_sourceType'] == element['type'];
  }

  /// 注册默认适配器
  void _registerDefaultAdapters() {
    registerAdapter('text', TextPropertyPanelAdapter());
    registerAdapter('image', ImagePropertyAdapter());
    registerAdapter('group', GroupPropertyAdapter());
    debugPrint('统一服务管理器: 默认适配器注册完成');
  }

  /// 设置服务间的交互
  void _setupServiceInteractions() {
    // 监听格式刷状态变化
    _formatPainter.addListener(() {
      notifyListeners();
    });

    // 监听剪贴板状态变化
    _clipboardManager.addListener(() {
      notifyListeners();
    });

    // 更新服务的适配器映射
    _updateServiceAdapters();
  }

  /// 更新服务的适配器映射
  void _updateServiceAdapters() {
    _undoRedoManager.updateAdapters(_adapters);
    _shortcutHandler.updateAdapters(_adapters);
  }
}
