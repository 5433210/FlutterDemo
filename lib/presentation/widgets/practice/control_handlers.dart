import 'package:flutter/material.dart';

/// 控制点处理类
/// 包含所有控制点和变换相关的方法
class ControlHandlers {
  /// 构建单个控制点
  static Widget buildControlPoint(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue, width: 2),
        shape: BoxShape.rectangle,
      ),
    );
  }

  /// 构建变换控制点
  static Widget buildTransformControls(double width, double height) {
    const controlSize = 10.0;

    return Stack(
      children: [
        // 四个角控制点 (缩放)
        // 左上
        Positioned(
          left: -controlSize / 2,
          top: -controlSize / 2,
          child: buildControlPoint(controlSize),
        ),
        // 右上
        Positioned(
          right: -controlSize / 2,
          top: -controlSize / 2,
          child: buildControlPoint(controlSize),
        ),
        // 左下
        Positioned(
          left: -controlSize / 2,
          bottom: -controlSize / 2,
          child: buildControlPoint(controlSize),
        ),
        // 右下
        Positioned(
          right: -controlSize / 2,
          bottom: -controlSize / 2,
          child: buildControlPoint(controlSize),
        ),

        // 四个边中点控制点 (水平/垂直缩放)
        // 上中
        Positioned(
          left: (width - controlSize) / 2,
          top: -controlSize / 2,
          child: buildControlPoint(controlSize),
        ),
        // 右中
        Positioned(
          right: -controlSize / 2,
          top: (height - controlSize) / 2,
          child: buildControlPoint(controlSize),
        ),
        // 下中
        Positioned(
          left: (width - controlSize) / 2,
          bottom: -controlSize / 2,
          child: buildControlPoint(controlSize),
        ),
        // 左中
        Positioned(
          left: -controlSize / 2,
          top: (height - controlSize) / 2,
          child: buildControlPoint(controlSize),
        ),

        // 旋转控制点
        Positioned(
          left: (width - controlSize) / 2,
          top: -30,
          child: Container(
            width: controlSize,
            height: controlSize,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue, width: 2),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // 旋转控制线
        Positioned(
          left: width / 2,
          top: -30 + controlSize / 2,
          child: Container(
            width: 1,
            height: 30 - controlSize / 2,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}
