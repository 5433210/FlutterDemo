import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/render_types.dart';

/// 渲染管理器接口
abstract class RenderManager {
  /// 清除指定类型的缓存
  void clearCache(CacheType type);

  /// 清除图层脏区域
  void clearDirtyRegion(LayerType type);

  /// 释放资源
  void dispose();

  /// 强制重绘所有图层
  void forceRepaint();

  /// 获取指定类型的缓存
  ui.Image? getCache(CacheType type);

  /// 获取缓存统计信息
  CacheStats getCacheStats();

  /// 获取图层脏区域
  Rect? getDirtyRegion(LayerType type);

  /// 获取指定类型的图层图像
  ui.Image? getLayerImage(LayerType type);

  /// 使指定图层无效（需要重绘）
  void invalidateLayer(LayerType type);

  /// 准备渲染资源
  Future<void> prepare(Size size);

  /// 重建所有缓存
  void rebuildCaches();

  /// 设置图层脏区域
  void setDirtyRegion(LayerType type, Rect region);

  /// 更新缓存
  void updateCache(CacheType type, ui.Image data);

  /// 更新图层
  void updateLayer(LayerType type, dynamic data);
}
