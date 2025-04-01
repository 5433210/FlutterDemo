import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../debug/debug_flags.dart';
import '../focus/focus_persistence.dart';
import 'keyboard_utils.dart';

/// 键盘状态监控器 - 用于追踪键盘状态变化，帮助调试
class KeyboardMonitor {
  static final instance = KeyboardMonitor._();

  // 私有构造函数
  KeyboardMonitor._() {
    // 注册键盘状态监听器
    KeyboardUtils.addKeyStateListener(_onKeyStateChanged);
  }

  // 输出当前Alt键状态
  void debugLogAltKeyState() {
    final isAltPressed = KeyboardUtils.isAltKeyPressed();
    print('⌨️ 当前Alt键状态: $isAltPressed');
  }

  // 处理键盘状态变化
  void _onKeyStateChanged(LogicalKeyboardKey key, bool isDown) {
    // 特别关注Alt键
    if (key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight) {
      DebugFlags.trackAltKeyState('KeyboardMonitor', isDown);
      print('⌨️ Alt键状态更新: ${key.keyLabel} = $isDown');
    }
  }

  // 添加到应用根Widget
  static Widget wrapApp(Widget app) {
    return KeyboardMonitorWidget(child: app);
  }
}

/// 键盘监控器Widget - 监听应用范围内的键盘事件
class KeyboardMonitorWidget extends StatefulWidget {
  final Widget child;

  const KeyboardMonitorWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<KeyboardMonitorWidget> createState() => _KeyboardMonitorWidgetState();
}

class _KeyboardMonitorWidgetState extends State<KeyboardMonitorWidget> {
  final FocusNode _rootFocusNode = FocusNode(debugLabel: 'RootMonitor');

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        // 确保点击事件能够传递到子部件
        if (!_rootFocusNode.hasFocus &&
            !FocusManager.instance.primaryFocus!.ancestors
                .contains(_rootFocusNode)) {
          // 如果根焦点未获取焦点且当前焦点不是根焦点的子代，尝试恢复焦点
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // 延迟执行以避免干扰当前事件
            FocusPersistence.restorePriorityFocus();
          });
        }
      },
      child: Focus(
        focusNode: _rootFocusNode,
        onKeyEvent: (node, event) {
          // 记录所有键盘事件
          if (DebugFlags.enableEventTracing) {
            print(
                '🔑 键盘事件: ${event.runtimeType} - ${event.logicalKey.keyLabel}');
          }
          return KeyEventResult.ignored;
        },
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _rootFocusNode.dispose();
    super.dispose();
  }
}
