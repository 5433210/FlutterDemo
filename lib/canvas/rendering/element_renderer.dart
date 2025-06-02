/// Canvas渲染系统 - 元素渲染器基类 (Phase 2.5)
///
/// 职责:
/// 1. 定义所有渲染器的基本接口
/// 2. 提供渲染生命周期管理
/// 3. 集成缓存和优化策略
/// 4. 支持变换和选择状态
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/interfaces/element_data.dart';

/// 缓存策略枚举
enum CachePolicy {
  /// 不使用缓存
  none,

  /// 自动缓存（根据元素特性和上下文决定）
  auto,

  /// 强制缓存
  force,
}

/// 渲染器扩展点
abstract class ElementRenderer<T extends ElementData> {
  /// 元素类型
  String get elementType;

  /// 是否已初始化
  bool get isInitialized;

  /// 是否支持缓存
  bool get supportsCaching;

  /// 是否支持GPU加速
  bool get supportsGpuAcceleration;

  /// 检查是否支持指定元素
  bool canRender(ElementData element);

  /// 清除缓存
  void clearCache([String? elementId]);

  /// 释放资源
  void dispose();

  /// 获取绘制该元素需要的估计时间（毫秒）
  /// 用于渲染队列优先级计算
  int estimateRenderTime(T element, RenderQuality quality);

  /// 获取元素的边界框
  Rect getBounds(T element, [Matrix4? transform]);

  /// 获取元素的命中测试路径
  Path getHitTestPath(T element, [Matrix4? transform]);

  /// 初始化渲染器
  Future<void> initialize();

  /// 预渲染元素（用于缓存）
  Future<ui.Image?> prerender(T element, RenderContext context);

  /// 渲染元素
  void render(T element, RenderContext context);

  /// 渲染元素的选择状态
  void renderSelection(T element, RenderContext context);

  /// 更新缓存
  void updateCache(T element);
}

/// 渲染上下文
/// 包含渲染一个元素所需的所有信息
class RenderContext {
  /// 画布
  final Canvas canvas;

  /// 尺寸
  final Size size;

  /// 设备像素比
  final double devicePixelRatio;

  /// 选择状态
  final bool isSelected;

  /// 悬停状态
  final bool isHovered;

  /// 变换矩阵
  final Matrix4? transform;

  /// 剪裁区域
  final Rect? clipRect;

  /// 渲染质量
  final RenderQuality quality;

  /// 缓存策略
  final CachePolicy cachePolicy;

  /// 当前时间戳
  final Duration timestamp;

  /// 自定义属性
  final Map<String, dynamic> properties;

  const RenderContext({
    required this.canvas,
    required this.size,
    this.devicePixelRatio = 1.0,
    this.isSelected = false,
    this.isHovered = false,
    this.transform,
    this.clipRect,
    this.quality = RenderQuality.normal,
    this.cachePolicy = CachePolicy.auto,
    required this.timestamp,
    this.properties = const {},
  });

  /// 创建修改后的渲染上下文
  RenderContext copyWith({
    Canvas? canvas,
    Size? size,
    double? devicePixelRatio,
    bool? isSelected,
    bool? isHovered,
    Matrix4? transform,
    Rect? clipRect,
    RenderQuality? quality,
    CachePolicy? cachePolicy,
    Duration? timestamp,
    Map<String, dynamic>? properties,
  }) {
    return RenderContext(
      canvas: canvas ?? this.canvas,
      size: size ?? this.size,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      isSelected: isSelected ?? this.isSelected,
      isHovered: isHovered ?? this.isHovered,
      transform: transform ?? this.transform,
      clipRect: clipRect ?? this.clipRect,
      quality: quality ?? this.quality,
      cachePolicy: cachePolicy ?? this.cachePolicy,
      timestamp: timestamp ?? this.timestamp,
      properties: properties ?? this.properties,
    );
  }
}

/// 渲染质量枚举
enum RenderQuality {
  /// 低质量 - 快速渲染，适用于拖拽和动画
  low,

  /// 普通质量 - 标准渲染
  normal,

  /// 高质量 - 用于高DPI显示和导出
  high,
}
