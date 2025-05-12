import 'package:flutter/material.dart';

/// 此类用于实现混合模式测试
class BlendModeTester {
  /// 在背景纹理上使用的混合模式
  static BlendMode findBestBlendModeForBackgroundTexture() {
    // 对于背景纹理，通常简单的SrcOver即可
    return BlendMode.srcOver;
  }

  /// 在字符纹理上使用的混合模式
  static BlendMode findBestBlendModeForCharacterTexture() {
    // 对于字符纹理，最佳混合模式:
    // - SrcATop: 保留原始形状，应用纹理图案，但保留形状
    // - SrcOver: 原样绘制纹理，可能会覆盖字符形状
    // - SrcIn: 仅在字符形状内绘制纹理
    // - Multiply: 可以保留字符的形状同时显示纹理的颜色和图案

    return BlendMode.multiply;
  }
}
