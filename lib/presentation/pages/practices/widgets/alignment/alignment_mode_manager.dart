import 'package:flutter/foundation.dart';

import '../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'alignment_types.dart';

/// 对齐模式管理器
///
/// 采用互斥设计，确保系统在任意时刻只处于一种对齐模式。
/// 基于状态机模式，提供原子性的状态转换。
class AlignmentModeManager {
  static AlignmentMode _currentMode = AlignmentMode.guideLine; // 临时默认启用参考线对齐
  static final ValueNotifier<AlignmentMode> _modeNotifier =
      ValueNotifier(AlignmentMode.guideLine); // 临时默认启用参考线对齐

  // 回调函数，用于与外部系统集成
  static Function(bool)? _onGridAlignmentToggle;

  /// 根据当前模式获取相应的吸附距离
  static double get activeSnapDistance {
    switch (_currentMode) {
      case AlignmentMode.grid:
        return 8.0; // 网格和参考线使用相同距离
      case AlignmentMode.guideLine:
        return 8.0;
      case AlignmentMode.none:
        return 0.0; // 无对齐
    }
  }

  /// 当前对齐模式
  static AlignmentMode get currentMode => _currentMode;

  /// 获取当前模式的描述
  static String get currentModeDescription {
    switch (_currentMode) {
      case AlignmentMode.none:
        return '无自动对齐，完全手动定位';
      case AlignmentMode.guideLine:
        return '对齐到其他元素，适合相对定位';
      case AlignmentMode.grid:
        return '对齐到网格点，适合规整布局';
    }
  }

  /// 获取当前模式的显示名称
  static String get currentModeDisplayName {
    switch (_currentMode) {
      case AlignmentMode.none:
        return '自由';
      case AlignmentMode.guideLine:
        return '参考线';
      case AlignmentMode.grid:
        return '网格';
    }
  }

  /// 检查是否启用了对齐功能
  static bool get isAlignmentEnabled => _currentMode != AlignmentMode.none;

  /// 检查是否启用了网格对齐
  static bool get isGridAlignmentEnabled => _currentMode == AlignmentMode.grid;

  /// 检查是否启用了参考线对齐
  static bool get isGuideLineAlignmentEnabled =>
      _currentMode == AlignmentMode.guideLine;

  /// 模式变化通知器
  static ValueNotifier<AlignmentMode> get modeNotifier => _modeNotifier;

  /// 重置到默认模式
  static void reset() {
    setMode(AlignmentMode.none);
  }

  /// 设置网格对齐切换回调（用于与现有snap功能集成）
  static void setGridAlignmentToggleCallback(Function(bool) callback) {
    _onGridAlignmentToggle = callback;
  }

  /// 设置对齐模式
  ///
  /// 算法设计：
  /// 1. 状态清理阶段：在切换到新模式前，完全清理前一模式的所有状态
  /// 2. 状态初始化阶段：根据新模式类型进行相应的初始化
  /// 3. 原子性保证：整个状态转换过程是原子的，不会出现中间状态
  ///
  /// 参数:
  /// - [mode]: 新的对齐模式
  static void setMode(AlignmentMode mode) {
    EditPageLogger.canvasDebug('尝试设置对齐模式', data: {
      'targetMode': mode.toString(),
      'currentMode': _currentMode.toString(),
      'operation': 'alignment_mode_change_attempt',
    });

    if (_currentMode == mode) {
      EditPageLogger.canvasDebug('对齐模式相同，跳过切换', data: {
        'mode': mode.toString(),
        'operation': 'alignment_mode_change_skip',
      });
      return;
    }

    // 清理前一模式的状态
    _cleanupPreviousMode(_currentMode);

    // 设置新模式
    _currentMode = mode;
    _modeNotifier.value = mode;

    // 初始化新模式
    _initializeMode(mode);

    EditPageLogger.canvasDebug('对齐模式切换完成', data: {
      'newMode': mode.toString(),
      'operation': 'alignment_mode_change_complete',
    });
  }

  /// 切换到下一个模式（用于快捷键切换）
  static void toggleMode() {
    switch (_currentMode) {
      case AlignmentMode.none:
        setMode(AlignmentMode.guideLine);
        break;
      case AlignmentMode.guideLine:
        setMode(AlignmentMode.grid);
        break;
      case AlignmentMode.grid:
        setMode(AlignmentMode.none);
        break;
    }
  }

  /// 清理前一模式的状态
  ///
  /// 确保没有状态泄漏影响新模式的工作
  static void _cleanupPreviousMode(AlignmentMode mode) {
    switch (mode) {
      case AlignmentMode.grid:
        // 清理网格对齐状态（通过回调关闭snap功能）
        if (_onGridAlignmentToggle != null) {
          _onGridAlignmentToggle!(false);
        }
        EditPageLogger.canvasDebug('清理网格对齐状态', data: {
          'mode': 'grid',
          'operation': 'alignment_mode_cleanup',
        });
        break;
      case AlignmentMode.guideLine:
        // 清理参考线对齐相关状态
        EditPageLogger.canvasDebug('清理参考线对齐状态', data: {
          'mode': 'guideLine',
          'operation': 'alignment_mode_cleanup',
        });
        break;
      case AlignmentMode.none:
        // 无需清理
        break;
    }
  }

  /// 初始化新模式
  ///
  /// 根据新模式类型进行相应的初始化
  static void _initializeMode(AlignmentMode mode) {
    switch (mode) {
      case AlignmentMode.grid:
        // 启用网格对齐（使用现有的snap功能）
        if (_onGridAlignmentToggle != null) {
          _onGridAlignmentToggle!(true);
        }
        EditPageLogger.canvasDebug('启用网格对齐', data: {
          'mode': 'grid',
          'operation': 'alignment_mode_initialize',
        });
        break;
      case AlignmentMode.guideLine:
        // 参考线按需显示，不需要预初始化
        EditPageLogger.canvasDebug('初始化参考线对齐', data: {
          'mode': 'guideLine',
          'operation': 'alignment_mode_initialize',
        });
        break;
      case AlignmentMode.none:
        // 停用网格对齐
        if (_onGridAlignmentToggle != null) {
          _onGridAlignmentToggle!(false);
        }
        EditPageLogger.canvasDebug('停用所有对齐功能', data: {
          'mode': 'none',
          'operation': 'alignment_mode_initialize',
        });
        break;
    }
  }
}
