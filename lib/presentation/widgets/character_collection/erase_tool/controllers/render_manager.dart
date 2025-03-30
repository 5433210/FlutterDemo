import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/erase_mode.dart';

/// 渲染管理器接口
/// 定义渲染层的所有操作和状态管理
abstract class RenderManager {
  /// 清除特定类型的缓存
  void clearCache(CacheType type);

  /// 合成所有图层并返回结果
  Future<ui.Image> composite();

  /// 释放资源
  void dispose();

  /// 获取特定类型的缓存
  ui.Image? getCache(CacheType type);

  /// 获取特定类型图层的当前图像
  ui.Image? getLayerImage(LayerType type);

  /// 使图层失效，需要重新渲染
  void invalidateLayer(LayerType type);

  /// 安排重绘
  /// 如果提供了area参数，则只重绘该区域
  void scheduleRepaint(Rect? area);

  /// 更新缓存
  void updateCache(CacheType type, ui.Image data);

  /// 更新特定类型的图层
  void updateLayer(LayerType type, dynamic data);
}
