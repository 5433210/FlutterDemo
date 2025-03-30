import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/erase_mode.dart';
import 'render_manager.dart';

/// 渲染管理器具体实现
class RenderManagerImpl implements RenderManager {
  /// 图层缓存
  final Map<LayerType, ui.Image?> _layerImages = {};

  /// 图层脏区域
  final Map<LayerType, Rect?> _dirtyRegions = {};

  /// 缓存
  final Map<CacheType, ui.Image?> _caches = {};

  /// 渲染锁
  final Completer<void>? _renderLock = null;

  /// 构造函数
  RenderManagerImpl();

  @override
  void clearCache(CacheType type) {
    final cache = _caches[type];
    if (cache != null) {
      cache.dispose();
      _caches[type] = null;
    }
  }

  @override
  Future<ui.Image> composite() async {
    if (_renderLock != null && !_renderLock!.isCompleted) {
      await _renderLock!.future;
    }

    final completer = Completer<ui.Image>();
    final Completer<void> renderLock = Completer<void>();

    // 创建离屏渲染器
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 获取最大图像尺寸
    Size compositeSize = const Size(1, 1);
    for (final layer in _layerImages.values) {
      if (layer != null) {
        if (layer.width > compositeSize.width) {
          compositeSize = Size(layer.width.toDouble(), compositeSize.height);
        }
        if (layer.height > compositeSize.height) {
          compositeSize = Size(compositeSize.width, layer.height.toDouble());
        }
      }
    }

    // 按顺序绘制每个图层
    final layerOrder = [
      LayerType.original,
      LayerType.buffer,
      LayerType.preview,
      LayerType.ui,
    ];

    for (final layerType in layerOrder) {
      final layerImage = _layerImages[layerType];
      if (layerImage != null) {
        canvas.drawImage(layerImage, Offset.zero, Paint());
      }
    }

    // 完成绘制并获取合成图像
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      compositeSize.width.toInt(),
      compositeSize.height.toInt(),
    );

    completer.complete(image);
    renderLock.complete();

    return completer.future;
  }

  @override
  void dispose() {
    // 释放所有图层图像
    for (final layer in _layerImages.values) {
      layer?.dispose();
    }
    _layerImages.clear();

    // 释放所有缓存
    for (final cache in _caches.values) {
      cache?.dispose();
    }
    _caches.clear();
  }

  @override
  ui.Image? getCache(CacheType type) {
    return _caches[type];
  }

  @override
  ui.Image? getLayerImage(LayerType type) {
    return _layerImages[type];
  }

  @override
  void invalidateLayer(LayerType type) {
    _dirtyRegions[type] = Rect.largest;
  }

  @override
  void scheduleRepaint(Rect? area) {
    // 如果指定了区域，更新所有图层的脏区域
    if (area != null) {
      for (final layerType in _dirtyRegions.keys) {
        final currentDirty = _dirtyRegions[layerType];
        if (currentDirty == null) {
          _dirtyRegions[layerType] = area;
        } else {
          _dirtyRegions[layerType] = currentDirty.expandToInclude(area);
        }
      }
    }

    // 在下一帧触发重绘
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 这里可以使用通知机制触发UI更新
    });
  }

  @override
  void updateCache(CacheType type, ui.Image data) {
    final oldCache = _caches[type];
    if (oldCache != null) {
      oldCache.dispose();
    }
    _caches[type] = data;
  }

  @override
  void updateLayer(LayerType type, dynamic data) {
    if (data is ui.Image) {
      final oldImage = _layerImages[type];
      if (oldImage != null) {
        oldImage.dispose();
      }
      _layerImages[type] = data;
      _dirtyRegions.remove(type);
    }
  }
}
