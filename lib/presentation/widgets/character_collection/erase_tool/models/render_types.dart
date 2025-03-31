import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 缓存统计信息
class CacheStats {
  /// 缓存大小
  final int size;

  /// 命中次数
  final int hits;

  /// 未命中次数
  final int misses;

  const CacheStats({
    this.size = 0,
    this.hits = 0,
    this.misses = 0,
  });

  /// 计算命中率
  double get hitRate => hits / (hits + misses);
}

/// 缓存类型
enum CacheType {
  /// 临时缓存
  temp,

  /// 持久缓存
  persistent,

  /// 合成缓存
  composite;

  /// 获取缓存名称
  String get displayName {
    switch (this) {
      case CacheType.temp:
        return '临时缓存';
      case CacheType.persistent:
        return '持久缓存';
      case CacheType.composite:
        return '合成缓存';
    }
  }
}

/// 图层数据结构
class LayerData {
  /// 图像数据
  final ui.Image? image;

  /// 脏区域
  final Rect? dirtyRegion;

  /// 是否需要重绘
  final bool needsRepaint;

  const LayerData({
    this.image,
    this.dirtyRegion,
    this.needsRepaint = false,
  });

  /// 创建新的图层数据
  LayerData copyWith({
    ui.Image? image,
    Rect? dirtyRegion,
    bool? needsRepaint,
  }) {
    return LayerData(
      image: image ?? this.image,
      dirtyRegion: dirtyRegion ?? this.dirtyRegion,
      needsRepaint: needsRepaint ?? this.needsRepaint,
    );
  }
}

/// 图层类型
enum LayerType {
  /// 原始图层
  original,

  /// 缓冲图层
  buffer,

  /// 预览图层
  preview,

  /// UI图层
  ui;

  /// 获取图层名称
  String get displayName {
    switch (this) {
      case LayerType.original:
        return '原始图层';
      case LayerType.buffer:
        return '缓冲图层';
      case LayerType.preview:
        return '预览图层';
      case LayerType.ui:
        return 'UI图层';
    }
  }
}
