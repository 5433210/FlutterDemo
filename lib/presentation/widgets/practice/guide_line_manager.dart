import 'package:flutter/material.dart';

/// 参考线类型
enum GuideLineType {
  /// 水平参考线
  horizontal,
  
  /// 垂直参考线
  vertical,
}

/// 参考线
class GuideLine {
  /// 参考线类型
  final GuideLineType type;
  
  /// 参考线位置
  final double position;
  
  /// 参考线颜色
  final Color color;
  
  /// 参考线ID
  final String id;
  
  /// 构造函数
  GuideLine({
    required this.type,
    required this.position,
    this.color = Colors.blue,
    String? id,
  }) : id = id ?? '${type.name}_${DateTime.now().millisecondsSinceEpoch}';
  
  /// 绘制参考线
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    if (type == GuideLineType.horizontal) {
      // 绘制水平参考线
      canvas.drawLine(
        Offset(0, position),
        Offset(size.width, position),
        paint,
      );
    } else {
      // 绘制垂直参考线
      canvas.drawLine(
        Offset(position, 0),
        Offset(position, size.height),
        paint,
      );
    }
  }
}

/// 参考线管理器
class GuideLineManager extends ChangeNotifier {
  /// 参考线列表
  final List<GuideLine> _guideLines = [];
  
  /// 是否显示参考线
  bool _visible = true;
  
  /// 获取参考线列表
  List<GuideLine> get guideLines => _guideLines;
  
  /// 获取是否显示参考线
  bool get visible => _visible;
  
  /// 添加参考线
  void addGuideLine(GuideLine guideLine) {
    _guideLines.add(guideLine);
    notifyListeners();
  }
  
  /// 移除参考线
  void removeGuideLine(String id) {
    _guideLines.removeWhere((guideLine) => guideLine.id == id);
    notifyListeners();
  }
  
  /// 清除所有参考线
  void clearGuideLines() {
    _guideLines.clear();
    notifyListeners();
  }
  
  /// 切换参考线显示
  void toggleVisibility() {
    _visible = !_visible;
    notifyListeners();
  }
  
  /// 设置参考线显示
  void setVisibility(bool visible) {
    if (_visible != visible) {
      _visible = visible;
      notifyListeners();
    }
  }
  
  /// 绘制所有参考线
  void paintGuideLines(Canvas canvas, Size size) {
    if (!_visible) return;
    
    for (final guideLine in _guideLines) {
      guideLine.paint(canvas, size);
    }
  }
}

/// 参考线绘制器
class GuideLinePainter extends CustomPainter {
  /// 参考线管理器
  final GuideLineManager guideLineManager;
  
  /// 构造函数
  GuideLinePainter(this.guideLineManager);
  
  @override
  void paint(Canvas canvas, Size size) {
    guideLineManager.paintGuideLines(canvas, size);
  }
  
  @override
  bool shouldRepaint(covariant GuideLinePainter oldDelegate) {
    return oldDelegate.guideLineManager != guideLineManager;
  }
}
