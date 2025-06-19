import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/providers/cache_providers.dart'
    as cache_providers;

/// 工具函数：比较两个Map是否相等
bool mapsEqual(Map<String, dynamic>? map1, Map<String, dynamic>? map2) {
  if (map1 == null && map2 == null) return true;
  if (map1 == null || map2 == null) return false;
  if (map1.length != map2.length) return false;

  for (final key in map1.keys) {
    if (!map2.containsKey(key)) return false;
    if (map1[key] != map2[key]) return false;
  }

  return true;
}

/// 颜色工具函数 - 解析颜色代码
Color parseColor(String colorCode) {
  if (colorCode.isEmpty) return Colors.black;

  final lowerColorValue = colorCode.toLowerCase().trim();

  // 处理特殊颜色名称
  switch (lowerColorValue) {
    case 'transparent':
      return Colors.transparent;
    case 'white':
      return Colors.white;
    case 'black':
      return Colors.black;
    case 'red':
      return Colors.red;
    case 'green':
      return Colors.green;
    case 'blue':
      return Colors.blue;
    case 'yellow':
      return Colors.yellow;
    case 'orange':
      return Colors.orange;
    case 'purple':
      return Colors.purple;
    case 'pink':
      return Colors.pink;
    case 'grey':
    case 'gray':
      return Colors.grey;
    case 'cyan':
      return Colors.cyan;
    case 'magenta':
      return const Color(0xFFFF00FF);
    case 'lime':
      return Colors.lime;
    case 'indigo':
      return Colors.indigo;
    case 'teal':
      return Colors.teal;
    case 'amber':
      return Colors.amber;
    case 'brown':
      return Colors.brown;
  }

  // 处理16进制颜色值
  try {
    final colorStr = lowerColorValue.startsWith('#')
        ? lowerColorValue.substring(1)
        : lowerColorValue;

    // 支持3位、6位、8位16进制格式
    String fullColorStr;
    if (colorStr.length == 3) {
      // 将 RGB 转换为 RRGGBB
      fullColorStr =
          'FF${colorStr[0]}${colorStr[0]}${colorStr[1]}${colorStr[1]}${colorStr[2]}${colorStr[2]}';
    } else if (colorStr.length == 6) {
      // 添加Alpha通道 (完全不透明)
      fullColorStr = 'FF$colorStr';
    } else if (colorStr.length == 8) {
      // 已包含Alpha通道
      fullColorStr = colorStr;
    } else {
      throw FormatException('Invalid color format: $colorCode');
    }

    return Color(int.parse(fullColorStr, radix: 16));
  } catch (e) {
    // 解析失败时返回黑色而不是抛出异常
    return Colors.black;
  }
}

/// 纹理配置类，定义如何应用纹理
/// This class defines how to apply a texture
class TextureConfig {
  /// 是否启用纹理
  final bool enabled;

  /// 纹理数据
  final Map<String, dynamic>? data;

  /// 填充模式
  final String fillMode;

  /// 适应模式
  final String fitMode;

  /// 不透明度
  final double opacity;

  /// 纹理尺寸
  final double textureWidth;
  final double textureHeight;

  /// 构造函数
  /// * enabled - 是否启用纹理
  /// * data - 纹理数据，包含path等信息
  /// * fillMode - 填充模式：'repeat', 'cover', 'stretch', 'contain'
  /// * fitMode - 适应模式：'scaleToFit', 'fill', 'scaleToCover'
  /// * opacity - 不透明度：0.0 ~ 1.0
  /// * textureWidth/textureHeight - 纹理尺寸（像素值）
  const TextureConfig({
    this.enabled = false,
    this.data,
    this.fillMode = 'stretch',
    this.fitMode = 'fill',
    this.opacity = 1.0,
    this.textureWidth = 100.0,
    this.textureHeight = 100.0,
  });
  @override
  int get hashCode {
    return Object.hash(
      enabled,
      data,
      fillMode,
      fitMode,
      opacity,
      textureWidth,
      textureHeight,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TextureConfig) return false;

    return enabled == other.enabled &&
        mapsEqual(data, other.data) &&
        fillMode == other.fillMode &&
        fitMode == other.fitMode &&
        opacity == other.opacity &&
        textureWidth == other.textureWidth &&
        textureHeight == other.textureHeight;
  }

  /// 创建一个新实例，可选择性覆盖部分属性
  TextureConfig copyWith({
    bool? enabled,
    Map<String, dynamic>? data,
    String? fillMode,
    String? fitMode,
    double? opacity,
    double? textureWidth,
    double? textureHeight,
  }) {
    return TextureConfig(
      enabled: enabled ?? this.enabled,
      data: data ?? this.data,
      fillMode: fillMode ?? this.fillMode,
      fitMode: fitMode ?? this.fitMode,
      opacity: opacity ?? this.opacity,
      textureWidth: textureWidth ?? this.textureWidth,
      textureHeight: textureHeight ?? this.textureHeight,
    );
  }
}

/// 纹理管理器 - 处理纹理缓存和失效
class TextureManager {
  /// 使纹理缓存失效，强制清除所有纹理缓存
  static Future<void> invalidateTextureCache(WidgetRef ref) async {
    // 清除纹理缓存
    final imageCacheService =
        ref.read(cache_providers.imageCacheServiceProvider);
    await imageCacheService.clearAll();
  }
}
