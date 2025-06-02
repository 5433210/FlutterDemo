// filepath: lib/canvas/interaction/keyboard_shortcut_manager.dart
/// 快捷键系统管理器 - Phase 2.4 快捷键系统实现
///
/// 职责：
/// 1. 全局快捷键注册和管理
/// 2. 快捷键冲突检测与解决
/// 3. 上下文相关的快捷键
/// 4. 快捷键可配置性
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/canvas_state_manager.dart';
import 'multi_selection_manager.dart';

/// 快捷键系统管理器
class KeyboardShortcutManager {
  final CanvasStateManager _stateManager;
  final MultiSelectionManager? _selectionManager;

  // 快捷键注册表
  final Map<ShortcutContext, List<ShortcutConfig>> _shortcuts = {};

  // 统计信息
  final ShortcutStats _stats = ShortcutStats();

  // 当前上下文
  ShortcutContext _currentContext = ShortcutContext.global;

  // 启用状态
  bool _enabled = true;

  // 冲突检测结果缓存
  final List<ShortcutConflict> _conflicts = [];

  KeyboardShortcutManager(this._stateManager, this._selectionManager) {
    _initializeDefaultShortcuts();
  }

  /// 获取所有冲突
  List<ShortcutConflict> get conflicts => List.unmodifiable(_conflicts);

  /// 获取当前上下文
  ShortcutContext get currentContext => _currentContext;

  /// 获取启用状态
  bool get isEnabled => _enabled;

  /// 获取统计信息
  ShortcutStats get stats => _stats;

  /// 资源清理
  void dispose() {
    _shortcuts.clear();
    _conflicts.clear();
    _stats.reset();
  }

  /// 处理按键事件
  ShortcutResult handleKeyEvent(KeyEvent event) {
    if (!_enabled || event is! KeyDownEvent) {
      return const ShortcutResult.unhandled();
    }
    // Implementation details...
    return const ShortcutResult.unhandled();
  }

  /// 注册快捷键
  bool registerShortcut(ShortcutConfig config) {
    if (!_enabled) return false;
    final contextShortcuts = _shortcuts[config.context] ??= [];
    contextShortcuts.add(config);
    _detectConflicts();
    return true;
  }

  /// 设置当前上下文
  void setContext(ShortcutContext context) {
    _currentContext = context;
  }

  /// 启用/禁用快捷键系统
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// 检测快捷键冲突
  void _detectConflicts() {
    _conflicts.clear();
    // Implementation details...
  }

  /// 初始化默认快捷键
  void _initializeDefaultShortcuts() {
    // Implementation details...
  }
}

/// 快捷键动作类型
enum ShortcutAction {
  // 编辑操作
  undo,
  redo,
  copy,
  paste,
  cut,
  delete,
  selectAll,
  // 视图操作
  zoomIn,
  zoomOut,
  zoomToFit,
  zoomToActual,
  // 工具操作
  selectTool,
  moveTool,
  drawTool,
  textTool,
  // 元素操作
  groupElements,
  ungroupElements,
  bringToFront,
  sendToBack,
  bringForward,
  sendBackward,
  // 对齐操作
  alignLeft,
  alignCenter,
  alignRight,
  alignTop,
  alignMiddle,
  alignBottom,
  // 分布操作
  distributeHorizontally,
  distributeVertically,
  // 自定义操作
  custom
}

/// 快捷键配置
class ShortcutConfig {
  final Set<LogicalKeyboardKey> keys;
  final ShortcutAction action;
  final ShortcutContext context;
  final ShortcutPriority priority;
  final String description;
  final bool enabled;
  final VoidCallback? customHandler;

  const ShortcutConfig({
    required this.keys,
    required this.action,
    this.context = ShortcutContext.global,
    this.priority = ShortcutPriority.medium,
    required this.description,
    this.enabled = true,
    this.customHandler,
  });

  @override
  int get hashCode => Object.hash(keys, action, context);

  LogicalKeySet get keySet => LogicalKeySet.fromSet(keys);

  @override
  bool operator ==(Object other) {
    return other is ShortcutConfig &&
        setEquals(keys, other.keys) &&
        action == other.action &&
        context == other.context;
  }
}

/// 快捷键冲突信息
class ShortcutConflict {
  final Set<LogicalKeyboardKey> keys;
  final List<ShortcutConfig> conflictingShortcuts;
  final ShortcutContext context;

  const ShortcutConflict({
    required this.keys,
    required this.conflictingShortcuts,
    required this.context,
  });

  @override
  String toString() {
    return 'ShortcutConflict(keys: $keys, shortcuts: ${conflictingShortcuts.length}, context: $context)';
  }
}

/// 快捷键上下文
enum ShortcutContext {
  global, // 全局上下文
  canvas, // 画布上下文
  textEditing, // 文本编辑上下文
  selection, // 选择上下文
  drawing, // 绘制上下文
}

/// 快捷键优先级
enum ShortcutPriority { low, medium, high, critical }

/// 快捷键结果
class ShortcutResult {
  // 静态工厂方法
  static const ShortcutResult defaultHandled = ShortcutResult.handled();
  static const ShortcutResult defaultUnhandled = ShortcutResult.unhandled();
  final bool handled;

  final String? message;
  final dynamic data;

  const ShortcutResult.handled({this.message, this.data}) : handled = true;
  const ShortcutResult.unhandled({this.message})
      : handled = false,
        data = null;
}

/// 快捷键统计信息
class ShortcutStats {
  final Map<ShortcutAction, int> _usageCount = {};
  final Map<ShortcutAction, DateTime> _lastUsed = {};

  Map<ShortcutAction, int> get allUsageCounts => Map.unmodifiable(_usageCount);

  DateTime? getLastUsed(ShortcutAction action) => _lastUsed[action];
  int getUsageCount(ShortcutAction action) => _usageCount[action] ?? 0;

  void recordUsage(ShortcutAction action) {
    _usageCount[action] = (_usageCount[action] ?? 0) + 1;
    _lastUsed[action] = DateTime.now();
  }

  void reset() {
    _usageCount.clear();
    _lastUsed.clear();
  }
}
