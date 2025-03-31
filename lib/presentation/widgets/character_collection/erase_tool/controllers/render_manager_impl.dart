import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/render_types.dart';
import 'render_manager.dart';

/// 渲染管理器实现
class RenderManagerImpl implements RenderManager {
  /// 图层图像缓存
  final Map<LayerType, ui.Image?> _layerImages = {};

  /// 图层脏区域
  final Map<LayerType, Rect?> _dirtyRegions = {};

  /// 类型缓存
  final Map<CacheType, ui.Image?> _caches = {};

  /// 画布尺寸
  Size? _size;

  /// 缓存统计
  final Map<CacheType, int> _cacheHits = {};
  final Map<CacheType, int> _cacheMisses = {};

  @override
  void clearCache(CacheType type) {
    _caches[type]?.dispose();
    _caches.remove(type);
  }

  @override
  void clearDirtyRegion(LayerType type) {
    _dirtyRegions.remove(type);
  }

  @override
  void dispose() {
    // 清理所有图像资源
    for (final image in [..._layerImages.values, ..._caches.values]) {
      image?.dispose();
    }
    _layerImages.clear();
    _caches.clear();
    _dirtyRegions.clear();
  }

  @override
  void forceRepaint() {
    // 将所有图层标记为脏区域
    for (final type in LayerType.values) {
      if (_layerImages.containsKey(type)) {
        _dirtyRegions[type] = Rect.fromLTWH(
          0,
          0,
          _size?.width ?? 0,
          _size?.height ?? 0,
        );
      }
    }
  }

  @override
  ui.Image? getCache(CacheType type) {
    final image = _caches[type];
    if (image != null) {
      _cacheHits[type] = (_cacheHits[type] ?? 0) + 1;
    } else {
      _cacheMisses[type] = (_cacheMisses[type] ?? 0) + 1;
    }
    return image;
  }

  @override
  CacheStats getCacheStats() {
    int totalSize = 0;
    int totalHits = 0;
    int totalMisses = 0;

    for (final type in CacheType.values) {
      if (_caches.containsKey(type)) {
        final image = _caches[type];
        if (image != null) {
          // 估算图像内存大小
          totalSize += image.width * image.height * 4; // 4字节/像素
        }
      }
      totalHits += _cacheHits[type] ?? 0;
      totalMisses += _cacheMisses[type] ?? 0;
    }

    return CacheStats(
      size: totalSize,
      hits: totalHits,
      misses: totalMisses,
    );
  }

  @override
  Rect? getDirtyRegion(LayerType type) => _dirtyRegions[type];

  @override
  ui.Image? getLayerImage(LayerType type) => _layerImages[type];

  @override
  void invalidateLayer(LayerType type) {
    // 如果图层存在，标记整个图层为脏区域
    if (_layerImages.containsKey(type)) {
      _dirtyRegions[type] = Rect.fromLTWH(
        0,
        0,
        _size?.width ?? 0,
        _size?.height ?? 0,
      );
    }
  }

  @override
  Future<void> prepare(Size size) async {
    _size = size;
    // 清除所有脏区域
    _dirtyRegions.clear();

    // 检查并调整图层尺寸
    for (final entry in _layerImages.entries) {
      final image = entry.value;
      if (image != null &&
          (image.width != size.width.toInt() ||
              image.height != size.height.toInt())) {
        // 图层尺寸不匹配，需要重新创建
        _layerImages[entry.key]?.dispose();
        _layerImages[entry.key] = null;
        invalidateLayer(entry.key);
      }
    }
  }

  @override
  void rebuildCaches() {
    // 清除所有缓存
    for (final cache in _caches.values) {
      cache?.dispose();
    }
    _caches.clear();

    // 重置统计数据
    _cacheHits.clear();
    _cacheMisses.clear();
  }

  @override
  void setDirtyRegion(LayerType type, Rect region) {
    final existing = _dirtyRegions[type];
    if (existing == null) {
      _dirtyRegions[type] = region;
    } else {
      // 合并脏区域
      _dirtyRegions[type] = existing.expandToInclude(region);
    }
  }

  @override
  void updateCache(CacheType type, ui.Image data) {
    _caches[type]?.dispose();
    _caches[type] = data;
  }

  @override
  void updateLayer(LayerType type, dynamic data) {
    if (data is ui.Image) {
      _layerImages[type]?.dispose();
      _layerImages[type] = data;
    } else {
      throw ArgumentError('Invalid layer data type');
    }
  }
}
