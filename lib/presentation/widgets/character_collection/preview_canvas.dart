import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 擦除绘制器
class ErasePainter extends CustomPainter {
  final List<Offset> points;
  final double brushSize;
  final Color color;

  ErasePainter({
    required this.points,
    required this.brushSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // 创建路径
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // 绘制路径
    canvas.drawPath(path, paint);

    // 在每个点画圆点，使线条更平滑
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, brushSize / 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ErasePainter oldDelegate) {
    return points != oldDelegate.points ||
        brushSize != oldDelegate.brushSize ||
        color != oldDelegate.color;
  }
}

class PreviewCanvas extends ConsumerStatefulWidget {
  final String regionId;
  final bool isInverted;
  final bool showOutline;
  final double zoomLevel;
  final bool isErasing;
  final double brushSize;
  final Function(List<Offset>) onErasePointsChanged;

  const PreviewCanvas({
    Key? key,
    required this.regionId,
    required this.isInverted,
    required this.showOutline,
    required this.zoomLevel,
    required this.isErasing,
    required this.brushSize,
    required this.onErasePointsChanged,
  }) : super(key: key);

  @override
  ConsumerState<PreviewCanvas> createState() => _PreviewCanvasState();
}

class _PreviewCanvasState extends ConsumerState<PreviewCanvas> {
  // 变换控制器
  final TransformationController _transformationController =
      TransformationController();

  // 擦除状态
  final List<Offset> _currentErasePoints = [];
  bool _isErasing = false;

  @override
  Widget build(BuildContext context) {
    // 使用FutureBuilder加载并显示字符图像
    return FutureBuilder<Uint8List?>(
      future: _loadCharacterImage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  '加载图像失败: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Text('无图像数据'),
          );
        }

        // 图像加载成功
        return Stack(
          children: [
            // 预览容器
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: Center(
                    child: Image.memory(
                      snapshot.data!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            ),

            // 擦除层 - 仅在擦除模式下显示
            if (widget.isErasing)
              Positioned.fill(
                child: GestureDetector(
                  onPanStart: _handleErasePanStart,
                  onPanUpdate: _handleErasePanUpdate,
                  onPanEnd: _handleErasePanEnd,
                  child: CustomPaint(
                    painter: ErasePainter(
                      points: _currentErasePoints,
                      brushSize: widget.brushSize,
                      color: Colors.red.withOpacity(0.6),
                    ),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),

            // 轮廓层 - 仅在显示轮廓时显示
            if (widget.showOutline)
              Positioned.fill(
                child: FutureBuilder<String?>(
                  future: _loadOutlineSvg(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      // 在实际应用中，这里应该使用SvgPicture显示SVG轮廓
                      return Center(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.blue,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Text(
                            'SVG Outline',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  void didUpdateWidget(PreviewCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 缩放级别变化时更新变换
    if (widget.zoomLevel != oldWidget.zoomLevel) {
      _updateTransform();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // 处理擦除结束
  void _handleErasePanEnd(DragEndDetails details) {
    if (!_isErasing || _currentErasePoints.isEmpty) return;

    // 通知擦除点变化
    widget.onErasePointsChanged(_currentErasePoints);

    setState(() {
      _isErasing = false;
      _currentErasePoints.clear();
    });
  }

  // 处理擦除开始
  void _handleErasePanStart(DragStartDetails details) {
    if (!widget.isErasing) return;

    setState(() {
      _isErasing = true;
      _currentErasePoints.clear();
      _currentErasePoints.add(details.localPosition);
    });
  }

  // 处理擦除更新
  void _handleErasePanUpdate(DragUpdateDetails details) {
    if (!_isErasing) return;

    setState(() {
      _currentErasePoints.add(details.localPosition);
    });
  }

  // 加载字符图像
  Future<Uint8List?> _loadCharacterImage() async {
    try {
      // 从仓库加载图像
      // 在实际应用中，这里应该调用字符服务加载处理后的图像
      // return await ref.read(characterServiceProvider).getProcessedImage(widget.regionId, widget.isInverted);

      // 临时实现：返回一个空的1x1图像
      return Uint8List.fromList([0, 0, 0, 0]);
    } catch (e) {
      // 记录错误并重新抛出
      print('加载字符图像失败: $e');
      rethrow;
    }
  }

  // 加载轮廓SVG
  Future<String?> _loadOutlineSvg() async {
    try {
      // 从仓库加载SVG
      // 在实际应用中，这里应该调用字符服务加载SVG轮廓
      // return await ref.read(characterServiceProvider).getOutlineSvg(widget.regionId);

      // 临时实现：返回一个示例SVG
      return '<svg>...</svg>';
    } catch (e) {
      print('加载轮廓失败: $e');
      return null;
    }
  }

  void _updateTransform() {
    // 计算基于当前缩放和平移的变换
    final scale = Matrix4.identity()
      ..scale(widget.zoomLevel, widget.zoomLevel, 1.0);
    _transformationController.value = scale;
  }
}
