import 'package:flutter/material.dart';

import '../../models/erase_operation.dart';

/// 预览图层
/// 负责显示擦除效果
class PreviewLayer extends StatelessWidget {
  /// 变换控制器
  final TransformationController transformationController;

  /// 笔刷大小
  final double brushSize;

  /// 缩放比例
  final double scale;

  /// 已完成的操作列表
  final List<EraseOperation> operations;

  /// 当前正在进行的操作
  final EraseOperation? currentOperation;

  const PreviewLayer({
    Key? key,
    required this.transformationController,
    required this.brushSize,
    this.scale = 1.0,
    this.operations = const [],
    this.currentOperation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _PreviewPainter(
          operations: operations,
          currentOperation: currentOperation,
          transform: transformationController.value,
          brushSize: brushSize,
          scale: scale,
        ),
        isComplex: true,
      ),
    );
  }
}

/// 预览绘制器
class _PreviewPainter extends CustomPainter {
  final List<EraseOperation> operations;
  final EraseOperation? currentOperation;
  final Matrix4 transform;
  final double brushSize;
  final double scale;

  const _PreviewPainter({
    required this.operations,
    this.currentOperation,
    required this.transform,
    required this.brushSize,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 应用变换
    canvas.save();
    canvas.transform(transform.storage);

    // 绘制已完成的操作
    for (final operation in operations) {
      operation.apply(canvas);
    }

    // 绘制当前操作
    currentOperation?.apply(canvas);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) {
    return operations != oldDelegate.operations ||
        currentOperation != oldDelegate.currentOperation ||
        transform != oldDelegate.transform ||
        brushSize != oldDelegate.brushSize ||
        scale != oldDelegate.scale;
  }
}
