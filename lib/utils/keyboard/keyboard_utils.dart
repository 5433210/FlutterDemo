import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 键盘状态辅助工具类
class KeyboardUtils {
  // 跟踪按键状态
  static final Map<LogicalKeyboardKey, bool> _keyStates = {};

  // 跟踪RawKeyboard状态 - 用于更可靠地处理Windows上的Alt键
  static final Set<LogicalKeyboardKey> _rawKeyStates = {};

  // 键盘状态监听器
  static final _keyStateListeners =
      <Function(LogicalKeyboardKey key, bool isDown)>[];

  // 防抖定时器
  static Timer? _altDebounceTimer;

  // 上次Alt键状态更新时间
  static DateTime _lastAltKeyUpdate = DateTime.now();

  // 是否在Windows平台
  static final bool _isWindows =
      defaultTargetPlatform == TargetPlatform.windows;

  /// 添加键盘状态监听器
  static void addKeyStateListener(
      Function(LogicalKeyboardKey key, bool isDown) listener) {
    _keyStateListeners.add(listener);
  }

  /// 初始化键盘监听
  static void initialize() {
    // 使用两个级别的事件处理来确保捕获所有键盘事件
    ServicesBinding.instance.keyboard.addHandler(_handleKeyEvent);

    // 对于Windows平台，添加原始键盘事件处理器来可靠地跟踪Alt键
    if (_isWindows) {
      RawKeyboard.instance.addListener(_handleRawKeyEvent);
    }

    // 添加定时检查Alt键状态的机制
    _setupAltKeyStatusCheck();
  }

  /// 检查Alt键是否被按下
  static bool isAltKeyPressed() {
    if (_isWindows) {
      // 在Windows上，使用HardwareKeyboard API检查是更可靠的
      return HardwareKeyboard.instance.isAltPressed;
    }

    return isKeyPressed(LogicalKeyboardKey.alt) ||
        isKeyPressed(LogicalKeyboardKey.altLeft) ||
        isKeyPressed(LogicalKeyboardKey.altRight);
  }

  /// 获取特定键的当前状态
  static bool isKeyPressed(LogicalKeyboardKey key) {
    // 对于Alt键，特殊处理
    if (key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight) {
      if (_isWindows) {
        // 在Windows上使用HardwareKeyboard.instance更可靠
        return HardwareKeyboard.instance.isAltPressed;
      }
    }

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

  /// RawKeyboard事件处理 - 专门用于处理Windows上的Alt键问题
  static void _handleRawKeyEvent(RawKeyEvent event) {
    // 只关注Alt键
    bool isAltKey = event.logicalKey == LogicalKeyboardKey.alt ||
        event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight;

    if (!isAltKey) return;

    if (event is RawKeyDownEvent) {
      _rawKeyStates.add(event.logicalKey);
      _updateKeyState(event.logicalKey, true);
    } else if (event is RawKeyUpEvent) {
      _rawKeyStates.remove(event.logicalKey);
      _updateKeyState(event.logicalKey, false);
    }
  }

  /// 设置定时检查Alt键状态的机制，解决Windows平台上的问题
  static void _setupAltKeyStatusCheck() {
    // 定期检查Alt键状态，防止UI状态与实际键盘状态不同步
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      // 只在Windows平台，且上次Alt键更新时间超过500ms时检查
      if (_isWindows &&
          DateTime.now().difference(_lastAltKeyUpdate).inMilliseconds > 500) {
        // 检查任何Alt键是否被标记为按下
        bool anyAltKeyDown = isKeyPressed(LogicalKeyboardKey.alt) ||
            isKeyPressed(LogicalKeyboardKey.altLeft) ||
            isKeyPressed(LogicalKeyboardKey.altRight);

        // 获取系统实际Alt键状态
        bool systemAltState = HardwareKeyboard.instance.isAltPressed;

        // 如果状态不一致，强制更新
        if (anyAltKeyDown != systemAltState) {
          LogicalKeyboardKey altKey = LogicalKeyboardKey.alt;
          _keyStates[altKey] = systemAltState;

          // 记录状态强制同步
          if (kDebugMode) {
            print('⌨️ Alt键状态强制同步: $systemAltState');
          }

          // 通知监听器
          for (var listener in _keyStateListeners) {
            listener(altKey, systemAltState);
          }

          // 更新时间戳
          _lastAltKeyUpdate = DateTime.now();
        }
      }
    });
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
        // 记录上次Alt键更新时间
        _lastAltKeyUpdate = DateTime.now();

        _altDebounceTimer?.cancel();

        // 短暂延迟以避免快速切换
        _altDebounceTimer = Timer(const Duration(milliseconds: 50), () {
          // 确保即使在延迟后，状态仍然与系统一致
          if (_isWindows) {
            bool systemAltState = HardwareKeyboard.instance.isAltPressed;
            if (isDown != systemAltState) {
              isDown = systemAltState;
              _keyStates[key] = isDown;
            }
          }

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
