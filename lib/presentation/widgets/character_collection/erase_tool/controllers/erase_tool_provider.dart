import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/erase_mode.dart';
import 'erase_tool_controller.dart';
import 'erase_tool_controller_impl.dart';
import 'render_manager_impl.dart';

/// EraseToolController的Provider
final eraseToolProvider =
    Provider.autoDispose.family<EraseToolController, EraseToolConfig>(
  (ref, config) {
    // 创建渲染管理器
    final renderManager = RenderManagerImpl();

    // 预先设置图像尺寸（如果有）
    if (config.imageSize != null) {
      renderManager.prepare(config.imageSize!);
    }

    // 创建控制器
    final controller = EraseToolControllerImpl(
      renderManager: renderManager,
      initialBrushSize: config.initialBrushSize,
      initialMode: config.initialMode,
    );

    // 在Provider销毁时释放资源
    ref.onDispose(() {
      controller.dispose();
      renderManager.dispose();
    });

    return controller;
  },
);

/// 擦除工具配置
class EraseToolConfig {
  /// 初始笔刷大小
  final double initialBrushSize;

  /// 初始擦除模式
  final EraseMode initialMode;

  /// 图像尺寸
  final Size? imageSize;

  /// 是否启用性能优化
  final bool enableOptimizations;

  const EraseToolConfig({
    this.initialBrushSize = 20.0,
    this.initialMode = EraseMode.normal,
    this.imageSize,
    this.enableOptimizations = true,
  });

  /// 根据图像尺寸创建配置
  factory EraseToolConfig.fromImage({
    required Size imageSize,
    double? initialBrushSize,
    EraseMode? initialMode,
  }) {
    return EraseToolConfig(
      imageSize: imageSize,
      initialBrushSize: initialBrushSize ?? 20.0,
      initialMode: initialMode ?? EraseMode.normal,
    );
  }

  @override
  int get hashCode => Object.hash(
        initialBrushSize,
        initialMode,
        imageSize,
        enableOptimizations,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EraseToolConfig &&
        other.initialBrushSize == initialBrushSize &&
        other.initialMode == initialMode &&
        other.imageSize == imageSize &&
        other.enableOptimizations == enableOptimizations;
  }

  /// 创建新的配置实例
  EraseToolConfig copyWith({
    double? initialBrushSize,
    EraseMode? initialMode,
    Size? imageSize,
    bool? enableOptimizations,
  }) {
    return EraseToolConfig(
      initialBrushSize: initialBrushSize ?? this.initialBrushSize,
      initialMode: initialMode ?? this.initialMode,
      imageSize: imageSize ?? this.imageSize,
      enableOptimizations: enableOptimizations ?? this.enableOptimizations,
    );
  }
}
