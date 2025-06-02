// filepath: lib/canvas/integration/practice_canvas_adapter.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/widgets/practice/practice_edit_controller.dart';
import '../compatibility/canvas_controller_adapter.dart';
import '../ui/canvas_widget.dart';

/// 练习Canvas适配器 - 将新Canvas架构集成到现有练习编辑系统
class PracticeCanvasAdapter extends ConsumerStatefulWidget {
  final PracticeEditController controller;
  final bool isPreviewMode;
  final TransformationController transformationController;

  const PracticeCanvasAdapter({
    super.key,
    required this.controller,
    required this.isPreviewMode,
    required this.transformationController,
  });

  @override
  ConsumerState<PracticeCanvasAdapter> createState() =>
      _PracticeCanvasAdapterState();
}

/// Canvas配置提供者 - 为练习编辑提供Canvas配置
class PracticeCanvasConfiguration {
  static CanvasConfiguration forCharacterPractice({
    bool isPreviewMode = false,
    Size? canvasSize,
  }) {
    return CanvasConfiguration(
      size: canvasSize ?? const Size(600, 600),
      backgroundColor: Colors.white,
      showGrid: true,
      gridSize: 25.0, // 字帖网格稍大
      gridColor: const Color(0xFFD0D0D0),
      enableGestures: !isPreviewMode,
      enablePerformanceMonitoring: true,
    );
  }

  static CanvasConfiguration forPracticeEdit({
    bool isPreviewMode = false,
    Size? canvasSize,
  }) {
    return CanvasConfiguration(
      size: canvasSize ?? const Size(800, 600),
      backgroundColor: Colors.white,
      showGrid: !isPreviewMode, // 预览模式不显示网格
      gridSize: 20.0,
      gridColor: const Color(0xFFE0E0E0),
      enableGestures: !isPreviewMode,
      enablePerformanceMonitoring: true,
    );
  }
}

class _PracticeCanvasAdapterState extends ConsumerState<PracticeCanvasAdapter> {
  late final CanvasControllerAdapter _canvasAdapter;
  late final CanvasConfiguration _canvasConfiguration;

  @override
  Widget build(BuildContext context) {
    return CanvasWidget(
      configuration: _canvasConfiguration,
      controller: _canvasAdapter,
      transformationController: widget.transformationController,
      isPreviewMode: widget.isPreviewMode,
    );
  }

  @override
  void dispose() {
    _canvasAdapter.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeAdapter();
  }

  void _initializeAdapter() {
    // 创建Canvas适配器
    _canvasAdapter = CanvasControllerAdapter();

    // 创建Canvas配置
    _canvasConfiguration = CanvasConfiguration(
      size: const Size(800, 600), // 默认大小，可以根据需要调整
      backgroundColor: Colors.white,
      showGrid: true, // 练习模式显示网格
      gridSize: 20.0,
      gridColor: const Color(0xFFE0E0E0),
      enableGestures: !widget.isPreviewMode, // 预览模式禁用手势
      enablePerformanceMonitoring: true,
    );
  }
}
