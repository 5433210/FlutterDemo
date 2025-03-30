import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 缓存层基类
/// 提供基础的缓存和绘制逻辑
abstract class CachedLayer extends StatefulWidget {
  const CachedLayer({super.key});
}

/// 缓存层状态基类
abstract class CachedLayerState<T extends CachedLayer> extends State<T> {
  /// 图层缓存
  ui.Image? _cachedImage;

  /// 脏区域
  Rect? _dirtyRegion;

  /// 是否需要重建
  bool _needsRebuild = true;

  /// 获取缓存图像
  ui.Image? get cachedImage => _cachedImage;

  /// 设置缓存图像
  set cachedImage(ui.Image? value) {
    if (_cachedImage != value) {
      _cachedImage?.dispose();
      _cachedImage = value;
      _needsRebuild = false;
      _dirtyRegion = null;
    }
  }

  /// 获取脏区域
  Rect? get dirtyRegion => _dirtyRegion;

  /// 检查是否需要重建
  bool get needsRebuild => _needsRebuild;

  @override
  void dispose() {
    _cachedImage?.dispose();
    super.dispose();
  }

  /// 标记脏区域
  void markDirty(Rect region) {
    if (_dirtyRegion == null) {
      _dirtyRegion = region;
    } else {
      _dirtyRegion = _dirtyRegion!.expandToInclude(region);
    }
    setState(() {});
  }

  /// 标记为需要重建
  void markNeedsRebuild() {
    _needsRebuild = true;
    setState(() {});
  }

  /// 重建缓存
  Future<void> rebuildCache();

  /// 更新缓存
  Future<void> updateCache() async {
    if (_needsRebuild || _cachedImage == null) {
      await rebuildCache();
    } else if (_dirtyRegion != null) {
      await updateDirtyRegion(_dirtyRegion!);
      _dirtyRegion = null;
    }
  }

  /// 更新脏区域
  Future<void> updateDirtyRegion(Rect region);
}
