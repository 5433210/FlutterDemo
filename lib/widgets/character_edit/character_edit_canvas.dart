import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/services/image/character_image_processor.dart';
import '../../domain/models/character/detected_outline.dart';
import '../../domain/models/character/path_info.dart';
import '../../domain/models/character/processing_options.dart';
import '../../presentation/providers/character/erase_providers.dart';
import '../../utils/debug/debug_flags.dart';
import '../../utils/focus/focus_persistence.dart';
import '../../utils/image/image_utils.dart';
import 'layers/erase_layer_stack.dart';

/// 编辑画布组件
class CharacterEditCanvas extends ConsumerStatefulWidget {
  final ui.Image image;
  final bool showOutline;
  final bool invertMode;
  final bool imageInvertMode;
  final Function(Offset)? onEraseStart;
  final Function(Offset, Offset)? onEraseUpdate;
  final Function()? onEraseEnd;
  final double brushSize;
  final Color brushColor;

  const CharacterEditCanvas({
    Key? key,
    required this.image,
    this.showOutline = false,
    this.invertMode = false,
    this.imageInvertMode = false,
    this.onEraseStart,
    this.onEraseUpdate,
    this.onEraseEnd,
    this.brushSize = 10.0,
    required this.brushColor,
  }) : super(key: key);

  @override
  ConsumerState<CharacterEditCanvas> createState() =>
      CharacterEditCanvasState();
}

class CharacterEditCanvasState extends ConsumerState<CharacterEditCanvas>
    with FocusPersistenceMixin {
  static const _altToggleDebounce = Duration(milliseconds: 100);
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey<EraseLayerStackState> _layerStackKey = GlobalKey();

  bool _isProcessing = false;
  bool _isAltKeyPressed = false;
  DateTime _lastAltToggleTime = DateTime.now();
  DetectedOutline? _outline;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode && DebugFlags.enableEraseDebug) {
      print(
          '画布构建 - showOutline: ${widget.showOutline}, isProcessing: $_isProcessing');
    }

    // 监听状态变化
    final eraseState = ref.watch(eraseStateProvider);
    final pathRenderData = ref.watch(pathRenderDataProvider);

    // 监听轮廓显示状态变化
    final showContour =
        ref.watch(eraseStateProvider.select((state) => state.showContour));

    // When contour state changes, force an update
    ref.listen(eraseStateProvider.select((state) => state.showContour),
        (previous, current) {
      if (current) {
        print('轮廓状态变化，强制更新轮廓显示，当前值: $current');
        _scheduleOutlineUpdate();
      }
    });

    // 监听路径数据变化，当路径变化且轮廓显示开启时更新轮廓
    ref.listen(pathRenderDataProvider, (previous, current) {
      // 只有在轮廓显示开启且路径有变化时才更新
      final showContour = ref.read(eraseStateProvider).showContour;
      if (showContour) {
        // 比较路径列表长度，检测是否有变化
        final prevPaths = previous?.completedPaths ?? [];
        final currentPaths = current.completedPaths ?? [];
        if (prevPaths.length != currentPaths.length) {
          print('路径变化检测：从 ${prevPaths.length} 到 ${currentPaths.length} 个路径');
          _scheduleOutlineUpdate();
        }
      }
    });

    // 监听图像反转状态变化，在需要时更新轮廓
    ref.listen(eraseStateProvider.select((state) => state.imageInvertMode),
        (previous, current) {
      if (previous != current && ref.read(eraseStateProvider).showContour) {
        print('图像反转状态变化，强制更新轮廓');
        // 延迟处理，确保状态更新完成
        Future.delayed(const Duration(milliseconds: 100), () {
          _scheduleOutlineUpdate();
        });
      }
    });

    return Focus(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!focusNode.hasFocus) focusNode.requestFocus();
        },
        child: InteractiveViewer(
          transformationController: _transformationController,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.1,
          maxScale: 5.0,
          panEnabled: _isAltKeyPressed, // 仅在Alt键按下时启用平移
          child: SizedBox(
            width: widget.image.width.toDouble(),
            height: widget.image.height.toDouble(),
            child: EraseLayerStack(
              key: _layerStackKey,
              image: widget.image,
              transformationController: _transformationController,
              onEraseStart: _handleEraseStart,
              onEraseUpdate: _handleEraseUpdate,
              onEraseEnd: _handleEraseEnd,
              altKeyPressed: _isAltKeyPressed,
              brushSize: widget.brushSize,
              brushColor: widget.brushColor,
              imageInvertMode: widget.imageInvertMode,
              showOutline: widget.showOutline,
              onPan: (delta) {
                // Alt键按下时的平移逻辑
                if (_isAltKeyPressed) {
                  final matrix = _transformationController.value.clone();
                  matrix.translate(delta.dx, delta.dy);
                  _transformationController.value = matrix;
                }
              },
              onTap: _handleTap, // 添加单击回调
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    focusNode.removeListener(_onFocusChange);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitToScreen();
      if (widget.showOutline) {
        _scheduleOutlineUpdate();
      }
    });
  }

  void setOutline(DetectedOutline? outline) {
    if (_layerStackKey.currentState != null) {
      _layerStackKey.currentState!.setOutline(outline);
    }
  }

  void updateCurrentPath(PathInfo? path) {
    // 不再直接更新EraseLayerStack，而是通过Provider更新
    // 仅用于保持兼容性
  }

  void updateDirtyRect(Rect? rect) {
    // 不再直接更新EraseLayerStack，而是通过Provider更新
    // 仅用于保持兼容性
  }

  void updatePaths(List<PathInfo> paths) {
    // 需要保留此方法以保持兼容性，但实际功能通过Provider实现
    if (_layerStackKey.currentState != null) {
      _layerStackKey.currentState!.updatePaths(paths);
    }
  }

  // 添加一个辅助方法来从Path对象中提取点，确保精确提取
  List<Offset> _extractPointsFromPath(Path path) {
    List<Offset> points = [];
    try {
      // 提取路径的每个点，使用更密集的采样确保准确性
      for (final metric in path.computeMetrics()) {
        // 对长度为0的度量进行特殊处理
        if (metric.length == 0) {
          // 这可能是单点的圆形路径，尝试获取路径边界的中心点
          final pathBounds = path.getBounds();
          points.add(pathBounds.center);
          continue;
        }

        // 根据路径长度计算步长，确保点的密度适中
        final stepLength = math.max(1.0, metric.length / 100);

        for (double distance = 0;
            distance <= metric.length;
            distance += stepLength) {
          final tangent = metric.getTangentForOffset(distance);
          if (tangent != null) {
            points.add(tangent.position);
          }
        }

        // 确保添加终点
        if (metric.length > 0) {
          final lastTangent = metric.getTangentForOffset(metric.length);
          if (lastTangent != null) {
            points.add(lastTangent.position);
          }
        }
      }

      // 确保提取了足够的点
      if (points.isEmpty) {
        print('警告：从路径中未提取到点，尝试使用路径边界');
        final bounds = path.getBounds();
        points.add(bounds.center);
      } else {
        print('从路径中提取了 ${points.length} 个点');
      }
    } catch (e) {
      print('提取路径点出错: $e');
      // 如果无法提取，尝试至少获取路径边界
      try {
        final bounds = path.getBounds();
        points.add(bounds.center);
        print('提取失败，使用路径中心点代替');
      } catch (e2) {
        print('无法获取路径边界: $e2');
      }
    }
    return points;
  }

  void _fitToScreen() {
    if (!mounted) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Size viewportSize = renderBox.size;
    final double imageWidth = widget.image.width.toDouble();
    final double imageHeight = widget.image.height.toDouble();

    final double scaleX = viewportSize.width / imageWidth;
    final double scaleY = viewportSize.height / imageHeight;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    final double dx = (viewportSize.width - imageWidth * scale) / 2;
    final double dy = (viewportSize.height - imageHeight * scale) / 2;

    final Matrix4 matrix = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale, scale);

    _transformationController.value = matrix;
  }

  void _handleEraseEnd() {
    // 首先调用原始回调
    widget.onEraseEnd?.call();

    // Alt键按下时不处理擦除
    if (!_isAltKeyPressed) {
      // 完成当前路径
      ref.read(eraseStateProvider.notifier).completePath();
      // 不再在这里调用轮廓更新，而是依赖pathRenderDataProvider的监听
      // 路径变化时会自动触发轮廓更新
    }
  }

  void _handleEraseStart(Offset position) {
    // 首先调用原始回调
    widget.onEraseStart?.call(position);

    // Alt键按下时不处理擦除
    if (!_isAltKeyPressed) {
      // 更新擦除状态
      ref.read(eraseStateProvider.notifier).startPath(position);
    }
  }

  void _handleEraseUpdate(Offset position, Offset delta) {
    // 首先调用原始回调
    widget.onEraseUpdate?.call(position, delta);

    // Alt键按下时处理平移
    if (_isAltKeyPressed) {
      final matrix = _transformationController.value.clone();
      matrix.translate(delta.dx, delta.dy);
      _transformationController.value = matrix;
    } else {
      // 更新擦除状态
      ref.read(eraseStateProvider.notifier).updatePath(position);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.alt ||
        event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight) {
      final now = DateTime.now();
      bool isDown;

      if (event is KeyDownEvent) {
        isDown = true;
      } else if (event is KeyUpEvent) {
        isDown = false;
      } else if (event is KeyRepeatEvent) {
        isDown = _isAltKeyPressed;
        return KeyEventResult.handled;
      } else {
        return KeyEventResult.ignored;
      }

      if (_isAltKeyPressed != isDown &&
          now.difference(_lastAltToggleTime) > _altToggleDebounce) {
        setState(() {
          _isAltKeyPressed = isDown;
          _lastAltToggleTime = now;
        });
      }

      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handleTap(Offset position) {
    // Alt键按下时不处理擦除
    if (_isAltKeyPressed) return;

    // 通过Provider执行单击擦除
    ref.read(eraseStateProvider.notifier).startPath(position);
    ref.read(eraseStateProvider.notifier).completePath();

    // 触发回调
    widget.onEraseStart?.call(position);
    widget.onEraseEnd?.call();
  }

  void _onFocusChange() {
    if (!focusNode.hasFocus && _isAltKeyPressed) {
      setState(() {
        _isAltKeyPressed = false;
      });
    }
  }

  void _scheduleOutlineUpdate() {
    if (_isProcessing) {
      print('轮廓正在处理中，跳过更新');
      return;
    }

    // 添加延迟，确保路径状态已经完全更新
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      final showContour = ref.read(eraseStateProvider).showContour;
      print(
          '准备更新轮廓, showContour=$showContour, 路径数量=${ref.read(pathRenderDataProvider).completedPaths.length ?? 0}');

      if (showContour) {
        _updateOutline();
      }
    });
  }

  Future<void> _updateOutline() async {
    setState(() => _isProcessing = true);

    if (kDebugMode) {
      print('开始处理轮廓...');
    }

    try {
      final imageBytes = await ImageUtils.imageToBytes(widget.image);
      if (imageBytes == null) {
        throw Exception('无法将图像转换为字节数组');
      }

      final imageProcessor = ref.read(characterImageProcessorProvider);
      final pathRenderData = ref.read(pathRenderDataProvider);
      final eraseState = ref.read(eraseStateProvider);

      // 添加详细的日志，确认擦除路径的颜色信息
      if (kDebugMode) {
        print('准备处理轮廓，路径数量: ${pathRenderData.completedPaths.length}');
        print(
            '图像反转状态: ${eraseState.imageInvertMode}, 笔刷反转状态: ${eraseState.isReversed}');
        print('使用的笔刷颜色: ${eraseState.brushColor}');

        // 检查路径中存储的颜色值
        int blackCount = 0;
        int whiteCount = 0;
        for (final path in pathRenderData.completedPaths) {
          if (path.brushColor == Colors.black)
            blackCount++;
          else if (path.brushColor == Colors.white) whiteCount++;
        }
        print('路径颜色统计: 黑色=$blackCount, 白色=$whiteCount');
      }

      // 确保ProcessingOptions与当前的EraseState一致
      final options = ProcessingOptions(
        // 修正这里的反转标志，使用与eraseState一致的逻辑
        inverted: eraseState.imageInvertMode,
        threshold: 128.0,
        noiseReduction: 0.5,
        showContour: true,
      );

      print(
          '轮廓处理选项: inverted=${options.inverted}, showContour=${options.showContour}');

      final fullImageRect = Rect.fromLTWH(
        0,
        0,
        widget.image.width.toDouble(),
        widget.image.height.toDouble(),
      );

      // 确保erasePaths里的brushColor与当前路径中存储的颜色一致
      List<Map<String, dynamic>> erasePaths = [];
      if (pathRenderData.completedPaths.isNotEmpty) {
        erasePaths = pathRenderData.completedPaths.map((p) {
          // 提取高密度的点集，确保擦除效果精确
          final points = _extractPointsFromPath(p.path);

          // 确保有足够的点来表示路径
          if (points.length < 5 && p.path.computeMetrics().isNotEmpty) {
            print('警告：路径点数过少(${points.length})，可能不精确');
          }

          return <String, dynamic>{
            'brushSize': p.brushSize,
            'brushColor': p.brushColor.value,
            'points': points,
            // 添加一个路径ID，便于调试
            'pathId': p.hashCode.toString(),
          };
        }).toList();

        print(
            '准备了 ${erasePaths.length} 条擦除路径，总点数: ${erasePaths.fold<int>(0, (sum, path) => sum + (path['points'] as List).length)}');
      }

      print('开始处理轮廓，传递 ${erasePaths.length} 个路径...');
      final result = await imageProcessor.previewProcessing(
        imageBytes,
        fullImageRect,
        options,
        erasePaths,
      );
      print('轮廓处理完成');

      if (mounted) {
        setState(() {
          _outline = result.outline;
          _isProcessing = false;
          if (_outline != null) {
            print('轮廓更新成功 - 包含 ${_outline!.contourPoints.length} 条路径');
            // 额外检查轮廓对象的位置信息
            final bounds = _outline!.boundingRect;
            print(
                '轮廓边界: $bounds, 图像大小: ${widget.image.width}x${widget.image.height}');
          } else {
            print('警告: 未生成轮廓数据');
          }
        });

        // 确保轮廓被设置和显示
        if (_layerStackKey.currentState != null) {
          final showContour = ref.read(eraseStateProvider).showContour;
          print('传递轮廓数据到 EraseLayerStack, 显示=$showContour');
          _layerStackKey.currentState!
              .setOutline(showContour ? _outline : null);
        } else {
          print('警告: EraseLayerStack state 不可用');
        }
      }
    } catch (e) {
      print('轮廓检测失败: $e');
      if (kDebugMode) {
        print('错误堆栈: ${StackTrace.current}');
      }
      setState(() => _isProcessing = false);
    }
  }
}
