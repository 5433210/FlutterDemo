import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/erase_operation.dart';

/// 渲染缓存
/// 负责管理图像缓存和优化渲染性能
class RenderCache {
  /// 静态缓存
  ui.Image? _staticCache;

  /// 动态缓存
  ui.Image? _dynamicCache;

  /// 是否需要重建缓存
  bool _isDirty = true;

  /// 缓存的操作
  final List<EraseOperation> _cachedOperations = [];

  /// 最近添加的操作
  final List<EraseOperation> _recentOperations = [];

  /// 获取动态缓存
  ui.Image? get dynamicCache => _dynamicCache;

  /// 设置动态缓存
  set dynamicCache(ui.Image? cache) {
    if (_dynamicCache != null && _dynamicCache != cache) {
      _dynamicCache!.dispose();
    }
    _dynamicCache = cache;
  }

  /// 是否需要重建缓存
  bool get isDirty => _isDirty;

  /// 获取静态缓存
  ui.Image? get staticCache => _staticCache;

  /// 设置静态缓存
  set staticCache(ui.Image? cache) {
    if (_staticCache != null && _staticCache != cache) {
      _staticCache!.dispose();
    }
    _staticCache = cache;
  }

  /// 添加显示操作
  void addDisplayOperation(EraseOperation operation) {
    _recentOperations.add(operation);

    // 如果最近操作太多，转移到缓存操作中
    if (_recentOperations.length > 5) {
      _cachedOperations.addAll(_recentOperations);
      _recentOperations.clear();
      _isDirty = true;
    }
  }

  /// 清除缓存
  void clearCache() {
    if (_staticCache != null) {
      _staticCache!.dispose();
      _staticCache = null;
    }

    if (_dynamicCache != null) {
      _dynamicCache!.dispose();
      _dynamicCache = null;
    }

    _cachedOperations.clear();
    _recentOperations.clear();
    _isDirty = true;
  }

  /// 释放资源
  void dispose() {
    clearCache();
  }

  /// 获取所有操作
  List<EraseOperation> getAllOperations() {
    return [..._cachedOperations, ..._recentOperations];
  }

  /// 获取最近的操作
  List<EraseOperation> getRecentOperations() {
    return List.unmodifiable(_recentOperations);
  }

  /// 使缓存失效
  void invalidateCache() {
    _isDirty = true;
  }

  /// 更新动态缓存
  Future<void> updateDynamicCache(
    ui.Image baseImage,
    List<Offset> currentPoints,
    double brushSize,
  ) async {
    // 实现离屏渲染来更新动态缓存
    // 这里需要实现具体的渲染逻辑
  }

  /// 更新静态缓存
  Future<void> updateStaticCache(ui.Image originalImage) async {
    if (!_isDirty && _staticCache != null) return;

    // 实现离屏渲染来更新静态缓存
    // 这里需要实现具体的渲染逻辑

    _isDirty = false;
  }
}
