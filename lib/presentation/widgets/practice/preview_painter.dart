import 'package:flutter/material.dart';

import 'preview_manager.dart';

/// 预览绘制器
class PreviewPainter extends CustomPainter {
  /// 预览管理器
  final PreviewManager previewManager;
  
  /// 页面大小
  final Size pageSize;
  
  /// 构造函数
  PreviewPainter({
    required this.previewManager,
    required this.pageSize,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = previewManager.previewBackgroundColor,
    );
    
    // 绘制页面边界
    if (previewManager.showPageBoundary) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
    
    // 绘制打印标记
    previewManager.drawPrintMarks(canvas, pageSize);
  }
  
  @override
  bool shouldRepaint(covariant PreviewPainter oldDelegate) {
    return oldDelegate.previewManager != previewManager ||
           oldDelegate.pageSize != pageSize;
  }
}
