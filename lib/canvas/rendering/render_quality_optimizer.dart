/// 渲染质量优化器 (Phase 2.5)
///
/// 职责:
/// 1. 动态调整渲染质量
/// 2. 根据性能提供最佳渲染设置
/// 3. 控制抗锯齿和细节级别
/// 4. 优化视觉效果和性能平衡
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 渲染质量级别
enum RenderQualityLevel {
  /// 低质量（性能优先）
  low,

  /// 中等质量（平衡）
  medium,

  /// 高质量（质量优先）
  high,

  /// 极高质量（最佳视觉效果）
  ultra,
}

/// 渲染质量优化器
class RenderQualityOptimizer {
  RenderQualitySettings _currentSettings =
      RenderQualitySettings.defaultSettings();
  double _devicePixelRatio = 1.0;
  bool _autoAdjust = true;

  /// 构造函数
  RenderQualityOptimizer() {
    // 初始化时获取设备像素比
    _devicePixelRatio = ui.window.devicePixelRatio;

    // 根据设备像素比自动调整初始质量
    _autoAdjustQuality();
  }

  /// 设置自动调整
  set autoAdjust(bool value) {
    _autoAdjust = value;
    if (_autoAdjust) {
      _autoAdjustQuality();
    }
  }

  /// 获取当前质量设置
  RenderQualitySettings get currentSettings => _currentSettings;

  /// 设置当前质量
  set currentSettings(RenderQualitySettings settings) {
    _currentSettings = settings;
  }

  /// 根据性能自动调整质量
  void adjustForPerformance(double frameRate) {
    if (!_autoAdjust) return;

    // 根据帧率调整质量
    if (frameRate < 30) {
      // 低于30FPS，降低质量以提高性能
      _currentSettings = RenderQualitySettings.low();
    } else if (frameRate > 55) {
      // 高于55FPS，有性能余量，可以提高质量
      _currentSettings = RenderQualitySettings.high();
    } else {
      // 在30-55FPS之间，使用平衡设置
      _currentSettings = RenderQualitySettings.defaultSettings();
    }
  }

  /// 应用质量设置到画笔
  void applyToPaint(Paint paint) {
    paint.isAntiAlias = _currentSettings.antiAlias;
    paint.filterQuality = _currentSettings.filterQuality;
  }

  /// 手动设置质量级别
  void setQualityLevel(RenderQualityLevel level) {
    switch (level) {
      case RenderQualityLevel.low:
        _currentSettings = RenderQualitySettings.low();
        break;
      case RenderQualityLevel.medium:
        _currentSettings = RenderQualitySettings.defaultSettings();
        break;
      case RenderQualityLevel.high:
      case RenderQualityLevel.ultra:
        _currentSettings = RenderQualitySettings.high();
        break;
    }
  }

  /// 自动调整质量
  void _autoAdjustQuality() {
    if (!_autoAdjust) return;

    // 根据设备像素比决定质量
    if (_devicePixelRatio >= 3.0) {
      // 高分辨率设备可以使用高质量
      _currentSettings = RenderQualitySettings.high();
    } else if (_devicePixelRatio <= 1.5) {
      // 低分辨率设备使用低质量
      _currentSettings = RenderQualitySettings.low();
    } else {
      // 中等分辨率设备使用默认设置
      _currentSettings = RenderQualitySettings.defaultSettings();
    }
  }
}

/// 渲染质量设置
class RenderQualitySettings {
  /// 抗锯齿级别
  final bool antiAlias;

  /// 滤镜质量
  final FilterQuality filterQuality;

  /// 曲线平滑度
  final double curveSmoothing;

  /// 纹理细节级别
  final double textureDetail;

  /// 阴影质量
  final double shadowQuality;

  /// 整体质量级别
  final RenderQualityLevel qualityLevel;

  const RenderQualitySettings({
    required this.antiAlias,
    required this.filterQuality,
    required this.curveSmoothing,
    required this.textureDetail,
    required this.shadowQuality,
    required this.qualityLevel,
  });

  /// 创建默认设置
  factory RenderQualitySettings.defaultSettings() {
    return const RenderQualitySettings(
      antiAlias: true,
      filterQuality: FilterQuality.medium,
      curveSmoothing: 1.0,
      textureDetail: 1.0,
      shadowQuality: 1.0,
      qualityLevel: RenderQualityLevel.medium,
    );
  }

  /// 创建高质量设置
  factory RenderQualitySettings.high() {
    return const RenderQualitySettings(
      antiAlias: true,
      filterQuality: FilterQuality.high,
      curveSmoothing: 1.0,
      textureDetail: 1.0,
      shadowQuality: 1.0,
      qualityLevel: RenderQualityLevel.high,
    );
  }

  /// 创建低质量设置
  factory RenderQualitySettings.low() {
    return const RenderQualitySettings(
      antiAlias: false,
      filterQuality: FilterQuality.low,
      curveSmoothing: 0.5,
      textureDetail: 0.5,
      shadowQuality: 0.5,
      qualityLevel: RenderQualityLevel.low,
    );
  }

  /// 复制并修改设置
  RenderQualitySettings copyWith({
    bool? antiAlias,
    FilterQuality? filterQuality,
    double? curveSmoothing,
    double? textureDetail,
    double? shadowQuality,
    RenderQualityLevel? qualityLevel,
  }) {
    return RenderQualitySettings(
      antiAlias: antiAlias ?? this.antiAlias,
      filterQuality: filterQuality ?? this.filterQuality,
      curveSmoothing: curveSmoothing ?? this.curveSmoothing,
      textureDetail: textureDetail ?? this.textureDetail,
      shadowQuality: shadowQuality ?? this.shadowQuality,
      qualityLevel: qualityLevel ?? this.qualityLevel,
    );
  }
}
