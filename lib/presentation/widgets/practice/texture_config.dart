import 'package:flutter/material.dart';
import 'global_image_cache.dart';

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

/// 纹理配置类 - 定义纹理的属性和行为
class TextureConfig {
  /// 是否启用纹理
  final bool enabled;

  /// 纹理数据
  final Map<String, dynamic>? data;

  /// 填充模式: 'repeat', 'cover', 'contain', 'stretch'
  final String fillMode;

  /// 不透明度: 0.0 ~ 1.0
  final double opacity;

  /// 应用模式: 'background', 'characterBackground'
  final String applicationMode;

  /// 构造函数
  /// * enabled - 是否启用纹理
  /// * data - 纹理数据，包含path等信息
  /// * fillMode - 填充模式：'repeat', 'cover', 'contain', 'stretch'
  /// * opacity - 不透明度：0.0 ~ 1.0
  /// * applicationMode - 应用模式：
  ///   - 'background'：纹理应用到整个集字元素背景
  ///   - 'characterBackground'：纹理只应用到每个字符的矩形背景区域
  const TextureConfig({
    this.enabled = false,
    this.data,
    this.fillMode = 'repeat',
    this.opacity = 1.0,
    this.applicationMode = 'background',
  });

  /// 创建一个新实例，可选择性覆盖部分属性
  TextureConfig copyWith({
    bool? enabled,
    Map<String, dynamic>? data,
    String? fillMode,
    double? opacity,
    String? applicationMode,
  }) {
    return TextureConfig(
      enabled: enabled ?? this.enabled,
      data: data ?? this.data,
      fillMode: fillMode ?? this.fillMode,
      opacity: opacity ?? this.opacity,
      applicationMode: applicationMode ?? this.applicationMode,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TextureConfig) return false;

    return enabled == other.enabled &&
        mapsEqual(data, other.data) &&
        fillMode == other.fillMode &&
        opacity == other.opacity &&
        applicationMode == other.applicationMode;
  }

  @override
  int get hashCode => Object.hash(enabled, data, fillMode, opacity, applicationMode);
}

/// 纹理管理器 - 处理纹理缓存和失效
class TextureManager {
  /// 使纹理缓存失效，强制清除所有纹理缓存
  static void invalidateTextureCache() {
    // 清除纹理缓存
    GlobalImageCache.clear();
  }
}

/// 颜色工具函数 - 解析颜色代码
Color parseColor(String colorCode) {
  if (colorCode == 'transparent') {
    return Colors.transparent;
  }

  // 检查是否是十六进制颜色代码
  if (colorCode.startsWith('#')) {
    // 处理不同长度的颜色代码
    String hex = colorCode.substring(1);
    if (hex.length == 3) {
      // 将短格式转换为长格式 #RGB -> #RRGGBB
      hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
    }

    // 解析十六进制颜色值
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
  }

  // 默认返回黑色
  return Colors.black;
}
