import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../application/services/practice/practice_service.dart';
import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../../pages/practices/widgets/state_change_dispatcher.dart';
import 'batch_update_mixin.dart';
import 'element_management_mixin.dart';
import 'element_operations_mixin.dart';
import 'guideline_alignment/guideline_manager.dart';
import 'guideline_alignment/guideline_types.dart';
import 'intelligent_notification_mixin.dart';
import 'intelligent_state_dispatcher.dart';
import 'layer_management_mixin.dart';
import 'page_management_mixin.dart';
import 'practice_edit_state.dart';
import 'practice_persistence_mixin.dart';
import 'throttled_notification_mixin.dart';
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
        // 不含dispose的mixin放前面
        ElementManagementMixin,
        ElementOperationsMixin,
        LayerManagementMixin,
        PageManagementMixin,
        ToolManagementMixin,
        PracticePersistenceMixin,
        UndoRedoMixin,
        UIStateMixin,
        // 包含dispose的mixin放后面，确保super.dispose()调用链正确
        BatchUpdateMixin,
        IntelligentNotificationMixin,
        DragOptimizedNotificationMixin,
        ThrottledNotificationMixin {
  // 状态
  final PracticeEditState _state = PracticeEditState();

  // 撤销/重做管理器
  late final UndoRedoManager _undoRedoManager;

  // UUID生成器
  final Uuid _uuid = const Uuid();

  // 字帖ID和标题 - 为 PracticePersistenceMixin 提供实现
  String? _practiceId;
  String? _practiceTitle;
  // 服务实例
  final PracticeService _practiceService;

  // 本地化实例
  AppLocalizations? _l10n;

  /// 获取本地化实例（为ElementManagementMixin提供）
  @override
  AppLocalizations get l10n => _l10n!;

  // 预览模式下的画布 GlobalKey
  GlobalKey? _canvasKey;
  // 每个页面的 GlobalKey 映射表
  final Map<String, GlobalKey> _pageKeys = {};

  // 预览模式回调函数
  Function(bool)? _previewModeCallback;

  // Reference to the edit canvas
  dynamic _editCanvas;

  // 🚀 智能状态分发器
  late IntelligentStateDispatcher _intelligentDispatcher;

  /// 构造函数
  PracticeEditController(this._practiceService) {
    _undoRedoManager = UndoRedoManager(
      onStateChanged: () {
        // 更新撤销/重做状态
        _state.canUndo = _undoRedoManager.canUndo;
        _state.canRedo = _undoRedoManager.canRedo;

        // 🚀 使用智能状态分发器替代传统的 notifyListeners
        intelligentNotify(
          changeType: 'undo_redo_state_change',
          operation: 'undo_redo_state_update',
          eventData: {
            'canUndo': _state.canUndo,
            'canRedo': _state.canRedo,
            'operation': 'undo_redo_state_update',
            'timestamp': DateTime.now().toIso8601String(),
          },
          affectedUIComponents: ['undo_redo_toolbar', 'menu_bar'],
        );
      },
    );

    // 初始化智能状态分发器
    _intelligentDispatcher = IntelligentStateDispatcher(this);

    // 初始化默认数据
    _initDefaultData();
  }

  /// 获取画布 GlobalKey
  @override
  GlobalKey? get canvasKey => _canvasKey;

  // CanvasManagementMixin接口实现
  @override
  set canvasKey(GlobalKey? key) => _canvasKey = key;

  @override
  set l10n(AppLocalizations? appLocalizations) => _l10n = appLocalizations;

  /// 获取画布缩放值
  double get canvasScale => _state.canvasScale;

  // 实现 PracticePersistenceMixin 需要的抽象字段
  @override
  String? get currentPracticeId => _practiceId;

  @override
  set currentPracticeId(String? value) {
    _practiceId = value;
    notifyListeners();
  }

  @override
  String? get currentPracticeTitle => _practiceTitle;

  @override
  set currentPracticeTitle(String? value) {
    _practiceTitle = value;
    notifyListeners();
  }

  @override
  dynamic get editCanvas => _editCanvas;

  /// 获取智能状态分发器（为IntelligentNotificationMixin提供）
  @override
  dynamic get intelligentDispatcher => _intelligentDispatcher;

  /// 检查字帖是否已保存过
  @override
  bool get isSaved => currentPracticeId != null;

  /// 获取当前字帖ID
  @override
  String? get practiceId => currentPracticeId;

  /// 获取字帖服务（为mixin提供）
  @override
  PracticeService get practiceService => _practiceService;

  /// 获取当前字帖标题
  @override
  String? get practiceTitle => currentPracticeTitle;

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

  /// 检查是否已销毁（为mixin提供）
  @override
  void checkDisposed() {
    _checkDisposed();
  }

  /// 释放资源
  @override
  void dispose() {
    EditPageLogger.controllerInfo(
      'PracticeEditController开始销毁',
      data: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    try {
      // 先释放智能分发器资源
      EditPageLogger.controllerDebug('销毁智能分发器');
      _intelligentDispatcher.dispose();
    } catch (e) {
      EditPageLogger.controllerError(
        '智能分发器销毁失败',
        error: e,
      );
    }

    try {
      // 清理批量更新相关资源
      EditPageLogger.controllerDebug('销毁批量更新资源');
      disposeBatchUpdate();
    } catch (e) {
      EditPageLogger.controllerError(
        '批量更新资源销毁失败',
        error: e,
      );
    }
    try {
      // 释放撤销重做管理器资源
      EditPageLogger.controllerDebug('销毁撤销重做管理器');
      _undoRedoManager.clearHistory();
    } catch (e) {
      EditPageLogger.controllerError(
        '撤销重做管理器资源销毁失败',
        error: e,
      );
    }

    // 清除所有引用
    _canvasKey = null;
    _pageKeys.clear();
    _previewModeCallback = null;
    _editCanvas = null;

    // 标记为已销毁
    _state.isDisposed = true;

    EditPageLogger.controllerInfo(
      'PracticeEditController: 即将调用super.dispose()',
      data: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // 确保调用完整的dispose链
    try {
      super.dispose();
      EditPageLogger.controllerInfo(
        'PracticeEditController: super.dispose()调用完成',
        data: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      EditPageLogger.controllerError(
        'PracticeEditController: super.dispose()调用失败',
        error: e,
      );
    }
  }

  // deleteAllLayers method removed - now using LayerManagementMixin

  /// 标记为未保存（为mixin提供）
  @override
  void markUnsaved() {
    _state.markUnsaved();
  }

  @override
  void notifyListeners() {
    if (_state.isDisposed) {
      EditPageLogger.controllerWarning(
        '尝试在控制器销毁后调用 notifyListeners()',
        data: {'controllerState': 'disposed'},
      );
      return;
    }

    EditPageLogger.controllerDebug(
      '执行传统 notifyListeners() 调用',
      data: {
        'controllerState': 'active',
        'reason': 'temporary_fallback_during_transition',
      },
    );

    // 🔧 临时恢复传统的 notifyListeners，确保UI更新
    super.notifyListeners();
  }

  /// 处理预览模式变化
  void onPreviewModeChanged(bool isPreviewMode) {
    EditPageLogger.controllerInfo(
      '预览模式变化',
      data: {
        'isPreviewMode': isPreviewMode,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // 更新状态
    _state.isPreviewMode = isPreviewMode;

    // 通知监听器
    intelligentNotify(
      changeType: 'preview_mode_change',
      operation: 'preview_mode_update',
      eventData: {
        'isPreviewMode': isPreviewMode,
        'timestamp': DateTime.now().toIso8601String(),
      },
      affectedUIComponents: ['canvas', 'toolbar', 'property_panel'],
    );
  }

  /// 设置画布引用（供画布组件注册自己）
  void setEditCanvas(dynamic canvas) {
    _editCanvas = canvas;
    EditPageLogger.controllerDebug(
      '画布已注册到控制器',
      data: {'canvasType': canvas.runtimeType.toString()},
    );
  }

  /// 触发网格设置变化事件
  void triggerGridSettingsChange() {
    EditPageLogger.controllerDebug(
      '触发网格设置变化',
      data: {
        'hasStateDispatcher': stateDispatcher != null,
        'gridVisible': _state.gridVisible,
        'gridSize': _state.gridSize,
        'snapEnabled': _state.snapEnabled,
      },
    );

    // 如果有状态分发器，触发网格设置变化事件
    if (stateDispatcher != null) {
      EditPageLogger.controllerDebug('使用StateDispatcher分发网格设置变化事件');
      stateDispatcher!.dispatch(StateChangeEvent(
        type: StateChangeType.gridSettingsChange,
        data: {
          'gridVisible': _state.gridVisible,
          'gridSize': _state.gridSize,
          'snapEnabled': _state.snapEnabled,
        },
      ));
      EditPageLogger.controllerDebug('StateDispatcher事件分发完成');
    } else {
      // 🚀 使用智能状态分发器替代传统的 notifyListeners
      EditPageLogger.controllerDebug('StateDispatcher不存在，使用智能状态分发器');
      intelligentNotify(
        changeType: 'grid_settings_change',
        operation: 'grid_settings_change',
        eventData: {
          'gridVisible': _state.gridVisible,
          'gridSize': _state.gridSize,
          'snapEnabled': _state.snapEnabled,
          'operation': 'grid_settings_change',
          'timestamp': DateTime.now().toIso8601String(),
        },
        affectedLayers: ['background'],
        affectedUIComponents: ['canvas'],
      );
    }
    EditPageLogger.controllerDebug('网格设置变化处理完成');
  }

  /// 实现ElementManagementMixin的抽象方法 - 更新参考线管理器元素数据
  @override
  void updateGuidelineManagerElements() {
    // 🔧 修复：直接实现功能，避免递归调用
    if (state.alignmentMode != AlignmentMode.guideline) {
      return;
    }

    checkDisposed();

    // 如果当前页面存在，更新GuidelineManager的元素数据
    if (state.currentPageIndex >= 0 && state.pages.isNotEmpty) {
      final currentPage = state.pages[state.currentPageIndex];
      final elements = <Map<String, dynamic>>[];

      // 🔧 CRITICAL FIX: 元素直接存储在页面中，不是在图层中
      final pageElements = currentPage['elements'] as List<dynamic>? ?? [];

      for (final element in pageElements) {
        final elementMap = element as Map<String, dynamic>;
        elements.add({
          'id': elementMap['id'],
          'x': elementMap['x'],
          'y': elementMap['y'],
          'width': elementMap['width'],
          'height': elementMap['height'],
          'layerId': elementMap['layerId'],
          'isHidden': elementMap['isHidden'] ?? false,
        });
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
      // 🔧 修复：传入回调函数来同步参考线到state
      GuidelineManager.instance.setActiveGuidelinesOutput((guidelines) {
        // 更新state中的参考线列表
        _state.activeGuidelines.clear();
        _state.activeGuidelines.addAll(guidelines);
        notifyListeners(); // 通知UI更新
      });

      EditPageLogger.controllerDebug('参考线管理器元素数据更新完成', data: {
        'elementsCount': elements.length,
        'pageSize': '${pageWidth}x$pageHeight',
        'enabled': state.alignmentMode == AlignmentMode.guideline,
      });
    }
  }

  /// 更新字帖数据
  void updatePractice(dynamic practice) {
    final practiceMap = practice is Map<String, dynamic>
        ? practice
        : (practice?.toJson() ?? <String, dynamic>{});

    EditPageLogger.controllerInfo(
      '更新字帖数据',
      data: {
        'practiceId': practiceMap['id'] ?? practice?.id,
        'title': practiceMap['title'] ?? practice?.title,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // 更新 mixin 字段（用于标题显示）
    currentPracticeId = practiceMap['id'] ?? practice?.id;
    currentPracticeTitle = practiceMap['title'] ?? practice?.title;

    // 更新状态字段（用于页面数据）
    _state.practiceId = practiceMap['id'] ?? practice?.id;
    _state.practiceTitle = practiceMap['title'] ?? practice?.title;
    _state.pages = List<Map<String, dynamic>>.from(
        practiceMap['pages'] ?? practice?.pages ?? []);
    _state.currentPageIndex = 0;

    // 通知监听器
    notifyListeners();
  }

  /// 检查控制器是否已销毁，如果已销毁则抛出异常
  void _checkDisposed() {
    if (_state.isDisposed) {
      throw StateError(
          'A PracticeEditController was used after being disposed.');
    }
  }

  /// 初始化默认数据
  void _initDefaultData() {
    // 创建默认图层
    final defaultLayer = {
      'id': _uuid.v4(),
      'name': _l10n?.defaultLayerName(1) ?? 'Layer 1',
      'order': 0,
      'isVisible': true,
      'isLocked': false,
      'opacity': 1.0,
    };

    // 创建默认页面
    final defaultPage = {
      'id': _uuid.v4(),
      'name': _l10n?.defaultPageName(1) ?? 'Page 1',
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
      'elements': <Map<String, dynamic>>[],
      'layers': <Map<String, dynamic>>[defaultLayer], // 每个页面都有自己的图层
    };

    // 添加到状态中
    _state.pages.add(defaultPage);
    _state.currentPageIndex = 0;

    // 设置默认选中的图层
    _state.selectedLayerId = defaultLayer['id'] as String;

    EditPageLogger.controllerDebug(
      '默认数据初始化完成',
      data: {
        'pagesCount': _state.pages.length,
        'layersCount': 1,
        'selectedLayerId': _state.selectedLayerId,
      },
    );

    // 🚀 使用智能状态分发器替代传统的 notifyListeners
    intelligentNotify(
      changeType: 'controller_init',
      operation: 'init_default_data',
      eventData: {
        'pagesCount': _state.pages.length,
        'layersCount': 1,
        'selectedLayerId': _state.selectedLayerId,
        'operation': 'init_default_data',
        'timestamp': DateTime.now().toIso8601String(),
      },
      affectedLayers: ['content', 'interaction'],
      affectedUIComponents: ['canvas', 'property_panel'],
    );
  }
}
