import 'dart:async';

import 'package:flutter/services.dart';

/// 键盘状态辅助工具类
class KeyboardUtils {
  // 跟踪按键状态
  static final Map<LogicalKeyboardKey, bool> _keyStates = {};

  // 键盘状态监听器
  static final _keyStateListeners =
      <Function(LogicalKeyboardKey key, bool isDown)>[];

  // 防抖定时器
  static Timer? _altDebounceTimer;

  /// 添加键盘状态监听器
  static void addKeyStateListener(
      Function(LogicalKeyboardKey key, bool isDown) listener) {
    _keyStateListeners.add(listener);
  }

  /// 初始化键盘监听
  static void initialize() {
    // 可以在应用启动时调用此方法设置全局键盘监听
    ServicesBinding.instance.keyboard.addHandler(_handleKeyEvent);
  }

  /// 检查Alt键是否被按下
  static bool isAltKeyPressed() {
    return isKeyPressed(LogicalKeyboardKey.alt) ||
        isKeyPressed(LogicalKeyboardKey.altLeft) ||
        isKeyPressed(LogicalKeyboardKey.altRight);
  }

  /// 获取特定键的当前状态
  static bool isKeyPressed(LogicalKeyboardKey key) {
    return _keyStates[key] ?? false;
  }

  /// 移除键盘状态监听器
  static void removeKeyStateListener(
      Function(LogicalKeyboardKey key, bool isDown) listener) {
    _keyStateListeners.remove(listener);
  }

  /// 全局键盘事件处理器
  static bool _handleKeyEvent(KeyEvent event) {
    LogicalKeyboardKey key = event.logicalKey;

    // 处理键盘事件
    if (event is KeyDownEvent) {
      _updateKeyState(key, true);
    } else if (event is KeyUpEvent) {
      _updateKeyState(key, false);
    } else if (event is KeyRepeatEvent) {
      // 对于重复事件，保持当前状态
      // 不做任何状态更改
    }

    // 返回false让事件继续传递
    return false;
  }

  /// 更新按键状态
  static void _updateKeyState(LogicalKeyboardKey key, bool isDown) {
    bool oldState = _keyStates[key] ?? false;

    // 如果状态发生变化
    if (oldState != isDown) {
      _keyStates[key] = isDown;

      // 对于Alt键，使用防抖处理
      if (key == LogicalKeyboardKey.alt ||
          key == LogicalKeyboardKey.altLeft ||
          key == LogicalKeyboardKey.altRight) {
        _altDebounceTimer?.cancel();

        // 短暂延迟以避免快速切换
        _altDebounceTimer = Timer(const Duration(milliseconds: 50), () {
          // 通知所有监听器
          for (var listener in _keyStateListeners) {
            listener(key, isDown);
          }
        });
      } else {
        // 立即通知其他键的变化
        for (var listener in _keyStateListeners) {
          listener(key, isDown);
        }
      }
    }
  }
}
