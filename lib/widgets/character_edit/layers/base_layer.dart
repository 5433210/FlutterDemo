import 'package:flutter/material.dart';

/// 所有图层的基类，提供公共功能和接口
abstract class BaseLayer extends StatelessWidget {
  const BaseLayer({Key? key}) : super(key: key);

  /// 是否是复杂绘制（提示Flutter可能需要更多资源）
  bool get isComplexPainting => false;

  /// 是否会频繁变化（提示Flutter准备更频繁的重绘）
  bool get willChangePainting => false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: createPainter(),
        isComplex: isComplexPainting,
        willChange: willChangePainting,
        size: Size.infinite,
      ),
    );
  }

  /// 创建图层使用的绘制器 - 公开方法以便子类可以重写
  CustomPainter createPainter();
}
