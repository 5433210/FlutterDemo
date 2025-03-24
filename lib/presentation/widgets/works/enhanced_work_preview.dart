import 'package:flutter/material.dart';

import '../../../domain/models/work/work_image.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../pages/works/components/thumbnail_strip.dart';
import '../common/zoomable_image_view.dart';

/// An enhanced work preview component that combines image viewing and thumbnails
class EnhancedWorkPreview extends StatefulWidget {
  /// List of work images to display
  final List<WorkImage> images;

  /// Currently selected image index
  final int selectedIndex;

  /// Whether the preview is in editing mode
  final bool isEditing;

  /// Whether to show the toolbar
  final bool showToolbar;

  /// Optional toolbar actions
  final List<Widget>? toolbarActions;

  /// Called when selected image index changes
  final Function(int)? onIndexChanged;

  /// Called when a new image is added
  final Function(WorkImage)? onImageAdded;

  /// Called when an image is deleted
  final Function(String)? onImageDeleted;

  /// Called when images are reordered
  final Function(int, int)? onImagesReordered;

  const EnhancedWorkPreview({
    super.key,
    required this.images,
    required this.selectedIndex,
    this.isEditing = false,
    this.showToolbar = false,
    this.toolbarActions,
    this.onIndexChanged,
    this.onImageAdded,
    this.onImageDeleted,
    this.onImagesReordered,
  });

  @override
  State<EnhancedWorkPreview> createState() => _EnhancedWorkPreviewState();
}

class _EnhancedWorkPreviewState extends State<EnhancedWorkPreview> {
  @override
  Widget build(BuildContext context) {
    AppLogger.debug(
        'Building EnhancedWorkPreview with ${widget.images.length} images');
    final currentImage = widget.selectedIndex < widget.images.length
        ? widget.images[widget.selectedIndex]
        : null;

    return Column(
      children: [
        // 工具栏 - 始终显示
        if (widget.showToolbar && widget.toolbarActions != null)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: widget.toolbarActions!),
                const SizedBox(width: 8),
              ],
            ),
          ),

        // 主图片显示区域
        Expanded(
          child: currentImage != null
              ? ZoomableImageView(
                  imagePath: currentImage.path,
                  enableMouseWheel: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                )
              : const Center(
                  child: Text('没有可显示的图片'),
                ),
        ),

        // 缩略图条 - 仅在有图片时显示
        if (widget.images.isNotEmpty)
          SizedBox(
            height: 120,
            child: ThumbnailStrip<WorkImage>(
              images: widget.images,
              selectedIndex: widget.selectedIndex,
              isEditable: widget.isEditing,
              onTap: (index) {
                AppLogger.debug('EnhancedWorkPreview onTap: $index');
                widget.onIndexChanged?.call(index);
              },
              onReorder: (oldIndex, newIndex) {
                AppLogger.debug(
                    'EnhancedWorkPreview onReorder: $oldIndex -> $newIndex');
                widget.onImagesReordered?.call(oldIndex, newIndex);
              },
              pathResolver: (image) => image.path,
              keyResolver: (image) => image.id,
            ),
          ),
      ],
    );
  }
}
