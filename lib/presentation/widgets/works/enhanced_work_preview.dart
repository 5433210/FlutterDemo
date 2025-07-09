import 'package:flutter/material.dart';

import '../../../domain/models/work/work_image.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../pages/works/components/thumbnail_strip.dart';
import '../common/zoomable_image_view.dart';

/// An enhanced work preview component that combines image viewing and thumbnails
class EnhancedWorkPreview extends StatefulWidget {
  final List<WorkImage> images;
  final int selectedIndex;
  final bool isEditing;
  final bool showToolbar;
  final List<Widget>? toolbarActions;
  final Function(int)? onIndexChanged;
  final Function(WorkImage)? onImageAdded;
  final Function(String)? onImageDeleted;
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
    final theme = Theme.of(context);

    return LayoutBuilder(builder: (context, constraints) {
      final toolbarHeight = widget.showToolbar ? 40.0 : 0.0;
      final thumbnailHeight = widget.images.isNotEmpty ? 100.0 : 0.0;

      return Stack(children: [
        Column(
          children: [
            // 主图片显示区域
            Expanded(
              child: currentImage != null
                  ? ZoomableImageView(
                      imagePath: currentImage.path,
                      enableMouseWheel: true,
                      minScale: 0.1,
                      maxScale: 10.0,
                      showControls: true,
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              size: 48, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(AppLocalizations.of(context).noDisplayableImages,
                              style:
                                  TextStyle(color: theme.colorScheme.outline)),
                        ],
                      ),
                    ),
            ),

            // 缩略图条 - 仅在有图片时显示
            if (widget.images.isNotEmpty)
              SizedBox(
                  height: thumbnailHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
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
                            'EnhancedWorkPreview onReorder: $oldIndex -> $newIndex', 
                            tag: 'EnhancedWorkPreview',
                            data: {
                              'oldIndex': oldIndex,
                              'newIndex': newIndex,
                              'totalImages': widget.images.length,
                            });
                        widget.onImagesReordered?.call(oldIndex, newIndex);
                      },
                      pathResolver: (image) => image.path,
                      keyResolver: (image) => image.id,
                    ),
                  )),
          ],
        ), // 工具栏 - 图标按钮设计
        if (widget.showToolbar && widget.toolbarActions != null)
          Container(
            height: toolbarHeight,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.toolbarActions!,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ]);
    });
  }
}
