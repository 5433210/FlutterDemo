import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/work/work_image.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../widgets/common/zoomable_image_view.dart';
import 'thumbnail_strip.dart';

class ViewModeImagePreview extends ConsumerStatefulWidget {
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
  ConsumerState<ViewModeImagePreview> createState() =>
      _ViewModeImagePreviewState();
}

class _ViewModeImagePreviewState extends ConsumerState<ViewModeImagePreview> {
  final Map<String, bool> _fileExistsCache = {};

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const Center(
        child: Text('没有可显示的图片'),
      );
    }

    // Get the current image
    final currentImage = widget.selectedIndex < widget.images.length
        ? widget.images[widget.selectedIndex]
        : widget.images.first;

    return Column(
      children: [
        // Main image display area
        Expanded(
          child: Center(
            child: FutureBuilder<bool>(
              // Check if file exists when building the widget
              future: _checkFileExists(currentImage.path),
              builder: (context, snapshot) {
                final fileExists = snapshot.data ?? false;

                if (!fileExists) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '无法加载图片: ${currentImage.path}',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _fileExistsCache.remove(currentImage.path);
                          setState(() {}); // Force rebuild
                        },
                        child: const Text('重试'),
                      ),
                    ],
                  );
                }

                return ZoomableImageView(
                  imagePath: currentImage.path,
                  enableMouseWheel: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                );
              },
            ),
          ),
        ),

        // Thumbnail strip below the main image
        SizedBox(
          height: 120,
          child: ThumbnailStrip<WorkImage>(
            images: widget.images,
            selectedIndex: widget.selectedIndex,
            onTap: widget.onImageSelect,
            pathResolver: (image) => image.thumbnailPath,
            keyResolver: (image) => image.id,
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(ViewModeImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.images != oldWidget.images) {
      _fileExistsCache.clear();
      _verifyImageFiles();
    }
  }

  @override
  void initState() {
    super.initState();
    _verifyImageFiles();
  }

  // Check if a file exists, using the cache when possible
  Future<bool> _checkFileExists(String path) async {
    if (_fileExistsCache.containsKey(path)) {
      return _fileExistsCache[path] ?? false;
    }

    try {
      final exists = await File(path).exists();
      _fileExistsCache[path] = exists;
      return exists;
    } catch (e) {
      _fileExistsCache[path] = false;
      return false;
    }
  }

  // Verify that image files exist and log any issues
  Future<void> _verifyImageFiles() async {
    for (final image in widget.images) {
      try {
        final file = File(image.path);
        final exists = await file.exists();
        _fileExistsCache[image.path] = exists;

        if (!exists) {
          AppLogger.warning(
            'Image file not found',
            tag: 'ViewModeImagePreview',
            data: {
              'path': image.path,
              'imageId': image.id,
              'workId': image.workId
            },
          );
        }
      } catch (e, stack) {
        AppLogger.error(
          'Error checking image file',
          tag: 'ViewModeImagePreview',
          error: e,
          stackTrace: stack,
          data: {'path': image.path},
        );
        _fileExistsCache[image.path] = false;
      }
    }
  }
}
