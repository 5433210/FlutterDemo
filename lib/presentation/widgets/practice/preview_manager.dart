import 'package:flutter/material.dart';

/// 预览模式管理器
class PreviewManager extends ChangeNotifier {
  /// 是否处于预览模式
  bool _isPreviewMode = false;

  /// 预览模式下的缩放比例
  double _previewScale = 1.0;

  /// 预览模式下的背景颜色
  Color _previewBackgroundColor = Colors.white;

  /// 是否显示页面边界
  bool _showPageBoundary = true;

  /// 是否显示打印标记
  bool _showPrintMarks = false;

  /// 获取是否处于预览模式
  bool get isPreviewMode => _isPreviewMode;

  /// 获取预览模式下的背景颜色
  Color get previewBackgroundColor => _previewBackgroundColor;

  /// 获取预览模式下的缩放比例
  double get previewScale => _previewScale;

  /// 获取是否显示页面边界
  bool get showPageBoundary => _showPageBoundary;

  /// 获取是否显示打印标记
  bool get showPrintMarks => _showPrintMarks;

  /// 绘制打印标记
  void drawPrintMarks(Canvas canvas, Size pageSize) {
    if (!_showPrintMarks) return;

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 绘制裁切标记
    const markLength = 20.0;
    const markOffset = 5.0;

    // 左上角
    canvas.drawLine(
      const Offset(-markOffset, 0),
      const Offset(-markOffset - markLength, 0),
      paint,
    );
    canvas.drawLine(
      const Offset(0, -markOffset),
      const Offset(0, -markOffset - markLength),
      paint,
    );

    // 右上角
    canvas.drawLine(
      Offset(pageSize.width + markOffset, 0),
      Offset(pageSize.width + markOffset + markLength, 0),
      paint,
    );
    canvas.drawLine(
      Offset(pageSize.width, -markOffset),
      Offset(pageSize.width, -markOffset - markLength),
      paint,
    );

    // 左下角
    canvas.drawLine(
      Offset(-markOffset, pageSize.height),
      Offset(-markOffset - markLength, pageSize.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, pageSize.height + markOffset),
      Offset(0, pageSize.height + markOffset + markLength),
      paint,
    );

    // 右下角
    canvas.drawLine(
      Offset(pageSize.width + markOffset, pageSize.height),
      Offset(pageSize.width + markOffset + markLength, pageSize.height),
      paint,
    );
    canvas.drawLine(
      Offset(pageSize.width, pageSize.height + markOffset),
      Offset(pageSize.width, pageSize.height + markOffset + markLength),
      paint,
    );
  }

  /// 设置预览背景颜色
  void setPreviewBackgroundColor(Color color) {
    _previewBackgroundColor = color;
    notifyListeners();
  }

  /// 设置预览模式
  void setPreviewMode(bool isPreviewMode) {
    if (_isPreviewMode == isPreviewMode) return;
    _isPreviewMode = isPreviewMode;
    notifyListeners();
  }

  /// 设置预览缩放比例
  void setPreviewScale(double scale) {
    if (scale <= 0) return;
    _previewScale = scale;
    notifyListeners();
  }

  /// 切换显示页面边界
  void togglePageBoundary() {
    _showPageBoundary = !_showPageBoundary;
    notifyListeners();
  }

  /// 切换预览模式
  void togglePreviewMode() {
    _isPreviewMode = !_isPreviewMode;
    notifyListeners();
  }

  /// 切换显示打印标记
  void togglePrintMarks() {
    _showPrintMarks = !_showPrintMarks;
    notifyListeners();
  }
}
