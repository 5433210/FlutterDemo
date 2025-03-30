import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../adapters/erase_processor_adapter.dart';
import '../controllers/erase_gesture_mixin.dart';
import '../controllers/erase_tool_controller.dart';
import '../controllers/erase_tool_controller_impl.dart';
import '../controllers/erase_tool_provider.dart';
import 'erase_layer_stack.dart';

/// 擦除工具主组件
/// 集成所有擦除功能的顶层组件
class EraseToolWidget extends StatefulWidget {
  /// 图像数据
  final ui.Image image;

  /// 初始笔刷大小
  final double initialBrushSize;

  /// 完成擦除回调
  final Function(ui.Image)? onEraseComplete;

  /// 控制器准备完成回调
  final Function(EraseToolController)? onControllerReady;

  /// 构造函数
  const EraseToolWidget({
    Key? key,
    required this.image,
    this.initialBrushSize = 10.0,
    this.onEraseComplete,
    this.onControllerReady,
  }) : super(key: key);

  @override
  State<EraseToolWidget> createState() => _EraseToolWidgetState();
}

class _EraseToolWidgetState extends State<EraseToolWidget>
    with EraseGestureMixin {
  static int _instanceCounter = 0; // 用于跟踪实例计数
  late final EraseToolController _controller;

  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _imageLayerKey = GlobalKey();
  final LayerLink _layerLink = LayerLink();
  bool _initialized = false;

  bool _initializeScheduled = false;
  final bool _firstBuildCompleted = false;
  final int _instanceId = _instanceCounter++; // 每个实例的唯一ID

  // 添加一个专用标记，标识初始化完成后的第一次构建
  bool _initialBuildComplete = false;

  @override
  EraseToolController get controller => _controller;

  @override
  Widget build(BuildContext context) {
    // 避免每次构建都打印日志，减少系统开销
    if (!_initialBuildComplete && _initialized) {
      _initialBuildComplete = true;
      print('📝 EraseToolWidget[$_instanceId] 初始化完成，首次构建');
    }

    return RepaintBoundary(
      child: EraseToolProvider(
        controller: _controller,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 仅在首次构建且未初始化时尝试初始化
            if (!_initialized && !_initializeScheduled) {
              _initializeScheduled = true;

              // 延迟到下一微任务进行初始化
              Future.microtask(() {
                if (mounted) {
                  _deferredInitialize(constraints.biggest);
                }
              });
            }

            // 使用完全透明的背景，只显示擦除界面，不显示原图像
            return AspectRatio(
              aspectRatio: widget.image.width / widget.image.height,
              child: ClipRect(
                child: Stack(
                  key: _stackKey,
                  fit: StackFit.passthrough,
                  children: [
                    // 使用RepaintBoundary隔离渲染区域
                    RepaintBoundary(
                      child: CompositedTransformTarget(
                        link: _layerLink,
                        child: RepaintBoundary(
                          key: _imageLayerKey,
                          child: EraseLayerStack(
                            image: widget.image,
                            transformationController: _transformationController,
                            onTransformationChanged:
                                _handleTransformationChanged,
                            onPanStart: handlePanStart,
                            onPanUpdate: handlePanUpdate,
                            onPanEnd: handlePanEnd,
                            onPanCancel: handlePanCancel,
                            showBackgroundImage: false, // 关键修改：不显示背景图像
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      _completeEraseProcess();
    } catch (e) {
      // 忽略销毁过程中的错误
    } finally {
      _controller.dispose();
      _transformationController.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    print('📌 EraseToolWidget[$_instanceId]: 创建新实例');
    _controller = EraseToolProvider.createController(
      initialBrushSize: widget.initialBrushSize,
    );

    // 减少初始化延迟，仅一次性调度
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_initialized && !_initializeScheduled) {
        _scheduleSingleInitialization();
      }
    });
  }

  /// 完成擦除处理并返回结果
  Future<void> _completeEraseProcess() async {
    if (widget.onEraseComplete == null) return;

    final controller = _controller as EraseToolControllerImpl;

    // 确保没有正在进行的擦除操作
    if (controller.isErasing) {
      try {
        controller.cancelErase();
      } catch (e) {
        print('Error canceling erase: $e');
      }
    }

    try {
      final processorAdapter = EraseProcessorAdapter();
      final operations = controller.operations;

      if (operations.isEmpty) {
        widget.onEraseComplete?.call(widget.image);
      } else {
        final processedImage =
            await processorAdapter.processBatch(widget.image, operations);
        widget.onEraseComplete?.call(processedImage);
      }
    } catch (e) {
      widget.onEraseComplete?.call(widget.image);
    }
  }

  /// 使用更优化的延迟初始化方法
  void _deferredInitialize(Size containerSize) {
    // 使用最短延迟，减少等待时间
    Future.microtask(() {
      if (mounted && !_initialized) {
        // 获取布局尺寸
        final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
        final size = box?.size ?? containerSize;

        if (size.width > 0 && size.height > 0) {
          // 初始化控制器
          _initializeController(size);
        } else {
          // 重置状态，下一帧重试
          _initializeScheduled = false;
        }
      }
    });
  }

  Rect? _getViewportRect() {
    try {
      // 获取Stack的全局位置和大小
      final RenderBox? stackBox =
          _stackKey.currentContext?.findRenderObject() as RenderBox?;
      if (stackBox == null) return null;

      // 获取图像层的全局位置和大小
      final RenderBox? imageBox =
          _imageLayerKey.currentContext?.findRenderObject() as RenderBox?;
      if (imageBox == null) return null;

      final imageGlobalOffset = imageBox.localToGlobal(Offset.zero);
      final stackGlobalOffset = stackBox.localToGlobal(Offset.zero);

      // 计算图像层相对于Stack的位置
      final relativeOffset = imageGlobalOffset - stackGlobalOffset;
      final imageSize = imageBox.size;

      return Rect.fromLTWH(
        relativeOffset.dx,
        relativeOffset.dy,
        imageSize.width,
        imageSize.height,
      );
    } catch (e) {
      assert(() {
        print('获取视口矩形失败: $e');
        return true;
      }());
      return null;
    }
  }

  void _handleTransformationChanged() {
    _updateViewportRect();
    final controller = _controller as EraseToolControllerImpl;
    controller.updateTransform(_transformationController.value);
  }

  void _initializeController(Size containerSize) {
    if (_initialized || !mounted) {
      _initializeScheduled = false;
      return;
    }

    try {
      print('📌 EraseToolWidget[$_instanceId]: 开始初始化控制器');

      final controller = _controller as EraseToolControllerImpl;

      // 如果已经初始化，则直接标记完成
      if (controller.isInitialized) {
        print('📌 EraseToolWidget[$_instanceId]: 控制器已初始化，无需重复');
        _initialized = true;
        _initializeScheduled = false;

        // 通知父组件控制器已准备好
        if (widget.onControllerReady != null) {
          widget.onControllerReady!(_controller);
        }
        return;
      }

      final imageSize = Size(
        widget.image.width.toDouble(),
        widget.image.height.toDouble(),
      );

      // 保证图像尺寸不为零
      if (imageSize.width <= 0 ||
          imageSize.height <= 0 ||
          containerSize.width <= 0 ||
          containerSize.height <= 0) {
        return;
      }

      final viewport = _getViewportRect();

      controller.initialize(
        originalImage: widget.image,
        transformMatrix: _transformationController.value,
        containerSize: containerSize,
        imageSize: imageSize,
        viewport: viewport,
      );

      print('📌 EraseToolWidget[$_instanceId]: 控制器初始化成功');
      _initialized = true;

      // 通知父组件控制器已准备好
      if (widget.onControllerReady != null) {
        widget.onControllerReady!(_controller);
      }
    } catch (e) {
      print('❌ EraseToolWidget[$_instanceId]: 初始化控制器失败: $e');
    } finally {
      _initializeScheduled = false;
    }
  }

  /// 确保只调度一次初始化
  void _scheduleSingleInitialization() {
    if (_initializeScheduled || _initialized) return;

    _initializeScheduled = true;
    print('📌 EraseToolWidget[$_instanceId]: 调度初始化');

    // 采用两阶段初始化，先快速获取约束尺寸，然后在下一帧获取实际渲染尺寸
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_initialized) {
        final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          _initializeController(box.size);
        } else {
          // 延迟重试，使用微任务队列避免阻塞
          _initializeScheduled = false;
          Future.microtask(() {
            if (mounted) _scheduleSingleInitialization();
          });
        }
      }
    });
  }

  void _updateViewportRect() {
    try {
      final viewport = _getViewportRect();
      if (viewport != null &&
          (_controller as EraseToolControllerImpl).isInitialized) {
        final controller = _controller as EraseToolControllerImpl;
        controller.updateViewport(viewport);
      }
    } catch (e) {
      // 忽略非关键错误
    }
  }
}
