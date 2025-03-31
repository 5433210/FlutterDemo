import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/erase_tool_controller.dart';
import '../controllers/erase_tool_provider.dart';
import '../models/erase_mode.dart';
import 'layers/background_layer.dart';
import 'layers/preview_layer.dart';
import 'layers/ui_layer.dart';

/// 擦除工具Widget
class EraseToolWidget extends ConsumerStatefulWidget {
  /// 原始图像
  final ui.Image image;

  /// 变换控制器
  final TransformationController transformationController;

  /// 初始笔刷大小
  final double initialBrushSize;

  /// 初始擦除模式
  final EraseMode initialMode;

  /// 大小变化回调
  final void Function(Size)? onSizeChanged;

  /// 控制器就绪回调
  final void Function(EraseToolController)? onControllerReady;

  /// 擦除完成回调
  final void Function(ui.Image)? onEraseComplete;

  const EraseToolWidget({
    Key? key,
    required this.image,
    required this.transformationController,
    this.initialBrushSize = 20.0,
    this.initialMode = EraseMode.normal,
    this.onSizeChanged,
    this.onControllerReady,
    this.onEraseComplete,
  }) : super(key: key);

  @override
  ConsumerState<EraseToolWidget> createState() => _EraseToolWidgetState();
}

class _EraseToolWidgetState extends ConsumerState<EraseToolWidget> {
  // 节流控制
  static const _updateThrottleMs = 16; // 约60fps
  late final EraseToolConfig _config;
  late final FocusNode _focusNode;
  Size? _currentSize;
  bool _isErasing = false;
  bool _isProcessingResult = false;

  DateTime? _lastUpdate;

  @override
  Widget build(BuildContext context) {
    // 使用Provider获取控制器
    final controller = ref.watch(eraseToolProvider(_config));

    // 监听控制器就绪状态
    ref.listen(eraseToolProvider(_config), (previous, next) {
      if (widget.onControllerReady != null) {
        widget.onControllerReady!(next);
      }
    });

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          _focusNode.requestFocus(); // 失去焦点时自动重新请求
        }
      },
      child: GestureDetector(
        onTapDown: (_) => _focusNode.requestFocus(),
        behavior: HitTestBehavior.opaque,
        child: RepaintBoundary(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);

              // 通知容器尺寸变化
              _handleSizeChanged(size);

              return Stack(
                fit: StackFit.expand,
                children: [
                  // 背景图层
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: BackgroundLayer(
                        image: widget.image,
                        transformationController:
                            widget.transformationController,
                      ),
                    ),
                  ),

                  // 预览图层
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: PreviewLayer(
                        transformationController:
                            widget.transformationController,
                        brushSize: widget.initialBrushSize,
                        operations: controller.operations,
                        currentOperation: controller.currentOperation,
                        scale: widget.transformationController.value
                            .getMaxScaleOnAxis(),
                      ),
                    ),
                  ),

                  // UI图层
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: UILayer(
                        transformationController:
                            widget.transformationController,
                        eraseMode: true,
                        brushSize: widget.initialBrushSize,
                        onPanStart: (details) {
                          _isErasing = true;
                          controller.startErase(details.localPosition);
                        },
                        onPanUpdate: (details) {
                          if (_isErasing) {
                            controller.continueErase(details.localPosition);
                          }
                        },
                        onPanEnd: (details) {
                          if (_isErasing) {
                            controller.endErase();
                            _handleEraseComplete();
                          }
                        },
                        onPanCancel: () {
                          if (_isErasing) {
                            controller.cancelErase();
                            _isErasing = false;
                          }
                        },
                      ),
                    ),
                  ),

                  // 加载指示器
                  if (_isProcessingResult)
                    const Positioned.fill(
                      child: RepaintBoundary(
                        child: ColoredBox(
                          color: Color(0x80FFFFFF),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    final imageSize = Size(
      widget.image.width.toDouble(),
      widget.image.height.toDouble(),
    );

    _config = EraseToolConfig(
      initialBrushSize: widget.initialBrushSize,
      initialMode: widget.initialMode,
      imageSize: imageSize,
    );

    // 设置初始画布尺寸
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(eraseToolProvider(_config));
      controller.setCanvasSize(imageSize);
      _focusNode.requestFocus(); // 请求焦点
    });
  }

  /// 处理擦除完成
  Future<void> _handleEraseComplete() async {
    if (!_isErasing || _isProcessingResult) return;
    _isErasing = false;
    _isProcessingResult = true;

    try {
      // 获取最终图像并通知
      if (widget.onEraseComplete != null) {
        final controller = ref.read(eraseToolProvider(_config));
        final resultImage = await controller.getResultImage();
        if (resultImage != null && mounted) {
          widget.onEraseComplete!(resultImage);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingResult = false;
        });
      }
    }
  }

  /// 处理大小变化
  void _handleSizeChanged(Size size) {
    if (_currentSize == size) return;

    // 节流控制
    final now = DateTime.now();
    if (_lastUpdate != null &&
        now.difference(_lastUpdate!).inMilliseconds < _updateThrottleMs) {
      return;
    }
    _lastUpdate = now;

    _currentSize = size;
    widget.onSizeChanged?.call(size);
  }
}
