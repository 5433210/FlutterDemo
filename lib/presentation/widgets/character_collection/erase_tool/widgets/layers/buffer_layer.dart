import 'package:flutter/material.dart';

import '../../controllers/erase_tool_provider.dart';
import '../../models/erase_operation.dart';

/// 擦除缓冲层
/// 显示已确认的擦除效果，使用离屏渲染优化性能
class BufferLayer extends StatelessWidget {
  /// 变换控制器
  final TransformationController transformationController;

  /// 构造函数
  const BufferLayer({
    Key? key,
    required this.transformationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = EraseToolProvider.of(context);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _BufferPainter(
              operations: controller.operations,
              transformationController: transformationController,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

/// 缓冲层绘制器
class _BufferPainter extends CustomPainter {
  /// 擦除操作列表
  final List<EraseOperation> operations;

  /// 变换控制器
  final TransformationController transformationController;

  /// 构造函数
  _BufferPainter({
    required this.operations,
    required this.transformationController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (operations.isEmpty) return;

    // 应用变换
    final matrix = transformationController.value;
    canvas.save();
    canvas.transform(matrix.storage);

    // 绘制所有已确认的擦除操作
    for (final operation in operations) {
      operation.apply(canvas);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BufferPainter oldDelegate) {
    return operations.length != oldDelegate.operations.length ||
        transformationController.value !=
            oldDelegate.transformationController.value;
  }
}
