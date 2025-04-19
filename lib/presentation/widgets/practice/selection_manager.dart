import 'package:flutter/material.dart';

/// 选择管理器
class SelectionManager {
  /// 选择框起始点
  Offset? _selectionStart;
  
  /// 选择框当前点
  Offset? _selectionCurrent;
  
  /// 是否正在选择
  bool _isSelecting = false;
  
  /// 获取选择框
  Rect? getSelectionRect() {
    if (_selectionStart == null || _selectionCurrent == null) {
      return null;
    }
    
    return Rect.fromPoints(_selectionStart!, _selectionCurrent!);
  }
  
  /// 开始选择
  void startSelection(Offset position) {
    _selectionStart = position;
    _selectionCurrent = position;
    _isSelecting = true;
  }
  
  /// 更新选择
  void updateSelection(Offset position) {
    if (!_isSelecting) return;
    _selectionCurrent = position;
  }
  
  /// 结束选择
  Rect? endSelection() {
    if (!_isSelecting) return null;
    
    final selectionRect = getSelectionRect();
    _selectionStart = null;
    _selectionCurrent = null;
    _isSelecting = false;
    
    return selectionRect;
  }
  
  /// 取消选择
  void cancelSelection() {
    _selectionStart = null;
    _selectionCurrent = null;
    _isSelecting = false;
  }
  
  /// 是否正在选择
  bool get isSelecting => _isSelecting;
  
  /// 绘制选择框
  void paintSelectionRect(Canvas canvas) {
    final selectionRect = getSelectionRect();
    if (selectionRect == null) return;
    
    // 绘制半透明填充
    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(selectionRect, fillPaint);
    
    // 绘制边框
    final strokePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(selectionRect, strokePaint);
  }
  
  /// 检查元素是否在选择框内
  bool isElementInSelection(Map<String, dynamic> element, Rect selectionRect) {
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    
    final elementRect = Rect.fromLTWH(x, y, width, height);
    
    // 检查元素是否与选择框相交
    return selectionRect.overlaps(elementRect);
  }
}
