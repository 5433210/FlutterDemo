import 'package:flutter/material.dart';

/// 焦点持久性辅助类 - 用于管理焦点状态和恢复丢失的焦点
class FocusPersistence {
  // 追踪应用中优先级焦点节点
  static final List<FocusNode> _priorityFocusNodes = [];

  /// 添加优先级焦点节点
  static void addPriorityFocusNode(FocusNode node) {
    if (!_priorityFocusNodes.contains(node)) {
      _priorityFocusNodes.add(node);
    }
  }

  /// 获取当前焦点状态信息
  static String getFocusInfo() {
    final focusedNodes = _priorityFocusNodes.where((node) => node.hasFocus);
    if (focusedNodes.isEmpty) {
      return '无优先级节点拥有焦点';
    }

    return '已获得焦点的节点: ${focusedNodes.map((n) => n.debugLabel ?? '未命名').join(', ')}';
  }

  /// 移除优先级焦点节点
  static void removePriorityFocusNode(FocusNode node) {
    _priorityFocusNodes.remove(node);
  }

  /// 恢复优先级焦点
  static void restorePriorityFocus() {
    // 如果当前没有焦点，尝试将焦点还给最后一个优先级节点
    if (_priorityFocusNodes.isNotEmpty &&
        !_priorityFocusNodes.any((node) => node.hasFocus)) {
      final node = _priorityFocusNodes.last;
      if (node.canRequestFocus) {
        node.requestFocus();
        debugPrint('已恢复优先级焦点到: ${node.debugLabel ?? '未命名节点'}');
      }
    }
  }
}

/// 焦点持久性混入 - 用于StatefulWidget自动处理焦点
mixin FocusPersistenceMixin<T extends StatefulWidget> on State<T> {
  late final FocusNode _persistentFocus =
      FocusNode(debugLabel: widget.runtimeType.toString());

  FocusNode get focusNode => _persistentFocus;

  @override
  void dispose() {
    FocusPersistence.removePriorityFocusNode(_persistentFocus);
    _persistentFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    FocusPersistence.addPriorityFocusNode(_persistentFocus);

    // 自动请求焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _persistentFocus.requestFocus();
    });
  }
}
