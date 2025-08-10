import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/work/work_image.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/zoomable_image_view.dart';
import 'thumbnail_strip.dart';

/// Material 3 version of the image preview component for view mode
class M3ViewModeImagePreview extends ConsumerStatefulWidget {
  /// List of work images to display
  final List<WorkImage> images;

  /// Index of the currently selected image
  final int selectedIndex;

  /// Callback when an image is selected
  final Function(int) onImageSelect;

  const M3ViewModeImagePreview({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onImageSelect,
  });

  @override
  ConsumerState<M3ViewModeImagePreview> createState() =>
      _M3ViewModeImagePreviewState();
}

class _M3ViewModeImagePreviewState
    extends ConsumerState<M3ViewModeImagePreview> {
  static const double _toolbarHeight = 48.0;
  final Map<String, bool> _fileExistsCache = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (widget.images.isEmpty) {
      return Column(
        children: [
          // Add toolbar height space for consistency with edit mode
          const SizedBox(height: _toolbarHeight),
          Expanded(
            child: Center(
              child: Text(
                l10n.noImages,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      );
    }

    // Get the current image
    final currentImage = widget.selectedIndex < widget.images.length
        ? widget.images[widget.selectedIndex]
        : widget.images.first;

    // Use LayoutBuilder to match layout calculation
    return LayoutBuilder(builder: (context, constraints) {
      const thumbnailHeight = 100.0;

      return Column(
        children: [
          // Add empty space matching toolbar height for visual consistency with edit mode

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
                          Icons.broken_image_outlined,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.imageLoadError(l10n.imageFileNotExists),
                          style: TextStyle(
                            color: theme.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  }

                  return ZoomableImageView(
                    imagePath: currentImage.path,
                    enableMouseWheel: true,
                    minScale: 0.1,
                    maxScale: 10.0,
                    showControls: true,
                  );
                },
              ),
            ),
          ),

          // Thumbnail strip below the main image
          SizedBox(
            height: thumbnailHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: ThumbnailStrip<WorkImage>(
                images: widget.images,
                selectedIndex: widget.selectedIndex,
                onTap: widget.onImageSelect,
                pathResolver: (image) => image.thumbnailPath,
                keyResolver: (image) => image.id,
                timestampResolver: (image) => image.updateTime.millisecondsSinceEpoch, // 使用WorkImage的updateTime
              ),
            ),
          ),
        ],
      );
    });
  }

  @override
  void didUpdateWidget(M3ViewModeImagePreview oldWidget) {
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

  // Check if a file exists, using cache for performance
  Future<bool> _checkFileExists(String path) async {
    if (_fileExistsCache.containsKey(path)) {
      return _fileExistsCache[path]!;
    }

    try {
      final file = File(path);
      final exists = await file.exists();
      _fileExistsCache[path] = exists;
      return exists;
    } catch (e) {
      AppLogger.error(
        'Error checking file existence',
        tag: 'M3ViewModeImagePreview',
        error: e,
        data: {'path': path},
      );
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
            tag: 'M3ViewModeImagePreview',
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
          tag: 'M3ViewModeImagePreview',
          error: e,
          stackTrace: stack,
          data: {'path': image.path},
        );
        _fileExistsCache[image.path] = false;
      }
    }
  }
}
