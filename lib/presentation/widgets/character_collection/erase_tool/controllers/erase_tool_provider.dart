import 'package:flutter/material.dart';

import 'erase_tool_controller.dart';
import 'erase_tool_controller_impl.dart';

/// 擦除工具控制器提供者
class EraseToolProvider extends InheritedNotifier<EraseToolController> {
  /// 构造函数
  const EraseToolProvider({
    super.key,
    required EraseToolController controller,
    required super.child,
  }) : super(notifier: controller);

  /// 创建控制器
  static EraseToolControllerImpl createController({
    double? initialBrushSize,
  }) {
    return EraseToolControllerImpl(
      initialBrushSize: initialBrushSize,
    );
  }

  /// 获取当前控制器
  static EraseToolController of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<EraseToolProvider>();

    if (provider == null) {
      throw FlutterError('EraseToolProvider not found in context');
    }

    return provider.notifier!;
  }
}
