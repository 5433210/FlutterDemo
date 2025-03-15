import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/models/work/work_image.dart';
import 'thumbnail_strip.dart';

/// 作品图片预览组件（查看模式）
class ViewModeImagePreview extends StatefulWidget {
  final List<WorkImage> images;
  final int selectedIndex;
  final Function(int) onImageSelect;

  const ViewModeImagePreview({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onImageSelect,
  });

  @override
  State<ViewModeImagePreview> createState() => _ViewModeImagePreviewState();
}

class _ViewModeImagePreviewState extends State<ViewModeImagePreview> {
  static const double _minScale = 0.5;
  static const double _maxScale = 4.0;
  final TransformationController _transformationController =
      TransformationController();
  bool _isZoomed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _buildPreviewArea(context),
        ),
        if (widget.images.length > 1)
          SizedBox(
            height: 100,
            child: ThumbnailStrip<WorkImage>(
              images: widget.images,
              selectedIndex: widget.selectedIndex,
              onTap: (index) {
                _resetZoom();
                widget.onImageSelect(index);
              },
              pathResolver: (image) => image.thumbnailPath.isNotEmpty
                  ? image.thumbnailPath
                  : image.path,
              keyResolver: (image) => image.id,
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Widget _buildPreviewArea(BuildContext context) {
    if (widget.images.isEmpty) {
      return const Center(
        child: Text('没有图片'),
      );
    }

    final image = widget.images[widget.selectedIndex];
    final imagePath =
        image.thumbnailPath.isNotEmpty ? image.thumbnailPath : image.path;

    return Stack(
      alignment: Alignment.topRight,
      children: [
        Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent &&
                HardwareKeyboard.instance.isControlPressed) {
              // 计算新的缩放比例
              final currentScale =
                  _transformationController.value.getMaxScaleOnAxis();
              final newScale = currentScale - event.scrollDelta.dy * 0.001;

              // 限制缩放范围
              final scale = newScale.clamp(_minScale, _maxScale);
              setState(() => _isZoomed = scale > 1.0);

              _transformationController.value = Matrix4.identity()
                ..scale(scale);
            }
          },
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: _minScale,
            maxScale: _maxScale,
            onInteractionStart: (details) {
              if (details.pointerCount > 1) {
                setState(() => _isZoomed = true);
              }
            },
            onInteractionEnd: (details) {
              // 检查是否恢复到原始大小
              final matrix = _transformationController.value;
              if (matrix == Matrix4.identity()) {
                setState(() => _isZoomed = false);
              }
            },
            child: Center(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          '图片加载失败',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // Zoom reset button
        if (_isZoomed)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.zoom_out_map),
              onPressed: _resetZoom,
              tooltip: '重置缩放',
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.8),
              ),
            ),
          ),
      ],
    );
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() => _isZoomed = false);
  }
}
