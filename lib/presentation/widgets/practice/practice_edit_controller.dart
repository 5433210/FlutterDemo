import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../application/services/practice/practice_service.dart';
import '../../pages/practices/widgets/state_change_dispatcher.dart';
import 'batch_update_mixin.dart';
import 'element_management_mixin.dart';
import 'element_operations_mixin.dart';
import 'layer_management_mixin.dart';
import 'page_management_mixin.dart';
import 'practice_edit_state.dart';
import 'practice_persistence_mixin.dart';
import 'tool_management_mixin.dart';
import 'ui_state_mixin.dart';
import 'undo_operations.dart';
import 'undo_redo_manager.dart';
import 'undo_redo_mixin.dart';

/// 自定义操作
class CustomOperation implements UndoableOperation {
  final VoidCallback _executeCallback;
  final VoidCallback _undoCallback;
  @override
  final String description;

  CustomOperation({
    required VoidCallback execute,
    required VoidCallback undo,
    required this.description,
  })  : _executeCallback = execute,
        _undoCallback = undo;

  @override
  void execute() {
    _executeCallback();
  }

  @override
  void undo() {
    _undoCallback();
  }
}

/// 字帖编辑控制器
class PracticeEditController extends ChangeNotifier
    with
        ElementManagementMixin,
        ElementOperationsMixin,
        LayerManagementMixin,
        PageManagementMixin,
        UndoRedoMixin,
        ToolManagementMixin,
        PracticePersistenceMixin,
        BatchUpdateMixin,
        UIStateMixin {
  // 状态
  final PracticeEditState _state = PracticeEditState();

  // 撤销/重做管理器
  late final UndoRedoManager _undoRedoManager;

  // UUID生成器
  final Uuid _uuid = const Uuid();

  // 字帖ID和标题
  String? _practiceId;
  String? _practiceTitle;

  // 服务实例
  final PracticeService _practiceService;

  // 预览模式下的画布 GlobalKey
  GlobalKey? _canvasKey;
  // 每个页面的 GlobalKey 映射表
  final Map<String, GlobalKey> _pageKeys = {};

  // 预览模式回调函数
  Function(bool)? _previewModeCallback;

  // Reference to the edit canvas
  dynamic _editCanvas;

  /// 构造函数
  PracticeEditController(this._practiceService) {
    _undoRedoManager = UndoRedoManager(
      onStateChanged: () {
        // 更新撤销/重做状态
        _state.canUndo = _undoRedoManager.canUndo;
        _state.canRedo = _undoRedoManager.canRedo;
        notifyListeners();
      },
    );

    // 初始化默认数据
    _initDefaultData();
  }

  /// 获取画布 GlobalKey
  @override
  GlobalKey? get canvasKey => _canvasKey;

  // CanvasManagementMixin接口实现
  @override
  set canvasKey(GlobalKey? key) => _canvasKey = key;

  /// 获取画布缩放值
  double get canvasScale => _state.canvasScale;

  @override
  dynamic get editCanvas => _editCanvas;

  /// 检查字帖是否已保存过
  @override
  bool get isSaved => _practiceId != null;

  /// 获取当前字帖ID
  @override
  String? get practiceId => _practiceId;

  /// 获取字帖服务（为mixin提供）
  @override
  PracticeService get practiceService => _practiceService;

  /// 获取当前字帖标题
  @override
  String? get practiceTitle => _practiceTitle;

  @override
  Function(bool)? get previewModeCallback => _previewModeCallback;

  @override
  set previewModeCallback(Function(bool)? callback) =>
      _previewModeCallback = callback;

  /// 获取当前状态
  @override
  PracticeEditState get state => _state;

  /// 获取撤销/重做管理器
  @override
  UndoRedoManager get undoRedoManager => _undoRedoManager;

  /// 获取UUID生成器（为mixin提供）
  @override
  Uuid get uuid => _uuid;

  /// 设置画布引用（供画布组件注册自己）
  void setEditCanvas(dynamic canvas) {
    _editCanvas = canvas;
    debugPrint('🔧 画布已注册到控制器：${canvas.runtimeType}');
  }

  /// 检查是否已销毁（为mixin提供）
  @override
  void checkDisposed() {
    _checkDisposed();
  }

  // deleteAllLayers method removed - now using LayerManagementMixin

  /// 释放资源
  @override
  void dispose() {
    // 清理批量更新相关资源
    disposeBatchUpdate();

    // 清除所有引用
    _canvasKey = null;
    _pageKeys.clear();
    _previewModeCallback = null;

    // 标记为已销毁
    _state.isDisposed = true;

    super.dispose();
  }

  /// 标记为未保存（为mixin提供）
  @override
  void markUnsaved() {
    _state.markUnsaved();
  }

  @override
  void notifyListeners() {
    if (_state.isDisposed) {
      debugPrint('警告: 尝试在控制器销毁后调用 notifyListeners()');
      return;
    }

    super.notifyListeners();
  }

  /// 检查控制器是否已销毁，如果已销毁则抛出异常
  void _checkDisposed() {
    if (_state.isDisposed) {
      throw StateError(
          'A PracticeEditController was used after being disposed.');
    }
  }

  /// 触发网格设置变化事件
  void triggerGridSettingsChange() {
    debugPrint('🎨 triggerGridSettingsChange() 被调用');
    debugPrint('🎨 stateDispatcher是否存在: ${stateDispatcher != null}');
    
    // 如果有状态分发器，触发网格设置变化事件
    if (stateDispatcher != null) {
      debugPrint('🎨 使用StateDispatcher分发网格设置变化事件');
      stateDispatcher!.dispatch(StateChangeEvent(
        type: StateChangeType.gridSettingsChange, 
        data: {
          'gridVisible': _state.gridVisible,
          'gridSize': _state.gridSize,
          'snapEnabled': _state.snapEnabled,
        },
      ));
      debugPrint('🎨 StateDispatcher事件分发完成');
    } else {
      // 回退到直接通知监听器
      debugPrint('🎨 StateDispatcher不存在，使用notifyListeners()');
      notifyListeners();
    }
    debugPrint('🎨 triggerGridSettingsChange() 执行完毕');
  }

  /// 初始化默认数据
  void _initDefaultData() {
    // 创建默认图层
    final defaultLayer = {
      'id': _uuid.v4(),
      'name': '图层1',
      'order': 0,
      'isVisible': true,
      'isLocked': false,
      'opacity': 1.0,
    };

    // 🧪 为了测试组合元素功能，创建一些测试元素
    final testTextElement1 = {
      'id': 'text_${_uuid.v4()}',
      'type': 'text',
      'x': 10.0,
      'y': 10.0,
      'width': 80.0,
      'height': 30.0,
      'rotation': 0.0,
      'layerId': defaultLayer['id'],
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'content': {
        'text': '测试文本1',
        'fontSize': 16.0,
        'fontColor': '#000000',
        'backgroundColor': '#FFEB3B',
        'textAlign': 'center',
      },
    };

    final testTextElement2 = {
      'id': 'text_${_uuid.v4()}',
      'type': 'text',
      'x': 20.0,
      'y': 50.0,
      'width': 60.0,
      'height': 40.0,
      'rotation': 15.0,
      'layerId': defaultLayer['id'],
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'content': {
        'text': '测试文本2',
        'fontSize': 14.0,
        'fontColor': '#FFFFFF',
        'backgroundColor': '#FF5722',
        'textAlign': 'center',
      },
    };

    // 🧪 创建测试组合元素
    final testGroupElement = {
      'id': 'group_${_uuid.v4()}',
      'type': 'group',
      'x': 50.0,
      'y': 50.0,
      'width': 100.0,
      'height': 100.0,
      'rotation': 0.0,
      'layerId': defaultLayer['id'],
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'name': '测试组合元素',
      'content': {
        'children': [
          testTextElement1,
          testTextElement2,
        ],
      },
    };

    // 创建默认页面
    final defaultPage = {
      'id': _uuid.v4(),
      'name': '页面1',
      'index': 0,
      'width': 210.0, // A4纸宽度（毫米）
      'height': 297.0, // A4纸高度（毫米）
      'orientation': 'portrait', // 默认纵向
      'dpi': 300, // 默认DPI
      'background': {
        'type': 'color',
        'value': '#FFFFFF',
        'opacity': 1.0,
      },
      'elements': <Map<String, dynamic>>[
        testGroupElement, // 🧪 添加测试组合元素
      ],
      'layers': <Map<String, dynamic>>[defaultLayer], // 每个页面都有自己的图层
    };

    // 添加到状态中
    _state.pages.add(defaultPage);
    _state.currentPageIndex = 0;

    // 设置默认选中的图层
    _state.selectedLayerId = defaultLayer['id'] as String;

    debugPrint('🧪 已创建测试组合元素用于验证缩放和旋转功能');
    debugPrint('🧪 组合元素位置: (50, 50), 尺寸: 100x100');
    debugPrint('🧪 包含两个带背景色的文本子元素');

    // 通知监听器
    notifyListeners();
  }
}
