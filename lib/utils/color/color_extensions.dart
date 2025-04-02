import 'dart:ui';

import 'package:image/image.dart' as img;

/// 颜色转换扩展方法
extension ColorConversionExt on img.ColorRgb8 {
  /// 从Color创建ColorRgb8
  static img.ColorRgb8 fromColor(Color color) {
    return img.ColorRgb8(color.red, color.green, color.blue);
  }
}
