import 'package:flutter/material.dart';

/// 对齐功能配置类
class AlignmentConfig {
  // 统一吸附距离：用于参考线检测和自动对齐的统一阈值
  static const double alignmentThreshold = 8.0;

  // 网格大小配置
  static const double gridSize = 20.0;

  // 对齐动画持续时间
  static const Duration animationDuration = Duration(milliseconds: 150);

  // 最多同时显示的参考线数量
  static const int maxSimultaneousGuideLines = 2;

  // 参考线视觉配置
  static const Color guideLineColor = Color(0xFF2196F3);
  static const double guideLineOpacity = 0.8;
  static const double guideLineWidth = 1.0;

  // 吸附指示器配置
  static const double snapIndicatorRadius = 4.0;
  static const double arrowLength = 20.0;
  static const double arrowHeadSize = 6.0;

  // 虚线配置
  static const double dashWidth = 8.0;
  static const double dashSpace = 4.0;
  // 调试配置
  static const bool showDebugInfo = true; // 临时启用以验证参考线功能
  static const bool enablePerformanceLogging = false;

  // 触觉反馈配置
  static const bool enableHapticFeedback = true;

  /// 获取距离标注文本样式（调试用）
  static const TextStyle debugTextStyle = TextStyle(
    color: Colors.red,
    fontSize: 10,
    fontWeight: FontWeight.bold,
  );

  /// 获取距离标注Paint对象（调试用）
  static Paint get debugTextBackgroundPaint =>
      Paint()..color = Colors.white.withOpacity(0.8);

  /// 获取参考线Paint对象
  static Paint get guideLinePaint => Paint()
    ..color = guideLineColor.withOpacity(guideLineOpacity)
    ..strokeWidth = guideLineWidth
    ..style = PaintingStyle.stroke;

  /// 获取吸附指示器Paint对象
  static Paint get snapIndicatorPaint => Paint()
    ..color = guideLineColor
    ..style = PaintingStyle.fill;

  /// 禁用构造函数，这是一个静态配置类
  AlignmentConfig._();

  /// 根据当前缩放级别调整阈值
  static double getScaledThreshold(double scaleFactor) {
    // 确保在高缩放级别下阈值仍然合理
    return alignmentThreshold / scaleFactor.clamp(0.5, 2.0);
  }
}
